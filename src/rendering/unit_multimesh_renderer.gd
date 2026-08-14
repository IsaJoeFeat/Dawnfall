class_name UnitMultiMeshRenderer
extends Node3D

const SELECTED_COLOR := Color(1.0, 0.95, 0.2)

class RenderPrototype:
	var near_mesh: Mesh
	var far_mesh: Mesh
	var vertical_offset: float
	var lod_distance: float

	func _init(
		requested_near_mesh: Mesh,
		requested_far_mesh: Mesh,
		requested_vertical_offset: float,
		requested_lod_distance: float
	) -> void:
		near_mesh = requested_near_mesh
		far_mesh = requested_far_mesh
		vertical_offset = requested_vertical_offset
		lod_distance = requested_lod_distance


class RenderGroup:
	var prototype: RenderPrototype
	var definition_index: int
	var chunk_coordinate: Vector2i
	var chunk_center: Vector3
	var node: MultiMeshInstance3D
	var multimesh: MultiMesh
	var entity_indices := PackedInt32Array()
	var is_far_lod: bool = false

	func _init(
		requested_prototype: RenderPrototype,
		requested_definition_index: int,
		requested_chunk_coordinate: Vector2i,
		requested_chunk_center: Vector3
	) -> void:
		prototype = requested_prototype
		definition_index = requested_definition_index
		chunk_coordinate = requested_chunk_coordinate
		chunk_center = requested_chunk_center


@export_range(4.0, 256.0, 1.0)
var render_chunk_size: float = 32.0


var _simulation_world: SimulationWorld
var _prototypes: Dictionary = {}
var _groups: Dictionary = {}
var _rendered_instance_count: int = 0
var _entity_groups: Array[RenderGroup] = []
var _entity_instance_indices := PackedInt32Array()
var _selected_entity_lookup: Dictionary = {}
var _total_chunk_migration_count: int = 0


func register_prototype(
	definition_index: int,
	near_mesh: Mesh,
	far_mesh: Mesh,
	vertical_offset: float,
	lod_distance: float
) -> bool:
	if not DawnfallLog.require_valid(
		definition_index >= 0,
		"Render prototype definition index cannot be negative.",
		&"UnitMultiMeshRenderer"
	):
		return false

	if not DawnfallLog.require_valid(
		near_mesh != null,
		"Render prototypes require a near mesh.",
		&"UnitMultiMeshRenderer"
	):
		return false

	if far_mesh == null:
		far_mesh = near_mesh

	_prepare_mesh_for_instance_colors(near_mesh)

	if far_mesh != near_mesh:
		_prepare_mesh_for_instance_colors(far_mesh)

	if not DawnfallLog.require_valid(
		lod_distance > 0.0,
		"Render prototype LOD distance must be positive.",
		&"UnitMultiMeshRenderer"
	):
		return false

	_prototypes[definition_index] = RenderPrototype.new(
		near_mesh,
		far_mesh,
		vertical_offset,
		lod_distance
	)

	return true


func build(simulation_world: SimulationWorld) -> bool:
	if not DawnfallLog.require_valid(
		simulation_world != null,
		"Cannot build rendering for a null simulation world.",
		&"UnitMultiMeshRenderer"
	):
		return false

	if not DawnfallLog.require_valid(
		render_chunk_size > 0.0,
		"Render chunk size must be positive.",
		&"UnitMultiMeshRenderer"
	):
		return false

	_simulation_world = simulation_world
	_clear_render_groups()
	_entity_groups.resize(_simulation_world.entities.capacity())
	_entity_instance_indices.resize(
		_simulation_world.entities.capacity()
	)
	_entity_instance_indices.fill(-1)

	for entity_index: int in range(
		_simulation_world.entities.capacity()
	):
		if not _simulation_world.entities.is_index_alive(
			entity_index
		):
			continue

		var definition_index: int = (
			_simulation_world.entities.definition_indices[
				entity_index
			]
		)

		if not _prototypes.has(definition_index):
			continue

		var entity_position: Vector3 = (
			_simulation_world.entities.positions[
				entity_index
			]
		)
		var chunk_coordinate: Vector2i = _world_to_chunk(
			entity_position
		)
		var group_key := Vector3i(
			definition_index,
			chunk_coordinate.x,
			chunk_coordinate.y
		)

		if not _groups.has(group_key):
			var prototype: RenderPrototype = _prototypes[
				definition_index
			]
			var chunk_center := Vector3(
				(
					float(chunk_coordinate.x) + 0.5
				) * render_chunk_size,
				0.0,
				(
					float(chunk_coordinate.y) + 0.5
				) * render_chunk_size
			)

			_groups[group_key] = RenderGroup.new(
				prototype,
				definition_index,
				chunk_coordinate,
				chunk_center
			)

		var group: RenderGroup = _groups[group_key]
		group.entity_indices.append(entity_index)
		_rendered_instance_count += 1

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if group.entity_indices.is_empty():
			continue

		_create_render_group(group)

	_sync_all_from_simulation()

	return true


func _sync_all_from_simulation() -> int:
	if _simulation_world == null:
		return 0

	var updated_instances: int = 0

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if group.multimesh == null:
			continue

		for instance_index: int in range(
			group.entity_indices.size()
		):
			var entity_index: int = group.entity_indices[
				instance_index
			]

			if _sync_entity_transform(
				group,
				instance_index,
				entity_index
			):
				updated_instances += 1

	return updated_instances

func sync_changed_from_simulation(
	changed_entity_indices: PackedInt32Array
) -> int:
	if _simulation_world == null:
		return 0

	var touched_group_keys: Dictionary = {}

	# First pass: update render-chunk membership.
	for entity_index: int in changed_entity_indices:
		if (
			entity_index < 0
			or entity_index >= _entity_groups.size()
			or not _simulation_world.entities.is_index_alive(
				entity_index
			)
		):
			continue

		var current_group: RenderGroup = (
			_entity_groups[entity_index]
		)

		if current_group == null:
			continue

		var entity_position: Vector3 = (
			_simulation_world.entities.positions[entity_index]
		)
		var new_chunk_coordinate: Vector2i = _world_to_chunk(
			entity_position
		)

		if (
			new_chunk_coordinate
			== current_group.chunk_coordinate
		):
			continue

		var definition_index: int = (
			_simulation_world.entities.definition_indices[
				entity_index
			]
		)

		var old_group_key := _make_group_key(
			definition_index,
			current_group.chunk_coordinate
		)
		var new_group_key := _make_group_key(
			definition_index,
			new_chunk_coordinate
		)

		var destination_group: RenderGroup = (
			_get_or_create_render_group(
				definition_index,
				new_chunk_coordinate
			)
		)

		if destination_group == null:
			continue

		if not _move_entity_between_groups(
			entity_index,
			current_group,
			destination_group
		):
			continue

		touched_group_keys[old_group_key] = true
		touched_group_keys[new_group_key] = true
		_total_chunk_migration_count += 1

	var updated_instances: int = 0

	# Rebuild groups whose membership changed.
	for group_key_value: Variant in touched_group_keys.keys():
		var group_key: Vector3i = group_key_value

		if not _groups.has(group_key):
			continue

		var group: RenderGroup = _groups[group_key]

		updated_instances += _rebuild_render_group(group)

	# Normal dirty-transform uploads for groups that did not
	# change membership.
	for entity_index: int in changed_entity_indices:
		if (
			entity_index < 0
			or entity_index >= _entity_groups.size()
			or not _simulation_world.entities.is_index_alive(
				entity_index
			)
		):
			continue

		var group: RenderGroup = _entity_groups[entity_index]

		if group == null:
			continue

		var group_key := _make_group_key(
			group.definition_index,
			group.chunk_coordinate
		)

		if touched_group_keys.has(group_key):
			continue

		var instance_index: int = (
			_entity_instance_indices[entity_index]
		)

		if instance_index < 0:
			continue

		if _sync_entity_transform(
			group,
			instance_index,
			entity_index
		):
			updated_instances += 1

	return updated_instances

func set_selected_entity_indices(
	selected_entity_indices: PackedInt32Array
) -> int:
	for entity_index_value: Variant in (
		_selected_entity_lookup.keys()
	):
		_set_entity_selection_color(
			int(entity_index_value),
			false
		)

	_selected_entity_lookup.clear()

	var highlighted_count: int = 0

	for entity_index: int in selected_entity_indices:
		if _set_entity_selection_color(entity_index, true):
			_selected_entity_lookup[entity_index] = true
			highlighted_count += 1

	return highlighted_count

func update_lod(camera_position: Vector3) -> int:
	var changed_groups: int = 0

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if group.multimesh == null:
			continue

		var lod_distance_squared: float = (
			group.prototype.lod_distance
			* group.prototype.lod_distance
		)
		var distance_squared: float = (
			camera_position.distance_squared_to(
				group.chunk_center
			)
		)
		var should_use_far_lod: bool = (
			distance_squared > lod_distance_squared
		)

		if should_use_far_lod == group.is_far_lod:
			continue

		group.is_far_lod = should_use_far_lod

		if should_use_far_lod:
			group.multimesh.mesh = group.prototype.far_mesh
		else:
			group.multimesh.mesh = group.prototype.near_mesh

		changed_groups += 1

	return changed_groups


func draw_group_count() -> int:
	var active_groups: int = 0

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if group.multimesh != null:
			active_groups += 1

	return active_groups


func near_lod_group_count() -> int:
	var near_groups: int = 0

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if (
			group.multimesh != null
			and not group.is_far_lod
		):
			near_groups += 1

	return near_groups


func far_lod_group_count() -> int:
	var far_groups: int = 0

	for group_key: Vector3i in _groups.keys():
		var group: RenderGroup = _groups[group_key]

		if (
			group.multimesh != null
			and group.is_far_lod
		):
			far_groups += 1

	return far_groups


func rendered_instance_count() -> int:
	return _rendered_instance_count

func total_chunk_migration_count() -> int:
	return _total_chunk_migration_count


func _make_group_key(
	definition_index: int,
	chunk_coordinate: Vector2i
) -> Vector3i:
	return Vector3i(
		definition_index,
		chunk_coordinate.x,
		chunk_coordinate.y
	)


func _get_or_create_render_group(
	definition_index: int,
	chunk_coordinate: Vector2i
) -> RenderGroup:
	var group_key := _make_group_key(
		definition_index,
		chunk_coordinate
	)

	if _groups.has(group_key):
		return _groups[group_key]

	if not _prototypes.has(definition_index):
		return null

	var prototype: RenderPrototype = _prototypes[
		definition_index
	]
	var chunk_center := Vector3(
		(float(chunk_coordinate.x) + 0.5)
		* render_chunk_size,
		0.0,
		(float(chunk_coordinate.y) + 0.5)
		* render_chunk_size
	)

	var group := RenderGroup.new(
		prototype,
		definition_index,
		chunk_coordinate,
		chunk_center
	)

	_groups[group_key] = group

	return group


func _move_entity_between_groups(
	entity_index: int,
	source_group: RenderGroup,
	destination_group: RenderGroup
) -> bool:
	var source_instance_index: int = (
		_entity_instance_indices[entity_index]
	)

	if (
		source_instance_index < 0
		or source_instance_index
		>= source_group.entity_indices.size()
	):
		return false

	var last_source_index: int = (
		source_group.entity_indices.size() - 1
	)

	if source_instance_index != last_source_index:
		var swapped_entity_index: int = (
			source_group.entity_indices[last_source_index]
		)

		source_group.entity_indices[
			source_instance_index
		] = swapped_entity_index

		_entity_instance_indices[
			swapped_entity_index
		] = source_instance_index

	source_group.entity_indices.resize(last_source_index)

	var destination_instance_index: int = (
		destination_group.entity_indices.size()
	)

	destination_group.entity_indices.append(entity_index)

	_entity_groups[entity_index] = destination_group
	_entity_instance_indices[
		entity_index
	] = destination_instance_index

	return true

func _rebuild_render_group(
	group: RenderGroup
) -> int:
	var group_key := _make_group_key(
		group.definition_index,
		group.chunk_coordinate
	)

	if group.entity_indices.is_empty():
		if group.node != null:
			group.node.queue_free()

		group.node = null
		group.multimesh = null
		_groups.erase(group_key)

		return 0

	if group.node == null:
		var multimesh_node := MultiMeshInstance3D.new()

		multimesh_node.name = (
			"Definition_%d_Chunk_%d_%d"
			% [
				group.definition_index,
				group.chunk_coordinate.x,
				group.chunk_coordinate.y,
			]
		)
		multimesh_node.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)

		add_child(multimesh_node)
		group.node = multimesh_node

	var multimesh := MultiMesh.new()

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true

	if group.is_far_lod:
		multimesh.mesh = group.prototype.far_mesh
	else:
		multimesh.mesh = group.prototype.near_mesh

	multimesh.instance_count = group.entity_indices.size()
	multimesh.visible_instance_count = (
		group.entity_indices.size()
	)

	group.node.multimesh = multimesh
	group.multimesh = multimesh

	var updated_instances: int = 0

	for instance_index: int in range(
		group.entity_indices.size()
	):
		var entity_index: int = group.entity_indices[
			instance_index
		]

		_entity_groups[entity_index] = group
		_entity_instance_indices[
			entity_index
		] = instance_index

		var color: Color

		if _selected_entity_lookup.has(entity_index):
			color = SELECTED_COLOR
		else:
			var owner_id: int = (
				_simulation_world.entities.owner_ids[
					entity_index
				]
			)
			color = _get_owner_color(owner_id)

		multimesh.set_instance_color(
			instance_index,
			color
		)

		if _sync_entity_transform(
			group,
			instance_index,
			entity_index
		):
			updated_instances += 1

	return updated_instances

func _create_render_group(group: RenderGroup) -> void:
	var multimesh := MultiMesh.new()

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = group.prototype.near_mesh
	multimesh.instance_count = group.entity_indices.size()
	multimesh.visible_instance_count = (
		group.entity_indices.size()
	)

	var multimesh_node := MultiMeshInstance3D.new()

	multimesh_node.name = (
		"Definition_%d_Chunk_%d_%d"
		% [
			group.definition_index,
			group.chunk_coordinate.x,
			group.chunk_coordinate.y,
		]
	)
	multimesh_node.multimesh = multimesh
	multimesh_node.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)

	add_child(multimesh_node)

	group.node = multimesh_node
	group.multimesh = multimesh

	for instance_index: int in range(
		group.entity_indices.size()
	):
		var entity_index: int = group.entity_indices[
			instance_index
		]
		var owner_id: int = (
			_simulation_world.entities.owner_ids[
				entity_index
			]
		)

		multimesh.set_instance_color(
			instance_index,
			_get_owner_color(owner_id)
		)

		_entity_groups[entity_index] = group
		_entity_instance_indices[entity_index] = instance_index


func _sync_entity_transform(
	group: RenderGroup,
	instance_index: int,
	entity_index: int
) -> bool:
	if not _simulation_world.entities.is_index_alive(
		entity_index
	):
		return false

	var entity_position: Vector3 = (
		_simulation_world.entities.positions[entity_index]
	)
	var heading: float = (
		_simulation_world.entities.headings[entity_index]
	)
	var instance_basis := Basis(Vector3.UP, heading)
	var render_position := (
		entity_position
		+ Vector3.UP * group.prototype.vertical_offset
	)

	group.multimesh.set_instance_transform(
		instance_index,
		Transform3D(instance_basis, render_position)
	)

	return true

func _set_entity_selection_color(
	entity_index: int,
	selected: bool
) -> bool:
	if (
		_simulation_world == null
		or entity_index < 0
		or entity_index >= _entity_groups.size()
		or not _simulation_world.entities.is_index_alive(
			entity_index
		)
	):
		return false

	var group: RenderGroup = _entity_groups[entity_index]
	var instance_index: int = (
		_entity_instance_indices[entity_index]
	)

	if (
		group == null
		or group.multimesh == null
		or instance_index < 0
	):
		return false

	var color: Color = SELECTED_COLOR

	if not selected:
		var owner_id: int = (
			_simulation_world.entities.owner_ids[
				entity_index
			]
		)
		color = _get_owner_color(owner_id)

	group.multimesh.set_instance_color(
		instance_index,
		color
	)

	return true


func _prepare_mesh_for_instance_colors(mesh: Mesh) -> void:
	if mesh is PrimitiveMesh:
		var primitive_mesh := mesh as PrimitiveMesh
		var primitive_material: Material = primitive_mesh.material

		if primitive_material == null:
			primitive_material = StandardMaterial3D.new()
			primitive_mesh.material = primitive_material

		_prepare_material_for_instance_colors(
			primitive_material,
			mesh.resource_path
		)
		return

	for surface_index: int in range(mesh.get_surface_count()):
		var surface_material: Material = (
			mesh.surface_get_material(surface_index)
		)

		if surface_material == null:
			surface_material = StandardMaterial3D.new()
			mesh.surface_set_material(
				surface_index,
				surface_material
			)

		_prepare_material_for_instance_colors(
			surface_material,
			mesh.resource_path
		)


func _prepare_material_for_instance_colors(
	material: Material,
	mesh_path: String
) -> void:
	if material is BaseMaterial3D:
		var base_material := material as BaseMaterial3D

		base_material.albedo_color = Color.WHITE
		base_material.vertex_color_use_as_albedo = true
		return

	if material is ShaderMaterial:
		push_warning(
			(
				"Shader material on '%s' must multiply ALBEDO by "
				+ "COLOR.rgb to display MultiMesh instance colors."
			) % mesh_path
		)

func _world_to_chunk(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_position.x / render_chunk_size),
		floori(world_position.z / render_chunk_size)
	)


func _get_owner_color(owner_id: int) -> Color:
	match owner_id:
		0:
			return Color(0.18, 0.48, 1.0)
		1:
			return Color(1.0, 0.25, 0.18)
		2:
			return Color(0.25, 0.85, 0.35)
		3:
			return Color(1.0, 0.78, 0.18)
		_:
			return Color(0.65, 0.65, 0.65)


func _clear_render_groups() -> void:
	for child: Node in get_children():
		child.queue_free()

	_groups.clear()
	_rendered_instance_count = 0
	_entity_groups.clear()
	_entity_instance_indices.clear()
	_selected_entity_lookup.clear()
	_total_chunk_migration_count = 0

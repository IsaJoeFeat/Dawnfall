class_name UnitMultiMeshRenderer
extends Node3D


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

	sync_from_simulation()

	return true


func sync_from_simulation() -> int:
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

			if not _simulation_world.entities.is_index_alive(
				entity_index
			):
				continue

			var entity_position: Vector3 = (
				_simulation_world.entities.positions[
					entity_index
				]
			)
			var heading: float = (
				_simulation_world.entities.headings[
					entity_index
				]
			)
			var basis := Basis(Vector3.UP, heading)
			var render_position := (
				entity_position
				+ Vector3.UP * group.prototype.vertical_offset
			)

			group.multimesh.set_instance_transform(
				instance_index,
				Transform3D(basis, render_position)
			)

			updated_instances += 1

	return updated_instances


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

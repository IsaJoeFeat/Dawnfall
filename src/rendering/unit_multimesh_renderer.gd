class_name UnitMultiMeshRenderer
extends Node3D


class RenderPrototype:
	var mesh: Mesh
	var vertical_offset: float

	func _init(
		requested_mesh: Mesh,
		requested_vertical_offset: float
	) -> void:
		mesh = requested_mesh
		vertical_offset = requested_vertical_offset


class RenderGroup:
	var prototype: RenderPrototype
	var node: MultiMeshInstance3D
	var multimesh: MultiMesh
	var entity_indices := PackedInt32Array()

	func _init(requested_prototype: RenderPrototype) -> void:
		prototype = requested_prototype


var _simulation_world: SimulationWorld
var _prototypes: Dictionary = {}
var _groups: Dictionary = {}
var _rendered_instance_count: int = 0


func register_prototype(
	definition_index: int,
	mesh: Mesh,
	vertical_offset: float
) -> bool:
	if not DawnfallLog.require_valid(
		definition_index >= 0,
		"Render prototype definition index cannot be negative.",
		&"UnitMultiMeshRenderer"
	):
		return false

	if not DawnfallLog.require_valid(
		mesh != null,
		"Render prototypes require a mesh.",
		&"UnitMultiMeshRenderer"
	):
		return false

	_prototypes[definition_index] = RenderPrototype.new(
		mesh,
		vertical_offset
	)

	return true


func build(simulation_world: SimulationWorld) -> bool:
	if not DawnfallLog.require_valid(
		simulation_world != null,
		"Cannot build rendering for a null simulation world.",
		&"UnitMultiMeshRenderer"
	):
		return false

	_simulation_world = simulation_world
	_clear_render_groups()

	for definition_index: int in _prototypes.keys():
		var prototype: RenderPrototype = _prototypes[
			definition_index
		]

		_groups[definition_index] = RenderGroup.new(prototype)

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

		if not _groups.has(definition_index):
			continue

		var group: RenderGroup = _groups[definition_index]
		group.entity_indices.append(entity_index)
		_rendered_instance_count += 1

	for definition_index: int in _groups.keys():
		var group: RenderGroup = _groups[definition_index]

		if group.entity_indices.is_empty():
			continue

		_create_render_group(definition_index, group)

	sync_from_simulation()

	return true


func sync_from_simulation() -> int:
	if _simulation_world == null:
		return 0

	var updated_instances: int = 0

	for definition_index: int in _groups.keys():
		var group: RenderGroup = _groups[definition_index]

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


func draw_group_count() -> int:
	var active_groups: int = 0

	for definition_index: int in _groups.keys():
		var group: RenderGroup = _groups[definition_index]

		if group.multimesh != null:
			active_groups += 1

	return active_groups


func rendered_instance_count() -> int:
	return _rendered_instance_count


func _create_render_group(
	definition_index: int,
	group: RenderGroup
) -> void:
	var multimesh := MultiMesh.new()

	# Format and color flags must be configured before instance_count.
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = group.prototype.mesh
	multimesh.instance_count = group.entity_indices.size()
	multimesh.visible_instance_count = (
		group.entity_indices.size()
	)

	var multimesh_node := MultiMeshInstance3D.new()

	multimesh_node.name = (
		"Definition_%d" % definition_index
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

class_name UnitMoveCommandController
extends Node


signal command_issued(
	accepted_count: int,
	formation: bool,
	planning_milliseconds: float,
	dispatch_milliseconds: float,
	path_length: float
)


const DRAG_PIXEL_THRESHOLD: float = 8.0
const SAMPLE_PIXEL_SPACING: float = 4.0
const PREVIEW_INTERVAL_MICROSECONDS: int = 33000
const GROUND_PLANE := Plane(Vector3.UP, 0.0)


var _simulation_world: SimulationWorld
var _camera: Camera3D
var _selection_controller: UnitSelectionController
var _planner := FormationMovePlanner.new()

var _drawing: bool = false
var _drag_start_screen := Vector2.ZERO
var _last_sample_screen := Vector2.ZERO
var _command_entity_indices := PackedInt32Array()
var _polyline := PackedVector3Array()
var _next_preview_time: int = 0

var _line_preview: MeshInstance3D
var _line_mesh: ImmediateMesh
var _slot_preview: MultiMeshInstance3D
var _slot_multimesh: MultiMesh


func _ready() -> void:
	_create_preview()


func configure(
	simulation_world: SimulationWorld,
	camera: Camera3D,
	selection_controller: UnitSelectionController
) -> bool:
	if not DawnfallLog.require_valid(
		simulation_world != null,
		"Move commands require a simulation world.",
		&"UnitMoveCommandController"
	):
		return false

	if not DawnfallLog.require_valid(
		camera != null,
		"Move commands require a camera.",
		&"UnitMoveCommandController"
	):
		return false

	if not DawnfallLog.require_valid(
		selection_controller != null,
		"Move commands require a selection controller.",
		&"UnitMoveCommandController"
	):
		return false

	_simulation_world = simulation_world
	_camera = camera
	_selection_controller = selection_controller

	return true


func _unhandled_input(event: InputEvent) -> void:
	if (
		_simulation_world == null
		or _camera == null
		or _selection_controller == null
	):
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_RIGHT:
			return

		if mouse_button.pressed:
			if _begin_command(mouse_button.position):
				get_viewport().set_input_as_handled()
		else:
			if not _drawing:
				return

			_finish_command(mouse_button.position)
			get_viewport().set_input_as_handled()

		return

	if event is InputEventMouseMotion and _drawing:
		var mouse_motion := event as InputEventMouseMotion

		_continue_command(mouse_motion.position)
		get_viewport().set_input_as_handled()


func _begin_command(screen_position: Vector2) -> bool:
	var selected: PackedInt32Array = (
		_selection_controller.selected_entity_indices()
	)

	if selected.is_empty():
		return false

	var ground_hit: Variant = _screen_to_ground(screen_position)

	if ground_hit == null:
		return false

	_drawing = true
	_drag_start_screen = screen_position
	_last_sample_screen = screen_position
	_command_entity_indices = selected
	_polyline = PackedVector3Array()
	_next_preview_time = 0

	var ground_position: Vector3 = ground_hit

	_append_path_point(
		ground_position,
		screen_position,
		true
	)
	_update_preview(true)

	return true


func _continue_command(screen_position: Vector2) -> void:
	if (
		screen_position.distance_to(_last_sample_screen)
		< SAMPLE_PIXEL_SPACING
	):
		return

	var ground_hit: Variant = _screen_to_ground(screen_position)

	if ground_hit == null:
		return

	var ground_position: Vector3 = ground_hit

	_append_path_point(
		ground_position,
		screen_position,
		false
	)
	_update_preview(false)


func _finish_command(screen_position: Vector2) -> void:
	var ground_hit: Variant = _screen_to_ground(screen_position)

	if ground_hit != null:
		var ground_position: Vector3 = ground_hit

		_append_path_point(
			ground_position,
			screen_position,
			true
		)

	if _polyline.is_empty():
		_cancel_command()
		return

	var path_length: float = _polyline_length(_polyline)
	var screen_drag_distance: float = (
		_drag_start_screen.distance_to(screen_position)
	)
	var formation: bool = (
	_command_entity_indices.size() > 1
	and screen_drag_distance >= DRAG_PIXEL_THRESHOLD
)

	var planning_start: int = Time.get_ticks_usec()
	var destinations := PackedVector3Array()

	if formation:
		var slots: PackedVector3Array = (
			_planner.create_even_slots(
				_polyline,
				_command_entity_indices.size()
			)
		)

		destinations = _planner.assign_slots(
			_simulation_world.entities,
			_command_entity_indices,
			slots
		)
	else:
		var destination: Vector3 = (
			_polyline[_polyline.size() - 1]
		)
		var point_slots: PackedVector3Array = (
			_planner.create_compact_slots(
				_simulation_world.entities,
				_command_entity_indices,
				destination
			)
		)

		destinations = _planner.assign_slots(
			_simulation_world.entities,
			_command_entity_indices,
			point_slots
		)

	var planning_milliseconds: float = (
		float(Time.get_ticks_usec() - planning_start)
		/ 1000.0
	)

	if (
		destinations.size()
		!= _command_entity_indices.size()
	):
		push_error(
			"Formation planner did not return one "
			+ "destination per selected entity."
		)
		_cancel_command()
		return

	var dispatch_start: int = Time.get_ticks_usec()
	var entity_ids := PackedInt64Array()
	var valid_destinations := PackedVector3Array()

	for entity_order: int in range(
		_command_entity_indices.size()
	):
		var entity_index: int = (
			_command_entity_indices[entity_order]
		)
		var entity_id: int = (
			_simulation_world.entities.get_id_by_index(
				entity_index
			)
		)

		if not EntityId.is_valid(entity_id):
			continue

		entity_ids.append(entity_id)
		valid_destinations.append(
			destinations[entity_order]
		)

	var accepted_count: int = (
		_simulation_world.issue_group_move(
			entity_ids,
			valid_destinations
		)
	)
	var dispatch_milliseconds: float = (
		float(Time.get_ticks_usec() - dispatch_start)
		/ 1000.0
	)

	command_issued.emit(
		accepted_count,
		formation,
		planning_milliseconds,
		dispatch_milliseconds,
		path_length
	)

	_cancel_command()


func _append_path_point(
	world_position: Vector3,
	screen_position: Vector2,
	force: bool
) -> void:
	if (
		not force
		and screen_position.distance_to(
			_last_sample_screen
		) < SAMPLE_PIXEL_SPACING
	):
		return

	_last_sample_screen = screen_position

	if not _polyline.is_empty():
		var previous: Vector3 = (
			_polyline[_polyline.size() - 1]
		)

		if _ground_distance(previous, world_position) < 0.01:
			return

	_polyline.append(world_position)


func _update_preview(force: bool) -> void:
	var current_time: int = Time.get_ticks_usec()

	if not force and current_time < _next_preview_time:
		return

	_next_preview_time = (
		current_time + PREVIEW_INTERVAL_MICROSECONDS
	)

	_line_mesh.clear_surfaces()

	if _polyline.size() >= 2:
		_line_mesh.surface_begin(
			Mesh.PRIMITIVE_LINE_STRIP
		)

		for point: Vector3 in _polyline:
			_line_mesh.surface_add_vertex(
				point + Vector3.UP * 0.18
			)

		_line_mesh.surface_end()
		_line_preview.visible = true
	else:
		_line_preview.visible = false

	var path_length: float = _polyline_length(_polyline)

	if _command_entity_indices.size() <= 1:
		_slot_multimesh.instance_count = 0
		_slot_preview.visible = false
		return

	var slots: PackedVector3Array = (
		_planner.create_even_slots(
			_polyline,
			_command_entity_indices.size()
		)
	)

	_slot_multimesh.instance_count = slots.size()

	for slot_index: int in range(slots.size()):
		_slot_multimesh.set_instance_transform(
			slot_index,
			Transform3D(
				Basis.IDENTITY,
				slots[slot_index] + Vector3.UP * 0.09
			)
		)

	_slot_preview.visible = true


func _create_preview() -> void:
	_line_mesh = ImmediateMesh.new()
	_line_preview = MeshInstance3D.new()
	_line_preview.name = "FormationLinePreview"
	_line_preview.mesh = _line_mesh
	_line_preview.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)

	var line_material := StandardMaterial3D.new()

	line_material.albedo_color = Color(
		0.15,
		0.8,
		1.0,
		0.9
	)
	line_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)
	line_material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	line_material.no_depth_test = true

	_line_preview.material_override = line_material
	_line_preview.visible = false
	add_child(_line_preview)

	var marker_mesh := BoxMesh.new()
	var marker_material := StandardMaterial3D.new()

	marker_mesh.size = Vector3(0.7, 0.08, 0.7)

	marker_material.albedo_color = Color(
		0.2,
		0.9,
		1.0,
		0.8
	)
	marker_material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)
	marker_material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	marker_material.no_depth_test = true

	marker_mesh.material = marker_material

	_slot_multimesh = MultiMesh.new()
	_slot_multimesh.transform_format = (
		MultiMesh.TRANSFORM_3D
	)
	_slot_multimesh.mesh = marker_mesh
	_slot_multimesh.instance_count = 0

	_slot_preview = MultiMeshInstance3D.new()
	_slot_preview.name = "FormationSlotPreview"
	_slot_preview.multimesh = _slot_multimesh
	_slot_preview.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	_slot_preview.visible = false

	add_child(_slot_preview)


func _cancel_command() -> void:
	_drawing = false
	_command_entity_indices = PackedInt32Array()
	_polyline = PackedVector3Array()

	_line_mesh.clear_surfaces()
	_line_preview.visible = false

	_slot_multimesh.instance_count = 0
	_slot_preview.visible = false


func _screen_to_ground(
	screen_position: Vector2
) -> Variant:
	var ray_origin: Vector3 = (
		_camera.project_ray_origin(screen_position)
	)
	var ray_direction: Vector3 = (
		_camera.project_ray_normal(screen_position)
	)

	return GROUND_PLANE.intersects_ray(
		ray_origin,
		ray_direction
	)


func _polyline_length(
	polyline: PackedVector3Array
) -> float:
	var total: float = 0.0

	for point_index: int in range(1, polyline.size()):
		total += _ground_distance(
			polyline[point_index - 1],
			polyline[point_index]
		)

	return total


func _ground_distance(
	first: Vector3,
	second: Vector3
) -> float:
	var offset: Vector3 = second - first

	offset.y = 0.0

	return offset.length()

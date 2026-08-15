class_name UnitSelectionController
extends Node


signal selection_changed(
	entity_indices: PackedInt32Array,
	elapsed_milliseconds: float
)


const CLICK_PIXEL_RADIUS: float = 18.0
const CLICK_WORLD_QUERY_RADIUS: float = 6.0
const DRAG_THRESHOLD: float = 8.0
const GROUND_PLANE := Plane(Vector3.UP, 0.0)


var _simulation_world: SimulationWorld
var _camera: Camera3D
var _owner_id: int = 0

var _pointer_down: bool = false
var _drag_start := Vector2.ZERO
var _drag_current := Vector2.ZERO
var _selected_indices := PackedInt32Array()

var _drag_rectangle: ColorRect


func _ready() -> void:
	_create_drag_rectangle()


func configure(
	simulation_world: SimulationWorld,
	camera: Camera3D,
	owner_id: int
) -> bool:
	if not DawnfallLog.require_valid(
		simulation_world != null,
		"Selection requires a simulation world.",
		&"UnitSelectionController"
	):
		return false

	if not DawnfallLog.require_valid(
		camera != null,
		"Selection requires a camera.",
		&"UnitSelectionController"
	):
		return false

	if not DawnfallLog.require_valid(
		owner_id >= 0,
		"Selection owner ID cannot be negative.",
		&"UnitSelectionController"
	):
		return false

	_simulation_world = simulation_world
	_camera = camera
	_owner_id = owner_id

	return true


func selected_entity_indices() -> PackedInt32Array:
	return _selected_indices


func selected_count() -> int:
	return _selected_indices.size()

func remove_destroyed_entity_indices(
	destroyed_entity_indices: PackedInt32Array
) -> int:
	if destroyed_entity_indices.is_empty():
		return 0

	var destroyed_lookup: Dictionary = {}

	for entity_index: int in destroyed_entity_indices:
		destroyed_lookup[
			entity_index
		] = true

	var filtered_selection := PackedInt32Array()
	var removed_count: int = 0

	for entity_index: int in _selected_indices:
		if destroyed_lookup.has(
			entity_index
		):
			removed_count += 1
			continue

		filtered_selection.append(
			entity_index
		)

	if removed_count == 0:
		return 0

	_selected_indices = filtered_selection

	selection_changed.emit(
		_selected_indices,
		0.0
	)

	return removed_count

func _unhandled_input(event: InputEvent) -> void:
	if _simulation_world == null or _camera == null:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_button.pressed:
			_pointer_down = true
			_drag_start = mouse_button.position
			_drag_current = mouse_button.position
			_update_drag_rectangle()
		else:
			if not _pointer_down:
				return

			_drag_current = mouse_button.position
			_pointer_down = false

			var drag_distance: float = (
				_drag_start.distance_to(_drag_current)
			)

			if drag_distance < DRAG_THRESHOLD:
				_select_click(_drag_current)
			else:
				_select_box(
					_screen_rectangle(
						_drag_start,
						_drag_current
					)
				)

			_drag_rectangle.visible = false

		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and _pointer_down:
		var mouse_motion := event as InputEventMouseMotion

		_drag_current = mouse_motion.position
		_update_drag_rectangle()
		get_viewport().set_input_as_handled()


func _select_click(screen_position: Vector2) -> void:
	var selection_start: int = Time.get_ticks_usec()
	var ground_hit: Variant = _screen_to_ground(
		screen_position
	)
	var selected := PackedInt32Array()

	if ground_hit != null:
		var ground_position: Vector3 = ground_hit
		var candidates: PackedInt32Array = (
			_simulation_world.query_entities_in_radius(
				ground_position,
				CLICK_WORLD_QUERY_RADIUS,
				_owner_id
			)
		)
		var closest_distance_squared: float = (
			CLICK_PIXEL_RADIUS * CLICK_PIXEL_RADIUS
		)
		var closest_index: int = -1

		for entity_index: int in candidates:
			var world_position: Vector3 = (
				_simulation_world.entities.positions[
					entity_index
				]
			)

			if _camera.is_position_behind(world_position):
				continue

			var candidate_screen_position: Vector2 = (
				_camera.unproject_position(world_position)
			)
			var screen_distance_squared: float = (
				screen_position.distance_squared_to(
					candidate_screen_position
				)
			)

			if (
				screen_distance_squared
				< closest_distance_squared
			):
				closest_distance_squared = (
					screen_distance_squared
				)
				closest_index = entity_index

		if closest_index >= 0:
			selected.append(closest_index)

	_commit_selection(selected, selection_start)


func _select_box(screen_rectangle: Rect2) -> void:
	var selection_start: int = Time.get_ticks_usec()
	var corners: Array[Vector2] = [
		screen_rectangle.position,
		Vector2(
			screen_rectangle.end.x,
			screen_rectangle.position.y
		),
		screen_rectangle.end,
		Vector2(
			screen_rectangle.position.x,
			screen_rectangle.end.y
		),
	]
	var ground_points: Array[Vector3] = []

	for corner: Vector2 in corners:
		var ground_hit: Variant = _screen_to_ground(corner)

		if ground_hit == null:
			_commit_selection(
				PackedInt32Array(),
				selection_start
			)
			return

		var ground_point: Vector3 = ground_hit
		ground_points.append(ground_point)

	var minimum := ground_points[0]
	var maximum := ground_points[0]

	for ground_point: Vector3 in ground_points:
		minimum.x = minf(minimum.x, ground_point.x)
		minimum.z = minf(minimum.z, ground_point.z)
		maximum.x = maxf(maximum.x, ground_point.x)
		maximum.z = maxf(maximum.z, ground_point.z)

	var candidates: PackedInt32Array = (
		_simulation_world.query_entities_in_aabb(
			minimum,
			maximum,
			_owner_id
		)
	)
	var selected := PackedInt32Array()
	var inclusive_rectangle: Rect2 = (
		screen_rectangle.grow(1.0)
	)

	for entity_index: int in candidates:
		var world_position: Vector3 = (
			_simulation_world.entities.positions[
				entity_index
			]
		)

		if _camera.is_position_behind(world_position):
			continue

		var screen_position: Vector2 = (
			_camera.unproject_position(world_position)
		)

		if inclusive_rectangle.has_point(screen_position):
			selected.append(entity_index)

	_commit_selection(selected, selection_start)


func _commit_selection(
	entity_indices: PackedInt32Array,
	selection_start: int
) -> void:
	entity_indices.sort()
	_selected_indices = entity_indices

	var elapsed_milliseconds: float = (
		float(Time.get_ticks_usec() - selection_start)
		/ 1000.0
	)

	selection_changed.emit(
		_selected_indices,
		elapsed_milliseconds
	)


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


func _screen_rectangle(
	first: Vector2,
	second: Vector2
) -> Rect2:
	var minimum := Vector2(
		minf(first.x, second.x),
		minf(first.y, second.y)
	)
	var maximum := Vector2(
		maxf(first.x, second.x),
		maxf(first.y, second.y)
	)

	return Rect2(minimum, maximum - minimum)


func _create_drag_rectangle() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "SelectionOverlay"
	canvas.layer = 20
	add_child(canvas)

	_drag_rectangle = ColorRect.new()
	_drag_rectangle.color = Color(0.2, 0.65, 1.0, 0.22)
	_drag_rectangle.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	_drag_rectangle.visible = false

	canvas.add_child(_drag_rectangle)


func _update_drag_rectangle() -> void:
	if _drag_rectangle == null:
		return

	var rectangle: Rect2 = _screen_rectangle(
		_drag_start,
		_drag_current
	)

	_drag_rectangle.position = rectangle.position
	_drag_rectangle.size = rectangle.size
	_drag_rectangle.visible = (
		rectangle.size.length() >= DRAG_THRESHOLD
	)

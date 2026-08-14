class_name RtsCameraController
extends Camera3D


const ZOOM_TRANSITION_RESPONSE: float = 12.0
const ZOOM_SNAP_DISTANCE: float = 0.01


@export_range(10.0, 1000.0, 1.0)
var minimum_distance: float = 30.0

@export_range(10.0, 1000.0, 1.0)
var maximum_distance: float = 300.0

@export_range(1.0, 500.0, 1.0)
var base_pan_speed: float = 80.0

@export_range(0.005, 0.10, 0.005)
var edge_pan_width_ratio: float = 0.02

@export
var edge_pan_enabled: bool = true

@export_range(0.1, 50.0, 0.1)
var zoom_step: float = 18.0

@export_range(0.01, 2.0, 0.01)
var mouse_rotation_sensitivity_degrees: float = 0.25

@export_range(1.0, 89.0, 1.0)
var minimum_elevation_degrees: float = 20.0

@export_range(1.0, 89.0, 1.0)
var maximum_elevation_degrees: float = 85.0


var _focus_position := Vector3.ZERO
var _distance: float = 180.0
var _yaw: float = deg_to_rad(45.0)
var _elevation: float = deg_to_rad(55.0)

var _middle_pan_active: bool = false
var _middle_pan_anchor := Vector3.ZERO

var _zoom_target_focus_position := Vector3.ZERO
var _zoom_target_distance: float = 180.0
var _zoom_transition_active: bool = false


func _ready() -> void:
	current = true
	fov = 45.0
	near = 0.5
	far = 2000.0

	_zoom_target_focus_position = _focus_position
	_zoom_target_distance = _distance

	_update_camera_transform()


func configure(
	focus_position: Vector3,
	starting_distance: float = 180.0
) -> void:
	_focus_position = focus_position
	_distance = clampf(
		starting_distance,
		minimum_distance,
		maximum_distance
	)

	_zoom_target_focus_position = _focus_position
	_zoom_target_distance = _distance
	_zoom_transition_active = false

	_update_camera_transform()


func _process(delta: float) -> void:
	var camera_changed: bool = false

	if _zoom_transition_active:
		_update_zoom_transition(delta)
		camera_changed = true

	if edge_pan_enabled and not _middle_pan_active:
		var forward := Vector3(
			-sin(_yaw),
			0.0,
			-cos(_yaw)
		)
		var right := Vector3(
			cos(_yaw),
			0.0,
			-sin(_yaw)
		)

		var movement_direction: Vector3 = (
			_get_edge_pan_direction(
				forward,
				right
			)
		)

		if not movement_direction.is_zero_approx():
			var distance_scale: float = maxf(
				_distance / 180.0,
				0.35
			)

			var movement_offset: Vector3 = (
				movement_direction
				* base_pan_speed
				* distance_scale
				* delta
			)

			_focus_position += movement_offset
			_zoom_target_focus_position += movement_offset

			camera_changed = true

	if camera_changed:
		_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _middle_pan_active:
			var mouse_motion := event as InputEventMouseMotion

			if mouse_motion.alt_pressed:
				_update_middle_mouse_rotation(
					mouse_motion
				)
			else:
				_update_middle_mouse_pan(
					mouse_motion
				)

			get_viewport().set_input_as_handled()

		return

	if event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
		if mouse_event.pressed:
			var ground_point: Variant = _screen_to_ground(
				mouse_event.position
			)

			if ground_point is Vector3:
				_middle_pan_anchor = (
					ground_point as Vector3
				)
				_middle_pan_active = true
			else:
				_middle_pan_active = false
		else:
			_middle_pan_active = false

		get_viewport().set_input_as_handled()
		return

	if not mouse_event.pressed:
		return

	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_queue_zoom_in(mouse_event.position)
			get_viewport().set_input_as_handled()

		MOUSE_BUTTON_WHEEL_DOWN:
			_queue_zoom_out()
			get_viewport().set_input_as_handled()


func _queue_zoom_in(
	screen_position: Vector2
) -> void:
	var base_focus: Vector3 = (
		_zoom_target_focus_position
		if _zoom_transition_active
		else _focus_position
	)
	var base_distance: float = (
		_zoom_target_distance
		if _zoom_transition_active
		else _distance
	)

	var desired_distance: float = maxf(
		minimum_distance,
		base_distance - zoom_step
	)

	if is_equal_approx(
		desired_distance,
		base_distance
	):
		return

	var saved_focus: Vector3 = _focus_position
	var saved_distance: float = _distance

	# Temporarily place the camera at the current target state.
	# This lets repeated wheel inputs accumulate naturally.
	_focus_position = base_focus
	_distance = base_distance
	_update_camera_transform()

	var anchor_before: Variant = _screen_to_ground(
		screen_position
	)

	_distance = desired_distance
	_update_camera_transform()

	var anchor_after: Variant = _screen_to_ground(
		screen_position
	)

	var desired_focus: Vector3 = base_focus

	if (
		anchor_before is Vector3
		and anchor_after is Vector3
	):
		desired_focus += (
			(anchor_before as Vector3)
			- (anchor_after as Vector3)
		)

	_zoom_target_focus_position = desired_focus
	_zoom_target_distance = desired_distance
	_zoom_transition_active = true

	# Return to the actually displayed camera state.
	_focus_position = saved_focus
	_distance = saved_distance
	_update_camera_transform()


func _queue_zoom_out() -> void:
	var base_focus: Vector3 = (
		_zoom_target_focus_position
		if _zoom_transition_active
		else _focus_position
	)
	var base_distance: float = (
		_zoom_target_distance
		if _zoom_transition_active
		else _distance
	)

	var desired_distance: float = minf(
		maximum_distance,
		base_distance + zoom_step
	)

	if is_equal_approx(
		desired_distance,
		base_distance
	):
		return

	# Zoom-out stays centered exactly as in the version
	# you already verified.
	_zoom_target_focus_position = base_focus
	_zoom_target_distance = desired_distance
	_zoom_transition_active = true


func _update_zoom_transition(
	delta: float
) -> void:
	var blend: float = (
		1.0
		- exp(
			-ZOOM_TRANSITION_RESPONSE
			* delta
		)
	)

	_distance = lerpf(
		_distance,
		_zoom_target_distance,
		blend
	)

	_focus_position = _focus_position.lerp(
		_zoom_target_focus_position,
		blend
	)

	var distance_remaining: float = absf(
		_zoom_target_distance - _distance
	)
	var focus_remaining: float = (
		_zoom_target_focus_position
		- _focus_position
	).length()

	if (
		distance_remaining <= ZOOM_SNAP_DISTANCE
		and focus_remaining <= ZOOM_SNAP_DISTANCE
	):
		_distance = _zoom_target_distance
		_focus_position = _zoom_target_focus_position
		_zoom_transition_active = false


func _update_middle_mouse_pan(
	mouse_event: InputEventMouseMotion
) -> void:
	var ground_point: Variant = _screen_to_ground(
		mouse_event.position
	)

	if ground_point is not Vector3:
		return

	var current_ground_point := ground_point as Vector3
	var movement_offset: Vector3 = (
		_middle_pan_anchor
		- current_ground_point
	)

	_focus_position += movement_offset
	_zoom_target_focus_position += movement_offset

	_update_camera_transform()


func _update_middle_mouse_rotation(
	mouse_event: InputEventMouseMotion
) -> void:
	var sensitivity_radians: float = deg_to_rad(
		mouse_rotation_sensitivity_degrees
	)

	_yaw -= (
		mouse_event.relative.x
		* sensitivity_radians
	)

	_elevation -= (
		mouse_event.relative.y
		* sensitivity_radians
	)

	_elevation = clampf(
		_elevation,
		deg_to_rad(minimum_elevation_degrees),
		deg_to_rad(maximum_elevation_degrees)
	)

	_update_camera_transform()

	var ground_point: Variant = _screen_to_ground(
		mouse_event.position
	)

	if ground_point is Vector3:
		_middle_pan_anchor = ground_point as Vector3


func _get_edge_pan_direction(
	forward: Vector3,
	right: Vector3
) -> Vector3:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)
	var mouse_position: Vector2 = (
		get_viewport().get_mouse_position()
	)

	if (
		viewport_size.x <= 0.0
		or viewport_size.y <= 0.0
	):
		return Vector3.ZERO

	var horizontal_zone: float = (
		viewport_size.x * edge_pan_width_ratio
	)
	var vertical_zone: float = (
		viewport_size.y * edge_pan_width_ratio
	)

	var horizontal_strength: float = 0.0
	var vertical_strength: float = 0.0

	if mouse_position.x <= horizontal_zone:
		horizontal_strength = -(
			1.0
			- mouse_position.x
			/ horizontal_zone
		)
	elif (
		mouse_position.x
		>= viewport_size.x - horizontal_zone
	):
		horizontal_strength = (
			1.0
			- (
				viewport_size.x
				- mouse_position.x
			) / horizontal_zone
		)

	if mouse_position.y <= vertical_zone:
		vertical_strength = (
			1.0
			- mouse_position.y
			/ vertical_zone
		)
	elif (
		mouse_position.y
		>= viewport_size.y - vertical_zone
	):
		vertical_strength = -(
			1.0
			- (
				viewport_size.y
				- mouse_position.y
			) / vertical_zone
		)

	var edge_direction: Vector3 = (
		right * horizontal_strength
		+ forward * vertical_strength
	)

	if edge_direction.length_squared() > 1.0:
		edge_direction = edge_direction.normalized()

	return edge_direction


func _screen_to_ground(
	screen_position: Vector2
) -> Variant:
	var ground_plane := Plane(Vector3.UP, 0.0)

	var ray_origin: Vector3 = project_ray_origin(
		screen_position
	)
	var ray_direction: Vector3 = project_ray_normal(
		screen_position
	)

	return ground_plane.intersects_ray(
		ray_origin,
		ray_direction
	)


func _update_camera_transform() -> void:
	var horizontal_distance: float = (
		cos(_elevation) * _distance
	)
	var vertical_distance: float = (
		sin(_elevation) * _distance
	)
	var offset := Vector3(
		sin(_yaw) * horizontal_distance,
		vertical_distance,
		cos(_yaw) * horizontal_distance
	)

	global_position = _focus_position + offset
	look_at(_focus_position, Vector3.UP)

class_name RtsCameraController
extends Camera3D


@export_range(10.0, 1000.0, 1.0)
var minimum_distance: float = 30.0

@export_range(10.0, 1000.0, 1.0)
var maximum_distance: float = 300.0

@export_range(1.0, 500.0, 1.0)
var base_pan_speed: float = 80.0

@export_range(0.1, 10.0, 0.1)
var zoom_step: float = 18.0

@export_range(1.0, 180.0, 1.0)
var rotation_speed_degrees: float = 60.0


var _focus_position := Vector3.ZERO
var _distance: float = 180.0
var _yaw: float = deg_to_rad(45.0)
var _elevation: float = deg_to_rad(55.0)


func _ready() -> void:
	current = true
	near = 0.5
	far = 2000.0
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

	_update_camera_transform()


func _process(delta: float) -> void:
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
	var movement_direction := Vector3.ZERO

	if (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_UP)
	):
		movement_direction += forward

	if (
		Input.is_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_DOWN)
	):
		movement_direction -= forward

	if (
		Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_RIGHT)
	):
		movement_direction += right

	if (
		Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_LEFT)
	):
		movement_direction -= right

	if not movement_direction.is_zero_approx():
		var distance_scale: float = maxf(
			_distance / 180.0,
			0.35
		)

		_focus_position += (
			movement_direction.normalized()
			* base_pan_speed
			* distance_scale
			* delta
		)

	var rotation_input: float = 0.0

	if Input.is_key_pressed(KEY_Q):
		rotation_input += 1.0

	if Input.is_key_pressed(KEY_E):
		rotation_input -= 1.0

	if not is_zero_approx(rotation_input):
		_yaw += (
			deg_to_rad(rotation_speed_degrees)
			* rotation_input
			* delta
		)

	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton

	if not mouse_event.pressed:
		return

	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(
				minimum_distance,
				_distance - zoom_step
			)
			get_viewport().set_input_as_handled()

		MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(
				maximum_distance,
				_distance + zoom_step
			)
			get_viewport().set_input_as_handled()

	_update_camera_transform()


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

class_name MovementDefinition
extends GameDefinition


enum MovementClass {
	IMMOBILE,
	INFANTRY,
	WHEELED,
	TRACKED,
	AMPHIBIOUS,
	NAVAL,
	AIR,
}

@export_group("Movement")

@export var movement_class: MovementClass = MovementClass.INFANTRY

@export_range(0.0, 1000.0, 0.1, "or_greater")
var max_speed: float = 5.0

@export_range(0.0, 1000.0, 0.1, "or_greater")
var acceleration: float = 5.0

@export_range(0.0, 1000.0, 0.1, "or_greater")
var deceleration: float = 8.0

@export_range(0.0, 1080.0, 1.0, "or_greater")
var turn_speed_degrees: float = 180.0


func validate() -> bool:
	var is_valid: bool = super.validate()
	var context: StringName = get_validation_context()
	var is_mobile: bool = movement_class != MovementClass.IMMOBILE

	if is_mobile:
		is_valid = DawnfallLog.require_valid(
			max_speed > 0.0,
			"Mobile movement profiles require a speed above zero.",
			context
		) and is_valid

		is_valid = DawnfallLog.require_valid(
			acceleration > 0.0,
			"Mobile movement profiles require acceleration above zero.",
			context
		) and is_valid

		is_valid = DawnfallLog.require_valid(
			deceleration > 0.0,
			"Mobile movement profiles require deceleration above zero.",
			context
		) and is_valid

		is_valid = DawnfallLog.require_valid(
			turn_speed_degrees > 0.0,
			"Mobile movement profiles require turn speed above zero.",
			context
		) and is_valid
	else:
		is_valid = DawnfallLog.require_valid(
			is_zero_approx(max_speed),
			"Immobile movement profiles must have zero speed.",
			context
		) and is_valid

	return is_valid

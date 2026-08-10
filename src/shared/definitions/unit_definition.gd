class_name UnitDefinition
extends Resource


@export_group("Identity")

@export var definition_id: StringName = &""
@export var display_name: String = ""


@export_group("Simulation")

@export_range(1.0, 100000.0, 1.0, "or_greater")
var max_health: float = 100.0

@export_range(0.0, 1000.0, 0.1, "or_greater")
var movement_speed: float = 5.0

@export_range(0.05, 100.0, 0.05, "or_greater")
var collision_radius: float = 0.5


func validate() -> bool:
	var is_valid: bool = true
	var context: StringName = _get_validation_context()

	is_valid = DawnfallLog.require_valid(
		definition_id != &"",
		"Definition ID cannot be empty.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		not display_name.strip_edges().is_empty(),
		"Display name cannot be empty.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		max_health > 0.0,
		"Maximum health must be greater than zero.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		movement_speed >= 0.0,
		"Movement speed cannot be negative.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		collision_radius > 0.0,
		"Collision radius must be greater than zero.",
		context
	) and is_valid

	return is_valid


func _get_validation_context() -> StringName:
	if definition_id != &"":
		return definition_id

	return &"UnnamedUnitDefinition"

class_name WeaponDefinition
extends GameDefinition


enum DeliveryType {
	HITSCAN,
	PROJECTILE,
	BOMB,
	TORPEDO,
	MINE,
}

@export_group("Weapon")

@export var delivery_type: DeliveryType = DeliveryType.HITSCAN

@export_flags("Infantry", "Vehicle", "Aircraft", "Naval", "Structure")
var valid_target_categories: int = CombatTypes.TargetCategory.INFANTRY

@export_range(0.0, 100000.0, 1.0, "or_greater")
var base_damage: float = 10.0

@export_range(0.01, 3600.0, 0.01, "or_greater")
var reload_seconds: float = 1.0

@export_range(0.0, 100000.0, 1.0, "or_greater")
var minimum_range: float = 0.0

@export_range(0.01, 100000.0, 1.0, "or_greater")
var maximum_range: float = 100.0

@export_range(0.0, 100000.0, 1.0, "or_greater")
var splash_radius: float = 0.0

@export_range(0.0, 100000.0, 1.0, "or_greater")
var projectile_speed: float = 0.0


func validate() -> bool:
	var is_valid: bool = super.validate()
	var context: StringName = get_validation_context()

	is_valid = DawnfallLog.require_valid(
		valid_target_categories != 0,
		"Weapons require at least one valid target category.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		base_damage >= 0.0,
		"Weapon damage cannot be negative.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		reload_seconds > 0.0,
		"Weapon reload time must be above zero.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		maximum_range > 0.0 and minimum_range <= maximum_range,
		"Weapon range must be positive and minimum cannot exceed maximum.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		splash_radius >= 0.0,
		"Weapon splash radius cannot be negative.",
		context
	) and is_valid

	var requires_projectile_speed: bool = delivery_type in [
		DeliveryType.PROJECTILE,
		DeliveryType.BOMB,
		DeliveryType.TORPEDO,
	]

	if requires_projectile_speed:
		is_valid = DawnfallLog.require_valid(
			projectile_speed > 0.0,
			"This delivery type requires projectile speed above zero.",
			context
		) and is_valid

	return is_valid

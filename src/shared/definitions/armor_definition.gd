class_name ArmorDefinition
extends GameDefinition


enum ArmorClass {
	SOFT,
	LIGHT,
	MEDIUM,
	HEAVY,
	FORTIFIED,
}

@export_group("Armor")

@export var armor_class: ArmorClass = ArmorClass.SOFT

@export_range(0.0, 1000.0, 1.0, "or_greater")
var front_armor: float = 0.0

@export_range(0.0, 1000.0, 1.0, "or_greater")
var side_armor: float = 0.0

@export_range(0.0, 1000.0, 1.0, "or_greater")
var rear_armor: float = 0.0

@export_range(0.0, 1000.0, 1.0, "or_greater")
var top_armor: float = 0.0


func validate() -> bool:
	var is_valid: bool = super.validate()
	var context: StringName = get_validation_context()

	for armor_value: float in [
		front_armor,
		side_armor,
		rear_armor,
		top_armor,
	]:
		is_valid = DawnfallLog.require_valid(
			armor_value >= 0.0,
			"Armor values cannot be negative.",
			context
		) and is_valid

	return is_valid

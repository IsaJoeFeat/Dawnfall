class_name UnitDefinition
extends GameDefinition


enum Faction {
	NEUTRAL,
	ALLIES,
	AXIS,
}

enum UnitRole {
	COMMAND,
	ENGINEER,
	INFANTRY,
	RECON,
	ANTI_ARMOR,
	ARMOR,
	ARTILLERY,
	ANTI_AIR,
	AIRCRAFT,
	NAVAL,
	SUPPORT,
	STRUCTURE,
}

@export_group("Classification")

@export var faction: Faction = Faction.NEUTRAL
@export var role: UnitRole = UnitRole.INFANTRY

@export_flags("Infantry", "Vehicle", "Aircraft", "Naval", "Structure")
var target_categories: int = CombatTypes.TargetCategory.INFANTRY

@export_range(1, 3, 1)
var tech_level: int = 1


@export_group("Simulation")

@export_range(1.0, 100000.0, 1.0, "or_greater")
var max_health: float = 100.0

@export_range(0.05, 100.0, 0.05, "or_greater")
var collision_radius: float = 0.5

@export_range(0.05, 100.0, 0.05, "or_greater")
var selection_radius: float = 0.5

@export_range(0.0, 100000.0, 1.0, "or_greater")
var vision_range: float = 300.0

@export var movement_profile: MovementDefinition
@export var armor_profile: ArmorDefinition
@export var weapons: Array[WeaponDefinition] = []


@export_group("Production")

@export var is_buildable: bool = true

@export_range(0.0, 1000000.0, 1.0, "or_greater")
var steel_cost: float = 0.0

@export_range(0.0, 1000000.0, 1.0, "or_greater")
var supply_cost: float = 0.0

@export_range(0.0, 100000.0, 0.1, "or_greater")
var build_seconds: float = 1.0


func validate() -> bool:
	var is_valid: bool = super.validate()
	var context: StringName = get_validation_context()

	is_valid = DawnfallLog.require_valid(
		max_health > 0.0,
		"Maximum health must be greater than zero.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		collision_radius > 0.0,
		"Collision radius must be greater than zero.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		selection_radius > 0.0,
		"Selection radius must be greater than zero.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		vision_range >= 0.0,
		"Vision range cannot be negative.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		target_categories != 0,
		"Units require at least one target category.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		movement_profile != null,
		"A movement profile is required.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		armor_profile != null,
		"An armor profile is required.",
		context
	) and is_valid

	for weapon: WeaponDefinition in weapons:
		is_valid = DawnfallLog.require_valid(
			weapon != null,
			"Weapon references cannot be null.",
			context
		) and is_valid

	is_valid = DawnfallLog.require_valid(
		steel_cost >= 0.0 and supply_cost >= 0.0,
		"Steel and Supply costs cannot be negative.",
		context
	) and is_valid

	if is_buildable:
		is_valid = DawnfallLog.require_valid(
			build_seconds > 0.0,
			"Buildable units require build time above zero.",
			context
		) and is_valid
	else:
		is_valid = DawnfallLog.require_valid(
			build_seconds >= 0.0,
			"Build time cannot be negative.",
			context
		) and is_valid

	return is_valid

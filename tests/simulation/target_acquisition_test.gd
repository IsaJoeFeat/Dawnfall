extends Node


func _ready() -> void:
	var world := SimulationWorld.new()

	assert(
		world.set_owner_team(0, 0),
		"Owner 0 should join team 0."
	)

	assert(
		world.set_owner_team(1, 0),
		"Owner 1 should join team 0."
	)

	assert(
		world.set_owner_team(2, 1),
		"Owner 2 should join team 1."
	)

	var movement := MovementDefinition.new()

	movement.definition_id = &"target_test_move"
	movement.display_name = "Target Test Movement"
	movement.max_speed = 5.0
	movement.acceleration = 5.0
	movement.deceleration = 5.0
	movement.turn_speed_degrees = 180.0

	var armor := ArmorDefinition.new()

	armor.definition_id = &"target_test_armor"
	armor.display_name = "Target Test Armor"

	var rifle := WeaponDefinition.new()

	rifle.definition_id = &"target_test_rifle"
	rifle.display_name = "Infantry Rifle"

	rifle.delivery_type = (
		WeaponDefinition.DeliveryType.HITSCAN
	)

	rifle.valid_target_categories = (
		CombatTypes.TargetCategory.INFANTRY
	)

	rifle.base_damage = 10.0
	rifle.reload_seconds = 1.0
	rifle.maximum_range = 100.0

	var anti_vehicle_weapon := WeaponDefinition.new()

	anti_vehicle_weapon.definition_id = (
		&"target_test_at"
	)

	anti_vehicle_weapon.display_name = (
		"Anti Vehicle Test Weapon"
	)

	anti_vehicle_weapon.delivery_type = (
		WeaponDefinition.DeliveryType.HITSCAN
	)

	anti_vehicle_weapon.valid_target_categories = (
		CombatTypes.TargetCategory.VEHICLE
	)

	anti_vehicle_weapon.base_damage = 10.0
	anti_vehicle_weapon.reload_seconds = 1.0
	anti_vehicle_weapon.maximum_range = 100.0

	var attacker_definition := UnitDefinition.new()

	attacker_definition.definition_id = (
		&"target_test_attacker"
	)

	attacker_definition.display_name = (
		"Target Test Attacker"
	)

	attacker_definition.movement_profile = movement
	attacker_definition.armor_profile = armor
	attacker_definition.weapons = [
		rifle,
		anti_vehicle_weapon,
	]

	var infantry_definition := UnitDefinition.new()

	infantry_definition.definition_id = (
		&"target_test_infantry"
	)

	infantry_definition.display_name = (
		"Target Test Infantry"
	)

	infantry_definition.target_categories = (
		CombatTypes.TargetCategory.INFANTRY
	)

	infantry_definition.movement_profile = movement
	infantry_definition.armor_profile = armor

	var vehicle_definition := UnitDefinition.new()

	vehicle_definition.definition_id = (
		&"target_test_vehicle"
	)

	vehicle_definition.display_name = (
		"Target Test Vehicle"
	)

	vehicle_definition.target_categories = (
		CombatTypes.TargetCategory.VEHICLE
	)

	vehicle_definition.movement_profile = movement
	vehicle_definition.armor_profile = armor

	var attacker_id: int = world.spawn_unit(
		attacker_definition,
		0,
		0,
		Vector3.ZERO
	)

	# Closest unit, but it's an ally.
	var ally_infantry_id: int = world.spawn_unit(
		infantry_definition,
		1,
		1,
		Vector3(5.0, 0.0, 0.0)
	)

	# Closest enemy, but wrong category for rifle.
	var enemy_vehicle_id: int = world.spawn_unit(
		vehicle_definition,
		2,
		2,
		Vector3(8.0, 0.0, 0.0)
	)

	var near_enemy_infantry_id: int = (
		world.spawn_unit(
			infantry_definition,
			1,
			2,
			Vector3(
				20.0,
				0.0,
				0.0
			)
		)
	)

	var far_enemy_infantry_id: int = (
		world.spawn_unit(
			infantry_definition,
			1,
			2,
			Vector3(
				40.0,
				0.0,
				0.0
			)
		)
	)

	# Enemy but outside both weapons' range.
	world.spawn_unit(
		infantry_definition,
		1,
		2,
		Vector3(
			150.0,
			0.0,
			0.0
		)
	)

	assert(
		EntityId.is_valid(attacker_id)
		and EntityId.is_valid(
			ally_infantry_id
		)
		and EntityId.is_valid(
			enemy_vehicle_id
		)
		and EntityId.is_valid(
			near_enemy_infantry_id
		)
		and EntityId.is_valid(
			far_enemy_infantry_id
		),
		"Target acquisition test entities should spawn."
	)

	world.rebuild_spatial_grid()

	var rifle_target: int = (
		world.acquire_target_for_weapon(
			attacker_id,
			0
		)
	)

	assert(
		rifle_target
		== near_enemy_infantry_id,
		(
			"Rifle should ignore ally and vehicle "
			+ "and choose nearest enemy infantry."
		)
	)

	var anti_vehicle_target: int = (
		world.acquire_target_for_weapon(
			attacker_id,
			1
		)
	)

	assert(
		anti_vehicle_target
		== enemy_vehicle_id,
		"Anti-vehicle weapon should choose enemy vehicle."
	)

	# Kill the nearest valid infantry target.
	world.apply_damage(
		near_enemy_infantry_id,
		1000.0
	)

	world.rebuild_spatial_grid()

	var replacement_target: int = (
		world.acquire_target_for_weapon(
			attacker_id,
			0
		)
	)

	assert(
		replacement_target
		== far_enemy_infantry_id,
		(
			"Rifle should automatically acquire "
			+ "the next valid living infantry target."
		)
	)

	print(
		(
			"TARGET ACQUISITION PASS | "
			+ "ally ignored | "
			+ "category filtering PASS | "
			+ "nearest hostile PASS | "
			+ "dead target replacement PASS"
		)
	)

extends Node


func _ready() -> void:
	var world := SimulationWorld.new()

	world.automatic_combat_enabled = true

	assert(world.set_owner_team(0, 0))
	assert(world.set_owner_team(1, 1))

	var movement := MovementDefinition.new()

	movement.definition_id = &"auto_combat_move"
	movement.display_name = "Auto Combat Movement"
	movement.max_speed = 5.0
	movement.acceleration = 5.0
	movement.deceleration = 5.0
	movement.turn_speed_degrees = 180.0

	var armor := ArmorDefinition.new()

	armor.definition_id = &"auto_combat_armor"
	armor.display_name = "Auto Combat Armor"

	var rifle := WeaponDefinition.new()

	rifle.definition_id = &"auto_combat_rifle"
	rifle.display_name = "Auto Combat Rifle"

	rifle.delivery_type = (
		WeaponDefinition.DeliveryType.HITSCAN
	)

	rifle.valid_target_categories = (
		CombatTypes.TargetCategory.INFANTRY
	)

	rifle.base_damage = 25.0
	rifle.reload_seconds = 0.10
	rifle.maximum_range = 100.0

	var attacker_definition := UnitDefinition.new()

	attacker_definition.definition_id = (
		&"auto_combat_attacker"
	)

	attacker_definition.display_name = (
		"Auto Combat Attacker"
	)

	attacker_definition.target_categories = (
		CombatTypes.TargetCategory.INFANTRY
	)

	attacker_definition.movement_profile = movement
	attacker_definition.armor_profile = armor
	attacker_definition.weapons = [
		rifle
	]

	var target_definition := UnitDefinition.new()

	target_definition.definition_id = (
		&"auto_combat_target"
	)

	target_definition.display_name = (
		"Auto Combat Target"
	)

	target_definition.target_categories = (
		CombatTypes.TargetCategory.INFANTRY
	)

	target_definition.max_health = 100.0
	target_definition.movement_profile = movement
	target_definition.armor_profile = armor

	var attacker_id: int = world.spawn_unit(
		attacker_definition,
		0,
		0,
		Vector3.ZERO
	)

	var target_id: int = world.spawn_unit(
		target_definition,
		1,
		1,
		Vector3(
			20.0,
			0.0,
			0.0
		)
	)

	assert(
		EntityId.is_valid(attacker_id)
		and EntityId.is_valid(target_id),
		"Automatic combat entities should spawn."
	)

	world.rebuild_spatial_grid()

	var target_index: int = (
		world.entities.get_index_if_alive(
			target_id
		)
	)

	# Tick 1:
	# attacker index 0 gets acquisition phase 0,
	# finds the enemy, and immediately fires.
	world.advance(
		world.clock.tick_seconds
	)

	assert(
		world.entities.is_alive(
			target_id
		),
		"Target should survive the first shot."
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				target_index
			],
			75.0
		),
		"First automatic shot should leave 75 HP."
	)

	assert(
		world.last_auto_target_acquisition_count == 1,
		"Attacker should automatically acquire one target."
	)

	assert(
		world.last_auto_fire_count == 1,
		"Attacker should automatically fire once."
	)

	# Tick 2: still reloading.
	world.advance(
		world.clock.tick_seconds
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				target_index
			],
			75.0
		),
		"Reload tick must not deal damage."
	)

	# Continue until the target dies.
	var safety_ticks: int = 20

	while (
		world.entities.is_alive(target_id)
		and safety_ticks > 0
	):
		world.advance(
			world.clock.tick_seconds
		)

		safety_ticks -= 1

	assert(
		not world.entities.is_alive(
			target_id
		),
		"Automatic combat should eventually destroy the target."
	)

	assert(
		world.entities.alive_count() == 1,
		"Only the attacker should remain alive."
	)

	# One more tick verifies the attacker safely drops
	# its now-dead retained target.
	world.advance(
		world.clock.tick_seconds
	)

	print(
		(
			"AUTOMATIC COMBAT PASS | "
			+ "acquired hostile | "
			+ "auto-fired | "
			+ "reload respected | "
			+ "target destroyed | "
			+ "dead target released"
		)
	)

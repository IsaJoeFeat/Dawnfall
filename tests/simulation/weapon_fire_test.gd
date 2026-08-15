extends Node


func _ready() -> void:
	var world := SimulationWorld.new()

	var movement := MovementDefinition.new()

	movement.definition_id = (
		&"movement_test_combat"
	)
	movement.display_name = (
		"Combat Test Movement"
	)
	movement.max_speed = 5.0
	movement.acceleration = 5.0
	movement.deceleration = 5.0
	movement.turn_speed_degrees = 180.0

	var armor := ArmorDefinition.new()

	armor.definition_id = (
		&"armor_test_combat"
	)
	armor.display_name = (
		"Combat Test Armor"
	)

	var weapon := WeaponDefinition.new()

	weapon.definition_id = (
		&"weapon_test_rifle"
	)
	weapon.display_name = (
		"Test Rifle"
	)

	weapon.delivery_type = (
		WeaponDefinition.DeliveryType.HITSCAN
	)

	weapon.base_damage = 40.0
	weapon.reload_seconds = 0.10
	weapon.minimum_range = 0.0
	weapon.maximum_range = 100.0

	var attacker_definition := (
		UnitDefinition.new()
	)

	attacker_definition.definition_id = (
		&"unit_test_attacker"
	)

	attacker_definition.display_name = (
		"Test Attacker"
	)

	attacker_definition.max_health = 100.0
	attacker_definition.movement_profile = movement
	attacker_definition.armor_profile = armor
	attacker_definition.weapons = [
		weapon
	]

	var target_definition := (
		UnitDefinition.new()
	)

	target_definition.definition_id = (
		&"unit_test_target"
	)

	target_definition.display_name = (
		"Test Target"
	)

	target_definition.max_health = 100.0
	target_definition.movement_profile = movement
	target_definition.armor_profile = armor

	var attacker_id: int = (
		world.spawn_unit(
			attacker_definition,
			0,
			0,
			Vector3.ZERO
		)
	)

	var target_id: int = (
		world.spawn_unit(
			target_definition,
			1,
			1,
			Vector3(
				20.0,
				0.0,
				0.0
			)
		)
	)

	assert(
		EntityId.is_valid(
			attacker_id
		)
		and EntityId.is_valid(
			target_id
		),
		"Combat test entities should spawn."
	)

	var target_index: int = (
		world.entities.get_index_if_alive(
			target_id
		)
	)

	# Shot 1: 100 -> 60.
	var first_shot: int = (
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
	)

	assert(
		first_shot
		== CombatSystem.FireResult.FIRED,
		"First shot should fire."
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				target_index
			],
			60.0
		),
		"First shot should leave target at 60 HP."
	)

	# Immediate second shot must be blocked.
	var immediate_second_shot: int = (
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
	)

	assert(
		immediate_second_shot
		== CombatSystem.FireResult.RELOADING,
		"Weapon should not fire again immediately."
	)

	# 0.10 seconds = two 20 Hz simulation ticks.
	world.advance(
		world.clock.tick_seconds
	)

	assert(
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
		== CombatSystem.FireResult.RELOADING,
		"Weapon should still reload after one tick."
	)

	world.advance(
		world.clock.tick_seconds
	)

	# Shot 2: 60 -> 20.
	assert(
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
		== CombatSystem.FireResult.FIRED,
		"Weapon should fire after its reload completes."
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				target_index
			],
			20.0
		),
		"Second shot should leave target at 20 HP."
	)

	# Finish another reload.
	world.advance(
		world.clock.tick_seconds
	)

	world.advance(
		world.clock.tick_seconds
	)

	# Out-of-range attempts must not consume the shot.
	assert(
		world.entities.set_position(
			target_id,
			Vector3(
				200.0,
				0.0,
				0.0
			)
		),
		"Target should move for range test."
	)

	assert(
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
		== CombatSystem.FireResult.OUT_OF_RANGE,
		"Weapon should reject an out-of-range target."
	)

	assert(
		world.entities.set_position(
			target_id,
			Vector3(
				20.0,
				0.0,
				0.0
			)
		),
		"Target should return to valid range."
	)

	# Shot 3: 20 -> destroyed.
	assert(
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
		== CombatSystem.FireResult.FIRED,
		"Ready weapon should still fire after an out-of-range attempt."
	)

	assert(
		not world.entities.is_alive(
			target_id
		),
		"Third shot should destroy the target."
	)

	assert(
		world.entities.alive_count() == 1,
		"Only the attacker should remain alive."
	)

	assert(
		world.fire_weapon(
			attacker_id,
			target_id,
			0
		)
		== CombatSystem.FireResult.INVALID,
		"Dead targets cannot be fired upon."
	)

	print(
		(
			"WEAPON FIRE PASS | "
			+ "40 damage | "
			+ "0.10 sec reload = 2 ticks | "
			+ "100 -> 60 -> 20 -> destroyed | "
			+ "range rejection PASS"
		)
	)

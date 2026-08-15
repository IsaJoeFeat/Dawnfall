extends Node


func _ready() -> void:
	var world := SimulationWorld.new()

	var entity_id: int = (
		world.entities.create_entity(
			0,
			0,
			Vector3.ZERO,
			100.0,
			0.5,
			10.0,
			50.0,
			50.0,
			deg_to_rad(360.0),
			0.0
		)
	)

	assert(
		EntityId.is_valid(entity_id),
		"Combat test entity should spawn."
	)

	assert(
		world.entities.alive_count() == 1,
		"Combat test should begin with one living entity."
	)

	world.rebuild_spatial_grid()

	var entity_index: int = (
		world.entities.get_index_if_alive(
			entity_id
		)
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				entity_index
			],
			100.0
		),
		"Entity should begin at full health."
	)

	var first_result: int = (
		world.apply_damage(
			entity_id,
			25.0
		)
	)

	assert(
		first_result
		== CombatSystem.DamageResult.DAMAGED,
		"Nonlethal damage should report DAMAGED."
	)

	assert(
		is_equal_approx(
			world.entities.current_health[
				entity_index
			],
			75.0
		),
		"25 damage should leave 75 HP."
	)

	assert(
		world.entities.is_alive(
			entity_id
		),
		"Nonlethal damage must not destroy the entity."
	)

	var zero_result: int = (
		world.apply_damage(
			entity_id,
			0.0
		)
	)

	assert(
		zero_result
		== CombatSystem.DamageResult.NO_EFFECT,
		"Zero damage should report NO_EFFECT."
	)

	var lethal_result: int = (
		world.apply_damage(
			entity_id,
			1000.0
		)
	)

	assert(
		lethal_result
		== CombatSystem.DamageResult.DESTROYED,
		"Lethal damage should report DESTROYED."
	)

	assert(
		not world.entities.is_alive(
			entity_id
		),
		"Lethally damaged entity must be dead."
	)

	assert(
		world.entities.alive_count() == 0,
		"World should contain no living entities after death."
	)

	# A normal simulation tick rebuilds the spatial
	# index and must remove the dead entity from it.
	world.advance(
		world.clock.tick_seconds
	)

	assert(
		world.spatial_grid.indexed_entity_count() == 0,
		"Dead entity must disappear from the spatial grid."
	)

	var dead_target_result: int = (
		world.apply_damage(
			entity_id,
			10.0
		)
	)

	assert(
		dead_target_result
		== CombatSystem.DamageResult.INVALID,
		"An already-dead entity cannot take more damage."
	)

	print(
		(
			"COMBAT DAMAGE LIFECYCLE PASS | "
			+ "100 HP -> 75 HP -> destroyed | "
			+ "alive count %d | "
			+ "spatial count %d"
		)
		% [
			world.entities.alive_count(),
			world.spatial_grid.indexed_entity_count(),
		]
	)

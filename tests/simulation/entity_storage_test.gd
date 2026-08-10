extends Node


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const TARGET_ENTITY_COUNT: int = 8000
const COMMANDED_ENTITY_COUNT: int = 2000
const SIMULATION_TICKS: int = 20


func _ready() -> void:
	var registry := DefinitionRegistry.new()

	if not CONTENT_CATALOG.load_into(registry):
		get_tree().quit(1)
		return

	var infantry: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_infantry"
	)
	var tank: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_tank"
	)

	if infantry == null or tank == null:
		push_error("Required test definitions were not loaded.")
		get_tree().quit(1)
		return

	var world := SimulationWorld.new()
	var entity_ids := PackedInt64Array()
	var creation_start: int = Time.get_ticks_usec()

	for index: int in range(TARGET_ENTITY_COUNT):
		var definition: UnitDefinition
		var definition_index: int

		if index % 2 == 0:
			definition = infantry
			definition_index = 0
		else:
			definition = tank
			definition_index = 1

		var column: int = index % 100
		var row: int = floori(float(index) / 100.0)

		var position := Vector3(
			float(column) * 2.0,
			0.0,
			float(row) * 2.0
		)

		var entity_id: int = world.spawn_unit(
			definition,
			definition_index,
			index % 4,
			position
		)

		entity_ids.append(entity_id)

	var creation_microseconds: int = (
		Time.get_ticks_usec() - creation_start
	)

	assert(
		world.entities.alive_count() == TARGET_ENTITY_COUNT,
		"Expected 8,000 live entities."
	)
	assert(
		world.entities.capacity() == TARGET_ENTITY_COUNT,
		"Expected an 8,000-slot entity capacity."
	)

	var stale_id: int = entity_ids[0]
	var stale_index: int = EntityId.get_index(stale_id)

	assert(
		world.entities.destroy_entity(stale_id),
		"The first entity should be destroyable."
	)
	assert(
		not world.entities.is_alive(stale_id),
		"A destroyed ID must become stale."
	)

	var replacement_id: int = world.spawn_unit(
		infantry,
		0,
		0,
		Vector3.ZERO
	)

	assert(
		EntityId.get_index(replacement_id) == stale_index,
		"The free entity slot should be reused."
	)
	assert(
		EntityId.get_generation(replacement_id)
		!= EntityId.get_generation(stale_id),
		"A reused slot must receive a new generation."
	)
	assert(
		not world.entities.is_alive(stale_id),
		"The stale ID must not control the replacement."
	)

	var commanded_ids := PackedInt64Array()

	for index: int in range(1, COMMANDED_ENTITY_COUNT + 1):
		commanded_ids.append(entity_ids[index])

	var first_commanded_id: int = commanded_ids[0]
	var initial_position: Vector3 = world.entities.get_position(
		first_commanded_id
	)

	var accepted_commands: int = world.issue_move(
		commanded_ids,
		Vector3(250.0, 0.0, 250.0)
	)

	assert(
		accepted_commands == COMMANDED_ENTITY_COUNT,
		"Expected all 2,000 mobile units to accept the move command."
	)

	var simulation_start: int = Time.get_ticks_usec()
	var simulated_steps: int = 0

	for _frame: int in range(SIMULATION_TICKS):
		simulated_steps += world.advance(0.05)

	var simulation_microseconds: int = (
		Time.get_ticks_usec() - simulation_start
	)

	assert(
		simulated_steps == SIMULATION_TICKS,
		"Expected twenty fixed simulation ticks."
	)
	assert(
		world.clock.tick_count == SIMULATION_TICKS,
		"The fixed clock should report twenty completed ticks."
	)

	var final_position: Vector3 = world.entities.get_position(
		first_commanded_id
	)

	assert(
		final_position.distance_to(initial_position) > 0.1,
		"The commanded unit should have moved."
	)

	var creation_milliseconds: float = (
		float(creation_microseconds) / 1000.0
	)
	var simulation_milliseconds: float = (
		float(simulation_microseconds) / 1000.0
	)

	print(
		(
			"Entity movement test passed: "
			+ "%d alive, %d commanded, %d ticks, "
			+ "%.2f ms creation, %.2f ms simulation."
		)
		% [
			world.entities.alive_count(),
			accepted_commands,
			simulated_steps,
			creation_milliseconds,
			simulation_milliseconds,
		]
	)

	get_tree().quit(0)

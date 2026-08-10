extends Node


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const ENTITY_COUNT: int = 8000
const COMMANDED_COUNT: int = 2000
const QUERY_ITERATIONS: int = 1000
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

	for index: int in range(ENTITY_COUNT):
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

		var entity_id: int = world.spawn_unit(
			definition,
			definition_index,
			index % 4,
			Vector3(
				float(column) * 2.0,
				0.0,
				float(row) * 2.0
			)
		)

		entity_ids.append(entity_id)

	var rebuild_start: int = Time.get_ticks_usec()
	world.rebuild_spatial_grid()
	var rebuild_microseconds: int = (
		Time.get_ticks_usec() - rebuild_start
	)

	assert(
		world.spatial_grid.indexed_entity_count() == ENTITY_COUNT,
		"The spatial grid should contain all 8,000 entities."
	)
	assert(
		world.spatial_grid.cell_count() > 0,
		"The spatial grid should contain occupied cells."
	)
	assert(
		world.spatial_grid.maximum_bucket_size() <= 16,
		"Eight-meter cells should contain at most sixteen test entities."
	)

	var nearby_entities: PackedInt32Array = (
		world.query_entities_in_radius(
			Vector3(10.0, 0.0, 10.0),
			3.0
		)
	)

	assert(
		nearby_entities.size() == 9,
		"A three-meter query should find the surrounding nine entities."
	)

	var owner_one_entities: PackedInt32Array = (
		world.query_entities_in_radius(
			Vector3(10.0, 0.0, 10.0),
			3.0,
			1
		)
	)

	assert(
		owner_one_entities.size() == 3,
		"The filtered query should find three owner-one entities."
	)

	var empty_query: PackedInt32Array = (
		world.query_entities_in_radius(
			Vector3(-1000.0, 0.0, -1000.0),
			10.0
		)
	)

	assert(
		empty_query.is_empty(),
		"An empty region should return no entities."
	)

	var query_start: int = Time.get_ticks_usec()
	var total_query_results: int = 0

	for query_index: int in range(QUERY_ITERATIONS):
		var sample_index: int = query_index % ENTITY_COUNT
		var sample_column: int = sample_index % 100
		var sample_row: int = floori(
			float(sample_index) / 100.0
		)
		var query_center := Vector3(
			float(sample_column) * 2.0,
			0.0,
			float(sample_row) * 2.0
		)

		total_query_results += world.query_entities_in_radius(
			query_center,
			10.0
		).size()

	var query_microseconds: int = (
		Time.get_ticks_usec() - query_start
	)

	assert(
		total_query_results > 0,
		"The repeated spatial queries should find entities."
	)

	var commanded_ids := PackedInt64Array()

	for index: int in range(COMMANDED_COUNT):
		commanded_ids.append(entity_ids[index])

	var first_commanded_id: int = commanded_ids[0]
	var initial_position: Vector3 = world.entities.get_position(
		first_commanded_id
	)

	assert(
		world.issue_move(
			commanded_ids,
			Vector3(250.0, 0.0, 250.0)
		) == COMMANDED_COUNT,
		"All 2,000 selected entities should accept movement."
	)

	var simulation_start: int = Time.get_ticks_usec()

	for _frame: int in range(SIMULATION_TICKS):
		world.advance(0.05)

	var simulation_microseconds: int = (
		Time.get_ticks_usec() - simulation_start
	)

	var final_position: Vector3 = world.entities.get_position(
		first_commanded_id
	)

	assert(
		final_position.distance_to(initial_position) > 0.1,
		"The commanded entity should move."
	)

	var moved_entity_index: int = EntityId.get_index(
		first_commanded_id
	)
	var entities_at_final_position: PackedInt32Array = (
		world.query_entities_in_radius(
			final_position,
			0.1
		)
	)

	assert(
		entities_at_final_position.has(moved_entity_index),
		"The rebuilt grid should contain the entity at its new position."
	)

	print(
		(
			"Spatial grid test passed: "
			+ "%d indexed, %d cells, max bucket %d, "
			+ "%d queries in %.2f ms, "
			+ "%d movement/grid ticks in %.2f ms, "
			+ "initial rebuild %.2f ms."
		)
		% [
			world.spatial_grid.indexed_entity_count(),
			world.spatial_grid.cell_count(),
			world.spatial_grid.maximum_bucket_size(),
			QUERY_ITERATIONS,
			float(query_microseconds) / 1000.0,
			SIMULATION_TICKS,
			float(simulation_microseconds) / 1000.0,
			float(rebuild_microseconds) / 1000.0,
		]
	)

	get_tree().quit(0)

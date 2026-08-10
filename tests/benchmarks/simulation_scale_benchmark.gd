extends Node


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

@export_range(1000, 8000, 1000)
var entity_count: int = 8000

const MAX_COMMANDED_ENTITIES: int = 2000
const QUERY_ITERATIONS: int = 1000
const BENCHMARK_TICKS: int = 20


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
		push_error("Required benchmark definitions were not loaded.")
		get_tree().quit(1)
		return

	print("Beginning Dawnfall simulation scale benchmark.")

	print("Starting scale: %d entities." % entity_count)
	_run_scenario(entity_count, infantry, tank)

	print("Simulation scale benchmark passed.")
	get_tree().quit(0)


func _run_scenario(
	entity_count: int,
	infantry: UnitDefinition,
	tank: UnitDefinition
) -> void:
	var world := SimulationWorld.new()
	var entity_ids := PackedInt64Array()
	var spawn_start: int = Time.get_ticks_usec()

	print("  Stage 1: spawning entities...")

	for index: int in range(entity_count):
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

		assert(
			EntityId.is_valid(entity_id),
			"Every benchmark entity should spawn successfully."
		)

		entity_ids.append(entity_id)

	print("  Stage 1 complete.")

	var spawn_microseconds: int = (
		Time.get_ticks_usec() - spawn_start
	)

	assert(
		world.entities.alive_count() == entity_count,
		"The scenario should contain the requested entity count."
	)

	print("  Stage 2: building grid...")

	var grid_start: int = Time.get_ticks_usec()
	world.rebuild_spatial_grid()
	var grid_microseconds: int = (
		Time.get_ticks_usec() - grid_start
	)

	print("  Stage 2 complete.")

	assert(
		world.spatial_grid.indexed_entity_count() == entity_count,
		"The initial grid should index every entity."
	)

	print("  Stage 3: running queries...")

	var query_start: int = Time.get_ticks_usec()
	var total_query_results: int = 0

	for query_index: int in range(QUERY_ITERATIONS):
		var sample_index: int = query_index % entity_count
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

	print("  Stage 3 complete.")

	var query_microseconds: int = (
		Time.get_ticks_usec() - query_start
	)

	assert(
		total_query_results > 0,
		"Benchmark spatial queries should find entities."
	)

	var commanded_count: int = mini(
		entity_count,
		MAX_COMMANDED_ENTITIES
	)
	var commanded_ids := PackedInt64Array()

	for index: int in range(commanded_count):
		commanded_ids.append(entity_ids[index])

	print("  Stage 4: dispatching commands...")

	var command_start: int = Time.get_ticks_usec()
	var accepted_commands: int = world.issue_move(
		commanded_ids,
		Vector3(250.0, 0.0, 250.0)
	)
	var command_microseconds: int = (
		Time.get_ticks_usec() - command_start
	)

	print("  Stage 4 complete.")

	assert(
		accepted_commands == commanded_count,
		"Every benchmark movement command should be accepted."
	)

	print("  Stage 5: simulating ticks...")

	var simulation_start: int = Time.get_ticks_usec()
	var completed_ticks: int = 0

	for tick_index: int in range(BENCHMARK_TICKS):
		completed_ticks += world.advance(0.05)

		if (tick_index + 1) % 5 == 0:
			print(
				"    Completed %d ticks."
				% (tick_index + 1)
			)

	print("  Stage 5 complete.")

	var simulation_microseconds: int = (
		Time.get_ticks_usec() - simulation_start
	)

	assert(
		completed_ticks == BENCHMARK_TICKS,
		"Every benchmark simulation tick should complete."
	)
	assert(
		world.spatial_grid.indexed_entity_count() == entity_count,
		"The final grid should still index every entity."
	)

	print("  Stage 6: calculating and printing results...")

	var spawn_milliseconds: float = (
		float(spawn_microseconds) / 1000.0
	)
	var grid_milliseconds: float = (
		float(grid_microseconds) / 1000.0
	)
	var query_milliseconds: float = (
		float(query_microseconds) / 1000.0
	)
	var command_milliseconds: float = (
		float(command_microseconds) / 1000.0
	)
	var simulation_milliseconds: float = (
		float(simulation_microseconds) / 1000.0
	)
	var average_tick_milliseconds: float = (
		simulation_milliseconds / float(BENCHMARK_TICKS)
	)

	print(
		(
			"SCALE %d | spawn %.2f ms | grid %.2f ms | "
			+ "1000 queries %.2f ms | command %d in %.2f ms | "
			+ "20 ticks %.2f ms | average tick %.2f ms | "
			+ "final cells %d | max bucket %d"
		)
		% [
			entity_count,
			spawn_milliseconds,
			grid_milliseconds,
			query_milliseconds,
			commanded_count,
			command_milliseconds,
			simulation_milliseconds,
			average_tick_milliseconds,
			world.spatial_grid.cell_count(),
			world.spatial_grid.maximum_bucket_size(),
		]
	)

	print("  Stage 6 complete.")
	print("  Stage 7: clearing scenario data...")

	entity_ids.clear()
	commanded_ids.clear()
	world.spatial_grid.clear()
	world.entities.clear()

	print("  Stage 7 complete.")

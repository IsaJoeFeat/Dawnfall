extends Node


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const TOTAL_ENTITY_COUNT: int = 8000
const PLAYER_COUNT: int = 4
const ENTITIES_PER_PLAYER: int = 2000

const FORMATION_COLUMNS: int = 50
const FORMATION_SPACING: float = 2.0

const WORLD_SIZE := Vector2(
	1024.0,
	1024.0
)

const NAVIGATION_CELL_SIZE: float = 4.0

const WALL_COLUMN: int = 128
const GAP_START_ROW: int = 135
const GAP_END_ROW: int = 195

const BENCHMARK_TICKS: int = 20


func _ready() -> void:
	var registry := DefinitionRegistry.new()

	if not CONTENT_CATALOG.load_into(
		registry
	):
		get_tree().quit(1)
		return

	var infantry: UnitDefinition = (
		registry.get_unit(
			&"unit_test_placeholder_infantry"
		)
	)

	var tank: UnitDefinition = (
		registry.get_unit(
			&"unit_test_placeholder_tank"
		)
	)

	if infantry == null or tank == null:
		push_error(
			"Required benchmark definitions were not loaded."
		)
		get_tree().quit(1)
		return

	print(
		"Beginning Dawnfall navigation scale benchmark."
	)

	_run_benchmark(
		infantry,
		tank
	)

	print(
		"Navigation scale benchmark passed."
	)

	get_tree().quit(0)


func _run_benchmark(
	infantry: UnitDefinition,
	tank: UnitDefinition
) -> void:
	var world := SimulationWorld.new()

	world.configure_navigation(
		Vector3.ZERO,
		WORLD_SIZE,
		NAVIGATION_CELL_SIZE
	)

	var navigation_grid: NavigationGrid = (
		world.navigation_grid
	)

	_build_navigation_wall(
		world,
		navigation_grid
	)

	var player_centers: Array[Vector3] = [
		Vector3(
			220.0,
			0.0,
			300.0
		),
		Vector3(
			220.0,
			0.0,
			800.0
		),
		Vector3(
			800.0,
			0.0,
			800.0
		),
		Vector3(
			800.0,
			0.0,
			500.0
		),
	]

	var commanded_start_center: Vector3 = (
		player_centers[0]
	)

	var commanded_destination_center := Vector3(
		820.0,
		0.0,
		300.0
	)

	assert(
		not navigation_grid.is_segment_traversable(
			commanded_start_center,
			commanded_destination_center
		),
		"Commanded group should require an indirect route."
	)

	var commanded_ids := PackedInt64Array()
	var commanded_destinations := PackedVector3Array()

	var spawn_start: int = (
		Time.get_ticks_usec()
	)

	print(
		"  Stage 1: spawning 8000 entities..."
	)

	for player_index: int in range(
		PLAYER_COUNT
	):
		var player_center: Vector3 = (
			player_centers[
				player_index
			]
		)

		for local_index: int in range(
			ENTITIES_PER_PLAYER
		):
			var definition: UnitDefinition
			var definition_index: int

			if local_index % 2 == 0:
				definition = infantry
				definition_index = 0
			else:
				definition = tank
				definition_index = 1

			var formation_offset: Vector3 = (
				_get_formation_offset(
					local_index
				)
			)

			var spawn_position: Vector3 = (
				player_center
				+ formation_offset
			)

			assert(
				navigation_grid.is_world_position_traversable(
					spawn_position
				),
				"Benchmark entity must spawn on traversable terrain."
			)

			var entity_id: int = (
				world.spawn_unit(
					definition,
					definition_index,
					player_index,
					spawn_position
				)
			)

			assert(
				EntityId.is_valid(
					entity_id
				),
				"Every benchmark entity should spawn successfully."
			)

			if player_index == 0:
				commanded_ids.append(
					entity_id
				)

				var final_destination: Vector3 = (
					commanded_destination_center
					+ formation_offset
				)

				assert(
					navigation_grid.is_world_position_traversable(
						final_destination
					),
					"Command destination must be traversable."
				)

				commanded_destinations.append(
					final_destination
				)

	var spawn_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- spawn_start
		)
		/ 1000.0
	)

	assert(
		world.entities.alive_count()
		== TOTAL_ENTITY_COUNT,
		"Benchmark should contain exactly 8000 entities."
	)

	assert(
		commanded_ids.size()
		== ENTITIES_PER_PLAYER,
		"Exactly 2000 entities should receive the move command."
	)

	print(
		"  Stage 1 complete."
	)

	print(
		"  Stage 2: building spatial grid..."
	)

	var grid_start: int = (
		Time.get_ticks_usec()
	)

	world.rebuild_spatial_grid()

	var initial_grid_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- grid_start
		)
		/ 1000.0
	)

	assert(
		world.spatial_grid.indexed_entity_count()
		== TOTAL_ENTITY_COUNT,
		"Spatial grid should contain all 8000 entities."
	)

	print(
		"  Stage 2 complete."
	)

	print(
		"  Stage 3: issuing one 2000-unit routed command..."
	)

	var command_start: int = (
		Time.get_ticks_usec()
	)

	var accepted_count: int = (
		world.issue_group_move(
			commanded_ids,
			commanded_destinations
		)
	)

	var command_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- command_start
		)
		/ 1000.0
	)

	assert(
		accepted_count
		== ENTITIES_PER_PLAYER,
		"All 2000 units should accept the routed command."
	)

	assert(
		world.shared_route_request_count == 1,
		"One group command should generate one shared A* request."
	)

	assert(
		world.last_shared_route.size() > 2,
		"Benchmark should use an indirect shared route."
	)

	for waypoint_index: int in range(
		1,
		world.last_shared_route.size()
	):
		assert(
			navigation_grid.is_segment_traversable(
				world.last_shared_route[
					waypoint_index - 1
				],
				world.last_shared_route[
					waypoint_index
				]
			),
			"Every simplified route segment must be terrain-legal."
		)

	print(
		"  Stage 3 complete."
	)

	print(
		"  Stage 4: simulating 20 navigation ticks..."
	)

	var simulation_start: int = (
		Time.get_ticks_usec()
	)

	var completed_ticks: int = 0

	var total_movement_milliseconds: float = 0.0
	var total_grid_milliseconds: float = 0.0

	var maximum_neighbors: int = 0
	var total_neighbors_examined: int = 0
	var total_neighbors_accepted: int = 0

	for tick_index: int in range(
		BENCHMARK_TICKS
	):
		completed_ticks += world.advance(
			world.clock.tick_seconds
		)

		total_movement_milliseconds += (
			world.last_movement_milliseconds
		)

		total_grid_milliseconds += (
			world.last_grid_rebuild_milliseconds
		)

		maximum_neighbors = maxi(
			maximum_neighbors,
			world.movement_system.last_maximum_neighbors
		)

		total_neighbors_examined += (
			world.movement_system.last_neighbors_examined
		)

		total_neighbors_accepted += (
			world.movement_system.last_neighbors_accepted
		)

		if (tick_index + 1) % 5 == 0:
			print(
				(
					"    Completed %d / %d ticks."
					% [
						tick_index + 1,
						BENCHMARK_TICKS,
					]
				)
			)

	var simulation_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- simulation_start
		)
		/ 1000.0
	)

	assert(
		completed_ticks == BENCHMARK_TICKS,
		"Every benchmark simulation tick should complete."
	)

	print(
		"  Stage 4 complete."
	)

	print(
		"  Stage 5: validating commanded units..."
	)

	var moving_count: int = 0
	var illegal_position_count: int = 0

	for entity_id: int in commanded_ids:
		var entity_index: int = (
			world.entities.get_index_if_alive(
				entity_id
			)
		)

		assert(
			entity_index >= 0,
			"Every commanded benchmark unit should remain alive."
		)

		var position: Vector3 = (
			world.entities.positions[
				entity_index
			]
		)

		if not navigation_grid.is_world_position_traversable(
			position
		):
			illegal_position_count += 1

		if world.entities.has_move_target_by_index(
			entity_index
		):
			moving_count += 1

	assert(
		illegal_position_count == 0,
		"No commanded unit may enter Impassable terrain."
	)

	assert(
		moving_count > 0,
		"Commanded formation should still be traversing the route after 20 ticks."
	)

	assert(
		world.spatial_grid.indexed_entity_count()
		== TOTAL_ENTITY_COUNT,
		"Final spatial grid should still contain all entities."
	)

	print(
		"  Stage 5 complete."
	)

	var average_tick_milliseconds: float = (
		simulation_milliseconds
		/ float(BENCHMARK_TICKS)
	)

	var average_movement_milliseconds: float = (
		total_movement_milliseconds
		/ float(BENCHMARK_TICKS)
	)

	var average_grid_milliseconds: float = (
		total_grid_milliseconds
		/ float(BENCHMARK_TICKS)
	)

	var average_other_milliseconds: float = maxf(
		0.0,
		average_tick_milliseconds
		- average_movement_milliseconds
		- average_grid_milliseconds
	)

	print("")
	print(
		"===== NAVIGATION SCALE RESULT ====="
	)

	print(
		(
			"8000 total | "
			+ "2000 routed | "
			+ "%d shared waypoints"
		)
		% [
			world.last_shared_route.size(),
		]
	)

	print(
		(
			"spawn %.2f ms | "
			+ "initial grid %.2f ms | "
			+ "group command %.2f ms"
		)
		% [
			spawn_milliseconds,
			initial_grid_milliseconds,
			command_milliseconds,
		]
	)

	print(
		(
			"20 ticks %.2f ms | "
			+ "average tick %.2f ms"
		)
		% [
			simulation_milliseconds,
			average_tick_milliseconds,
		]
	)

	print(
		(
			"average movement %.2f ms | "
			+ "average grid %.2f ms | "
			+ "average other %.2f ms"
		)
		% [
			average_movement_milliseconds,
			average_grid_milliseconds,
			average_other_milliseconds,
		]
	)

	print(
		(
			"avoidance examined %d | "
			+ "accepted %d | "
			+ "max neighbors %d"
		)
		% [
			total_neighbors_examined,
			total_neighbors_accepted,
			maximum_neighbors,
		]
	)

	print(
		(
			"moving after benchmark %d | "
			+ "illegal positions %d | "
			+ "final cells %d | "
			+ "max bucket %d"
		)
		% [
			moving_count,
			illegal_position_count,
			world.spatial_grid.cell_count(),
			world.spatial_grid.maximum_bucket_size(),
		]
	)

	print(
		"==================================="
	)


func _build_navigation_wall(
	world: SimulationWorld,
	navigation_grid: NavigationGrid
) -> void:
	for row: int in range(
		navigation_grid.row_count()
	):
		if (
			row >= GAP_START_ROW
			and row <= GAP_END_ROW
		):
			continue

		world.set_navigation_cell_blocked(
			Vector2i(
				WALL_COLUMN,
				row
			)
		)


func _get_formation_offset(
	local_index: int
) -> Vector3:
	var column: int = (
		local_index
		% FORMATION_COLUMNS
	)

	var row: int = floori(
		float(local_index)
		/ float(FORMATION_COLUMNS)
	)

	var row_count: int = (
		ENTITIES_PER_PLAYER
		/ FORMATION_COLUMNS
	)

	var x_offset: float = (
		(
			float(row)
			- float(row_count - 1) * 0.5
		)
		* FORMATION_SPACING
	)

	var z_offset: float = (
		(
			float(column)
			- float(FORMATION_COLUMNS - 1) * 0.5
		)
		* FORMATION_SPACING
	)

	return Vector3(
		x_offset,
		0.0,
		z_offset
	)

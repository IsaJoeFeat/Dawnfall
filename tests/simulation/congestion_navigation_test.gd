extends Node


const WORLD_SIZE := Vector2(
	256.0,
	256.0
)

const CELL_SIZE: float = 4.0

const WALL_COLUMN: int = 32
const GAP_ROW: int = 31

const UNIT_COUNT: int = 128
const FORMATION_COLUMNS: int = 16
const FORMATION_ROWS: int = 8
const FORMATION_SPACING: float = 1.5

const UNIT_SPEED: float = 20.0

const MAXIMUM_TEST_TICKS: int = 2000
const FIRST_CROSSING_TIMEOUT_TICKS: int = 600
const STALL_TIMEOUT_TICKS: int = 300


func _ready() -> void:
	var world := SimulationWorld.new()

	world.configure_navigation(
		Vector3.ZERO,
		WORLD_SIZE,
		CELL_SIZE
	)

	var navigation_grid: NavigationGrid = (
		world.navigation_grid
	)

	_build_wall(
		world,
		navigation_grid
	)

	var start_center := Vector3(
		64.0,
		0.0,
		64.0
	)

	var destination_center := Vector3(
		192.0,
		0.0,
		64.0
	)

	assert(
		not navigation_grid.is_segment_traversable(
			start_center,
			destination_center
		),
		"Direct group path should be blocked by the wall."
	)

	var route: PackedVector3Array = (
		world.build_shared_route(
			start_center,
			destination_center
		)
	)

	assert(
		route.size() > 2,
		"Congestion test should require an indirect route."
	)

	for waypoint_index: int in range(
		1,
		route.size()
	):
		assert(
			navigation_grid.is_segment_traversable(
				route[
					waypoint_index - 1
				],
				route[
					waypoint_index
				]
			),
			"Every route segment must be terrain-legal."
		)

	var entity_ids := PackedInt64Array()
	var destinations := PackedVector3Array()
	var previous_positions := PackedVector3Array()

	var crossed_gap := PackedByteArray()
	crossed_gap.resize(
		UNIT_COUNT
	)
	crossed_gap.fill(0)

	for unit_index: int in range(
		UNIT_COUNT
	):
		var offset: Vector3 = (
			_get_formation_offset(
				unit_index
			)
		)

		var spawn_position: Vector3 = (
			start_center + offset
		)

		var final_destination: Vector3 = (
			destination_center + offset
		)

		assert(
			navigation_grid.is_world_position_traversable(
				spawn_position
			),
			"Unit must spawn on traversable terrain."
		)

		assert(
			navigation_grid.is_world_position_traversable(
				final_destination
			),
			"Final slot must be traversable."
		)

		var entity_id: int = (
			world.entities.create_entity(
				0,
				0,
				spawn_position,
				100.0,
				0.35,
				UNIT_SPEED,
				100.0,
				100.0,
				deg_to_rad(720.0),
				0.0
			)
		)

		assert(
			EntityId.is_valid(
				entity_id
			),
			"Congestion-test unit should spawn."
		)

		entity_ids.append(
			entity_id
		)

		destinations.append(
			final_destination
		)

		previous_positions.append(
			spawn_position
		)

	world.rebuild_spatial_grid()

	assert(
		world.issue_group_move(
			entity_ids,
			destinations
		) == UNIT_COUNT,
		"Every unit should accept the group order."
	)

	assert(
		world.shared_route_request_count == 1,
		"Group should use one shared route request."
	)

	var wall_crossing_x: float = (
		float(WALL_COLUMN)
		* CELL_SIZE
	)

	var completed_ticks: int = 0

	var best_progress_count: int = 0
	var last_progress_tick: int = 0

	var first_crossing_happened: bool = false
	var deadlocked: bool = false

	var maximum_neighbors: int = 0

	var simulation_start: int = (
		Time.get_ticks_usec()
	)

	for tick_index: int in range(
		MAXIMUM_TEST_TICKS
	):
		world.advance(
			world.clock.tick_seconds
		)

		completed_ticks = tick_index + 1

		maximum_neighbors = maxi(
			maximum_neighbors,
			world.movement_system.last_maximum_neighbors
		)

		var crossed_count: int = 0
		var completed_count: int = 0

		for unit_index: int in range(
			UNIT_COUNT
		):
			var entity_index: int = (
				world.entities.get_index_if_alive(
					entity_ids[
						unit_index
					]
				)
			)

			assert(
				entity_index >= 0,
				"Every test unit should remain alive."
			)

			var current_position: Vector3 = (
				world.entities.positions[
					entity_index
				]
			)

			assert(
				navigation_grid.is_world_position_traversable(
					current_position
				),
				"Unit entered Impassable terrain."
			)

			if crossed_gap[
				unit_index
			] == 0:
				if _crossed_wall_this_tick(
					previous_positions[
						unit_index
					],
					current_position,
					wall_crossing_x
				):
					var crossing_row: int = (
						_get_crossing_row(
							previous_positions[
								unit_index
							],
							current_position,
							wall_crossing_x
						)
					)

					assert(
						crossing_row == GAP_ROW,
						"Unit crossed wall outside the legal gap."
					)

					crossed_gap[
						unit_index
					] = 1

			if crossed_gap[
				unit_index
			] == 1:
				crossed_count += 1

			if not world.entities.has_move_target_by_index(
				entity_index
			):
				completed_count += 1

			previous_positions[
				unit_index
			] = current_position

		if crossed_count > 0:
			first_crossing_happened = true

		var progress_count: int = (
			crossed_count
			+ completed_count
		)

		if progress_count > best_progress_count:
			best_progress_count = progress_count
			last_progress_tick = tick_index

		if (
			not first_crossing_happened
			and tick_index
			>= FIRST_CROSSING_TIMEOUT_TICKS
		):
			deadlocked = true
			break

		if (
			first_crossing_happened
			and tick_index
			- last_progress_tick
			>= STALL_TIMEOUT_TICKS
		):
			deadlocked = true
			break

		if completed_count == UNIT_COUNT:
			break

	var elapsed_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- simulation_start
		)
		/ 1000.0
	)

	var final_crossed_count: int = 0
	var final_completed_count: int = 0
	var maximum_final_error: float = 0.0

	for unit_index: int in range(
		UNIT_COUNT
	):
		var entity_index: int = (
			world.entities.get_index_if_alive(
				entity_ids[
					unit_index
				]
			)
		)

		if crossed_gap[
			unit_index
		] == 1:
			final_crossed_count += 1

		if not world.entities.has_move_target_by_index(
			entity_index
		):
			final_completed_count += 1

		var final_error: float = (
			world.entities.positions[
				entity_index
			].distance_to(
				destinations[
					unit_index
				]
			)
		)

		maximum_final_error = maxf(
			maximum_final_error,
			final_error
		)

	if (
		deadlocked
		or final_crossed_count != UNIT_COUNT
		or final_completed_count != UNIT_COUNT
	):
		_print_diagnostics(
			world,
			entity_ids,
			destinations,
			crossed_gap
		)

	assert(
		not deadlocked,
		"Congested group stopped making meaningful progress."
	)

	assert(
		final_crossed_count == UNIT_COUNT,
		"Every unit should eventually cross the choke."
	)

	assert(
		final_completed_count == UNIT_COUNT,
		"Every unit should eventually complete its order."
	)

	assert(
		maximum_final_error <= 0.01,
		"Every unit should reform at its assigned final slot."
	)

	print(
		(
			"CONGESTION NAVIGATION PASS | "
			+ "%d units | "
			+ "%d shared waypoints | "
			+ "1-cell choke | "
			+ "%d ticks | "
			+ "%.2f ms simulation | "
			+ "max neighbors %d | "
			+ "max final error %.3f"
		)
		% [
			UNIT_COUNT,
			world.last_shared_route.size(),
			completed_ticks,
			elapsed_milliseconds,
			maximum_neighbors,
			maximum_final_error,
		]
	)


func _build_wall(
	world: SimulationWorld,
	navigation_grid: NavigationGrid
) -> void:
	for row: int in range(
		navigation_grid.row_count()
	):
		if row == GAP_ROW:
			continue

		world.set_navigation_cell_blocked(
			Vector2i(
				WALL_COLUMN,
				row
			)
		)


func _get_formation_offset(
	unit_index: int
) -> Vector3:
	var column: int = (
		unit_index
		% FORMATION_COLUMNS
	)

	var row: int = floori(
		float(unit_index)
		/ float(FORMATION_COLUMNS)
	)

	var x_offset: float = (
		(
			float(row)
			- float(
				FORMATION_ROWS - 1
			) * 0.5
		)
		* FORMATION_SPACING
	)

	var z_offset: float = (
		(
			float(column)
			- float(
				FORMATION_COLUMNS - 1
			) * 0.5
		)
		* FORMATION_SPACING
	)

	return Vector3(
		x_offset,
		0.0,
		z_offset
	)


func _crossed_wall_this_tick(
	previous_position: Vector3,
	current_position: Vector3,
	wall_crossing_x: float
) -> bool:
	return (
		previous_position.x
		< wall_crossing_x
		and current_position.x
		>= wall_crossing_x
	)


func _get_crossing_row(
	previous_position: Vector3,
	current_position: Vector3,
	wall_crossing_x: float
) -> int:
	var x_difference: float = (
		current_position.x
		- previous_position.x
	)

	assert(
		not is_zero_approx(
			x_difference
		),
		"Wall crossing requires horizontal movement."
	)

	var interpolation: float = (
		(
			wall_crossing_x
			- previous_position.x
		)
		/ x_difference
	)

	var crossing_z: float = lerpf(
		previous_position.z,
		current_position.z,
		interpolation
	)

	return floori(
		crossing_z
		/ CELL_SIZE
	)


func _print_diagnostics(
	world: SimulationWorld,
	entity_ids: PackedInt64Array,
	destinations: PackedVector3Array,
	crossed_gap: PackedByteArray
) -> void:
	print(
		"----- CONGESTION DEBUG -----"
	)

	print(
		"Route: ",
		world.last_shared_route
	)

	var printed_count: int = 0

	for unit_index: int in range(
		UNIT_COUNT
	):
		var entity_index: int = (
			world.entities.get_index_if_alive(
				entity_ids[
					unit_index
				]
			)
		)

		var moving: bool = (
			world.entities.has_move_target_by_index(
				entity_index
			)
		)

		var final_error: float = (
			world.entities.positions[
				entity_index
			].distance_to(
				destinations[
					unit_index
				]
			)
		)

		if (
			not moving
			and crossed_gap[
				unit_index
			] == 1
			and final_error <= 0.01
		):
			continue

		print(
			(
				"Unit %d | "
				+ "pos %s | "
				+ "target %s | "
				+ "moving %s | "
				+ "crossed %s | "
				+ "final error %.3f"
			)
			% [
				unit_index,
				str(
					world.entities.positions[
						entity_index
					]
				),
				str(
					world.entities.movement_targets[
						entity_index
					]
				),
				str(moving),
				str(
					crossed_gap[
						unit_index
					] == 1
				),
				final_error,
			]
		)

		printed_count += 1

		if printed_count >= 12:
			break

	print(
		"----------------------------"
	)

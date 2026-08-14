extends Node


const WORLD_SIZE := Vector2(
	1024.0,
	1024.0
)

const CELL_SIZE: float = 4.0
const ROUTE_REQUEST_COUNT: int = 100

const FOLLOWER_COUNT: int = 64
const FOLLOWER_COLUMNS: int = 8
const FOLLOWER_SPACING: float = 1.25
const FOLLOWER_SPEED: float = 100.0
const MAXIMUM_FOLLOW_TICKS: int = 500


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

	var wall_x: int = (
		navigation_grid.column_count() / 2
	)

	var gap_start: int = (
		navigation_grid.row_count() / 2 - 4
	)

	var gap_end: int = (
		navigation_grid.row_count() / 2 + 4
	)

	for row: int in range(
		navigation_grid.row_count()
	):
		if (
			row >= gap_start
			and row <= gap_end
		):
			continue

		world.set_navigation_cell_blocked(
			Vector2i(
				wall_x,
				row
			)
		)

	var start := Vector3(
		100.0,
		0.0,
		180.0
	)

	var destination := Vector3(
		920.0,
		0.0,
		840.0
	)

	var first_route: PackedVector3Array = (
		world.build_shared_route(
			start,
			destination
		)
	)

	assert(
		first_route.size() >= 2,
		"Navigation test should find a route."
	)

	assert(
		first_route.size() < 20,
		"Shared route should be simplified."
	)

	var wall_center_x: float = (
		(float(wall_x) + 0.5)
		* CELL_SIZE
	)

	var crossed_gap: bool = false

	for point_index: int in range(
		1,
		first_route.size()
	):
		var start_point: Vector3 = (
			first_route[point_index - 1]
		)
		var end_point: Vector3 = (
			first_route[point_index]
		)

		var minimum_x: float = minf(
			start_point.x,
			end_point.x
		)
		var maximum_x: float = maxf(
			start_point.x,
			end_point.x
		)

		if (
			wall_center_x < minimum_x
			or wall_center_x > maximum_x
		):
			continue

		var x_difference: float = (
			end_point.x - start_point.x
		)

		if is_zero_approx(x_difference):
			continue

		var interpolation: float = (
			(wall_center_x - start_point.x)
			/ x_difference
		)

		var crossing_z: float = lerpf(
			start_point.z,
			end_point.z,
			interpolation
		)

		var crossing_row: int = floori(
			crossing_z / CELL_SIZE
		)

		if (
			crossing_row >= gap_start
			and crossing_row <= gap_end
		):
			crossed_gap = true
			break

	assert(
		crossed_gap,
		"Shared route should pass through the wall gap."
	)

	var benchmark_start: int = (
		Time.get_ticks_usec()
	)

	var total_waypoints: int = 0

	for _request: int in range(
		ROUTE_REQUEST_COUNT
	):
		var route: PackedVector3Array = (
			world.build_shared_route(
				start,
				destination
			)
		)

		assert(
			not route.is_empty(),
			"Every benchmark route should succeed."
		)

		total_waypoints += route.size()

	var route_elapsed_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- benchmark_start
		)
		/ 1000.0
	)

	var average_milliseconds: float = (
		route_elapsed_milliseconds
		/ float(ROUTE_REQUEST_COUNT)
	)

	print(
		(
			"SHARED ROUTE PASS | "
			+ "%dx%d cells | "
			+ "%d requests | "
			+ "%.2f ms total | "
			+ "%.3f ms average | "
			+ "%d simplified waypoints"
		)
		% [
			navigation_grid.column_count(),
			navigation_grid.row_count(),
			ROUTE_REQUEST_COUNT,
			route_elapsed_milliseconds,
			average_milliseconds,
			first_route.size(),
		]
	)

	_run_route_follow_test(
		world,
		start,
		destination,
		wall_center_x,
		gap_start,
		gap_end
	)


func _run_route_follow_test(
	world: SimulationWorld,
	start: Vector3,
	destination: Vector3,
	wall_center_x: float,
	gap_start: int,
	gap_end: int
) -> void:
	var entity_ids := PackedInt64Array()
	var destinations := PackedVector3Array()
	var previous_positions := PackedVector3Array()

	var crossed_gap_flags := PackedByteArray()

	crossed_gap_flags.resize(FOLLOWER_COUNT)

	for follower_index: int in range(
		FOLLOWER_COUNT
	):
		var column: int = (
			follower_index % FOLLOWER_COLUMNS
		)
		var row: int = floori(
			float(follower_index)
			/ float(FOLLOWER_COLUMNS)
		)

		var offset := Vector3(
			(
				float(column)
				- float(FOLLOWER_COLUMNS - 1)
				* 0.5
			) * FOLLOWER_SPACING,
			0.0,
			(
				float(row)
				- float(FOLLOWER_COLUMNS - 1)
				* 0.5
			) * FOLLOWER_SPACING
		)

		var spawn_position: Vector3 = (
			start + offset
		)

		var final_destination: Vector3 = (
			destination + offset
		)

		# This isolated test gives every follower a unique owner.
		# MovementSystem only performs local avoidance against
		# units with the same owner, so this proves shared-route
		# following without mixing congestion/separation into
		# the result.
		var test_owner_id: int = follower_index

		var entity_id: int = (
			world.entities.create_entity(
				0,
				test_owner_id,
				spawn_position,
				100.0,
				0.35,
				FOLLOWER_SPEED,
				500.0,
				500.0,
				deg_to_rad(720.0),
				0.0
			)
		)

		assert(
			EntityId.is_valid(entity_id),
			"Route follower should spawn."
		)

		entity_ids.append(entity_id)
		destinations.append(final_destination)
		previous_positions.append(
			spawn_position
		)

	world.rebuild_spatial_grid()

	var accepted_count: int = (
		world.issue_group_move(
			entity_ids,
			destinations
		)
	)

	assert(
		accepted_count == FOLLOWER_COUNT,
		"Every route follower should accept the shared route."
	)

	var follow_start: int = (
		Time.get_ticks_usec()
	)

	var completed_tick_count: int = 0

	for tick_index: int in range(
		MAXIMUM_FOLLOW_TICKS
	):
		world.advance(
			world.clock.tick_seconds
		)

		completed_tick_count = tick_index + 1

		var all_finished: bool = true

		for follower_index: int in range(
			FOLLOWER_COUNT
		):
			var entity_index: int = (
				world.entities.get_index_if_alive(
					entity_ids[follower_index]
				)
			)

			assert(
				entity_index >= 0,
				"Route follower should remain alive."
			)

			var current_position: Vector3 = (
				world.entities.positions[
					entity_index
				]
			)

			var previous_position: Vector3 = (
				previous_positions[
					follower_index
				]
			)

			if (
				crossed_gap_flags[
					follower_index
				] == 0
				and previous_position.x
				< wall_center_x
				and current_position.x
				>= wall_center_x
			):
				var x_difference: float = (
					current_position.x
					- previous_position.x
				)

				if not is_zero_approx(
					x_difference
				):
					var interpolation: float = (
						(
							wall_center_x
							- previous_position.x
						)
						/ x_difference
					)

					var crossing_z: float = lerpf(
						previous_position.z,
						current_position.z,
						interpolation
					)

					var crossing_row: int = floori(
						crossing_z
						/ CELL_SIZE
					)

					if (
						crossing_row
						>= gap_start
						and crossing_row
						<= gap_end
					):
						crossed_gap_flags[
							follower_index
						] = 1

			previous_positions[
				follower_index
			] = current_position

			if (
				world.entities.has_move_target_by_index(
					entity_index
				)
			):
				all_finished = false

		if all_finished:
			break

	var follow_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- follow_start
		)
		/ 1000.0
	)

	for follower_index: int in range(
		FOLLOWER_COUNT
	):
		assert(
			crossed_gap_flags[
				follower_index
			] == 1,
			"Every follower should cross through the navigation gap."
		)

		var entity_index: int = (
			world.entities.get_index_if_alive(
				entity_ids[follower_index]
			)
		)

		assert(
			not world.entities.has_move_target_by_index(
				entity_index
			),
			"Every follower should finish its route."
		)

		var final_error: float = (
			world.entities.positions[
				entity_index
			].distance_to(
				destinations[
					follower_index
				]
			)
		)

		assert(
			final_error <= 0.01,
			"Every follower should reach its assigned final slot."
		)

	print(
		(
			"SHARED ROUTE FOLLOW PASS | "
			+ "%d units | "
			+ "%d ticks | "
			+ "%.2f ms test simulation"
		)
		% [
			FOLLOWER_COUNT,
			completed_tick_count,
			follow_milliseconds,
		]
	)

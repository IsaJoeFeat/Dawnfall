extends Node


const WORLD_SIZE := Vector2(
	128.0,
	128.0
)

const CELL_SIZE: float = 4.0

const WALL_COLUMN: int = 16
const GAP_START_ROW: int = 14
const GAP_END_ROW: int = 18

const MAXIMUM_TEST_TICKS: int = 500


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

	# Build a vertical wall with one opening near the
	# center of the map.
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

	# Start and destination are deliberately on the
	# same Z coordinate. A straight movement order
	# would hit the solid part of the wall.
	var start := Vector3(
		40.0,
		0.0,
		24.0
	)

	var destination := Vector3(
		88.0,
		0.0,
		24.0
	)

	assert(
		not navigation_grid.is_segment_traversable(
			start,
			destination
		),
		"Direct path should be blocked by the wall."
	)

	var route: PackedVector3Array = (
		world.build_shared_route(
			start,
			destination
		)
	)

	assert(
		route.size() > 2,
		"Pathfinder should produce an indirect route."
	)

	assert(
		route.size() < 20,
		"Shared route should remain simplified."
	)

	# Every simplified segment must itself be legal.
	for waypoint_index: int in range(
		1,
		route.size()
	):
		assert(
			navigation_grid.is_segment_traversable(
				route[waypoint_index - 1],
				route[waypoint_index]
			),
			"Every shared-route segment must be traversable."
		)

	var entity_id: int = (
		world.entities.create_entity(
			0,
			0,
			start,
			100.0,
			0.35,
			20.0,
			100.0,
			100.0,
			deg_to_rad(720.0),
			0.0
		)
	)

	assert(
		EntityId.is_valid(entity_id),
		"Navigation test unit should spawn."
	)

	world.rebuild_spatial_grid()

	var entity_ids := PackedInt64Array()
	entity_ids.append(entity_id)

	var destinations := PackedVector3Array()
	destinations.append(destination)

	assert(
		world.issue_group_move(
			entity_ids,
			destinations
		) == 1,
		"Unit should accept its shared-route move command."
	)

	assert(
		world.shared_route_request_count == 1,
		"One group command should request exactly one shared route."
	)

	var wall_crossing_x: float = (
		float(WALL_COLUMN)
		* CELL_SIZE
	)

	var crossed_gap: bool = false

	var entity_index: int = (
		world.entities.get_index_if_alive(
			entity_id
		)
	)

	var previous_position: Vector3 = (
		world.entities.positions[
			entity_index
		]
	)

	var completed_ticks: int = 0

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

		var current_position: Vector3 = (
			world.entities.positions[
				entity_index
			]
		)

		if (
			not crossed_gap
			and previous_position.x
			< wall_crossing_x
			and current_position.x
			>= wall_crossing_x
		):
			var x_difference: float = (
				current_position.x
				- previous_position.x
			)

			assert(
				not is_zero_approx(
					x_difference
				),
				"Wall crossing should have horizontal movement."
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

			var crossing_row: int = floori(
				crossing_z / CELL_SIZE
			)

			assert(
				crossing_row >= GAP_START_ROW
				and crossing_row <= GAP_END_ROW,
				"Unit must cross the wall through the legal gap."
			)

			crossed_gap = true

		previous_position = current_position

		if not world.entities.has_move_target_by_index(
			entity_index
		):
			break

	var elapsed_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- simulation_start
		)
		/ 1000.0
	)

	print("----- NAV DEBUG -----")
	print("Route: ", world.last_shared_route)
	print("Final position: ", world.entities.positions[entity_index])
	print(
		"Current movement target: ",
		world.entities.movement_targets[entity_index]
	)
	print(
		"Has move target: ",
		world.entities.has_move_target_by_index(entity_index)
	)
	print(
		"Direct current->target legal: ",
		navigation_grid.is_segment_traversable(
			world.entities.positions[entity_index],
			world.entities.movement_targets[entity_index]
		)
	)
	print("---------------------")

	assert(
		crossed_gap,
		"Unit should cross through the wall gap."
	)

	assert(
		not world.entities.has_move_target_by_index(
			entity_index
		),
		"Unit should complete its routed move order."
	)

	var final_position: Vector3 = (
		world.entities.positions[
			entity_index
		]
	)

	var final_error: float = (
		final_position.distance_to(
			destination
		)
	)

	assert(
		final_error <= 0.01,
		"Unit should finish at the commanded destination."
	)

	print(
		(
			"SINGLE UNIT NAVIGATION PASS | "
			+ "%d shared waypoints | "
			+ "%d ticks | "
			+ "%.2f ms simulation | "
			+ "final error %.3f"
		)
		% [
			world.last_shared_route.size(),
			completed_ticks,
			elapsed_milliseconds,
			final_error,
		]
	)

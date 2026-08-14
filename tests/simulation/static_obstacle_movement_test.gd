extends Node


const WORLD_SIZE := Vector2(
	128.0,
	128.0
)

const CELL_SIZE: float = 4.0

const WALL_COLUMN: int = 16
const TEST_TICKS: int = 100


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

	for row: int in range(
		navigation_grid.row_count()
	):
		world.set_navigation_cell_blocked(
			Vector2i(
				WALL_COLUMN,
				row
			)
		)

	var start := Vector3(
		40.0,
		0.0,
		64.0
	)

	var destination := Vector3(
		88.0,
		0.0,
		64.0
	)

	var wall_minimum_x: float = (
		float(WALL_COLUMN)
		* CELL_SIZE
	)

	assert(
		not navigation_grid.is_segment_traversable(
			start,
			destination
		),
		"Direct movement through the wall must be illegal."
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
		"Static obstacle test unit should spawn."
	)

	world.rebuild_spatial_grid()

	var command_ids := PackedInt64Array()
	command_ids.append(entity_id)

	assert(
		world.issue_move(
			command_ids,
			destination
		) == 1,
		"Test unit should accept the move order."
	)

	var simulation_start: int = (
		Time.get_ticks_usec()
	)

	for _tick: int in range(TEST_TICKS):
		world.advance(
			world.clock.tick_seconds
		)

	var elapsed_milliseconds: float = (
		float(
			Time.get_ticks_usec()
			- simulation_start
		)
		/ 1000.0
	)

	var entity_index: int = (
		world.entities.get_index_if_alive(
			entity_id
		)
	)

	assert(
		entity_index >= 0,
		"Test unit should remain alive."
	)

	var final_position: Vector3 = (
		world.entities.positions[
			entity_index
		]
	)

	assert(
		final_position.x > start.x,
		"Unit should move toward the wall."
	)

	assert(
		final_position.x < wall_minimum_x,
		"Unit must never cross into the blocked wall."
	)

	assert(
		world.entities.has_move_target_by_index(
			entity_index
		),
		"Blocked unit should retain its movement order."
	)

	print(
		(
			"STATIC OBSTACLE PASS | "
			+ "start x %.2f | "
			+ "wall begins x %.2f | "
			+ "final x %.2f | "
			+ "%d ticks | "
			+ "%.2f ms simulation"
		)
		% [
			start.x,
			wall_minimum_x,
			final_position.x,
			TEST_TICKS,
			elapsed_milliseconds,
		]
	)

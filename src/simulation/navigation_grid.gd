class_name NavigationGrid
extends RefCounted


var _grid := AStarGrid2D.new()

var _origin := Vector3.ZERO
var _cell_size: float = 4.0
var _column_count: int = 0
var _row_count: int = 0


func configure(
	origin: Vector3,
	world_size: Vector2,
	cell_size: float
) -> void:
	assert(cell_size > 0.0)
	assert(world_size.x > 0.0)
	assert(world_size.y > 0.0)

	_origin = origin
	_cell_size = cell_size

	_column_count = ceili(
		world_size.x / _cell_size
	)
	_row_count = ceili(
		world_size.y / _cell_size
	)

	_grid.clear()

	_grid.region = Rect2i(
		0,
		0,
		_column_count,
		_row_count
	)

	_grid.cell_size = Vector2(
		_cell_size,
		_cell_size
	)

	_grid.offset = Vector2(
		_origin.x + _cell_size * 0.5,
		_origin.z + _cell_size * 0.5
	)

	_grid.diagonal_mode = (
		AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	)

	_grid.default_compute_heuristic = (
		AStarGrid2D.HEURISTIC_OCTILE
	)

	_grid.default_estimate_heuristic = (
		AStarGrid2D.HEURISTIC_OCTILE
	)

	_grid.update()


func set_cell_blocked(
	cell: Vector2i,
	blocked: bool = true
) -> void:
	if not _grid.is_in_boundsv(cell):
		return

	_grid.set_point_solid(
		cell,
		blocked
	)


func is_cell_blocked(
	cell: Vector2i
) -> bool:
	if not _grid.is_in_boundsv(cell):
		return true

	return _grid.is_point_solid(cell)


func world_to_cell(
	world_position: Vector3
) -> Vector2i:
	return Vector2i(
		floori(
			(world_position.x - _origin.x)
			/ _cell_size
		),
		floori(
			(world_position.z - _origin.z)
			/ _cell_size
		)
	)


func cell_to_world(
	cell: Vector2i
) -> Vector3:
	return Vector3(
		_origin.x
		+ (float(cell.x) + 0.5) * _cell_size,
		_origin.y,
		_origin.z
		+ (float(cell.y) + 0.5) * _cell_size
	)


func is_world_position_traversable(
	world_position: Vector3
) -> bool:
	var cell: Vector2i = world_to_cell(
		world_position
	)

	return not is_cell_blocked(cell)


func is_segment_traversable(
	start_world: Vector3,
	end_world: Vector3
) -> bool:
	var current_cell: Vector2i = world_to_cell(
		start_world
	)
	var end_cell: Vector2i = world_to_cell(
		end_world
	)

	if (
		is_cell_blocked(current_cell)
		or is_cell_blocked(end_cell)
	):
		return false

	if current_cell == end_cell:
		return true

	var delta_x: float = (
		end_world.x - start_world.x
	)
	var delta_z: float = (
		end_world.z - start_world.z
	)

	var step_x: int = 0
	var step_z: int = 0

	if delta_x > 0.0:
		step_x = 1
	elif delta_x < 0.0:
		step_x = -1

	if delta_z > 0.0:
		step_z = 1
	elif delta_z < 0.0:
		step_z = -1

	var t_max_x: float = INF
	var t_max_z: float = INF

	var t_delta_x: float = INF
	var t_delta_z: float = INF

	if step_x != 0:
		var next_boundary_x: float = (
			_origin.x
			+ float(
				current_cell.x
				+ (1 if step_x > 0 else 0)
			) * _cell_size
		)

		t_max_x = (
			(next_boundary_x - start_world.x)
			/ delta_x
		)

		t_delta_x = (
			_cell_size / absf(delta_x)
		)

	if step_z != 0:
		var next_boundary_z: float = (
			_origin.z
			+ float(
				current_cell.y
				+ (1 if step_z > 0 else 0)
			) * _cell_size
		)

		t_max_z = (
			(next_boundary_z - start_world.z)
			/ delta_z
		)

		t_delta_z = (
			_cell_size / absf(delta_z)
		)

	while current_cell != end_cell:
		if is_equal_approx(
			t_max_x,
			t_max_z
		):
			var side_x := Vector2i(
				current_cell.x + step_x,
				current_cell.y
			)

			var side_z := Vector2i(
				current_cell.x,
				current_cell.y + step_z
			)

			# Prevent diagonal movement through the corner
			# between two blocked cells.
			if (
				is_cell_blocked(side_x)
				or is_cell_blocked(side_z)
			):
				return false

			current_cell = Vector2i(
				current_cell.x + step_x,
				current_cell.y + step_z
			)

			t_max_x += t_delta_x
			t_max_z += t_delta_z

		elif t_max_x < t_max_z:
			current_cell.x += step_x
			t_max_x += t_delta_x

		else:
			current_cell.y += step_z
			t_max_z += t_delta_z

		if is_cell_blocked(current_cell):
			return false

	return true


func find_route(
	start_world: Vector3,
	destination_world: Vector3
) -> PackedVector3Array:
	var empty_route := PackedVector3Array()

	var start_cell: Vector2i = world_to_cell(
		start_world
	)
	var destination_cell: Vector2i = world_to_cell(
		destination_world
	)

	if (
		not _grid.is_in_boundsv(start_cell)
		or not _grid.is_in_boundsv(
			destination_cell
		)
	):
		return empty_route

	if (
		is_cell_blocked(start_cell)
		or is_cell_blocked(destination_cell)
	):
		return empty_route

	if is_segment_traversable(
		start_world,
		destination_world
	):
		var direct_route := PackedVector3Array()

		direct_route.append(start_world)
		direct_route.append(destination_world)

		return direct_route

	var cell_path: Array[Vector2i] = (
		_grid.get_id_path(
			start_cell,
			destination_cell
		)
	)

	if cell_path.is_empty():
		return empty_route

	var raw_route := PackedVector3Array()

	raw_route.append(start_world)

	# Keep every A* cell center initially.
	# This gives the simplifier a known-safe chain.
	for path_index: int in range(
		1,
		cell_path.size()
	):
		raw_route.append(
			cell_to_world(
				cell_path[path_index]
			)
		)

	raw_route.append(destination_world)

	return _simplify_route(raw_route)


func _simplify_route(
	raw_route: PackedVector3Array
) -> PackedVector3Array:
	if raw_route.size() <= 2:
		return raw_route

	var simplified := PackedVector3Array()

	simplified.append(raw_route[0])

	var anchor_index: int = 0
	var final_index: int = (
		raw_route.size() - 1
	)

	while anchor_index < final_index:
		var chosen_index: int = (
			anchor_index + 1
		)

		# Search backward from the destination and take
		# the furthest waypoint that has a completely
		# legal straight segment from the current anchor.
		for candidate_index: int in range(
			final_index,
			anchor_index,
			-1
		):
			if is_segment_traversable(
				raw_route[anchor_index],
				raw_route[candidate_index]
			):
				chosen_index = candidate_index
				break

		simplified.append(
			raw_route[chosen_index]
		)

		anchor_index = chosen_index

	return simplified


func column_count() -> int:
	return _column_count


func row_count() -> int:
	return _row_count

class_name SpatialGrid
extends RefCounted


const ANY_OWNER: int = -2

var cell_size: float

var _cells: Dictionary = {}
var _indexed_entity_count: int = 0


func _init(requested_cell_size: float = 8.0) -> void:
	assert(
		requested_cell_size > 0.0,
		"Spatial grid cell size must be greater than zero."
	)

	cell_size = requested_cell_size


func rebuild(entities: EntityStore) -> void:
	clear()

	for index: int in range(entities.capacity()):
		if not entities.is_index_alive(index):
			continue

		var cell: Vector2i = world_to_cell(
			entities.positions[index]
		)
		var bucket: PackedInt32Array = _cells.get(
			cell,
			PackedInt32Array()
		)

		bucket.append(index)
		_cells[cell] = bucket
		_indexed_entity_count += 1


func query_radius(
	center: Vector3,
	radius: float,
	entities: EntityStore,
	owner_filter: int = ANY_OWNER
) -> PackedInt32Array:
	var results := PackedInt32Array()

	if not DawnfallLog.require_valid(
		radius >= 0.0,
		"Spatial query radius cannot be negative.",
		&"SpatialGrid"
	):
		return results

	var minimum_cell: Vector2i = world_to_cell(
		Vector3(
			center.x - radius,
			0.0,
			center.z - radius
		)
	)
	var maximum_cell: Vector2i = world_to_cell(
		Vector3(
			center.x + radius,
			0.0,
			center.z + radius
		)
	)
	var radius_squared: float = radius * radius

	for cell_x: int in range(
		minimum_cell.x,
		maximum_cell.x + 1
	):
		for cell_z: int in range(
			minimum_cell.y,
			maximum_cell.y + 1
		):
			var cell := Vector2i(cell_x, cell_z)

			if not _cells.has(cell):
				continue

			var bucket: PackedInt32Array = _cells[cell]

			for entity_index: int in bucket:
				if not entities.is_index_alive(entity_index):
					continue

				if (
					owner_filter != ANY_OWNER
					and entities.owner_ids[entity_index]
					!= owner_filter
				):
					continue

				var candidate_position: Vector3 = (
					entities.positions[entity_index]
				)
				var difference_x: float = (
					candidate_position.x - center.x
				)
				var difference_z: float = (
					candidate_position.z - center.z
				)
				var distance_squared: float = (
					difference_x * difference_x
					+ difference_z * difference_z
				)

				if distance_squared <= radius_squared:
					results.append(entity_index)

	return results


func query_nearest_radius_into(
	center: Vector3,
	radius: float,
	entities: EntityStore,
	owner_filter: int,
	excluded_entity_index: int,
	maximum_results: int,
	result_indices: PackedInt32Array,
	result_distances_squared: PackedFloat32Array
) -> Vector2i:
	# This is a simulation hot path. The caller owns correctly sized
	# buffers, so keep validation lightweight here.
	if (
		radius < 0.0
		or maximum_results <= 0
		or result_indices.size() < maximum_results
		or result_distances_squared.size() < maximum_results
	):
		return Vector2i.ZERO

	var minimum_cell: Vector2i = world_to_cell(
		Vector3(
			center.x - radius,
			0.0,
			center.z - radius
		)
	)
	var maximum_cell: Vector2i = world_to_cell(
		Vector3(
			center.x + radius,
			0.0,
			center.z + radius
		)
	)

	var radius_squared: float = radius * radius
	var examined_count: int = 0
	var result_count: int = 0

	for cell_x: int in range(
		minimum_cell.x,
		maximum_cell.x + 1
	):
		for cell_z: int in range(
			minimum_cell.y,
			maximum_cell.y + 1
		):
			var cell := Vector2i(cell_x, cell_z)
			var bucket_value: Variant = _cells.get(cell)

			if bucket_value == null:
				continue

			var bucket: PackedInt32Array = bucket_value

			for entity_index: int in bucket:
				if entity_index == excluded_entity_index:
					continue

				# The spatial grid is rebuilt from living entities, so
				# repeating an alive lookup for every candidate is
				# unnecessary during this movement query.
				if (
					owner_filter != ANY_OWNER
					and entities.owner_ids[entity_index]
					!= owner_filter
				):
					continue

				examined_count += 1

				var candidate_position: Vector3 = (
					entities.positions[entity_index]
				)
				var difference_x: float = (
					candidate_position.x - center.x
				)
				var difference_z: float = (
					candidate_position.z - center.z
				)
				var distance_squared: float = (
					difference_x * difference_x
					+ difference_z * difference_z
				)

				if distance_squared > radius_squared:
					continue

				# Results are kept nearest-first. Once the buffer is
				# full, reject anything farther than the current
				# farthest neighbor immediately.
				if (
					result_count == maximum_results
					and distance_squared
					>= result_distances_squared[
						maximum_results - 1
					]
				):
					continue

				var insertion_index: int = result_count

				for existing_slot: int in range(result_count):
					var existing_distance: float = (
						result_distances_squared[
							existing_slot
						]
					)
					var existing_entity_index: int = (
						result_indices[existing_slot]
					)

					if (
						distance_squared < existing_distance
						or (
							is_equal_approx(
								distance_squared,
								existing_distance
							)
							and entity_index
							< existing_entity_index
						)
					):
						insertion_index = existing_slot
						break

				var final_slot: int = mini(
					result_count,
					maximum_results - 1
				)

				for shift_slot: int in range(
					final_slot,
					insertion_index,
					-1
				):
					result_indices[shift_slot] = (
						result_indices[shift_slot - 1]
					)
					result_distances_squared[shift_slot] = (
						result_distances_squared[
							shift_slot - 1
						]
					)

				result_indices[insertion_index] = entity_index
				result_distances_squared[insertion_index] = (
					distance_squared
				)

				result_count = mini(
					result_count + 1,
					maximum_results
				)

	return Vector2i(examined_count, result_count)


func query_aabb(
	minimum: Vector3,
	maximum: Vector3,
	entities: EntityStore,
	owner_filter: int = ANY_OWNER
) -> PackedInt32Array:
	var results := PackedInt32Array()
	var minimum_x: float = minf(minimum.x, maximum.x)
	var maximum_x: float = maxf(minimum.x, maximum.x)
	var minimum_z: float = minf(minimum.z, maximum.z)
	var maximum_z: float = maxf(minimum.z, maximum.z)

	var minimum_cell: Vector2i = world_to_cell(
		Vector3(minimum_x, 0.0, minimum_z)
	)
	var maximum_cell: Vector2i = world_to_cell(
		Vector3(maximum_x, 0.0, maximum_z)
	)

	for cell_x: int in range(
		minimum_cell.x,
		maximum_cell.x + 1
	):
		for cell_z: int in range(
			minimum_cell.y,
			maximum_cell.y + 1
		):
			var cell := Vector2i(cell_x, cell_z)

			if not _cells.has(cell):
				continue

			var bucket: PackedInt32Array = _cells[cell]

			for entity_index: int in bucket:
				if not entities.is_index_alive(entity_index):
					continue

				if (
					owner_filter != ANY_OWNER
					and entities.owner_ids[entity_index]
					!= owner_filter
				):
					continue

				var position: Vector3 = (
					entities.positions[entity_index]
				)

				if (
					position.x >= minimum_x
					and position.x <= maximum_x
					and position.z >= minimum_z
					and position.z <= maximum_z
				):
					results.append(entity_index)

	return results


func world_to_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size),
		floori(world_position.z / cell_size)
	)


func indexed_entity_count() -> int:
	return _indexed_entity_count


func cell_count() -> int:
	return _cells.size()


func maximum_bucket_size() -> int:
	var largest_bucket: int = 0

	for cell_key: Vector2i in _cells:
		var bucket: PackedInt32Array = _cells[cell_key]
		largest_bucket = maxi(largest_bucket, bucket.size())

	return largest_bucket


func clear() -> void:
	_cells.clear()
	_indexed_entity_count = 0

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
					and entities.owner_ids[entity_index] != owner_filter
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

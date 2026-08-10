class_name FormationMovePlanner
extends RefCounted


const HUNGARIAN_UNIT_LIMIT: int = 20
const CROSSING_REMOVAL_MICROSECONDS: int = 10000
const INFINITE_COST: int = 1 << 30


class SortEntry:
	var source_index: int
	var position: Vector3
	var projection: float

	func _init(
		new_source_index: int,
		new_position: Vector3,
		new_projection: float
	) -> void:
		source_index = new_source_index
		position = new_position
		projection = new_projection


func create_even_slots(
	polyline: PackedVector3Array,
	slot_count: int
) -> PackedVector3Array:
	var slots := PackedVector3Array()

	if polyline.is_empty() or slot_count <= 0:
		return slots

	if slot_count == 1:
		slots.append(polyline[0])
		return slots

	var cumulative_distances := PackedFloat32Array()
	var total_distance: float = 0.0

	cumulative_distances.append(0.0)

	for point_index: int in range(1, polyline.size()):
		total_distance += _ground_distance(
			polyline[point_index - 1],
			polyline[point_index]
		)
		cumulative_distances.append(total_distance)

	if is_zero_approx(total_distance):
		for _slot_index: int in range(slot_count):
			slots.append(polyline[0])

		return slots

	var slot_spacing: float = (
		total_distance / float(slot_count - 1)
	)
	var segment_index: int = 1

	slots.append(polyline[0])

	for slot_index: int in range(1, slot_count - 1):
		var required_distance: float = (
			slot_spacing * float(slot_index)
		)

		while (
			segment_index < cumulative_distances.size() - 1
			and required_distance
			> cumulative_distances[segment_index]
		):
			segment_index += 1

		var segment_start_distance: float = (
			cumulative_distances[segment_index - 1]
		)
		var segment_end_distance: float = (
			cumulative_distances[segment_index]
		)
		var segment_distance: float = (
			segment_end_distance - segment_start_distance
		)
		var interpolation: float = 0.0

		if segment_distance > 0.0:
			interpolation = (
				(required_distance - segment_start_distance)
				/ segment_distance
			)

		slots.append(
			polyline[segment_index - 1].lerp(
				polyline[segment_index],
				interpolation
			)
		)

	slots.append(polyline[polyline.size() - 1])

	return slots

func create_compact_slots(
	entities: EntityStore,
	entity_indices: PackedInt32Array,
	center: Vector3,
	padding: float = 0.25
) -> PackedVector3Array:
	var slots := PackedVector3Array()

	if entity_indices.is_empty():
		return slots

	if not DawnfallLog.require_valid(
		padding >= 0.0,
		"Compact-slot padding cannot be negative.",
		&"FormationMovePlanner"
	):
		return slots

	var maximum_radius: float = 0.0

	for entity_index: int in entity_indices:
		if not entities.is_index_alive(entity_index):
			return PackedVector3Array()

		maximum_radius = maxf(
			maximum_radius,
			entities.collision_radii[entity_index]
		)

	var spacing: float = maximum_radius * 2.0 + padding
	var slot_count: int = entity_indices.size()
	var column_count: int = ceili(
		sqrt(float(slot_count))
	)
	var row_count: int = ceili(
		float(slot_count) / float(column_count)
	)
	var generated_center := Vector3.ZERO

	for row: int in range(row_count):
		var row_start: int = row * column_count
		var slots_in_row: int = mini(
			column_count,
			slot_count - row_start
		)

		for column: int in range(slots_in_row):
			var horizontal_offset: float = (
				float(column)
				- float(slots_in_row - 1) * 0.5
			) * spacing
			var vertical_offset: float = (
				float(row)
				- float(row_count - 1) * 0.5
			) * spacing
			var slot := Vector3(
				center.x + horizontal_offset,
				center.y,
				center.z + vertical_offset
			)

			slots.append(slot)
			generated_center += slot

	generated_center /= float(slots.size())

	var centering_correction: Vector3 = (
		center - generated_center
	)

	for slot_index: int in range(slots.size()):
		slots[slot_index] += centering_correction

	return slots

func assign_slots(
	entities: EntityStore,
	entity_indices: PackedInt32Array,
	slots: PackedVector3Array
) -> PackedVector3Array:
	var destinations := PackedVector3Array()

	if not DawnfallLog.require_valid(
		entity_indices.size() == slots.size(),
		"Formation assignment requires one slot per entity.",
		&"FormationMovePlanner"
	):
		return destinations

	if entity_indices.is_empty():
		return destinations

	var positions := PackedVector3Array()

	for entity_index: int in entity_indices:
		if not entities.is_index_alive(entity_index):
			return PackedVector3Array()

		positions.append(entities.positions[entity_index])

	var slot_assignments: PackedInt32Array

	if entity_indices.size() <= HUNGARIAN_UNIT_LIMIT:
		slot_assignments = _assign_hungarian(
			positions,
			slots
		)
	else:
		slot_assignments = _assign_large_group(
			positions,
			slots
		)

	for entity_order: int in range(entity_indices.size()):
		destinations.append(
			slots[slot_assignments[entity_order]]
		)

	return destinations


func _assign_hungarian(
	positions: PackedVector3Array,
	slots: PackedVector3Array
) -> PackedInt32Array:
	var count: int = positions.size()
	var costs: Array[PackedInt32Array] = []

	for entity_order: int in range(count):
		var row := PackedInt32Array()

		for slot_index: int in range(count):
			row.append(
				roundi(
					_ground_distance(
						positions[entity_order],
						slots[slot_index]
					)
				)
			)

		costs.append(row)

	var row_potentials := PackedInt32Array()
	var column_potentials := PackedInt32Array()
	var matched_rows := PackedInt32Array()
	var previous_columns := PackedInt32Array()

	row_potentials.resize(count + 1)
	column_potentials.resize(count + 1)
	matched_rows.resize(count + 1)
	previous_columns.resize(count + 1)

	for row_index: int in range(1, count + 1):
		matched_rows[0] = row_index

		var current_column: int = 0
		var minimum_values := PackedInt32Array()
		var used_columns := PackedByteArray()

		minimum_values.resize(count + 1)
		minimum_values.fill(INFINITE_COST)
		used_columns.resize(count + 1)

		while true:
			used_columns[current_column] = 1

			var current_row: int = (
				matched_rows[current_column]
			)
			var delta: int = INFINITE_COST
			var next_column: int = 0

			for column_index: int in range(1, count + 1):
				if used_columns[column_index] == 1:
					continue

				var reduced_cost: int = (
					costs[current_row - 1][column_index - 1]
					- row_potentials[current_row]
					- column_potentials[column_index]
				)

				if reduced_cost < minimum_values[column_index]:
					minimum_values[column_index] = reduced_cost
					previous_columns[column_index] = (
						current_column
					)

				if minimum_values[column_index] < delta:
					delta = minimum_values[column_index]
					next_column = column_index

			for column_index: int in range(count + 1):
				if used_columns[column_index] == 1:
					row_potentials[
						matched_rows[column_index]
					] += delta
					column_potentials[column_index] -= delta
				else:
					minimum_values[column_index] -= delta

			current_column = next_column

			if matched_rows[current_column] == 0:
				break

		while true:
			var previous_column: int = (
				previous_columns[current_column]
			)

			matched_rows[current_column] = (
				matched_rows[previous_column]
			)
			current_column = previous_column

			if current_column == 0:
				break

	var assignments := PackedInt32Array()

	assignments.resize(count)

	for column_index: int in range(1, count + 1):
		var matched_row: int = matched_rows[column_index]

		assignments[matched_row - 1] = column_index - 1

	return assignments


func _assign_large_group(
	positions: PackedVector3Array,
	slots: PackedVector3Array
) -> PackedInt32Array:
	var algorithm_start: int = Time.get_ticks_usec()
	var position_axis: Dictionary = _find_farthest_axis(
		positions
	)
	var slot_axis: Dictionary = _find_farthest_axis(slots)
	var axis: Vector2

	if (
		float(slot_axis["distance_squared"])
		> float(position_axis["distance_squared"])
	):
		axis = slot_axis["direction"]
	else:
		axis = position_axis["direction"]

	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	else:
		axis = axis.normalized()

	var unit_entries: Array[SortEntry] = []
	var slot_entries: Array[SortEntry] = []

	for entity_order: int in range(positions.size()):
		var position: Vector3 = positions[entity_order]

		unit_entries.append(
			SortEntry.new(
				entity_order,
				position,
				Vector2(position.x, position.z).dot(axis)
			)
		)

	for slot_index: int in range(slots.size()):
		var slot: Vector3 = slots[slot_index]

		slot_entries.append(
			SortEntry.new(
				slot_index,
				slot,
				Vector2(slot.x, slot.z).dot(axis)
			)
		)

	unit_entries.sort_custom(_sort_entries)
	slot_entries.sort_custom(_sort_entries)

	var assignments := PackedInt32Array()

	assignments.resize(positions.size())

	for sorted_index: int in range(unit_entries.size()):
		var unit_entry: SortEntry = unit_entries[sorted_index]
		var slot_entry: SortEntry = slot_entries[sorted_index]

		assignments[unit_entry.source_index] = (
			slot_entry.source_index
		)

	_remove_crossings(
		positions,
		slots,
		assignments,
		algorithm_start
	)

	return assignments


func _remove_crossings(
	positions: PackedVector3Array,
	slots: PackedVector3Array,
	assignments: PackedInt32Array,
	algorithm_start: int
) -> void:
	var deadline: int = (
		algorithm_start + CROSSING_REMOVAL_MICROSECONDS
	)
	var finished: Array[int] = []
	var pending: Array[int] = []

	for entity_order: int in range(positions.size()):
		pending.append(entity_order)

	var comparison_count: int = 0

	while not pending.is_empty():
		if Time.get_ticks_usec() >= deadline:
			return

		var entity_order: int = pending[pending.size() - 1]
		var crossing_found: bool = false

		for finished_index: int in range(finished.size()):
			comparison_count += 1

			if (
				comparison_count % 64 == 0
				and Time.get_ticks_usec() >= deadline
			):
				return

			var other_entity_order: int = (
				finished[finished_index]
			)

			if not _segments_cross(
				positions[entity_order],
				slots[assignments[entity_order]],
				positions[other_entity_order],
				slots[assignments[other_entity_order]]
			):
				continue

			var temporary_slot: int = assignments[entity_order]

			assignments[entity_order] = (
				assignments[other_entity_order]
			)
			assignments[other_entity_order] = temporary_slot

			finished.remove_at(finished_index)
			pending.append(other_entity_order)
			crossing_found = true
			break

		if crossing_found:
			continue

		finished.append(entity_order)
		pending.pop_back()


func _find_farthest_axis(
	points: PackedVector3Array
) -> Dictionary:
	var greatest_distance_squared: float = -1.0
	var direction := Vector2.RIGHT

	for first_index: int in range(points.size() - 1):
		var first := Vector2(
			points[first_index].x,
			points[first_index].z
		)

		for second_index: int in range(
			first_index + 1,
			points.size()
		):
			var second := Vector2(
				points[second_index].x,
				points[second_index].z
			)
			var offset: Vector2 = second - first
			var distance_squared: float = (
				offset.length_squared()
			)

			if distance_squared > greatest_distance_squared:
				greatest_distance_squared = distance_squared
				direction = offset

	return {
		"distance_squared": greatest_distance_squared,
		"direction": direction,
	}


func _segments_cross(
	first_start: Vector3,
	first_end: Vector3,
	second_start: Vector3,
	second_end: Vector3
) -> bool:
	var a := Vector2(first_start.x, first_start.z)
	var b := Vector2(first_end.x, first_end.z)
	var c := Vector2(second_start.x, second_start.z)
	var d := Vector2(second_end.x, second_end.z)

	var first_side: float = _orientation(a, b, c)
	var second_side: float = _orientation(a, b, d)
	var third_side: float = _orientation(c, d, a)
	var fourth_side: float = _orientation(c, d, b)

	return (
		first_side * second_side < 0.0
		and third_side * fourth_side < 0.0
	)


func _orientation(
	first: Vector2,
	second: Vector2,
	point: Vector2
) -> float:
	return (
		(second.x - first.x) * (point.y - first.y)
		- (second.y - first.y) * (point.x - first.x)
	)


func _sort_entries(
	first: SortEntry,
	second: SortEntry
) -> bool:
	if is_equal_approx(
		first.projection,
		second.projection
	):
		return first.source_index < second.source_index

	return first.projection < second.projection


func _ground_distance(
	first: Vector3,
	second: Vector3
) -> float:
	var offset: Vector3 = second - first

	offset.y = 0.0

	return offset.length()

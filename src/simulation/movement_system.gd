class_name MovementSystem
extends RefCounted


const ARRIVAL_DISTANCE: float = 0.05
const MINIMUM_DECELERATION: float = 0.001

const SEPARATION_PADDING: float = 0.20
const SEPARATION_STRENGTH: float = 1.25
const SIDE_STEP_STRENGTH: float = 0.65
const PREDICTION_TICK_COUNT: float = 3.0
const MAXIMUM_NEIGHBORS: int = 8
const MINIMUM_DISTANCE_SQUARED: float = 0.000001


var last_neighbors_examined: int = 0
var last_neighbors_accepted: int = 0
var last_maximum_neighbors: int = 0


var _moving_indices := PackedInt32Array()
var _planned_positions := PackedVector3Array()
var _planned_headings := PackedFloat32Array()
var _planned_speeds := PackedFloat32Array()
var _planned_arrivals := PackedByteArray()
var _neighbor_indices := PackedInt32Array()
var _neighbor_distances_squared := PackedFloat32Array()


func step(
	entities: EntityStore,
	spatial_grid: SpatialGrid,
	delta_seconds: float
) -> PackedInt32Array:
	var changed_indices := PackedInt32Array()

	last_neighbors_examined = 0
	last_neighbors_accepted = 0
	last_maximum_neighbors = 0

	if delta_seconds <= 0.0:
		return changed_indices

	_prepare_scratch(entities.capacity())
	_moving_indices.clear()

	var global_maxima: Vector2 = _find_global_maxima(entities)
	var maximum_collision_radius: float = global_maxima.x
	var maximum_movement_speed: float = global_maxima.y
	var prediction_seconds: float = (
		delta_seconds * PREDICTION_TICK_COUNT
	)

	# Planning pass: nothing in EntityStore is changed here.
	for index: int in range(entities.capacity()):
		if not entities.has_move_target_by_index(index):
			continue

		_moving_indices.append(index)

		_plan_entity(
			entities,
			spatial_grid,
			index,
			delta_seconds,
			maximum_collision_radius,
			maximum_movement_speed,
			prediction_seconds
		)

	# Application pass: every plan used the same start-of-tick state.
	for index: int in _moving_indices:
		var previous_position: Vector3 = entities.positions[index]
		var previous_heading: float = entities.headings[index]

		entities.positions[index] = _planned_positions[index]
		entities.headings[index] = _planned_headings[index]
		entities.current_speeds[index] = _planned_speeds[index]

		if _planned_arrivals[index] == 1:
			entities.clear_move_target_by_index(index)

		if (
			not previous_position.is_equal_approx(
				entities.positions[index]
			)
			or not is_equal_approx(
				previous_heading,
				entities.headings[index]
			)
		):
			changed_indices.append(index)

	return changed_indices


func _plan_entity(
	entities: EntityStore,
	spatial_grid: SpatialGrid,
	index: int,
	delta_seconds: float,
	maximum_collision_radius: float,
	maximum_movement_speed: float,
	prediction_seconds: float
) -> void:
	var current_position: Vector3 = entities.positions[index]
	var target_position: Vector3 = entities.movement_targets[index]
	var target_offset: Vector3 = target_position - current_position

	target_offset.y = 0.0

	var distance: float = target_offset.length()

	_planned_positions[index] = current_position
	_planned_headings[index] = entities.headings[index]
	_planned_speeds[index] = entities.current_speeds[index]
	_planned_arrivals[index] = 0

	if distance <= ARRIVAL_DISTANCE:
		_planned_positions[index] = target_position
		_planned_speeds[index] = 0.0
		_planned_arrivals[index] = 1
		return

	var target_direction: Vector3 = target_offset / distance
	var steering_direction: Vector3 = _calculate_steering_direction(
		entities,
		spatial_grid,
		index,
		target_direction,
		maximum_collision_radius,
		maximum_movement_speed,
		prediction_seconds
	)

	var desired_heading: float = atan2(
		steering_direction.x,
		steering_direction.z
	)
	var current_heading: float = entities.headings[index]
	var maximum_heading_change: float = (
		entities.turn_speeds_radians[index]
		* delta_seconds
	)
	var heading_difference: float = wrapf(
		desired_heading - current_heading,
		-PI,
		PI
	)

	current_heading += clampf(
		heading_difference,
		-maximum_heading_change,
		maximum_heading_change
	)

	_planned_headings[index] = wrapf(
		current_heading,
		-PI,
		PI
	)

	var current_speed: float = entities.current_speeds[index]
	var maximum_speed: float = entities.maximum_speeds[index]
	var acceleration: float = entities.accelerations[index]
	var deceleration: float = maxf(
		entities.decelerations[index],
		MINIMUM_DECELERATION
	)
	var stopping_distance: float = (
		(current_speed * current_speed)
		/ (2.0 * deceleration)
	)

	if distance <= stopping_distance:
		current_speed = move_toward(
			current_speed,
			0.0,
			deceleration * delta_seconds
		)
	else:
		current_speed = move_toward(
			current_speed,
			maximum_speed,
			acceleration * delta_seconds
		)

	_planned_speeds[index] = current_speed

	var travel_distance: float = minf(
		current_speed * delta_seconds,
		distance
	)

	if travel_distance >= distance:
		_planned_positions[index] = target_position
		_planned_speeds[index] = 0.0
		_planned_arrivals[index] = 1
		return

	_planned_positions[index] = (
		current_position
		+ steering_direction * travel_distance
	)


func _calculate_steering_direction(
	entities: EntityStore,
	spatial_grid: SpatialGrid,
	index: int,
	target_direction: Vector3,
	maximum_collision_radius: float,
	maximum_movement_speed: float,
	prediction_seconds: float
) -> Vector3:
	var current_position: Vector3 = entities.positions[index]
	var own_radius: float = entities.collision_radii[index]
	var own_maximum_speed: float = entities.maximum_speeds[index]
	var query_radius: float = (
		own_radius
		+ maximum_collision_radius
		+ SEPARATION_PADDING
		+ (
			own_maximum_speed
			+ maximum_movement_speed
		) * prediction_seconds
	)

	var query_counts: Vector2i = (
		spatial_grid.query_nearest_radius_into(
			current_position,
			query_radius,
			entities,
			entities.owner_ids[index],
			index,
			MAXIMUM_NEIGHBORS,
			_neighbor_indices,
			_neighbor_distances_squared
		)
	)
	var examined_count: int = query_counts.x
	var neighbor_count: int = query_counts.y

	last_neighbors_examined += examined_count
	last_neighbors_accepted += neighbor_count
	last_maximum_neighbors = maxi(
		last_maximum_neighbors,
		neighbor_count
	)

	var separation := Vector3.ZERO
	var side_step := Vector3.ZERO
	var influence_count: int = 0
	var own_velocity: Vector3 = (
		target_direction
		* entities.current_speeds[index]
	)

	for neighbor_slot: int in range(neighbor_count):
		var neighbor_index: int = (
			_neighbor_indices[neighbor_slot]
		)
		var neighbor_position: Vector3 = (
			entities.positions[neighbor_index]
		)
		var to_neighbor: Vector3 = (
			neighbor_position - current_position
		)

		to_neighbor.y = 0.0

		var distance_squared: float = (
			_neighbor_distances_squared[neighbor_slot]
		)
		var distance: float = sqrt(distance_squared)
		var minimum_separation: float = (
			own_radius
			+ entities.collision_radii[neighbor_index]
		)
		var neighbor_velocity: Vector3 = (
			_get_current_velocity(
				entities,
				neighbor_index
			)
		)
		var relative_velocity: Vector3 = (
			own_velocity - neighbor_velocity
		)
		var closing_speed: float = 0.0

		if distance_squared > MINIMUM_DISTANCE_SQUARED:
			closing_speed = maxf(
				0.0,
				(to_neighbor / distance).dot(
					relative_velocity
				)
			)

		var influence_distance: float = (
			minimum_separation
			+ SEPARATION_PADDING
			+ closing_speed * prediction_seconds
		)

		if distance >= influence_distance:
			continue

		var away_direction: Vector3

		if distance_squared <= MINIMUM_DISTANCE_SQUARED:
			away_direction = (
				Vector3.RIGHT
				if index < neighbor_index
				else Vector3.LEFT
			)
		else:
			away_direction = -to_neighbor / distance

		var proximity: float = 1.0 - clampf(
			distance / influence_distance,
			0.0,
			1.0
		)

		separation += away_direction * proximity

		if closing_speed > 0.0:
			var perpendicular := Vector3(
				-target_direction.z,
				0.0,
				target_direction.x
			)

			side_step += (
				perpendicular
				* _pair_side_sign(
					index,
					neighbor_index
				)
				* proximity
			)

		influence_count += 1

	if influence_count == 0:
		return target_direction

	var divisor: float = float(influence_count)
	var steered_direction: Vector3 = (
		target_direction
		+ (
			separation / divisor
		) * SEPARATION_STRENGTH
		+ (
			side_step / divisor
		) * SIDE_STEP_STRENGTH
	)

	steered_direction.y = 0.0

	if (
		steered_direction.length_squared()
		<= MINIMUM_DISTANCE_SQUARED
	):
		return target_direction

	return steered_direction.normalized()


func _get_current_velocity(
	entities: EntityStore,
	index: int
) -> Vector3:
	if not entities.has_move_target_by_index(index):
		return Vector3.ZERO

	var offset: Vector3 = (
		entities.movement_targets[index]
		- entities.positions[index]
	)

	offset.y = 0.0

	if offset.length_squared() <= MINIMUM_DISTANCE_SQUARED:
		return Vector3.ZERO

	return (
		offset.normalized()
		* entities.current_speeds[index]
	)


func _pair_side_sign(
	first_index: int,
	second_index: int
) -> float:
	var lower_index: int = mini(
		first_index,
		second_index
	)
	var upper_index: int = maxi(
		first_index,
		second_index
	)
	var mixed_value: int = (
		(lower_index * 73856093)
		^ (upper_index * 19349663)
	)

	return (
		1.0
		if (mixed_value & 1) == 0
		else -1.0
	)


func _find_global_maxima(
	entities: EntityStore
) -> Vector2:
	var maximum_radius: float = 0.0
	var maximum_speed: float = 0.0

	for index: int in range(entities.capacity()):
		if not entities.is_index_alive(index):
			continue

		maximum_radius = maxf(
			maximum_radius,
			entities.collision_radii[index]
		)
		maximum_speed = maxf(
			maximum_speed,
			entities.maximum_speeds[index]
		)

	return Vector2(maximum_radius, maximum_speed)


func _prepare_scratch(required_size: int) -> void:
	if _planned_positions.size() != required_size:
		_planned_positions.resize(required_size)
		_planned_headings.resize(required_size)
		_planned_speeds.resize(required_size)
		_planned_arrivals.resize(required_size)

	if _neighbor_indices.size() != MAXIMUM_NEIGHBORS:
		_neighbor_indices.resize(MAXIMUM_NEIGHBORS)
		_neighbor_distances_squared.resize(
			MAXIMUM_NEIGHBORS
		)

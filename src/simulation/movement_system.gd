class_name MovementSystem
extends RefCounted


const ARRIVAL_DISTANCE: float = 0.05
const MINIMUM_DECELERATION: float = 0.001


func step(
	entities: EntityStore,
	delta_seconds: float
) -> PackedInt32Array:
	var changed_indices := PackedInt32Array()

	if delta_seconds <= 0.0:
		return changed_indices

	for index: int in range(entities.capacity()):
		if not entities.has_move_target_by_index(index):
			continue

		if _step_entity(entities, index, delta_seconds):
			changed_indices.append(index)

	return changed_indices


func _step_entity(
	entities: EntityStore,
	index: int,
	delta_seconds: float
) -> bool:
	var current_position: Vector3 = entities.positions[index]
	var initial_heading: float = entities.headings[index]
	var target_position: Vector3 = entities.movement_targets[index]
	var offset: Vector3 = target_position - current_position

	# Ground movement currently ignores height.
	offset.y = 0.0

	var distance: float = offset.length()

	if distance <= ARRIVAL_DISTANCE:
		entities.positions[index] = target_position
		entities.clear_move_target_by_index(index)

		return not current_position.is_equal_approx(
			entities.positions[index]
		)

	var direction: Vector3 = offset / distance
	var desired_heading: float = atan2(direction.x, direction.z)
	var current_heading: float = entities.headings[index]
	var maximum_heading_change: float = (
		entities.turn_speeds_radians[index] * delta_seconds
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

	entities.headings[index] = wrapf(current_heading, -PI, PI)

	var current_speed: float = entities.current_speeds[index]
	var maximum_speed: float = entities.maximum_speeds[index]
	var acceleration: float = entities.accelerations[index]
	var deceleration: float = maxf(
		entities.decelerations[index],
		MINIMUM_DECELERATION
	)

	var stopping_distance: float = (
		(current_speed * current_speed) / (2.0 * deceleration)
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

	entities.current_speeds[index] = current_speed

	var travel_distance: float = minf(
		current_speed * delta_seconds,
		distance
	)

	entities.positions[index] = (
		current_position + direction * travel_distance
	)

	if travel_distance >= distance:
		entities.positions[index] = target_position
		entities.clear_move_target_by_index(index)

	return (
		not current_position.is_equal_approx(
			entities.positions[index]
		)
		or not is_equal_approx(
			initial_heading,
			entities.headings[index]
		)
	)

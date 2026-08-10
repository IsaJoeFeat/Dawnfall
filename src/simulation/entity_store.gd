class_name EntityStore
extends RefCounted


const FLAG_HAS_MOVE_TARGET: int = 1 << 0


var positions := PackedVector3Array()
var collision_radii := PackedFloat32Array()
var headings := PackedFloat32Array()

var current_health := PackedFloat32Array()
var maximum_health := PackedFloat32Array()

var current_speeds := PackedFloat32Array()
var maximum_speeds := PackedFloat32Array()
var accelerations := PackedFloat32Array()
var decelerations := PackedFloat32Array()
var turn_speeds_radians := PackedFloat32Array()
var movement_targets := PackedVector3Array()

var owner_ids := PackedInt32Array()
var definition_indices := PackedInt32Array()
var flags := PackedInt32Array()

var _alive_flags := PackedByteArray()
var _generations := PackedInt32Array()
var _free_indices: Array[int] = []
var _alive_count: int = 0


func create_entity(
	definition_index: int,
	owner_id: int,
	position: Vector3,
	max_health: float,
	collision_radius: float,
	movement_max_speed: float,
	movement_acceleration: float,
	movement_deceleration: float,
	movement_turn_speed_radians: float,
	heading: float = 0.0
) -> int:
	if not DawnfallLog.require_valid(
		definition_index >= 0,
		"Definition index cannot be negative.",
		&"EntityStore"
	):
		return EntityId.INVALID

	if not DawnfallLog.require_valid(
		owner_id >= -1,
		"Owner ID cannot be less than -1.",
		&"EntityStore"
	):
		return EntityId.INVALID

	if not DawnfallLog.require_valid(
		max_health > 0.0,
		"Maximum health must be greater than zero.",
		&"EntityStore"
	):
		return EntityId.INVALID

	if not DawnfallLog.require_valid(
		movement_max_speed >= 0.0
		and movement_acceleration >= 0.0
		and movement_deceleration >= 0.0
		and movement_turn_speed_radians >= 0.0,
		"Movement values cannot be negative.",
		&"EntityStore"
	):
		return EntityId.INVALID
	
	if not DawnfallLog.require_valid(
		collision_radius > 0.0,
		"Collision radius must be greater than zero.",
		&"EntityStore"
	):
		return EntityId.INVALID

	var index: int

	if _free_indices.is_empty():
		index = _append_empty_slot()
	else:
		index = _free_indices.pop_back()

	_alive_flags[index] = 1
	positions[index] = position
	headings[index] = heading
	collision_radii[index] = collision_radius

	current_health[index] = max_health
	maximum_health[index] = max_health

	current_speeds[index] = 0.0
	maximum_speeds[index] = movement_max_speed
	accelerations[index] = movement_acceleration
	decelerations[index] = movement_deceleration
	turn_speeds_radians[index] = movement_turn_speed_radians
	movement_targets[index] = position

	owner_ids[index] = owner_id
	definition_indices[index] = definition_index
	flags[index] = 0

	_alive_count += 1

	return EntityId.create(index, _generations[index])


func destroy_entity(entity_id: int) -> bool:
	if not is_alive(entity_id):
		return false

	var index: int = EntityId.get_index(entity_id)

	_alive_flags[index] = 0
	positions[index] = Vector3.ZERO
	headings[index] = 0.0
	collision_radii[index] = 0.0

	current_health[index] = 0.0
	maximum_health[index] = 0.0

	current_speeds[index] = 0.0
	maximum_speeds[index] = 0.0
	accelerations[index] = 0.0
	decelerations[index] = 0.0
	turn_speeds_radians[index] = 0.0
	movement_targets[index] = Vector3.ZERO

	owner_ids[index] = -1
	definition_indices[index] = -1
	flags[index] = 0

	_generations[index] += 1

	if _generations[index] <= 0:
		_generations[index] = 1

	_free_indices.append(index)
	_alive_count -= 1

	return true


func is_alive(entity_id: int) -> bool:
	if not EntityId.is_valid(entity_id):
		return false

	var index: int = EntityId.get_index(entity_id)

	if not is_index_alive(index):
		return false

	return _generations[index] == EntityId.get_generation(entity_id)


func is_index_alive(index: int) -> bool:
	return (
		index >= 0
		and index < _alive_flags.size()
		and _alive_flags[index] == 1
	)


func set_move_target(entity_id: int, destination: Vector3) -> bool:
	var index: int = get_index_if_alive(entity_id)

	if index < 0:
		return false

	if maximum_speeds[index] <= 0.0:
		return false

	movement_targets[index] = destination
	flags[index] = flags[index] | FLAG_HAS_MOVE_TARGET

	return true


func clear_move_target_by_index(index: int) -> void:
	if not is_index_alive(index):
		return

	flags[index] = flags[index] & ~FLAG_HAS_MOVE_TARGET
	current_speeds[index] = 0.0


func has_move_target_by_index(index: int) -> bool:
	if not is_index_alive(index):
		return false

	return (flags[index] & FLAG_HAS_MOVE_TARGET) != 0


func get_position(entity_id: int) -> Vector3:
	var index: int = get_index_if_alive(entity_id)

	if index < 0:
		return Vector3.ZERO

	return positions[index]


func set_position(entity_id: int, new_position: Vector3) -> bool:
	var index: int = get_index_if_alive(entity_id)

	if index < 0:
		return false

	positions[index] = new_position
	return true

func get_id_by_index(index: int) -> int:
	if not is_index_alive(index):
		return EntityId.INVALID

	return EntityId.create(index, _generations[index])

func get_index_if_alive(entity_id: int) -> int:
	if not is_alive(entity_id):
		return -1

	return EntityId.get_index(entity_id)


func alive_count() -> int:
	return _alive_count


func capacity() -> int:
	return _alive_flags.size()


func clear() -> void:
	positions.clear()
	headings.clear()
	collision_radii.clear()

	current_health.clear()
	maximum_health.clear()

	current_speeds.clear()
	maximum_speeds.clear()
	accelerations.clear()
	decelerations.clear()
	turn_speeds_radians.clear()
	movement_targets.clear()

	owner_ids.clear()
	definition_indices.clear()
	flags.clear()

	_alive_flags.clear()
	_generations.clear()
	_free_indices.clear()

	_alive_count = 0


func _append_empty_slot() -> int:
	var index: int = _alive_flags.size()

	_alive_flags.append(0)
	_generations.append(1)

	positions.append(Vector3.ZERO)
	headings.append(0.0)
	collision_radii.append(0.0)

	current_health.append(0.0)
	maximum_health.append(0.0)

	current_speeds.append(0.0)
	maximum_speeds.append(0.0)
	accelerations.append(0.0)
	decelerations.append(0.0)
	turn_speeds_radians.append(0.0)
	movement_targets.append(Vector3.ZERO)

	owner_ids.append(-1)
	definition_indices.append(-1)
	flags.append(0)

	return index

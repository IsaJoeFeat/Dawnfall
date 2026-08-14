class_name SimulationWorld
extends RefCounted


var entities := EntityStore.new()
var clock := FixedStepClock.new()
var movement_system := MovementSystem.new()
var spatial_grid := SpatialGrid.new(8.0)
var shared_route_request_count: int = 0
var last_shared_route := PackedVector3Array()
var last_movement_milliseconds: float = 0.0
var last_grid_rebuild_milliseconds: float = 0.0


var _changed_transform_indices := PackedInt32Array()
var _changed_transform_lookup: Dictionary = {}


func spawn_unit(
	definition: UnitDefinition,
	definition_index: int,
	owner_id: int,
	position: Vector3,
	heading: float = 0.0
) -> int:
	if not DawnfallLog.require_valid(
		definition != null,
		"Cannot spawn a null unit definition.",
		&"SimulationWorld"
	):
		return EntityId.INVALID

	if not DawnfallLog.require_valid(
		definition.movement_profile != null,
		"Cannot spawn a unit without a movement profile.",
		&"SimulationWorld"
	):
		return EntityId.INVALID

	var movement: MovementDefinition = definition.movement_profile

	return entities.create_entity(
		definition_index,
		owner_id,
		position,
		definition.max_health,
		definition.collision_radius,
		movement.max_speed,
		movement.acceleration,
		movement.deceleration,
		deg_to_rad(movement.turn_speed_degrees),
		heading
	)


func issue_move(
	entity_ids: PackedInt64Array,
	destination: Vector3
) -> int:
	var accepted_count: int = 0

	for entity_id: int in entity_ids:
		if entities.set_move_target(entity_id, destination):
			accepted_count += 1

	return accepted_count

func issue_group_move(
	entity_ids: PackedInt64Array,
	destinations: PackedVector3Array
) -> int:
	if not DawnfallLog.require_valid(
		entity_ids.size() == destinations.size(),
		"Group movement requires one destination per entity.",
		&"SimulationWorld"
	):
		return 0

	if entity_ids.is_empty():
		return 0

	var valid_entity_ids := PackedInt64Array()
	var valid_destinations := PackedVector3Array()
	var route_start := Vector3.ZERO
	var route_destination := Vector3.ZERO

	for order_index: int in range(entity_ids.size()):
		var entity_id: int = entity_ids[order_index]
		var entity_index: int = entities.get_index_if_alive(
			entity_id
		)

		if entity_index < 0:
			continue

		if entities.maximum_speeds[entity_index] <= 0.0:
			continue

		valid_entity_ids.append(entity_id)
		valid_destinations.append(destinations[order_index])
		route_start += entities.positions[entity_index]
		route_destination += destinations[order_index]

	if valid_entity_ids.is_empty():
		return 0

	var valid_count: float = float(valid_entity_ids.size())

	route_start /= valid_count
	route_destination /= valid_count

	last_shared_route = PackedVector3Array()
	last_shared_route.append(route_start)
	last_shared_route.append(route_destination)
	shared_route_request_count += 1

	var accepted_count: int = 0

	for order_index: int in range(valid_entity_ids.size()):
		if entities.set_move_target(
			valid_entity_ids[order_index],
			valid_destinations[order_index]
		):
			accepted_count += 1

	return accepted_count

func rebuild_spatial_grid() -> void:
	spatial_grid.rebuild(entities)


func query_entities_in_radius(
	center: Vector3,
	radius: float,
	owner_filter: int = SpatialGrid.ANY_OWNER
) -> PackedInt32Array:
	return spatial_grid.query_radius(
		center,
		radius,
		entities,
		owner_filter
	)

func query_entities_in_aabb(
	minimum: Vector3,
	maximum: Vector3,
	owner_filter: int = SpatialGrid.ANY_OWNER
) -> PackedInt32Array:
	return spatial_grid.query_aabb(
		minimum,
		maximum,
		entities,
		owner_filter
	)

func advance(frame_delta: float) -> int:
	var steps_to_run: int = clock.consume_steps(frame_delta)

	for _step_index: int in range(steps_to_run):
		_simulate_tick(clock.tick_seconds)

	return steps_to_run


func consume_changed_transform_indices() -> PackedInt32Array:
	var changed_indices: PackedInt32Array = (
		_changed_transform_indices
	)

	_changed_transform_indices = PackedInt32Array()
	_changed_transform_lookup.clear()

	return changed_indices


func _simulate_tick(delta_seconds: float) -> void:
	var movement_start: int = Time.get_ticks_usec()

	var changed_indices: PackedInt32Array = movement_system.step(
		entities,
		spatial_grid,
		delta_seconds
	)

	last_movement_milliseconds = (
		float(Time.get_ticks_usec() - movement_start)
		/ 1000.0
	)

	for entity_index: int in changed_indices:
		if _changed_transform_lookup.has(entity_index):
			continue

		_changed_transform_lookup[entity_index] = true
		_changed_transform_indices.append(entity_index)

	var grid_start: int = Time.get_ticks_usec()

	spatial_grid.rebuild(entities)

	last_grid_rebuild_milliseconds = (
		float(Time.get_ticks_usec() - grid_start)
		/ 1000.0
	)

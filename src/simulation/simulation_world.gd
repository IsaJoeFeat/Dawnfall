class_name SimulationWorld
extends RefCounted


var entities := EntityStore.new()
var clock := FixedStepClock.new()
var movement_system := MovementSystem.new()
var spatial_grid := SpatialGrid.new(8.0)


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


func advance(frame_delta: float) -> int:
	var steps_to_run: int = clock.consume_steps(frame_delta)

	for _step_index: int in range(steps_to_run):
		_simulate_tick(clock.tick_seconds)

	return steps_to_run


func _simulate_tick(delta_seconds: float) -> void:
	movement_system.step(entities, delta_seconds)
	spatial_grid.rebuild(entities)

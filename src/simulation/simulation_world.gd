class_name SimulationWorld
extends RefCounted


const NO_SHARED_ROUTE: int = -1


var entities := EntityStore.new()
var clock := FixedStepClock.new()
var movement_system := MovementSystem.new()
var spatial_grid := SpatialGrid.new(8.0)
var navigation_grid: NavigationGrid

var shared_route_request_count: int = 0
var last_shared_route := PackedVector3Array()

var last_movement_milliseconds: float = 0.0
var last_grid_rebuild_milliseconds: float = 0.0


var _changed_transform_indices := PackedInt32Array()
var _changed_transform_lookup: Dictionary = {}

var _shared_routes: Dictionary = {}
var _shared_route_remaining_counts: Dictionary = {}
var _next_shared_route_id: int = 1

var _entity_route_ids := PackedInt32Array()
var _entity_route_waypoint_indices := PackedInt32Array()
var _entity_route_final_destinations := PackedVector3Array()


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

	var entity_id: int = entities.create_entity(
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

	if EntityId.is_valid(entity_id):
		var entity_index: int = (
			entities.get_index_if_alive(entity_id)
		)

		_prepare_route_state(
			entities.capacity()
		)

		_cancel_route_for_index(
			entity_index
		)

	return entity_id


func configure_navigation(
	origin: Vector3,
	world_size: Vector2,
	cell_size: float
) -> void:
	navigation_grid = NavigationGrid.new()

	navigation_grid.configure(
		origin,
		world_size,
		cell_size
	)


func set_navigation_cell_blocked(
	cell: Vector2i,
	blocked: bool = true
) -> void:
	if navigation_grid == null:
		return

	navigation_grid.set_cell_blocked(
		cell,
		blocked
	)


func build_shared_route(
	start_position: Vector3,
	destination: Vector3
) -> PackedVector3Array:
	if navigation_grid == null:
		var direct_route := PackedVector3Array()

		direct_route.append(
			start_position
		)

		direct_route.append(
			destination
		)

		return direct_route

	return navigation_grid.find_route(
		start_position,
		destination
	)


func issue_move(
	entity_ids: PackedInt64Array,
	destination: Vector3
) -> int:
	var accepted_count: int = 0

	_prepare_route_state(
		entities.capacity()
	)

	for entity_id: int in entity_ids:
		var entity_index: int = (
			entities.get_index_if_alive(
				entity_id
			)
		)

		if entity_index < 0:
			continue

		_cancel_route_for_index(
			entity_index
		)

		if entities.set_move_target(
			entity_id,
			destination
		):
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
	var valid_entity_indices := PackedInt32Array()
	var valid_destinations := PackedVector3Array()

	var route_start := Vector3.ZERO
	var route_destination := Vector3.ZERO

	for order_index: int in range(
		entity_ids.size()
	):
		var entity_id: int = (
			entity_ids[order_index]
		)

		var entity_index: int = (
			entities.get_index_if_alive(
				entity_id
			)
		)

		if entity_index < 0:
			continue

		if (
			entities.maximum_speeds[
				entity_index
			] <= 0.0
		):
			continue

		valid_entity_ids.append(
			entity_id
		)

		valid_entity_indices.append(
			entity_index
		)

		valid_destinations.append(
			destinations[order_index]
		)

		route_start += (
			entities.positions[
				entity_index
			]
		)

		route_destination += (
			destinations[
				order_index
			]
		)

	if valid_entity_ids.is_empty():
		return 0

	var valid_count: float = float(
		valid_entity_ids.size()
	)

	route_start /= valid_count
	route_destination /= valid_count

	last_shared_route = build_shared_route(
		route_start,
		route_destination
	)

	shared_route_request_count += 1

	if last_shared_route.size() < 2:
		return 0

	_prepare_route_state(
		entities.capacity()
	)

	var route_id: int = (
		_next_shared_route_id
	)

	_next_shared_route_id += 1

	_shared_routes[route_id] = (
		last_shared_route
	)

	var final_waypoint_index: int = (
		last_shared_route.size() - 1
	)

	var accepted_count: int = 0

	for order_index: int in range(
		valid_entity_ids.size()
	):
		var entity_id: int = (
			valid_entity_ids[
				order_index
			]
		)

		var entity_index: int = (
			valid_entity_indices[
				order_index
			]
		)

		var final_destination: Vector3 = (
			valid_destinations[
				order_index
			]
		)

		_cancel_route_for_index(
			entity_index
		)

		var first_target: Vector3

		if final_waypoint_index == 1:
			# Direct route: go straight to this
			# unit's assigned final slot.
			first_target = final_destination
		else:
			# Routed movement: all units initially
			# follow the shared strategic path.
			first_target = (
				last_shared_route[1]
			)

		if not entities.set_move_target(
			entity_id,
			first_target
		):
			continue

		_entity_route_ids[
			entity_index
		] = route_id

		_entity_route_waypoint_indices[
			entity_index
		] = 1

		_entity_route_final_destinations[
			entity_index
		] = final_destination

		accepted_count += 1

	if accepted_count <= 0:
		_shared_routes.erase(
			route_id
		)

		return 0

	_shared_route_remaining_counts[
		route_id
	] = accepted_count

	return accepted_count


func rebuild_spatial_grid() -> void:
	spatial_grid.rebuild(
		entities
	)


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


func advance(
	frame_delta: float
) -> int:
	var steps_to_run: int = (
		clock.consume_steps(
			frame_delta
		)
	)

	for _step_index: int in range(
		steps_to_run
	):
		_simulate_tick(
			clock.tick_seconds
		)

	return steps_to_run


func consume_changed_transform_indices() -> PackedInt32Array:
	var changed_indices: PackedInt32Array = (
		_changed_transform_indices
	)

	_changed_transform_indices = (
		PackedInt32Array()
	)

	_changed_transform_lookup.clear()

	return changed_indices


func _simulate_tick(
	delta_seconds: float
) -> void:
	var movement_start: int = (
		Time.get_ticks_usec()
	)

	var changed_indices: PackedInt32Array = (
		movement_system.step(
			entities,
			spatial_grid,
			delta_seconds,
			navigation_grid
		)
	)

	last_movement_milliseconds = (
		float(
			Time.get_ticks_usec()
			- movement_start
		)
		/ 1000.0
	)

	for entity_index: int in changed_indices:
		if _changed_transform_lookup.has(
			entity_index
		):
			continue

		_changed_transform_lookup[
			entity_index
		] = true

		_changed_transform_indices.append(
			entity_index
		)

	# MovementSystem clears a move target when the
	# entity reaches it. At that point we can safely
	# hand the entity its next shared-route waypoint.
	_advance_shared_route_followers()

	var grid_start: int = (
		Time.get_ticks_usec()
	)

	spatial_grid.rebuild(
		entities
	)

	last_grid_rebuild_milliseconds = (
		float(
			Time.get_ticks_usec()
			- grid_start
		)
		/ 1000.0
	)


func _advance_shared_route_followers() -> void:
	if _entity_route_ids.is_empty():
		return

	for entity_index: int in range(
		_entity_route_ids.size()
	):
		var route_id: int = (
			_entity_route_ids[
				entity_index
			]
		)

		if route_id == NO_SHARED_ROUTE:
			continue

		if not entities.is_index_alive(
			entity_index
		):
			_cancel_route_for_index(
				entity_index
			)
			continue

		if not _shared_routes.has(
			route_id
		):
			_clear_route_state(
				entity_index
			)
			continue

		# If MovementSystem still has an active target,
		# this waypoint has not been reached yet.
		if entities.has_move_target_by_index(
			entity_index
		):
			continue

		var route: PackedVector3Array = (
			_shared_routes[
				route_id
			]
		)

		if route.size() < 2:
			_cancel_route_for_index(
				entity_index
			)
			continue

		var waypoint_index: int = (
			_entity_route_waypoint_indices[
				entity_index
			]
		)

		var final_waypoint_index: int = (
			route.size() - 1
		)

		# If the final target has already been reached,
		# this route is complete.
		if (
			waypoint_index
			>= final_waypoint_index
		):
			_cancel_route_for_index(
				entity_index
			)
			continue

		# Current waypoint was reached.
		# Advance exactly one waypoint.
		waypoint_index += 1

		_entity_route_waypoint_indices[
			entity_index
		] = waypoint_index

		var next_target: Vector3

		if (
			waypoint_index
			>= final_waypoint_index
		):
			# Only restore formation geometry at the
			# actual final destination.
			next_target = (
				_entity_route_final_destinations[
					entity_index
				]
			)
		else:
			# Intermediate movement follows the shared
			# safe strategic route exactly.
			next_target = (
				route[
					waypoint_index
				]
			)

		var entity_id: int = (
			entities.get_id_by_index(
				entity_index
			)
		)

		if not entities.set_move_target(
			entity_id,
			next_target
		):
			_cancel_route_for_index(
				entity_index
			)


func _prepare_route_state(
	required_size: int
) -> void:
	var previous_size: int = (
		_entity_route_ids.size()
	)

	if previous_size >= required_size:
		return

	_entity_route_ids.resize(
		required_size
	)

	_entity_route_waypoint_indices.resize(
		required_size
	)

	_entity_route_final_destinations.resize(
		required_size
	)

	for index: int in range(
		previous_size,
		required_size
	):
		_entity_route_ids[index] = (
			NO_SHARED_ROUTE
		)

		_entity_route_waypoint_indices[
			index
		] = -1

		_entity_route_final_destinations[
			index
		] = Vector3.ZERO


func _cancel_route_for_index(
	entity_index: int
) -> void:
	if (
		entity_index < 0
		or entity_index
		>= _entity_route_ids.size()
	):
		return

	var route_id: int = (
		_entity_route_ids[
			entity_index
		]
	)

	if route_id == NO_SHARED_ROUTE:
		return

	_clear_route_state(
		entity_index
	)

	if not _shared_route_remaining_counts.has(
		route_id
	):
		return

	var remaining_count: int = (
		int(
			_shared_route_remaining_counts[
				route_id
			]
		)
		- 1
	)

	if remaining_count <= 0:
		_shared_route_remaining_counts.erase(
			route_id
		)

		_shared_routes.erase(
			route_id
		)
	else:
		_shared_route_remaining_counts[
			route_id
		] = remaining_count


func _clear_route_state(
	entity_index: int
) -> void:
	_entity_route_ids[
		entity_index
	] = NO_SHARED_ROUTE

	_entity_route_waypoint_indices[
		entity_index
	] = -1

	_entity_route_final_destinations[
		entity_index
	] = Vector3.ZERO

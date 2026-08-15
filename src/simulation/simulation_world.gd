class_name SimulationWorld
extends RefCounted


const NO_SHARED_ROUTE: int = -1
const AUTO_TARGET_REFRESH_PHASES: int = 10


var entities := EntityStore.new()
var clock := FixedStepClock.new()
var movement_system := MovementSystem.new()
var combat_system := CombatSystem.new()
var spatial_grid := SpatialGrid.new(8.0)
var navigation_grid: NavigationGrid
var targeting_system := TargetingSystem.new()

var shared_route_request_count: int = 0
var last_shared_route := PackedVector3Array()

var last_movement_milliseconds: float = 0.0
var last_grid_rebuild_milliseconds: float = 0.0

var automatic_combat_enabled: bool = false

var last_combat_milliseconds: float = 0.0
var last_auto_target_acquisition_count: int = 0
var last_auto_fire_count: int = 0


var _changed_transform_indices := PackedInt32Array()
var _changed_transform_lookup: Dictionary = {}
var _destroyed_entity_indices := PackedInt32Array()

var _shared_routes: Dictionary = {}
var _shared_route_remaining_counts: Dictionary = {}
var _next_shared_route_id: int = 1
var _automatic_targets_by_entity: Dictionary = {}

var _entity_route_ids := PackedInt32Array()
var _entity_route_waypoint_indices := PackedInt32Array()
var _entity_route_final_destinations := PackedVector3Array()

var _unit_definitions_by_index: Array[UnitDefinition] = []
var _team_ids_by_owner := PackedInt32Array()


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
	if not _register_unit_definition(
		definition_index,
		definition
	):
		return EntityId.INVALID

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

func set_owner_team(
	owner_id: int,
	team_id: int
) -> bool:
	if not DawnfallLog.require_valid(
		owner_id >= 0,
		"Owner ID cannot be negative.",
		&"SimulationWorld"
	):
		return false

	if not DawnfallLog.require_valid(
		team_id >= 0,
		"Team ID cannot be negative.",
		&"SimulationWorld"
	):
		return false

	var previous_size: int = (
		_team_ids_by_owner.size()
	)

	if previous_size <= owner_id:
		_team_ids_by_owner.resize(
			owner_id + 1
		)

		for index: int in range(
			previous_size,
			_team_ids_by_owner.size()
		):
			_team_ids_by_owner[
				index
			] = -1

	_team_ids_by_owner[
		owner_id
	] = team_id

	return true


func get_owner_team(
	owner_id: int
) -> int:
	if (
		owner_id < 0
		or owner_id
		>= _team_ids_by_owner.size()
	):
		return -1

	return _team_ids_by_owner[
		owner_id
	]

func acquire_target_for_weapon(
	attacker_entity_id: int,
	weapon_slot: int
) -> int:
	var attacker_index: int = (
		entities.get_index_if_alive(
			attacker_entity_id
		)
	)

	if attacker_index < 0:
		return EntityId.INVALID

	var definition_index: int = (
		entities.definition_indices[
			attacker_index
		]
	)

	if (
		definition_index < 0
		or definition_index
		>= _unit_definitions_by_index.size()
	):
		return EntityId.INVALID

	var unit_definition: UnitDefinition = (
		_unit_definitions_by_index[
			definition_index
		]
	)

	if unit_definition == null:
		return EntityId.INVALID

	if (
		weapon_slot < 0
		or weapon_slot
		>= unit_definition.weapons.size()
	):
		return EntityId.INVALID

	var weapon: WeaponDefinition = (
		unit_definition.weapons[
			weapon_slot
		]
	)

	return targeting_system.find_nearest_valid_target(
		entities,
		spatial_grid,
		attacker_entity_id,
		weapon,
		_unit_definitions_by_index,
		_team_ids_by_owner
	)

func fire_weapon(
	attacker_entity_id: int,
	target_entity_id: int,
	weapon_slot: int
) -> int:
	var attacker_index: int = (
		entities.get_index_if_alive(
			attacker_entity_id
		)
	)

	if attacker_index < 0:
		return CombatSystem.FireResult.INVALID

	var definition_index: int = (
		entities.definition_indices[
			attacker_index
		]
	)

	if (
		definition_index < 0
		or definition_index
		>= _unit_definitions_by_index.size()
	):
		return CombatSystem.FireResult.INVALID

	var unit_definition: UnitDefinition = (
		_unit_definitions_by_index[
			definition_index
		]
	)

	if unit_definition == null:
		return CombatSystem.FireResult.INVALID

	if (
		weapon_slot < 0
		or weapon_slot
		>= unit_definition.weapons.size()
	):
		return CombatSystem.FireResult.INVALID

	var weapon: WeaponDefinition = (
		unit_definition.weapons[
			weapon_slot
		]
	)

	var fire_result: int = (
		combat_system.try_fire(
			entities,
			attacker_entity_id,
			target_entity_id,
			weapon,
			weapon_slot,
			clock.tick_count,
			clock.tick_seconds
		)
	)

	if (
		fire_result
		!= CombatSystem.FireResult.FIRED
	):
		return fire_result

	apply_damage(
		target_entity_id,
		weapon.base_damage
	)

	return fire_result

func apply_damage(
	entity_id: int,
	damage: float
) -> int:
	var damage_result: int = (
		combat_system.apply_damage(
			entities,
			entity_id,
			damage
		)
	)

	if (
		damage_result
		!= CombatSystem.DamageResult.DESTROYED
	):
		return damage_result

	var entity_index: int = (
		entities.get_index_if_alive(
			entity_id
		)
	)

	if entity_index < 0:
		return damage_result

	_cancel_route_for_index(
		entity_index
	)

	_destroyed_entity_indices.append(
		entity_index
	)
	
	combat_system.forget_entity(
		entity_id
	)

	_automatic_targets_by_entity.erase(
		entity_id
	)

	entities.destroy_entity(
		entity_id
	)

	return damage_result

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

func consume_destroyed_entity_indices() -> PackedInt32Array:
	var destroyed_indices: PackedInt32Array = (
		_destroyed_entity_indices
	)

	_destroyed_entity_indices = (
		PackedInt32Array()
	)

	return destroyed_indices

func _run_automatic_combat() -> void:
	last_auto_target_acquisition_count = 0
	last_auto_fire_count = 0

	var acquisition_phase: int = (
		(clock.tick_count - 1)
		% AUTO_TARGET_REFRESH_PHASES
	)

	for entity_index: int in range(
		entities.capacity()
	):
		if not entities.is_index_alive(
			entity_index
		):
			continue

		var definition_index: int = (
			entities.definition_indices[
				entity_index
			]
		)

		if (
			definition_index < 0
			or definition_index
			>= _unit_definitions_by_index.size()
		):
			continue

		var unit_definition: UnitDefinition = (
			_unit_definitions_by_index[
				definition_index
			]
		)

		if (
			unit_definition == null
			or unit_definition.weapons.is_empty()
		):
			continue

		var attacker_entity_id: int = (
			entities.get_id_by_index(
				entity_index
			)
		)

		var target_ids := PackedInt64Array()

		if _automatic_targets_by_entity.has(
			attacker_entity_id
		):
			target_ids = (
				_automatic_targets_by_entity[
					attacker_entity_id
				]
			)

		if (
			target_ids.size()
			< unit_definition.weapons.size()
		):
			target_ids.resize(
				unit_definition.weapons.size()
			)

		var should_acquire: bool = (
			entity_index
			% AUTO_TARGET_REFRESH_PHASES
			== acquisition_phase
		)

		for weapon_slot: int in range(
			unit_definition.weapons.size()
		):
			var weapon: WeaponDefinition = (
				unit_definition.weapons[
					weapon_slot
				]
			)

			if weapon == null:
				target_ids[
					weapon_slot
				] = EntityId.INVALID
				continue

			# Physical projectile weapons enter later.
			# B4 only automates the hitscan path proven in B2.
			if (
				weapon.delivery_type
				!= WeaponDefinition.DeliveryType.HITSCAN
			):
				target_ids[
					weapon_slot
				] = EntityId.INVALID
				continue

			var target_entity_id: int = (
				target_ids[
					weapon_slot
				]
			)

			# Existing targets are cheap: try to keep using them.
			if EntityId.is_valid(
				target_entity_id
			):
				var fire_result: int = (
					fire_weapon(
						attacker_entity_id,
						target_entity_id,
						weapon_slot
					)
				)

				if (
					fire_result
					== CombatSystem.FireResult.FIRED
				):
					last_auto_fire_count += 1
					continue

				if (
					fire_result
					== CombatSystem.FireResult.RELOADING
				):
					continue

				# Dead, invalid, or out of range:
				# release it and search again later.
				target_ids[
					weapon_slot
				] = EntityId.INVALID

			if not should_acquire:
				continue

			var acquired_target: int = (
				acquire_target_for_weapon(
					attacker_entity_id,
					weapon_slot
				)
			)

			if not EntityId.is_valid(
				acquired_target
			):
				continue

			target_ids[
				weapon_slot
			] = acquired_target

			last_auto_target_acquisition_count += 1

			# A newly acquired target may be fired upon
			# immediately instead of waiting another tick.
			var acquired_fire_result: int = (
				fire_weapon(
					attacker_entity_id,
					acquired_target,
					weapon_slot
				)
			)

			if (
				acquired_fire_result
				== CombatSystem.FireResult.FIRED
			):
				last_auto_fire_count += 1

		var has_target: bool = false

		for target_entity_id: int in target_ids:
			if EntityId.is_valid(
				target_entity_id
			):
				has_target = true
				break

		if has_target:
			_automatic_targets_by_entity[
				attacker_entity_id
			] = target_ids
		else:
			_automatic_targets_by_entity.erase(
				attacker_entity_id
			)

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
	
	if automatic_combat_enabled:
		var combat_start: int = (
			Time.get_ticks_usec()
		)

		_run_automatic_combat()

		last_combat_milliseconds = (
			float(
				Time.get_ticks_usec()
				- combat_start
			)
			/ 1000.0
		)
	else:
		last_combat_milliseconds = 0.0
		last_auto_target_acquisition_count = 0
		last_auto_fire_count = 0


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

func _register_unit_definition(
	definition_index: int,
	definition: UnitDefinition
) -> bool:
	if definition_index < 0:
		return false

	if (
		_unit_definitions_by_index.size()
		<= definition_index
	):
		_unit_definitions_by_index.resize(
			definition_index + 1
		)

	var existing_definition: UnitDefinition = (
		_unit_definitions_by_index[
			definition_index
		]
	)

	if (
		existing_definition != null
		and existing_definition
		!= definition
	):
		return DawnfallLog.require_valid(
			false,
			(
				"Definition index %d is already assigned "
				+ "to another unit definition."
			)
			% definition_index,
			&"SimulationWorld"
		)

	_unit_definitions_by_index[
		definition_index
	] = definition

	return true

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

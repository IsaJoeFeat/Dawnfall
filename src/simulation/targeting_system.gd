class_name TargetingSystem
extends RefCounted


func find_nearest_valid_target(
	entities: EntityStore,
	spatial_grid: SpatialGrid,
	attacker_entity_id: int,
	weapon: WeaponDefinition,
	unit_definitions_by_index: Array[UnitDefinition],
	team_ids_by_owner: PackedInt32Array
) -> int:
	if weapon == null:
		return EntityId.INVALID

	var attacker_index: int = (
		entities.get_index_if_alive(
			attacker_entity_id
		)
	)

	if attacker_index < 0:
		return EntityId.INVALID

	var attacker_owner_id: int = (
		entities.owner_ids[
			attacker_index
		]
	)

	var attacker_team_id: int = _get_team_id(
		attacker_owner_id,
		team_ids_by_owner
	)

	if attacker_team_id < 0:
		return EntityId.INVALID

	var attacker_position: Vector3 = (
		entities.positions[
			attacker_index
		]
	)

	var candidates: PackedInt32Array = (
		spatial_grid.query_radius(
			attacker_position,
			weapon.maximum_range,
			entities,
			SpatialGrid.ANY_OWNER
		)
	)

	var minimum_range_squared: float = (
		weapon.minimum_range
		* weapon.minimum_range
	)

	var best_entity_index: int = -1
	var best_distance_squared: float = INF

	for target_index: int in candidates:
		if target_index == attacker_index:
			continue

		if not entities.is_index_alive(
			target_index
		):
			continue

		var target_owner_id: int = (
			entities.owner_ids[
				target_index
			]
		)

		var target_team_id: int = _get_team_id(
			target_owner_id,
			team_ids_by_owner
		)

		if (
			target_team_id < 0
			or target_team_id == attacker_team_id
		):
			continue

		var definition_index: int = (
			entities.definition_indices[
				target_index
			]
		)

		if (
			definition_index < 0
			or definition_index
			>= unit_definitions_by_index.size()
		):
			continue

		var target_definition: UnitDefinition = (
			unit_definitions_by_index[
				definition_index
			]
		)

		if target_definition == null:
			continue

		if (
			weapon.valid_target_categories
			& target_definition.target_categories
		) == 0:
			continue

		var offset: Vector3 = (
			entities.positions[
				target_index
			]
			- attacker_position
		)

		var distance_squared: float = (
			offset.x * offset.x
			+ offset.z * offset.z
		)

		if (
			distance_squared
			< minimum_range_squared
		):
			continue

		if (
			distance_squared
			< best_distance_squared
			or (
				is_equal_approx(
					distance_squared,
					best_distance_squared
				)
				and (
					best_entity_index < 0
					or target_index
					< best_entity_index
				)
			)
		):
			best_distance_squared = (
				distance_squared
			)

			best_entity_index = (
				target_index
			)

	if best_entity_index < 0:
		return EntityId.INVALID

	return entities.get_id_by_index(
		best_entity_index
	)


func _get_team_id(
	owner_id: int,
	team_ids_by_owner: PackedInt32Array
) -> int:
	if (
		owner_id < 0
		or owner_id >= team_ids_by_owner.size()
	):
		return -1

	return team_ids_by_owner[
		owner_id
	]

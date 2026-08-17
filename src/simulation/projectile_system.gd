class_name ProjectileSystem
extends RefCounted


var positions := PackedVector3Array()
var velocities := PackedVector3Array()
var target_entity_ids := PackedInt64Array()
var damages := PackedFloat32Array()
var remaining_seconds := PackedFloat32Array()

var _impact_target_ids := PackedInt64Array()
var _impact_damages := PackedFloat32Array()


func spawn_projectile(
	start_position: Vector3,
	target_position: Vector3,
	target_entity_id: int,
	speed: float,
	damage: float,
	maximum_range: float
) -> int:
	if not EntityId.is_valid(target_entity_id):
		return -1

	if speed <= 0.0 or damage < 0.0 or maximum_range <= 0.0:
		return -1

	var offset: Vector3 = target_position - start_position
	var distance: float = offset.length()

	if distance <= 0.001:
		return -1

	var projectile_index: int = positions.size()
	var direction: Vector3 = offset / distance

	positions.append(start_position)
	velocities.append(direction * speed)
	target_entity_ids.append(target_entity_id)
	damages.append(damage)
	remaining_seconds.append(
		maximum_range / speed + 0.25
	)

	return projectile_index


func step(
	entities: EntityStore,
	delta_seconds: float
) -> void:
	_impact_target_ids = PackedInt64Array()
	_impact_damages = PackedFloat32Array()

	if delta_seconds <= 0.0:
		return

	for projectile_index: int in range(
		positions.size() - 1,
		-1,
		-1
	):
		var target_entity_id: int = (
			target_entity_ids[
				projectile_index
			]
		)

		var target_index: int = (
			entities.get_index_if_alive(
				target_entity_id
			)
		)

		if target_index < 0:
			_remove_projectile(
				projectile_index
			)
			continue

		var start_position: Vector3 = (
			positions[
				projectile_index
			]
		)

		var end_position: Vector3 = (
			start_position
			+ velocities[
				projectile_index
			]
			* delta_seconds
		)

		var target_position: Vector3 = (
			entities.positions[
				target_index
			]
		)

		var hit_radius: float = maxf(
			0.25,
			entities.collision_radii[
				target_index
			] + 0.20
		)

		if _segment_intersects_ground_circle(
			start_position,
			end_position,
			target_position,
			hit_radius
		):
			_impact_target_ids.append(
				target_entity_id
			)

			_impact_damages.append(
				damages[
					projectile_index
				]
			)

			_remove_projectile(
				projectile_index
			)
			continue

		positions[
			projectile_index
		] = end_position

		remaining_seconds[
			projectile_index
		] -= delta_seconds

		if remaining_seconds[
			projectile_index
		] <= 0.0:
			_remove_projectile(
				projectile_index
			)


func active_count() -> int:
	return positions.size()


func consume_impact_target_ids() -> PackedInt64Array:
	var impact_target_ids: PackedInt64Array = (
		_impact_target_ids
	)

	_impact_target_ids = PackedInt64Array()

	return impact_target_ids


func consume_impact_damages() -> PackedFloat32Array:
	var impact_damages: PackedFloat32Array = (
		_impact_damages
	)

	_impact_damages = PackedFloat32Array()

	return impact_damages


func clear() -> void:
	positions = PackedVector3Array()
	velocities = PackedVector3Array()
	target_entity_ids = PackedInt64Array()
	damages = PackedFloat32Array()
	remaining_seconds = PackedFloat32Array()
	_impact_target_ids = PackedInt64Array()
	_impact_damages = PackedFloat32Array()


func _remove_projectile(
	projectile_index: int
) -> void:
	var last_index: int = positions.size() - 1

	if (
		projectile_index < 0
		or projectile_index > last_index
	):
		return

	if projectile_index != last_index:
		positions[
			projectile_index
		] = positions[
			last_index
		]

		velocities[
			projectile_index
		] = velocities[
			last_index
		]

		target_entity_ids[
			projectile_index
		] = target_entity_ids[
			last_index
		]

		damages[
			projectile_index
		] = damages[
			last_index
		]

		remaining_seconds[
			projectile_index
		] = remaining_seconds[
			last_index
		]

	positions.resize(last_index)
	velocities.resize(last_index)
	target_entity_ids.resize(last_index)
	damages.resize(last_index)
	remaining_seconds.resize(last_index)


func _segment_intersects_ground_circle(
	start_position: Vector3,
	end_position: Vector3,
	circle_center: Vector3,
	radius: float
) -> bool:
	var segment_x: float = (
		end_position.x - start_position.x
	)
	var segment_z: float = (
		end_position.z - start_position.z
	)

	var segment_length_squared: float = (
		segment_x * segment_x
		+ segment_z * segment_z
	)

	if segment_length_squared <= 0.000001:
		var point_x: float = (
			start_position.x - circle_center.x
		)
		var point_z: float = (
			start_position.z - circle_center.z
		)

		return (
			point_x * point_x
			+ point_z * point_z
			<= radius * radius
		)

	var center_x: float = (
		circle_center.x - start_position.x
	)
	var center_z: float = (
		circle_center.z - start_position.z
	)

	var projection: float = clampf(
		(
			center_x * segment_x
			+ center_z * segment_z
		)
		/ segment_length_squared,
		0.0,
		1.0
	)

	var closest_x: float = (
		start_position.x
		+ segment_x * projection
	)
	var closest_z: float = (
		start_position.z
		+ segment_z * projection
	)

	var difference_x: float = (
		closest_x - circle_center.x
	)
	var difference_z: float = (
		closest_z - circle_center.z
	)

	return (
		difference_x * difference_x
		+ difference_z * difference_z
		<= radius * radius
	)

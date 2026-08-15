class_name CombatSystem
extends RefCounted


enum DamageResult {
	INVALID,
	NO_EFFECT,
	DAMAGED,
	DESTROYED,
}


enum FireResult {
	INVALID,
	RELOADING,
	OUT_OF_RANGE,
	UNSUPPORTED_DELIVERY,
	FIRED,
}


# Only entities that have actually fired need runtime
# reload state. Each entity stores one ready tick per
# weapon slot.
var _ready_ticks_by_entity: Dictionary = {}


func apply_damage(
	entities: EntityStore,
	entity_id: int,
	damage: float
) -> int:
	if not DawnfallLog.require_valid(
		damage >= 0.0,
		"Damage cannot be negative.",
		&"CombatSystem"
	):
		return DamageResult.INVALID

	var entity_index: int = (
		entities.get_index_if_alive(
			entity_id
		)
	)

	if entity_index < 0:
		return DamageResult.INVALID

	if is_zero_approx(
		damage
	):
		return DamageResult.NO_EFFECT

	var remaining_health: float = maxf(
		0.0,
		entities.current_health[
			entity_index
		] - damage
	)

	entities.current_health[
		entity_index
	] = remaining_health

	if remaining_health <= 0.0:
		return DamageResult.DESTROYED

	return DamageResult.DAMAGED


func try_fire(
	entities: EntityStore,
	attacker_entity_id: int,
	target_entity_id: int,
	weapon: WeaponDefinition,
	weapon_slot: int,
	current_tick: int,
	tick_seconds: float
) -> int:
	if weapon == null:
		return FireResult.INVALID

	if weapon_slot < 0:
		return FireResult.INVALID

	if tick_seconds <= 0.0:
		return FireResult.INVALID

	var attacker_index: int = (
		entities.get_index_if_alive(
			attacker_entity_id
		)
	)

	var target_index: int = (
		entities.get_index_if_alive(
			target_entity_id
		)
	)

	if (
		attacker_index < 0
		or target_index < 0
		or attacker_entity_id
		== target_entity_id
	):
		return FireResult.INVALID

	if (
		weapon.delivery_type
		!= WeaponDefinition.DeliveryType.HITSCAN
	):
		return FireResult.UNSUPPORTED_DELIVERY

	var ready_ticks := PackedInt64Array()

	if _ready_ticks_by_entity.has(
		attacker_entity_id
	):
		ready_ticks = (
			_ready_ticks_by_entity[
				attacker_entity_id
			]
		)

	if ready_ticks.size() <= weapon_slot:
		ready_ticks.resize(
			weapon_slot + 1
		)

	if (
		current_tick
		< ready_ticks[
			weapon_slot
		]
	):
		return FireResult.RELOADING

	var offset: Vector3 = (
		entities.positions[
			target_index
		]
		- entities.positions[
			attacker_index
		]
	)

	offset.y = 0.0

	var distance: float = (
		offset.length()
	)

	if (
		distance < weapon.minimum_range
		or distance > weapon.maximum_range
	):
		return FireResult.OUT_OF_RANGE

	var reload_ticks: int = maxi(
		1,
		ceili(
			weapon.reload_seconds
			/ tick_seconds
		)
	)

	ready_ticks[
		weapon_slot
	] = (
		current_tick
		+ reload_ticks
	)

	_ready_ticks_by_entity[
		attacker_entity_id
	] = ready_ticks

	return FireResult.FIRED


func forget_entity(
	entity_id: int
) -> void:
	_ready_ticks_by_entity.erase(
		entity_id
	)


func clear() -> void:
	_ready_ticks_by_entity.clear()

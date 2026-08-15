class_name CombatSystem
extends RefCounted


enum DamageResult {
	INVALID,
	NO_EFFECT,
	DAMAGED,
	DESTROYED,
}


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

	if is_zero_approx(damage):
		return DamageResult.NO_EFFECT

	var remaining_health: float = maxf(
		0.0,
		entities.current_health[entity_index]
		- damage
	)

	entities.current_health[
		entity_index
	] = remaining_health

	if remaining_health <= 0.0:
		return DamageResult.DESTROYED

	return DamageResult.DAMAGED

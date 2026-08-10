class_name EntityId
extends RefCounted


const INVALID: int = 0
const INDEX_MASK: int = 0xFFFFFFFF


static func create(index: int, generation: int) -> int:
	assert(index >= 0, "Entity index cannot be negative.")
	assert(generation > 0, "Entity generation must be positive.")

	return (generation << 32) | (index & INDEX_MASK)


static func get_index(entity_id: int) -> int:
	return entity_id & INDEX_MASK


static func get_generation(entity_id: int) -> int:
	return (entity_id >> 32) & INDEX_MASK


static func is_valid(entity_id: int) -> bool:
	return entity_id != INVALID

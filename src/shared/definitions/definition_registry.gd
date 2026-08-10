class_name DefinitionRegistry
extends RefCounted


var _definitions_by_id: Dictionary[StringName, GameDefinition] = {}
var _movement_by_id: Dictionary[StringName, MovementDefinition] = {}
var _armor_by_id: Dictionary[StringName, ArmorDefinition] = {}
var _weapons_by_id: Dictionary[StringName, WeaponDefinition] = {}
var _units_by_id: Dictionary[StringName, UnitDefinition] = {}


func register(definition: GameDefinition) -> bool:
	if not DawnfallLog.require_valid(
		definition != null,
		"Cannot register a null definition.",
		&"DefinitionRegistry"
	):
		return false

	if not definition.validate():
		return false

	if not DawnfallLog.require_valid(
		not _definitions_by_id.has(definition.definition_id),
		"Duplicate definition ID: %s" % definition.definition_id,
		&"DefinitionRegistry"
	):
		return false

	var is_supported_type: bool = (
		definition is MovementDefinition
		or definition is ArmorDefinition
		or definition is WeaponDefinition
		or definition is UnitDefinition
	)

	if not DawnfallLog.require_valid(
		is_supported_type,
		"Unsupported definition type for ID: %s" % definition.definition_id,
		&"DefinitionRegistry"
	):
		return false

	_definitions_by_id[definition.definition_id] = definition

	if definition is MovementDefinition:
		_movement_by_id[definition.definition_id] = definition
	elif definition is ArmorDefinition:
		_armor_by_id[definition.definition_id] = definition
	elif definition is WeaponDefinition:
		_weapons_by_id[definition.definition_id] = definition
	elif definition is UnitDefinition:
		_units_by_id[definition.definition_id] = definition

	return true


func validate_references() -> bool:
	var is_valid: bool = true

	for unit: UnitDefinition in _units_by_id.values():
		is_valid = _require_registered_reference(
			unit,
			unit.movement_profile,
			"movement profile"
		) and is_valid

		is_valid = _require_registered_reference(
			unit,
			unit.armor_profile,
			"armor profile"
		) and is_valid

		for weapon: WeaponDefinition in unit.weapons:
			is_valid = _require_registered_reference(
				unit,
				weapon,
				"weapon"
			) and is_valid

	return is_valid


func get_definition(definition_id: StringName) -> GameDefinition:
	return _definitions_by_id.get(definition_id) as GameDefinition


func get_unit(definition_id: StringName) -> UnitDefinition:
	return _units_by_id.get(definition_id) as UnitDefinition


func has_definition(definition_id: StringName) -> bool:
	return _definitions_by_id.has(definition_id)


func total_count() -> int:
	return _definitions_by_id.size()


func summary() -> String:
	return "%d total (%d movement, %d armor, %d weapons, %d units)" % [
		_definitions_by_id.size(),
		_movement_by_id.size(),
		_armor_by_id.size(),
		_weapons_by_id.size(),
		_units_by_id.size(),
	]


func _require_registered_reference(
	owner: UnitDefinition,
	reference: GameDefinition,
	reference_label: String
) -> bool:
	if reference == null:
		return false

	var registered: GameDefinition = get_definition(reference.definition_id)
	return DawnfallLog.require_valid(
		registered == reference,
		"Referenced %s '%s' is missing from the content catalog."
		% [reference_label, reference.definition_id],
		owner.get_validation_context()
	)

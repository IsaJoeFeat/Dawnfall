class_name UnitDefinitionRegistry
extends RefCounted


var _definitions_by_id: Dictionary[StringName, UnitDefinition] = {}


func register(definition: UnitDefinition) -> bool:
	if not DawnfallLog.require_valid(
		definition != null,
		"Cannot register a null unit definition.",
		&"UnitDefinitionRegistry"
	):
		return false

	if not definition.validate():
		return false

	if not DawnfallLog.require_valid(
		not _definitions_by_id.has(definition.definition_id),
		"Duplicate unit definition ID: %s" % definition.definition_id,
		&"UnitDefinitionRegistry"
	):
		return false

	_definitions_by_id[definition.definition_id] = definition
	return true


func get_definition(definition_id: StringName) -> UnitDefinition:
	return _definitions_by_id.get(definition_id) as UnitDefinition


func has_definition(definition_id: StringName) -> bool:
	return _definitions_by_id.has(definition_id)


func size() -> int:
	return _definitions_by_id.size()

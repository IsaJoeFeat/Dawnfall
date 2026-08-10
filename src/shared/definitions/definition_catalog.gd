class_name DefinitionCatalog
extends Resource


@export var definitions: Array[GameDefinition] = []


func load_into(registry: DefinitionRegistry) -> bool:
	if not DawnfallLog.require_valid(
		registry != null,
		"A registry is required to load the content catalog.",
		&"DefinitionCatalog"
	):
		return false

	for definition: GameDefinition in definitions:
		if not registry.register(definition):
			return false

	return registry.validate_references()

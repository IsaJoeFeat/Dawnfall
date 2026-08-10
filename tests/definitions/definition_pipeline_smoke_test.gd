extends SceneTree


const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)


func _init() -> void:
	var registry := DefinitionRegistry.new()

	if not CONTENT_CATALOG.load_into(registry):
		quit(1)
		return

	if not _verify_fixture_contract(registry):
		quit(1)
		return

	print("Definition Pipeline v1 smoke test passed: %s." % registry.summary())
	quit(0)


func _verify_fixture_contract(registry: DefinitionRegistry) -> bool:
	var is_valid: bool = true
	var tank: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_tank"
	)
	var headquarters: UnitDefinition = registry.get_unit(
		&"unit_test_placeholder_hq"
	)

	is_valid = DawnfallLog.require_valid(
		registry.total_count() == 12,
		"The fixture catalog must contain exactly 12 definitions.",
		&"DefinitionPipelineSmokeTest"
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		tank != null and tank.weapons.size() == 2,
		"The placeholder tank must compose a cannon and machine gun.",
		&"DefinitionPipelineSmokeTest"
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		registry.has_definition(&"weapon_test_tank_machine_gun"),
		"The shared tank machine gun must be registered.",
		&"DefinitionPipelineSmokeTest"
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		headquarters != null and not headquarters.is_buildable,
		"The placeholder Command HQ must be non-buildable.",
		&"DefinitionPipelineSmokeTest"
	) and is_valid

	return is_valid

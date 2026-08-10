extends Node


const EMPTY_BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/empty_battle.tscn"
)

const CONTENT_CATALOG: DefinitionCatalog = preload(
	"res://content/content_catalog.tres"
)

const SMOKE_TEST_ARGUMENT := "--smoke-test"
const EXIT_SUCCESS := 0
const EXIT_FAILURE := 1

var _definitions: DefinitionRegistry


func _ready() -> void:
	if not _initialize_definitions():
		get_tree().quit(EXIT_FAILURE)
		return

	if _is_smoke_test():
		print("Dawnfall headless smoke test passed")
		get_tree().quit(EXIT_SUCCESS)
		return

	var battle: Node = EMPTY_BATTLE_SCENE.instantiate()
	add_child(battle)
	DawnfallLog.info("Booted into the empty battle scene.", &"App")


func _initialize_definitions() -> bool:
	_definitions = DefinitionRegistry.new()

	if not CONTENT_CATALOG.load_into(_definitions):
		return false

	DawnfallLog.info(
		"Loaded %s." % _definitions.summary(),
		&"Definitions"
	)
	return true


func _is_smoke_test() -> bool:
	return SMOKE_TEST_ARGUMENT in OS.get_cmdline_user_args()

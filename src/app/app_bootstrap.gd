extends Node


const EMPTY_BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/empty_battle.tscn"
)

const PLACEHOLDER_TANK_DEFINITION: UnitDefinition = preload(
	"res://content/units/testing/placeholder_tank.tres"
)

const SMOKE_TEST_ARGUMENT := "--smoke-test"
const EXIT_SUCCESS := 0
const EXIT_FAILURE := 1

var _unit_definitions: UnitDefinitionRegistry


func _ready() -> void:
	if not _initialize_unit_definitions():
		get_tree().quit(EXIT_FAILURE)
		return

	if _is_smoke_test():
		print("Dawnfall headless smoke test passed")
		get_tree().quit(EXIT_SUCCESS)
		return

	var battle: Node = EMPTY_BATTLE_SCENE.instantiate()
	add_child(battle)
	print("Dawnfall booted into the empty battle scene")


func _initialize_unit_definitions() -> bool:
	_unit_definitions = UnitDefinitionRegistry.new()

	if not _unit_definitions.register(PLACEHOLDER_TANK_DEFINITION):
		return false

	print(
		"Loaded %d validated unit definition(s)"
		% _unit_definitions.size()
	)
	return true


func _is_smoke_test() -> bool:
	return SMOKE_TEST_ARGUMENT in OS.get_cmdline_user_args()

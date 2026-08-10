extends Node

const EMPTY_BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/empty_battle.tscn"
)
const SMOKE_TEST_ARGUMENT := "--smoke-test"
const EXIT_SUCCESS := 0


func _ready() -> void:
	if _is_smoke_test():
		print("Dawnfall headless smoke test passed")
		get_tree().quit(EXIT_SUCCESS)
		return

	var battle: Node = EMPTY_BATTLE_SCENE.instantiate()
	add_child(battle)
	print("Dawnfall booted into the empty battle scene")


func _is_smoke_test() -> bool:
	return SMOKE_TEST_ARGUMENT in OS.get_cmdline_user_args()

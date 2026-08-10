class_name GameDefinition
extends Resource


@export_group("Identity")

@export var definition_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""


func validate() -> bool:
	var is_valid: bool = true
	var context: StringName = get_validation_context()

	is_valid = DawnfallLog.require_valid(
		definition_id != &"",
		"Definition ID cannot be empty.",
		context
	) and is_valid

	is_valid = DawnfallLog.require_valid(
		not display_name.strip_edges().is_empty(),
		"Display name cannot be empty.",
		context
	) and is_valid

	return is_valid


func get_validation_context() -> StringName:
	if definition_id != &"":
		return definition_id

	return &"UnnamedDefinition"

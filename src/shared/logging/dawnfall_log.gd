class_name DawnfallLog
extends RefCounted


static func require_valid(
	condition: bool,
	message: String,
	context: StringName = &"General"
) -> bool:
	if condition:
		return true

	var full_message: String = "[%s] %s" % [context, message]
	push_error(full_message)
	assert(condition, full_message)
	return false

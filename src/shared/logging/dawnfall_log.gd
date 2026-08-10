class_name DawnfallLog
extends RefCounted


enum Level {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
}

static var minimum_level: int = Level.DEBUG


static func debug(message: String, context: StringName = &"General") -> void:
	if not OS.is_debug_build():
		return

	_write(Level.DEBUG, message, context)


static func info(message: String, context: StringName = &"General") -> void:
	_write(Level.INFO, message, context)


static func warning(message: String, context: StringName = &"General") -> void:
	_write(Level.WARNING, message, context)


static func error(message: String, context: StringName = &"General") -> void:
	_write(Level.ERROR, message, context)


static func require_valid(
	condition: bool,
	message: String,
	context: StringName = &"General"
) -> bool:
	if condition:
		return true

	error(message, context)
	assert(condition, _format_message(Level.ERROR, message, context))
	return false


static func _write(level: int, message: String, context: StringName) -> void:
	if level < minimum_level:
		return

	var formatted_message: String = _format_message(level, message, context)

	match level:
		Level.WARNING:
			push_warning(formatted_message)
		Level.ERROR:
			push_error(formatted_message)
		_:
			print(formatted_message)


static func _format_message(
	level: int,
	message: String,
	context: StringName
) -> String:
	var level_name: String = String(Level.keys()[level])
	return "[%s] [%s] %s" % [level_name, context, message]

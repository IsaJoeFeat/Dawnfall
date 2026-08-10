class_name FixedStepClock
extends RefCounted


const DEFAULT_TICKS_PER_SECOND: float = 20.0
const DEFAULT_MAX_STEPS_PER_FRAME: int = 8

var tick_seconds: float
var max_steps_per_frame: int
var tick_count: int = 0

var _accumulator: float = 0.0


func _init(
	requested_ticks_per_second: float = DEFAULT_TICKS_PER_SECOND,
	requested_max_steps: int = DEFAULT_MAX_STEPS_PER_FRAME
) -> void:
	assert(
		requested_ticks_per_second > 0.0,
		"Simulation tick rate must be positive."
	)
	assert(
		requested_max_steps > 0,
		"Maximum simulation steps must be positive."
	)

	tick_seconds = 1.0 / requested_ticks_per_second
	max_steps_per_frame = requested_max_steps


func consume_steps(frame_delta: float) -> int:
	if frame_delta <= 0.0:
		return 0

	var maximum_accumulation: float = (
		tick_seconds * float(max_steps_per_frame)
	)

	_accumulator += minf(frame_delta, maximum_accumulation)

	var available_steps: int = floori(_accumulator / tick_seconds)
	var steps_to_run: int = mini(
		available_steps,
		max_steps_per_frame
	)

	_accumulator -= float(steps_to_run) * tick_seconds
	tick_count += steps_to_run

	return steps_to_run


func interpolation_alpha() -> float:
	return clampf(_accumulator / tick_seconds, 0.0, 1.0)


func reset() -> void:
	_accumulator = 0.0
	tick_count = 0

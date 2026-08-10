# Entity Simulation Baseline

## Test information

- Date: 2026-08-10
- Godot version: 4.7.1
- Execution mode: Godot editor, debug, F6 test scene
- Test scene: `res://tests/simulation/entity_storage_test.tscn`
- Hardware: Initial Dawnfall development machine; exact specifications not yet recorded

## Scenario

- 8,000 logical entities
- Alternating placeholder infantry and tanks
- Four simulated owners
- 2,000 individually addressed entities given one batched move order
- 20 simulation ticks
- 20 ticks per second
- No rendering
- No navigation or shared paths
- No spatial grid
- No collision or separation
- No combat

## Results

| Measurement | Result |
| --- | ---: |
| Initial storage-only creation test | 15.14 ms |
| Expanded entity creation test | 21.72 ms |
| Twenty movement ticks | 89.49 ms |
| Average movement tick | 4.47 ms |
| Fixed simulation tick budget | 50.00 ms |
| Approximate tick budget consumed | 8.95% |

## Interpretation

The current GDScript implementation can create 8,000 compact logical entities and scan them during fixed-step movement simulation without approaching the 20 Hz simulation budget.

This is an encouraging foundation result, not proof that Gate A has passed. Rendering, selection, spatial queries, shared-path movement, formations, local separation, networking, and combat will add substantial costs.

The movement implementation is temporary direct-line movement. Its purpose is to test data layout, entity lifecycle, fixed simulation timing, and batched command dispatch.

## Limitations

- Timings were collected from one run.
- Hardware specifications have not yet been recorded.
- Debug/editor timings may differ from exported builds.
- Memory usage was not recorded.
- Frame time and draw calls were not measured.
- No profiler capture was recorded.
- Movement does not yet use terrain or navigation.

# Spatial Grid Scale Baseline

## Test information

- Date: 2026-08-10
- Godot version: 4.7.1
- Execution mode: Godot editor debug test
- Benchmark scene: `res://tests/benchmarks/simulation_scale_benchmark.tscn`
- Fixed simulation rate: 20 ticks per second
- Fixed tick budget: 50 milliseconds
- Hardware: Initial Dawnfall development machine; exact specifications not yet recorded

## Scenario

Each scenario contains compact logical entities arranged at consistent density.

- Up to 2,000 individually addressed entities receive a batched move command.
- Movement uses temporary direct-line movement.
- The spatial grid is rebuilt after every simulation tick.
- Each scenario runs 1,000 radius queries.
- Each scenario runs 20 movement and spatial-grid ticks.
- Commanded units share a destination, deliberately producing congestion.
- Rendering, navigation, separation, combat, and networking are disabled.

## Results

| Entities | Spawn | Initial grid | 1,000 queries | Command dispatch | Average tick | Tick budget used |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | 2.99 ms | 0.62 ms | 42.80 ms | 1.16 ms for 1,000 | 1.84 ms | 3.68% |
| 2,000 | 5.79 ms | 1.25 ms | 55.56 ms | 2.33 ms for 2,000 | 3.67 ms | 7.34% |
| 4,000 | 12.63 ms | 2.75 ms | 54.46 ms | 2.34 ms for 2,000 | 5.53 ms | 11.06% |
| 8,000 | 22.32 ms | 4.87 ms | 55.52 ms | 2.36 ms for 2,000 | 9.36 ms | 18.72% |

## Interpretation

Entity creation and spatial-grid rebuilding scale approximately with entity count.

The cost of 1,000 local-radius queries remains relatively stable as the total entity count grows. This is the desired result: query cost primarily follows local density and query radius instead of total battlefield population.

At 8,000 entities, movement plus a complete spatial-grid rebuild consumes approximately 9.36 milliseconds of the 50-millisecond simulation tick budget.

This leaves encouraging preliminary capacity for additional simulation systems. It does not prove that Gate A has passed because rendering, selection, shared navigation, formations, separation, memory measurements, and frame-time measurements remain unfinished.

## Benchmark runner note

Running all four scenarios sequentially in one editor process caused the final scenario to stop unpredictably despite the isolated 8,000-entity scenario completing successfully.

The benchmark was therefore changed to run one selected entity count per execution. This gives every measurement a clean simulation world and avoids accumulated editor/debug-process behavior.

Future command-line automation should launch a fresh Godot process for each scale.

## Current limitations

- Results are from single runs.
- Exact hardware specifications are not recorded.
- No exported-build comparison exists.
- No profiler capture exists.
- Memory and rendering costs are not measured.
- The grid is completely rebuilt each tick.
- Units do not use paths, formations, or separation.

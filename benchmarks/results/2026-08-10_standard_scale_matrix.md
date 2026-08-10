# Standard Scale Benchmark Matrix

## Test information

- Date: 2026-08-10
- Godot version: 4.7.1
- Execution mode: Godot editor debug test
- Test scene: `res://tests/rendering/multimesh_render_test.tscn`
- Sample timing: Approximately five seconds after launch
- Camera: Initial standardized overview, unchanged for every run
- Hardware: Initial Dawnfall development machine; exact specifications not yet recorded

## Scenario

Each run uses the same deterministic placeholder-unit scenario at a different scale:

- 1,000, 2,000, 4,000, or 8,000 logical and rendered units
- Equal placeholder infantry and tank distribution
- Four owner colors
- 25% of entities moving toward a shared destination
- Simulation running at 20 ticks per second
- Complete spatial-grid rebuild after each tick
- Deduplicated upload of only changed visual transforms
- Definition-and-spatial-chunk MultiMesh groups
- Far LOD throughout the standardized initial overview
- Primitive placeholder meshes
- Directional-light shadows disabled
- No selection indicators
- No combat, navigation, separation, or networking

## Results

| Total units | Moving / uploaded | Chunk groups | Near / far | FPS | Frame | Draw calls | Simulation tick | Transform upload | Video memory |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | 250 | 14 | 0 / 14 | 179 | 5.59 ms | 34 | 1.67 ms | 0.26 ms | 63.3 MB |
| 2,000 | 500 | 28 | 0 / 28 | 178 | 5.62 ms | 48 | 2.48 ms | 0.52 ms | 63.3 MB |
| 4,000 | 1,000 | 42 | 0 / 42 | 180 | 5.56 ms | 62 | 5.39 ms | 1.02 ms | 62.4 MB |
| 8,000 | 2,000 | 70 | 0 / 70 | 180 | 5.56 ms | 90 | 9.85 ms | 1.91 ms | 63.2 MB |

## Scaling summary

| Change from 1,000 to 8,000 units | Observed change |
| --- | ---: |
| Unit count | 8.0x |
| Moving transforms | 8.0x |
| Simulation tick | 5.9x |
| Transform upload | 7.3x |
| Draw calls | 2.6x |
| Reported video memory | -0.1 MB |
| Approximate frame time | -0.03 ms |

## Interpretation

The scale matrix passes this stage of the rendering and simulation feasibility test.

The standardized overview remains at 178–180 FPS at every tested scale. This comfortably exceeds Gate A's 60 FPS normal-view target and 30 FPS worst-case all-unit-view target for the current primitive scenario.

Simulation time grows from 1.67 milliseconds at 1,000 units to 9.85 milliseconds at 8,000 units. The 8,000-unit sample remains within the 50-millisecond budget of the current 20 Hz fixed simulation tick, with substantial room for systems that have not yet been implemented.

Dirty transform uploads scale closely with the number of moving entities: 0.26 milliseconds for 250 uploads and 1.91 milliseconds for 2,000. The upload path continues to avoid touching the static 75% of the army.

Draw calls increase with spatial chunk count, from 34 calls across 14 groups to 90 calls across 70 groups. That is an intentional tradeoff for chunk culling and LOD control and remains inexpensive in this test.

Reported video memory stays effectively flat around 63 MB. The small variation between runs is measurement noise at this resolution, not evidence that additional unit instances have no memory cost.

## Important measurement boundaries

- The near-LOD count is zero in every run because the unchanged overview camera places all groups beyond their LOD thresholds.
- The reported FPS appears capped or otherwise limited near 180, so these samples do not measure maximum uncapped throughput.
- The typical frame-time monitor does not isolate frames containing a fixed simulation tick.
- Draw calls include the entire rendered frame, not only unit groups.
- Video memory is total reported renderer memory, not unit-only memory.
- Results are single samples rather than averages, peaks, or percentiles.
- Editor/debug results may differ from exported builds.
- The benchmark uses simple boxes and flat markers rather than production models.
- Shadows are disabled.
- Selection, shared-path navigation, formation assignment, local separation, combat, and networking are not yet included.
- Render groups remain based on each entity's build-time chunk assignment; moving entities are not yet migrated between groups.

## Gate A impact

This matrix completes the standardized scale-measurement task and supports the feasibility of the existing logical simulation, spatial grid, chunked MultiMesh renderer, LOD, and partial-transform-upload architecture.

Gate A does not pass yet. Selection responsiveness, shared-path movement, formation assignment, local separation, and combined-system performance still require implementation and measurement.

## Next task

Add individual click selection and drag-box selection, then measure selection responsiveness at standard army sizes.

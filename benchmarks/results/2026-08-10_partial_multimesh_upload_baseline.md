# Partial MultiMesh Upload Baseline

## Test information

- Date: 2026-08-10
- Godot version: 4.7.1
- Execution mode: Godot editor debug test
- Test scene: `res://tests/rendering/multimesh_render_test.tscn`
- Sample timing: Approximately five seconds after launch while commanded units were moving
- Hardware: Initial Dawnfall development machine; exact specifications not yet recorded

## Scenario

- 8,000 logical simulation entities
- 8,000 visible mesh instances
- 4,000 placeholder infantry
- 4,000 placeholder tanks
- Four owner colors
- 70 definition-and-spatial-chunk MultiMesh groups
- 36 near-LOD groups and 34 far-LOD groups in the sampled view
- 2,000 entities moving toward a shared destination
- Simulation running at 20 ticks per second
- Complete spatial-grid rebuild after each tick
- Deduplicated upload of only changed visual transforms
- Primitive placeholder meshes
- Directional-light shadows disabled
- No selection indicators
- No combat, navigation, separation, or networking

## Results

| Measurement | Result |
| --- | ---: |
| Logical entities | 8,000 |
| Rendered instances | 8,000 |
| MultiMesh chunk groups | 70 |
| Near-LOD groups | 36 |
| Far-LOD groups | 34 |
| Frames per second | 179 FPS |
| Approximate typical frame time | 5.59 ms |
| Total reported draw calls | 74 |
| Last completed simulation tick | 10.03 ms |
| Partial transform upload | 1.96 ms |
| Simulation plus upload | 11.99 ms |
| Transforms uploaded per tick frame | 2,000 |
| LOD groups changed in sampled frame | 0 |
| Reported total video memory | 69.2 MB |

## Comparison with the complete-upload baseline

| Measurement | Complete upload | Partial upload | Change |
| --- | ---: | ---: | ---: |
| Transforms uploaded | 8,000 | 2,000 | -75.0% |
| Transform upload time | 5.03 ms | 1.96 ms | -61.0% |
| Simulation plus upload | 14.38 ms | 11.99 ms | -16.6% |

## Interpretation

The dirty-transform path behaves as intended. Only the 2,000 commanded units receive transform uploads while 6,000 static units require no per-tick renderer synchronization.

The partial upload reduces measured upload time by 3.07 milliseconds compared with the original complete-upload baseline. The remaining 1.96-millisecond cost includes dirty-set consumption, direct entity-to-instance lookup, and 2,000 `MultiMesh` transform writes.

The 179 FPS sample remains encouraging, but the typical frame-time value does not isolate simulation-tick frames. The sampled simulation tick plus partial upload costs 11.99 milliseconds before accounting for all remaining frame work.

The draw-call totals are not a direct before-and-after comparison. The complete-upload baseline used two battlefield-wide MultiMeshes, while this test uses 70 spatial groups with near and far LOD meshes. Draw-call behavior should be compared at matched camera views during the standard-scale benchmark matrix.

## Important measurement boundaries

- Draw calls include the entire rendered frame, not only unit groups.
- Video memory is total reported renderer memory, not unit-only memory.
- The benchmark uses simple boxes and flat markers rather than production models.
- Shadows are disabled.
- Results are from one sampled run.
- Peak and percentile frame times are not recorded.
- Editor/debug results may differ from exported builds.
- Render groups remain based on each entity's build-time chunk assignment; moving entities are not yet migrated between groups.
- Spawn and renderer-build timings were not captured for this sampled run.

## Next measurement

Run matched 1,000-, 2,000-, 4,000-, and 8,000-unit scenarios and record frame time, simulation time, upload time, memory, draw calls, render groups, and visible LOD distribution.

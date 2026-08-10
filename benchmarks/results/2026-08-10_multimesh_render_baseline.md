# MultiMesh Rendering Baseline

## Test information

- Date: 2026-08-10
- Godot version: 4.7.1
- Execution mode: Godot editor debug test
- Test scene: `res://tests/rendering/multimesh_render_test.tscn`
- Sample timing: Approximately five seconds after launch
- Hardware: Initial Dawnfall development machine; exact specifications not yet recorded

## Scenario

- 8,000 logical simulation entities
- 8,000 visible mesh instances
- 4,000 placeholder infantry
- 4,000 placeholder tanks
- Four owner colors
- Two MultiMesh unit groups
- 2,000 entities moving toward a shared destination
- Simulation running at 20 ticks per second
- Complete spatial-grid rebuild after each tick
- Complete upload of all 8,000 visual transforms after each tick
- Primitive placeholder meshes
- Directional-light shadows disabled
- No selection indicators
- No spatial render chunks
- No LOD buckets
- No combat, navigation, separation, or networking

## Results

| Measurement | Result |
| --- | ---: |
| Logical entities | 8,000 |
| Rendered instances | 8,000 |
| Unit MultiMesh groups | 2 |
| Frames per second | 180 FPS |
| Approximate typical frame time | 5.56 ms |
| Total reported draw calls | 18 |
| Last completed simulation tick | 9.35 ms |
| Complete transform upload | 5.03 ms |
| Simulation plus upload | 14.38 ms |
| Transforms uploaded per tick | 8,000 |
| Reported total video memory | 69.4 MB |

## Interpretation

Rendering 8,000 primitive unit visuals through two MultiMesh groups is feasible on the initial development machine.

The unit renderer avoids one node and draw submission per unit. Total reported draw calls remain low even with all entities visible.

The displayed frame rate is encouraging, but the typical frame-time value does not fully represent simulation-tick frames. A simulation tick plus a complete transform upload costs approximately 14.38 milliseconds before accounting for all remaining frame work.

The next rendering optimization should avoid uploading transforms for static entities. During this test only 2,000 entities were moving, but all 8,000 transforms were uploaded after every completed simulation tick.

## Important measurement boundaries

- Draw calls include the entire rendered frame, not only unit groups.
- Video memory is total reported renderer memory, not unit-only memory.
- The benchmark uses simple boxes rather than production models.
- Shadows are disabled.
- No LOD or spatial render culling is implemented.
- Results are from one sampled run.
- Peak and percentile frame times are not recorded.
- Editor/debug results may differ from exported builds.

## Camera note

The temporary RTS camera successfully supports panning, zooming, and rotation, but it does not yet reproduce Beyond All Reason's camera behavior.

BAR-style camera feel remains part of the dedicated RTS camera work in M3.

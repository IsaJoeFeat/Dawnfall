# Rendering Foundation

Dawnfall rendering is a presentation of simulation state. It is not the authoritative owner of unit positions, health, ownership, or behavior.

## No visual node per unit

Logical entities remain compact data inside `EntityStore`.

Ordinary units do not receive:

- A `Node3D`
- A movement script
- A physics body
- A unique material
- A unique draw submission

`UnitMultiMeshRenderer` groups entities that share a mesh into MultiMesh buffers.

## Render prototypes

A render prototype currently maps a numeric unit-definition index to:

- A near mesh
- A far mesh
- A vertical offset
- An LOD distance

This test-only prototype mapping will eventually be supplied by validated visual-definition data.

Adding a unit should not require editing the renderer.

## Render groups

Entities are divided by unit definition and 32-meter spatial chunk. Each
definition-and-chunk pair owns one `MultiMeshInstance3D` and one `MultiMesh`.

Instance colors communicate the owning player without creating separate materials or render groups for each owner.

## Synchronization

The simulation advances at 20 ticks per second.

`MovementSystem` reports entity indices whose positions or headings changed.
`SimulationWorld` deduplicates those indices across every simulation tick
completed during one rendered frame. Rendering consumes the changed set and
updates only the corresponding MultiMesh instances.

The renderer maintains a direct lookup from each entity index to its render
group and instance index. Static entities therefore require no transform
upload after the initial renderer build.

## Culling and LOD

A MultiMesh group is treated as one render object for visibility. Individual instances are not independently frustum-culled.

Spatial chunks give Godot smaller visibility bounds, and each chunk switches
between its prototype's near and far mesh according to camera distance.

## Current limitations

- Render prototypes are created by test code.
- No interpolation exists between simulation states.
- Moving entities remain assigned to their original render chunks even after
  crossing a chunk boundary.
- Death and dynamic spawning do not rebuild render groups.
- Selection visuals are not implemented.
- Production models and animation are not implemented.
- Shadows are disabled.
- The camera is a temporary functional controller, not the final BAR-style camera.

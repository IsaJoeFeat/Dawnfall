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

- A mesh
- A vertical offset

This test-only prototype mapping will eventually be supplied by validated visual-definition data.

Adding a unit should not require editing the renderer.

## Render groups

The initial test contains two groups:

- Placeholder infantry
- Placeholder tanks

Each group owns one `MultiMeshInstance3D` and one `MultiMesh`.

Instance colors communicate the owning player without creating separate materials or render groups for each owner.

## Synchronization

The simulation advances at 20 ticks per second.

After a completed simulation tick, the renderer copies simulation positions and headings into MultiMesh instance transforms.

The initial implementation uploads all 8,000 transforms. This establishes a simple correctness baseline.

Future synchronization should track changed transforms and upload only units whose visual state changed.

## Culling and LOD

A MultiMesh group is treated as one render object for visibility. Individual instances are not independently frustum-culled.

Future rendering work should divide units into spatial chunks and basic LOD buckets. This will allow distant or off-screen regions to use cheaper rendering without creating one node per unit.

## Current limitations

- Render prototypes are created by test code.
- All transforms are uploaded after each simulation tick.
- No interpolation exists between simulation states.
- No spatial render chunks exist.
- No LOD buckets exist.
- Death and dynamic spawning do not rebuild render groups.
- Selection visuals are not implemented.
- Production models and animation are not implemented.
- Shadows are disabled.
- The camera is a temporary functional controller, not the final BAR-style camera.

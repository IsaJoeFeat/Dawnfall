# Simulation Foundation

Dawnfall represents active gameplay units as compact logical entities rather than creating a large Godot scene-tree branch for every unit.

## Entity identity

An entity ID is a 64-bit integer containing:

- A storage index
- A generation number

The index locates the entity's data. The generation changes whenever a storage slot is reused.

This prevents an old command or selection from accidentally controlling a new entity that reused the same storage position.

## Entity storage

`EntityStore` uses parallel packed arrays.

For example, entity index 42 uses index 42 in:

- `positions`
- `headings`
- `current_health`
- `maximum_health`
- `owner_ids`
- `definition_indices`
- Movement state arrays
- Runtime flags

This structure avoids thousands of script instances and allows simulation systems to process similar data in batches.

Runtime entities reference definition data instead of copying complete unit definitions into every entity.

## Fixed-step simulation

`FixedStepClock` advances gameplay at 20 ticks per second.

A fixed simulation step provides:

- Reproducible timing
- Consistent movement and combat calculations
- A foundation for multiplayer synchronization
- Simulation behavior independent of rendering frame rate

Rendering will eventually interpolate between simulation states.

## Simulation systems

`SimulationWorld` owns the entity store, clock, and simulation systems.

Each system processes relevant entities in batches. The current `MovementSystem` scans the store and advances entities that have active movement targets.

Future systems will include:

- Spatial indexing
- Navigation and shared paths
- Local separation
- Combat
- Vision and detection
- Production
- Economy
- Status effects

Units should not receive unique controller scripts for ordinary behavior.

## Commands

Commands refer to entities through generation-safe entity IDs.

A single command can contain many entity IDs. This allows thousands of individually selectable units without requiring one Godot signal, RPC, or object call per unit.

The current move command assigns one destination to many entities. Formation positions, path sharing, command queues, and ownership validation will be added later.

## Current limitations

The current movement system:

- Moves directly toward a destination
- Ignores terrain and obstacles
- Does not maintain formations
- Does not perform collision avoidance
- Does not use a spatial grid
- Does not render entities

It exists to validate the simulation architecture before more expensive systems are added.

## Spatial indexing

`SpatialGrid` divides the horizontal battlefield into fixed-size cells.

Each occupied cell stores the indices of entities currently inside it. Radius queries inspect only cells overlapping the requested area and then perform an exact distance check on their candidates.

This prevents nearby-unit queries from scanning every entity in the match.

The initial implementation rebuilds the complete grid after every simulation tick. This favors correctness and simple lifecycle behavior while the architecture is young.

The 8,000-entity baseline measured a complete grid rebuild at approximately 4.87 milliseconds. Incremental updates should only replace full rebuilding if later profiler evidence demonstrates a need.

Spatial queries currently return internal entity indices for immediate simulation use. Player commands and persistent references continue to use generation-safe entity IDs.

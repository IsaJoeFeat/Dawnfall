# Definition Pipeline v1

Definition Pipeline v1 is the first usable slice of Dawnfall's content engine.
It proves that editable Godot resources can be composed, validated, registered,
and loaded without giving every unit its own controller script.

## Current source definition types

```text
GameDefinition
├── MovementDefinition
├── ArmorDefinition
├── WeaponDefinition
└── UnitDefinition
```

Every definition inherits a stable `definition_id`, player-facing
`display_name`, description, and common validation.

A unit composes reusable resources:

```text
UnitDefinition
├── classification and target categories
├── health, collision/selection radii, and vision
├── MovementDefinition
├── ArmorDefinition
├── zero or more WeaponDefinitions
└── Steel, Supply, and production values
```

The placeholder tank demonstrates two independent weapons: a projectile cannon
and a reusable hitscan machine gun. This supports Dawnfall's rule that every
tank can carry an MG without duplicating the MG's shared statistics.

## Runtime loading

`content/content_catalog.tres` is the source manifest. At application startup:

1. `DefinitionCatalog` submits each referenced resource to
   `DefinitionRegistry`.
2. Each definition validates its own fields.
3. The registry rejects null entries and globally duplicated IDs.
4. The registry verifies that every movement, armor, and weapon reference used
   by a unit is also present in the catalog.
5. Only a valid catalog allows the battle scene to start.

Global IDs use a type prefix for readability, for example:

```text
movement_tracked_medium
armor_medium_vehicle
weapon_test_tank_cannon
unit_test_placeholder_tank
```

## Current authoring workflow

For Definition Pipeline v1, creating a unit involves:

1. Create or reuse movement, armor, and weapon `.tres` resources.
2. Create a `UnitDefinition` resource.
3. Assign its component resources through the Inspector.
4. Add the finished unit and any new components to
   `content/content_catalog.tres`.
5. Run Dawnfall and confirm the definition summary contains the expected count.

Never duplicate a shared profile merely to rename it. Create a new profile only
when its gameplay values or behavior are meaningfully different.

## Deliberate limitations

This version does not yet define:

- penetration and ricochet formulas;
- turret mounts, firing arcs, or muzzle transforms;
- accuracy, suppression, ammunition, or experience;
- factories, prerequisites, build menus, or upgrade rules;
- visual, audio, projectile, or effect recipes;
- automatic catalog generation;
- compiled numeric runtime IDs.

Those systems should extend the composition model after their gameplay
requirements are tested. They should not turn `UnitDefinition` into a single
file containing every field in the game.

## Testing contract

A valid catalog must pass the headless smoke test and log a typed summary. An
invalid ID, duplicate ID, invalid numeric value, null component, or unregistered
reference must stop a development build with a contextual assertion. Release
builds receive `false` and can reject the catalog safely.

The fixture contract also has a focused headless test:

```bash
godot --headless --path . --script \
  res://tests/definitions/definition_pipeline_smoke_test.gd
```

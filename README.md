# Dawnfall

Dawnfall is an open-source, large-scale World War II RTS being built in Godot.
It is inspired by the clarity, scale, and combined-arms battles of games such as
Beyond All Reason, while using original code and assets.

## Current goal

Prove that one 2v2 battle can support up to 2,000 individually selectable units
per player before expanding the faction rosters. The living roadmap is in
[`PROJECT_PLAN.md`](PROJECT_PLAN.md).

## Requirements

- Godot 4.7.1 Standard Edition (GDScript, not the .NET build)
- A desktop GPU capable of running Godot's Forward+ renderer
- Git or GitHub Desktop

## Open the project

1. Clone this repository.
2. Open Godot's Project Manager.
3. Select **Import**, choose this repository's `project.godot`, then select
   **Import & Edit**.
4. Press **F6** to run the current scene, or **F5** to run the project.

The first screen is intentionally a labeled gray-box battlefield. It confirms
that the project, boot flow, renderer, and starter scene load correctly.

## Headless smoke test

From the repository root:

```bash
godot --headless --path . -- --smoke-test
```

A successful run prints `Dawnfall headless smoke test passed` and exits with
status code `0`.

## Development rules

- Gameplay state will be data-oriented; normal units will not get a unique
  controller script.
- Rendering is kept separate from the simulation.
- New units will primarily be definitions assembled from reusable systems.
- Performance and multiplayer feasibility are measured before large-scale
  content production.

See [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) before adding code.

## Definition Pipeline v1

Dawnfall's first data-driven content path is operational. A runtime catalog
loads and validates reusable movement, armor, weapon, and unit resources before
the battle scene starts. The current testing catalog contains placeholder
infantry, tank, and Command HQ definitions.

See [`docs/CONTENT_PIPELINE.md`](docs/CONTENT_PIPELINE.md) for the resource
relationships, current limitations, and the safe unit-authoring workflow.

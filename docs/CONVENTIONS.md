# Dawnfall Code Conventions

These conventions keep the project approachable while leaving room for the
performance work required by an 8,000-unit battle.

## Godot and GDScript

- Use Godot 4.7.1 Standard Edition and the Forward+ renderer.
- Use typed GDScript for production code: type parameters, return values,
  properties, and important local variables.
- Use tabs for GDScript indentation, matching Godot's formatter.
- Use `snake_case` for files, functions, variables, and signals.
- Use `PascalCase` for named classes and `SCREAMING_SNAKE_CASE` for constants.
- Treat warnings as problems to understand, not noise to hide.

## Project structure

- `scenes/` contains editable Godot scenes.
- `src/app/` owns startup and application flow.
- `src/simulation/` will own authoritative, graphics-free match state.
- `src/rendering/` will turn simulation state into visible units.
- `src/client/` will own local input and presentation state.
- `src/shared/` is reserved for small cross-layer types and utilities.
- `content/` will contain data definitions for units, weapons, buildings,
  factions, and maps.
- `tests/` and `benchmarks/` must remain runnable without opening editor tools.

## Architecture boundaries

- A normal unit is data in the simulation, not a unique scene tree or script.
- Simulation systems update batches of unit data.
- Visual nodes never decide damage, resources, ownership, or production.
- UI reads the same validated definitions used by the simulation.
- Unique behavior should become a reusable capability before being copied.

## Change discipline

- Keep commits focused and give them an outcome-oriented message.
- Update `PROJECT_PLAN.md` when a task or milestone changes state.
- Record a meaningful architectural choice in `docs/decisions/`.
- Do not mark a feature complete until it has been run in Godot.

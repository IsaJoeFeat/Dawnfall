# ADR 0002: Compose Source Definitions

- **Status:** Accepted
- **Date:** 2026-08-10

## Decision

Dawnfall source content will compose small reusable Godot resources rather than
store all possible gameplay fields in a monolithic unit file. The initial
resource types are movement, armor, weapon, and unit definitions.

Source definitions use readable global string IDs. A later compiler may map
those IDs and references to compact numeric runtime data without changing the
authoring model.

Runtime startup loads an explicit content catalog. Automatic catalog generation
is deferred until the editor tooling milestone; the catalog remains export-safe
and makes every distributed resource dependency explicit.

## Why

Dawnfall needs a tank cannon, machine gun, tracked movement profile, or armor
profile to be reusable across many units. Fixing or balancing a shared concept
should not require editing every unit that uses it.

Keeping source resources separate also prevents editor-friendly authoring data
from dictating the data-oriented representation used by thousands of live
simulation entities.

## Consequences

- A standard unit is primarily assembled through Inspector resource references.
- Shared changes intentionally affect every unit using that definition.
- The registry rejects duplicate IDs and references missing from the catalog.
- Mount-specific weapon data and compiled runtime IDs require later extensions.
- The content catalog is edited manually until tooling can generate it safely.

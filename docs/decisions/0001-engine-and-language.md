# ADR 0001: Godot and GDScript First

- **Status:** Accepted
- **Date:** 2026-08-10

## Decision

Dawnfall will use Godot 4.7.1 Standard Edition with GDScript as its initial
implementation language. C#, GDExtension, or engine modifications may be added
only when a repeatable profile demonstrates that GDScript cannot meet a named
performance budget.

The PC build begins on the Forward+ renderer. Gate A will benchmark rendering
at target scale; a renderer change must be based on those measurements.

## Why

Godot provides fast scene editing and testing while keeping the complete game
project open source. GDScript offers the shortest feedback loop for the team.
The data-oriented architecture keeps hot simulation work isolated so an
optimized implementation can replace a bottleneck without rewriting content.

## Consequences

- Normal game systems should be written clearly in typed GDScript first.
- Performance tests are architectural deliverables, not late polish.
- Engine-specific scene nodes stay outside authoritative simulation state.
- The exact supported Godot patch version is recorded in the README.

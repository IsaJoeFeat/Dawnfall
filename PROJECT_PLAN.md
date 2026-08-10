# Dawnfall Project Plan

> Living roadmap for Dawnfall. Update this file whenever scope, architecture, milestone status, or the immediate next task changes.

## Current status

- **Project stage:** Scale feasibility laboratory
- **Current milestone:** M1 — Scale laboratory
- **Current gate:** Gate A — Scale feasibility
- **Next task:** Add individual click selection and drag-box selection
- **Target engine:** Godot 4.7.1 stable
- **Primary language:** GDScript initially; introduce C# or C++ only after profiling proves a need
- **Primary platform:** PC, keyboard and mouse
- **Repository:** `IsaJoeFeat/Dawnfall`

### Completed decisions

- [x] Dawnfall is a WWII combined-arms RTS.
- [x] Dawnfall will be open source.
- [x] Godot is the engine.
- [x] The initial multiplayer target is 2v2.
- [x] The unit cap target is 2,000 individually selectable units per player.
- [x] A full 2v2 match must therefore be designed around as many as 8,000 logical units.
- [x] Units remain individually selectable; infantry are not collapsed into squad-level agents.
- [x] The economy uses Steel and Supply.
- [x] Mines produce Steel.
- [x] Supply represents fuel, ammunition, electricity, labor, and logistics.
- [x] A player's fixed Command HQ is the elimination condition.
- [x] Factories upgrade in place to unlock T2 and T3 units.
- [x] There are three engineer tiers; higher tiers retain earlier build options.

## Vision

Dawnfall is a large-scale WWII RTS where clear unit roles combine into complex frontline warfare and no single military branch can win alone.

### Design principles

1. **Simplification can create complexity.** Prefer a small number of readable rules that interact deeply.
2. **Complexity over complication.** A decision may be difficult; understanding the interface should not be.
3. **Combined arms is mandatory.** Infantry, armor, artillery, aircraft, defenses, and naval forces cover one another's weaknesses.
4. **Position and information matter.** Terrain, vision, radar, capture points, firing ranges, mines, and formation choices shape battles.
5. **Production is understandable.** Upgrade existing factories, preserve old build options, and communicate unlock requirements clearly.
6. **Single-player is first-class.** Tutorials, missions, and campaigns use the same simulation as multiplayer.
7. **Scale must remain readable.** Thousands of units cannot turn controls, UI, or battlefield information into noise.

## Product boundaries

### In scope

- Large-scale 3D RTS battles
- Individually selectable land, air, and naval units
- Allies and Axis factions
- Three technology tiers
- Steel and Supply economy
- Construction, production queues, reclaim/salvage, and factory upgrades
- Fog of war, vision, radar, sonar, and range overlays
- Capture points and territory pressure
- Multiplayer 2v2
- Skirmish AI
- Mission and campaign framework
- Unit-by-unit interactive tutorials
- Data-driven content tools

### Not in the first playable release

- Every historical vehicle or national subfaction
- Full campaign
- Naval warfare
- T3 technology
- Advanced aircraft modes
- Mod marketplace or Steam Workshop integration
- Mobile or controller-first controls
- Photorealistic visuals
- A general-purpose engine for unrelated genres

## Architecture rules

These rules are constraints, not suggestions.

1. **The simulation is data-oriented.** An active unit is primarily compact state in arrays or packed data, not an elaborate scene tree.
2. **No script per unit.** Systems update groups of units in batches.
3. **No physics body per moving unit.** Dawnfall owns strategic movement, separation, and collision behavior.
4. **Rendering is separate from simulation.** Visual units represent simulation state and may change detail without changing gameplay.
5. **Use high-level Godot nodes where they help.** Cameras, menus, map tools, boot flow, and developer utilities should remain easy to edit.
6. **Use low-level APIs only where measured.** MultiMesh and RenderingServer are expected for units; C# or GDExtension requires profiling evidence.
7. **The server owns competitive state.** Clients submit commands and render results; clients do not decide damage, ownership, resources, or production.
8. **Definitions are immutable during a match.** Runtime state references validated definitions by stable numeric IDs.
9. **One source of truth feeds simulation and UI.** Costs, ranges, roles, counters, prerequisites, and tooltips come from the same definition data.
10. **Every hot system has a benchmark.** Performance claims require recorded measurements.

## Proposed repository layout

```text
Dawnfall/
├── project.godot
├── README.md
├── PROJECT_PLAN.md
├── LICENSE
├── assets/
│   ├── audio/
│   ├── models/
│   ├── textures/
│   └── ui/
├── content/
│   ├── factions/
│   ├── units/
│   ├── weapons/
│   ├── buildings/
│   └── maps/
├── scenes/
│   ├── boot/
│   ├── battle/
│   ├── menus/
│   └── tools/
├── src/
│   ├── app/
│   ├── client/
│   ├── shared/
│   ├── simulation/
│   ├── rendering/
│   ├── networking/
│   ├── ui/
│   └── tools/
├── tests/
├── benchmarks/
└── docs/
	├── architecture/
	├── decisions/
	└── design/
```

The layout may change during M0. Any major structural change should receive a short Architecture Decision Record in `docs/decisions/`.

## Definition pipeline

Normal units should be created by composing reusable data rather than writing unique gameplay scripts.

```text
Unit source data
  + chassis
  + locomotion class
  + armor profile
  + one or more weapons
  + targeting rules
  + visual recipe
  + unit-specific overrides
		↓
Definition compiler and validator
		↓
Stable runtime definitions
  ├── simulation data
  ├── build menus
  ├── tooltips
  ├── AI roles
  ├── range overlays
  └── benchmark/test fixtures
```

A unique mechanic may attach a reusable behavior component. It should not become a copy-pasted unit controller.

## Stage gates

### Gate A — Scale feasibility

We prove that the engine architecture can represent, select, move, render, and query thousands of individual units before producing faction content.

**Pass conditions:**

- 8,000 logical units exist in one battle simulation.
- A player can own and select 2,000 individual units.
- Box selection and command dispatch remain responsive.
- Shared-path movement works without one path request per unit.
- Spatial queries avoid all-versus-all comparisons.
- Normal views target 60 FPS on the agreed development PC.
- A worst-case all-unit view remains playable near 30 FPS.
- Simulation steps remain within their measured time budget.
- Results are recorded under `benchmarks/`.

If Gate A fails, optimize from profiler evidence. Reconsider scope or engine only after documenting the bottleneck and attempted fixes.

### Gate B — Multiplayer authority

We prove a 2v2-capable networking model before building most game systems.

**Pass conditions:**

- Four local clients can join a dedicated/headless server test.
- Commands are validated and owned by the issuing player.
- Late, duplicated, malformed, and unauthorized commands fail safely.
- Unit movement and combat remain acceptably synchronized under simulated latency and packet loss.
- Reconnect and match recovery behavior are explicitly decided.
- Bandwidth and server simulation costs are recorded.

### Gate C — Combined-arms vertical slice

We prove Dawnfall is fun and understandable with a deliberately small roster.

**Pass conditions:**

- Two gray-box factions can complete a match.
- Each faction has an HQ, engineer, economy, barracks, vehicle factory, and a small combined-arms roster.
- Infantry, armor, anti-armor, artillery, AA, and one aircraft interaction all function.
- No single unit type is an efficient answer to every threat.
- Factory upgrading unlocks new units in place.
- UI explains role, targets, counters, cost, range, and unavailable requirements.
- At least one human 2v2 playtest finishes without developer intervention.

### Gate D — Content production

We prove new content is inexpensive enough to build the intended game.

**Pass conditions:**

- A standard unit can be added primarily through definition data and asset hooks.
- Invalid content produces actionable validation errors.
- Build menus and tooltips update automatically.
- A unit creation guide has been followed successfully without editing core systems.
- Balance values can be exported, compared, and reviewed.

## Milestones

### M0 — Project foundation

- [x] Pin the Godot version and renderer.
- [x] Create `project.godot` and a minimal boot scene.
- [x] Establish naming, formatting, typing, and folder conventions.
- [x] Add a central app bootstrap with explicit initialization order.
- [x] Add command-line/headless launch modes.
- [x] Add logging levels and developer assertions.
- [ ] Choose the code and content licenses.
- [ ] Add contribution and asset-license rules.
- [x] Add the first Architecture Decision Records.
- [ ] Confirm clean import, launch, and export on the development machine.

**Done when:** a fresh clone opens in the pinned Godot version, launches a labeled empty battle scene, runs headlessly, and exports a Windows development build.

### M1 — Scale laboratory

- [x] Create compact entity IDs and lifecycle management.
- [x] Store positions, rotations, ownership, type, health, and flags in data-oriented containers.
- [x] Implement a fixed-step simulation clock.
- [x] Create a simple spatial grid.
- [x] Render units with MultiMesh groups and basic LOD buckets.
- [ ] Add click and drag-box selection.
- [x] Add batched command dispatch.
- [ ] Add placeholder shared-path/flow-field movement.
- [x] Build automated stress scenarios for 1,000, 2,000, 4,000, and 8,000 units.
- [x] Record CPU, frame time, memory, and draw-call results. *(The matched 1,000/2,000/4,000/8,000 matrix and prior 8,000-unit baselines are recorded.)*

**Done when:** Gate A passes or a written decision changes the target based on measured evidence.

### M2 — Multiplayer laboratory

- [ ] Choose and document the synchronization model after comparing command lockstep and authoritative snapshots.
- [ ] Create headless server and client launch profiles.
- [ ] Implement connection, identity, team, and ownership state.
- [ ] Serialize compact command and state data.
- [ ] Add server validation and rate limits.
- [ ] Add latency, jitter, loss, and disconnect test controls.
- [ ] Run automated four-client sessions.

**Done when:** Gate B passes.

### M3 — RTS controls and movement

- [ ] Top-down camera with edge pan, drag pan, zoom, rotate, and tactical overview.
- [ ] Click, box, additive, subtractive, and type-filtered selection.
- [ ] Control groups and selection cycling.
- [ ] Move, attack-move, patrol, guard, stop, and queued orders.
- [ ] Command visualization and order feedback.
- [ ] Terrain movement classes for infantry, tracked, wheeled, amphibious, naval, and air.
- [ ] Shared paths, formation assignment, local separation, congestion recovery, and stuck detection.
- [ ] Reproducible movement tests.

**Done when:** thousands of individually selectable units can receive understandable orders and traverse representative terrain reliably.

### M4 — Combat, vision, and information

- [ ] Target categories and targeting priorities.
- [ ] Turret arcs, aim time, reload, accuracy, and range.
- [ ] Multiple weapons per unit, including tank cannon and machine gun.
- [ ] Projectile, hitscan, splash, penetration, and suppression foundations.
- [ ] Damage, death, wreck, salvage, and experience hooks.
- [ ] Fog of war, line of sight, radar, and sonar foundations.
- [ ] Weapon, radar, and defensive range overlays.
- [ ] Data-driven combat test scenarios.

**Done when:** combat results are deterministic enough to reproduce, readable to a player, and affordable at target scale.

### M5 — Economy, construction, and production

- [ ] Steel and Supply ledgers, income, storage, spending, and stall behavior.
- [ ] Mines, Supply producers, storage, salvage, and capture-point income.
- [ ] Command HQ ownership and elimination.
- [ ] Engineer construction, assistance, repair, and reclaim.
- [ ] Placement preview, footprints, build grids, obstruction checks, and build queues.
- [ ] Barracks, vehicle factory, runway, and shipyard production foundations.
- [ ] Factory rally points and repeat queues.
- [ ] In-place T2/T3 factory upgrades and grayed unlocks.
- [ ] Three engineer tiers with inherited construction options.

**Done when:** a player can expand, produce an army, recover from resource stalls, and eliminate an opponent's HQ.

### M6 — Combined-arms vertical slice

- [ ] Define the minimum Allied gray-box roster.
- [ ] Define the minimum Axis gray-box roster.
- [ ] Add infantry, anti-armor, armor, artillery, AA, fighter, and ground-attack roles.
- [ ] Implement enough aircraft behavior to test air versus ground and AA.
- [ ] Add capture points and a first playable map.
- [ ] Add match start, victory, defeat, and post-match flow.
- [ ] Build the first complete generated build menu and information panel.
- [ ] Conduct balance and usability playtests.

**Done when:** Gate C passes.

### M7 — Content engine and developer tools

**Foundation now available:** editable movement, armor, weapon, and unit
resources; composition; an explicit content catalog; global ID validation; and
reference validation. The compiler, automatic catalog generation, stable
numeric runtime IDs, broader schemas, and authoring tools remain M7 work.

- [ ] Definition compiler, schema, inheritance/composition rules, and stable IDs.
- [ ] Unit, weapon, building, movement, armor, effect, and faction validators.
- [ ] Content browser and unit preview scene.
- [ ] Automated stat cards, tooltips, build menus, and range data.
- [ ] Balance export and comparison tools.
- [ ] Batch stress-test generation from definitions.
- [ ] Unit creation documentation.

**Done when:** Gate D passes.

### M8 — Advanced land and air warfare

- [ ] Prone and crouch states.
- [ ] Cover, suppression, morale, and recovery decisions.
- [ ] Mines, detection, clearing, and route denial.
- [ ] Carpet and strategic bombing modes.
- [ ] Fighter AA and anti-ground role clarity.
- [ ] Transport aircraft and paradrop foundations.
- [ ] Better long-range artillery and counter-battery information.
- [ ] HQ protection and anti-snipe counterplay.

### M9 — Naval warfare

- [ ] Water navigation and naval formations.
- [ ] Shipyard shoreline placement.
- [ ] Submarine depth, sonar, torpedo, and detection systems.
- [ ] Naval transport and amphibious landing systems.
- [ ] Aircraft carrier production and seaplane restriction.
- [ ] Naval construction and repair.

### M10 — AI, tutorials, and campaign

- [ ] Shared command API for humans, AI, and mission scripts.
- [ ] Skirmish AI economy, scouting, production, tactics, and adaptation.
- [ ] Mission trigger/objective framework.
- [ ] Save/checkpoint strategy.
- [ ] Unit-by-unit interactive tutorial framework.
- [ ] Campaign progression and mission selection.
- [ ] Difficulty modifiers that change behavior before merely changing stats.

### M11 — Alpha readiness

- [ ] Complete first public faction rosters and tech trees.
- [ ] Performance pass across minimum and recommended PCs.
- [ ] Networking soak tests and dedicated-server deployment.
- [ ] Settings, controls rebinding, accessibility, and localization foundations.
- [ ] Crash reporting, logs, replay/debug capture, and support workflow.
- [ ] Installer/build pipeline and release signing.
- [ ] Credits, licenses, third-party notices, and asset provenance audit.
- [ ] Public issue templates and contributor documentation.

## UI information contract

Every selectable unit must communicate, without requiring a wiki:

- Name and battlefield role
- Current orders and stance
- Health and relevant status effects
- Steel and Supply cost
- Build time and factory/tech requirement
- Valid and invalid target categories
- Primary strengths and counters
- Weapon ranges and minimum ranges
- Vision, radar, or sonar range
- Movement class and terrain limitations
- Why an unavailable action is unavailable

## Testing strategy

1. **Pure simulation tests:** Run without graphics or an active scene where possible.
2. **Replayable scenarios:** Fixed seeds and command logs reproduce movement and combat bugs.
3. **Performance scenarios:** Standardized counts and maps produce comparable benchmark files.
4. **Multiplayer soak tests:** Headless server plus automated clients run long sessions.
5. **Visual tests:** Small scenes isolate selection, overlays, effects, UI, and model setup.
6. **Human playtests:** Every stage gate includes observation of real player behavior.

No milestone is complete solely because its code exists. It must meet its stated exit condition in an actual Godot run.

## Open-source and inspiration policy

- Dawnfall may study the design and architecture of BAR, Zero-K, and other RTS games.
- Do not copy BAR models, textures, sounds, animations, or other restricted assets.
- Do not copy GPL game code into Dawnfall unless the project deliberately adopts compatible licensing and records the decision.
- Prefer original implementations derived from documented behavior and our own requirements.
- Record the source and license of every third-party asset.
- Decide the Dawnfall code license before accepting outside contributions.

## Primary risks

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| 8,000-unit scale fails | Core vision becomes infeasible | Gate A comes before content; profile standardized stress tests |
| Pathfinding dominates CPU | Large armies stall the simulation | Shared fields/paths, movement classes, spatial partitioning, staggered updates |
| Networking becomes too expensive | 2v2 cannot ship | Gate B early; compact commands/state; compare synchronization models |
| Content scope explodes | Project never reaches a complete match | Gray-box functional rosters before historical breadth |
| HQ sniping feels arbitrary | Long matches end without counterplay | Strong warnings, information, AA, durability, and protection rules |
| UI becomes BAR-level opaque | Players cannot learn the game | Enforce the UI information contract from definition data |
| Open-source asset mistakes | Legal or distribution problems | Provenance records and automated license audit checklist |
| Premature optimization | Complex architecture without benefit | Optimize only against Gate A/B measurements |
| Familiarity gap with Godot | Development momentum collapses | Beginner-friendly steps, explicit paths, small verified systems, documented terminology |

## Working agreement

- Build one complete, testable system at a time.
- Explain architecture and tradeoffs before major implementation.
- Keep the user involved in design choices that affect identity or gameplay.
- Provide exact file paths, editor actions, and test steps.
- Prefer understandable code over clever abstractions.
- Do not silently expand scope.
- Do not claim something works until it has been run and tested in Godot.
- The user applies all code and project changes and performs all Godot editor and in-engine testing; the assistant publishes only project-plan and documentation updates unless explicitly asked otherwise.
- Update **Current status** and milestone checkboxes after every meaningful change.
- Keep one explicit **Next task** at all times.

## Immediate next sequence

1. Add individual click selection and drag-box selection.
2. Measure selection responsiveness at standard army sizes.
3. Add shared destination paths and formation slot assignment.
4. Add local separation using the spatial grid.
5. Reassign moving render instances when they cross spatial render chunks.
6. Measure combined-system performance at every standard scale.
7. Complete the remaining M0 licensing, contribution, and Windows export tasks.

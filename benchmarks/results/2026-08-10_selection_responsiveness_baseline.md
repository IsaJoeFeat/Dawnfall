# Selection responsiveness baseline — 2026-08-10

## Result

Click selection and drag-box selection passed in the 8,000-unit scale benchmark.

- Player-owned units selected: 2,000 of 2,000
- Full-army selection query: 3.107 ms
- Total logical/rendered units: 8,000
- Moving units: 2,000 (25%)
- Simulation tick: 10.20 ms
- Dirty-transform upload: 1.90 ms for 2,000 instances
- FPS: 179.0
- Approximate frame time: 5.59 ms
- Draw calls: 92
- Render groups: 70 (0 near, 70 far)
- Reported video memory: 66.7 MB

## Test coverage

The in-engine test confirmed that:

- individual click selection works;
- clicking empty ground clears selection;
- drag-box selection works;
- ownership filtering limits selection to the blue player units;
- selected units receive the yellow highlight;
- a full-army drag selects exactly 2,000 player-owned units.

## Conclusion

The selection portion of Gate A passes at the target per-player army size. A 3.107 ms worst-case full-army drag query is responsive in this isolated benchmark. Selection must be remeasured after shared-path movement, formation assignment, and local separation are combined.

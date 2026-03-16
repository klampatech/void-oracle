# PRD: Milestone 4 — Ghost Board Encounter

## Introduction

Milestone 4 implements the haunted persistence mechanic: your past runs return as challenge encounters. The player's failed board layouts manifest as ghost boards with distinct behaviors based on their composition.

**Goal:** Your past haunts you. Mechanically.

---

## Goals

- [ ] Create Ghost Board Encounter scene that loads saved board layouts
- [ ] Implement ghost behavior based on dominant peg state
- [ ] Implement Ghost Board Assignment system for run placement

---

## User Stories

### VO-017: Ghost Board Encounter Scene
**Description:** As a player, I want to face my past failures as enemies so my choices matter beyond a single run.

**Acceptance Criteria:**
- [ ] Load `GhostBoardManager.active_ghost` board layout
- [ ] Render ghost board as semi-transparent enemy "display" panel
- [ ] Ghost behavior based on board composition:
  - Mostly Blessed → heals enemy each drop
  - Mostly Cursed → damages your board (acts as Corruptor)
  - High Mutation → fires chaos balls that randomize your peg states
- [ ] A ghost encounter spawns, exhibits correct behavior based on saved state

---

### VO-018: Ghost Board Assignment
**Description:** As a player, I want ghost encounters to appear at consistent positions so runs are deterministic by seed.

**Acceptance Criteria:**
- [ ] At run start: `GhostBoardManager.assign_ghost_for_run(run_seed)`
- [ ] Seeded random pick from saved ghosts
- [ ] Place ghost encounter at deterministic position in Zone 2 map
- [ ] Ghost encounter appears in same map position if run is restarted with same seed

---

## Functional Requirements

### FR-1: Ghost Board Encounter
- FR-1.1: GhostBoardEncounter scene loads ghost JSON from GhostBoardManager
- FR-1.2: Reconstructs board layout from JSON: pegs, positions, states, synergies
- FR-1.3: Renders as semi-transparent panel (modulate.a = 0.5)
- FR-1.4: Ghost behavior determined by analyzing saved board state:
  - Count Blessed, Cursed, Mutant, Void pegs
  - Determine dominant state (>50% = primary behavior)
  - Tie-breaker: Cursed > Mutant > Void > Blessed
- FR-1.5: Behavior implementations:
  | Dominant State | Behavior |
  |----------------|----------|
  | >50% Blessed | Heal companion enemy 10 HP per player drop |
  | >50% Cursed | Corrupt 1 player peg per turn (Corruptor AI) |
  | >30% Mutant | Fire chaos balls: randomize 1 peg state on hit |
  | >30% Void | Steal 1 ball from player's drop count |
  | Degraded/Shattered | Ghost is weakened (50% HP of normal) |

### FR-2: Ghost Board Assignment
- FR-2.1: GhostBoardManager.assign_ghost_for_run(seed) called at run start
- FR-2.2: Uses seeded RNG to pick from available ghosts
- FR-2.3: If no ghosts saved, assign no ghost (null)
- FR-2.4: Stores active ghost reference in RunState
- FR-2.5: Ghost appears in Zone 2 at fixed map node (deterministic by seed)

### FR-3: Ghost JSON Schema
- FR-3.1: Ghost saved as JSON with exact schema:
```json
{
  "version": "1.0",
  "timestamp": 1735689600,
  "run_seed": 847293,
  "oracle_class": "none",
  "zone_reached": 2,
  "pegs": [
    {
      "id": "peg_001",
      "type": "fungal",
      "position": {"x": 300, "y": 450},
      "state": "mutant",
      "hit_count": 12,
      "mutation_level": 2,
      "tags": ["growth", "death"]
    }
  ],
  "active_synergies": ["necrotic_bloom"],
  "relics": ["rot_crown"],
  "stability_at_death": 12.5,
  "total_drops": 47
}
```

---

## Non-Goals

- No Ghost vs Ghost combat (player fights ghost + companion enemy)
- No ghost recruitment (ghosts are always hostile)
- No ghost dialogue or narrative

---

## Technical Considerations

### EventBus Integration
No new signals — uses existing infrastructure:
- GhostBoardManager loads ghost data
- EnemyAI uses ghost behavior (different from Corruptor)

### Data Dependencies
- Ghost JSON files in `user://void_oracle/ghost_boards/`

### GhostBoardManager Expansion
New methods:
- `assign_ghost_for_run(seed: int) -> Dictionary?` — picks ghost, stores in RunState
- `get_active_ghost() -> Dictionary?` — returns current run's ghost
- `get_saved_ghosts() -> Array[Dictionary]` — lists all saved ghosts

---

## Open Questions

- What if player has 10+ ghosts? The spec says keep last 10 — is this a hard limit or soft?
- Does ghost persist between runs in the same session? Yes, saved to disk
- Ghost + companion enemy — do they share HP or have separate health bars?

---

## Related Tickets

- **Depends on:** Milestone 3 (death save, basic enemy system)
- **Blocks:** Milestone 5 (map integration for ghost placement)

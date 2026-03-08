# PRD: Milestone 3 — Single Encounter

## Introduction

Milestone 3 creates the first complete game loop: players drop balls, pockets score, enemies act, and the run progresses or ends. This transforms the physics sandbox into an actual game.

**Goal:** Fight one enemy. Win or die. Loop feels complete.

---

## Goals

- [ ] Implement Drop Phase / Result Phase / Board Phase loop
- [ ] Create Corruptor enemy with HP, intent display, turn actions
- [ ] Add Stability System UI (stability bar, depletion, game over)
- [ ] Implement Ghost Board save on death

---

## User Stories

### VO-013: Drop Phase / Result Phase Loop
**Description:** As a player, I need to launch balls and see results so the game has structure.

**Acceptance Criteria:**
- [ ] Drop Phase: launch N balls, wait for all balls to settle or leave board
- [ ] Result Phase: tally pocket results (damage, healing, gold, void essence)
- [ ] Apply results to `RunState` and enemy HP
- [ ] Board Phase: show draft UI (stub for now — just "End Turn" button)
- [ ] Full drop → result → next drop loop runs without errors

---

### VO-014: Corruptor Enemy (First Enemy)
**Description:** As a player, I need an enemy to fight so there's a win condition.

**Acceptance Criteria:**
- [ ] Enemy panel UI: HP bar, name, intent display
- [ ] On each player turn end: pick 1 random Blessed peg → shift to Cursed
- [ ] If no Blessed pegs: pick random Dormant peg
- [ ] HP: 80. Takes damage from Damage pockets
- [ ] On death: emit `EventBus.enemy_defeated`, trigger draft phase
- [ ] Full combat loop: drop → deal damage → enemy corrupts a peg → repeat until enemy dies

---

### VO-015: Stability System UI
**Description:** As a player, I need to see my board's health so I know when I'm in danger.

**Acceptance Criteria:**
- [ ] HUD stability bar (ColorRect, fills left to right, gold → red as depletes)
- [ ] Tick down 10 stability on each enemy action
- [ ] Run ends at 0 stability → show death screen stub
- [ ] Taking damage from enemy visibly depletes bar; 0 triggers game over

---

### VO-016: Ghost Board: Save on Death
**Description:** As a player, I want my failed board saved so it can haunt future runs.

**Acceptance Criteria:**
- [ ] On `EventBus.run_ended`: call `RunState.snapshot_board()` → `GhostBoardManager.save_ghost()`
- [ ] Death screen shows board state summary (zone reached, pegs, synergies)
- [ ] Save persists: restart game, load ghost_001.json successfully
- [ ] Die, restart, confirm ghost JSON exists in user:// directory

---

## Functional Requirements

### FR-1: Phase System
- FR-1.1: GameManager tracks current phase: DROP | RESULT | BOARD
- FR-1.2: DROP Phase: spawn balls per RunState.ball_count, enable BallSpawner
- FR-1.3: Wait for all balls to exit board (Area2D at bottom) or settle (velocity < threshold)
- FR-1.4: RESULT Phase: calculate pocket results:
  | Pocket | Effect |
  |--------|--------|
  | Damage | enemy.hp -= damage_value |
  | Heal | player.stability += heal_value |
  | Gold | RunState.gold += gold_value |
  | Void | RunState.void_essence += void_value |
  | Chaos | trigger_chaos_effect() |
- FR-1.5: BOARD Phase: show draft UI stub, "End Turn" button advances to next DROP
- FR-1.6: Enemy acts between DROP phases (after all balls resolve)

### FR-2: Corruptor Enemy
- FR-2.1: Enemy inherits from Enemy base class
- FR-2.2: HP: 80, displayed as HP bar
- FR-2.3: Intent display shows current action (e.g., "Will corrupt a peg")
- FR-2.4: On turn start: select target peg, apply action
- FR-2.5: On death: emit `EventBus.enemy_defeated`, trigger rewards
- FR-2.6: Enemy reads from `data/enemies/corruptor.json`

### FR-3: Stability System
- FR-3.1: RunState.stability starts at 100
- FR-3.2: Enemy actions reduce stability (Corruptor: -10 per turn)
- FR-3.3: Stability bar in HUD: gold (100) → red (0)
- FR-3.4: On stability <= 0: emit `EventBus.run_ended`, show death screen
- FR-3.5: Stability can be healed via Heal pockets and certain synergies

### FR-4: Ghost Board Save
- FR-4.1: RunState.snapshot_board() captures:
  - All peg positions, types, states, hit_counts
  - Active synergies
  - Stability at death
  - Total drops taken
  - Zone reached
- FR-4.2: GhostBoardManager.save_ghost() serializes to JSON
- FR-4.3: Save location: `user://void_oracle/ghost_boards/ghost_001.json`
- FR-4.4: Keep last 10 ghosts, rotate oldest on new save
- FR-4.5: Death screen shows ghost summary before transitioning to main menu

---

## Non-Goals

- No map generation (single encounter only)
- No draft system (stub UI only)
- No shop
- No additional enemy types beyond Corruptor
- No zone progression

---

## Technical Considerations

### EventBus Integration
New signals for this milestone:
- `EventBus.drop_started.emit(ball_count)` — BallSpawner emits when balls launch
- `EventBus.drop_ended.emit()` — GameManager emits when all balls resolve
- `EventBus.enemy_acted.emit(enemy, action)` — Enemy emits after taking action
- `EventBus.enemy_defeated.emit(enemy)` — Enemy emits on death
- `EventBus.run_ended.emit(final_state)` — GameManager emits on stability <= 0

### Data Dependencies
- `data/enemies/corruptor.json` — enemy HP, actions, intent display text

### RunState Expansion
RunState now tracks:
- `stability: float` (starts 100)
- `gold: int` (starts 0)
- `void_essence: int` (starts 0)
- `ball_count: int` (starts 1)
- `total_drops: int` (starts 0)
- `current_enemy: Node` (reference to active enemy)
- `pegs: Array` (all peg instances on board)

---

## Open Questions

- Damage values per pocket — should these be in the pocket definition or uniform?
- How does the player select how many balls to drop? For M3, fixed at 1 ball
- Draft stub UI — what exactly shows? Just "End Turn" button is spec, but what does it do?

---

## Related Tickets

- **Depends on:** Milestone 1 (physics), Milestone 2 (mutation/synergies)
- **Blocks:** Milestone 4 (Ghost Board encounter uses this infrastructure)

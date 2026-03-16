# Void Oracle — PRD Generation Prompt
# ──────────────────────────────────────────────────────────────────────────────
# HOW TO USE THIS FILE
# ──────────────────────────────────────────────────────────────────────────────
# Hand this file to Claude (claude.ai or Claude Code) with the following message:
#
#   "Using the context in this file, generate a detailed PRD for: [TICKET ID]"
#
# Example: "Using the context in this file, generate a detailed PRD for: VO-007"
#
# Claude will produce a full Product Requirements Document including:
#   - Exact GDScript implementation
#   - Godot node structure
#   - Edge cases and failure modes
#   - Test criteria
#   - Integration points with other systems
# ──────────────────────────────────────────────────────────────────────────────

## Project Context

Void Oracle is a physics-driven roguelike pachinko game built in Godot 4.3+ with GDScript.

**Core concept**: The pachinko board is the player character. No avatar. The board mutates,
grows, and degrades across a run of encounters resolved through real ball physics.

**Engine**: Godot 4.3+, GDScript, GL Compatibility renderer (WebGL2 target)
**Physics**: 120 ticks/sec, Jolt-backed, CCD enabled on all balls
**Platform**: Web (itch.io) first, then Steam + Mobile from same codebase

---

## Architecture (Always Respected in PRDs)

### Signal Flow (NEVER bypass this)
All systems communicate via EventBus (AutoLoad singleton).
Direct method calls between systems are forbidden.

```
Physics event → BasePeg._on_body_entered()
             → EventBus.peg_hit.emit(peg, ball)
             → [MutationEngine, SynergyChecker, AudioManager, EnemyAI all subscribed]
```

### AutoLoad Singletons
- `EventBus` — signal definitions only, zero game logic
- `RunState` — current run data (stability, gold, pegs array, synergies)
- `GhostBoardManager` — file I/O for ghost board persistence
- `SynergyChecker` — tag counting, synergy activation/deactivation
- `AudioManager` — per-peg tone playback
- `MutationEngine` — peg state transitions (blessed/cursed axis)

### Data Sources
All game values come from JSON, never hardcoded:
- `data/pegs/peg_definitions.json` — peg stats (restitution, friction, tags, bonuses)
- `data/synergies/synergy_definitions.json` — synergy definitions
- `data/enemies/` — enemy HP, intent, action tables
- `data/events/` — branching event scripts

---

## Peg System Reference

### Peg States (Blessed/Cursed Axis)
| State | corruption_level | Behavior |
|---|---|---|
| Blessed | 0.0 | Gold veins, +1 chain bonus on hit |
| Dormant | 0.5 | Neutral |
| Cursed | 1.0 | Crimson cracks, ball gains Rot charge |
| Mutant | 0.5 + mutation_pulse | Wild deflection, triggers chain reaction |
| Void-Touched | Special | Ball phases through, teleports to random pocket |
| Shattered | Special | No collision, no bonus, reduces nearby peg bonuses |

### Peg Types & Physics
| Type | Restitution | Friction | Tags | Special |
|---|---|---|---|---|
| stone | 0.6 | 0.1 | foundation | None |
| bone | 0.5 | 0.05 | death | None |
| fungal | 0.4 | 0.45 | growth, death | Spawns adjacent Sprout pegs every 3 drops |
| ember | 0.9 | 0.05 | fire | Ignites adjacent pegs on hit |
| eye | 0.6 | 0.1 | void | Reveals pocket contents |
| heart | 0.7 | 0.15 | blood | +5 Stability on hit |
| oracle | 0.6 | 0.1 | all | Splits ball into 3 |
| void_rift | 0.0 | 0.0 | void | Teleports ball to best pocket |

### Mutation Rules
- Threshold: 5 hits before mutation eligible
- Chance: 15% per hit after threshold
- Dormant → Blessed (low corruption pressure) or Cursed (high corruption pressure)
- Blessed → Mutant (30% chance), else stays Blessed
- Cursed → Mutant (40% chance), else stays Cursed
- Mutant → Void (10% chance), else stays Mutant

---

## Synergy Reference

| ID | Tags Required | Min Pegs | Tier 1 (3 pegs) | Tier 2 (6 pegs) | Curse Risk |
|---|---|---|---|---|---|
| necrotic_bloom | death + growth | 3 | Rot pegs deal 3 dmg on contact | All pegs regen 1 Stability/drop | Rot spreads 2× faster |
| cursed_flame | fire + cursed | 3 | Burning pegs corrupt adjacent on ignite | Ball speed +20%, double damage | Board takes 5 dmg/drop |
| void_choir | void | 3 | Every 5th ball becomes Void Ball | Void Balls open extra pocket slot | Void consumes 1 Blessed peg/run |
| bleeding_arch | blood + foundation | 3 | Stone pegs heal 1 Stability on contact | Board gains Regen 2 passive | Heart pegs slowly rot |
| profane_eye | void + death | 3 | Eye pegs reveal enemy next move | Bone pegs double dmg vs revealed | Eye pegs blind randomly |

---

## Enemy Reference

| Enemy | HP | Action per Turn | Board Interaction |
|---|---|---|---|
| Corruptor | 80 | Shifts 1 Blessed → Cursed | Direct peg state modification |
| Wrecker | 100 | Shatters 1 peg (removes it) | Permanent peg removal |
| Spawner | 90 | Drops 1 enemy ball | Enemy ball damages Stability on pocket entry |
| Leech | 70 | Steals 5 Gold | No board modification |
| Mycologist | 120 | Accelerates Rot spread | Converts 1 Growth peg to Rot |

### Boss: The Gardener (Zone 1)
- HP: 150
- Phase 1 (100–75 HP): Converts 1 Blessed → Dormant per turn. Prunes "too much growth."
- Phase 2 (74–0 HP): Places 2 Thorn pegs (enemy-owned, immovable, deflect balls sideways at ±30°)
- Weakness: Void-Touched pegs are invisible to her. She cannot prune what she cannot perceive.

### Boss: The Architect of Ruin (Zone 2)
- HP: 200
- Phase 1 (200–120 HP): Cracks board frame every 2 turns (reduces effective board width by 20px per crack)
- Phase 2 (119–60 HP): Cracks become live Void Channels (balls falling through grant ×2 Void Essence)
- Phase 3 (59–0 HP): Cracks become hazard zones (balls touching cracks gain Cursed state)

### Boss: The Final Oracle (Zone 3)
- HP: 300
- Mirrors player's synergy tags back as resistances
- Phase 1 (300–200 HP): Copies player's most active synergy
- Phase 2 (199–100 HP): Adds a second copied synergy
- Phase 3 (99–0 HP): Reveals it is a Ghost Board of the player's best run; all resistances active

---

## Ghost Board System

Ghost Board JSON schema (must match exactly when generating save/load code):
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

Ghost behavior in encounter (determined by dominant peg state at time of death):
- >50% Blessed pegs → heals enemy 10 HP per player drop
- >50% Cursed pegs → damages player board (Corruptor behavior)
- >30% Mutant pegs → fires chaos balls that randomize 1 peg state per hit
- >30% Void pegs → steals 1 ball from player's drop count per encounter
- Shattered / degraded board → ghost is weakened (half HP of normal encounter)

---

## Chaos Drop Table (15% chance after any drop)

| Type | Probability | Effect |
|---|---|---|
| Blessing Rain | 20% | Ball trail blesses every peg it touches |
| Corruption Wave | 20% | Ball trail curses every peg it touches |
| Spore Cloud | 20% | Ball explodes on landing, 3 adjacent empty slots → Fungal Pegs |
| Void Marble | 20% | Ball skips all pegs, goes directly to random pocket (×2 value) |
| Echo Ball | 20% | Replays exact previous drop path with inverted gravity |

---

## PRD Template

When generating a PRD for a ticket, use this structure:

```
# PRD: [TICKET ID] — [Ticket Name]

## Overview
[2–3 sentence description of what this ticket builds and why it matters]

## Acceptance Criteria
[ ] Criterion 1
[ ] Criterion 2
...

## Godot Node Structure
[Scene tree diagram for new scenes]

## GDScript Implementation
[Complete, runnable GDScript files]

## EventBus Integration
[Which signals this system emits and subscribes to]

## Data Dependencies
[Which JSON files this reads from]

## Edge Cases & Failure Modes
[What can go wrong and how to handle it]

## Test Procedure
[Step-by-step manual test to verify acceptance criteria]

## Related Tickets
[Other tickets that block this or are blocked by this]
```

---

## Example PRD Request

User message: "Using the context in this file, generate a detailed PRD for: VO-008"

Expected output: A complete PRD for the Mutation Engine Integration ticket, including:
- Full `MutationEngine.gd` implementation with all edge cases handled
- How it connects to EventBus signals
- How corruption_level on peg shaders gets updated
- What happens if a peg is destroyed mid-mutation
- Test procedure (what to do in the editor to verify it works)

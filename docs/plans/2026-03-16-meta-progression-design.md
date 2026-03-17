# Meta-Progression System Design

**Date:** 2026-03-16
**Status:** Approved for Implementation

## Overview

Implement meta-progression system with Oracle Class selection and Void Shard tracking to give players persistent progression across runs.

## Oracle Classes

Each class provides a distinct starting condition:

| Class | Starting Bonus |
|-------|----------------|
| **The Naturalist** | 4 Fungal pegs, Growth synergy bias |
| **The Doomsayer** | 2 Bone, 1 Cursed peg, Death/Void bias |
| **The Architect** | +10 Stability (110 max), Foundation/Fire bias |
| **The Void-Walker** | 1 Void Rift, Void/Eye bias |

### Implementation

1. **Class Selection UI** (`MainMenu.tscn`)
   - Add 4 class buttons below "Start Run"
   - Each button shows class name + icon placeholder + brief description
   - Hover shows full bonus details

2. **RunManager Changes**
   - `start_new_run(seed, class_id)` - accept optional class_id parameter
   - Pass class_id to `RunState.new_run(seed, class_id)`

3. **RunState Changes**
   - `new_run(seed, class_id)` - apply class bonuses based on class_id
   - Apply starting pegs, stability, gold based on class

4. **Class Bonus Application**
   ```gdscript
   match class_id:
       "naturalist":
           stability = 100  # default
           _add_starting_pegs(["fungal", "fungal", "fungal", "fungal"])
       "doomsayer":
           stability = 90  # slightly weaker
           _add_starting_pegs(["bone", "bone", "cursed"])
       "architect":
           stability = 110  # stronger
           max_stability = 110
           _add_starting_pegs(["stone", "ember"])
       "void_walker":
           stability = 80  # weaker but powerful
           void_essence = 5
           _add_starting_pegs(["void_rift", "eye"])
   ```

## Void Shards

Track and persist Void Shards earned from defeating bosses.

### Data Model

```gdscript
# In RunState or new MetaState singleton
var void_shards: int = 0
var total_void_shards: int = 0  # lifetime shards
var unlocked_pegs: Array[String] = []  # pegs unlocked via shards
var unlocked_relics: Array[String] = []
```

### Boss Rewards

| Boss | Void Shards |
|------|-------------|
| The Gardener (Zone 1) | 5 |
| Architect of Ruin (Zone 2) | 10 |
| Final Oracle (Zone 3) | 25 |

### Implementation

1. **MetaState Singleton** - New AutoLoad for persistent data
   - Load from `user://meta_save.json` on startup
   - Save on any change

2. **Void Shard Tracking**
   - Add to RunState: `void_shards` (current run), `total_void_shards` (lifetime)
   - On boss defeat in RunManager._on_enemy_defeated(): increment shards

3. **Persistence**
   - Save void_shards to `user://void_oracle/meta_save.json`
   - Load on game startup

## Save System

### File: `user://void_oracle/meta_save.json`

```json
{
  "version": "1.0",
  "total_void_shards": 35,
  "unlocked_pegs": ["void_rift"],
  "unlocked_relics": [],
  "runs_completed": 3,
  "highest_zone_reached": 3
}
```

### Load Order

1. Game starts → Load MetaState from `meta_save.json`
2. MainMenu shows class selection + void shard display
3. On run start → Load/initialize RunState with class bonuses

## UI Components

### MainMenu Updates

1. **Void Shard Display** (top-right)
   - "Void Shards: XX" label
   - Icon placeholder

2. **Class Selection** (center)
   - 4 class cards in a 2x2 grid
   - Each card: class name, icon, 1-line description
   - Selected card highlighted with border

### Class Card Design

```
┌─────────────────────┐
│   [Icon Placeholder] │
│    CLASS NAME        │
│  Short description  │
│  Starting: X pegs    │
└─────────────────────┘
```

## Acceptance Criteria

- [ ] MainMenu shows 4 class options
- [ ] Clicking a class starts run with correct bonuses
- [ ] Each class has distinct starting board configuration
- [ ] Void shards increment on boss defeat
- [ ] Void shards persist between game sessions
- [ ] Game runs without errors after implementation

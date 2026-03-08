---
name: void-oracle-best-practices
description: Code quality and best practices for Void Oracle GDScript development
version: 1.0.0
priority: 85
compatible_with: [godot]
---

# Void Oracle Best Practices

## Core Rules (Never Break)

### 1. EventBus for ALL Cross-System Communication
- NEVER call methods directly: `enemy.damage_peg()` → BAD
- ALWAYS emit signals: `EventBus.peg_hit.emit(self, ball)` → GOOD
- EventBus owns signal definitions only - no game logic

### 2. AutoLoad Singleton Responsibilities
| Singleton | Owns | Never Does |
|---|---|---|
| EventBus | Signals only | Game logic |
| RunState | Run data | Physics/rendering |
| GhostBoardManager | File I/O | Game logic |
| SynergyChecker | Tag counting | Board modification |
| AudioManager | Audio playback | Game logic |
| MutationEngine | Peg state | Rendering |

### 3. Data-Driven Pegs
- All peg values in `data/pegs/peg_definitions.json`
- NEVER hardcode values in GDScript
- Load via: `preload("res://data/pegs/peg_definitions.json")`

### 4. Physics is Sacred
- Ball uses RigidBody2D with real physics
- For special effects (Void Rift teleport), use `_integrate_forces()` with PhysicsDirectBodyState2D
- NEVER set position directly
- CCD must stay ON

### 5. GL Compatibility Only
- No Forward+ features
- All shaders work in WebGL2
- Test web export early

## Naming Conventions

- Scenes: `PascalCase.tscn` (e.g., `StonePeg.tscn`)
- Scripts: `PascalCase.gd` matching scene
- Assets: `snake_case.png`
- Signals: `snake_case` (e.g., `peg_state_changed`)
- Constants: `ALL_CAPS`
- Variables: `_private_with_underscore` or `public_without`

## Peg Implementation Pattern

```gdscript
# BasePeg.gd
func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("ball"):
        return
    _hit_count += 1
    EventBus.peg_hit.emit(self, body)
    _apply_hit_bonus(body)
    _update_shader()

# Subclass adds:
# - _apply_hit_bonus() override for type-specific behavior
# - shader parameters for visual effects
```

## File Organization

```
scenes/
  game/
    Board.tscn
    Ball.tscn
    BallSpawner.tscn
    pegs/
      BasePeg.tscn
      StonePeg.tscn
      ...
  menus/
    MainMenu.tscn

scripts/
  autoloads/
    EventBus.gd
    RunState.gd
    ...
  game/
    Board.gd
    Ball.gd
    pegs/
      BasePeg.gd
      StonePeg.gd

data/
  pegs/peg_definitions.json
  synergies/synergy_definitions.json
```

## Scene Structure (Board.tscn)

```
Board.tscn
├── PhysicsWorld (Node2D)
│   ├── BallSpawner
│   ├── PegContainer
│   ├── PocketRow
│   └── BoardFrame
├── EffectsLayer (CanvasLayer)
├── BoardUI (CanvasLayer)
└── EncounterManager (Node)
```

## Testing

- Test physics at 120 ticks/sec
- Verify ball reaches pockets consistently
- Test web export for GL Compatibility issues
- Check no tunneling with CCD enabled

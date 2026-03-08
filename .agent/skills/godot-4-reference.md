---
name: godot-4-reference
description: Godot 4.6 GDScript reference for Void Oracle - physics patterns, node types, signals, and GL Compatibility specifics
version: 1.0.0
priority: 90
compatible_with: [godot]
---

# Godot 4 Reference

## Project Context

- **Engine**: Godot 4.6
- **Renderer**: GL Compatibility (WebGL2)
- **Language**: GDScript
- **Physics**: 120 ticks/sec

## Key Patterns for Void Oracle

### Peg Signal Pattern
```gdscript
# All pegs inherit from BasePeg - use EventBus for cross-system communication
func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("ball"):
        return
    EventBus.peg_hit.emit(self, body)
```

### Ball Physics
```gdscript
# Ball.gd - RigidBody2D with continuous CD enabled
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    # Use for custom force modifications
    pass
```

### Loading Peg Data
```gdscript
var PEG_DATA = preload("res://data/pegs/peg_definitions.json")
var stone_restitution = PEG_DATA["stone"]["restitution"]
```

### Scene Instantiation
```gdscript
var peg_scene = preload("res://scenes/game/pegs/StonePeg.tscn")
var peg_instance = peg_scene.instantiate()
$PegContainer.add_child(peg_instance)
```

## GL Compatibility Restrictions

- NO SDFGI (no global illumination)
- NO Volumetric fog
- NO Screen-space reflections
- Use `CPUParticles2D` for low-frequency effects
- Use `GPUParticles2D` for performance-critical effects

## PhysicsMaterial Setup

Set on StaticBody2D pegs:
- `friction`: From peg_definitions.json
- `bounce`: From peg_definitions.json (restitution)

## Signal Connections

Use callable syntax in Godot 4:
```gdscript
body.body_entered.connect(_on_body_entered)
```

## CanvasLayer for UI

UI goes in CanvasLayer to stay above physics:
```gdscript
var ui_layer = CanvasLayer.new()
add_child(ui_layer)
```

## Constants

From CLAUDE.md:
- `MUTATION_THRESHOLD` (in MutationEngine)
- All peg values from `data/pegs/peg_definitions.json`

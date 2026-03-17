# Particle Effects Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement particle effects for peg hits and boss phase transitions, following the ART_BIBLE specifications for visual style.

**Architecture:** Create a ParticleEffects AutoLoad that subscribes to EventBus.peg_hit and spawns GPUParticles2D at hit locations. Each peg type/state combination gets appropriate particle colors. Boss screen distortion uses a fullscreen shader.

**Tech Stack:** Godot 4.3+, GDScript, GPUParticles2D, CPUParticles2D, ColorRects for now (placeholders), shaders

---

### Task 1: Create ParticleEffects AutoLoad

**Files:**
- Create: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Create the ParticleEffects AutoLoad**

```gdscript
extends Node

# Particle effect configurations based on ART_BIBLE:
# - Blessed sparkle: Small 4-pointed gold stars, 6-8px, float upward slowly
# - Rot spore: Tiny irregular circles, muted green-brown, drift sideways
# - Void wisp: Dark blue tendril shapes, reach and retract

# Particle colors from ART_BIBLE palette
const COLOR_BLESSED := Color("#C9A84C")    # Blessed Gold
const COLOR_CURSED := Color("#8C1E1E")     # Cursed Crimson
const COLOR_MUTANT := Color("#1E5E2A")     # Mutant Green
const COLOR_VOID := Color("#0A0A1A")       # Deep Void with Void Star rim
const COLOR_DEFAULT := Color("#8880A8")    # Dim Gray

func _ready() -> void:
	# Connect to peg_hit signal like AudioManager does
	EventBus.peg_hit.connect(_on_peg_hit)

func _on_peg_hit(peg: Node, ball: Node) -> void:
	# Spawn particles at the hit location
	# Get peg position for particle spawn
	var spawn_pos := Vector2.ZERO
	if peg and peg.get("global_position"):
		spawn_pos = peg.global_position

	# Get peg state to determine particle type
	var peg_state := "dormant"
	if peg and peg.has_method("get_peg_state_string"):
		peg_state = peg.get_peg_state_string()

	# Spawn appropriate particle effect
	_spawn_hit_particles(spawn_pos, peg_state)

func _spawn_hit_particles(pos: Vector2, peg_state: String) -> void:
	# This will be implemented with actual particle scenes
	pass
```

**Step 2: Register as AutoLoad in project.godot**

Add to Project → Project Settings → Autoloads:
- Name: `ParticleEffects`
- Path: `res://scripts/autoloads/ParticleEffects.gd`

**Step 3: Test compilation**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path /Users/kylelampa/Development/Games/void-oracle --check-only`
Expected: No errors

**Step 4: Commit**

```bash
git add scripts/autoloads/ParticleEffects.gd
git commit -m "feat: Add ParticleEffects AutoLoad stub"
```

---

### Task 2: Create Blessed Sparkle Particle Scene

**Files:**
- Create: `scenes/effects/BlessedSparkle.tscn`
- Modify: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Create BlessedSparkle.tscn**

Create a new scene with CPUParticles2D:
- Amount: 8
- Lifetime: 1.0s
- Emitting: false (one-shot)
- Explosiveness: 0.8
- Direction: (0, -1) - upward
- Spread: 30 degrees
- Gravity: (0, -20) - float up
- Initial Velocity: 20-40
- Scale: 6-8 pixels
- Color: Blessed Gold (#C9A84C)
- Draw Order: Index

**Step 2: Update ParticleEffects to spawn it**

Modify `_spawn_hit_particles` to check peg state and spawn BlessedSparkle when state is "blessed".

**Step 3: Test in editor**

Run the game, hit a blessed peg, verify sparkles appear.

**Step 4: Commit**

```bash
git add scenes/effects/BlessedSparkle.tscn scripts/autoloads/ParticleEffects.gd
git commit -m "feat: Add Blessed Sparkle particles"
```

---

### Task 3: Create Rot Spore Particle Scene

**Files:**
- Create: `scenes/effects/RotSpore.tscn`
- Modify: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Create RotSpore.tscn**

Create a new scene with GPUParticles2D:
- Amount: 12
- Lifetime: 1.5s
- Emitting: false (one-shot)
- Explosiveness: 0.5
- Direction: (1, 0) - sideways drift
- Spread: 60 degrees
- Gravity: (0, 10) - slight downward
- Initial Velocity: 30-50
- Scale: 4-6 pixels
- Color: Mutant Green (#1E5E2A)
- Draw Order: Index

**Step 2: Update ParticleEffects to spawn it**

Modify `_spawn_hit_particles` to check for mutant/rot state and spawn RotSpore.

**Step 3: Test in editor**

Run the game, hit a fungal/mutant peg, verify spores appear.

**Step 4: Commit**

```bash
git add scenes/effects/RotSpore.tscn scripts/autoloads/ParticleEffects.gd
git commit -m "feat: Add Rot Spore particles"
```

---

### Task 4: Create Cursed Crack Particle Scene

**Files:**
- Create: `scenes/effects/CursedCrack.tscn`
- Modify: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Create CursedCrack.tscn**

Based on ART_BIBLE:
- Thin crimson fracture lines radiating outward
- Fade over 0.5s

Create scene with CPUParticles2D:
- Amount: 6
- Lifetime: 0.5s
- Emitting: false
- Direction: radial outward
- Spread: 0 (emit in all directions)
- Initial Velocity: 50-80
- Color: Cursed Crimson (#8C1E1E)
- Scale: decreasing over lifetime

**Step 2: Update ParticleEffects for cursed state**

**Step 3: Commit**

```bash
git add scenes/effects/CursedCrack.tscn scripts/autoloads/ParticleEffects.gd
git commit -m "feat: Add Cursed Crack particles"
```

---

### Task 5: Create Void Wisp Particle Scene

**Files:**
- Create: `scenes/effects/VoidWisp.tscn`
- Modify: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Create VoidWisp.tscn**

Based on ART_BIBLE:
- Dark blue tendril shapes, reach and retract

Create scene with GPUParticles2D:
- Amount: 4
- Lifetime: 1.0s
- Emitting: false
- Direction: random
- Color: Deep Void with Void Star (#C8D4FF rim)
- Scale: 8-12 pixels

**Step 2: Update ParticleEffects for void state**

**Step 3: Commit**

```bash
git add scenes/effects/VoidWisp.tscn scripts/autoloads/ParticleEffects.gd
git commit -m "feat: Add Void Wisp particles"
```

---

### Task 6: Create Generic Hit Particle System

**Files:**
- Modify: `scripts/autoloads/ParticleEffects.gd`

**Step 1: Add default particle for dormant/neutral pegs**

Simple white/gray particles for default hits.

**Step 2: Update ParticleEffects to handle all states**

Ensure all peg states have appropriate particles.

**Step 3: Commit**

```bash
git commit -m "feat: Add generic hit particles"
```

---

### Task 7: Boss Screen Distortion Shader

**Files:**
- Create: `shaders/boss_distortion.gdshader`
- Modify: `scenes/game/Board.tscn` (or add to EffectsLayer)

**Step 1: Create boss_distortion.gdshader**

```glsl
shader_type canvas_item;

uniform float distortion_amount : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    float distort = sin(TIME * time_scale + uv.y * 10.0) * distortion_amount * 0.02;
    uv.x += distort;
    vec4 color = texture(TEXTURE, uv);
    COLOR = color;
}
```

**Step 2: Add to EffectsLayer**

Add a ColorRect with this shader to Board.tscn EffectsLayer.

**Step 3: Connect to boss phase changes**

Listen to EventBus.boss_phase_changed and animate distortion_amount.

**Step 4: Commit**

```bash
git add shaders/boss_distortion.gdshader scripts/game/Board.gd
git commit -m "feat: Add boss screen distortion"
```

---

### Task 8: Final Testing and Integration

**Step 1: Run full game test**

Run: `./run_debug.sh`
- Start new run
- Hit various peg types
- Verify particles appear correctly

**Step 2: Test boss distortion**

- Face a boss enemy
- Verify phase transition triggers distortion

**Step 3: Commit final**

```bash
git add -A
git commit -m "feat: Complete particle effects system"
```

---

## Summary

| Task | Files | Status |
|------|-------|--------|
| 1. ParticleEffects AutoLoad | scripts/autoloads/ParticleEffects.gd | ⬜ |
| 2. Blessed Sparkle | scenes/effects/BlessedSparkle.tscn | ⬜ |
| 3. Rot Spore | scenes/effects/RotSpore.tscn | ⬜ |
| 4. Cursed Crack | scenes/effects/CursedCrack.tscn | ⬜ |
| 5. Void Wisp | scenes/effects/VoidWisp.tscn | ⬜ |
| 6. Generic Hit | scripts/autoloads/ParticleEffects.gd | ⬜ |
| 7. Boss Distortion | shaders/boss_distortion.gdshader | ⬜ |
| 8. Integration Test | - | ⬜ |

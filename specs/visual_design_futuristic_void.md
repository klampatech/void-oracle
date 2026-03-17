# Void Oracle Visual Design — Futuristic Void Theme

**Created:** 2026-03-17
**Style:** Futuristic Void — Clean geometric patterns with glowing neon accents
**Scope:** All elements (pegs, ball, enemies, UI)

---

## 1. Color Palette

The Futuristic Void aesthetic uses deep void blacks contrasted with sharp neon accents.

### Primary Colors

| Role | Hex | Usage |
|------|-----|-------|
| Void Black | `#0A0A14` | Main background |
| Void Deep | `#12121F` | Secondary backgrounds, panels |
| Void Edge | `#1A1A2E` | Borders, dividers |
| Void Glow | `#252540` | Hover states, subtle highlights |

### Accent Colors (Neon Glow)

| Role | Hex | Usage |
|------|-----|-------|
| Cyan Neon | `#00F5FF` | Primary actions, stone pegs |
| Magenta Void | `#FF00FF` | Rare/legendary items, oracle |
| Gold Oracle | `#FFD700` | Void shards, achievements |
| Toxic Green | `#39FF14` | Growth/synergy effects |
| Ember Orange | `#FF6B00` | Fire damage, ember pegs |
| Blood Red | `#FF1744` | Damage, enemies |
| Soul White | `#E0E0FF` | Text, death/reveal |

### Peg-Specific Colors

| Peg Type | Primary | Secondary Glow | Shape |
|----------|---------|---------------|-------|
| Stone | `#4A5568` | `#00F5FF` (cyan ring) | Hexagon |
| Bone | `#E8E0D0` | `#FF00FF` (magenta core) | Skull triangle |
| Fungal | `#2D5A27` | `#39FF14` (green spores) | Organic circle |
| Ember | `#FF6B00` | `#FFD700` (fire glow) | Flame diamond |
| Eye | `#6B5B95` | `#FF00FF` (void eye) | Eye shape |
| Heart | `#B71C1C` | `#FF1744` (pulse glow) | Heart |
| Oracle | `#FFD700` | Rainbow cycle | Star octagon |
| Void Rift | `#0A0A2A` | `#00F5FF` (portal swirl) | Spiral portal |

---

## 2. SVG Asset Specifications

### Peg Designs (64x64 viewBox)

All pegs follow this structure:
- **Base shape**: Geometric (hexagon, diamond, etc.)
- **Inner detail**: Symbol representing peg type
- **Glow ring**: Animated neon outline
- **State indicators**: Visual feedback for blessed/cursed/void

#### Stone Peg — Hexagon Foundation
```
<svg viewBox="0 0 64 64">
  <defs>
    <filter id="glow-cyan">...</filter>
    <linearGradient id="stone-grad">...</linearGradient>
  </defs>
  <!-- Hexagon base -->
  <polygon points="32,4 56,18 56,46 32,60 8,46 8,18" fill="url(#stone-grad)"/>
  <!-- Neon ring -->
  <polygon points="32,4 56,18 56,46 32,60 8,46 8,18" fill="none" stroke="#00F5FF" stroke-width="2" filter="url(#glow-cyan)"/>
  <!-- Foundation symbol (nested hex) -->
  <polygon points="32,12 48,22 48,42 32,52 16,42 16,22" fill="none" stroke="#00F5FF" stroke-width="1"/>
</svg>
```

#### Bone Peg — Death Triangle
```
<svg viewBox="0 0 64 64">
  <!-- Skull-in-triangle base -->
  <polygon points="32,8 56,56 8,56" fill="#E8E0D0"/>
  <!-- Magenta inner glow -->
  <circle cx="32" cy="36" r="8" fill="#FF00FF" opacity="0.6" filter="url(#glow-magenta)"/>
  <!-- Sharp eye sockets -->
  <circle cx="26" cy="30" r="4" fill="#0A0A14"/>
  <circle cx="38" cy="30" r="4" fill="#0A0A14"/>
</svg>
```

*(Similar patterns for Fungal, Ember, Eye, Heart, Oracle, Void Rift)*

### Ball Design (32x32)

```
<svg viewBox="0 0 32 32">
  <!-- Void core -->
  <circle cx="16" cy="16" r="14" fill="#1A1A2E"/>
  <!-- Neon rim -->
  <circle cx="16" cy="16" r="14" fill="none" stroke="#00F5FF" stroke-width="2" filter="url(#glow-cyan)"/>
  <!-- Inner glow -->
  <circle cx="16" cy="16" r="8" fill="#00F5FF" opacity="0.3"/>
  <!-- Trail particles (CSS animation) -->
</svg>
```

### UI Elements

#### Main Menu Panel
- Background: `#12121F` with `#1A1A2E` border
- Corner accents: Neon cyan lines (geometric bracket corners)
- Buttons: Transparent with `#00F5FF` border, glow on hover

#### Button Design
```
<!-- Default state -->
<rect width="200" height="48" rx="4" fill="#12121F" stroke="#00F5FF" stroke-width="2"/>

<!-- Hover state -->
<rect width="200" height="48" rx="4" fill="#1A1A2E" stroke="#00F5FF" stroke-width="2" filter="url(#glow-cyan)"/>

<!-- Text: Soul White -->
<text x="100" y="30" text-anchor="middle" fill="#E0E0FF">START RUN</text>
```

#### Stability Bar
- Container: `#1A1A2E` border
- Fill gradient: `#00F5FF` (full) → `#FF1744` (empty)
- Animated pulse when low

---

## 3. Shader Effects

### Peg Glow Shader (peg_state.gdshader already exists, extend it)

```glsl
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 0.96, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Pulsing glow
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    vec4 glow = glow_color * glow_intensity * pulse;

    COLOR = tex_color + glow * (1.0 - tex_color.a);
}
```

### Void Portal Effect (for Void Rift)

```glsl
// Animated spiral distortion
uniform float rotation_speed = 1.0;
uniform float distortion_amount = 0.1;

void fragment() {
    vec2 center = UV - 0.5;
    float angle = atan(center.y, center.x);
    float dist = length(center);

    // Spiral animation
    float spiral = sin(angle * 6.0 + TIME * rotation_speed + dist * 10.0);
    vec2 offset = normalize(center) * spiral * distortion_amount;

    vec4 color = texture(TEXTURE, UV + offset);
    // Add chromatic aberration
    color.r = texture(TEXTURE, UV + offset * 1.1).r;
    color.b = texture(TEXTURE, UV + offset * 0.9).b;

    COLOR = color;
}
```

---

## 4. Implementation Plan

### Phase 1: Core Assets (Priority)
1. Create SVG files for all 8 peg types
2. Create ball SVG with glow
3. Create pocket SVG markers
4. Set up Godot SVG import settings

### Phase 2: UI System (Priority)
1. Design system tokens (colors, spacing, typography)
2. Create SVG-based button components
3. Create panel/background SVGs
4. Update MainMenu.tscn with new visuals

### Phase 3: Game Elements
1. Replace ColorRect pegs with SVG sprites
2. Add glow shaders to pegs
3. Create enemy icon SVGs
4. Update particle effects with neon colors

### Phase 4: Polish
1. Add hover/active states to all interactive elements
2. Implement screen-space glow (WorldEnvironment)
3. Add subtle animations (pulse, float)
4. Test web export compatibility

---

## 5. File Structure

```
assets/
├── svg/
│   ├── pegs/
│   │   ├── stone.svg
│   │   ├── bone.svg
│   │   ├── fungal.svg
│   │   ├── ember.svg
│   │   ├── eye.svg
│   │   ├── heart.svg
│   │   ├── oracle.svg
│   │   └── void_rift.svg
│   ├── ui/
│   │   ├── button_default.svg
│   │   ├── button_hover.svg
│   │   ├── panel_bg.svg
│   │   ├── stability_bar.svg
│   │   └── corner_accent.svg
│   ├── ball.svg
│   ├── pocket.svg
│   └── icons/
│       ├── gold.svg
│       ├── stability.svg
│       └── void_shard.svg
└── textures/
    └── (existing)
```

---

## 6. Acceptance Criteria

- [ ] All 8 peg types render as vector graphics with distinct silhouettes
- [ ] Neon glow visible on all pegs, adjustable per state (blessed/cursed)
- [ ] Main menu has cohesive Futuristic Void aesthetic
- [ ] All buttons have hover/active states with glow feedback
- [ ] Ball has visible neon glow trail
- [ ] Web export maintains visual quality (no texture compression artifacts)
- [ ] Performance: 60fps with 50+ pegs on screen

---

## 7. Next Steps

1. **Approve this design** → Move to implementation
2. **Request changes** → Revise specific sections
3. **Add requirements** → Extend scope


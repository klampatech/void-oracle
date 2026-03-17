# Visual Design Implementation Plan — Futuristic Void Theme

> **For Claude:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace placeholder graphics with vector SVG assets and create a cohesive Futuristic Void aesthetic across all game elements.

**Architecture:** Create SVG assets in `assets/svg/`, import as textures, replace existing ColorRect/placeholder elements with sprite-based visuals, add glow shaders for neon effects.

**Tech Stack:** Godot 4.3+, SVG imports, custom shaders (GLSL), ColorRects → Sprites

---

## Task 1: Create SVG Asset Directory Structure

**Files:**
- Create: `assets/svg/pegs/`
- Create: `assets/svg/ui/`
- Create: `assets/svg/icons/`

**Step 1: Create directories**

```bash
mkdir -p assets/svg/pegs assets/svg/ui assets/svg/icons
```

**Step 2: Verify Godot SVG import settings**

Check if Godot has SVG support enabled (SVG is supported natively in Godot 4.x).

---

## Task 2: Create Peg SVG Assets

**Files:**
- Create: `assets/svg/pegs/stone.svg` — Hexagon with cyan neon ring
- Create: `assets/svg/pegs/bone.svg` — Skull triangle with magenta core
- Create: `assets/svg/pegs/fungal.svg` — Organic circle with green spores
- Create: `assets/svg/pegs/ember.svg` — Flame diamond with fire glow
- Create: `assets/svg/pegs/eye.svg` — Eye shape with void glow
- Create: `assets/svg/pegs/heart.svg` — Heart with pulse glow
- Create: `assets/svg/pegs/oracle.svg` — Star octagon with rainbow cycle
- Create: `assets/svg/pegs/void_rift.svg` — Spiral portal

**Step 1: Write stone.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-cyan" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <linearGradient id="stone-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A5568"/>
      <stop offset="100%" style="stop-color:#2D3748"/>
    </linearGradient>
  </defs>
  <!-- Hexagon base -->
  <polygon points="32,4 56,18 56,46 32,60 8,46 8,18" fill="url(#stone-grad)"/>
  <!-- Neon ring -->
  <polygon points="32,4 56,18 56,46 32,60 8,46 8,18" fill="none" stroke="#00F5FF" stroke-width="2" filter="url(#glow-cyan)"/>
  <!-- Inner hex -->
  <polygon points="32,12 48,22 48,42 32,52 16,42 16,22" fill="none" stroke="#00F5FF" stroke-width="1" opacity="0.6"/>
</svg>
```

**Step 2: Write bone.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-magenta" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Triangle base -->
  <polygon points="32,8 56,56 8,56" fill="#E8E0D0"/>
  <!-- Magenta glow center -->
  <circle cx="32" cy="40" r="8" fill="#FF00FF" opacity="0.5" filter="url(#glow-magenta)"/>
  <!-- Eye sockets -->
  <circle cx="24" cy="28" r="5" fill="#0A0A14"/>
  <circle cx="40" cy="28" r="5" fill="#0A0A14"/>
  <!-- Nose -->
  <polygon points="32,34 28,42 36,42" fill="#0A0A14"/>
</svg>
```

**Step 3: Write fungal.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-green" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Organic cap -->
  <ellipse cx="32" cy="28" rx="24" ry="18" fill="#2D5A27"/>
  <!-- Stem -->
  <rect x="26" y="38" width="12" height="18" rx="4" fill="#1E3D1A"/>
  <!-- Spore glow -->
  <circle cx="32" cy="28" r="12" fill="#39FF14" opacity="0.4" filter="url(#glow-green)"/>
  <!-- Spots -->
  <circle cx="22" cy="22" r="4" fill="#39FF14" opacity="0.6"/>
  <circle cx="42" cy="24" r="3" fill="#39FF14" opacity="0.6"/>
  <circle cx="32" cy="18" r="2" fill="#39FF14" opacity="0.6"/>
</svg>
```

**Step 4: Write ember.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-orange" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Flame diamond -->
  <polygon points="32,4 56,32 32,60 8,32" fill="#FF6B00"/>
  <!-- Inner fire -->
  <polygon points="32,12 48,32 32,52 16,32" fill="#FFD700"/>
  <!-- Core glow -->
  <polygon points="32,20 40,32 32,44 24,32" fill="#FF4500" filter="url(#glow-orange)"/>
  <!-- Spark -->
  <circle cx="32" cy="32" r="4" fill="#FFFFFF" opacity="0.8"/>
</svg>
```

**Step 5: Write eye.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-void" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Eye outline -->
  <ellipse cx="32" cy="32" rx="26" ry="16" fill="#1A1A2E" stroke="#6B5B95" stroke-width="3"/>
  <!-- Iris -->
  <circle cx="32" cy="32" r="12" fill="#6B5B95"/>
  <!-- Pupil -->
  <circle cx="32" cy="32" r="6" fill="#0A0A14"/>
  <!-- Void glow -->
  <circle cx="32" cy="32" r="14" fill="none" stroke="#FF00FF" stroke-width="2" opacity="0.6" filter="url(#glow-void)"/>
  <!-- Highlight -->
  <circle cx="28" cy="28" r="3" fill="#FFFFFF" opacity="0.8"/>
</svg>
```

**Step 6: Write heart.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-red" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Heart shape -->
  <path d="M32 56 L8 32 C4 28 4 20 8 16 C12 12 20 12 24 16 L32 24 L40 16 C44 12 52 12 56 16 C60 20 60 28 56 32 Z" fill="#B71C1C"/>
  <!-- Inner glow -->
  <path d="M32 48 L14 30 C12 28 12 24 14 22 C16 20 20 20 22 22 L32 32 L42 22 C44 20 48 20 50 22 C52 24 52 28 50 30 Z" fill="#FF1744" opacity="0.6" filter="url(#glow-red)"/>
  <!-- Shine -->
  <ellipse cx="20" cy="24" rx="4" ry="6" fill="#FFFFFF" opacity="0.4"/>
</svg>
```

**Step 7: Write oracle.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="oracle-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFD700"/>
      <stop offset="25%" style="stop-color:#FF00FF"/>
      <stop offset="50%" style="stop-color:#00F5FF"/>
      <stop offset="75%" style="stop-color:#39FF14"/>
      <stop offset="100%" style="stop-color:#FFD700"/>
    </linearGradient>
  </defs>
  <!-- Star octagon -->
  <polygon points="32,4 42,14 56,14 56,28 48,38 56,56 32,60 8,56 16,38 8,28 8,14 22,14" fill="#1A1A2E" stroke="url(#oracle-grad)" stroke-width="2"/>
  <!-- Inner star -->
  <polygon points="32,12 38,20 48,20 40,28 44,38 32,32 20,38 24,28 16,20 26,20" fill="url(#oracle-grad)"/>
  <!-- Center gem -->
  <circle cx="32" cy="32" r="6" fill="#FFD700" filter="url(#glow-cyan)"/>
</svg>
```

**Step 8: Write void_rift.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <filter id="glow-rift" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Void circle -->
  <circle cx="32" cy="32" r="26" fill="#0A0A2A"/>
  <!-- Spiral -->
  <path d="M32 32 Q32 16 20 16 Q8 16 8 32 Q8 48 24 48 Q40 48 40 32 Q40 20 28 20" fill="none" stroke="#00F5FF" stroke-width="2" filter="url(#glow-rift)"/>
  <path d="M32 32 Q32 22 24 22 Q16 22 16 32 Q16 42 28 42" fill="none" stroke="#00F5FF" stroke-width="2" opacity="0.6" filter="url(#glow-rift)"/>
  <!-- Center void -->
  <circle cx="32" cy="32" r="6" fill="#0A0A14"/>
</svg>
```

---

## Task 3: Create Ball SVG

**Files:**
- Create: `assets/svg/ball.svg`

**Step 1: Write ball.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <defs>
    <filter id="ball-glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Void core -->
  <circle cx="16" cy="16" r="14" fill="#1A1A2E"/>
  <!-- Neon rim -->
  <circle cx="16" cy="16" r="14" fill="none" stroke="#00F5FF" stroke-width="2" filter="url(#ball-glow)"/>
  <!-- Inner glow -->
  <circle cx="16" cy="16" r="8" fill="#00F5FF" opacity="0.3"/>
  <!-- Highlight -->
  <circle cx="12" cy="12" r="3" fill="#FFFFFF" opacity="0.6"/>
</svg>
```

---

## Task 4: Create UI SVG Assets

**Files:**
- Create: `assets/svg/ui/button_default.svg`
- Create: `assets/svg/ui/button_hover.svg`
- Create: `assets/svg/ui/panel_bg.svg`
- Create: `assets/svg/ui/corner_accent.svg`

**Step 1: Write button_default.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 48">
  <defs>
    <filter id="btn-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="2" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Background -->
  <rect x="2" y="2" width="196" height="44" rx="4" fill="#12121F" stroke="#00F5FF" stroke-width="2"/>
  <!-- Inner accent -->
  <rect x="6" y="6" width="188" height="36" rx="2" fill="none" stroke="#00F5FF" stroke-width="1" opacity="0.3"/>
</svg>
```

**Step 2: Write button_hover.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 48">
  <defs>
    <filter id="btn-glow-hover" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="4" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Background -->
  <rect x="2" y="2" width="196" height="44" rx="4" fill="#1A1A2E" stroke="#00F5FF" stroke-width="2" filter="url(#btn-glow-hover)"/>
  <!-- Inner glow -->
  <rect x="6" y="6" width="188" height="36" rx="2" fill="#00F5FF" opacity="0.1"/>
  <rect x="6" y="6" width="188" height="36" rx="2" fill="none" stroke="#00F5FF" stroke-width="1" opacity="0.5"/>
</svg>
```

**Step 3: Write panel_bg.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300">
  <!-- Background -->
  <rect width="400" height="300" fill="#12121F"/>
  <!-- Border -->
  <rect x="2" y="2" width="396" height="296" rx="8" fill="none" stroke="#1A1A2E" stroke-width="4"/>
  <!-- Inner line -->
  <rect x="6" y="6" width="388" height="288" rx="6" fill="none" stroke="#00F5FF" stroke-width="1" opacity="0.2"/>
</svg>
```

**Step 4: Write corner_accent.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <!-- Top-left corner -->
  <path d="M4 4 L4 16 M4 4 L16 4" stroke="#00F5FF" stroke-width="2" fill="none"/>
  <!-- Glow effect -->
  <path d="M4 4 L4 16 M4 4 L16 4" stroke="#00F5FF" stroke-width="4" fill="none" opacity="0.3"/>
</svg>
```

---

## Task 5: Create Icon SVGs

**Files:**
- Create: `assets/svg/icons/gold.svg`
- Create: `assets/svg/icons/stability.svg`
- Create: `assets/svg/icons/void_shard.svg`

**Step 1: Write gold.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" fill="#FFD700"/>
  <text x="12" y="16" text-anchor="middle" fill="#12121F" font-size="12" font-weight="bold">$</text>
</svg>
```

**Step 2: Write stability.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <rect x="4" y="4" width="16" height="16" rx="2" fill="#00F5FF"/>
  <rect x="8" y="8" width="8" height="8" fill="#12121F"/>
</svg>
```

**Step 3: Write void_shard.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <polygon points="12,2 20,8 20,16 12,22 4,16 4,8" fill="#6B5B95"/>
  <polygon points="12,6 16,10 16,14 12,18 8,14 8,10" fill="#FF00FF"/>
</svg>
```

---

## Task 6: Import SVGs into Godot

**Files:**
- Modify: Import settings for SVG files

**Step 1: Drag assets/svg/ folder into Godot project**

Godot 4.x auto-imports SVGs. Verify import settings:
- SVG → Compress: Lossless
- Scale: 1.0
- Preserve edges: On

**Step 2: Verify imports**

Check `.godot/imported/` for SVG files.

---

## Task 7: Update Peg Scenes to Use SVG Sprites

**Files:**
- Modify: `scenes/game/pegs/StonePeg.tscn`
- Modify: `scenes/game/pegs/BonePeg.tscn`
- Modify: `scenes/game/pegs/FungalPeg.tscn`
- Modify: `scenes/game/pegs/EmberPeg.tscn`
- Modify: `scenes/game/pegs/EyePeg.tscn`
- Modify: `scenes/game/pegs/HeartPeg.tscn`
- Modify: `scenes/game/pegs/OraclePeg.tscn`
- Modify: `scenes/game/pegs/VoidRiftPeg.tscn`

**Step 1: Read StonePeg.tscn**

```bash
cat scenes/game/pegs/StonePeg.tscn
```

**Step 2: Replace ColorRect with Sprite2D**

Replace:
```
[node name="Sprite2D" type="ColorRect"]
```

With:
```
[node name="Sprite2D" type="Sprite2D"]
texture = preload("res://assets/svg/pegs/stone.svg")
```

Repeat for all peg types.

---

## Task 8: Update Ball Scene

**Files:**
- Modify: `scenes/game/Ball.tscn`

**Step 1: Read Ball.tscn**

**Step 2: Replace ColorRect with Sprite2D**

Replace ball's ColorRect with Sprite2D using `res://assets/svg/ball.svg`.

---

## Task 9: Update MainMenu UI

**Files:**
- Modify: `scenes/menus/MainMenu.tscn`

**Step 1: Read MainMenu.tscn**

**Step 2: Add panel backgrounds**

Add SVG-based panel backgrounds using Sprite2D nodes behind UI elements.

**Step 3: Update button styles**

Replace Button default styling with custom theme using SVG backgrounds.

---

## Task 10: Add Glow WorldEnvironment

**Files:**
- Modify: `scenes/game/Board.tscn`

**Step 1: Add WorldEnvironment node**

```gdscript
[node name="WorldEnvironment" type="WorldEnvironment"]
```

**Step 2: Configure Environment**

Set up glow/bloom:
- Mode: Additive
- Bloom: 0.5
- Blend Mode: Screen

---

## Task 11: Verify in Editor

**Step 1: Open project in Godot**

Run: `godot --editor &`

**Step 2: Verify all pegs render correctly**

Check each peg scene shows SVG sprite with glow.

**Step 3: Run game**

Verify ball, pegs, UI all display properly.

**Step 4: Test web export**

Export to HTML5 and verify visuals.

---

## Verification

Run through all scenes in editor:
1. Main Menu loads with new visual style
2. Board shows all peg types with neon glow
3. Ball has visible glow effect
4. UI elements use new SVG assets
5. Web export maintains visual quality

---

**Plan saved to:** `docs/plans/2026-03-17-visual-design.md`

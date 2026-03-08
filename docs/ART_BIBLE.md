# Void Oracle — Asset List & Art Bible
*Hand this to your artist. Everything they need to know to create assets independently.*

---

## Aesthetic Direction

**The board is a ritual.** Not a machine — a living, breathing altar that barely tolerates the player's presence. Every asset should feel *grown*, not manufactured.

### Palette

| Name | Hex | Usage |
|---|---|---|
| Deep Void | `#0A0A1A` | Primary background |
| Cosmic Purple | `#2D1B5E` | Secondary background, shadows |
| Eldritch | `#4A1E8C` | UI borders, accents, mid-tone |
| Blessed Gold | `#C9A84C` | Blessed state, key UI elements, headings |
| Cursed Crimson | `#8C1E1E` | Cursed state, danger, enemy |
| Mutant Green | `#1E5E2A` | Mutant/growth state, rot, biological |
| Ghost White | `#E8E4F0` | Text, neutral UI, dormant pegs |
| Dim Gray | `#8880A8` | Subtext, inactive UI, shattered pegs |
| Void Star | `#C8D4FF` | Void-touched particles, star accents |

### Typography (for UI, not needed as assets — handled in engine)
- Display/headers: Georgia or a serif with weight. Slightly archaic. Not modern sans-serif.
- Body/numbers: Calibri or similar clean readable font.

### Do Not
- No clean geometric shapes — everything slightly irregular, organic
- No bright whites or pure blacks — always tinted toward Deep Void or Ghost White
- No cartoonish outlines — subtle inner glow, not hard outline
- No modern/tech aesthetic — ancient, biological, eldritch

---

## Pegs (Core Priority — Needed for M1)

All pegs are circular. Base diameter: **32px** (displayed at various scales, design at 2x = 64px).

Each peg needs **4 state variants** (or design base + shader-friendly texture for runtime tinting):

| State | Visual Description |
|---|---|
| Dormant | Neutral, slightly textured, muted color |
| Blessed | Gold veins threading through, warm inner glow |
| Cursed | Crimson cracks spreading outward, dark core |
| Mutant | Bioluminescent green pustules, wet/organic look |
| Void-Touched | Near-black with tiny star points within, faint blue rim |
| Shattered | Cracked, fragmented, dark — parts visibly missing |

> **Efficiency tip for artist:** Design each peg's *dormant* state. Then design a single "blessed overlay," "cursed overlay," and "mutant overlay" texture that can be composited. This saves 3–4x work. The shader does the final blending at runtime.

### Peg Type Designs

| Peg | Description | Key Visual Element |
|---|---|---|
| **Stone Peg** | Ancient river rock. Smooth, dense, weathered. | Faint grain lines, grey-brown |
| **Bone Peg** | A vertebra or joint bone, slightly yellowed. | Visible bone texture, hollow core visible |
| **Fungal Peg** | Mushroom cap cross-section. Wet, spored. | Gill texture underneath, spore dots on surface |
| **Ember Peg** | Glowing coal, cracks of orange-white heat visible. | Internal fire glow, dark ashy exterior |
| **Eye Peg** | A lidless eye, always watching. Iris visible. | Sclera, iris, pupil — no lid, slightly veined |
| **Heart Peg** | Anatomical heart, glistening, still beating. | Ventricle texture, a single drip of ichor |
| **Oracle Peg** | All symbols at once — an impossible geometry. | Concentric rings of all other peg symbols, overlapping |
| **Void Rift Peg** | A tear in space. Darkness with depth. | Not a circle — a void that *has* edges, wisps of dark smoke |

---

## Ball

Single ball design. **24px diameter** (design at 2x = 48px).

| Ball State | Visual |
|---|---|
| Normal | Pearlescent white sphere, very subtle inner shimmer |
| Void Ball | Deep blue-black, tiny star points, faint glow |
| Chaos Ball | Rapidly shifting — the artist designs the base; color cycling handled by shader |

The ball leaves a **trail** (handled in engine with Line2D + shader), so no trail asset needed. But design the ball to look good mid-motion — slight motion-blur-friendly silhouette.

---

## Board

### Background
**1080×1920px** (portrait — mobile-first canvas). Designed as a layered PSD/Figma file:

1. **Base layer**: Deep Void (`#0A0A1A`) — solid fill
2. **Texture layer**: Subtle noise/grain overlay, 15% opacity. Ancient stone or cosmic static feel.
3. **Vignette layer**: Radial gradient darkening edges. Center slightly lighter.
4. **Star field layer**: ~200 tiny scattered dots, Void Star color, randomized opacity 20–60%
5. **Void Channel hints**: Faint vertical lighter bands where Void Channels typically appear

> Note: Corruption ink spread is handled by shader at runtime. The background asset should be neutral enough that crimson ink spreading over it looks dramatic.

### Board Frame
The walls of the board. Delivered as a 9-slice-friendly sprite or a repeating tile.

- Material: Ancient carved stone or bone. NOT metal. NOT wood.
- Has carved rune-like markings at intervals (purely decorative)
- Top edge: slightly ornate — this is the "launch mouth" of the ritual machine
- **Size needed**: Left/right wall strips at ~40px wide, top/bottom ~40px tall, corners ~40px square

### Pocket Row
8 pockets at the bottom. Each pocket is ~80px wide, ~60px tall.

| Pocket Type | Visual | Color |
|---|---|---|
| Damage (×2) | A cracked skull or fang motif | Crimson |
| Heal (×2) | A dripping heart or leaf | Muted gold-green |
| Gold (×2) | Coin stack or alchemy symbol | Blessed Gold |
| Void (×1) | The void rift symbol | Deep void blue |
| Chaos (×1) | A spinning spiral, unstable | All colors blending |

---

## UI Elements

### HUD (In-Game Overlay)

| Asset | Size | Description |
|---|---|---|
| Stability bar background | 400×30px | Dark stone, carved slot |
| Stability bar fill | 380×18px | Gold fill that shifts to crimson at low values (shader tintable) |
| Stability bar icon | 32×32px | Small anatomical heart |
| Gold icon | 24×24px | Glowing coin, alchemical |
| Void Essence icon | 24×24px | Tiny void rift, contained |
| Ball counter icon | 24×24px | Single pearl/ball |
| Drop button | 120×60px | Stone tablet with carved drop-arrow |
| End Turn button | 120×60px | Same, different symbol |

### Map Screen

| Asset | Size | Description |
|---|---|---|
| Map node — Combat | 48×48px | Crossed bones or weapons |
| Map node — Elite | 48×48px | Glowing skull |
| Map node — Event | 48×48px | Eye in a triangle |
| Map node — Shop | 48×48px | Alchemical scales |
| Map node — Rest | 48×48px | A dormant peg with soft glow |
| Map node — Boss | 64×64px | Large ominous entity silhouette |
| Map node — Ghost | 48×48px | Transparent/ghostly version of above nodes |
| Map path line | Tileable | Thin ancient chain or rope connecting nodes |
| Map background | 1080×1920px | Same as board background but even darker, constellation-like |

### Draft Screen

| Asset | Size | Description |
|---|---|---|
| Draft card background | 200×280px | Stone tablet with carved frame. 9-slice friendly. |
| Draft card tier — Common | Overlay | No decoration |
| Draft card tier — Uncommon | Overlay | Silver rune border |
| Draft card tier — Rare | Overlay | Gold rune border, soft glow |
| Draft card tier — Legendary | Overlay | Full illuminated border, animated shimmer (if possible) |

---

## Enemy Assets

Each enemy needs: **idle sprite** + **attack animation** (3–4 frames or spritesheet) + **death animation**.

| Enemy | Size | Visual Description |
|---|---|---|
| **Corruptor** | 200×300px | A writhing mass of crimson tendrils. No fixed form. Pulsates slowly. Attack: a tendril extends toward a peg. |
| **Wrecker** | 200×300px | A heavy, ancient stone golem with cracked knuckles. Slow, deliberate. Attack: fist slams down. |
| **Spawner** | 200×300px | A bloated, floating jellyfish-like entity. Transparent body, dark core. Attack: releases small balls from its underside. |
| **Mycologist** | 200×300px | A hooded figure whose lower body is a mass of fungal growth. Spores drift from it constantly. |
| **The Gardener (Boss)** | 300×400px | Phase 1: elegant, serene humanoid made of vines and pruning shears. Phase 2: monstrous, frenzied, thorn-covered. |
| **Architect of Ruin (Boss)** | 300×400px | A vast, slow, geometric entity — like a crumbling cathedral given consciousness. Each phase it loses structural integrity. |
| **Final Oracle (Boss)** | 300×400px | A perfect mirror of the player's own board. Literally: the board, reflected, as a face. |

---

## Effects & Particles (Reference Only — Implemented by Engine)

These are described so the art style is consistent if any hand-animated frames are needed:

- **Blessed sparkle**: Small 4-pointed gold stars, 6–8px, float upward slowly
- **Cursed crack**: Thin crimson fracture lines radiating outward, fade over 0.5s
- **Rot spore**: Tiny irregular circles, muted green-brown, drift sideways
- **Void wisp**: Dark blue tendril shapes, reach and retract
- **Ember ignite**: Brief orange-white flash, circular, 0.2s duration

---

## Fonts (Engine-Handled — Artist Reference Only)

No font assets needed. Engine uses:
- Headers: Georgia (system font)
- Body: Calibri (system font)

If the artist wants to suggest a thematic display font for a future iteration, it should feel: *archaic, slightly irregular, readable at small sizes, serif*. Reference: Cinzel, Cormorant Garamond, Vollkorn.

---

## Asset Delivery Format

| Type | Format | Notes |
|---|---|---|
| Sprites / UI | PNG, transparent background | 2x resolution (72dpi minimum) |
| Backgrounds | PNG or JPG | Full 1080×1920px |
| Spritesheets | PNG, horizontal strip | Label frame count in filename: `gardener_idle_8f.png` |
| Layered source | PSD or Figma | Deliver for backgrounds and complex UI |

**Naming convention**: `snake_case_descriptive.png`
Examples: `peg_fungal_dormant.png`, `enemy_corruptor_attack_4f.png`, `pocket_damage.png`

**Delivery folder structure**:
```
assets/
  pegs/         ← all peg sprites
  balls/        ← ball sprites
  board/        ← background, frame, pockets
  ui/           ← HUD, buttons, map nodes
  enemies/      ← enemy sprites + animations
  effects/      ← any hand-animated effect frames
```

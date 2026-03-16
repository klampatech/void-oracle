# PRD: Milestone 7 — Polish & Web Export

## Introduction

Milestone 7 brings the game to release quality: all shaders finalized, audio system complete, UI polished, and web export tested on itch.io. This is the launch-ready milestone.

**Goal:** Ship to web. Game feels complete. Players can play and complete the full experience.

---

## Goals

- [ ] Full Shader Pass (all pegs, corruption, trails)
- [ ] Audio: Per-Peg Tone System
- [ ] Audio: Ambient Layering (3 loop tracks, zone-based)
- [ ] Main Menu + UI Polish
- [ ] Web Export Test (itch.io test page)
- [ ] Mobile Touch Input Layer

---

## User Stories

### VO-030: Full Shader Pass
**Description:** As a player, I want polished visuals so the game feels cohesive and atmospheric.

**Acceptance Criteria:**
- [ ] All 8 peg types have final shader visuals (not placeholders)
- [ ] Peg state shader fully implemented: blessed gold veins, neutral stone, crimson cracks, mutant pustules
- [ ] Corruption spread shader: ink-bleeding effect across background
- [ ] Ball trail shader: ghost-blue fading trail
- [ ] Screen effects: boss phase transitions have subtle distortion
- [ ] All shaders work in WebGL2 (Compatibility renderer)

---

### VO-031: Audio: Per-Peg Tone System
**Description:** As a player, I want each peg to have a unique sound so the board feels musical.

**Acceptance Criteria:**
- [ ] Each peg type has a unique resonant tone
- [ ] Tones play on ball collision
- [ ] Blessed pegs: bell-like, clear
- [ ] Cursed pegs: bass drone
- [ ] Mutant pegs: dissonant chord
- [ ] Volume scales with ball velocity (harder hit = louder)

---

### VO-032: Audio: Ambient Layering
**Description:** As a player, I want immersive background music so the atmosphere draws me in.

**Acceptance Criteria:**
- [ ] 3 ambient loop tracks: Zone 1, Zone 2, Zone 3
- [ ] Crossfade between zones
- [ ] Layered: base drone + subtle details
- [ ] Boss music: atonal, builds in complexity with each phase
- [ ] Volume settings in options menu

---

### VO-033: Main Menu + UI Polish
**Description:** As a player, I want a polished menu and UI so the game feels professional.

**Acceptance Criteria:**
- [ ] Main menu: New Run, Continue (if save exists), Stats, Settings, Quit
- [ ] Settings: Audio volume, graphics quality, controls
- [ ] HUD polish: clear fonts, readable numbers, smooth animations
- [ ] Consistent visual language throughout
- [ ] Responsive: works at 1920×1080, 1280×720, mobile resolutions

---

### VO-034: Web Export Test
**Description:** As a player, I want to play in a browser so the game is accessible.

**Acceptance Criteria:**
- [ ] Export to HTML5/WebGL
- [ ] Works in Chrome, Firefox, Safari
- [ ] Works on mobile browsers (iOS Safari, Android Chrome)
- [ ] Loads in under 5 seconds on broadband
- [ ] No console errors on startup
- [ ] Touch controls work on mobile

---

### VO-035: Mobile Touch Input Layer
**Description:** As a mobile player, I want touch controls so I can play on my phone.

**Acceptance Criteria:**
- [ ] Touch to aim (drag from ball spawn point)
- [ ] Release to launch ball
- [ ] Tap nodes on map
- [ ] Tap UI elements (draft selection, shop, etc.)
- [ ] Pinch-to-zoom on map (optional, stretch goal)

---

## Functional Requirements

### FR-1: Shader Polish
- FR-1.1: Replace placeholder ColorRects with Sprite2D + shader materials
- FR-1.2: Peg shader final: gold veins (blessed), neutral stone texture, crimson cracks (cursed), green pustules (mutant), void stars (void)
- FR-1.3: Corruption spread: blur + flow shader on background
- FR-1.4: Ball trail: gradient opacity + color shift
- FR-1.5: Test all shaders in Compatibility renderer
- FR-1.6: Particle effects for peg hits (GPUParticles2D)

### FR-2: Audio System
- FR-2.1: AudioManager subscribes to `peg_hit` signal
- FR-2.2: Per-peg audio: 8 unique tones
- FR-2.3: Dynamic volume: ball.velocity.length() mapped to gain
- FR-2.4: Audio bus setup: master, sfx, music, ambient
- FR-2.5: Load from `res://assets/audio/`

### FR-3: Ambient Music
- FR-3.1: 3 loopable tracks: zone1.ogg, zone2.ogg, zone3.ogg
- FR-3.2: Zone transition triggers crossfade
- FR-3.3: Boss track layers additional elements per phase
- FR-3.4: Settings persist in `user://void_oracle/settings.json`

### FR-4: UI Polish
- FR-4.1: Main menu scene with all buttons
- FR-4.2. Continue button hidden if no save exists
- FR-4.3: Settings panel: sliders for volume, toggle for fullscreen
- FR-4.4: HUD: stability bar, gold, void essence, drop counter
- FR-4.5: Typography: clear, readable fonts at all sizes

### FR-5: Web Export
- FR-5.1: Export template: Web
- FR-5.2: Renderer: Compatibility (WebGL2)
- FR-5.3: Test on itch.io (private test link)
- FR-5.4: Performance: 60 FPS on mid-range devices
- FR-5.5: Memory: no leaks over 30+ minute session

### FR-6: Mobile Touch
- FR-6.1: Input handling: Touch → aim direction
- FR-6.2: Gesture support for tap, drag
- FR-6.3: Responsive UI scales to screen size
- FR-6.4: Test on iOS Safari, Android Chrome

---

## Non-Goals

- No Steam achievements (Milestone 8)
- No additional content (beyond what's in Zone 1-3)
- No save cloud sync
- No multiplayer

---

## Technical Considerations

### EventBus Integration
No new signals — polish phase focuses on implementation quality:
- AudioManager already subscribes to peg_hit
- Settings already defined in tech spec

### Performance Targets
- Web: 60 FPS on integrated graphics
- Mobile: 30+ FPS on mid-range phone (iPhone 11, Pixel 4 equivalent)
- Memory: < 512MB total

### Asset Requirements
- Audio: 8 peg tones + 3 zone tracks + boss track + UI sounds
- Sprites: 8 peg types × 4 states = 32 sprites (or shader-driven)
- Fonts: Game font (TTF)

---

## Open Questions

- Audio tone synthesis — will these be generated or recorded samples?
- Particle effects — GPUParticles2D or sprites? GPU is better for performance
- Font licensing — use open-source font or Godot default?

---

## Related Tickets

- **Depends on:** Milestone 6 (all content complete)
- **Blocks:** Milestone 8 (Steam launch)

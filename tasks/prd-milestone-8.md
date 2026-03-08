# PRD: Milestone 8 — Steam

## Introduction

Milestone 8 brings Void Oracle to Steam: Windows and macOS builds, SteamWorks integration for achievements, and all platform-specific optimizations for a quality desktop release.

**Goal:** Ship on Steam. Achievements work. Desktop players can play.

---

## Goals

- [ ] Windows + macOS builds
- [ ] GodotSteam Integration (achievements)
- [ ] Steam Page Assets

---

## User Stories

### VO-036: Windows + macOS Builds
**Description:** As a player, I want to buy and play on Steam so I can access the game from my library.

**Acceptance Criteria:**
- [ ] Export to Windows (exe)
- [ ] Export to macOS (app bundle)
- [ ] Both builds launch without errors
- [ ] Both builds run at 60 FPS
- [ ] Save files work correctly on both platforms
- [ ] Tested on Windows 10/11 and macOS 12+

---

### VO-037: GodotSteam Integration
**Description:** As a player, I want achievements so my progress is recognized.

**Acceptance Criteria:**
- [ ] Install GodotSteam plugin
- [ ] Implement achievements:
  - "First Blood" — Win first combat
  - "Mutant" — Get a peg to mutate
  - "Synergy!" — Activate first synergy
  - "Ghost Hunter" — Defeat a ghost board
  - "The Gardener" — Defeat Zone 1 boss
  - "Architect" — Defeat Zone 2 boss
  - "Oracle" — Complete the game
  - "Collector" — Own all peg types
  - "Master" — Win on hardest difficulty
- [ ] Achievements unlock correctly
- [ ] Cloud save support (optional stretch goal)

---

### VO-038: Steam Page Assets
**Description:** As a player, I want to see the game on Steam so I can wishlist and buy it.

**Acceptance Criteria:**
- [ ] Create Steam store page
- [ ] Header capsule image
- [ ] Library capsule image (main 600×900)
- [ ] Background/hero image
- [ ] Screenshots (5-10)
- [ ] Trailer video (optional)
- [ ] Write store description
- [ ] Set pricing ($14.99 USD recommended)
- [ ] Configure tags

---

## Functional Requirements

### FR-1: Desktop Builds
- FR-1.1: Export templates: Windows (x86_64), macOS (Universal)
- FR-1.2: Renderer: Compatibility (works on more hardware)
- FR-1.3: Windowed and fullscreen modes
- FR-1.4: Save location: platform-appropriate (AppData on Windows, ~/Library on macOS)
- FR-1.5: Test: launch, new run, save, quit, reload — saves persist
- FR-1.6: Test: no crashes over 1 hour session

### FR-2: Steam Integration
- FR-2.1: GodotSteam plugin integrated via Godot Asset Library
- FR-2.2: Steam App ID obtained (placeholder or real)
- FR-2.3: Achievements implemented via Steamworks API
- FR-2.4: Achievement unlock calls placed in correct game moments
- FR-2.5: Cloud saves (stretch): use Steam Cloud for save sync

### FR-3: Steam Store
- FR-3.1: Store page created in Steam Partner Portal
- FR-3.2: Assets prepared:
  | Asset | Size | Purpose |
  |-------|------|---------|
  | header | 460×215 | Store page header |
  | library_600 | 600×900 | Library hero |
  | library_900 | 900×600 | Library hero alt |
  | capsule | 1200×1600 | Main capsule |
  | screenshot | 1920×1080 | In-game capture |
  | background | 1920×620 | Page background |
- FR-3.3: Screenshots: 5-10 diverse captures
- FR-3.4: Description: 300-500 words, highlights unique mechanics
- FR-3.5. Tags: roguelike, physics, pachinko, indie

---

## Non-Goals

- No Linux build (stretch goal for after launch)
- No controller support (keyboard/mouse only for v1)
- No trading cards (post-launch)
- No DRM beyond Steam

---

## Technical Considerations

### GodotSteam Setup
- Download from Steamworks SDK or Godot Asset Library
- Requires Steamworks.dll (Windows) / libsteam_api.so (Linux) / libsteam_api.dylib (macOS)
- GodotSteam provides: achievements, leaderboards, cloud, overlay

### Build Configuration
- Export presets: Windows, macOS
- Code signing: Windows (optional), macOS (required for notarization)
- Version: 1.0.0

### Performance Targets
- Desktop: 60 FPS, < 1GB RAM
- GPU: works on GTX 1060 / RX 580 equivalent and above

---

## Open Questions

- Steam App ID — use placeholder or apply now?
- Pricing — $14.99 USD is spec recommendation. Confirm or adjust?
- macOS notarization — requires Apple Developer account. Is one available?
- Linux — add to scope or defer?

---

## Related Tickets

- **Depends on:** Milestone 7 (web launch complete)
- **Blocks:** None — this is the final milestone!

---

## Milestone Summary

With Milestone 8 complete, Void Oracle is fully released:

| Platform | Status |
|----------|--------|
| Web (itch.io) | ✅ Milestone 7 |
| Windows (Steam) | ✅ Milestone 8 |
| macOS (Steam) | ✅ Milestone 8 |
| Linux | ❌ Deferred |
| Mobile | ❌ Deferred |

The game is feature-complete and available to players on primary platforms.

# Godot GUT Testing Spec
## Test-Driven Development & Functional Testing with GUT (Godot 4)

---

## 1. Overview

This document defines the conventions, structure, and patterns for using [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) to drive TDD and functional testing across the entire project. GUT 9.x is required for Godot 4.x.

**Goals:**
- Define a test-first development workflow
- Cover as many game systems as possible with automated tests
- Support running tests in-editor, from the command line, and in CI/CD pipelines

---

## 2. Installation & Setup

### 2.1 Install via AssetLib

1. Open the Godot editor and click **AssetLib** at the top center.
2. Search for `GUT - Godot Unit Testing (Godot 4)`.
3. Download and install. GUT installs into `res://addons/gut/`.
4. Enable the plugin: **Project → Project Settings → Plugins → GUT → Enable**.
5. Restart Godot.

### 2.2 Directory Structure

```
res://
├── addons/
│   └── gut/
├── src/                  # Production source code
│   ├── player/
│   ├── enemy/
│   ├── items/
│   └── ui/
└── test/
    ├── unit/             # Pure logic tests, no scene tree
    │   ├── test_player_stats.gd
    │   ├── test_inventory.gd
    │   └── test_damage_calculator.gd
    ├── integration/      # Tests that involve scenes or multiple systems
    │   ├── test_player_scene.gd
    │   ├── test_combat_system.gd
    │   └── test_ui_hud.gd
    └── .gutconfig.json
```

### 2.3 GUT Config File

Create `res://test/.gutconfig.json`:

```json
{
  "dirs": ["res://test/unit", "res://test/integration"],
  "prefix": "test_",
  "suffix": ".gd",
  "selected": "",
  "log_level": 1,
  "ignore_pause": false,
  "exit_on_success": true
}
```

### 2.4 Running Tests

| Method | Command / Action |
|---|---|
| **In-Editor** | GUT panel → Run All |
| **Single file** | GUT panel → select file → Run |
| **Command Line** | `godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://test/.gutconfig.json` |
| **VSCode** | Install `gut-extension`, run tests from the sidebar |

---

## 3. TDD Workflow

Follow the **Red → Green → Refactor** cycle for every new feature or bug fix:

```
1. RED    — Write a failing test that describes the desired behavior
2. GREEN  — Write the minimum production code to make it pass
3. REFACTOR — Clean up both test and production code; re-run to confirm green
```

### 3.1 Example TDD Cycle

**Step 1 — Write the failing test first:**

```gdscript
# test/unit/test_player_stats.gd
extends GutTest

func test_player_starts_with_full_health():
    var stats = PlayerStats.new()
    assert_eq(stats.current_health, stats.max_health, "Health should be full on init")
```

**Step 2 — Run it. It fails (PlayerStats doesn't exist yet). Now implement:**

```gdscript
# src/player/player_stats.gd
class_name PlayerStats
extends Resource

@export var max_health: int = 100
var current_health: int

func _init() -> void:
    current_health = max_health
```

**Step 3 — Run again. Green. Refactor if needed.**

---

## 4. Test File Conventions

### 4.1 Naming

- Test files must start with `test_` (e.g., `test_inventory.gd`)
- Test functions must start with `test_` (e.g., `func test_item_stacks_correctly()`)
- Inner test classes must start with `Test` (e.g., `class TestEquipping`)
- Name tests as full sentences: `test_player_dies_when_health_reaches_zero`

### 4.2 File Template

```gdscript
extends GutTest

# --- Setup / Teardown ---

func before_each() -> void:
    pass  # Runs before every test in this file

func after_each() -> void:
    pass  # Runs after every test (cleanup)

func before_all() -> void:
    pass  # Runs once before all tests in this file

func after_all() -> void:
    pass  # Runs once after all tests in this file

# --- Tests ---

func test_example() -> void:
    assert_true(true, "Sanity check")
```

### 4.3 Inner Classes for Grouping

```gdscript
extends GutTest

class TestTakeDamage:
    extends GutTest

    func test_reduces_health_by_damage_amount():
        var stats = PlayerStats.new()
        stats.take_damage(10)
        assert_eq(stats.current_health, 90)

    func test_health_cannot_go_below_zero():
        var stats = PlayerStats.new()
        stats.take_damage(999)
        assert_gte(stats.current_health, 0)

class TestHealing:
    extends GutTest

    func test_heal_increases_health():
        var stats = PlayerStats.new()
        stats.take_damage(50)
        stats.heal(20)
        assert_eq(stats.current_health, 70)
```

---

## 5. Assertion Reference

### 5.1 Common Assertions

| Assertion | Description |
|---|---|
| `assert_eq(a, b, msg)` | `a == b` |
| `assert_ne(a, b, msg)` | `a != b` |
| `assert_true(val, msg)` | `val` is truthy |
| `assert_false(val, msg)` | `val` is falsy |
| `assert_gt(a, b, msg)` | `a > b` |
| `assert_gte(a, b, msg)` | `a >= b` |
| `assert_lt(a, b, msg)` | `a < b` |
| `assert_lte(a, b, msg)` | `a <= b` |
| `assert_null(val, msg)` | `val` is null |
| `assert_not_null(val, msg)` | `val` is not null |
| `assert_has(collection, val, msg)` | collection contains val |
| `assert_does_not_have(collection, val, msg)` | collection does not contain val |
| `assert_string_contains(str, sub, msg)` | string contains substring |
| `assert_no_new_orphans()` | No nodes were leaked |
| `pending("reason")` | Mark test as pending / not yet implemented |

---

## 6. Memory Management

### 6.1 Rules

- `RefCounted` / `Resource` subclasses: just call `.new()`, no cleanup needed.
- `Node` subclasses: **must** use `add_child_autofree()` or `autofree()` to avoid orphans.
- Always call `assert_no_new_orphans()` at the end of tests that create nodes.

```gdscript
func test_player_node_no_leaks():
    var player = add_child_autofree(preload("res://src/player/player.tscn").instantiate())
    player.take_damage(10)
    assert_eq(player.health, 90)
    assert_no_new_orphans()
```

---

## 7. Signal Testing

Godot's signal system is a first-class testing target in GUT.

```gdscript
func test_player_emits_died_signal_on_lethal_damage():
    var player = Player.new()
    add_child_autofree(player)

    watch_signals(player)           # Start watching before triggering
    player.take_damage(999)

    assert_signal_emitted(player, "died")

func test_score_signal_carries_correct_value():
    var scorer = Scorer.new()
    add_child_autofree(scorer)

    watch_signals(scorer)
    scorer.add_points(50)

    # Parameters must be passed as an array
    assert_signal_emitted_with_parameters(scorer, "score_changed", [50])

func test_signal_not_emitted_when_invincible():
    var player = Player.new()
    add_child_autofree(player)
    player.is_invincible = true

    watch_signals(player)
    player.take_damage(999)

    assert_signal_not_emitted(player, "died")
```

---

## 8. Doubles, Stubs & Spies

Use doubles to isolate the system under test from its dependencies.

### 8.1 Full Double

All methods do nothing and return null unless stubbed.

```gdscript
func test_combat_calls_enemy_take_damage():
    var enemy = double(Enemy).new()
    add_child_autofree(enemy)

    var combat = CombatSystem.new()
    combat.attack(enemy, 25)

    assert_called(enemy, "take_damage")
    assert_called(enemy, "take_damage", [25])   # With specific params
```

### 8.2 Partial Double

Calls real methods unless stubbed.

```gdscript
func test_ai_uses_real_pathfinding_but_mocked_distance():
    var enemy = partial_double(Enemy).new()
    add_child_autofree(enemy)

    stub(enemy, "get_distance_to_player").to_return(5.0)
    enemy.update_ai(0.1)

    assert_called(enemy, "attack_player")
```

### 8.3 Stubbing

```gdscript
# Return a fixed value
stub(my_double, "get_gold").to_return(500)

# Return different values based on arguments
stub(my_double, "get_damage").to_return(10).when_passed("sword")
stub(my_double, "get_damage").to_return(5).when_passed("dagger")

# Call the real implementation
stub(my_double, "calculate_path").to_call_super()

# Do nothing (silence a void method)
stub(my_double, "play_sound").to_do_nothing()
```

### 8.4 Spy Assertions

```gdscript
assert_called(my_double, "method_name")
assert_not_called(my_double, "method_name")
assert_call_count(my_double, "method_name", 3)

# Get parameters from the last call
var params = get_call_parameters(my_double, "method_name")

# Get parameters from the Nth call (1-indexed)
var first_call_params = get_call_parameters(my_double, "method_name", 1)
```

### 8.5 Doubling Scenes

```gdscript
func test_doubled_scene():
    var DoubledPlayer = double(preload("res://src/player/player.tscn"))
    var player = DoubledPlayer.instantiate()
    add_child_autofree(player)

    stub(player, "get_attack_power").to_return(99)
    assert_eq(player.get_attack_power(), 99)
```

---

## 9. Scene & Integration Tests

Integration tests load real scenes and exercise them as they would run in-game.

```gdscript
# test/integration/test_player_scene.gd
extends GutTest

var player: Player

func before_each():
    player = preload("res://src/player/player.tscn").instantiate()
    add_child_autofree(player)

func test_player_spawns_with_correct_defaults():
    assert_eq(player.health, 100)
    assert_eq(player.gold, 0)
    assert_false(player.is_dead)

func test_player_can_pick_up_item():
    var item = preload("res://src/items/health_potion.tscn").instantiate()
    add_child_autofree(item)
    player.pick_up(item)
    assert_has(player.inventory.items, item)
```

---

## 10. Async & Frame-Based Testing

Use `await` helpers for tests that depend on signals firing asynchronously or on physics/process ticks.

```gdscript
func test_animation_finished_signal():
    var player = add_child_autofree(preload("res://src/player/player.tscn").instantiate())
    player.play_death_animation()

    # Wait up to 3 seconds for signal — fails if it never arrives
    await wait_for_signal(player.animation_finished, 3)
    assert_true(player.is_dead)

func test_enemy_moves_after_two_frames():
    var enemy = add_child_autofree(preload("res://src/enemy/enemy.tscn").instantiate())
    var start_pos = enemy.position

    # Wait at least 2 frames (1 frame can be flaky)
    await wait_frames(2)
    assert_ne(enemy.position, start_pos)
```

---

## 11. Parameterized Tests

Run the same test logic over multiple input sets.

```gdscript
extends GutTest

var test_params = [
    [10,  5,  5],   # damage, armor, expected net damage
    [10,  10, 0],
    [5,   10, 0],   # armor exceeds damage, result floored at 0
    [100, 25, 75],
]

func test_net_damage_after_armor(damage: int, armor: int, expected: int):
    var calc = DamageCalculator.new()
    var result = calc.calculate(damage, armor)
    assert_eq(result, expected, "damage=%d armor=%d" % [damage, armor])
```

---

## 12. What to Test — Coverage Plan

### 12.1 Unit Tests (no scene tree)

| System | What to Test |
|---|---|
| **PlayerStats** | Initial values, `take_damage`, `heal`, clamp to min/max, death condition |
| **Inventory** | Add/remove items, stack limits, item-not-found, full inventory rejection |
| **DamageCalculator** | Armor reduction, critical hits, damage type resistances, floor/ceil edge cases |
| **LootTable** | Correct probability distribution, handles empty table, correct item type returned |
| **SaveData** | Serialization/deserialization, missing fields default correctly |
| **QuestSystem** | Quest activation, objective progress, completion trigger, reward grant |
| **StateMachine** | State transitions, guards prevent invalid transitions, on_enter/on_exit fire |
| **Pathfinder / Grid** | Shortest path found, blocked tile is avoided, no-path returns empty |

### 12.2 Integration Tests (with scene tree)

| System | What to Test |
|---|---|
| **Player Scene** | Correct initial state, input leads to movement, death scene shows |
| **Combat** | Attack lands, damage applied, death signal fired, corpse spawned |
| **Enemy AI** | Idle → alert → chase → attack transitions, returns to idle out of range |
| **UI / HUD** | Health bar updates on damage, item icon appears on pickup |
| **Items** | Pickup adds to inventory, consumable applies effect, equipment changes stats |
| **Level / World** | Scene loads without errors, spawn points present, exits connected |

### 12.3 Signal Coverage Checklist

Every custom signal in the project should have at least one test verifying it:
- Fires when expected
- Does **not** fire when conditions are not met
- Carries the correct parameters (where applicable)

---

## 13. What Cannot Be Fully Automated

Some areas require manual or visual validation:

| Area | Reason | Mitigation |
|---|---|---|
| Rendering / VFX | No visual diff tool built in | Manual QA checklist |
| Audio | Cannot assert sound quality | Manual QA checklist |
| Controller/input feel | Subjective, timing-sensitive | Playtest sessions |
| Physics jitter | Non-deterministic at runtime | Smoke test scenes |
| Multiplayer sync | Requires network simulation | Dedicated integration harness |

---

## 14. CI/CD Integration

Run tests headlessly in a pipeline (GitHub Actions example):

```yaml
# .github/workflows/test.yml
name: Run GUT Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download Godot
        run: |
          wget -q https://github.com/godotengine/godot/releases/download/4.x.x-stable/Godot_v4.x.x-stable_linux.x86_64.zip
          unzip Godot*.zip -d godot_bin

      - name: Run GUT Tests
        run: |
          ./godot_bin/Godot_v4.x.x-stable_linux.x86_64 \
            --headless \
            -s addons/gut/gut_cmdln.gd \
            -gconfig=res://test/.gutconfig.json \
            -gexit_on_success

      - name: Upload JUnit Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: res://test/results.xml
```

To export JUnit XML add `-gjunit_xml_file=res://test/results.xml` to the GUT command line call.

---

## 15. Quick Reference Cheat Sheet

```gdscript
# Lifecycle
func before_all()   # Once before all tests in file
func before_each()  # Before each test
func after_each()   # After each test
func after_all()    # Once after all tests in file

# Memory
autofree(obj)                      # Free after test
add_child_autofree(node)           # Add to tree + free after test
assert_no_new_orphans()            # Verify no leaks

# Signals
watch_signals(obj)
assert_signal_emitted(obj, "signal_name")
assert_signal_emitted_with_parameters(obj, "signal_name", [param1, param2])
assert_signal_not_emitted(obj, "signal_name")

# Doubles
double(MyClass).new()
partial_double(MyClass).new()
double(preload("res://scene.tscn")).instantiate()

# Stubs
stub(obj, "method").to_return(value)
stub(obj, "method").to_return(value).when_passed(arg)
stub(obj, "method").to_call_super()
stub(obj, "method").to_do_nothing()

# Spies
assert_called(obj, "method")
assert_called(obj, "method", [args])
assert_not_called(obj, "method")
assert_call_count(obj, "method", N)
get_call_parameters(obj, "method")

# Async
await wait_for_signal(obj.signal_name, timeout_seconds)
await wait_frames(N)   # Minimum 2 for reliability

# Meta
pending("not implemented yet")
```

# Void Oracle QA Requirements

> **Version**: 1.0
> **Created**: 2026-03-16
> **Author**: Godot QA Expert
> **Scope**: test/, data/, scripts/autoloads/

---

## 1. Executive Summary

This document defines quality assurance requirements for the Void Oracle game. It establishes test coverage targets, performance benchmarks, acceptance criteria, and risk-prioritized testing strategy for a physics-driven roguelike pachinko game built in Godot 4.6.

**Current Testing Baseline**: Minimal. One sanity test (`test_sanity.gd`) verifies GUT framework is functional. No unit tests for business logic, no integration tests, no performance benchmarks.

---

## 2. Test Coverage Targets

### 2.1 Coverage Goals by Module

| Module | Target Coverage | Priority |
|--------|-----------------|----------|
| **Autoloads** | 90% | Critical |
| **Data Loading/Validation** | 100% | Critical |
| **Peg Logic** | 80% | High |
| **Synergy System** | 85% | High |
| **Enemy Behaviors** | 70% | Medium |
| **Board/Physics** | 60% | Medium |
| **UI Systems** | 50% | Low |

### 2.2 Coverage Type Distribution

- **Unit Tests**: 70% of test code — test individual functions, classes, and data transformations in isolation
- **Integration Tests**: 25% of test code — test interactions between autoloads, data loading, and signal flows
- **E2E Tests**: 5% of test code — critical paths only (new run → first drop → first enemy defeat)

### 2.3 Minimum Thresholds

- **Autoload functions tested**: All public methods must have at least one test
- **Data validation**: Every JSON key must be validated on load
- **Signal paths**: Every EventBus signal must have at least one test verifying emission and handling
- **Edge cases**: Invalid JSON, missing files, boundary values (stability 0, gold negative, etc.)

---

## 3. Quality Metrics

### 3.1 Test Suite Pass Criteria

| Metric | Requirement |
|--------|-------------|
| **Pass Rate** | 100% of tests must pass |
| **Code Coverage** | Minimum 70% line coverage across all modules |
| **Execution Time** | Full suite completes in < 30 seconds |
| **Flakiness** | Zero flaky tests — same code must produce same result every run |
| **Isolation** | Each test must be independent — no shared state between tests |

### 3.2 Test Health Indicators

- **Tests per module**:
  - RunState: 15+ tests
  - MutationEngine: 12+ tests
  - SynergyChecker: 12+ tests
  - GhostBoardManager: 8+ tests
  - MetaState: 8+ tests
  - EventBus: 10+ tests (signal verification)
  - BasePeg: 15+ tests

- **Test naming**: Must describe behavior, not implementation
  - ✅ `test_should_emit_stability_changed_when_stability_goes_negative`
  - ❌ `test_stability_changed_signal`

### 3.3 Reporting Requirements

Generate on every test run:
1. **JUnit XML** — for CI integration (`test/results/junit.xml`)
2. **Coverage HTML** — visual report (`test/results/coverage/index.html`)
3. **Console summary** — pass/fail counts, execution time

---

## 4. Performance Benchmarks

### 4.1 Physics Performance

| Metric | Target | Tolerance |
|--------|--------|-----------|
| **Physics FPS** | 120 FPS stable | Min 110 FPS under load |
| **Ball tunneling** | Zero instances | Per 1000 drops |
| **Collision accuracy** | 100% | No missed contacts |

### 4.2 Game Logic Performance

| Metric | Target |
|--------|--------|
| **Synergy evaluation** | < 1ms per recalculation |
| **Peg mutation check** | < 0.5ms per hit |
| **Board state snapshot** | < 5ms |
| **Ghost save/load** | < 50ms |

### 4.3 Test Execution Performance

| Metric | Target |
|--------|--------|
| **Unit test execution** | < 500ms per test |
| **Integration test execution** | < 2000ms per test |
| **Full suite** | < 30 seconds |
| **Memory footprint** | < 200MB during test run |

---

## 5. Acceptance Criteria

### 5.1 Functional Acceptance

| ID | Criterion | Validation Method |
|----|-----------|-------------------|
| AC-1 | RunState.new_run() initializes all fields correctly | Unit test |
| AC-2 | RunState.modify_stability() clamps to 0-max and emits signal | Unit test |
| AC-3 | RunState.snapshot_board() returns valid JSON-serializable dict | Unit test |
| AC-4 | EventBus.peg_hit emits with correct node references | Integration test |
| AC-5 | EventBus.run_ended emits with cause and board state | Integration test |
| AC-6 | SynergyChecker.recount_from_board() calculates correct tag counts | Unit test |
| AC-7 | SynergyChecker._evaluate_all() activates synergies at threshold | Unit test |
| AC-8 | MutationEngine._try_mutate() changes peg state correctly | Unit test |
| AC-9 | GhostBoardManager.save_ghost() writes valid JSON to disk | Integration test |
| AC-10 | GhostBoardManager.load_ghost() returns stored data correctly | Integration test |
| AC-11 | MetaState.save_game() persists and load_game() restores state | Integration test |
| AC-12 | All 8 peg types load physics values from JSON | Unit test |
| AC-13 | All 5 synergy definitions parse correctly from JSON | Unit test |
| AC-14 | All 8 enemy definitions parse correctly from JSON | Unit test |

### 5.2 Data Validation Acceptance

| ID | Criterion | Validation Method |
|----|-----------|-------------------|
| DV-1 | peg_definitions.json loads without errors | Startup test |
| DV-2 | synergy_definitions.json loads without errors | Startup test |
| DV-3 | All enemy JSON files load without errors | Startup test |
| DV-4 | Missing required keys in JSON produce error | Edge case test |
| DV-5 | Invalid values (negative friction, >1 restitution) produce error | Edge case test |
| DV-6 | Unknown peg types gracefully handled | Edge case test |

### 5.3 Error Handling Acceptance

| ID | Criterion | Validation Method |
|----|-----------|-------------------|
| EH-1 | FileAccess.open failure logs push_error, returns safely | Unit test |
| EH-2 | JSON.parse failure logs push_error, returns default data | Unit test |
| EH-3 | Invalid board state snapshot returns empty dict, no crash | Edge case test |
| EH-4 | Null node references in signals handled gracefully | Integration test |
| EH-5 | Division by zero in physics calculations prevented | Edge case test |

---

## 6. Risk Areas — Priority Testing

### 6.1 Critical Risk (Must Test First)

| Risk | Impact | Mitigation |
|------|--------|------------|
| **RunState data corruption** | Game state loss, run-ending | Test all modifiers, verify signal emission |
| **Synergy calculation errors** | Wrong bonuses applied, broken gameplay | Test all 5 synergies with varied tag counts |
| **Peg mutation logic bugs** | Unexpected board states | Test state machine transitions thoroughly |
| **Ghost board save/load corruption** | Lost progress, data loss | Test malformed JSON, file permissions |

### 6.2 High Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **EventBus signal disconnection** | Systems stop communicating | Test all signal connections in autoloads |
| **Physics material misapplication** | Balls behave wrong | Test all peg types load correct values |
| **Stability calculation errors** | Incorrect game over triggers | Test boundary conditions (0, negative, max) |

### 6.3 Medium Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **JSON schema mismatches** | Runtime errors | Validate all data files on load |
| **Enemy definitions missing** | Encounter failures | Test all enemy JSON integrity |
| **MetaState version conflicts** | Save file incompatibility | Test version migration paths |

### 6.4 Low Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Shader parameter errors** | Visual glitches | Test shader uniform setting |
| **Audio playback failures** | Missing sound effects | Test AudioManager API |

---

## 7. Test Execution Requirements

### 7.1 Environment

- **Godot Version**: 4.6 (matching project)
- **Renderer**: GL Compatibility (headless for testing)
- **Test Framework**: GUT (Godot Unit Tester)
- **Execution Mode**: `--headless` via command line

### 7.2 Dependencies

No external test dependencies beyond GUT. All mocks/spies implemented via GUT's built-in double system.

### 7.3 CI Integration

```bash
# Run tests in headless mode
godot --headless --script test/runner.gd

# Generate reports
# - JUnit XML: test/results/junit.xml
# - Coverage: test/results/coverage/
```

### 7.4 Test Organization

```
test/
├── unit/
│   ├── test_run_state.gd
│   ├── test_mutation_engine.gd
│   ├── test_synergy_checker.gd
│   ├── test_ghost_board_manager.gd
│   ├── test_meta_state.gd
│   ├── test_event_bus.gd
│   ├── test_peg_base.gd
│   ├── test_data_validation.gd
│   └── test_sanity.gd
├── integration/
│   ├── test_autoload_signal_flow.gd
│   ├── test_ghost_save_load.gd
│   ├── test_run_lifecycle.gd
│   └── test_synergy_activation_flow.gd
└── .gutconfig.json
```

### 7.5 Execution Frequency

| Trigger | Action |
|---------|--------|
| Every commit | Run full test suite |
| Every PR | Run full test suite + coverage report |
| Pre-release | Run full suite + performance benchmarks |
| Manual | Run targeted module tests |

---

## 8. Test Design Guidelines

### 8.1 Naming Convention

```gdscript
# Pattern: test_given_condition_then_expected_behavior
func test_given_zero_stability_when_modified_negative_then_clamped_to_zero() -> void:
func test_given_synergy_3_tags_when_evaluate_all_then_activated() -> void:
func test_given_invalid_json_file_when_load_peg_data_then_returns_default() -> void:
```

### 8.2 Test Structure

```gdscript
func test_<behavior>() -> void:
    # Arrange: Set up input conditions
    var input := <specific value>

    # Act: Execute the function under test
    var result = system_under_test.method(input)

    # Assert: Verify expected outcome
    assert_eq(result, expected_value, "description of expectation")
```

### 8.3 Test Isolation Rules

1. **Never modify global state** — use `add_child`/`remove_child` for scene tests
2. **Never rely on execution order** — each test must set up its own data
3. **Never use real files** — mock FileAccess for I/O tests
4. **Never use real signals** — verify signal emission without connecting

### 8.4 Mocking Strategy

| Dependency | Mock Strategy |
|------------|----------------|
| `FileAccess` | Create in-memory mock, inject via subclass |
| `EventBus` | Use GUT's `replace_node()` to swap with mock |
| `JSON` | Provide pre-parsed data directly |
| `RandomNumberGenerator` | Inject seeded instance for deterministic tests |

---

## 9. Validation Checklist

### 9.1 Data Validation Tests Required

- [ ] All peg types have matching entry in peg_definitions.json
- [ ] All synergy IDs have matching entry in synergy_definitions.json
- [ ] All enemies have JSON files in data/enemies/
- [ ] Peg physics values are within valid ranges (friction 0-1, restitution 0-1)
- [ ] Synergy required_tags reference valid peg tags
- [ ] Enemy tier values are valid (common, uncommon, rare, legendary, boss)

### 9.2 Autoload API Tests Required

| Autoload | Methods to Test |
|----------|-----------------|
| RunState | new_run, modify_stability, modify_gold, snapshot_board |
| MutationEngine | _try_mutate, _next_state, _get_local_corruption |
| SynergyChecker | recount_from_board, _evaluate_all, get_active_synergies |
| GhostBoardManager | save_ghost, load_ghost, count_saved_ghosts, assign_ghost_for_run |
| MetaState | save_game, load_game, get_save_version |
| EventBus | Verify all signals emit with correct parameters |

### 9.3 Edge Case Tests Required

| Scenario | Test Name |
|----------|-----------|
| Stability at 0 | test_stability_zero_prevents_negative |
| Stability at max | test_stability_max_prevents_exceed |
| Gold negative | test_gold_clamped_to_zero |
| Empty board | test_synergy_evaluates_empty_pegs |
| Missing peg type | test_handles_unknown_peg_gracefully |
| Corrupt ghost file | test_load_corrupt_ghost_returns_empty |
| Version mismatch | test_meta_state_handles_old_save_version |

---

## 10. Blockers and Open Questions

### 10.1 Blockers

| Blocker | Resolution Required |
|---------|---------------------|
| **No test runner script** | Need `test/runner.gd` to execute GUT from CLI |
| **No coverage plugin** | Need godot-gut-coverage or alternative for coverage reports |
| **No CI pipeline** | Need GitHub Actions workflow for automated testing |

### 10.2 Open Questions

| Question | Impact |
|----------|--------|
| How to test physics interactions without running full board? | Requires guidance on physics mocking |
| Should enemy AI be unit tested or only integration tested? | May change coverage target |
| What performance metrics are acceptable for web export? | Need to define web-specific benchmarks |

---

## Appendix: Key Files Reference

| File | Purpose |
|------|---------|
| `scripts/autoloads/EventBus.gd` | 64 signals for cross-system communication |
| `scripts/autoloads/RunState.gd` | Run data, modifiers, snapshot |
| `scripts/autoloads/MutationEngine.gd` | Peg state transitions on hit |
| `scripts/autoloads/SynergyChecker.gd` | Tag counting, synergy activation |
| `scripts/autoloads/GhostBoardManager.gd` | Ghost file I/O |
| `scripts/autoloads/MetaState.gd` | Save/load with version migration |
| `data/pegs/peg_definitions.json` | 9 peg types with physics values |
| `data/synergies/synergy_definitions.json` | 5 synergies with tiers |
| `data/enemies/` | 8 enemy type definitions |
| `scripts/game/pegs/BasePeg.gd` | Peg base class, physics setup |
| `test/.gutconfig.json` | GUT framework configuration |

---

*This document is a SPEC DOCUMENT ONLY — no test implementation included.*
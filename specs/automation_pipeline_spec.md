# Void Oracle CI/CD Automation Pipeline Specification

## Overview

This document specifies the automated testing, linting, and export pipeline for the Void Oracle Godot game project. The pipeline uses GitHub Actions to run tests, validate builds, and generate exports for multiple platforms.

---

## 1. Project Analysis Summary

### 1.1 Technology Stack

| Component | Version/Value |
|-----------|---------------|
| Engine | Godot 4.6 |
| Renderer | GL Compatibility (WebGL2) |
| Physics | 120 ticks/sec |
| Testing Framework | GUT (Godot Unit Tester) |
| Languages | GDScript |

### 1.2 Export Targets

| Platform | Preset Name | Export Path | Runnable |
|----------|-------------|--------------|----------|
| Web | Web | `export/web/index.html` | Yes |
| Windows | Windows | `export/windows/void_oracle.exe` | Yes |
| macOS | macOS | `export/macos/Void Oracle.app` | Yes |

### 1.3 Project Structure

```
void-oracle/
├── .godot/                    # Godot engine files
├── addons/gut/                # GUT testing framework
├── data/                      # JSON data files (pegs, enemies, synergies)
│   ├── enemies/
│   ├── pegs/
│   └── synergies/
├── docs/                      # Documentation
├── export/                    # Build output
├── scenes/                    # Godot scenes (.tscn)
├── scripts/                   # GDScript source code
│   ├── autoloads/             # Singleton scripts
│   ├── game/                  # Core game logic
│   │   ├── pegs/              # Peg implementations
│   │   ├── enemies/           # Enemy implementations
│   │   ├── map/               # Map system
│   │   └── systems/           # Game systems
│   └── ui/                    # UI components
├── export_presets.cfg         # Export configuration
└── project.godot              # Project configuration
```

---

## 2. CI/CD Pipeline Design

### 2.1 Trigger Conditions

| Event | Action |
|-------|--------|
| Push to `main` | Run full pipeline (tests + all exports) |
| Push to `feature/*` | Run tests only |
| Pull Request to `main` | Run tests + lint |
| Tag `v*` | Run full pipeline + create release artifacts |
| Manual dispatch | Run selected stages |

### 2.2 Pipeline Stages

```
┌─────────────┐
│   Stage 0   │  Checkout & Setup
│   (0-30s)  │  - Checkout code
│            │  - Setup Godot
│            │  - Cache dependencies
└─────────────┘
       │
       ▼
┌─────────────┐
│   Stage 1   │  Lint & Format Check
│   (30-60s)  │  - Parse GDScript for errors
│            │  - Check for missing imports
└─────────────┘
       │
       ▼
┌─────────────┐
│   Stage 2   │  Unit Tests (GUT)
│   (1-3min)  │  - Run all test suites
│            │  - Generate JUnit XML report
│            │  - Exit code indicates pass/fail
└─────────────┘
       │
       ▼
┌─────────────┐
│   Stage 3   │  Export Verification
│   (5-15min) │  - Export Web (HTML5)
│            │  - Export Windows (.exe)
│            │  - Export macOS (.app)
└─────────────┘
       │
       ▼
┌─────────────┐
│   Stage 4   │  Artifact Upload
│   (30s)    │  - Upload export binaries
│            │  - Create GitHub release (on tags)
└─────────────┘
```

---

## 3. Stage Specifications

### 3.1 Stage 0: Checkout & Setup

**Runtime**: 0-30 seconds

**Steps**:
1. Checkout repository with fetch-depth: 1
2. Download Godot 4.6 headless/server binary
3. Configure export templates
4. Restore cache (optional: Godot templates, dependencies)

**Environment Variables**:
```yaml
GODOT_VERSION: "4.6.1"
GODOT_PLATFORM: "linux"
```

### 3.2 Stage 1: Lint & Format Check

**Runtime**: 30-60 seconds

**Approach**: Use Godot's built-in parsing to detect script errors without running the game.

**Command**:
```bash
godot --headless --script-check .
```

This command parses all GDScript files and reports syntax errors without launching the editor.

**Alternative (if --script-check unavailable)**:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**Failure Criteria**:
- Any script parse error
- Missing resource references

### 3.3 Stage 2: Unit Tests (GUT)

**Runtime**: 1-3 minutes

**Test Discovery**:
- Directory: `res://tests/`
- Prefix: `test_`
- Suffix: `.gd`

**Command**:
```bash
godot --headless \
  -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -gsuffix=.gd \
  -gprefix=test_ \
  -gexit \
  -gjunit_xml_file=results.xml
```

**GUT CLI Options**:
| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| `-gdir` | Test directories | `res://tests` |
| `-gsuffix` | Test file suffix | `.gd` |
| `-gprefix` | Test file prefix | `test_` |
| `-gexit` | Exit after tests | `true` |
| `-glog` | Log level (0-3) | `2` |
| `-gjunit_xml_file` | JUnit output | `results.xml` |
| `-gselect` | Run specific tests | (optional) |
| `-gunit_test_name` | Run tests matching | (optional) |

**Exit Codes**:
- `0`: All tests passed
- `1`: Tests failed
- `2`: GUT error (internal)

**Test Report**:
- JUnit XML format for CI integration
- Console output with test names and assertions

### 3.4 Stage 3: Export Verification

**Runtime**: 5-15 minutes total

#### 3.4.1 Web Export (HTML5)

**Command**:
```bash
godot --headless \
  --export-release "Web" export/web/index.html
```

**Verification**:
- Check `export/web/index.html` exists
- Check `export/web/index.js` exists
- Check file size > 0

#### 3.4.2 Windows Export

**Command**:
```bash
godot --headless \
  --export-release "Windows" export/windows/void_oracle.exe
```

**Verification**:
- Check `export/windows/void_oracle.exe` exists
- Check executable is valid PE file (optional: `file` command)

#### 3.4.3 macOS Export

**Command**:
```bash
godot --headless \
  --export-release "macOS" "export/macos/Void Oracle.app"
```

**Verification**:
- Check `export/macos/Void Oracle.app` exists
- Check `Contents/MacOS/Void Oracle` exists

**Note**: macOS export requires running on macOS runners or using cross-compilation.

### 3.5 Stage 4: Artifact Upload

**Artifacts**:
| Artifact | Path | Retention |
|----------|------|-----------|
| Web Build | `export/web/*` | 90 days |
| Windows Build | `export/windows/void_oracle.exe` | 90 days |
| macOS Build | `export/macos/Void Oracle.app` | 90 days |
| Test Results | `results.xml` | 90 days |

**Upload Action**:
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: void-oracle-web
    path: export/web/
```

---

## 4. GitHub Actions Workflow

### 4.1 Workflow File Structure

Location: `.github/workflows/ci.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, feature/*]
  pull_request:
    branches: [main]
  release:
    tags: ['v*']
  workflow_dispatch:
    inputs:
      stage:
        description: 'Stage to run'
        required: true
        default: 'all'
        type: choice
        options:
          - all
          - tests
          - export

env:
  GODOT_VERSION: "4.6.1"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip
          unzip -o godot.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64
          mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 godot

      - name: Run Script Check
        run: |
          ./godot --headless --script-check .

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Godot
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip
          unzip -o godot.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64
          mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 godot

      - name: Run GUT Tests
        run: |
          ./godot --headless \
            -s addons/gut/gut_cmdln.gd \
            -gdir=res://tests \
            -gsuffix=.gd \
            -gprefix=test_ \
            -gexit \
            -gjunit_xml_file=results.xml

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: results.xml

  export-web:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Godot & Templates
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip
          unzip -o godot.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64
          mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 godot
          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o templates.zip
          unzip -j templates.zip "templates/*" -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable

      - name: Export Web
        run: |
          ./godot --headless --export-release "Web" export/web/index.html

      - name: Verify Web Export
        run: |
          test -f export/web/index.html
          test -f export/web/index.js
          test -s export/web/index.html

      - name: Upload Web Artifact
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: export/web/

  export-windows:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Godot & Templates
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip
          unzip -o godot.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64
          mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 godot
          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o templates.zip
          unzip -j templates.zip "templates/*" -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable

      - name: Export Windows
        run: |
          ./godot --headless --export-release "Windows" export/windows/void_oracle.exe

      - name: Verify Windows Export
        run: |
          test -f export/windows/void_oracle.exe
          test -s export/windows/void_oracle.exe

      - name: Upload Windows Artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: export/windows/void_oracle.exe

  export-macos:
    runs-on: macos-latest
    needs: test
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Godot & Templates
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip" -o godot.zip
          unzip -o godot.zip
          chmod +x Godot_v${GODOT_VERSION}-stable_macos.universal
          mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
          curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o templates.zip
          unzip -j templates.zip "templates/*" -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable

      - name: Export macOS
        run: |
          ./Godot_v${GODOT_VERSION}-stable_macos.universal --headless --export-release "macOS" "export/macos/Void Oracle.app"

      - name: Verify macOS Export
        run: |
          test -d "export/macos/Void Oracle.app"
          test -f "export/macos/Void Oracle.app/Contents/MacOS/Void Oracle"

      - name: Upload macOS Artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: export/macos/Void Oracle.app
```

---

## 5. Test Implementation Guidelines

### 5.1 Test File Structure

Location: `tests/`

```
tests/
├── test_autoloads/
│   └── test_event_bus.gd
├── test_game/
│   ├── test_ball.gd
│   ├── test_pegs/
│   │   ├── test_base_peg.gd
│   │   └── test_stone_peg.gd
│   └── test_systems/
│       └── test_synergy_checker.gd
└── test_utils/
    └── test_math_utils.gd
```

### 5.2 Test Class Template

```gdscript
extends GutTest

var _subject: MyClass


func before_each():
    _subject = MyClass.new()


func after_each():
    _subject.free()


func test_should_return_expected_value():
    var result = _subject.do_something("input")
    assert_eq(result, "expected_output")


func test_should_handle_edge_case():
    var result = _subject.do_something("")
    assert_null(result)
```

### 5.3 Running Specific Tests

```bash
# Run tests in specific directory
./godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/game/pegs -gexit

# Run tests matching name
./godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gunit_test_name="stone_peg" -gexit

# Run specific test script
./godot --headless -s addons/gut/gut_cmdln.gd -gtest="res://tests/game/pegs/test_stone_peg.gd" -gexit
```

---

## 6. Environment Variables & Secrets

### 6.1 Required Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GODOT_VERSION` | Godot engine version | Yes |
| `GITHUB_TOKEN` | GitHub API token | Yes (auto-provided) |

### 6.2 Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GODOT_PLATFORM` | Target platform | linux |
| `EXPORT_TEMPLATES_URL` | Custom templates URL | Official releases |

### 6.3 Secrets (for future use)

| Secret | Description |
|--------|-------------|
| `STEAM_BUILD_PATH` | Path to Steam CLI |
| `ITCHIO_API_KEY` | Itch.io API key for deployment |
| `APPLE_SIGNING_ID` | Apple developer signing identity |

---

## 7. Runtime & Resource Requirements

### 7.1 Job Resource Allocation

| Job | Runner | vCPU | RAM | Time |
|-----|--------|------|-----|------|
| lint | ubuntu-latest | 2 | 4 GB | 1 min |
| test | ubuntu-latest | 2 | 4 GB | 3 min |
| export-web | ubuntu-latest | 2 | 4 GB | 5 min |
| export-windows | ubuntu-latest | 2 | 4 GB | 5 min |
| export-macos | macos-latest | 3 | 6 GB | 8 min |

### 7.2 Total Pipeline Runtime

| Trigger Type | Expected Duration |
|--------------|------------------|
| Push (main) | 15-20 minutes |
| Pull Request | 3-5 minutes |
| Release Tag | 20-25 minutes |
| Manual (tests only) | 3 minutes |

### 7.3 Caching Strategy

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.local/share/godot
      ~/.cache/godot
    key: godot-${{ env.GODOT_VERSION }}-${{ hashFiles('**/*.godot') }}
```

---

## 8. Pre-commit Hooks (Local Development)

### 8.1 Setup

Create `.githooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook for Godot project

echo "Running GDScript lint check..."
godot --headless --script-check .

if [ $? -ne 0 ]; then
    echo "Script check failed"
    exit 1
fi

echo "Running GUT tests..."
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit -glog=2

if [ $? -ne 0 ]; then
    echo "Tests failed"
    exit 1
fi

echo "All checks passed"
exit 0
```

### 8.2 Installation

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

---

## 9. Export Verification Checklist

### 9.1 Web Export

- [ ] `index.html` exists and size > 0
- [ ] `index.js` exists and size > 0
- [ ] `index.wasm` exists (if applicable)
- [ ] No export errors in console

### 9.2 Windows Export

- [ ] `void_oracle.exe` exists and size > 0
- [ ] Valid PE executable format
- [ ] No export errors in console

### 9.3 macOS Export

- [ ] `Void Oracle.app` directory exists
- [ ] `Contents/Info.plist` exists
- [ ] `Contents/MacOS/Void Oracle` exists (executable)
- [ ] No export errors in console

---

## 10. Implementation Notes

### 10.1 Godot Headless Mode

Godot supports headless/server mode via `--headless` flag. This:
- Disables all rendering
- Runs without display server
- Suitable for CI environments
- Still executes all game logic and physics

### 10.2 Export Templates

Export templates must be downloaded separately:
```bash
mkdir -p ~/.local/share/godot/export_templates/4.6.1.stable
curl -fL "https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz" -o templates.zip
unzip -j templates.zip "templates/*" -d ~/.local/share/godot/export_templates/4.6.1.stable
```

### 10.3 GUT Configuration File

Optional: Create `.gutconfig.json` in project root:

```json
{
  "dirs": ["res://tests"],
  "suffix": ".gd",
  "prefix": "test_",
  "log_level": 2,
  "exit_after_run": true,
  "junit_xml_file": "results.xml"
}
```

---

## 11. File Deliverables

| File | Description |
|------|-------------|
| `.github/workflows/ci.yml` | Main CI/CD workflow |
| `.github/workflows/release.yml` | Release workflow (optional) |
| `tests/` | Test directory (create) |
| `.githooks/pre-commit` | Local pre-commit hook |
| `.gutconfig.json` | GUT configuration (optional) |

---

## 12. Confidence Assessment

| Aspect | Confidence |
|--------|------------|
| GUT CLI integration | 95% - Well-documented, tested approach |
| Export commands | 90% - Standard Godot CLI usage |
| GitHub Actions syntax | 95% - Standard workflow syntax |
| Headless execution | 95% - Godot supports --headless |
| Web export | 90% - Requires templates |
| Windows export | 90% - Requires templates |
| macOS export | 85% - Requires macOS runner |

**Overall Confidence**: 90%

### Blockers Identified

1. **macOS Export**: Requires macOS runner - Linux cannot produce macOS builds
2. **Export Templates**: Must be downloaded separately in each job
3. **Script Check**: `--script-check` flag availability in Godot 4.6 needs verification

---

## 13. References

- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Godot Command Line](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_templates.html)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Godot Export](https://docs.godotengine.org/en/stable/tutorials/exporting/index.html)

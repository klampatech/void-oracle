## Build & Run

Succinct rules for how to BUILD the project:

```bash
# Export game (creates standalone build)
./run_debug.sh --export-release <output_path>

# Or run directly in editor
./run_debug.sh
```

## Validation

Run these after implementing to get immediate feedback:

- Tests: Godot has no built-in test runner; run the game and check for runtime errors in output
- Typecheck: GDScript is checked by Godot editor; use editor to see errors
- Lint: Use Godot editor or `gdlint` if installed (`pip install gdlint`)

## Quick Check

To quickly validate scripts compile without running the full game:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/kylelampa/Development/Games/void-oracle --check-only
```

## Run Commands

```bash
# Run with debug logging (recommended for development)
./run_debug.sh

# Run with log tailing (watch logs in real-time)
./run_debug.sh --tail-logs
```

**Note:** Godot must be installed at `/Applications/Godot.app` or update `GODOT` path in `run_debug.sh`.

## Operational Notes

Succinct learnings about how to RUN the project:

- Press F5 in Godot editor to run the current scene
- Use the debug panel to see runtime errors and warnings
- Check `logs/godot_debug_*.log` for detailed output

### Codebase Patterns

...

## Agent Behavior Rules

- **Never ask for user input.** If you have a question, answer it yourself with a recommendation and proceed. Only ask if you genuinely cannot make progress without clarification.

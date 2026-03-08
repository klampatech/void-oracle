# Project Context

**Generated**: 2026-03-07
**Project**: Void Oracle
**Type**: Godot 4 Game

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Renderer**: GL Compatibility (WebGL2)
- **Physics**: 120 ticks/sec
- **Key Dependencies**: Built-in (no external packages)

## Peg Types

| Type | Tier | Tags |
|------|------|------|
| Stone | common | foundation |
| Bone | common | death |
| Fungal | uncommon | growth, death |
| Ember | uncommon | fire |
| Eye | rare | void |
| Heart | rare | - |
| Oracle | legendary | - |
| Void Rift | legendary | void |

## Project Structure

- **Source**: `scenes/` and `scripts/`
- **Data**: `data/pegs/`, `data/synergies/`
- **Config**: `project.godot`

## Development Workflow

- **Open**: Godot 4.6 editor
- **Run**: F5 in editor or export
- **Web Export**: Use GL Compatibility renderer

## AutoLoads

- EventBus (signals only)
- RunState (run data)
- GhostBoardManager (file I/O)
- SynergyChecker (tag counting)
- AudioManager (audio)
- MutationEngine (peg mutations)

## Active Skills

- godot-4-reference - Godot 4.6 patterns and syntax
- void-oracle-best-practices - Project-specific code quality rules

## Notes

- All peg values must come from `data/pegs/peg_definitions.json`
- All cross-system communication via EventBus signals
- Physics must use real RigidBody2D simulation
- Web export must work with GL Compatibility renderer

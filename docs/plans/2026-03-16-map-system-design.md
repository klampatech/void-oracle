# Map System Design — Void Oracle

**Date:** 2026-03-16

## Overview

Implemented the core map system for Void Oracle's run navigation, allowing players to traverse a procedurally generated branching map across 3 zones.

## Implementation Summary

### MapGenerator.gd
- Generates 3-zone DAG with 8-10 nodes per zone
- Node type distribution: Combat(40%), Elite(15%), Event(20%), Shop(10%), Rest(10%)
- Guaranteed nodes per zone: 1 shop, 1 rest, 1 boss (final zone)
- Board-aware weighting: peg tags influence node generation (e.g., "growth" tags → more events)
- Seeded RNG for deterministic runs

### RunMap.gd
- Visual map display with clickable nodes
- Connection lines (Line2D) showing paths between nodes
- Zone labels for navigation clarity
- Path validation (BFS) to ensure reachable nodes are selectable
- Current position tracking with visual indicators

### MapNode.gd
- Color-coded nodes by type (red=combat, purple=elite, blue=event, amber=shop, cyan=rest, orange=boss)
- Selection highlight for reachable nodes
- Visited node dimming

## Key Design Decisions

1. **DAG Structure**: Nodes flow forward only (zone 1 → zone 2 → zone 3), no backtracking
2. **Procedural Generation**: Seed-based for replayability
3. **Board Influence**: RunState tags modify node weights for personalized runs
4. **Visual Clarity**: Color coding + connection lines for intuitive navigation

## Future Work

- P4.3: Navigation Phase - wire into game flow (Board → Map → Board)
- P4.4: Shop System implementation
- P4.5: Additional enemy types (Wrecker, Spawner, Leech)

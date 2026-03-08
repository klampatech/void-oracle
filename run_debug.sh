#!/bin/bash
# Launch Void Oracle with debug logging enabled
# Usage: ./run_debug.sh [--tail-logs]

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

# Create logs directory if it doesn't exist
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

# Generate timestamp for log file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/godot_debug_$TIMESTAMP.log"

# Check if Godot exists
if [ ! -f "$GODOT" ]; then
    echo "Error: Godot not found at $GODOT"
    echo "Please ensure Godot is installed in /Applications/"
    exit 1
fi

echo "=== Void Oracle Debug Launcher ==="
echo "Project: $PROJECT_DIR"
echo "Log file: $LOG_FILE"
echo ""
echo "Starting Godot with debug mode and verbose logging..."
echo "Press Ctrl+C to stop"
echo ""

# Check for --tail-logs flag
if [ "$1" = "--tail-logs" ]; then
    # Run Godot in background and tail logs
    "$GODOT" --path "$PROJECT_DIR" --debug --verbose 2>&1 | tee "$LOG_FILE" &
    GODOT_PID=$!

    echo "Godot started with PID: $GODOT_PID"
    echo "Tailing log output (Ctrl+C to stop Godot)..."
    echo ""

    # Tail the log file
    tail -f "$LOG_FILE"

    # When tail exits, kill Godot
    kill $GODOT_PID 2>/dev/null
else
    # Just run Godot with logging to file (tee for console + file)
    "$GODOT" --path "$PROJECT_DIR" --debug --verbose 2>&1 | tee "$LOG_FILE"
fi

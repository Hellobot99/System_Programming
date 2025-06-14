#!/bin/bash

TARGET="mini-shell-3"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
OUTPUT_DIR="outputs_mini-shell-3"
LOG="${OUTPUT_DIR}/test_fg.log"
SCRIPT_FILE="test_fg_combined.script"

# Cleanup temporary files on exit
cleanup() {
  rm -f "$SCRIPT_FILE"
  pkill sleep
}
trap cleanup EXIT

# 1. Check source
if [[ ! -f "$SRC" ]]; then
  echo "FAIL: Source file '$SRC' not found"
  exit 1
fi

# 2. Compile
if ! gcc -o "$BIN" "$SRC" 2> build_error.log; then
  echo "FAIL: Build failed"
  cat build_error.log
  exit 1
fi
rm -f build_error.log

# 3. Prepare output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Test: fg command
echo "=== Test: fg command ==="

cat <<EOF > "$SCRIPT_FILE"
sleep 20
jobs
sleep 2
fg 1
exit
EOF

$BIN "$SCRIPT_FILE" > "$LOG" 2>&1 &
SHELL_PID=$!
sleep 1

# Get child process
CHILD_PID=$(pgrep -P "$SHELL_PID" | head -n 1)
if [[ -z "$CHILD_PID" ]]; then
  echo "FAIL: No child process found for mini-shell."
  exit 1
fi

# Send SIGTSTP (simulate Ctrl+Z)
kill -TSTP "$SHELL_PID"
sleep 1

STATE=$(ps -o stat= -p "$CHILD_PID" 2>/dev/null)
PROC_STATE=$(grep State /proc/$CHILD_PID/status 2>/dev/null | awk '{print $2}')

if echo "$STATE" | grep -q "^T" || [[ "$PROC_STATE" == "T" ]]; then
  echo "PASS: Process $CHILD_PID is stopped (state: $STATE / $PROC_STATE)"
else
  echo "FAIL: Process $CHILD_PID is not stopped (state: $STATE / $PROC_STATE)"
  exit 1
fi

# Check if fg resumes it
sleep 1
RESUME_STATE=$(ps -o stat= -p "$CHILD_PID" 2>/dev/null)
if [[ "$RESUME_STATE" =~ ^[RS] ]]; then
  echo "PASS: fg resumed stopped job (state: $RESUME_STATE)"
else
  echo "FAIL: fg did not resume properly (state: $RESUME_STATE)"
  exit 1
fi

# Final report
echo ""
echo "SUCCESS: All tests PASS!"

#!/bin/bash

TARGET="mini-shell-2"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
OUTPUT_DIR="outputs_mini-shell-2"
LOG1="${OUTPUT_DIR}/test1_bg.log"
LOG2="${OUTPUT_DIR}/test2_ctrlz.log"
LOG3="${OUTPUT_DIR}/test3_jobs.log"

# Cleanup temporary files on exit
cleanup() {
  rm -f test1.script test2.script test3.script
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

# Test 1: Background execution (5 jobs)
echo "=== Test 1: Background execution ==="
cat <<EOF > test1.script
sleep 11 &
sleep 12 &
sleep 13 &
sleep 14 &
sleep 15 &
sleep 10
EOF

$BIN test1.script > "$LOG1" 2>&1 &
SHELL_PID=$!
sleep 1.5

CHILD_PIDS=($(pgrep -P "$SHELL_PID"))
if [[ ${#CHILD_PIDS[@]} -lt 5 ]]; then
  echo "FAIL: Expected 5+ background processes, found ${#CHILD_PIDS[@]}"
  echo "Found PIDs: ${CHILD_PIDS[*]}"
  exit 1
fi

RUNNING=0
for pid in "${CHILD_PIDS[@]}"; do
  STATE=$(ps -o stat= -p "$pid" 2>/dev/null)
  if [[ "$STATE" =~ ^[RS] ]]; then
    ((RUNNING++))
  fi
done

if [[ $RUNNING -ge 5 ]]; then
  echo "PASS: Background execution works ($RUNNING running processes)"
else
  echo "FAIL: Only $RUNNING background jobs actually running"
  exit 1
fi

# Test 2: Ctrl+Z handling
echo "=== Test 2: Ctrl+Z handling ==="
cat <<EOF > test2.script
sleep 20
EOF

$BIN test2.script > "$LOG2" 2>&1 &
SHELL_PID=$!
sleep 1.5

CHILD_PID=$(pgrep -P "$SHELL_PID" | head -n 1)
if [[ -z "$CHILD_PID" ]]; then
  echo "FAIL: No child process found for mini-shell."
  exit 1
fi

kill -TSTP "$SHELL_PID"
kill -TSTP "$CHILD_PID"
sleep 1

STATE=$(ps -o stat= -p "$CHILD_PID" 2>/dev/null)
PROC_STATE=$(grep State /proc/$CHILD_PID/status 2>/dev/null | awk '{print $2}')

if echo "$STATE" | grep -q "^T" || [[ "$PROC_STATE" == "T" ]]; then
  echo "PASS: Process $CHILD_PID is stopped (state: $STATE)"
else
  echo "FAIL: Process $CHILD_PID is not stopped (state: $STATE)"
  exit 1
fi

# Test 3: jobs output
echo "=== Test 3: jobs output ==="
cat <<EOF > test3.script
sleep 15 &
sleep 16 &
sleep 17 &
sleep 18 &
sleep 19 &
sleep 20
jobs
exit
EOF

$BIN test3.script > "$LOG3" 2>&1 &
JOBS_PID=$!
sleep 1
kill -TSTP "$JOBS_PID"
sleep 1

if grep -q "\[1\] Running" "$LOG3" &&
   grep -q "\[5\] Running" "$LOG3" &&
   grep -q "\[6\] Stopped" "$LOG3"; then
  echo "PASS: jobs command output is correct."
else
  echo "FAIL: jobs command output incorrect."
  cat "$LOG3"
  exit 1
fi

# Final report
echo ""
echo "SUCCESS: All tests PASS!"

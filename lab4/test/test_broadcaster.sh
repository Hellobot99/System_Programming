#!/bin/bash

# Configuration
NUM_TERMINALS=3
LOG_DIR="/tmp/pts_logs"
PTS_INFO="/tmp/pts_info.txt"
BINARY="./broadcaster"
ERROR_LOG="/tmp/broadcast_error.log"

TARGET="broadcaster"
SRC="${TARGET}.c"

# Cleanup function to terminate background processes and remove temp files
cleanup() {
  pkill -f "cat > $LOG_DIR/" 2>/dev/null
  pkill -f "socat" 2>/dev/null
  rm -rf "$LOG_DIR" "$PTS_INFO" /tmp/socat_pty_* "$ERROR_LOG" build_error.log
}

# Exit with cleanup
fail_exit() {
  cleanup
  exit 1
}

# Check if source file exists
if [[ ! -f "$SRC" ]]; then
  echo "FAIL: Source file '$SRC' not found"
  exit 1
fi

# Build the program
if ! gcc -o "$TARGET" "$SRC" 2> build_error.log; then
  echo "FAIL: Build failed"
  cat build_error.log
  fail_exit
fi
rm -f build_error.log

# Clean up any previous runs
cleanup

# Launch socat terminals (quietly)
mkdir -p "$LOG_DIR"
for i in $(seq 1 $NUM_TERMINALS); do
  socat -d -d PTY,raw,echo=0,link="/tmp/socat_pty_$i" SYSTEM:"cat > $LOG_DIR/term_$i.log" > /dev/null 2>&1 &
  sleep 0.5
done

# Wait for PTS devices to appear
sleep 1

# Map PTS devices to log files
for i in $(seq 1 $NUM_TERMINALS); do
  PTS_DEV=$(readlink -f /tmp/socat_pty_$i)
  LOG_FILE="$LOG_DIR/term_$i.log"
  echo "$$ $PTS_DEV $LOG_FILE" >> "$PTS_INFO"
done

################################################################################
# Test Case 1: Basic Broadcast Test
################################################################################
$BINARY "Test message" 2> "$ERROR_LOG"
if [ -s "$ERROR_LOG" ]; then
  echo "FAIL: broadcaster wrote to stderr during TC1"
  cat "$ERROR_LOG"
  fail_exit
fi
sleep 1

while read -r line; do
  TTY=$(echo "$line" | awk '{print $2}')
  LOG_FILE=$(echo "$line" | awk '{print $3}')

  if grep -q "\[Broadcast\] Test message" "$LOG_FILE"; then
    echo "PASS: $TTY received the broadcast message"
  else
    echo "FAIL: $TTY did NOT receive the broadcast message"
    echo "--- Debug Info ---"
    echo "Expected: [Broadcast] Test message"
    echo "Actual:"
    cat "$LOG_FILE"
    echo "------------------"
    fail_exit
  fi
done < "$PTS_INFO"

################################################################################
# Test Case 2: Permission Denied Test
################################################################################
DENIED_PTS=$(tail -n 1 "$PTS_INFO" | awk '{print $2}')
chmod a-w "$DENIED_PTS" 2>/dev/null
$BINARY "Test with permission issue" 2> "$ERROR_LOG"
chmod a+w "$DENIED_PTS" 2>/dev/null
if [ -s "$ERROR_LOG" ]; then
  echo "FAIL: broadcaster wrote to stderr during TC2"
  cat "$ERROR_LOG"
  fail_exit
fi
sleep 1

while read -r line; do
  TTY=$(echo "$line" | awk '{print $2}')
  LOG_FILE=$(echo "$line" | awk '{print $3}')

  if [[ "$TTY" == "$DENIED_PTS" ]]; then
    if grep -q "Test with permission issue" "$LOG_FILE"; then
      echo "FAIL: $TTY received message despite permission denial"
      echo "--- Debug Info ---"
      echo "Expected: no message due to permission denial"
      echo "Actual:"
      cat "$LOG_FILE"
      echo "------------------"
      fail_exit
    else
      echo "PASS: $TTY did not receive message (permission denied as expected)"
    fi
  else
    if grep -q "Test with permission issue" "$LOG_FILE"; then
      echo "PASS: $TTY received the message"
    else
      echo "FAIL: $TTY missed the message"
      echo "--- Debug Info ---"
      echo "Expected: Test with permission issue"
      echo "Actual:"
      cat "$LOG_FILE"
      echo "------------------"
      fail_exit
    fi
  fi
done < "$PTS_INFO"

################################################################################
# Test Case 3: Closed Terminal Test
################################################################################
FIRST_LINE=$(head -n 1 "$PTS_INFO")
CLOSED_PTS=$(echo "$FIRST_LINE" | awk '{print $2}')
LOG_FILE=$(echo "$FIRST_LINE" | awk '{print $3}')
pkill -f "cat > $LOG_FILE"
sleep 1

$BINARY "Test after closing terminal" 2> "$ERROR_LOG"
if [ -s "$ERROR_LOG" ]; then
  echo "FAIL: broadcaster wrote to stderr during TC3"
  cat "$ERROR_LOG"
  fail_exit
fi
sleep 1

while read -r line; do
  TTY=$(echo "$line" | awk '{print $2}')
  LOG_FILE=$(echo "$line" | awk '{print $3}')

  if [[ "$TTY" == "$CLOSED_PTS" ]]; then
    if grep -q "Test after closing terminal" "$LOG_FILE"; then
      echo "FAIL: $TTY received message despite being closed"
      echo "--- Debug Info ---"
      echo "Expected: no message because terminal was closed"
      echo "Actual:"
      cat "$LOG_FILE"
      echo "------------------"
      fail_exit
    else
      echo "PASS: $TTY did not receive message (closed as expected)"
    fi
  else
    if grep -q "Test after closing terminal" "$LOG_FILE"; then
      echo "PASS: $TTY received the message"
    else
      echo "FAIL: $TTY missed the message"
      echo "--- Debug Info ---"
      echo "Expected: Test after closing terminal"
      echo "Actual:"
      cat "$LOG_FILE"
      echo "------------------"
      fail_exit
    fi
  fi
done < "$PTS_INFO"

echo ""
echo "SUCCESS: All tests passed!"
cleanup
exit 0


#!/bin/bash

TARGET="editor"
SRC="./${TARGET}.c"

# Check if source file exists
if [[ ! -f "$SRC" ]]; then
  echo "FAIL: Source file '$SRC' not found"
  exit 1
fi

# Build the program
if ! gcc -o "$TARGET" "$SRC" -lncurses 2> build_error.log; then
  echo "FAIL: Build failed"
  cat build_error.log
  fail_exit
fi
rm -f build_error.log

EXEC="editor"
AUTOSAVE_FILE="autosave.txt"
EXPECTED_FILE="expected_output.txt"

########################################
# Test Case 1: SIGINT (Immediate Save Test)
########################################
echo -e "\n[TEST] SIGINT test - immediate save on Ctrl+C"

rm -f $AUTOSAVE_FILE $EXPECTED_FILE

expect << EOF
log_user 0
spawn ./$EXEC

expect "Enter text"
sleep 1
send "SIGINT Line 1\r"
sleep 1
send "SIGINT Line 2\r"
sleep 1
# Send SIGINT (Ctrl+C) to trigger immediate save
send "\003"
expect eof
EOF

# Prepare expected result
echo -e "SIGINT Line 1\nSIGINT Line 2" > $EXPECTED_FILE

# Compare output
if [ ! -f $AUTOSAVE_FILE ]; then
  echo "FAIL: [SIGINT] autosave.txt was not created."
  exit 1
else
  if diff -q --strip-trailing-cr "$AUTOSAVE_FILE" "$EXPECTED_FILE" > /dev/null; then
    echo "PASS: [SIGINT] autosave.txt content is correct (saved immediately on Ctrl+C)."
  else
    echo "FAIL: [SIGINT] autosave.txt content is incorrect."
    echo "----- Expected -----"
    cat "$EXPECTED_FILE"
    echo "----- Actual -----"
    cat "$AUTOSAVE_FILE"
    exit 1
  fi
fi

########################################
# Test Case 2: SIGALRM (Auto-Save After Timeout Test)
########################################
echo -e "\n[TEST] SIGALRM test - auto-save after 5 seconds"

rm -f $AUTOSAVE_FILE $EXPECTED_FILE

expect << EOF
log_user 0
spawn ./$EXEC

expect "Enter text"
sleep 1
send "SIGALRM Line 1\r"
sleep 1
send "SIGALRM Line 2\r"
# Wait enough time for alarm(5) to trigger auto-save
sleep 6
# Send SIGINT to exit
send "\003"
expect eof
EOF

# Prepare expected result
echo -e "SIGALRM Line 1\nSIGALRM Line 2" > $EXPECTED_FILE

# Compare output
if [ ! -f $AUTOSAVE_FILE ]; then
  echo "FAIL: [SIGALRM] autosave.txt was not created."
  exit 1
else
  if diff -q --strip-trailing-cr "$AUTOSAVE_FILE" "$EXPECTED_FILE" > /dev/null; then
    echo "PASS: [SIGALRM] autosave.txt content is correct (saved automatically after 5 seconds)."
  else
    echo "FAIL: [SIGALRM] autosave.txt content is incorrect."
    echo "----- Expected -----"
    cat "$EXPECTED_FILE"
    echo "----- Actual -----"
    cat "$AUTOSAVE_FILE"
    exit 1
  fi
fi

# Cleanup
rm -f $EXPECTED_FILE

echo ""
echo "SUCCESS: All tests PASS!"

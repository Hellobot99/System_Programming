#!/bin/bash

TARGET="pw_input"
SRC="${TARGET}.c"

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

EXP_SCRIPT="${LAB_HOME}/test/test_pw_input.exp"

expect "$EXP_SCRIPT"
EXIT_CODE=$?

echo ""
echo "-----------------------------------"

if [ $EXIT_CODE -eq 0 ]; then
  echo "SUCCESS: All tests passed!"
else
  echo "FAIL: Some tests failed."
fi

exit $EXIT_CODE

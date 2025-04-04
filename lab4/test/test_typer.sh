#!/bin/bash

TARGET="typer"
SRC="${TARGET}.c"

# Check if source file exists
if [[ ! -f "$SRC" ]]; then
  echo "ERROR: Source file '$SRC' not found."
  exit 1
fi

# Build the program
if ! gcc -o "$TARGET" "$SRC" 2> build_error.log; then
  echo "ERROR: Build failed"
  cat build_error.log
  rm -f build_error.log
  exit 1
fi
rm -f build_error.log

run_test_case() {
  local test_name="$1"
  local target_sentence="$2"
  local user_input="$3"
  local expected_line="$4"

  LOGFILE="test_${test_name// /_}.log"

  # Run the program and capture output
  echo -e "$user_input" \
    | stdbuf -oL "./$TARGET" "$target_sentence" \
    | cat -v \
    > "$LOGFILE"

  # Extract line beginning with "Start typing:"
  typing_line=$(grep -m1 "^Start typing:" "$LOGFILE")

  if [[ "$typing_line" == "$expected_line" ]]; then
    echo "PASS: $test_name"
  else
    echo "FAILED: $test_name"
    echo ""
    echo "Expected:"
    echo "$expected_line"
    echo ""
    echo "Actual:"
    echo "$typing_line"
    echo ""
    echo "--- Diff ---"
    echo "$expected_line" > /tmp/expected.txt
    echo "$typing_line"   > /tmp/actual.txt
    diff -u /tmp/expected.txt /tmp/actual.txt
    echo "-------------"
    cleanup_temp_files
    exit 1
  fi

  rm -f "$LOGFILE"
}

cleanup_temp_files() {
  rm -f /tmp/expected.txt /tmp/actual.txt" test_*.log"
}

# Run the ICANON test
# ${LAB_HOME}/test/test_typer_icanon.exp
# if [ $? -eq 1 ]; then
#   echo "FAIL: ICANON test failed"
#   exit 1
# else
#   echo "PASS: ICANON test passed"
# fi

run_test_case \
  "Perfect input matches target" \
  "Hello World" \
  "Hello World" \
  "Start typing: Hello World"

run_test_case \
  "Input with uncorrected typos" \
  "Hello World" \
  "Hxllo Wxrld" \
  "Start typing: H^[[31mx^[[0mllo W^[[31mx^[[0mrld"

run_test_case \
  "Typo fixed with backspace" \
  "abcd" \
  "$(echo -e 'abx\x08cd')" \
  "Start typing: ab^[[31mx^[[0m^H ^Hcd"

cleanup_temp_files

echo ""
echo "SUCCESS: All tests passed!"

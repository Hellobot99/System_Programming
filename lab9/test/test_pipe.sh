#!/bin/bash

TARGET="pipe"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
OUTPUT_DIR="outputs_${TARGET}"
TEST_INPUT="input_test.txt"
TIMEOUT_SEC=5  # default timeout per test in seconds

# Define test cases
declare -a CMD1_LIST=(
"echo hello world"
"echo hello world"
"echo user:pass:info"
"cat $TEST_INPUT"
)
declare -a CMD2_LIST=(
"grep hello"
"grep test"
"cut -d: -f1"
"sort"
)
declare -a EXPECTED_LIST=(
"hello world"
""
"user"
$'a\nb\nc'
)

# Cleanup temporary files on exit
cleanup() {
  rm -f "$TEST_INPUT"
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT

# 1. Check if source file exists
if [[ ! -f "$SRC" ]]; then
  echo "FAIL: Source file '$SRC' not found"
  exit 1
fi

# 2. Compile the program
echo "Building $SRC..."
if ! gcc -o "$BIN" "$SRC" -O2 2> build_error.log; then
  echo "FAIL: Build failed"
  cat build_error.log
  exit 1
fi
rm -f build_error.log

# 3. Prepare output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 4. Generate input file for test using 'cat | sort'
echo "Generating test input for 'cat | sort'..."
echo -e "c\nb\na" > "$TEST_INPUT"

# 5. Run functional tests
echo ""
echo "=== PIPE FUNCTIONAL TESTS (timeout=${TIMEOUT_SEC}s) ==="
total=${#CMD1_LIST[@]}
pass=0
fail=0

for ((i=0; i<total; i++)); do
  cmd1="${CMD1_LIST[$i]}"
  cmd2="${CMD2_LIST[$i]}"
  expected="${EXPECTED_LIST[$i]}"
  test_name="Test #$((i+1)): \"$cmd1\" | \"$cmd2\""

  echo -n "[TEST] $test_name ... "

  # Run with timeout and capture result
  result=$(timeout "$TIMEOUT_SEC" "$BIN" "$cmd1" "$cmd2" 2>/dev/null)
  exit_code=$?

  # Check for timeout
  if [[ $exit_code -eq 124 ]]; then
    echo "FAIL (timeout after ${TIMEOUT_SEC}s)"
    fail=$((fail + 1))
    continue
  fi

  # Compare output
  if [[ "$result" == "$expected" ]]; then
    echo "PASS"
    pass=$((pass + 1))
  else
    echo "FAIL"
    echo "  Expected: \"$expected\""
    echo "  Got     : \"$result\""
    fail=$((fail + 1))
  fi
done

# 6. Summary
echo ""
echo "=== TEST SUMMARY ==="
echo "PASS: $pass / $total"
echo "FAIL: $fail / $total"
echo ""

if [[ $fail -eq 0 ]]; then
  echo "SUCCESS: All tests PASS!"
  exit 0
else
  echo "FAILURE: Some tests failed."
  exit 1
fi

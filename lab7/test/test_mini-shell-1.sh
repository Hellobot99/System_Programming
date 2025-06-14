#!/bin/bash

TARGET="mini-shell-1"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
OUTPUT_DIR="outputs_mini-shell-1"

# Cleanup temporary test files on exit
cleanup() {
  rm -f test*.script test_input.txt test_output.txt
  pkill sleep
}
trap cleanup EXIT

# 1. Check source file
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

# 3. Prepare output dir
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Run script helper
run_script() {
  local test_name="$1"
  local script_file="$2"
  local log_file="${OUTPUT_DIR}/${test_name}.log"
  ./$BIN "$script_file" > "$log_file" 2>&1
}

# === Test 1: Variable assignment ===
echo "=== Test 1: Variable assignment ==="
cat <<EOF > test1.script
MSG=hello
echo \$MSG
EOF

run_script "test1_var" test1.script
if grep -q "hello" "${OUTPUT_DIR}/test1_var.log"; then
  echo "PASS: Variable expansion works."
else
  echo "FAIL: Variable expansion failed."
  exit 1
fi

# === Test 2: export ===
echo "=== Test 2: export ==="
cat <<EOF > test2.script
export GREETING=hi
echo \$GREETING
EOF

run_script "test2_export" test2.script
if grep -q "hi" "${OUTPUT_DIR}/test2_export.log"; then
  echo "PASS: Export works."
else
  echo "FAIL: Export failed."
  exit 1
fi

# === Test 3: if-then-fi ===
echo "=== Test 3: if-then-fi ==="
cat <<EOF > test3.script
if true
then
echo passed
fi
EOF

run_script "test3_if" test3.script
if grep -q "passed" "${OUTPUT_DIR}/test3_if.log"; then
  echo "PASS: if-then-fi executed."
else
  echo "FAIL: if-then-fi failed."
  exit 1
fi

# === Test 4: Output redirection ===
echo "=== Test 4: Output redirection ==="
cat <<EOF > test4.script
echo HelloRedirection > test_output.txt
EOF

run_script "test4_redirect" test4.script
if grep -q "HelloRedirection" test_output.txt; then
  echo "PASS: Output redirection works."
else
  echo "FAIL: Output redirection failed."
  exit 1
fi

# === Test 5: set ===
echo "=== Test 5: set ==="
cat <<EOF > test5.script
A=foo
export B=bar
set
EOF

run_script "test5_set" test5.script
if grep -q "A=foo" "${OUTPUT_DIR}/test5_set.log" && \
  grep -q "export B=bar" "${OUTPUT_DIR}/test5_set.log"; then
  echo "PASS: set shows variables."
else
  echo "FAIL: set output incorrect."
  exit 1
fi

# === Test 6: Invalid command ===
echo "=== Test 6: Invalid command ==="
cat <<EOF > test6.script
nosuchcommand
EOF

run_script "test6_invalid" test6.script
if grep -q "command not found" "${OUTPUT_DIR}/test6_invalid.log"; then
  echo "PASS: Invalid command handled."
else
  echo "FAIL: Invalid command not detected."
  exit 1
fi

# === Test 7: Input redirection ===
echo "=== Test 7: Input redirection ==="
echo "FromInputFile" > test_input.txt
cat <<EOF > test7.script
cat < test_input.txt
EOF

run_script "test7_input_redirect" test7.script
if grep -q "FromInputFile" "${OUTPUT_DIR}/test7_input_redirect.log"; then
  echo "PASS: Input redirection works."
else
  echo "FAIL: Input redirection failed."
  exit 1
fi

# === Test 8: if false ===
echo "=== Test 8: if false ==="
cat <<EOF > test8.script
if false
then
echo should_not_see
fi
EOF

run_script "test8_if_fail" test8.script
if grep -q "should_not_see" "${OUTPUT_DIR}/test8_if_fail.log"; then
  echo "FAIL: False condition executed block."
  exit 1
else
  echo "PASS: False condition handled correctly."
fi

# === Test 9: Variable redefinition ===
echo "=== Test 9: Variable redefinition ==="
cat <<EOF > test9.script
X=first
X=second
echo \$X
EOF

run_script "test9_var_redefine" test9.script
if grep -q "second" "${OUTPUT_DIR}/test9_var_redefine.log"; then
  echo "PASS: Variable redefinition works."
else
  echo "FAIL: Variable redefinition failed."
  exit 1
fi

# === Test 10: Variable-expanded if condition ===
echo "=== Test 10: if \$VAR ==="
cat <<EOF > test10.script
CMD=true
if \$CMD
then
echo correct
fi
EOF

run_script "test10_if_var" test10.script
if grep -q "correct" "${OUTPUT_DIR}/test10_if_var.log"; then
  echo "PASS: Variable-expanded condition works."
else
  echo "FAIL: Variable-expanded condition failed."
  exit 1
fi

# === Test 11: env inheritance ===
echo "=== Test 11: env inheritance ==="
cat <<EOF > test11.script
export HELLO=world
env
EOF

run_script "test11_env_propagation" test11.script
if grep -q "HELLO=world" "${OUTPUT_DIR}/test11_env_propagation.log"; then
  echo "PASS: Environment passed to child."
else
  echo "FAIL: Environment not seen by child."
  exit 1
fi

# Final report
echo ""
echo "SUCCESS: All tests PASS!"

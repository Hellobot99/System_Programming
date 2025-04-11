#!/bin/bash

TARGET="snake"
SRC="./${TARGET}.c"
BIN="./${TARGET}"

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

OUTPUT_DIR="snake_outputs"
mkdir -p "$OUTPUT_DIR"

# Function to remove ANSI escape codes
strip_ansi() {
  python3 - "$@" <<EOF
import sys, re
ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
  for line in f:
    print(ansi_escape.sub('', line), end='')
EOF
}

# Function to run snake program with given key actions
run_snake_and_signal() {
  local outfile="$1"
  local actions="$2"

  expect <<EOF > /dev/null
    set timeout 10
    set env(TERM) "ansi"
    log_file -noappend "$outfile"
    spawn $BIN
    after 1000
$actions
    expect eof
EOF
}

# Test 1: Check basic rendering (borders, snake, food, status)
echo "Test 1: Basic rendering check"
out1="$OUTPUT_DIR/test1.log"
run_snake_and_signal "$out1" "
after 1000
send q
"

stripped=$(mktemp)
strip_ansi "$out1" > "$stripped"

# Border check
top_border=$(grep '^#' "$stripped" | head -n1)
bottom_border=$(grep '^#' "$stripped" | tail -n1)
if [[ "$top_border" == *"#"* && "$bottom_border" == *"#"* ]]; then
  echo "PASS: Border detected"
else
  echo "FAIL: Border missing"
  exit 1
fi

# Snake body check
snake_count=$(grep -o "O" "$stripped" | wc -l)
if (( snake_count >= 5 )); then
  echo "PASS: Snake appears on screen"
else
  echo "FAIL: Snake not rendered properly"
  exit 1
fi

# Food symbol check
if grep -q "@" "$stripped"; then
  echo "PASS: Food symbol (@) found"
else
  echo "FAIL: Food not found"
  exit 1
fi

# Initial status line check
if grep -q "Score: 0, Length: 5" "$stripped"; then
  echo "PASS: Status line is correct"
else
  echo "FAIL: Status line is incorrect or missing"
  exit 1
fi

# Test 2: Ctrl+C triggers quit prompt
echo "Test 2: Ctrl+C triggers exit prompt"
out2="$OUTPUT_DIR/test2.log"
run_snake_and_signal "$out2" "
after 1000
send \003
after 1000
send q
"

strip_ansi "$out2" > "$stripped"
if grep -q "Are you sure you want to quit" "$stripped"; then
  echo "PASS: Ctrl+C prompt shown"
else
  echo "FAIL: Ctrl+C prompt not shown"
  exit 1
fi

# Test 3: Ctrl+C + y exits the game
echo "Test 3: Ctrl+C + y exits the game"
out3="$OUTPUT_DIR/test3.log"
run_snake_and_signal "$out3" "
after 1000
send \003
after 1000
send y
"

strip_ansi "$out3" > "$stripped"
if grep -q "Terminated by user" "$stripped"; then
  echo "PASS: Ctrl+C + y exits successfully"
else
  echo "FAIL: Ctrl+C + y did not exit properly"
  exit 1
fi

# Test 4: Ctrl+Z triggers pause message
echo "Test 4: Ctrl+Z triggers pause"
out4="$OUTPUT_DIR/test4.log"
run_snake_and_signal "$out4" "
after 1000
send \032
after 1000
send q
"

strip_ansi "$out4" > "$stripped"
if grep -q "PAUSED" "$stripped"; then
  echo "PASS: Ctrl+Z pause message shown"
else
  echo "FAIL: Ctrl+Z pause not detected"
  exit 1
fi

# Test 5: Ctrl+C + n resumes the game
echo "Test 5: Ctrl+C + n resumes the game"
out5="$OUTPUT_DIR/test5.log"
run_snake_and_signal "$out5" "
after 1000
send \003
after 1000
send n
after 1000
send q
"

strip_ansi "$out5" > "$stripped"
if grep -q "Score: 0, Length: 5" "$stripped"; then
  echo "PASS: Ctrl+C + n resumed the game"
else
  echo "FAIL: Ctrl+C + n did not resume properly"
  exit 1
fi

# Test 6: Ctrl+Z + p resumes the game
echo "Test 6: Ctrl+Z then 'p' to resume"
out6="$OUTPUT_DIR/test6.log"
run_snake_and_signal "$out6" "
after 1000
send \032
after 1000
send p
after 1000
send q
"

strip_ansi "$out6" > "$stripped"
if grep -q "PAUSED" "$stripped" && grep -q "Score: 0, Length: 5" "$stripped"; then
  echo "PASS: Ctrl+Z then p resumed the game"
else
  echo "FAIL: Ctrl+Z + p did not resume properly"
  exit 1
fi

echo ""
echo "SUCCESS: All tests PASS!"

#!/bin/bash

TARGET="move"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
OUTPUT_DIR="outputs"

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

mkdir -p "$OUTPUT_DIR"

# Define test cases: name, input keys, expected Y, expected X
TESTS=(
  "move_up w 4 10"
  "move_down s 6 10"
  "move_left a 5 9"
  "move_right d 5 11"
  "hit_top_wall wwwwwwwwwwwwwww 1 10"
  "hit_left_wall aaaaaaaaaaaaaaa 5 1"
)

# Function to remove ANSI escape codes (uses Python)
strip_ansi() {
  python3 - "$@" <<EOF
import sys, re
ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
  for line in f:
    print(ansi_escape.sub('', line), end='')
EOF
}

# Function to run the program with expect
run_expect() {
  local keys="$1"
  local outfile="$2"

  expect <<EOF > /dev/null
    set timeout 5
    set env(TERM) "ansi"
    log_file -noappend "$outfile"
    spawn $BIN
    after 300
    foreach c [split "$keys" ""] {
      send "\$c"
      after 400
    }
    send "q"
    expect eof
EOF
}

# Test loop
for test in "${TESTS[@]}"; do
  read -r name keys expected_y expected_x <<< "$test"
  out_file="$OUTPUT_DIR/$name.log"

  run_expect "$keys" "$out_file"

  # Strip ANSI escape codes
  stripped=$(mktemp)
  strip_ansi "$out_file" > "$stripped"

  # Extract all position outputs
  mapfile -t positions < <(grep -oE "Current Position: \([0-9]+,[[:space:]]*[0-9]+\)" "$stripped")

  if [ "${#positions[@]}" -eq 0 ]; then
    echo "FAIL: $name (Position not found)"
    exit 1
  fi

  # Parse the last position
  last="${positions[-1]}"
  if [[ "$last" =~ \(([0-9]+),[[:space:]]*([0-9]+)\) ]]; then
    actual_y="${BASH_REMATCH[1]}"
    actual_x="${BASH_REMATCH[2]}"
  else
    echo "FAIL: $name (Invalid position format)"
    exit 1
  fi

  if [[ "$actual_y" == "$expected_y" && "$actual_x" == "$expected_x" ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name (Expected: $expected_y, $expected_x | Actual: $actual_y, $actual_x)"
    exit 1
  fi
done

echo ""
echo "SUCCESS: All tests PASS!"

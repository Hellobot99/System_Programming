#!/bin/bash

TARGET="wc_mt"
SRC="./${TARGET}.c"
BIN="./${TARGET}"
INPUT_SMALL="test_input_small.txt"
INPUT_LARGE="test_input_large.txt"
OUTPUT_DIR="outputs_${TARGET}"
MAX_THREADS=4

STRACE_LOG="${OUTPUT_DIR}/strace.log"
SMALL_LOG="${OUTPUT_DIR}/output_small.log"
LARGE_LOG="${OUTPUT_DIR}/output_large.log"

# Cleanup
cleanup() {
  rm -f "$INPUT_SMALL" "$INPUT_LARGE"
}
trap cleanup EXIT

# 1. Check source
if [[ ! -f "$SRC" ]]; then
  echo "FAIL: Source file '$SRC' not found"
  exit 1
fi

# 2. Compile
if ! gcc -o "$BIN" "$SRC" -lpthread -O3 2> build_error.log; then
  echo "FAIL: Build failed"
  cat build_error.log
  exit 1
fi
rm -f build_error.log

# 3. Detect CPU cores and decide thread count
CPU_CORES=$(getconf _NPROCESSORS_ONLN)
if [[ "$CPU_CORES" -lt 2 ]]; then
  echo "FAIL: This test requires at least 2 CPU cores (found: $CPU_CORES)"
  exit 1
fi
NUM_THREADS=$(( CPU_CORES < MAX_THREADS ? CPU_CORES : MAX_THREADS ))
echo "INFO: Detected $CPU_CORES CPU cores. Use $NUM_THREADS threads"
echo ""

# 4. Prepare output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

####################################
# Part 1: Small input + strace test
####################################
echo "=== [Part 1] Small Input + Thread Count Test ==="

echo "Generating small input (10 words)..."
if ! python3 gen.py 10 "$INPUT_SMALL"; then
  echo "FAIL: Small input generation failed"
  exit 1
fi

echo "Running with strace to capture thread creation..."
strace -f -e trace=clone "$BIN" "$INPUT_SMALL" "$NUM_THREADS" > "$SMALL_LOG" 2> "$STRACE_LOG"

ATTACHED_COUNT=$(grep -c 'strace: Process [0-9]\+ attached' "$STRACE_LOG")
EXPECTED_THREADS=$NUM_THREADS

echo "Observed thread attach count: $ATTACHED_COUNT"
echo "Expected thread count: $EXPECTED_THREADS"

if [[ "$ATTACHED_COUNT" -lt "$EXPECTED_THREADS" ]]; then
  echo "FAIL: Too few threads attached (expected at least $EXPECTED_THREADS, got $ATTACHED_COUNT)"
  exit 1
else
  echo "PASS: Thread creation verified."
fi

####################################
# Part 2: Large input + accuracy/speed test
####################################
echo ""
echo "=== [Part 2] Large Input: Accuracy & Performance Test ==="

if ! command -v shuf &> /dev/null; then
  echo "FAIL: 'shuf' is required but not installed."
  exit 1
fi

WORD_COUNT=$(shuf -i 60000000-70000000 -n 1)
echo "Generating large input ($WORD_COUNT words)..."
if ! python3 gen.py "$WORD_COUNT" "$INPUT_LARGE"; then
  echo "FAIL: Large input generation failed"
  exit 1
fi

# Run wc -w
echo "Running baseline wc -w..."
echo 3 | sudo tee /proc/sys/vm/drop_caches 1>/dev/null
WC_LOG="${OUTPUT_DIR}/wc.log"
WC_COUNT=$( (time -p wc -w < "$INPUT_LARGE") 2> "$WC_LOG" | awk '{print $1}')
WC_TIME=$(grep real "$WC_LOG" | awk '{print $2}')
echo "Baseline word count: $WC_COUNT"
echo "Baseline time: $WC_TIME s"

# Run wc_mt
echo "Running target program: $TARGET"
echo 3 | sudo tee /proc/sys/vm/drop_caches 1>/dev/null
{ time -p "$BIN" "$INPUT_LARGE" "$NUM_THREADS"; } > "$LARGE_LOG" 2>&1

# Extract results from log
TARGET_COUNT=$(grep -oP 'Total words: \K[0-9]+' "$LARGE_LOG")
TARGET_TIME=$(grep ^real "$LARGE_LOG" | awk '{print $2}')
echo "Target word count: $TARGET_COUNT"
echo "Target time: $TARGET_TIME s"

# Validate word count
if [[ "$TARGET_COUNT" == "$WC_COUNT" ]]; then
  echo "PASS: Word count matches."
else
  echo "FAIL: Word count mismatch (expected: $WC_COUNT, got: $TARGET_COUNT)"
  exit 1
fi

# Compare performance
IS_FASTER=$(echo "$TARGET_TIME < $WC_TIME" | bc)
if [[ "$IS_FASTER" -eq 1 ]]; then
  echo "PASS: Program is faster than wc -w."
else
  echo "FAIL: Program is slower than wc -w."
  exit 1
fi

# Final result
echo ""
echo "SUCCESS: All tests PASS!"

#!/bin/bash

# === Configuration ===
TARGET1="wc_mt"
TARGET2="wc_mt_overlap"
SRC1="./${TARGET1}.c"
SRC2="./${TARGET2}.c"
BIN1="./${TARGET1}"
BIN2="./${TARGET2}"
INPUT_SMALL="test_input_small.txt"
INPUT_LARGE="test_input_large.txt"
OUTPUT_DIR="outputs_${TARGET2}"
MAX_THREADS=2
STRACE_LOG="${OUTPUT_DIR}/strace.log"
LOG_SMALL="${OUTPUT_DIR}/output_small.log"
LOG1_LARGE="${OUTPUT_DIR}/output_${TARGET1}.log"
LOG2_LARGE="${OUTPUT_DIR}/output_${TARGET2}.log"

# === Cleanup on exit ===
cleanup() {
  rm -f "$INPUT_SMALL" "$INPUT_LARGE"
}
trap cleanup EXIT

# === 1. Check for source files ===
if [[ ! -f "$SRC1" ]]; then
  echo "FAIL: Source file '$SRC1' not found"
  echo "INFO: wc_mt is required for this test"
  exit 1
fi
if [[ ! -f "$SRC2" ]]; then
  echo "FAIL: Source file '$SRC2' not found"
  exit 1
fi

# === 2. Compile both targets ===
echo "Compiling $TARGET1..."
if ! gcc -o "$BIN1" "$SRC1" -lpthread -O3 2> build_error.log; then
  echo "FAIL: Build failed for $TARGET1"
  cat build_error.log
  exit 1
fi

echo "Compiling $TARGET2..."
if ! gcc -o "$BIN2" "$SRC2" -lpthread -O3 2> build_error.log; then
  echo "FAIL: Build failed for $TARGET2"
  cat build_error.log
  exit 1
fi
rm -f build_error.log

# === 3. Check CPU cores and set thread count ===
CPU_CORES=$(getconf _NPROCESSORS_ONLN)
if [[ "$CPU_CORES" -lt 2 ]]; then
  echo "FAIL: This test requires at least 2 CPU cores"
  exit 1
fi
NUM_THREADS=$MAX_THREADS
echo "INFO: Using $NUM_THREADS threads on CPUs 0-1"
echo ""

# === 4. Prepare output directory ===
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# === 5. Small input + strace-based thread creation test ===
echo "=== [Part 1] Small Input + Thread Count Test ==="
if ! python3 gen.py 10 "$INPUT_SMALL"; then
  echo "FAIL: Input generation failed"
  exit 1
fi

echo "Running with strace to capture thread creation..."
strace -f -e trace=clone "$BIN2" "$INPUT_SMALL" "$NUM_THREADS" > "$LOG_SMALL" 2> "$STRACE_LOG"

ATTACHED_COUNT=$(grep -c 'strace: Process [0-9]\+ attached' "$STRACE_LOG")
EXPECTED_THREADS=$((NUM_THREADS + 1))  # 1 producer + N consumers

echo "Observed thread attach count: $ATTACHED_COUNT"
echo "Expected thread count: $EXPECTED_THREADS"

if [[ "$ATTACHED_COUNT" -lt "$EXPECTED_THREADS" ]]; then
  echo "FAIL: Too few threads attached (expected at least $EXPECTED_THREADS, got $ATTACHED_COUNT)"
  exit 1
else
  echo "PASS: Thread creation verified."
fi

# === 6. Generate large input for performance comparison ===
echo ""
echo "=== [Part 2] Large Input: Accuracy & Performance Comparison ==="
if ! command -v shuf &> /dev/null; then
  echo "FAIL: 'shuf' not available"
  exit 1
fi

WORD_COUNT=$(shuf -i 60000000-70000000 -n 1)
echo "Generating large input ($WORD_COUNT words)..."
if ! python3 gen.py "$WORD_COUNT" "$INPUT_LARGE"; then
  echo "FAIL: Large input generation failed"
  exit 1
fi

# === 7. Run wc -w to get baseline word count ===
echo "Running wc -w..."
echo 3 | sudo tee /proc/sys/vm/drop_caches 1>/dev/null
WC_LOG="${OUTPUT_DIR}/wc.log"
WC_COUNT=$( (time -p wc -w < "$INPUT_LARGE") 2> "$WC_LOG" | awk '{print $1}')
echo "Expected word count: $WC_COUNT"

# === 8. Run baseline wc_mt under 2-core constraint ===
echo "Running $TARGET1 (baseline)..."
echo 3 | sudo tee /proc/sys/vm/drop_caches 1>/dev/null
{ time -p taskset -c 0-1 "$BIN1" "$INPUT_LARGE" "$NUM_THREADS"; } > "$LOG1_LARGE" 2>&1
  COUNT1=$(grep -oP 'Total words: \K[0-9]+' "$LOG1_LARGE")
  TIME1=$(grep ^real "$LOG1_LARGE" | awk '{print $2}')

# === 9. Run wc_mt_overlap under same conditions ===
echo "Running $TARGET2 (overlap)..."
echo 3 | sudo tee /proc/sys/vm/drop_caches 1>/dev/null
{ time -p taskset -c 0-1 "$BIN2" "$INPUT_LARGE" "$NUM_THREADS"; } > "$LOG2_LARGE" 2>&1
  COUNT2=$(grep -oP 'Total words: \K[0-9]+' "$LOG2_LARGE")
  TIME2=$(grep ^real "$LOG2_LARGE" | awk '{print $2}')

# === 10. Verify correctness and compare performance ===
echo ""
echo "[wc_mt]         Count: $COUNT1   Time: ${TIME1}s"
echo "[wc_mt_overlap] Count: $COUNT2   Time: ${TIME2}s"

if [[ "$COUNT2" != "$WC_COUNT" ]]; then
  echo "FAIL: $TARGET2 returned incorrect word count"
  exit 1
else
  echo "PASS: $TARGET2 produced correct word count"
fi

IS_FASTER=$(echo "$TIME2 < $TIME1" | bc)
if [[ "$IS_FASTER" -eq 1 ]]; then
  echo "PASS: $TARGET2 is faster than $TARGET1"
else
  echo "FAIL: $TARGET2 is not faster than $TARGET1."
  exit 1
fi

echo ""
echo "SUCCESS: All tests PASS!"


#!/bin/bash
TEST_BIN="ls3"

# 1) Compile
rm -f $TEST_BIN
gcc -o $TEST_BIN $TEST_BIN.c
if [ $? -ne 0 ]; then
	echo "ERROR: Compilation failed."
	exit 1
fi

# 2) Create test directories with different structures
TEST_DIR1="test_dir1_ls3"
TEST_DIR2="test_dir2_ls3"

# Remove any old remnants before creating fresh directories
rm -rf "$TEST_DIR1" "$TEST_DIR2"

# Directory structure for TEST_DIR1
mkdir -p "$TEST_DIR1/sub_dir1"
touch "$TEST_DIR1/file1_in_dir1.txt" \
	"$TEST_DIR1/file2_in_dir1.txt" \
	"$TEST_DIR1/sub_dir1/sub_file1.txt" \
	"$TEST_DIR1/sub_dir1/sub_file2.txt"

# Directory structure for TEST_DIR2
mkdir -p "$TEST_DIR2/sub_dir2/sub_sub_dir2"
touch "$TEST_DIR2/file1_in_dir2.txt" \
	"$TEST_DIR2/sub_dir2/file_in_sub_dir2.txt" \
	"$TEST_DIR2/sub_dir2/sub_sub_dir2/deeper_file.txt"

# Adjust permissions to show different mode bits
chmod 775 "$TEST_DIR1/sub_dir1"
chmod 644 "$TEST_DIR1/file1_in_dir1.txt"
chmod 600 "$TEST_DIR1/file2_in_dir1.txt"
chmod 755 "$TEST_DIR1/sub_dir1/sub_file1.txt"
chmod 700 "$TEST_DIR1/sub_dir1/sub_file2.txt"

chmod 775 "$TEST_DIR2/sub_dir2"
chmod 755 "$TEST_DIR2/sub_dir2/sub_sub_dir2"
chmod 644 "$TEST_DIR2/file1_in_dir2.txt"
chmod 600 "$TEST_DIR2/sub_dir2/file_in_sub_dir2.txt"
chmod 755 "$TEST_DIR2/sub_dir2/sub_sub_dir2/deeper_file.txt"

# 3) Set a fixed timestamp so outputs remain consistent across runs
FIXED_TIME="202403201200.00"  # "YYYYMMDDhhmm.ss" => 2024-03-20 12:00:00
touch -t "$FIXED_TIME" "$TEST_DIR1" \
	"$TEST_DIR1/file1_in_dir1.txt" \
	"$TEST_DIR1/file2_in_dir1.txt" \
	"$TEST_DIR1/sub_dir1" \
	"$TEST_DIR1/sub_dir1/sub_file1.txt" \
	"$TEST_DIR1/sub_dir1/sub_file2.txt"

touch -t "$FIXED_TIME" "$TEST_DIR2" \
	"$TEST_DIR2/file1_in_dir2.txt" \
	"$TEST_DIR2/sub_dir2" \
	"$TEST_DIR2/sub_dir2/file_in_sub_dir2.txt" \
	"$TEST_DIR2/sub_dir2/sub_sub_dir2" \
	"$TEST_DIR2/sub_dir2/sub_sub_dir2/deeper_file.txt"

#ls -lR "$TEST_DIR1" "$TEST_DIR2"
#echo

# Directory to store output files from ls3 during tests
OUTPUT_DIR="outputs"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

REF_DIR="ls3_references"

# Helper function for running a test, capturing output, and diffing against reference
run_and_compare() {
	local test_cmd="$1"        # The exact command (including arguments)
	local output_file="$2"     # Where to store the test's output
	local reference_file="$3"  # Which reference file to compare against
	local test_name="$4"       # A human-readable label

	echo "=== Running $test_name ==="
	echo "[Command]: $test_cmd"

    # Run the command, capture output
    eval "$test_cmd" > "$output_file" 2>&1
    if [ $? -ne 0 ]; then
	    echo "ERROR: Program execution failed!"
	    exit 1
    fi

    # Compare with reference (if the reference file exists)
    if [ -f "$reference_file" ]; then
	    cat ${reference_file} | tr -s ' ' | sort -r > ${reference_file}.1
	    cat ${output_file} | tr -s ' ' | sort -r > ${output_file}.1
	    awk '{ $3=""; $4=""; print }' ${reference_file}.1 > ${reference_file}.2
	    awk '{ $3=""; $4=""; print }' ${output_file}.1 > ${output_file}.2
	    diff -u "${reference_file}.2" "${output_file}.2"
	    if [ $? -eq 0 ]; then
		    echo "[PASS] $test_name matches reference."
	    else
		    echo "[FAIL] $test_name differs from reference."
		    echo "REF:"
		    cat ${reference_file}.2
		    echo "OUT:"
		    cat ${output_file}.2
		    exit 1
	    fi
    else
	    echo "[WARN] Reference file '$reference_file' not found."
	    echo "       Cannot compare output."
	    exit 1
    fi
    echo
}

# 4) Execute Tests
run_and_compare \
	"./ls3 $TEST_DIR1" \
	"$OUTPUT_DIR/test1_out.txt" \
	"$REF_DIR/test1_ref.txt" \
	"Test 1: $TEST_DIR1"

run_and_compare \
	"./ls3 $TEST_DIR2" \
	"$OUTPUT_DIR/test2_out.txt" \
	"$REF_DIR/test2_ref.txt" \
	"Test 2: $TEST_DIR2"

run_and_compare \
	"./ls3 $TEST_DIR1 $TEST_DIR2" \
	"$OUTPUT_DIR/test3_out.txt" \
	"$REF_DIR/test3_ref.txt" \
	"Test 3: Multiple arguments for test directories"

echo "SUCCESS: All tests passed!"
exit 0

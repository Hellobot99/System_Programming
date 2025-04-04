#!/bin/bash

TEST_DIR="$(dirname `realpath $0`)"
cd $TEST_DIR

REFERENCE_BINARY="cp"
TEST_BINARY="./cp2"
SOURCE_FILE="source.txt"
DEST_FILE="dest.txt"
REF_OUTPUT="ref_error.txt"
TEST_OUTPUT="test_error.txt"
SOURCE_CODE="cp2.c"

# Cleanup function to remove temporary files
cleanup() {
    rm -f "$TEST_BINARY" "$SOURCE_FILE" "$DEST_FILE" "test_$DEST_FILE" "$REF_OUTPUT" "$TEST_OUTPUT"
}
# Ensure cleanup runs on exit (normal or error)
trap cleanup EXIT

# Check if source file exists
if [ ! -f "$SOURCE_CODE" ]; then
    echo "ERROR: Source file $SOURCE_CODE not found."
    exit 1
fi

# Compile the test binary
gcc -o "$TEST_BINARY" "$SOURCE_CODE"
if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed."
    exit 1
fi

# Check if test binary exists after compilation
if [ ! -f "$TEST_BINARY" ]; then
    echo "ERROR: Test binary ($TEST_BINARY) not found after compilation."
    exit 1
fi

# Create a sample source file
echo "This is a test file." > "$SOURCE_FILE"

# Test 1: Basic Copy Test
$REFERENCE_BINARY "$SOURCE_FILE" "$DEST_FILE"
$TEST_BINARY "$SOURCE_FILE" "test_$DEST_FILE"

if ! diff -q "$DEST_FILE" "test_$DEST_FILE" > /dev/null; then
    echo "FAILED: Basic copy test failed."
    echo "Reference output:" 
    cat $DEST_FILE
    echo "Your output:"
    cat test_$DEST_FILE
    exit 1
fi

# Test 2: Self-copy ERROR Message Test
$REFERENCE_BINARY "$SOURCE_FILE" "$SOURCE_FILE" 2> "$REF_OUTPUT"
$TEST_BINARY "$SOURCE_FILE" "$SOURCE_FILE" 2> "$TEST_OUTPUT"

if ! diff -q "$REF_OUTPUT" "$TEST_OUTPUT" > /dev/null; then
    echo "FAILED: Self-copy error message test failed."
    echo "Reference output:" 
    cat $REF_OUTPUT
    echo "Your output:"
    cat $TEST_OUTPUT
    exit 1
fi

echo "All tests passed!"
exit 0

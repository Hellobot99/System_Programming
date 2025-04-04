#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
	echo "ERROR: Usage: $0 <ls3|cpdr>"
	exit 1
fi

TARGET="$1"

if [[ "$TARGET" != "ls3" && "$TARGET" != "cpdr" ]]; then
	echo "ERROR: Invalid input '$TARGET'. Only 'ls3' or 'cpdr' are allowed."
	exit 1
fi

# Check if the source file exists before creating the symbolic link
SOURCE_FILE="${TARGET}.c"
if [ ! -f "$SOURCE_FILE" ]; then
	echo "ERROR: Source file '$SOURCE_FILE' not found. Exiting."
	exit 1
fi

echo "[INFO] Updating test scripts to the latest version..."

# Initialize and update git submodules
git submodule init
git submodule update --remote --merge

# Verify if the update was successful
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to update test scripts. Exiting."
	exit 1
fi

# Ensure the test directory exists before changing into it
if [ ! -d "test" ]; then
	echo "ERROR: Test directory 'test' not found. Exiting."
	exit 1
fi
cd test

ln -sf "../$SOURCE_FILE" "$SOURCE_FILE"

# Run the test script dynamically based on the target
TEST_SCRIPT="test_${TARGET}.sh"
if [ ! -f "$TEST_SCRIPT" ]; then
	echo "ERROR: Test script '$TEST_SCRIPT' not found. Exiting."
	exit 1
fi

bash "$TEST_SCRIPT"
if [ $? -ne 0 ]; then
	echo "ERROR: Test script execution failed."
	exit 1
fi

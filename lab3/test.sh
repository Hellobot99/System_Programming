#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
  echo "ERROR: Usage: $0 <hello|count>"
  exit 1
fi

TARGET="$1"

if [[ "$TARGET" != "hello" && "$TARGET" != "count" ]]; then
  echo "ERROR: Invalid input '$TARGET'. Only 'hello' or 'count' are allowed."
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

# Run the test script dynamically based on the target
TEST_SCRIPT="test/test.sh"
if [ ! -f "$TEST_SCRIPT" ]; then
  echo "ERROR: Test script '$TEST_SCRIPT' not found. Exiting."
  exit 1
fi

export LAB_HOME=$(pwd)
bash "$TEST_SCRIPT" "$TARGET"
if [ $? -ne 0 ]; then
  echo "ERROR: Test script execution failed."
  exit 1
fi

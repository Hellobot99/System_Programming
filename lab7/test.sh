#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
  echo "ERROR: Usage: $0 <mini-shell-1|mini-shell-2|mini-shell-3>"
  exit 1
fi

TARGET="$1"

if [[ "$TARGET" != "mini-shell-1" && "$TARGET" != "mini-shell-2" && "$TARGET" != "mini-shell-3" ]]; then
  echo "ERROR: Invalid input '$TARGET'. Only 'mini-shell-1', 'mini-shell-2', or 'mini-shell-3' are allowed."
  exit 1
fi

echo "[INFO] Updating test scripts to the latest version..."

# Initialize and update git submodules
git submodule init test
git submodule update --remote --merge test

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


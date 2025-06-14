#!/bin/bash

#echo ""
#echo "[INFO] Test script is not available yet. Stay tuned for updates!"
#exit 1

# Check and install dependencies
install_if_missing() {
  if ! dpkg -s "$1" &> /dev/null; then
    echo "Installing missing package: $1"
    sudo apt-get update
    sudo apt-get install -y "$1"
  fi
}

# Check if LAB_HOME is set
if [ -z "${LAB_HOME}" ]; then
  echo "[ERROR] LAB_HOME is not set. Please export LAB_HOME before running this script."
  exit 1
fi

cd "${LAB_HOME}" || { echo "[ERROR] Failed to cd into LAB_HOME"; exit 1; }

# Argument check
TARGET="$1"
if [ -z "${TARGET}" ]; then
  echo "[ERROR] No target specified. Usage: $0 <target_name>"
  exit 1
fi

# Check if test script exists
TEST_SCRIPT="${LAB_HOME}/test/test_${TARGET}.sh"
if [ ! -f "${TEST_SCRIPT}" ]; then
  echo "[ERROR] Test script not found: ${TEST_SCRIPT}"
  exit 1
fi

install_if_missing "strace"

echo "[INFO] Sudo privilege is required for accurate timing."
echo "[INFO] Requesting sudo access..."
sudo -v

# Run test
echo "[INFO] Running test script for ${TARGET}"
${TEST_SCRIPT}

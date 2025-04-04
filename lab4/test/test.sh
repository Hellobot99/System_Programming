#!/bin/bash

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

# Check if expect is installed
if ! command -v expect &> /dev/null; then
  echo "[INFO] 'expect' is not installed. Installing it now..."
  sudo apt update && sudo apt install -y expect
  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to install expect. Please install it manually."
    exit 1
  fi
fi

# Check if socat is installed
if ! command -v socat &> /dev/null; then
  echo "[INFO] 'socat' is not installed. Installing it now..."
  sudo apt update && sudo apt install -y socat
  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to install socat. Please install it manually."
    exit 1
  fi
fi

# Run test
echo "[INFO] Running test script for ${TARGET}"
${TEST_SCRIPT}

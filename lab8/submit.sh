#!/bin/bash

echo "[INFO] Updating test scripts to the latest version..."
git submodule init test
git submodule update --remote --merge test

# Verify if the update was successful
if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to update test scripts. Exiting."
  exit 1
fi

export LAB_HOME=$(pwd)
bash test/submit.sh "$1"

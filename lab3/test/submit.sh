#!/bin/bash

set -e

# Check LAB_HOME is set
if [ -z "$LAB_HOME" ]; then
  echo "[ERROR] LAB_HOME is not set. Please set it before running this script."
  exit 1
fi
cd "$LAB_HOME" || exit 1

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default commit message
DEFAULT_MSG="[SUBMIT] Lab #3"

# Step 1: Check if inside a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${RED}[ERROR] This directory is not a git repository.${NC}"
  exit 1
fi

# Step 2: Check if user.name and user.email are configured
name=$(git config user.name)
email=$(git config user.email)

if [ -z "$name" ] || [ -z "$email" ]; then
  echo -e "${RED}[ERROR] Git user name and/or email not configured.${NC}"
  echo "Please run the following commands to configure:"
  echo
  echo "  git config --global user.name \"Your Name\""
  echo "  git config --global user.email \"your@email.com\""
  exit 1
fi

echo -e "${GREEN}[INFO] Git user: $name <$email>${NC}"

# Step 3: Stage all changes
git add -A
echo -e "${GREEN}[INFO] All changes staged.${NC}"

# Step 4: Check if anything is staged
if git diff --cached --quiet; then
  echo -e "${GREEN}[INFO] No changes to commit.${NC}"
else
  # Step 5: Get commit message
  COMMIT_MSG="${1:-$DEFAULT_MSG}"  # Use input if provided, else default

  if git commit -m "$COMMIT_MSG"; then
    echo -e "${GREEN}[INFO] Changes committed with message: '$COMMIT_MSG'${NC}"
  else
    echo -e "${RED}[ERROR] Commit failed.${NC}"
    exit 1
  fi
fi

# Step 6: Push
echo -e "${GREEN}[INFO] Pushing to remote repository...${NC}"
if git push; then
  echo -e "${GREEN}[SUCCESS] Submission pushed successfully!${NC}"
else
  echo -e "${RED}[ERROR] Push failed. Please check your remote settings or network.${NC}"
  exit 1
fi

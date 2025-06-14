#!/bin/bash

TARGET="webserver"
SRC="${PWD}/${TARGET}.c"
PORT=8080
TIMEOUT=5

# Create isolated temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

WWW_DIR="./www"
OUTPUT_DIR="./outputs"
BIN="./$TARGET"
SERVER_LOG="$OUTPUT_DIR/server.log"

# Cleanup on exit
cleanup() {
  pkill -f "$BIN" 2>/dev/null
  cd /  # leave temp dir before deletion
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# 1. Copy source
cp "$SRC" "$TMP_DIR/"

# 2. Build in temp dir
echo "[INFO] Building $TARGET..."
mkdir -p "$OUTPUT_DIR"
if ! gcc -o "$BIN" "$SRC"; then
  echo "FAIL: Build failed"
  exit 1
fi

# 3. Create ./www directory
echo "[INFO] Creating web root at $TMP_DIR/$WWW_DIR..."
mkdir -p "$WWW_DIR"
echo "<h1>Hello from index</h1>" > "$WWW_DIR/index.html"
echo "file-content" > "$WWW_DIR/hello.txt"

# 4. Start server (in current dir)
echo "[INFO] Starting server in $TMP_DIR..."
"$BIN" > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!
sleep "$TIMEOUT"

if ! ps -p "$SERVER_PID" > /dev/null; then
  echo "FAIL: Server failed to start"
  cat "$SERVER_LOG"
  exit 1
fi

# 5. Run tests
echo ""
echo "=== HTTP SERVER FUNCTIONAL TESTS ==="

pass=0
fail=0

run_test() {
  local name="$1"
  local url="$2"
  local expect_status="$3"
  local expect_body="$4"
  local check_body="${5:-yes}"  # default: check body

  echo -n "[TEST] $name ... "
  response=$(curl --path-as-is -s -o response_body.txt -w "%{http_code}" "$url")
  body=$(cat response_body.txt)

  if [[ "$response" == "$expect_status" ]]; then
    if [[ "$check_body" == "no" || "$body" == *"$expect_body"* ]]; then
      echo "PASS"
      pass=$((pass + 1))
    else
      echo "FAIL (status OK, but body mismatch)"
      echo "  Expected body to contain: \"$expect_body\""
      echo "  Got body: \"$body\""
      fail=$((fail + 1))
    fi
  else
    echo "FAIL (wrong status)"
    echo "  Expected: $expect_status, Got: $response"
    fail=$((fail + 1))
  fi
}

run_test "GET /" \
  "http://localhost:$PORT/" \
  "200" \
  "Hello from index"

run_test "GET /hello.txt" \
  "http://localhost:$PORT/hello.txt" \
  "200" \
  "file-content"

run_test "GET /notfound.txt" \
  "http://localhost:$PORT/notfound.txt" \
  "404" \
  "404 Not Found"

run_test "GET outside root (/../../../../etc/passwd)" \
  "http://localhost:$PORT/../../../../etc/passwd" \
  "403" \
  "" \
  "no"

# 6. Summary
echo ""
echo "=== TEST SUMMARY ==="
echo "PASS: $pass"
echo "FAIL: $fail"
echo ""

if [[ $fail -eq 0 ]]; then
  echo "SUCCESS: All tests PASS!"
else
  echo "FAILURE: Some tests failed."
  exit 1
fi


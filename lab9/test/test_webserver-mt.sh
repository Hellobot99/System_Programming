#!/bin/bash

# === Configuration ===
PORT=8080
DURATION=5
CONNECTIONS=64
THREADS=4
REPEAT=3  # Set the number of repetitions

SRC_MT="${PWD}/webserver-mt.c"
PY_SERVER="${PWD}/baseline.py"
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

# Check CPU core count
NUM_CORES=$(getconf _NPROCESSORS_ONLN)
if [[ "$NUM_CORES" -lt 2 ]]; then
  echo "FAIL: At least 2 CPU cores required (found: $NUM_CORES)"
  exit 1
fi

# Cleanup on exit
cleanup() {
  pkill -f "webserver_mt" 2>/dev/null
  pkill -f "baseline.py" 2>/dev/null
  cd /
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Prepare working files
cp "$SRC_MT" ./webserver-mt.c
cp "$PY_SERVER" ./baseline.py
mkdir -p www
echo "[INFO] Generating large index.html..."
python3 -c "with open('www/index.html', 'w') as f: f.write('<html><body><h1>Benchmark</h1>' + '<p>line</p>' * 10000 + '</body></html>')"

# Build C multi-threaded server
echo "[INFO] Compiling webserver-mt.c..."
if ! gcc webserver-mt.c -o webserver_mt -lpthread -O3 -Wno-unused-result; then
  echo "FAIL: Failed to build webserver-mt.c"
  exit 1
fi

# Functional test
echo "[TEST] Functional test for ./webserver_mt"
./webserver_mt > /dev/null 2>&1 &
pid=$!
sleep 1
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/index.html)
if ps -p "$pid" > /dev/null; then kill "$pid"; fi
sleep 1

if [[ "$http_code" == "200" ]]; then
  echo "PASS: ./webserver_mt served index.html successfully."
else
  echo "FAIL: ./webserver_mt failed to serve index.html (HTTP $http_code)"
  exit 1
fi
echo ""

# === Python baseline benchmark ===
echo "[INFO] Benchmarking Python (single-threaded)..."
total_py=0

for i in $(seq 1 $REPEAT); do
  echo "[INFO] Python run $i..."

  taskset -c 0 python3 baseline.py > /dev/null 2>&1 &
  pid=$!

  for j in {1..10}; do
    sleep 0.5
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/index.html)
    if [[ "$http_code" == "200" ]]; then break; fi
  done

  if ! ps -p "$pid" > /dev/null; then
    echo "FAIL: Python server did not start properly"
    exit 1
  fi

  wrk -t"$THREADS" -c"$CONNECTIONS" -d"${DURATION}s" http://localhost:$PORT/index.html > py_wrk.log
  req=$(grep "Requests/sec" py_wrk.log | awk '{print $2}')
  echo " - $req req/sec"
  total_py=$(echo "$total_py + $req" | bc)

  kill "$pid" 2>/dev/null
  sleep 1
done

avg_py=$(echo "scale=2; $total_py / $REPEAT" | bc)

# === C multi-threaded benchmark ===
echo "[INFO] Benchmarking C (multi-threaded)..."
total_mt=0

for i in $(seq 1 $REPEAT); do
  echo "[INFO] C run $i..."

  ./webserver_mt > /dev/null 2>&1 &
  pid=$!

  for j in {1..10}; do
    sleep 0.5
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/index.html)
    if [[ "$http_code" == "200" ]]; then break; fi
  done

  if ! ps -p "$pid" > /dev/null; then
    echo "FAIL: C server did not start properly"
    exit 1
  fi

  wrk -t"$THREADS" -c"$CONNECTIONS" -d"${DURATION}s" http://localhost:$PORT/index.html > mt_wrk.log
  req=$(grep "Requests/sec" mt_wrk.log | awk '{print $2}')
  echo " - $req req/sec"
  total_mt=$(echo "$total_mt + $req" | bc)

  kill "$pid" 2>/dev/null
  sleep 1
done

avg_mt=$(echo "scale=2; $total_mt / $REPEAT" | bc)

# === Result and threshold check ===
threshold=$(echo "$avg_py * 1.3" | bc)
echo ""
echo "=== PERFORMANCE RESULTS (average over $REPEAT runs) ==="
printf "Python (single-threaded):  %s req/sec\n" "$avg_py"
printf "C (multi-threaded):        %s req/sec\n" "$avg_mt"

is_faster=$(echo "$avg_mt >= $threshold" | bc)
if [[ "$is_faster" -eq 1 ]]; then
  echo "PASS: Multi-threaded C server outperforms the single-threaded Python baseline."
  echo "HINT: Results may vary depending on the system. Please also verify using GitHub Actions."
else
  echo "FAIL: Multi-threaded C server is not at least 30% faster than the Python baseline."
  echo "HINT: Results may vary depending on the system. Please also verify using GitHub Actions."
  exit 1
fi

echo ""
echo "SUCCESS: All tests PASS!"

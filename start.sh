#!/bin/sh

# Railway sets PORT dynamically - Piston reads it automatically
API_PORT=${PORT:-8080}
echo "Starting Piston on port $API_PORT ..."

cd /piston_api
node src/index.js &
API_PID=$!

(
  echo "Waiting for API on port $API_PORT ..."
  until curl -sf http://localhost:$API_PORT/api/v2/runtimes > /dev/null 2>&1; do
    sleep 3
  done
  echo "API ready - installing languages in background..."

  install() {
    echo "  Installing $1 $2"
    curl -sf -X POST http://localhost:$API_PORT/api/v2/packages \
      -H 'Content-Type: application/json' \
      -d "{\"language\":\"$1\",\"version\":\"$2\"}" || true
    sleep 2
  }

  install python     3.10.0
  install javascript 18.15.0
  install typescript 5.0.3
  install java       15.0.2
  install c          10.2.0
  install c++        10.2.0
  install csharp     6.12.0
  install go         1.16.2
  install rust       1.50.0
  install ruby       3.0.1
  install swift      5.3.3
  install kotlin     1.4.31

  echo "All languages installed! Piston fully ready."
) &

wait $API_PID

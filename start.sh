#!/bin/sh

echo "Starting Piston API on port 2000..."

# Start Piston API immediately so Railway health check passes
node /piston/repo/src/api.js &
API_PID=$!

# Install languages in the background — does not block startup
(
  echo "Waiting for API to be ready before installing languages..."
  until curl -sf http://localhost:2000/api/v2/runtimes > /dev/null 2>&1; do
    sleep 3
  done
  echo "API ready — installing languages in background..."

  install() {
    echo "  Installing $1 $2 ..."
    curl -sf -X POST http://localhost:2000/api/v2/packages \
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

# Keep container alive
wait $API_PID

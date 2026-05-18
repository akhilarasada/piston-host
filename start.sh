#!/bin/sh

echo "=== Listing root directories ==="
ls -la /

echo ""
echo "=== Finding all package.json (not in node_modules) ==="
find / -name "package.json" 2>/dev/null | grep -v "node_modules"

echo ""
echo "=== Finding all .js entry files ==="
find / -name "*.js" 2>/dev/null | grep -v "node_modules" | head -30

echo "=== Debug done, sleeping so you can read logs ==="
sleep 3600

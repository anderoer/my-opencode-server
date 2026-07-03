#!/bin/bash

set -e

echo "========================================"
echo "  OpenCode + Bore Tunnel Setup"
echo "========================================"

# Set password if not provided
if [ -z "$OPENCODE_SERVER_PASSWORD" ]; then
    export OPENCODE_SERVER_PASSWORD="changeme123"
    echo "⚠️  WARNING: Using default password: changeme123"
    echo "⚠️  Set OPENCODE_SERVER_PASSWORD environment variable to change"
fi

echo "🚀 Starting OpenCode Web Server..."
opencode web --port 2222 &
OPENCODE_PID=$!
echo "✓ OpenCode PID: $OPENCODE_PID"

# Wait for opencode to start
sleep 3

# Check if opencode is running
if ! kill -0 $OPENCODE_PID 2>/dev/null; then
    echo "❌ OpenCode failed to start"
    exit 1
fi

echo "🌐 Starting Bore Tunnel..."
/tools/bore local --to bore.pub 2222 &
BORE_PID=$!
echo "✓ Bore PID: $BORE_PID"

echo ""
echo "========================================"
echo "  Services Running"
echo "========================================"
echo "OpenCode Web: http://127.0.0.1:2222"
echo "Bore Tunnel: <check logs below>"
echo "========================================"
echo ""

# Keep container running
wait $OPENCODE_PID $BORE_PID

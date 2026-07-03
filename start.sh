#!/bin/bash

set -e

# Railway PORT variable
PORT=${PORT:-2222}

echo "========================================"
echo "  OpenCode + Railway Proxy Setup"
echo "========================================"
echo "Port: $PORT"
echo "Railway Mode: ${RAILWAY_ENVIRONMENT:-local}"
echo ""

# Download and setup bore if not exists
if [ ! -f ./bore ]; then
  echo "📥 Downloading Bore..."
  rm -f bore*
  wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  chmod +x bore
  echo "✓ Bore installed"
fi

# Install opencode if not exists
if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

echo ""
echo "🚀 Starting OpenCode Web Server (port $PORT)..."
opencode web --port $PORT &
OPENCODE_PID=$!
echo "✓ OpenCode PID: $OPENCODE_PID"

sleep 3

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo ""
echo "========================================"
echo "  ✓ Services Running"
echo "========================================"
echo "OpenCode: http://localhost:$PORT"
echo ""

# Check if running on Railway
if [ "$RAILWAY_ENVIRONMENT" = "production" ]; then
  echo "🌐 Railway Proxy Active"
  echo "Public URL: https://\$RAILWAY_PUBLIC_DOMAIN"
  echo ""
  echo "Optional: Create Bore tunnel for backup"
  echo "./bore local --to bore.pub $PORT"
  echo ""
else
  echo "🌐 Starting Bore Tunnel (local mode)..."
  ./bore local --to bore.pub $PORT
fi

# Keep container running
wait

#!/bin/bash

set -e

# Railway PORT env var (default 8080)
PORT=${PORT:-8080}

echo "========================================"
echo "  Railway OpenCode Setup"
echo "========================================"
echo "Port: $PORT"
echo ""

# Install if needed
if [ ! -f ./bore ]; then
  echo "📥 Downloading Bore..."
  rm -f bore*
  wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz 2>&1 | grep -v "^--" || true
  tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  chmod +x bore
  echo "✓ Bore installed"
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

echo ""
echo "🚀 Starting OpenCode on port $PORT..."

# CRITICAL FIX: opencode web only takes --port, NOT --hostname
# It listens on 127.0.0.1 by default but Railway will proxy it
opencode web --port $PORT &
OPENCODE_PID=$!

sleep 4

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo "✓ OpenCode running (PID: $OPENCODE_PID)"
echo ""
echo "========================================"
echo "  Railway Proxy Active"
echo "========================================"
echo ""
echo "✓ OpenCode listening on port $PORT"
echo ""
echo "Your application is ready!"
echo "Check Railway dashboard for public URL"
echo ""

wait

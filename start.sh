#!/bin/bash

set -e

PORT=${PORT:-8080}

echo "========================================"
echo "  Railway OpenCode Setup"
echo "========================================"
echo "Port: $PORT"
echo ""

if [ ! -f ./bore ]; then
  echo "📥 Downloading Bore..."
  rm -f bore*
  wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz 2>&1 | tail -5
  tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  chmod +x bore
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash 2>&1 | tail -3
  export PATH="$HOME/.opencode/bin:$PATH"
fi

echo ""
echo "🚀 Starting OpenCode on port $PORT..."

# CRITICAL: Use --mdns to make it accessible to Railway proxy
# This makes OpenCode listen on 0.0.0.0 instead of localhost
opencode web --port $PORT --mdns &
OPENCODE_PID=$!

sleep 4

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo "✓ OpenCode running with mDNS (PID: $OPENCODE_PID)"
echo ""
echo "========================================"
echo "  Railway Proxy Active"
echo "========================================"
echo ""
echo "✓ OpenCode accessible on port $PORT"
echo "✓ Railway HTTP proxy will forward traffic"
echo ""
echo "Check Railway dashboard for your public URL"
echo ""

wait

#!/bin/bash

set -e

# Railway PORT env var
PORT=${PORT:-2222}

echo "========================================"
echo "  Railway HTTP Proxy Setup"
echo "========================================"
echo "Port: $PORT"
echo ""

# Install if needed
if [ ! -f ./bore ]; then
  echo "📥 Downloading Bore..."
  rm -f bore*
  wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  chmod +x bore
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  export PATH="$HOME/.opencode/bin:$PATH"
fi

echo ""
echo "🚀 Starting OpenCode on port $PORT..."
# CRITICAL: Bind to 0.0.0.0 (all interfaces) not just localhost
opencode web --port $PORT --host 0.0.0.0 &
OPENCODE_PID=$!

sleep 3

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo "✓ OpenCode running (PID: $OPENCODE_PID)"
echo ""
echo "========================================"
echo "  Railway HTTP Proxy Active"
echo "========================================"
echo ""
echo "✓ OpenCode listening on:"
echo "  http://0.0.0.0:$PORT"
echo ""
echo "Access Details:"
echo "  Check Railway Networking for public URL"
echo "  Railway auto-assigns: something.up.railway.app"
echo ""

wait

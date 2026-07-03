#!/bin/bash

set -e

echo "========================================"
echo "  OpenCode + Bore Tunnel Installer"
echo "========================================"
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
echo "🚀 Starting OpenCode Web Server (port 2222)..."
opencode web --port 2222 &
OPENCODE_PID=$!
echo "✓ OpenCode PID: $OPENCODE_PID"

sleep 2

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo ""
echo "🌐 Starting Bore Tunnel to bore.pub..."
echo "========================================"
echo ""

./bore local --to bore.pub 2222

wait

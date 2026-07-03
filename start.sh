#!/bin/bash

set -e

echo "========================================"
echo "  Railway TCP Proxy Setup"
echo "========================================"
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
echo "🚀 Starting OpenCode on port 2222..."
opencode web --port 2222 &
OPENCODE_PID=$!

sleep 3

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo "✓ OpenCode running (PID: $OPENCODE_PID)"
echo ""
echo "========================================"
echo "  Railway TCP Proxy Active"
echo "========================================"
echo ""
echo "✓ Railway will automatically proxy"
echo "  your TCP connection on port 2222"
echo ""
echo "Access Details:"
echo "  Check Railway Networking tab for:"
echo "  TCP Proxy Domain: shuttle.proxy.rlwy.net"
echo "  TCP Proxy Port: XXXXX (auto-assigned)"
echo ""

wait

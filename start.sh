#!/bin/bash

set -e

PORT=${PORT:-8080}
SSH_PORT=${SSH_PORT:-2222}

echo "========================================"
echo "  Railway OpenCode + SSH Setup"
echo "========================================"
echo "OpenCode Port: $PORT"
echo "SSH Port: $SSH_PORT"
echo ""

# Install dependencies
if [ ! -f ./bore ]; then
  echo "📥 Downloading Bore..."
  rm -f bore*
  wget -q https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
  chmod +x bore
  echo "✓ Bore installed"
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash 2>&1 | grep -i "successfully" || true
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

# Setup SSH - AUTO DETECT sshd_config
echo ""
echo "🔐 Configuring SSH..."

# Find sshd_config - try multiple paths
SSHD_CONFIG=""
for path in /etc/ssh/sshd_config /root/.ssh/sshd_config /app/sshd_config; do
  if [ -f "$path" ]; then
    SSHD_CONFIG="$path"
    break
  fi
done

# If not found, create it
if [ -z "$SSHD_CONFIG" ]; then
  SSHD_CONFIG="/etc/ssh/sshd_config"
  mkdir -p $(dirname "$SSHD_CONFIG")
  touch "$SSHD_CONFIG"
fi

echo "Using SSH config: $SSHD_CONFIG"

# Configure SSH (safe way)
{
  echo "Port $SSH_PORT"
  echo "PermitRootLogin yes"
  echo "PasswordAuthentication yes"
  echo "PubkeyAuthentication yes"
  echo "PermitEmptyPasswords no"
  echo "UsePAM yes"
  echo "X11Forwarding no"
  echo "PrintMotd no"
} > "$SSHD_CONFIG"

# Create /run/sshd if missing
mkdir -p /run/sshd

# Start SSH with all fixes
echo "🚀 Starting SSH server on port $SSH_PORT..."

# Kill any existing sshd
pkill -9 sshd 2>/dev/null || true
sleep 1

# Start with debug info
/usr/sbin/sshd -D -p $SSH_PORT -f "$SSHD_CONFIG" &
SSH_PID=$!

sleep 2

if ! kill -0 $SSH_PID 2>/dev/null; then
  echo "❌ SSH failed to start"
  echo "Trying alternate startup..."
  /usr/sbin/sshd -p $SSH_PORT || true
  exit 1
fi

echo "✓ SSH server running (PID: $SSH_PID)"
echo "  Config: $SSHD_CONFIG"
echo "  Port: $SSH_PORT"

# Start OpenCode
echo ""
echo "🚀 Starting OpenCode on port $PORT..."
opencode web --port $PORT --mdns &
OPENCODE_PID=$!

sleep 3

if ! kill -0 $OPENCODE_PID 2>/dev/null; then
  echo "❌ OpenCode failed to start"
  exit 1
fi

echo "✓ OpenCode running (PID: $OPENCODE_PID)"

echo ""
echo "========================================"
echo "  Services Ready"
echo "========================================"
echo ""
echo "🌐 OpenCode:"
echo "  Check Railway dashboard for URL"
echo ""
echo "🔑 SSH Terminal:"
echo "  Config: $SSHD_CONFIG"
echo "  Port: $SSH_PORT"
echo "  User: root"
echo "  Auth: password"
echo ""
echo "📋 Bore Tunnel (for remote access):"
echo "  ./bore local --to bore.pub $SSH_PORT"
echo ""

wait

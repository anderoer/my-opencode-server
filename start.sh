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

# Configure SSH with username/password support
echo ""
echo "🔐 Configuring SSH..."

# Create SSH config
mkdir -p /etc/ssh

# Enable password authentication
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true

# Set SSH port
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config 2>/dev/null || true
sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config 2>/dev/null || true

# Allow root login with password
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config 2>/dev/null || true

# Start SSH daemon
echo "🚀 Starting SSH server on port $SSH_PORT..."
/usr/sbin/sshd -D &
SSH_PID=$!
sleep 1

if ! kill -0 $SSH_PID 2>/dev/null; then
  echo "❌ SSH failed to start"
  exit 1
fi
echo "✓ SSH server running (PID: $SSH_PID)"

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
echo "  Services Configuration"
echo "========================================"
echo ""
echo "🌐 OpenCode:"
echo "  URL: Check Railway dashboard"
echo "  Port: $PORT (HTTP Proxy)"
echo ""
echo "🔑 SSH Terminal:"
echo "  Port: $SSH_PORT (via Bore tunnel)"
echo "  Username: root (or create custom user)"
echo "  Password: set with 'passwd' command"
echo ""
echo "📋 To use with Bore:"
echo "  ./bore local --to bore.pub $SSH_PORT"
echo ""
echo "📋 To use with Termius:"
echo "  Host: bore.pub"
echo "  Port: (shown by bore)"
echo "  Username: root"
echo "  Password: (your SSH password)"
echo ""
echo "========================================"
echo ""

wait

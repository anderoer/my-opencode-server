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

# Setup SSH - BYPASS PAM ISSUES
echo ""
echo "🔐 Configuring SSH (Bypass PAM)..."

SSHD_CONFIG="/etc/ssh/sshd_config"
mkdir -p $(dirname "$SSHD_CONFIG")
mkdir -p /run/sshd

# Create minimal SSH config that BYPASSES PAM
cat > "$SSHD_CONFIG" << 'SSHEOF'
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords yes
PubkeyAuthentication yes
UsePAM no
AuthenticationMethods password
ChallengeResponseAuthentication no
X11Forwarding no
PrintMotd no
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

echo "Using SSH config: $SSHD_CONFIG"

# Generate SSH keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo "  Generating SSH host keys..."
  ssh-keygen -A
fi

# Kill any existing sshd
pkill -9 sshd 2>/dev/null || true
sleep 1

# Start SSH server
echo "🚀 Starting SSH server on port $SSH_PORT..."

/usr/sbin/sshd -D -f "$SSHD_CONFIG" &
SSH_PID=$!

sleep 2

if ! kill -0 $SSH_PID 2>/dev/null; then
  echo "❌ SSH failed to start - checking error..."
  /usr/sbin/sshd -f "$SSHD_CONFIG" -t 2>&1 || true
  exit 1
fi

echo "✓ SSH server running (PID: $SSH_PID)"
echo "  Port: $SSH_PORT"
echo "  Auth: Password (UsePAM disabled)"
echo "  User: root (empty password accepted)"

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
echo "🔑 SSH Terminal (Bore Tunnel):"
echo "  Port: $SSH_PORT"
echo "  Username: root"
echo "  Password: (empty - just press Enter)"
echo ""
echo "📋 How to connect:"
echo "  1. Local: ./bore local --to bore.pub $SSH_PORT"
echo "  2. Termius:"
echo "     - Host: bore.pub"
echo "     - Port: (from bore output)"
echo "     - Username: root"
echo "     - Password: (leave empty or press Enter)"
echo ""

wait

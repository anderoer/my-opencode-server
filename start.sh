#!/bin/bash

set -e

OPENCODE_PORT=${PORT:-8080}
SSH_PORT=2222

if [ "$OPENCODE_PORT" = "$SSH_PORT" ]; then
  OPENCODE_PORT=8080
fi

# Variables from Railway dashboard (set these in Variables tab)
SSH_USERNAME=${SSH_USERNAME:-root}
SSH_PASSWORD=${SSH_PASSWORD:-}

echo "========================================"
echo "  Railway OpenCode + SSH Setup"
echo "========================================"
echo "OpenCode Port: $OPENCODE_PORT"
echo "SSH Port: $SSH_PORT"
echo "SSH Username: $SSH_USERNAME"
echo ""

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash 2>&1 | grep -i "successfully" || true
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

# Setup SSH - PASSWORD AUTH ONLY
echo ""
echo "🔐 Configuring SSH (password auth)..."

SSHD_CONFIG="/etc/ssh/sshd_config"
mkdir -p $(dirname "$SSHD_CONFIG")
mkdir -p /run/sshd

cat > "$SSHD_CONFIG" << SSHEOF
Port $SSH_PORT
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
UsePAM no
X11Forwarding no
PrintMotd no
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo "  Generating SSH host keys..."
  ssh-keygen -A
fi

# Set password for the user (from Railway Variables)
if [ -n "$SSH_PASSWORD" ]; then
  echo "root:$SSH_PASSWORD" | chpasswd
  echo "✓ Password set from SSH_PASSWORD variable"
else
  echo "⚠️  SSH_PASSWORD not set in Railway Variables — using fallback password: changeme123"
  echo "root:changeme123" | chpasswd
  SSH_PASSWORD="changeme123"
fi

pkill -9 sshd 2>/dev/null || true
sleep 1

echo "🚀 Starting SSH server on port $SSH_PORT..."
/usr/sbin/sshd -D -f "$SSHD_CONFIG" &
SSH_PID=$!
sleep 2

if ! kill -0 $SSH_PID 2>/dev/null; then
  echo "❌ SSH failed to start"
  exit 1
fi

echo "✓ SSH server running (PID: $SSH_PID)"

# Use the SAME username/password for OpenCode's HTTP Basic Auth
export OPENCODE_SERVER_USERNAME="$SSH_USERNAME"
export OPENCODE_SERVER_PASSWORD="$SSH_PASSWORD"

echo ""
echo "========================================"
echo "  🔑 ACCESS CREDENTIALS (same for both)"
echo "========================================"
echo "Username: $SSH_USERNAME"
echo "Password: $SSH_PASSWORD"
echo "========================================"
echo ""

echo "🚀 Starting OpenCode on port $OPENCODE_PORT..."
opencode web --port $OPENCODE_PORT --mdns &
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
echo "🌐 OpenCode: Check Railway dashboard for domain"
echo "   Login with Username/Password above"
echo ""
echo "🔑 SSH: Use Railway TCP Proxy (Settings → Networking)"
echo "   ssh $SSH_USERNAME@<proxy-domain> -p <proxy-port>"
echo "   Login with same Password above"
echo ""

wait

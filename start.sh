#!/bin/bash

set -e

PORT=${PORT:-8080}
SSH_PORT=${SSH_PORT:-2222}

# Variables from Railway dashboard (set these in Variables tab)
SSH_USERNAME=${SSH_USERNAME:-root}
SSH_PASSWORD=${SSH_PASSWORD:-}

echo "========================================"
echo "  Railway OpenCode + SSH Setup"
echo "========================================"
echo "OpenCode Port: $PORT"
echo "SSH Port: $SSH_PORT"
echo "SSH Username: $SSH_USERNAME"
echo ""

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash 2>&1 | grep -i "successfully" || true
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

# Setup SSH - BOTH key and password auth
echo ""
echo "🔐 Configuring SSH..."

SSHD_CONFIG="/etc/ssh/sshd_config"
mkdir -p $(dirname "$SSHD_CONFIG")
mkdir -p /run/sshd
mkdir -p /root/.ssh

cat > "$SSHD_CONFIG" << SSHEOF
Port $SSH_PORT
PermitRootLogin yes
PubkeyAuthentication yes
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

# Generate SSH keypair if not exists (persists only for this container life)
if [ ! -f /root/.ssh/id_rsa ]; then
  echo "  Generating SSH keypair..."
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
fi

# Set password for the user (from Railway Variables)
if [ -n "$SSH_PASSWORD" ]; then
  echo "root:$SSH_PASSWORD" | chpasswd
  echo "✓ Password set from SSH_PASSWORD variable"
else
  echo "⚠️  SSH_PASSWORD not set in Railway Variables - password login disabled"
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
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

# Display credentials clearly in logs
echo ""
echo "========================================"
echo "  🔑 SSH ACCESS CREDENTIALS"
echo "========================================"
echo ""
echo "── Username ──"
echo "$SSH_USERNAME"
echo ""
echo "── Password (if set in Variables) ──"
if [ -n "$SSH_PASSWORD" ]; then
  echo "(the value you set in SSH_PASSWORD variable)"
else
  echo "(not set — add SSH_PASSWORD in Railway Variables tab)"
fi
echo ""
echo "── Private Key (copy everything below, including BEGIN/END lines) ──"
cat /root/.ssh/id_rsa
echo ""
echo "========================================"
echo ""

# Start OpenCode
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
echo "🌐 OpenCode: Check Railway dashboard for domain"
echo "🔑 SSH: Use Railway TCP Proxy (Settings → Networking)"
echo "   Then: ssh $SSH_USERNAME@<proxy-domain> -p <proxy-port>"
echo ""

wait

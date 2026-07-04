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

if ! command -v opencode >/dev/null 2>&1; then
  echo "📥 Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash 2>&1 | grep -i "successfully" || true
  export PATH="$HOME/.opencode/bin:$PATH"
  echo "✓ OpenCode installed"
fi

# Setup SSH - KEY-BASED AUTH
echo ""
echo "🔐 Configuring SSH (Key-based auth)..."

SSHD_CONFIG="/etc/ssh/sshd_config"
mkdir -p $(dirname "$SSHD_CONFIG")
mkdir -p /run/sshd
mkdir -p /root/.ssh

cat > "$SSHD_CONFIG" << 'SSHEOF'
Port 2222
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM no
AuthenticationMethods publickey
X11Forwarding no
PrintMotd no
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo "  Generating SSH host keys..."
  ssh-keygen -A
fi

if [ ! -f /root/.ssh/id_rsa ]; then
  echo "  Generating SSH keypair for root..."
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
fi

echo ""
echo "📋 Your SSH Private Key (save this!):"
echo "========================================"
cat /root/.ssh/id_rsa
echo "========================================"
echo ""

cp /root/.ssh/id_rsa /tmp/railway_ssh_key.txt

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
echo "  Services Ready - Railway Proxy Mode"
echo "========================================"
echo ""
echo "🌐 OpenCode:"
echo "  URL: Check Railway dashboard (main domain)"
echo ""
echo "🔑 SSH Terminal:"
echo "  Use Railway TCP Proxy for port $SSH_PORT"
echo "  Check Railway → Settings → Networking → TCP Proxy"
echo "  Add port: $SSH_PORT"
echo ""
echo "📋 Connect via Termius:"
echo "  Host: (Railway TCP proxy domain, e.g. xxx.proxy.rlwy.net)"
echo "  Port: (Railway TCP proxy port)"
echo "  Username: root"
echo "  Auth: Private Key (shown above, or from /tmp/railway_ssh_key.txt)"
echo ""

wait

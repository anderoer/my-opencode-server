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

# Setup SSH - KEY-BASED AUTH (NO PASSWORD)
echo ""
echo "🔐 Configuring SSH (Key-based auth)..."

SSHD_CONFIG="/etc/ssh/sshd_config"
mkdir -p $(dirname "$SSHD_CONFIG")
mkdir -p /run/sshd
mkdir -p /root/.ssh

# Create SSH config - KEY AUTH ONLY
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

# Generate host keys
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo "  Generating SSH host keys..."
  ssh-keygen -A
fi

# Create SSH key for root
if [ ! -f /root/.ssh/id_rsa ]; then
  echo "  Generating SSH keypair for root..."
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
fi

# Display public key
echo ""
echo "📋 Your SSH Public Key:"
echo "========================================"
cat /root/.ssh/id_rsa.pub
echo "========================================"
echo ""

# Save keys to file for easy access
cp /root/.ssh/id_rsa /tmp/railway_ssh_key.txt
echo "✓ Keys generated and saved"

# Kill existing sshd
pkill -9 sshd 2>/dev/null || true
sleep 1

# Start SSH
echo "🚀 Starting SSH server on port $SSH_PORT..."

/usr/sbin/sshd -D -f "$SSHD_CONFIG" &
SSH_PID=$!

sleep 2

if ! kill -0 $SSH_PID 2>/dev/null; then
  echo "❌ SSH failed to start"
  /usr/sbin/sshd -f "$SSHD_CONFIG" -t 2>&1 || true
  exit 1
fi

echo "✓ SSH server running (PID: $SSH_PID)"
echo "  Port: $SSH_PORT"
echo "  Auth: SSH Keys (no password)"

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
echo "  Check Railway dashboard"
echo ""
echo "🔑 SSH Terminal (SSH Key Auth):"
echo "  Port: $SSH_PORT"
echo "  Auth: SSH Public Key (no password!)"
echo ""
echo "📋 Connection Steps:"
echo "  1. Download private key:"
echo "     railway shell"
echo "     cat /tmp/railway_ssh_key.txt > ~/.ssh/railway_key"
echo "     chmod 600 ~/.ssh/railway_key"
echo ""
echo "  2. Local bore tunnel:"
echo "     ./bore local --to bore.pub $SSH_PORT"
echo ""
echo "  3. SSH command:"
echo "     ssh -i ~/.ssh/railway_key -p BORE_PORT root@bore.pub"
echo ""
echo "  4. Or use Termius with key auth"
echo ""

wait

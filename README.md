# OpenCode Server with Bore Tunnel

Run OpenCode IDE with public access via Bore tunnel on Railway.

## Features

- ✅ OpenCode Web IDE
- ✅ Automatic Bore tunnel to bore.pub
- ✅ Auto-restart on crash
- ✅ Health checks
- ✅ Ubuntu 22.04 base

## Quick Deploy to Railway

1. Fork/Clone this repository
2. Push to GitHub
3. Go to [Railway.app](https://railway.app)
4. Create New Project → Deploy from GitHub
5. Select your repository
6. Railway auto-detects Dockerfile and deploys

## Environment Variables

```bash
# Set custom OpenCode password (optional)
OPENCODE_SERVER_PASSWORD=your_secure_password

# Bore server (default: bore.pub)
BORE_SERVER=bore.pub
```

## Access

After deployment, Railway will show you the tunnel details in logs:

```
Bore Tunnel: bore.pub:XXXXX
Access: http://bore.pub:XXXXX
```

## Local Testing

```bash
# Build image
docker build -t opencode-server .

# Run container
docker run -p 2222:2222 -e OPENCODE_SERVER_PASSWORD=test123 opencode-server

# Access: http://localhost:2222
```

## Manual Setup (without Railway)

```bash
# Install dependencies
apt update && apt install -y nodejs npm wget

# Install opencode
npm install -g opencode

# Download bore
mkdir -p ~/tools && cd ~/tools
wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz
chmod +x bore

# Run
opencode web --port 2222 &
./bore local --to bore.pub 2222
```

## Architecture

```
Client Browser
     ↓
Bore Tunnel (bore.pub:XXXXX)
     ↓
Railway Container
     ├─ OpenCode Web (port 2222)
     └─ Bore Client (tunnel)
```

## Troubleshooting

### OpenCode not responding
```bash
# Check logs
railway logs

# Restart
railway shell
pkill -9 opencode
```

### Bore tunnel disconnected
```bash
# Reconnect
./bore local --to bore.pub 2222
```

### Port already in use
Change port in `start.sh` and Dockerfile EXPOSE

## License

MIT

## Support

Issues? Check:
- [OpenCode Docs](https://mimo.xiaomi.com)
- [Bore GitHub](https://github.com/ekzhang/bore)
- [Railway Docs](https://docs.railway.app)

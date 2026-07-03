FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Railway environment
ENV RAILWAY_ENVIRONMENT=production

# Update and install dependencies
RUN apt update && apt install -y \
    curl \
    wget \
    git \
    nano \
    vim \
    openssh-server \
    openssh-client \
    build-essential \
    nodejs \
    npm

# Create working directory
RUN mkdir -p /app
WORKDIR /app

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Railway auto-assigns PORT env var
# Default to 2222 if PORT not set
ENV PORT=${PORT:-2222}

# Expose dynamic port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD pgrep -f opencode || exit 1

# Run startup script
CMD ["/app/start.sh"]

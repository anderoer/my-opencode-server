FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt update && apt install -y \
    curl \
    wget \
    git \
    build-essential \
    nodejs \
    npm \
    nano \
    vim \
    openssh-server \
    openssh-client

# Install opencode globally
RUN npm install -g opencode

# Create tools directory
RUN mkdir -p /tools && cd /tools

# Download and setup bore
RUN cd /tools && \
    wget https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz && \
    rm bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz && \
    chmod +x bore

# Create startup script
RUN mkdir -p /app
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 2222

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f opencode || exit 1

# Run startup script
CMD ["/app/start.sh"]

FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

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

# Expose ports
EXPOSE 2222 22

# Run startup script
CMD ["/app/start.sh"]

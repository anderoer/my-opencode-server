FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl wget git nano vim \
    openssh-server openssh-client \
    build-essential nodejs npm

RUN mkdir -p /app
WORKDIR /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Listen on Railway PORT (auto-detected from PORT env var)
# Default to 2222 if PORT not set
ENV PORT=${PORT:-2222}
EXPOSE ${PORT}

CMD ["/app/start.sh"]

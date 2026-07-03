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

# Listen on port specified by Railway (default 2222)
ENV OPENCODE_PORT=${OPENCODE_PORT:-2222}
EXPOSE 2222

CMD ["/app/start.sh"]

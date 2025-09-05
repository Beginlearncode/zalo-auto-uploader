FROM mcr.microsoft.com/playwright:v1.46.0-jammy

# ===== 0) APT: ép IPv4 + mirror nhanh + retry =====
ARG DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.edge.kernel.org/ubuntu|g' /etc/apt/sources.list
RUN bash -lc 'for i in {1..5}; do \
      apt-get update -o Acquire::ForceIPv4=true && break || (echo "apt update retry $i" && sleep 5); \
    done'

# ===== 1) Xvfb + x11vnc + fluxbox + noVNC (websockify) =====
RUN apt-get install -y --no-install-recommends \
      xvfb x11vnc net-tools python3 python3-pip curl unzip fluxbox \
  && pip3 install --no-cache-dir websockify \
  && rm -rf /var/lib/apt/lists/*

# Tải noVNC để phục vụ web static
RUN mkdir -p /opt/novnc && \
    curl -L -o /opt/novnc.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    unzip /opt/novnc.zip -d /opt && mv /opt/noVNC-master /opt/novnc && rm /opt/novnc.zip

# ===== 2) App =====
WORKDIR /app

# Cấu hình NPM an toàn khi build
ENV npm_config_loglevel=warn \
    npm_config_audit=false \
    npm_config_fund=false \
    npm_config_progress=false \
    npm_config_legacy_peer_deps=true \
    npm_config_fetch_retries=5 \
    npm_config_fetch_retry_fa

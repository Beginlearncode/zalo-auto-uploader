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

# Tải noVNC (chỉ để phục vụ web client tĩnh)
RUN mkdir -p /opt/novnc && \
    curl -L -o /opt/novnc.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    unzip /opt/novnc.zip -d /opt && mv /opt/noVNC-master /opt/novnc && rm /opt/novnc.zip

# ===== 2) App =====
WORKDIR /app

# Cấu hình NPM an toàn khi build (mỗi biến 1 dòng để tránh lỗi)
ENV npm_config_loglevel=warn
ENV npm_config_audit=false
ENV npm_config_fund=false
ENV npm_config_progress=false
ENV npm_config_legacy_peer_deps=true
ENV npm_config_fetch_retries=5
ENV npm_config_fetch_retry_factor=2
ENV npm_config_fetch_retry_maxtimeout=120000
ENV npm_config_fetch_retry_mintimeout=20000

# Cài deps (ưu tiên lockfile; có retry)
COPY package.json package-lock.json* ./
RUN npm config set registry https://registry.npmjs.org/ \
 && bash -lc 'for i in {1..5}; do \
        if [ -f package-lock.json ]; then \
          npm ci --ignore-scripts && break; \
        else \
          npm install --ignore-scripts --omit=dev --no-audit --no-fund && break; \
        fi; \
        echo "npm install retry $i"; sleep 8; \
      done' \
 && npm cache clean --force

# Copy phần còn lại
COPY . .

# Xử lý CRLF & cấp quyền
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Không tải lại browser (base image đã có)
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV NODE_ENV=production
ENV DISPLAY=:99

# Start Xvfb + websockify(noVNC) + app
CMD ["sh", "start.sh"]

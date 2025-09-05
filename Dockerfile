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

RUN mkdir -p /opt/novnc && \
    curl -L -o /opt/novnc.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    unzip /opt/novnc.zip -d /opt && mv /opt/noVNC-master /opt/novnc && rm /opt/novnc.zip

# ===== 2) App =====
WORKDIR /app

# Cài deps (ổn định, không chạy postinstall)
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then \
      npm ci --ignore-scripts; \
    else \
      npm install --ignore-scripts --omit=dev --no-audit --no-fund; \
    fi

# Copy phần còn lại
COPY . .

# Cho phép script chạy
RUN chmod +x start.sh

# Base image đã có trình duyệt → bỏ qua tải lại
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV NODE_ENV=production
ENV DISPLAY=:99

# Render map $PORT; start.sh khởi động Xvfb + noVNC + app
CMD ["sh", "start.sh"]

FROM mcr.microsoft.com/playwright:v1.46.0-jammy

# =========================
# 0) Sửa mạng cho APT (ép IPv4 + mirror nhanh + retry)
# =========================
ARG DEBIAN_FRONTEND=noninteractive
# đổi mirror để tránh archive.ubuntu.com chậm/IPv6
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.edge.kernel.org/ubuntu|g' /etc/apt/sources.list

# update có retry và ép IPv4
RUN bash -lc 'for i in {1..5}; do \
      apt-get update -o Acquire::ForceIPv4=true && break || (echo "apt update retry $i" && sleep 5); \
    done'

# =========================
# 1) Cài Xvfb + x11vnc + fluxbox + noVNC (websockify)
# =========================
RUN apt-get install -y --no-install-recommends \
      xvfb x11vnc net-tools python3 python3-pip curl unzip fluxbox \
    && pip3 install --no-cache-dir websockify \
    && rm -rf /var/lib/apt/lists/*

# noVNC
RUN mkdir -p /opt/novnc && \
    curl -L -o /opt/novnc.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    unzip /opt/novnc.zip -d /opt && mv /opt/noVNC-master /opt/novnc && rm /opt/novnc.zip

# =========================
# 2) Ứng dụng
# =========================
WORKDIR /app
COPY . .

RUN npm install
RUN chmod +x start.sh

ENV NODE_ENV=production
ENV DISPLAY=:99

# Render sẽ map $PORT; start.sh sẽ forward noVNC vào $PORT
CMD ["sh", "start.sh"]

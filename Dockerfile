FROM mcr.microsoft.com/playwright:v1.46.0-jammy

# Cài Xvfb (màn hình ảo), x11vnc (VNC server), fluxbox (WM), noVNC (VNC qua web)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc net-tools python3 python3-pip curl unzip fluxbox \
  && pip3 install websockify \
  && rm -rf /var/lib/apt/lists/*

# Tải noVNC
RUN mkdir -p /opt/novnc && \
    curl -L -o /opt/novnc.zip https://github.com/novnc/noVNC/archive/refs/heads/master.zip && \
    unzip /opt/novnc.zip -d /opt && mv /opt/noVNC-master /opt/novnc && rm /opt/novnc.zip

WORKDIR /app

# Copy code
COPY . .

# Cài deps
RUN npm install

# Cho phép start.sh thực thi
RUN chmod +x start.sh

# Biến mặc định
ENV NODE_ENV=production
ENV DISPLAY=:99

# Chạy app (script sẽ khởi động Xvfb + noVNC + Node)
CMD ["sh", "start.sh"]

#!/usr/bin/env bash
set -e

# --- Dọn lock cũ nếu có (tránh "Server is already active for display :99")
rm -f /tmp/.X99-lock || true
rm -f /tmp/.X11-unix/X99 || true
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 1) Màn hình ảo Xvfb
Xvfb ${DISPLAY} -screen 0 1280x800x24 -ac +extension RANDR &
XVFB_PID=$!

# Chờ Xvfb sẵn sàng
for i in $(seq 1 20); do
  if [ -e "/tmp/.X11-unix/X99" ] || netstat -an 2>/dev/null | grep -q 'tmp/.X11-unix/X99'; then
    echo "Xvfb is ready"; break
  fi
  echo "Waiting Xvfb... ($i)"; sleep 0.5
done

# 2) Window manager nhẹ
fluxbox &

# 3) VNC server trên 5901
if [ -n "${VNC_PASSWORD}" ]; then
  x11vnc -display ${DISPLAY} -forever -shared -rfbport 5901 -passwd ${VNC_PASSWORD} &
else
  x11vnc -display ${DISPLAY} -forever -shared -rfbport 5901 -nopw &
fi

# 4) noVNC qua websockify (không dùng novnc_proxy nữa)
#    Expose web client ở $PORT (Render yêu cầu), trỏ đến VNC 5901
websockify --web /opt/novnc ${PORT:-8080} localhost:5901 &

# 5) Chạy app Node
exec npm start

#!/usr/bin/env bash
set -e

# 1) Màn hình ảo
Xvfb ${DISPLAY} -screen 0 1280x800x24 -ac +extension RANDR &

# 2) Window manager nhẹ
fluxbox &

# 3) VNC server (5901)
if [ -n "${VNC_PASSWORD}" ]; then
  x11vnc -display ${DISPLAY} -forever -shared -rfbport 5901 -passwd ${VNC_PASSWORD} &
else
  x11vnc -display ${DISPLAY} -forever -shared -rfbport 5901 -nopw &
fi

# 4) noVNC: map $PORT (Render yêu cầu) -> 5901
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen ${PORT:-8080} &

# 5) Chạy app Node
npm start

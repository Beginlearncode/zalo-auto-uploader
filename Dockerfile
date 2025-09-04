FROM mcr.microsoft.com/playwright:v1.46.0-jammy

# Đặt thư mục làm việc trong container
WORKDIR /app

# Copy toàn bộ code từ repo vào container
COPY . .

# Cài dependencies cho Node.js
RUN npm install

# Cho phép script start.sh được chạy
RUN chmod +x start.sh

# Chạy app (dùng start.sh để boot node index.js)
CMD ["sh", "start.sh"]

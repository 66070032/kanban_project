FROM node:20-alpine

# สร้างโฟลเดอร์ทำงาน
WORKDIR /app

# ก๊อปปี้ไฟล์ package.json เพื่อลง dependencies
COPY package*.json ./
RUN npm install

# ก๊อปปี้โค้ดทั้งหมด
COPY . .

# Express มักใช้ Port 3000
EXPOSE 3000

CMD ["node", "src/app.js"]
# 📱 Voice-based Task Manager with Smart Notification

## 📌 Project Overview

โปรเจคนี้เป็นแอพ ที่ออกแบบมาเพื่อแก้ปัญหาการสั่งงานและการเตือนงานที่มักถูกมองข้าม

จุดเด่นของแอพคือการใช้ **เสียงอัดแทนการพิมพ์คำสั่งงาน**  
และการแจ้งเตือนแบบ **จำลองสายเรียกเข้า (Simulated Incoming Call)**  
เพื่อดึงความสนใจของผู้รับงานได้มากกว่าการแจ้งเตือนแบบข้อความทั่วไป

แอพพัฒนาด้วย Flutter และ Firebase โดยเน้นการใช้งานจริง  
เหมาะสำหรับนักศึกษาและกลุ่มเพื่อนที่ทำงานร่วมกัน

---

## 🎯 Problem Statement

- การสั่งงานด้วยข้อความยาวทำให้สื่อสารไม่ชัดเจน
- Notification แบบตัวอักษรถูกมองข้ามได้ง่าย
- การทวงงานขาดความรู้สึกและน้ำหนักในการเตือน

แอพนี้จึงนำ “เสียงของคนสั่งงาน” มาใช้เป็นตัวกลาง  
เพื่อเพิ่มประสิทธิภาพและความเป็นมนุษย์ในการเตือนงาน

---

## 👥 Target Users

- นักเรียน / นักศึกษาที่ทำงานกลุ่ม
- กลุ่มเพื่อนหรือทีมขนาดเล็ก (2–6 คน)
- ผู้ใช้ที่ตอบสนองต่อเสียงของคนรู้จักได้ดีกว่าข้อความ

---

## 🚀 Features

### ✅ Core Features (MVP)

- **User Authentication**
  - Login / Register ด้วย Email
- **Task Management**
  - สร้าง แก้ไข ลบ Task
  - กำหนดวัน–เวลาส่ง
  - สถานะ Todo / Doing / Done
- **Voice Instruction**
  - อัดเสียงคำสั่งงานแทนการพิมพ์
  - ฟังซ้ำได้ในหน้า Task detail
- **Voice Reminder**
  - อัดเสียงเตือนหรือทวงงาน
  - ผูกเสียงกับ Task แต่ละงาน
- **Local Notification**
  - แจ้งเตือนตรงตามเวลา
  - ทำงานได้แม้แอพถูกปิดหรือหน้าจอล็อก
- **Simulated Incoming Call Notification**
  - แจ้งเตือนในรูปแบบหน้าจอสายเรียกเข้า
  - แสดงชื่อและรูปโปรไฟล์ผู้สั่งงาน
- **Call Action**
  - รับสาย → เล่นเสียงเตือน
  - วางสาย → Snooze และเตือนซ้ำภายหลัง

---

### ⭐ Nice-to-have Features

- Room / Group สำหรับทำงานร่วมกัน
- Repeat Task (รายวัน / รายสัปดาห์)
- Task History
- Preset Voice สำหรับผู้ที่ไม่ต้องการอัดเสียงเอง
- Kanban แบบลากเปลี่ยนสถานะ
- Sync ข้อมูลข้ามอุปกรณ์

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Dart) + Riverpod (state management)
- **Backend:** Node.js / Express.js REST API
- **Database:** PostgreSQL (hosted at `https://kanban.jokeped.xyz`)
- **Audio**
  - Recording: `record`
  - Playback: `just_audio`
- **Notification**
  - `flutter_local_notifications`
  - `flutter_callkit_incoming` (Simulated Call)

---

## 🧱 System Architecture (High Level)

- **Frontend (Flutter)** — UI layer using Riverpod providers for reactive state
- **Service Layer** — Handles all HTTP API calls (`task_service`, `user_service`, etc.)
- **Backend REST API** — Express.js server at `https://kanban.jokeped.xyz`
- **Database** — PostgreSQL stores users, tasks, reminders, groups
- Voice files are uploaded as multipart form-data and the path stored in the task record
- Local Notifications trigger at Due Date/Time using `flutter_local_notifications`

---

## 🚀 Setup & Running

### Prerequisites

- Flutter SDK ≥ 3.10
- A device/emulator (Android or iOS)
- Internet connection (API is hosted)

### Run the Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

The app connects to the live backend at `https://kanban.jokeped.xyz` automatically.

### Backend (optional local setup)

```bash
cd backend
npm install
# Set DATABASE_URL in .env
npm start
```

---

## 📦 Project Scope

**Focus**

- Task Management
- Voice-based Interaction
- Smart Notification

**Out of Scope**

- Chat แบบ real-time
- Social feed

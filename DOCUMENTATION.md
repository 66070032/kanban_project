# 📋 เอกสารประกอบโปรเจกต์ Kanban Voice Task Manager

## สารบัญ

1. [ภาพรวมของโปรเจกต์](#1-ภาพรวมของโปรเจกต์)
2. [สถาปัตยกรรมระบบ](#2-สถาปัตยกรรมระบบ)
3. [ฟีเจอร์หลัก (Core Features)](#3-ฟีเจอร์หลัก-core-features)
4. [ฟีเจอร์เด่น (Cool Features)](#4-ฟีเจอร์เด่น-cool-features)
5. [โค้ดส่วนสำคัญ (Crucial Code)](#5-โค้ดส่วนสำคัญ-crucial-code)
6. [API Endpoints ทั้งหมด](#6-api-endpoints-ทั้งหมด)
7. [โครงสร้างฐานข้อมูล](#7-โครงสร้างฐานข้อมูล)
8. [โครงสร้างไฟล์](#8-โครงสร้างไฟล์)
9. [เทคโนโลยีที่ใช้](#9-เทคโนโลยีที่ใช้)
10. [วิธีรันโปรเจกต์](#10-วิธีรันโปรเจกต์)

---

## 1. ภาพรวมของโปรเจกต์

**Kanban Voice Task Manager** เป็นแอปพลิเคชัน Mobile สำหรับจัดการงาน (Task Management) ที่รองรับทั้งการทำงานส่วนตัวและการทำงานเป็นทีม พร้อมระบบบันทึกเสียง (Voice Recording) เพื่อแนบคำสั่งเสียงกับงาน และระบบแจ้งเตือน (Notification) แบบ Incoming Call

- **Frontend**: Flutter (Dart) + Riverpod State Management
- **Backend**: Express.js + PostgreSQL
- **API**: RESTful API จำนวน 25+ endpoints
- **Deploy**: https://kanban.jokeped.xyz

---

## 2. สถาปัตยกรรมระบบ

### Frontend — สถาปัตยกรรมแบบ 3 ชั้น

```
┌─────────────────────────────────────────┐
│            UI Layer (Widgets)           │  ← หน้าจอ, Widget ต่าง ๆ
├─────────────────────────────────────────┤
│         Provider Layer (Riverpod)       │  ← จัดการ State, AsyncValue
├─────────────────────────────────────────┤
│          Service Layer (HTTP)           │  ← เรียก API, Business Logic
└─────────────────────────────────────────┘
```

1. **Service Layer** — รับผิดชอบเรียก API และจัดการ Business Logic (8 services)
2. **Provider Layer** — จัดการ State ด้วย Riverpod โดยใช้ `FutureProvider`, `AsyncNotifier`
3. **UI Layer** — Widget ที่ consume providers เพื่อแสดงผลแบบ Reactive

### Backend — Express.js + PostgreSQL

```
┌─────────────────────────────────────────┐
│           Express.js Server             │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐  │
│  │ Routes  │→│Controller│→│   DB    │  │
│  └─────────┘ └──────────┘ └─────────┘  │
│       ↑                                 │
│  ┌─────────┐                            │
│  │Middleware│ (Multer, CORS, Morgan)    │
│  └─────────┘                            │
└─────────────────────────────────────────┘
```

---

## 3. ฟีเจอร์หลัก (Core Features)

### 3.1 ระบบสมัครสมาชิกและเข้าสู่ระบบ (Authentication)

- ลงทะเบียนด้วย Email, ชื่อที่แสดง, รหัสผ่าน
- เข้าสู่ระบบด้วย Email + Password
- รหัสผ่านเข้ารหัสด้วย **bcrypt** (hash + salt)
- ตรวจสอบอีเมลซ้ำ (unique constraint)
- ไม่ส่งรหัสผ่านกลับไปที่ client

**โค้ดสำคัญ (Backend — auth.controller.js):**
```javascript
// การ Login — ตรวจสอบรหัสผ่านด้วย bcrypt
exports.login = async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
  const isMatch = await bcrypt.compare(password, user.password);
  // ส่งข้อมูลผู้ใช้กลับ (ไม่รวม password)
  const { password: _, ...userWithoutPassword } = user;
  res.json({ message: "Login successful", user: userWithoutPassword });
};

// การ Register — เข้ารหัสรหัสผ่านก่อนบันทึก
exports.register = async (req, res) => {
  const passwordHash = await bcrypt.hash(password, 10);
  await pool.query(
    `INSERT INTO users (email, display_name, password) VALUES ($1, $2, $3)`,
    [email, name, passwordHash]
  );
};
```

**โค้ดสำคัญ (Frontend — auth_gate.dart):**
```dart
// AuthGate ควบคุมการเข้าถึง — ถ้าไม่ได้ login จะเห็นหน้า Login
class AuthGate extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const LoginPage();
    return const MainWrapper();
  }
}
```

### 3.2 ระบบจัดการงาน (Task Management — CRUD)

- **สร้างงาน (Create)** — กรอกชื่อ, คำอธิบาย, กำหนดส่ง, สถานะ, แนบเสียง
- **ดูงาน (Read)** — ดูรายการงานทั้งหมด กรองตามสถานะ (To Do / Doing / Done)
- **แก้ไขงาน (Update)** — เปลี่ยนสถานะ, แก้ไขรายละเอียด
- **ลบงาน (Delete)** — ลบงานที่ไม่ต้องการ

**โค้ดสำคัญ (Backend — task.controller.js):**
```javascript
// สร้าง Task
exports.createTask = async (req, res) => {
  const { title, description, assignee_id, status, due_at } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO tasks (title, description, assignee_id, status, due_at)
     VALUES ($1, $2, $3, COALESCE($4, 'todo'), $5) RETURNING *`,
    [title, description, assignee_id, status, due_at || null]
  );
  res.status(201).json(rows[0]);
};

// ดึง Tasks พร้อม JOIN ชื่อผู้รับผิดชอบ
exports.getTasks = async (req, res) => {
  const { rows } = await pool.query(`
    SELECT t.*, u.display_name as assignee_name, g.name as group_name
    FROM tasks t
    LEFT JOIN users u ON t.assignee_id = u.id
    LEFT JOIN "groups" g ON t.group_id = g.id
    ORDER BY t.created_at DESC
  `);
  res.json(rows);
};
```

**โค้ดสำคัญ (Frontend — task_provider.dart):**
```dart
// Provider สำหรับดึง Tasks ของผู้ใช้
final userTasksProvider = FutureProvider.family<List<Task>, String>((ref, userId) async {
  return TaskService.getTasksByAssignee(userId);
});

// Notifier สำหรับ create/update/delete
class TasksNotifier extends AsyncNotifier<List<Task>> {
  Future<Task?> createTask({required String title, ...}) async {
    final task = await TaskService.createTask(title: title, ...);
    ref.invalidateSelf(); // รีเฟรชรายการ
    return task;
  }
}
```

### 3.3 ระบบปฏิทิน (Calendar)

- แสดงปฏิทินรายเดือนพร้อมจุดบอกว่ามีงานวันไหน
- กดวันที่เพื่อดูรายการงานที่ครบกำหนดวันนั้น
- ใช้สี่แยกตามสถานะ:
  - 🟢 สีเขียว = เสร็จแล้ว (done)
  - 🟠 สีส้ม = กำลังทำ (doing)
  - 🔵 สีฟ้า = ยังไม่ทำ (todo)

### 3.4 ระบบ Reminder (แจ้งเตือน)

- สร้าง Reminder พร้อมวันที่/เวลาที่ต้องการแจ้งเตือน
- ระบบตั้ง Local Notification อัตโนมัติเมื่อถึงเวลา
- รองรับ CRUD (สร้าง, ดู, แก้ไข, ลบ)

**โค้ดสำคัญ (Frontend — notification_service.dart):**
```dart
class NotificationService {
  // ตั้งเวลาแจ้งเตือนล่วงหน้า
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
```

### 3.5 โปรไฟล์และตั้งค่า (Profile & Settings)

- แก้ไขชื่อที่แสดง
- อัปโหลดรูปโปรไฟล์ (Avatar)
- เปลี่ยนรหัสผ่าน (ต้องใส่รหัสเดิมก่อน)
- ตั้งค่าการแจ้งเตือน (เปิด/ปิดเสียง, สั่น)
- Logout

---

## 4. ฟีเจอร์เด่น (Cool Features)

### 4.1 🎙️ บันทึกเสียงแนบกับงาน (Voice Instructions)

ฟีเจอร์ที่โดดเด่นที่สุดของแอป — สามารถบันทึกเสียงคำสั่งแนบไปกับงานได้

**ขั้นตอนการทำงาน:**
1. กดปุ่มบันทึกเสียงบนหน้าสร้าง/ดูงาน
2. บันทึกเสียงจากไมโครโฟนจริง → ไฟล์ .m4a
3. อัปโหลดไฟล์เสียงผ่าน Multipart API → เก็บใน server ด้วยชื่อ UUID
4. เปิดฟังเสียงกลับมาได้ พร้อม Play/Pause/Seek

**โค้ดสำคัญ (Frontend — audio_recording_service.dart):**
```dart
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String> startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) throw Exception('Microphone permission denied');
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );
    return path;
  }
}
```

**โค้ดสำคัญ (Backend — multer middleware):**
```javascript
// รับไฟล์เสียงผ่าน Multer พร้อม validate ประเภทไฟล์
const upload = multer({
  storage: multer.diskStorage({
    destination: './uploads',
    filename: (req, file, cb) => cb(null, `${uuidv4()}_${Date.now()}.m4a`)
  }),
  fileFilter: (req, file, cb) => {
    // รองรับ: .m4a, .mp3, .wav, .aac, .ogg, .flac
  }
});
```

**โค้ดสำคัญ (Backend — อัปโหลด voice instruction):**
```javascript
exports.uploadVoiceInstruction = async (req, res) => {
  const { id } = req.params;
  const uuid = req.file.filename;
  await pool.query(
    "UPDATE tasks SET voice_instruction_uuid = $1 WHERE id = $2",
    [uuid, id]
  );
  res.json({ url: `/uploads/${uuid}` });
};
```

### 4.2 📞 หน้าจอ Incoming Call สำหรับแจ้งเตือน

เมื่อถึงเวลาที่ตั้ง Reminder ไว้ แอปจะแสดงหน้าจอเหมือนมีสายเข้า (Incoming Call) พร้อม Animation

**คุณสมบัติ:**
- Avatar ขนาดใหญ่พร้อม **Pulse Animation** (เต้นตามจังหวะ)
- แสดงชื่อผู้ส่งและหัวข้องาน
- นับถอยหลัง 30 วินาที — ถ้าไม่ตอบจะ auto-reject
- ปุ่ม ❌ ปฏิเสธ (แดง) และ ✅ รับ (เขียว)

**โค้ดสำคัญ (Frontend — incoming_call_screen.dart):**
```dart
class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String taskTitle;
  final Function onAccept;
  final Function onReject;
  final Duration autoRejectAfter; // ค่าเริ่มต้น 30 วินาที

  // Animation Controller สำหรับ Pulse Effect
  _pulseController = AnimationController(
    vsync: this, duration: Duration(seconds: 1),
  )..repeat(reverse: true);

  // นับถอยหลัง Auto Reject
  _countdownController = AnimationController(
    vsync: this, duration: widget.autoRejectAfter,
  )..forward();
}
```

**การเชื่อมต่อกับ Notification (main.dart):**
```dart
NotificationService.onNotificationTap = (payload) {
  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (_) => IncomingCallScreen(
      callerId: 'reminder',
      callerName: 'Task Reminder',
      taskTitle: payload ?? 'You have a task reminder!',
      onAccept: () => navigatorKey.currentState?.pop(),
      onReject: () => navigatorKey.currentState?.pop(),
    ),
  ));
};
```

### 4.3 💬 Group Chat พร้อมสร้างงานในแชท

ระบบแชทกลุ่มที่สามารถสร้างงานและส่งเป็นข้อความในกลุ่มได้

**คุณสมบัติ:**
- สร้างกลุ่ม พร้อมเพิ่ม/ลบสมาชิก
- ค้นหาผู้ใช้เพื่อเพิ่มเข้ากลุ่ม
- ส่งข้อความแบบทั่วไป (text) และแบบงาน (task)
- เมื่อสร้างงานในกลุ่ม → งานถูกบันทึกในระบบ + ส่งข้อความแจ้งในแชทอัตโนมัติ
- มอบหมายงานให้สมาชิกในกลุ่มได้
- แสดง Task Card ในแชท พร้อมลิงก์ไปหน้ารายละเอียด
- ดูรายการงานทั้งหมดของกลุ่ม (Group Tasks Panel)
- Poll ข้อความใหม่ทุก 5 วินาที (real-time feel)
- Cursor-based pagination สำหรับข้อความ

**โค้ดสำคัญ (Backend — สร้าง Task + Message ในกลุ่ม):**
```javascript
exports.sendTaskMessage = async (req, res) => {
  const client = await pool.connect();
  await client.query("BEGIN");

  // 1. สร้าง Task เชื่อมกับ Group
  const taskResult = await client.query(
    `INSERT INTO tasks (title, description, assignee_id, status, due_at, group_id)
     VALUES ($1, $2, $3, 'todo', $4, $5) RETURNING *`,
    [title, description, assignee_id, due_at, groupId]
  );

  // 2. สร้างข้อความประเภท 'task' ในกลุ่ม
  await client.query(
    `INSERT INTO messages (group_id, sender_id, content, message_type, task_id)
     VALUES ($1, $2, $3, 'task', $4)`,
    [groupId, senderId, messageContent, task.id]
  );

  await client.query("COMMIT");
  // ใช้ Transaction เพื่อกรณีเกิด Error จะ Rollback ทั้งหมด
};
```

### 4.4 📊 Dashboard แบบ Kanban Board

- แสดงงานทั้งหมดแยกตามสถานะ (To Do / Doing / Done)
- Tab filtering — กดเลือกดูเฉพาะสถานะที่ต้องการ
- Pull-to-refresh — ดึงลงเพื่อรีเฟรชข้อมูล
- แสดงสถิติจำนวนงานทั้งหมด
- คลิกงานเพื่อไปหน้ารายละเอียด

### 4.5 🔄 State Management ด้วย Riverpod + AsyncValue

ใช้ Riverpod สำหรับจัดการ State ทั้งหมด พร้อมรองรับ 3 สถานะอัตโนมัติ:
- `loading` → แสดง Loading Spinner
- `error` → แสดงข้อผิดพลาด
- `data` → แสดงข้อมูล

```dart
// ใช้ .when() เพื่อจัดการทุกสถานะ
tasksAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (err, _) => Text('เกิดข้อผิดพลาด'),
  data: (tasks) => ListView.builder(itemCount: tasks.length, ...),
);
```

---

## 5. โค้ดส่วนสำคัญ (Crucial Code)

### 5.1 Data Models (แบบจำลองข้อมูล)

```dart
// Task Model — โมเดลงาน
class Task {
  final int id;
  final String title;
  final String? description;
  final String? status;          // 'todo' | 'doing' | 'done'
  final String? assigneeId;      // ผู้รับผิดชอบ
  final String? assigneeName;
  final int? groupId;            // กลุ่มที่งานสังกัด
  final DateTime? dueAt;         // กำหนดส่ง
  final String? voiceInstructionUrl; // ลิงก์ไฟล์เสียง

  factory Task.fromJson(Map<String, dynamic> json) { ... }
  bool get isFromGroup => groupId != null;
}

// User Model — โมเดลผู้ใช้
class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
}

// Reminder Model — โมเดลการแจ้งเตือน
class Reminder {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
}

// ChatMessage Model — โมเดลข้อความในกลุ่ม
class ChatMessage {
  final int id;
  final int groupId;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType;  // 'text' | 'task'
  final int? taskId;         // ลิงก์ไปงาน (ถ้าเป็นประเภท task)
}
```

### 5.2 ระบบ Navigation หลัก

```dart
// main_wrapper.dart — Bottom Navigation 4 หน้า
class MainWrapper extends StatefulWidget {
  final List<Widget> _pages = [
    const DashboardPage(),  // 🏠 หน้าหลัก
    const CalendarPage(),   // 📅 ปฏิทิน
    const GroupPage(),      // 💬 กลุ่มแชท
    const ProfilePage(),    // 👤 โปรไฟล์
  ];
}
```

### 5.3 API Service (ศูนย์กลางเรียก API)

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  static String get baseUrl => AppConfig.baseUrl;

  Future<dynamic> get(String path) async { ... }
  Future<dynamic> post(String path, Map<String, dynamic> body) async { ... }
  Future<dynamic> put(String path, Map<String, dynamic> body) async { ... }
  Future<dynamic> delete(String path) async { ... }
  Future<dynamic> upload(String path, File file, String field) async { ... }
}
```

### 5.4 Backend Middleware — Multer (อัปโหลดไฟล์)

```javascript
// รองรับไฟล์เสียงหลายประเภท
const ALLOWED_MIMES = ['audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/x-m4a'];
const ALLOWED_EXTS = ['.m4a', '.mp3', '.wav', '.aac', '.ogg', '.flac'];

const upload = multer({
  storage: multer.diskStorage({
    destination: './uploads',
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname) || '.m4a';
      cb(null, `${uuidv4()}_${Date.now()}${ext}`);
    }
  }),
  fileFilter: /* ตรวจสอบ MIME type + นามสกุลไฟล์ */
});
```

---

## 6. API Endpoints ทั้งหมด

### Authentication (การยืนยันตัวตน)
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| POST | `/auth/register` | สมัครสมาชิก |
| POST | `/auth/login` | เข้าสู่ระบบ |

### Users (ผู้ใช้)
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| GET | `/users` | ดูผู้ใช้ทั้งหมด |
| GET | `/users/:id` | ดูผู้ใช้ตาม ID |
| PUT | `/users/:id` | แก้ไขข้อมูลผู้ใช้ |
| PUT | `/users/:id/password` | เปลี่ยนรหัสผ่าน |
| POST | `/users/:id/avatar` | อัปโหลดรูปโปรไฟล์ |
| DELETE | `/users/:id` | ลบบัญชีผู้ใช้ |

### Tasks (งาน)
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| GET | `/tasks` | ดูงานทั้งหมด |
| POST | `/tasks` | สร้างงานใหม่ |
| GET | `/tasks/:id` | ดูงานตาม ID |
| PUT | `/tasks/:id` | แก้ไขงาน |
| DELETE | `/tasks/:id` | ลบงาน |
| GET | `/tasks/assignee/:assignee_id` | ดูงานตามผู้รับผิดชอบ |
| GET | `/tasks/group/:group_id` | ดูงานตามกลุ่ม |
| POST | `/tasks/:id/voice-instruction` | อัปโหลดเสียงคำสั่ง |
| GET | `/tasks/:id/voice-instruction` | ดึงเสียงคำสั่ง |

### Reminders (การแจ้งเตือน)
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| GET | `/reminders/user/:userId` | ดู Reminder ของผู้ใช้ |
| GET | `/reminders/:id` | ดู Reminder ตาม ID |
| POST | `/reminders` | สร้าง Reminder ใหม่ |
| PUT | `/reminders/:id` | แก้ไข Reminder |
| DELETE | `/reminders/:id` | ลบ Reminder |

### Groups (กลุ่ม)
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| POST | `/groups` | สร้างกลุ่มใหม่ |
| GET | `/groups/user/:userId` | ดูกลุ่มของผู้ใช้ |
| GET | `/groups/:id` | ดูกลุ่มตาม ID |
| PUT | `/groups/:id` | แก้ไขกลุ่ม |
| DELETE | `/groups/:id` | ลบกลุ่ม |
| GET | `/groups/:id/members` | ดูสมาชิกในกลุ่ม |
| POST | `/groups/:id/members` | เพิ่มสมาชิก |
| DELETE | `/groups/:id/members/:userId` | ลบสมาชิก |
| GET | `/groups/:id/search-users` | ค้นหาผู้ใช้เพื่อเพิ่มเข้ากลุ่ม |
| GET | `/groups/:id/messages` | ดูข้อความในกลุ่ม (Paginated) |
| POST | `/groups/:id/messages` | ส่งข้อความ |
| POST | `/groups/:id/messages/task` | ส่งข้อความพร้อมสร้างงาน |

### Health Check
| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| GET | `/health` | ตรวจสอบสถานะ Server |

---

## 7. โครงสร้างฐานข้อมูล

### ตาราง users (ผู้ใช้)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | UUID | Primary Key |
| email | VARCHAR | อีเมล (unique) |
| display_name | VARCHAR | ชื่อที่แสดง |
| password | VARCHAR | รหัสผ่าน (bcrypt hash) |
| avatar_url | VARCHAR | URL รูปโปรไฟล์ |
| created_at | TIMESTAMP | วันที่สร้าง |

### ตาราง tasks (งาน)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | SERIAL | Primary Key |
| title | VARCHAR | ชื่องาน |
| description | TEXT | คำอธิบาย |
| status | VARCHAR | สถานะ (todo/doing/done) |
| assignee_id | UUID | FK → users.id (ผู้รับผิดชอบ) |
| group_id | INT | FK → groups.id (กลุ่ม) |
| due_at | TIMESTAMP | กำหนดส่ง |
| voice_instruction_uuid | VARCHAR | ชื่อไฟล์เสียง |
| created_at | TIMESTAMP | วันที่สร้าง |
| updated_at | TIMESTAMP | วันที่อัปเดต |

### ตาราง reminders (การแจ้งเตือน)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | SERIAL | Primary Key |
| user_id | UUID | FK → users.id |
| title | VARCHAR | หัวข้อ |
| description | TEXT | คำอธิบาย |
| due_date | TIMESTAMP | วันเวลาแจ้งเตือน |
| is_completed | BOOLEAN | เสร็จแล้วหรือยัง |
| is_sent | BOOLEAN | ส่งแจ้งเตือนแล้วหรือยัง |

### ตาราง groups (กลุ่ม)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | SERIAL | Primary Key |
| name | VARCHAR | ชื่อกลุ่ม |
| description | TEXT | คำอธิบาย |
| created_by | UUID | FK → users.id (ผู้สร้าง) |
| created_at | TIMESTAMP | วันที่สร้าง |

### ตาราง group_members (สมาชิกกลุ่ม)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | SERIAL | Primary Key |
| group_id | INT | FK → groups.id |
| user_id | UUID | FK → users.id |
| role | VARCHAR | บทบาท (admin/member) |
| joined_at | TIMESTAMP | วันที่เข้าร่วม |

### ตาราง messages (ข้อความ)
| Column | Type | คำอธิบาย |
|--------|------|----------|
| id | SERIAL | Primary Key |
| group_id | INT | FK → groups.id |
| sender_id | UUID | FK → users.id |
| content | TEXT | เนื้อหาข้อความ |
| message_type | VARCHAR | ประเภท (text/task) |
| task_id | INT | FK → tasks.id (เฉพาะประเภท task) |
| created_at | TIMESTAMP | วันที่ส่ง |

---

## 8. โครงสร้างไฟล์

```
kanban_project/
├── backend/                         # เซิร์ฟเวอร์ Express.js
│   ├── src/
│   │   ├── app.js                   # Entry point, mount routes
│   │   ├── db.js                    # เชื่อมต่อ PostgreSQL
│   │   ├── controllers/
│   │   │   ├── auth.controller.js   # Login / Register
│   │   │   ├── user.controller.js   # CRUD ผู้ใช้, อัปโหลด Avatar
│   │   │   ├── task.controller.js   # CRUD งาน, อัปโหลดเสียง
│   │   │   ├── reminder.controller.js # CRUD Reminder
│   │   │   └── group.controller.js  # กลุ่ม, สมาชิก, แชท
│   │   ├── routes/
│   │   │   ├── auth.routes.js
│   │   │   ├── user.routes.js
│   │   │   ├── task.routes.js
│   │   │   ├── reminder.routes.js
│   │   │   └── group.routes.js
│   │   └── middleware/
│   │       └── multer.js            # จัดการอัปโหลดไฟล์
│   ├── uploads/                     # เก็บไฟล์เสียง + Avatar
│   ├── package.json
│   └── Dockerfile
│
├── frontend/                        # แอป Flutter
│   └── lib/
│       ├── main.dart                # Entry point, Notification setup
│       ├── auth_gate.dart           # ตรวจสอบการ Login
│       ├── main_wrapper.dart        # Bottom Navigation
│       ├── core/
│       │   ├── config/
│       │   │   └── app_config.dart  # Base URL
│       │   ├── theme/
│       │   │   └── app_colors.dart  # ชุดสี
│       │   └── widgets/             # Widget พื้นฐาน
│       ├── models/
│       │   ├── user_model.dart
│       │   ├── task_model.dart
│       │   ├── reminder_model.dart
│       │   └── group_model.dart     # Group, ChatMessage, GroupMember
│       ├── services/
│       │   ├── api_service.dart           # HTTP Client กลาง
│       │   ├── audio_recording_service.dart # บันทึกเสียง
│       │   ├── audio_playback_service.dart  # เล่นเสียง
│       │   ├── notification_service.dart    # Local Notification
│       │   ├── user_service.dart            # จัดการโปรไฟล์
│       │   └── group_chat_service.dart      # กลุ่ม + แชท
│       ├── providers/
│       │   ├── auth_provider.dart           # สถานะ Login
│       │   ├── task_provider.dart           # สถานะงาน
│       │   ├── group_provider.dart          # สถานะกลุ่ม/แชท
│       │   ├── reminder_provider.dart       # สถานะ Reminder
│       │   ├── dashboard_provider.dart      # สถิติ Dashboard
│       │   └── settings_provider.dart       # ตั้งค่า
│       └── features/
│           ├── auth/pages/
│           │   ├── login_page.dart          # หน้า Login
│           │   └── register_page.dart       # หน้าสมัครสมาชิก
│           ├── dashboard/widgets/
│           │   ├── dashboard_screen.dart    # หน้าหลัก
│           │   ├── kanban_board.dart        # บอร์ด Kanban
│           │   ├── status_tabs.dart         # แท็บกรองสถานะ
│           │   ├── upcoming_tasks.dart      # รายการงาน
│           │   └── task_card.dart           # การ์ดงาน
│           ├── task/
│           │   ├── pages/
│           │   │   ├── task_screen.dart     # สร้างงานใหม่
│           │   │   └── task_detail.dart     # รายละเอียดงาน
│           │   └── widget/
│           │       ├── voice_recorder_widget.dart  # Widget บันทึกเสียง
│           │       ├── voice_player_widget.dart    # Widget เล่นเสียง
│           │       └── incoming_call_screen.dart   # หน้า Incoming Call
│           ├── calendar/pages/
│           │   └── calendar_page.dart       # ปฏิทิน
│           ├── group/
│           │   ├── group_page.dart          # รายการกลุ่ม
│           │   ├── chat_room_page.dart      # ห้องแชท
│           │   └── group_cards.dart         # การ์ดกลุ่ม
│           ├── profile/pages/
│           │   ├── profile_pages.dart       # หน้าโปรไฟล์
│           │   ├── profile_tab.dart         # แก้ไขโปรไฟล์
│           │   └── settings_tab.dart        # ตั้งค่า
│           └── settings/pages/
│               └── settings_page.dart       # หน้าตั้งค่า
```

---

## 9. เทคโนโลยีที่ใช้

### Frontend
| เทคโนโลยี | วัตถุประสงค์ |
|-----------|-------------|
| Flutter (Dart) | Framework สร้างแอป Cross-platform |
| flutter_riverpod 3.2 | State Management |
| http | เรียก RESTful API |
| record | บันทึกเสียงจากไมโครโฟน |
| just_audio | เล่นไฟล์เสียง |
| flutter_local_notifications | แจ้งเตือน Local |
| path_provider | จัดการ File Path |
| google_fonts | ฟอนต์ Plus Jakarta Sans |
| intl | จัดรูปแบบวันที่ |
| image_picker | เลือกรูปภาพ |
| permission_handler | ขอสิทธิ์ (ไมค์, แจ้งเตือน) |
| timezone | Timezone สำหรับ Notification |

### Backend
| เทคโนโลยี | วัตถุประสงค์ |
|-----------|-------------|
| Express.js | Web Framework |
| PostgreSQL | ฐานข้อมูล Relational |
| pg (node-postgres) | เชื่อมต่อ PostgreSQL |
| bcrypt | เข้ารหัสรหัสผ่าน |
| multer | อัปโหลดไฟล์ (เสียง, รูป) |
| uuid | สร้างชื่อไฟล์ Unique |
| cors | Cross-Origin Resource Sharing |
| morgan | HTTP Request Logging |
| dotenv | Environment Variables |

---

## 10. วิธีรันโปรเจกต์

### Backend
```bash
cd backend
npm install
# สร้างไฟล์ .env
echo "DATABASE_URL=postgresql://user:password@localhost:5432/kanban" > .env
npm start
# Server จะรันที่ http://localhost:3000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
# แก้ไข Base URL ที่ lib/core/config/app_config.dart
```

### ตรวจสอบ Server
```bash
curl https://kanban.jokeped.xyz/health
# ควรได้: {"status":"ok"}
```

---

## สรุปจุดเด่นของโปรเจกต์

| หมวด | สิ่งที่ทำได้ |
|------|------------|
| **Core Features** | Auth, Task CRUD, Calendar, Reminder, Group Chat, Profile |
| **App Flow & UX** | Create → View → Edit → Delete ครบ, Bottom Nav 4 หน้า, Pull-to-refresh |
| **Data Handling** | CRUD/State ด้วย Riverpod + AsyncValue, UI อัปเดตอัตโนมัติ |
| **Persistence/Backend** | PostgreSQL + Express.js API, ข้อมูลคงอยู่หลังปิดแอป |
| **Error/Edge Cases** | Loading state, Error state, Empty state, Validation ครบ |
| **ฟีเจอร์พิเศษ** | บันทึกเสียง, Incoming Call Screen, Group Task Sharing |

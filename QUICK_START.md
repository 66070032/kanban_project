# เริ่มต้นอย่างรวดเร็ว: การใช้งานฟีเจอร์จัดการข้อผิดพลาดและออฟไลน์

## 🚀 ขั้นตอนการรวมติดตั้ง (5 นาที)

### ขั้นตอนที่ 1: อัปเดตการเรียก API ของคุณ

เปลี่ยนจากการเรียก `http` โดยตรงไปยัง `ApiService`:

**ก่อนหน้า:**

```dart
final res = await http.get(Uri.parse('$baseUrl/tasks'));
final tasks = jsonDecode(res.body);
```

**หลังจาก:**

```dart
final api = ApiService();
final tasks = await api.get('/tasks');
```

### ขั้นตอนที่ 2: จัดการข้อผิดพลาดอย่างถูกต้อง

**ก่อนหน้า:**

```dart
catch (e) {
  print(e);
}
```

**หลังจาก:**

```dart
catch (e) {
  if (!mounted) return;
  ErrorHandler.showErrorSnackBar(context, e);
}
```

### ขั้นตอนที่ 3: เพิ่มการสนับสนุนออฟไลน์ให้กับแบบฟอร์ม

```dart
// สำหรับการสร้างการดำเนินการที่ควรทำงานออฟไลน์
await api.post(
  '/tasks',
  body: data,
  allowOffline: true,  // ← เพิ่มสิ่งนี้!
);
```

### ขั้นตอนที่ 4: แสดงสถานะการเชื่อมต่อ

```dart
Consumer(
  builder: (context, ref, _) {
    final isOnline = ref.watch(isOnlineProvider);

    return Row(
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          color: isOnline ? Colors.green : Colors.orange,
        ),
        Text(isOnline ? 'อนไลน์' : 'ออฟไลน์'),
      ],
    );
  },
)
```

## 📝 รูปแบบทั่วไป

### รูปแบบที่ 1: การสร้างงานพร้อมการสนับสนุนออฟไลน์

```dart
class CreateTaskButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _createTask(context, ref),
      child: const Text('สร้างงาน'),
    );
  }

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    try {
      final api = ApiService();

      await api.post(
        '/tasks',
        body: {'title': 'งานใหม่', 'status': 'todo'},
        allowOffline: true,  // สนับสนุนออฟไลน์!
      );

      if (context.mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'สร้างงานเรียบร้อย!');
        Navigator.pop(context);
      }
    } on OfflineException {
      if (context.mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'การเปลี่ยนแปลงจะซิงค์เมื่อการเชื่อมต่อได้รับการคืนสภาพ',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}
```

### รูปแบบที่ 2: การโหลดข้อมูลโดยตรวจจับออฟไลน์

```dart
class TasksPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final tasksAsync = ref.watch(userTasksProvider);

    return Scaffold(
      body: Column(
        children: [
          // แบนเนอร์ออฟไลน์
          if (!isOnline)
            Container(
              color: Colors.orange[50],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('คุณอยู่ในโหมดออฟไลน์'),
                ],
              ),
            ),

          // รายการงาน
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) =>
                  TaskTile(task: tasks[index]),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => ErrorRetryWidget(
                error: error,
                onRetry: () => ref.invalidate(userTasksProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### รูปแบบที่ 3: รายการที่มีจำนวนการรอคอย

```dart
class TasksTabWithPending extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingTasksCountProvider);

    return pendingCount.when(
      data: (count) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('งาน'),
            if (count > 0) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.orange,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Tab(child: Text('งาน (กำลังโหลด...)')),
      error: (e, st) => const Tab(child: Text('งาน (ข้อผิดพลาด)')),
    );
  }
}
```

### รูปแบบที่ 4: ซิงค์อัตโนมัติเมื่อการเชื่อมต่อได้รับการคืนสภาพ

```dart
class MainWrapper extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  @override
  void initState() {
    super.initState();

    // ฟังการเปลี่ยนแปลงการเชื่อมต่อ
    ref.read(connectivityProvider).listen((previous, next) {
      next.whenData((isOnline) {
        if (isOnline && previous?.value == false) {
          _syncOfflineQueue();
        }
      });
    });
  }

  Future<void> _syncOfflineQueue() async {
    try {
      await ApiService().retrySyncQueue();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'ซิงค์การเปลี่ยนแปลงออฟไลน์เรียบร้อย!',
        );
      }

      // รีเฟรชข้อมูลทั้งหมด
      ref.invalidate(userTasksProvider);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... รหัสการสร้างที่มีอยู่ ...
  }
}
```

### รูปแบบที่ 5: วิดเจ็ตการแสดงข้อผิดพลาดที่กำหนดเอง

```dart
class ApiErrorDisplay extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ApiErrorDisplay({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ไอคอนตามประเภทข้อผิดพลาด
            Icon(
              error is OfflineException
                  ? Icons.cloud_off
                  : error is NetworkException
                  ? Icons.wifi_off
                  : error is UnauthorizedException
                  ? Icons.lock
                  : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),

            // ชื่อข้อผิดพลาด
            Text(
              ErrorHandler.getErrorTitle(error),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ข้อความข้อผิดพลาด
            Text(
              ErrorHandler.getErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // ปุ่มลองใหม่
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## 🔍 เคล็ดลับการแก้จุดบกพร่อง

### ตรวจสอบว่าออฟไลน์หรือไม่

```dart
print('อนไลน์: ${ConnectivityService().isOnline}');
```

### ตรวจสอบการดำเนินการที่รอคอย

```dart
final queue = await OfflineQueueService().getQueue();
print('การดำเนินการที่รอคอย: ${queue.length}');
for (final op in queue) {
  print('${op.operationType}: ${op.entityType}');
}
```

### ตรวจสอบการเปลี่ยนแปลงการเชื่อมต่อ

```dart
ConnectivityService().connectionStatusStream.listen((isOnline) {
  print('การเชื่อมต่อเปลี่ยนแปลง: $isOnline');
});
```

### ทดสอบโหมดออฟไลน์

1. เปิดใช้โหมดเครื่องบินบนอุปกรณ์
2. แอปพ์ควรตรวจจับออฟไลน์
3. การดำเนินการที่เปิดใช้ออฟไลน์ควรเข้าคิว
4. ปิดใช้โหมดเครื่องบิน
5. ตรวจสอบว่าการดำเนินการลองใหม่หรือไม่

## ⚠️ หมายเหตุสำคัญ

### พฤติกรรมเริ่มต้น

- **`allowOffline=false`** (ค่าเริ่มต้น) - ล้มเหลวทันทีหากออฟไลน์
- **`allowOffline=true`** - เข้าคิวการดำเนินการหากออฟไลน์

### สำหรับเนื้อหาที่สร้างโดยผู้ใช้

ใช้ `allowOffline=true` เสมอ:

- สร้างงาน ✅
- อัปเดตงาน ✅
- ลบงาน ✅
- สร้างการเตือน ✅
- ส่งข้อความ ✅

### สำหรับการดึงข้อมูล

ปกติใช้ `allowOffline=false`:

- รับงาน ✅
- รับการเตือน ✅
- รับข้อความ ✅

### การจัดการข้อผิดพลาด

ตรวจสอบข้อผิดพลาดเครือข่ายและการตรวจสอบทั้งสองอย่าง:

```dart
try {
  await api.post(...);
} on UnauthorizedException {
  // เปลี่ยนเส้นทางไปยังการเข้าสู่ระบบ
} on OfflineException {
  // แสดงข้อความออฟไลน์
} on NetworkException {
  // แสดงข้อผิดพลาดเครือข่าย
} catch (e) {
  // จัดการข้อผิดพลาดอื่น ๆ
}
```

## 📚 เอกสารอ้างอิง

- คู่มือฉบับสมบูรณ์: [ERROR_HANDLING_OFFLINE_GUIDE.md](ERROR_HANDLING_OFFLINE_GUIDE.md)
- ตัวอย่างโค้ด: [IMPLEMENTATION_EXAMPLES.md](IMPLEMENTATION_EXAMPLES.md)
- สรุปการปรับปรุง: [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)

## ✅ รายการตรวจสอบสำหรับแต่ละหน้าจอ

สำหรับทุกหน้าจออ้างอิง API:

- [ ] แทนที่ `http.*` ด้วย `ApiService.*`
- [ ] เพิ่มการลองใหม่พร้อมการจัดการข้อผิดพลาด
- [ ] ตั้ง `allowOffline=true` สำหรับการเขียน
- [ ] จัดการ `OfflineException` แยกต่างหากหากจำเป็น
- [ ] เพิ่มตัวบ่งชี้การเชื่อมต่อ (ตัวเลือก)
- [ ] ทดสอบโดยปิดใช้เครือข่าย
- [ ] ทดสอบโดยใช้เครือข่ายที่ช้า
- [ ] ทดสอบโดยใช้หมดเวลาเครือข่าย

---

**แอปของคุณพร้อมสำหรับการใช้งานในจริงด้วยการจัดการข้อผิดพลาดและการสนับสนุนออฟไลน์ที่ครอบคลุม! 🎉**

### Step 1: Update Your API Calls

Change from direct `http` calls to `ApiService`:

**Before:**

```dart
final res = await http.get(Uri.parse('$baseUrl/tasks'));
final tasks = jsonDecode(res.body);
```

**After:**

```dart
final api = ApiService();
final tasks = await api.get('/tasks');
```

### Step 2: Handle Errors Properly

**Before:**

```dart
catch (e) {
  print(e);
}
```

**After:**

```dart
catch (e) {
  if (!mounted) return;
  ErrorHandler.showErrorSnackBar(context, e);
}
```

### Step 3: Add Offline Support to Forms

```dart
// For create operations that should work offline
await api.post(
  '/tasks',
  body: data,
  allowOffline: true,  // ← Add this!
);
```

### Step 4: Show Connection Status

```dart
Consumer(
  builder: (context, ref, _) {
    final isOnline = ref.watch(isOnlineProvider);

    return Row(
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          color: isOnline ? Colors.green : Colors.orange,
        ),
        Text(isOnline ? 'Online' : 'Offline'),
      ],
    );
  },
)
```

## 📝 Common Patterns

### Pattern 1: Task Creation with Offline Support

```dart
class CreateTaskButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _createTask(context, ref),
      child: const Text('Create Task'),
    );
  }

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    try {
      final api = ApiService();

      await api.post(
        '/tasks',
        body: {'title': 'New Task', 'status': 'todo'},
        allowOffline: true,  // Support offline!
      );

      if (context.mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Task created!');
        Navigator.pop(context);
      }
    } on OfflineException {
      if (context.mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Changes will sync when connection restored',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}
```

### Pattern 2: Data Loading with Offline Detection

```dart
class TasksPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final tasksAsync = ref.watch(userTasksProvider);

    return Scaffold(
      body: Column(
        children: [
          // Offline banner
          if (!isOnline)
            Container(
              color: Colors.orange[50],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('You are offline'),
                ],
              ),
            ),

          // Tasks list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) =>
                  TaskTile(task: tasks[index]),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => ErrorRetryWidget(
                error: error,
                onRetry: () => ref.invalidate(userTasksProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 3: List with Pending Count

```dart
class TasksTabWithPending extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingTasksCountProvider);

    return pendingCount.when(
      data: (count) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tasks'),
            if (count > 0) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.orange,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Tab(child: Text('Tasks (loading...)')),
      error: (e, st) => const Tab(child: Text('Tasks (error)')),
    );
  }
}
```

### Pattern 4: Auto-Sync on Connection Restore

```dart
class MainWrapper extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  @override
  void initState() {
    super.initState();

    // Listen to connection changes
    ref.read(connectivityProvider).listen((previous, next) {
      next.whenData((isOnline) {
        if (isOnline && previous?.value == false) {
          _syncOfflineQueue();
        }
      });
    });
  }

  Future<void> _syncOfflineQueue() async {
    try {
      await ApiService().retrySyncQueue();

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Synced offline changes!',
        );
      }

      // Refresh all data
      ref.invalidate(userTasksProvider);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build code ...
  }
}
```

### Pattern 5: Custom Error Display Widget

```dart
class ApiErrorDisplay extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ApiErrorDisplay({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon based on error type
            Icon(
              error is OfflineException
                  ? Icons.cloud_off
                  : error is NetworkException
                  ? Icons.wifi_off
                  : error is UnauthorizedException
                  ? Icons.lock
                  : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),

            // Error title
            Text(
              ErrorHandler.getErrorTitle(error),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Error message
            Text(
              ErrorHandler.getErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Retry button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## 🔍 Debugging Tips

### Check if offline

```dart
print('Is online: ${ConnectivityService().isOnline}');
```

### Check pending operations

```dart
final queue = await OfflineQueueService().getQueue();
print('Pending operations: ${queue.length}');
for (final op in queue) {
  print('${op.operationType}: ${op.entityType}');
}
```

### Monitor connectivity changes

```dart
ConnectivityService().connectionStatusStream.listen((isOnline) {
  print('Connection changed: $isOnline');
});
```

### Test offline mode

1. Enable airplane mode on device
2. App should detect offline
3. Offline-enabled operations should queue
4. Disable airplane mode
5. Check if operations retry

## ⚠️ Important Notes

### Default Behavior

- **`allowOffline=false`** (default) - Fails immediately if offline
- **`allowOffline=true`** - Queues operation if offline

### For User-Generated Content

Always use `allowOffline=true`:

- Creating tasks ✅
- Updating tasks ✅
- Deleting tasks ✅
- Creating reminders ✅
- Sending messages ✅

### For Fetching Data

Usually use `allowOffline=false`:

- Getting tasks ✅
- Getting reminders ✅
- Getting messages ✅

### Error Handling

Always check for both network and auth errors:

```dart
try {
  await api.post(...);
} on UnauthorizedException {
  // Redirect to login
} on OfflineException {
  // Show offline message
} on NetworkException {
  // Show network error
} catch (e) {
  // Handle other errors
}
```

## 📚 Reference Documentation

- Full guide: [ERROR_HANDLING_OFFLINE_GUIDE.md](ERROR_HANDLING_OFFLINE_GUIDE.md)
- Code examples: [IMPLEMENTATION_EXAMPLES.md](IMPLEMENTATION_EXAMPLES.md)
- Refactoring summary: [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)

## ✅ Checklist for Each Screen

For every screen that makes API calls:

- [ ] Replace `http.*` with `ApiService.*`
- [ ] Add try-catch with error handling
- [ ] Set `allowOffline=true` for writes
- [ ] Handle `OfflineException` separately if needed
- [ ] Add connectivity indicator (optional)
- [ ] Test with network disabled
- [ ] Test with slow network
- [ ] Test with network timeout

---

**Now your app is production-ready with comprehensive error handling and offline support! 🎉**

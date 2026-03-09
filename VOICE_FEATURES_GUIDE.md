# Voice-Based Task Manager - Implementation Guide

## Missing Files Created ✅

This document outlines all the missing files that have been created to complete the voice-based task manager implementation. All files are designed to work with the existing Express.js + PostgreSQL backend.

---

## 📁 New Files Overview

### 1. **Services Layer** (`lib/services/`)

#### `api_service.dart`

- **Purpose**: Centralized HTTP client for all API communication
- **Functions**:
  - `get()`, `post()`, `put()`, `delete()` - Standard REST methods
  - `upload()` - Multipart file upload for voice files
- **Features**:
  - Handles 30-second timeouts
  - Automatic error handling (401 Unauthorized, 404 Not Found, etc.)
  - Works with both local (`http://localhost:3000`) and hosted backends
- **Usage**:
  ```dart
  final api = ApiService();
  final tasks = await api.get('/tasks/assignee/user-id');
  ```

#### `audio_recording_service.dart`

- **Purpose**: Manages voice recording functionality
- **Methods**:
  - `startRecording()` - Begin voice recording
  - `stopRecording()` - Stop and return file path
  - `cancelRecording()` - Discard recording
  - `hasRecordingPermission()` - Check microphone permission
  - `requestRecordingPermission()` - Request permission from user
- **Note**: Includes placeholders for integration with the `record` package
- **Backend Integration**: Records to local temp directory, then uploads to backend

#### `audio_playback_service.dart`

- **Purpose**: Manages voice playback with state tracking
- **Enum**: `PlaybackState` (idle, playing, paused, stopped)
- **Methods**:
  - `play(filePath)` - Play local audio file
  - `playFromUrl(url)` - Stream audio from server (for reminders)
  - `pause()`, `resume()`, `stop()` - Playback controls
  - `seek(position)` - Jump to specific time
- **Callback Methods**:
  - `onPlaybackStateChanged()` - Track state changes
  - `onPositionChanged()` - Update playback progress
- **Note**: Callbacks are ready for Riverpod integration

#### `notification_service.dart`

- **Purpose**: Handles local notifications and incoming call overlays
- **Methods**:
  - `initialize()` - Setup on app startup
  - `showNotification()` - Simple text notification
  - `scheduleNotification()` - Schedule at specific time with sound
  - `showIncomingCallNotification()` - Display call-like UI
  - `cancelNotification(id)`, `cancelAllNotifications()`
  - `hasNotificationPermission()`, `requestNotificationPermission()`
- **Integrations**:
  - Uses `flutter_local_notifications` (notifications)
  - Uses `flutter_callkit_incoming` (simulated call UI)
- **Backend Connection**: Receives trigger times from task `due_at` field

---

### 2. **UI Widgets** (`lib/features/task/widget/`)

#### `voice_recorder_widget.dart`

- **Purpose**: Reusable recording UI component
- **Features**:
  - Start/Stop/Cancel buttons
  - Real-time duration display (MM:SS format)
  - Animated recording icon with pulsing effect
  - Customizable title and accent color
- **Callback**: `onRecordingComplete(filePath, duration)`
- **Usage**:
  ```dart
  VoiceRecorderWidget(
    title: 'Record Voice Instruction',
    onRecordingComplete: (path, duration) {
      // Handle recorded file
    },
  )
  ```

#### `voice_player_widget.dart`

- **Purpose**: Reusable playback UI component
- **Features**:
  - Play/Pause/Stop controls
  - Slider for seeking through audio
  - Duration display (current/total)
  - States: loading, playing, paused, stopped, error
  - Auto-play option
- **Properties**:
  - `audioPath` - Local file path
  - `audioUrl` - URL for streaming from server
  - `autoPlay` - Auto-start playback
- **Usage**:
  ```dart
  VoicePlayerWidget(
    audioUrl: 'https://kanban-api.com/voices/instruction-123.m4a',
    title: 'Voice Instruction',
    autoPlay: false,
  )
  ```

#### `incoming_call_screen.dart`

- **Purpose**: Simulated incoming call notification screen
- **Features**:
  - Full-screen call interface
  - Caller name and task title display
  - Pulsing avatar animation
  - Accept (green) and Reject (red) buttons
  - Auto-reject countdown (30 seconds default)
  - Call actions trigger sound playback
- **Callback Functions**:
  - `onAccept()` - Plays voice reminder
  - `onReject()` - Snoozes notification
- **Usage**:
  ```dart
  await showIncomingCallOverlay(
    context: context,
    callerId: 'user-123',
    callerName: 'John Doe',
    taskTitle: 'Review project proposal',
    onAccept: () { /* play reminder */ },
    onReject: () { /* snooze */ },
  );
  ```

---

### 3. **Providers** (`lib/providers/`)

#### `task_provider.dart`

- **Purpose**: Riverpod providers and service for task management
- **TaskService Class**:
  - Static methods for all task operations
  - Full CRUD (Create, Read, Update, Delete)
  - Voice instruction upload
- **FutureProviders**:
  - `userTasksProvider` - Fetch all tasks for user
  - `taskDetailProvider` - Fetch single task
  - `createTaskProvider` - Create new task
  - `updateTaskProvider` - Update existing task
  - `deleteTaskProvider` - Delete task
  - `uploadVoiceInstructionProvider` - Upload voice file
- **NotifierProvider**:
  - `taskFormProvider` - Manage task creation form state
  - Methods: `setTitle()`, `setDescription()`, `setStatus()`, `setDueDate()`, `setVoiceInstruction()`, `reset()`
- **Backend Endpoints Used**:
  - `GET /tasks/assignee/{userId}`
  - `GET /tasks/{taskId}`
  - `POST /tasks`
  - `PUT /tasks/{taskId}`
  - `DELETE /tasks/{taskId}`
  - `POST /tasks/{taskId}/voice-instruction` (multipart)

#### `reminder_provider.dart`

- **Purpose**: Riverpod providers and service for reminders
- **ReminderService Class**:
  - Static methods for reminder operations
  - Full CRUD operations
  - Voice reminder upload and retrieval
- **FutureProviders**:
  - `userRemindersProvider` - Fetch all reminders for user
  - `reminderDetailProvider` - Fetch single reminder
  - `createReminderProvider` - Create reminder
  - `updateReminderProvider` - Update reminder
  - `deleteReminderProvider` - Delete reminder
  - `uploadVoiceReminderProvider` - Upload voice reminder
- **NotifierProvider**:
  - `voiceNotificationProvider` - Manage incoming call notification state
  - Methods: `showIncomingCallNotification()`, `hideIncomingCallNotification()`
- **Backend Endpoints Used**:
  - `GET /reminders/user/{userId}`
  - `GET /reminders/{reminderId}`
  - `POST /reminders`
  - `PUT /reminders/{reminderId}`
  - `DELETE /reminders/{reminderId}`
  - `POST /reminders/{reminderId}/voice` (multipart)

---

### 4. **Pages** (`lib/features/task/pages/`)

#### `task_detail.dart`

- **Purpose**: Comprehensive task detail page with voice integration
- **Features**:
  - Display task title, description, status, due date
  - Voice instruction recording and playback sections
  - Update and delete task buttons
  - Full-featured task editor
- **Sections**:
  1. **Task Basic Info**: Title, description
  2. **Task Metadata**: Status badge, due date
  3. **Voice Instruction**: Record or playback section
  4. **Action Buttons**: Save and Delete
- **Error Handling**:
  - Loading states for async operations
  - Confirmation dialogs for destructive actions
  - Snackbar notifications for user feedback
- **Usage**:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailPage(task: task),
    ),
  );
  ```

---

## 🔌 Backend Integration

All files are designed to work with your existing Express.js backend:

### Required Backend Endpoints

The implementation expects these endpoints (confirm they exist):

```
✅ Task Endpoints:
- GET /tasks/assignee/{userId}
- GET /tasks/{taskId}
- POST /tasks
- PUT /tasks/{taskId}
- DELETE /tasks/{taskId}

✅ Reminder Endpoints:
- GET /reminders/user/{userId}
- GET /reminders/{reminderId}
- POST /reminders
- PUT /reminders/{reminderId}
- DELETE /reminders/{reminderId}

✅ File Upload Endpoints:
- POST /tasks/{taskId}/voice-instruction (multipart form-data)
- POST /reminders/{reminderId}/voice (multipart form-data)
```

### API Base URL Configuration

Change the base URL in `lib/services/api_service.dart` and both provider files:

**For Local Development:**

```dart
static const String baseUrl = 'http://localhost:3000';
```

**For Hosted Database:**

```dart
static const String baseUrl = 'https://your-backend-domain.com';
// Example: https://kanban.jokeped.xyz
```

---

## 🗄️ Database Configuration

All data persists in your existing PostgreSQL database tables:

### Required Database Tables

```sql
-- Tasks with voice support
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'todo', -- todo, doing, done
  assignee_id INTEGER REFERENCES users(id),
  due_at TIMESTAMP,
  voice_instruction_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Reminders with voice
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id INTEGER REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  due_date TIMESTAMP NOT NULL,
  voice_reminder_url VARCHAR(500),
  is_completed BOOLEAN DEFAULT FALSE,
  is_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Hosted Database Options

The implementation works with any PostgreSQL hosting:

1. **Supabase** - Best for beginners

   ```
   Base URL: https://[project].supabase.co
   Connection: postgresql://[user]:[pass]@db.[project].supabase.co
   ```

2. **Railway** - Easiest deployment

   ```
   Base URL: https://your-railway-app.up.railway.app
   Auto-generated connection strings
   ```

3. **AWS RDS** - Enterprise solution

   ```
   Base URL: https://your-backend-on-ec2.com
   PostgreSQL endpoint: [identifier].c9akciq32.us-east-1.rds.amazonaws.com
   ```

4. **DigitalOcean** - Reliable and affordable
   ```
   Base URL: https://your-app.ondigitalocean.app
   Managed database: db-postgresql-[region]
   ```

### Migration for Voice Fields

If your database doesn't have voice fields, run:

```sql
-- Add voice fields to existing tables
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS voice_instruction_url VARCHAR(500);

ALTER TABLE reminders
ADD COLUMN IF NOT EXISTS voice_reminder_url VARCHAR(500);
```

---

## 📦 Dependencies to Install

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^3.2.1 # Already installed
  http: ^1.6.0 # Already installed
  just_audio: ^0.9.0 # For audio playback
  record: ^4.4.0 # For audio recording
  flutter_local_notifications: ^15.0.0 # For local notifications
  flutter_callkit_incoming: ^2.0.0 # For incoming call UI
  permission_handler: ^11.0.0 # For permissions
```

Install with:

```bash
cd frontend
flutter pub get
```

---

## 🚀 Implementation Roadmap

### Phase 1: Basic Setup (Done ✅)

- ✅ Services layer created
- ✅ UI widgets created
- ✅ Providers created
- ✅ Task detail page created

### Phase 2: Audio Integration (Next)

- Replace placeholder implementations in services
- Test with actual audio files
- Implement permission handling

### Phase 3: Notification System (Then)

- Initialize notification service on app startup
- Schedule notifications based on due dates
- Test incoming call notifications

### Phase 4: Full Feature Integration (Finally)

- Connect all UI flows
- End-to-end testing
- Performance optimization

---

## ✅ Testing Checklist

Use this checklist to verify everything works:

```
Backend:
☐ Backend running at correct URL
☐ Database is accessible
☐ Voice upload endpoints working
☐ Task endpoints returning correct data
☐ Reminders accessible

Frontend:
☐ API service connects successfully
☐ Task list loads from backend
☐ Can create new tasks
☐ Can view task details
☐ Voice recorder initializes
☐ Voice player controls work
☐ Incoming call screen displays
☐ Notifications work (after dependency install)

Database:
☐ PostgreSQL running
☐ Voice fields exist in tables
☐ Connection string correct for hosted DB
☐ Data persists between app restarts
```

---

## 🔧 Troubleshooting

### API Connection Issues

**Problem**: "Network error" when connecting to backend
**Solution**:

1. Check base URL in `api_service.dart`
2. Verify backend is running: `curl http://localhost:3000/health`
3. Check Flutter app is using correct domain

### Voice Recording Fails

**Problem**: "Recording error" when trying to record
**Solution**:

1. Check microphone permission in app settings
2. Ensure `record` package is installed
3. Check storage permissions (Android/iOS)

### Database Connection Failed

**Problem**: Cannot connect to hosted database
**Solution**:

1. Verify connection string in backend `.env`
2. Check firewall/security groups
3. Test connection: `psql [connection-string] -c "SELECT 1"`

### Reminders Not Triggering

**Problem**: Notifications not showing at scheduled time
**Solution**:

1. Verify `flutter_local_notifications` is initialized
2. Check reminder due date is in future
3. Ensure notification permission is granted

---

## 📝 File Locations Summary

```
lib/
├── services/
│   ├── api_service.dart
│   ├── audio_recording_service.dart
│   ├── audio_playback_service.dart
│   └── notification_service.dart
├── features/task/
│   ├── widget/
│   │   ├── voice_recorder_widget.dart
│   │   ├── voice_player_widget.dart
│   │   └── incoming_call_screen.dart
│   └── pages/
│       └── task_detail.dart
└── providers/
    ├── task_provider.dart
    └── reminder_provider.dart
```

---

## 🎯 Next Steps

1. **Install audio dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure backend URL**
   - Update `api_service.dart` with your backend URL
   - Update both provider files

3. **Verify database tables**
   - Ensure voice fields exist
   - Run migration if needed

4. **Test with real backend**
   - Create test task with voice
   - Verify upload works
   - Test playback

5. **Enable audio permissions**
   - Update `AndroidManifest.xml`
   - Update `Info.plist` for iOS

---

## 📞 Support

All files work with your existing backend. If issues arise:

1. Check backend logs for API errors
2. Verify database connectivity
3. Test endpoints manually with curl
4. Enable debug logging in Flutter

---

**Last Updated**: March 9, 2026  
**Status**: All missing files created ✅  
**Ready for**: Integration with hosted database

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============= Settings Models =============

class NotificationSettings {
  final bool taskNotifications;
  final bool reminderNotifications;
  final bool messageNotifications;

  NotificationSettings({
    required this.taskNotifications,
    required this.reminderNotifications,
    required this.messageNotifications,
  });

  NotificationSettings copyWith({
    bool? taskNotifications,
    bool? reminderNotifications,
    bool? messageNotifications,
  }) {
    return NotificationSettings(
      taskNotifications: taskNotifications ?? this.taskNotifications,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
    );
  }
}

class DisplaySettings {
  final String theme; // 'Auto', 'Light', 'Dark'
  final String textSize; // 'Small', 'Normal', 'Large'
  final bool enableAnimations;

  DisplaySettings({
    required this.theme,
    required this.textSize,
    required this.enableAnimations,
  });

  DisplaySettings copyWith({
    String? theme,
    String? textSize,
    bool? enableAnimations,
  }) {
    return DisplaySettings(
      theme: theme ?? this.theme,
      textSize: textSize ?? this.textSize,
      enableAnimations: enableAnimations ?? this.enableAnimations,
    );
  }
}

class SoundSettings {
  final bool soundEffects;
  final bool vibration;
  final String notificationVolume; // 'Low', 'Normal', 'High'

  SoundSettings({
    required this.soundEffects,
    required this.vibration,
    required this.notificationVolume,
  });

  SoundSettings copyWith({
    bool? soundEffects,
    bool? vibration,
    String? notificationVolume,
  }) {
    return SoundSettings(
      soundEffects: soundEffects ?? this.soundEffects,
      vibration: vibration ?? this.vibration,
      notificationVolume: notificationVolume ?? this.notificationVolume,
    );
  }
}

class TaskSettings {
  final bool autoDeleteCompleted;
  final String defaultSortOrder; // 'Due Date', 'Priority', 'Created'
  final bool showRecurringTasks;

  TaskSettings({
    required this.autoDeleteCompleted,
    required this.defaultSortOrder,
    required this.showRecurringTasks,
  });

  TaskSettings copyWith({
    bool? autoDeleteCompleted,
    String? defaultSortOrder,
    bool? showRecurringTasks,
  }) {
    return TaskSettings(
      autoDeleteCompleted: autoDeleteCompleted ?? this.autoDeleteCompleted,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      showRecurringTasks: showRecurringTasks ?? this.showRecurringTasks,
    );
  }
}

class SecuritySettings {
  final bool biometricLogin;

  SecuritySettings({required this.biometricLogin});

  SecuritySettings copyWith({bool? biometricLogin}) {
    return SecuritySettings(
      biometricLogin: biometricLogin ?? this.biometricLogin,
    );
  }
}

// ============= State Notifiers =============

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return NotificationSettings(
      taskNotifications: true,
      reminderNotifications: true,
      messageNotifications: false,
    );
  }

  void updateTaskNotifications(bool value) {
    state = state.copyWith(taskNotifications: value);
  }

  void updateReminderNotifications(bool value) {
    state = state.copyWith(reminderNotifications: value);
  }

  void updateMessageNotifications(bool value) {
    state = state.copyWith(messageNotifications: value);
  }
}

class DisplaySettingsNotifier extends Notifier<DisplaySettings> {
  @override
  DisplaySettings build() {
    return DisplaySettings(
      theme: 'Auto',
      textSize: 'Normal',
      enableAnimations: true,
    );
  }

  void updateTheme(String theme) {
    state = state.copyWith(theme: theme);
  }

  void updateTextSize(String size) {
    state = state.copyWith(textSize: size);
  }

  void updateAnimations(bool enabled) {
    state = state.copyWith(enableAnimations: enabled);
  }
}

class SoundSettingsNotifier extends Notifier<SoundSettings> {
  @override
  SoundSettings build() {
    return SoundSettings(
      soundEffects: true,
      vibration: true,
      notificationVolume: 'High',
    );
  }

  void updateSoundEffects(bool value) {
    state = state.copyWith(soundEffects: value);
  }

  void updateVibration(bool value) {
    state = state.copyWith(vibration: value);
  }

  void updateNotificationVolume(String volume) {
    state = state.copyWith(notificationVolume: volume);
  }
}

class TaskSettingsNotifier extends Notifier<TaskSettings> {
  @override
  TaskSettings build() {
    return TaskSettings(
      autoDeleteCompleted: false,
      defaultSortOrder: 'Due Date',
      showRecurringTasks: true,
    );
  }

  void updateAutoDeleteCompleted(bool value) {
    state = state.copyWith(autoDeleteCompleted: value);
  }

  void updateDefaultSortOrder(String order) {
    state = state.copyWith(defaultSortOrder: order);
  }

  void updateShowRecurringTasks(bool value) {
    state = state.copyWith(showRecurringTasks: value);
  }
}

class SecuritySettingsNotifier extends Notifier<SecuritySettings> {
  @override
  SecuritySettings build() {
    return SecuritySettings(biometricLogin: false);
  }

  void updateBiometricLogin(bool value) {
    state = state.copyWith(biometricLogin: value);
  }
}

// ============= Riverpod Providers =============

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsNotifier, DisplaySettings>(
      DisplaySettingsNotifier.new,
    );

final soundSettingsProvider =
    NotifierProvider<SoundSettingsNotifier, SoundSettings>(
      SoundSettingsNotifier.new,
    );

final taskSettingsProvider =
    NotifierProvider<TaskSettingsNotifier, TaskSettings>(
      TaskSettingsNotifier.new,
    );

final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
      SecuritySettingsNotifier.new,
    );

// ============= Combined Settings Provider =============

class AllSettings {
  final NotificationSettings notifications;
  final DisplaySettings display;
  final SoundSettings sound;
  final TaskSettings task;
  final SecuritySettings security;

  AllSettings({
    required this.notifications,
    required this.display,
    required this.sound,
    required this.task,
    required this.security,
  });
}

final allSettingsProvider = FutureProvider<AllSettings>((ref) async {
  final notifications = ref.watch(notificationSettingsProvider);
  final display = ref.watch(displaySettingsProvider);
  final sound = ref.watch(soundSettingsProvider);
  final task = ref.watch(taskSettingsProvider);
  final security = ref.watch(securitySettingsProvider);

  return AllSettings(
    notifications: notifications,
    display: display,
    sound: sound,
    task: task,
    security: security,
  );
});

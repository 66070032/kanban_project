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



// ============= Riverpod Providers =============

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

final soundSettingsProvider =
    NotifierProvider<SoundSettingsNotifier, SoundSettings>(
      SoundSettingsNotifier.new,
    );

// ============= Combined Settings Provider =============

class AllSettings {
  final NotificationSettings notifications;
  final SoundSettings sound;

  AllSettings({
    required this.notifications,
    required this.sound,
  });
}

final allSettingsProvider = FutureProvider<AllSettings>((ref) async {
  final notifications = ref.watch(notificationSettingsProvider);
  final sound = ref.watch(soundSettingsProvider);

  return AllSettings(
    notifications: notifications,
    sound: sound,
  );
});

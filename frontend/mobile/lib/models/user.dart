class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final UserSettings settings;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    required this.settings,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      name: json['name'],
      settings: UserSettings.fromJson(json['settings'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'settings': settings.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserSettings {
  final String preferredChannel;
  final bool quietMode;
  final List<String> quietHours;
  final String language;
  final int alertMinutesBefore;

  UserSettings({
    this.preferredChannel = 'whatsapp',
    this.quietMode = true,
    this.quietHours = const ['22:00', '06:00'],
    this.language = 'he',
    this.alertMinutesBefore = 5,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      preferredChannel: json['preferred_channel'] ?? 'whatsapp',
      quietMode: json['quiet_mode'] ?? true,
      quietHours: List<String>.from(json['quiet_hours'] ?? ['22:00', '06:00']),
      language: json['language'] ?? 'he',
      alertMinutesBefore: json['alert_minutes_before'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_channel': preferredChannel,
      'quiet_mode': quietMode,
      'quiet_hours': quietHours,
      'language': language,
      'alert_minutes_before': alertMinutesBefore,
    };
  }

  UserSettings copyWith({
    String? preferredChannel,
    bool? quietMode,
    List<String>? quietHours,
    String? language,
    int? alertMinutesBefore,
  }) {
    return UserSettings(
      preferredChannel: preferredChannel ?? this.preferredChannel,
      quietMode: quietMode ?? this.quietMode,
      quietHours: quietHours ?? this.quietHours,
      language: language ?? this.language,
      alertMinutesBefore: alertMinutesBefore ?? this.alertMinutesBefore,
    );
  }
}

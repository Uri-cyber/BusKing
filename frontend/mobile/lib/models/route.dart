class UserRoute {
  final String id;
  final String userId;
  final String stopId;
  final String? stopName;
  final String routeNumber;
  final String? routeName;
  final List<int> daysOfWeek;
  final String timeWindowStart;
  final String timeWindowEnd;
  final int alertMinutesBefore;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRoute({
    required this.id,
    required this.userId,
    required this.stopId,
    this.stopName,
    required this.routeNumber,
    this.routeName,
    required this.daysOfWeek,
    required this.timeWindowStart,
    required this.timeWindowEnd,
    required this.alertMinutesBefore,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRoute.fromJson(Map<String, dynamic> json) {
    return UserRoute(
      id: json['id'],
      userId: json['user_id'] ?? '',
      stopId: json['stop_id'],
      stopName: json['stop_name'],
      routeNumber: json['route_number'],
      routeName: json['route_name'],
      daysOfWeek: List<int>.from(json['days_of_week']),
      timeWindowStart: json['time_window_start'],
      timeWindowEnd: json['time_window_end'],
      alertMinutesBefore: json['alert_minutes_before'] ?? 5,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stop_id': stopId,
      'stop_name': stopName,
      'route_number': routeNumber,
      'route_name': routeName,
      'days_of_week': daysOfWeek,
      'time_window_start': timeWindowStart,
      'time_window_end': timeWindowEnd,
      'alert_minutes_before': alertMinutesBefore,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserRoute copyWith({
    String? id,
    String? userId,
    String? stopId,
    String? stopName,
    String? routeNumber,
    String? routeName,
    List<int>? daysOfWeek,
    String? timeWindowStart,
    String? timeWindowEnd,
    int? alertMinutesBefore,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRoute(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stopId: stopId ?? this.stopId,
      stopName: stopName ?? this.stopName,
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      alertMinutesBefore: alertMinutesBefore ?? this.alertMinutesBefore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

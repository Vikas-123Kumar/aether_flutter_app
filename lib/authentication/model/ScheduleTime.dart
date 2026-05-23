class ScheduleTime {
  final String start;
  final String end;

  ScheduleTime({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {
      "start": start,
      "end": end,
    };
  }
}

class DeviceScheduleRequest {
  final String deviceId;
  final int temperature;
  final String timezones;

  /// Dynamic days
  final Map<String, List<ScheduleTime>> schedule;

  DeviceScheduleRequest({
    required this.deviceId,
    required this.temperature,
    required this.timezones,
    required this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      "device_id": deviceId,
      "temperature": temperature,
      "timezones": timezones,
      "schedule": schedule.map(
            (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };
  }
}

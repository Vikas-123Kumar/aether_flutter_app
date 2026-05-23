class ThermostatData {
  final int currentTemp;
  final int targetTemp;
  final String mode;

  ThermostatData({
    required this.currentTemp,
    required this.targetTemp,
    required this.mode,
  });

  factory ThermostatData.fromJson(Map<String, dynamic> json) {
    return ThermostatData(
      currentTemp: json['current_temp'],
      targetTemp: json['target_temp'],
      mode: json['mode'],
    );
  }
}
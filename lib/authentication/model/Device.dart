class Device {
  final String name;
  final String address;
  final String model;
  final double? temperature;
  final String mode;
  final bool isOnline;
  final int alerts;

  Device({
    required this.name,
    required this.address,
    required this.model,
    this.temperature,
    required this.mode,
    required this.isOnline,
    required this.alerts,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      address: json['address'],
      model: json['model'],
      temperature: json['temperature'],
      mode: json['mode'],
      isOnline: json['isOnline'],
      alerts: json['alerts'],
    );
  }
}
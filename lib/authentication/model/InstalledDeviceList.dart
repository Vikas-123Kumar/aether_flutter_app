class InstalledDeviceList {
  final String message;
  final List<Device> devices;

  InstalledDeviceList({
    required this.message,
    required this.devices,
  });

  factory InstalledDeviceList.fromJson(Map<String, dynamic> json) {
    return InstalledDeviceList(
      message: json['message'] ?? '',
      devices: (json['devices'] as List? ?? [])
          .map((e) => Device.fromJson(e))
          .toList(),
    );
  }
}

class Device {
  final String id;
  final String userId;
  final String installerId;
  final String bindSpaceId;
  final String deviceId;
  final String customName;
  final String model;
  final String createTime;
  final String address;
  final String fullName;

  Device({
    required this.id,
    required this.userId,
    required this.installerId,
    required this.bindSpaceId,
    required this.deviceId,
    required this.customName,
    required this.model,
    required this.createTime,
    required this.address,
    required this.fullName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      installerId: json['installer_id'] ?? '',
      bindSpaceId: json['bind_space_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      customName: json['custom_name'] ?? '',
      model: json['model'] ?? '',
      createTime: json['create_time'] ?? '',
      address: json['address'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }
}
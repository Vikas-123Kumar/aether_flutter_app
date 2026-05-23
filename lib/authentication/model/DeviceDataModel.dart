class DeviceDataModel {
  final String devid;
  final String val;
  final String datatypeName;
  final int serialNumber;
  final String dataAddress;
  final String itemname;
  final String specificType;
  final bool readOnly;
  final String devName;
  final int frequency;
  final String quality;
  final String itemid;
  final String datatype;
  final String alias;
  final String htime;
  final String config;
  final String unit;
  final int timestamp;

  DeviceDataModel({
    required this.devid,
    required this.val,
    required this.datatypeName,
    required this.serialNumber,
    required this.dataAddress,
    required this.itemname,
    required this.specificType,
    required this.readOnly,
    required this.devName,
    required this.frequency,
    required this.quality,
    required this.itemid,
    required this.datatype,
    required this.alias,
    required this.htime,
    required this.config,
    required this.unit,
    required this.timestamp,
  });

  factory DeviceDataModel.fromJson(Map<String, dynamic> json) {
    return DeviceDataModel(
      devid: json['devid']?.toString() ?? "",
      val: json['val']?.toString() ?? "",
      datatypeName: json['datatypeName'] ?? "",
      serialNumber: json['serialNumber'] ?? 0,
      dataAddress: json['dataAddress']?.toString() ?? "",
      itemname: json['itemname'] ?? "",
      specificType: json['specificType']?.toString() ?? "",
      readOnly: json['readOnly'] ?? false,
      devName: json['devName'] ?? "",
      frequency: json['frequency'] ?? 0,
      quality: json['quality'] ?? "",
      itemid: json['itemid']?.toString() ?? "",
      datatype: json['datatype']?.toString() ?? "",
      alias: json['alias'] ?? "",
      htime: json['htime'] ?? "",
      config: json['config'] ?? "",
      unit: json['unit'] ?? "",
      timestamp: json['timestamp'] ?? 0,
    );
  }

}

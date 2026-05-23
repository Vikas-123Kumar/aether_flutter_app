class ProfileInfo {
  final Data data;

  ProfileInfo({required this.data});

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      data: Data.fromJson(json['data']),
    );
  }
}

class Data {
  final String name;
  final String email;
  final int id;

  Data({required this.name, required this.email, required this.id});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      id: json['id'] ?? 0,
    );
  }
}
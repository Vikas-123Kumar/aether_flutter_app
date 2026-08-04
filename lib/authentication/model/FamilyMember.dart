class FamilyMember {
  final int id;
  final String name;
  final String email;
  final String role;
  final int is_device_access;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.is_device_access,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? 0,
      name: json['full_name'] ?? "",
      email: json['email'] ?? "",
      role: json['device_user_type'] ?? "",
      is_device_access: json['is_device_access'] ??0,
    );
  }
}
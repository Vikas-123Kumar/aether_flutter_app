class FamilyMember {
  final int id;
  final String name;
  final String email;
  final String role;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? 0,
      name: json['full_name'] ?? "",
      email: json['email'] ?? "",
      role: json['device_user_type'] ?? "",
    );
  }
}
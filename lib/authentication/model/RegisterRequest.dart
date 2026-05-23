class RegisterRequest {
  final String fullName;
  final String email;
  final String companyName;
  final String licenseId;
  final String phone;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.companyName,
    required this.licenseId,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "full_name": fullName,
      "email": email,
      "company_name": companyName,
      "license_id": licenseId,
      "phone": phone,
      "password": password,
    };
  }
}
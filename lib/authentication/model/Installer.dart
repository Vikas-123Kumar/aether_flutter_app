class Installer {
  final int installerId;
  final String installerName;
  final String companyName;
  final String email;
  final String phoneNumber;
  final String licenceNo;

  Installer({
    required this.installerId,
    required this.installerName,
    required this.companyName,
    required this.email,
    required this.phoneNumber,
    required this.licenceNo,
  });

  factory Installer.fromJson(Map<String, dynamic> json) {
    return Installer(
      installerId: json["installer_id"] ?? 0,
      installerName: json["installer_name"] ?? "",
      companyName: json["company_name"] ?? "",
      email: json["email"] ?? "",
      phoneNumber: json["phone_number"] ?? "",
      licenceNo: json["licence_no"] ?? "",
    );
  }
}
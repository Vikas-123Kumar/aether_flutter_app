import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Make sure to keep your own imports here
// import 'package:untitled/DeviceInformations.dart';
// import 'package:untitled/authentication/NewLoginScreen.dart';
// import 'package:untitled/authentication/rest/APIService.dart';
// import '../InternetService.dart';
// import '../common_function/SnackBar.dart';
// import '../pairdevice/ConnectScreen.dart';

class Installerprofile extends StatefulWidget {
  const Installerprofile({super.key});

  @override
  State<Installerprofile> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Installerprofile> {
  bool _isLoading = false;

  // API Data Variables
  String name = "";
  String role = "";
  String licenseNumber = "";
  String email = "";
  String mobile = "";
  String companyName = "";
  String abn = "62 184 339 220"; // Hardcoded as it's not in the provided API

  // Example device ID (Keep your original logic)
  String deviceId = "dummy_device_id";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    const String apiUrl = 'https://aetherone.com.au/api/v1/profile';
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final userData = decodedData["data"];

        setState(() {
          name = userData["full_name"] ?? "";
          email = userData["email"] ?? "";
          mobile = userData["phone_number"] ?? "";
          licenseNumber = userData["licence_no"] ?? "";
          companyName = userData["company_name"] ?? "";

          // Capitalize the first letter of the type/role
          String rawRole = userData["type"] ?? "Installer";
          role = rawRole.isNotEmpty
              ? '${rawRole[0].toUpperCase()}${rawRole.substring(1)}'
              : rawRole;
        });
      } else {
        print("API Failed");
      }
    } catch (e) {
      print("Error => $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void moveConnect() {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectScreen()));
  }

  Future<void> showLogoutDialog(BuildContext context) {
    // Keep your existing logout dialog logic here
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Logout")),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              "Your installer account",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39AEFB).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39AEFB), // Cyan Button
                  foregroundColor: Colors.black, // Dark Text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  "Assist",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF39AEFB)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCertificationCard(),
            const SizedBox(height: 24),

            _buildSectionTitle("ABOUT YOU"),
            _buildSectionContainer([
              _buildInfoTile(label: "FULL NAME", value: name),
              _buildDivider(),
              _buildInfoTile(label: "TITLE / ROLE", value: role),
              _buildDivider(),
              _buildInfoTile(label: "LICENSE NUMBER", value: licenseNumber),
            ]),

            const SizedBox(height: 24),

            _buildSectionTitle("CONTACT"),
            _buildSectionContainer([
              _buildInfoTile(
                label: "EMAIL",
                value: email,
                icon: Icons.mail_outline,
              ),
              _buildDivider(),
              _buildInfoTile(
                label: "PHONE",
                value: mobile,
                icon: Icons.phone_outlined,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionTitle("COMPANY"),
            _buildSectionContainer([
              _buildInfoTile(
                label: "COMPANY",
                value: companyName,
                icon: Icons.domain,
              ),
              // _buildDivider(),
              // _buildInfoTile(label: "ABN", value: abn),
            ]),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => showLogoutDialog(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF14213D),
                  side: BorderSide(color: Colors.blueGrey.shade700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                label: const Text(
                  "Sign out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildCertificationCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A3E26), // Golden dark tint
            const Color(0xFF161F33).withOpacity(0.8), // Navy blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          // Hexagon/Badge placeholder
          Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE2A938), // Gold color
              shape: BoxShape.circle, // Using circle as fallback for hexagon
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CERTIFICATION",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "aetherPro Elite",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$name • $companyName",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13192B), // Section Background Color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile({required String label, required String value, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C253B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF39AEFB), size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isNotEmpty ? value : "Not provided",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // // Edit Icon
          // Container(
          //   padding: const EdgeInsets.all(6),
          //   decoration: const BoxDecoration(
          //     color: Color(0xFF1C253B),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(Icons.edit, color: Colors.grey, size: 14),
          // ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.white10,
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
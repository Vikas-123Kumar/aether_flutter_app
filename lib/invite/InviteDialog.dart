import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';

import '../InternetService.dart';

class InviteDialog extends StatefulWidget {
  @override
  _InviteDialogState createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String selectedPermission = "control"; // control / view
  bool isLoading = false;
  String device_id = DeviceInformations.selectedDeviceId;

  Future<void> sendInvite() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }
    bool connected = await InternetService().hasInternet();
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection"),
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      String token = prefs.getString("token") ?? "";
      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/inviteUser"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": nameController.text,
          "email": emailController.text,
          "permission": selectedPermission,
          "device_id": device_id,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiMsg = data['message'] ?? "Something went wrong";
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(apiMsg)),
        );
      } else {
        final data = jsonDecode(response.body);
        final apiMsg = data['message'] ?? "Something went wrong";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text(apiMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error sending invite")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1C2C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Invite family member",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            /// Name
            _field("Full name", "e.g. Sarah Marsden", nameController),

            const SizedBox(height: 12),

            /// Email
            _field("Email", "name@email.com", emailController),

            const SizedBox(height: 16),

            /// Permission
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Permission",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _permissionCard(
                    title: "Can control",
                    subtitle: "Adjust temp, modes & timers",
                    value: "control",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _permissionCard(
                    title: "View only",
                    subtitle: "See status & alerts \n",
                    value: "view",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Send invite"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Input Field
  Widget _field(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// Permission Card
  Widget _permissionCard({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = selectedPermission == value;

    return GestureDetector(
      onTap: () {
        setState(() => selectedPermission = value);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.white12),
          color: isSelected
              ? Colors.blue.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: isSelected ? Colors.blue : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

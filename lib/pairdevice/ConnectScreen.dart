import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:untitled/pairdevice/ConnectedScreen.dart';

import '../authentication/rest/APIService.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isLoading = false;
  int _selectedNetworkIndex = 0;
  final TextEditingController _serialnumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController ssidController = TextEditingController();

  Future<void> sendWifiCredentials() async {
    String ssid = ssidController.text.trim();
    String password = _passwordController.text.trim();
    String serialNumber = _serialnumberController.text.trim();
    if (serialNumber.isEmpty || ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }
    // Encode to handle spaces like "OM NAMAH SHIVAYA"
    String url =
        "http://192.168.4.1/wifisave?s=${Uri.encodeComponent(ssid)}&p=${Uri.encodeComponent(password)}";

    try {

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("Success: ${response.body}");
      } else {
        print("Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
    await Future.delayed(const Duration(seconds: 8));

    /// SYNC DEVICE TO SERVER
    await syncDevice(serialNumber);
  }
  Future<void> syncDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
   int user_id = prefs.getInt("user_id") ??0;
    String currentRole = prefs.getString("current_role") ?? "";
    try {
      String apiEndpoint = currentRole == "installer"
          ? "syncDeviceByInstaller"
          : "syncDevice";
      final response = await ApiService().post(
        apiEndpoint,
        {
          "device_id": deviceId,
          "user_id": user_id.toString(),
        },
      );

      print("Sync Response => ${response.data}");

      final data = response.data;

      bool success = data["success"] ?? false;
      String message = data["message"] ?? "";

      /// SUCCESS
      if (success == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedScreen(
              serial_number: deviceId,
            ),
          ),
        );
      }
      /// DEVICE ALREADY SYNCED
      else if (message.contains("already sync")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );        /// STILL OPEN NEXT SCREEN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedScreen(
              serial_number: deviceId,
            ),
          ),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print("Sync Error => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e")),
      );
    }
  }
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Connect",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "System notifications & diagnostics",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF162544),
                foregroundColor: const Color(0xFF00B4D8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.star_border, size: 14),
              label: const Text("Assist", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF161F33),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Text(
                      "A",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Aether Home 270L - AE-HP-2402-7841",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Set Wi-Fi Details",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _serialnumberController,
              hint: "Enter Serial Number",
              icon: Icons.device_thermostat,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: ssidController,
              hint: "SSID",
              icon: Icons.wifi,
            ),
            const SizedBox(height: 16),
            const Text(
              "PASSWORD",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161F33),
                hintText: "Enter Wi-Fi password",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Color(0xFF00B4D8),
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF00B4D8), size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your password is sent over an encrypted Wi-Fi link directly to your device. We never store it.",
                    style: TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : sendWifiCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Connect device",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:  Icon(icon, color: Color(0xFF00B4D8), size: 18),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF121A2F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

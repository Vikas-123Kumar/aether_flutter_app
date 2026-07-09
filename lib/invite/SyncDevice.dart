import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';

import '../InternetService.dart';
import '../authentication/rest/APIService.dart';
import '../pairdevice/ConnectedScreen.dart';

class Syncdevice extends StatefulWidget {
  @override
  _SyncdeviceState createState() => _SyncdeviceState();
}

class _SyncdeviceState extends State<Syncdevice> {
  final device_id = TextEditingController();

  String selectedPermission = "control"; // control / view
  bool isLoading = false;

  Future<void> syncDevice() async {
    if (device_id.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter device serial number")),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    int user_id = prefs.getInt("user_id") ?? 0;
    print("user id" + user_id.toString());
    String currentRole = prefs.getString("current_role") ?? "";
    try {
      bool connected = await InternetService().hasInternet();
      if (!connected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Internet Connection")));
        return;
      }
      String apiEndpoint = currentRole == "Installer"
          ? "syncDeviceByInstaller"
          : "syncDevice";
      final response = await ApiService().post(apiEndpoint, {
        "device_id": device_id.text,
        "user_id": user_id.toString(),
      });

      print("Sync Response => ${response.data}");
      final data = response.data;
      bool success = data["success"] ?? false;
      String message = data["message"] ?? "";

      /// SUCCESS
      if (success == true) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConnectedScreen(serial_number: device_id.text),
          ),
        );
      }
      /// DEVICE ALREADY SYNCED
      else if (message.contains("already sync")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        /// STILL OPEN NEXT SCREEN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConnectedScreen(serial_number: device_id.text),
          ),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      print("Sync Error => $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
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
                "Sync Device",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            /// Name
            _field("Serial Number", "e.g. 1234567", device_id),

            const SizedBox(height: 12),

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
                  onPressed: isLoading ? null : syncDevice,
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
                      : const Text("Sync"),
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

}

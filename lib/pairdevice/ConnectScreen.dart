import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:untitled/pairdevice/ConnectedScreen.dart';

import '../authentication/rest/APIService.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isLoading = false;
  double _progress = 0.0; // Tracks progress from 0.0 to 1.0
  String _loadingMessage = ""; // Track current step description
  int _selectedNetworkIndex = 0;
  final TextEditingController _serialnumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController ssidController = TextEditingController();
  String ssid = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadWifi();
    });
  }

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

    // Step 1: Send Wi-Fi credentials to hardware
    setState(() {
      _isLoading = true;
      _progress = 0.15;
      _loadingMessage = "Sending Wi-Fi credentials to device...";
    });

    String url =
        "http://192.168.4.1/wifisave?s=${Uri.encodeComponent(ssid)}&p=${Uri.encodeComponent(password)}";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("Success sending Wi-Fi info: ${response.body}");
      } else {
        print("Failed to send Wi-Fi info: ${response.statusCode}");
      }
    } catch (e) {
      print("Error connecting to hardware: $e");
      // Stop process if hardware request fails
    }

    // Step 2: Waiting for hardware to connect to Wi-Fi
    setState(() {
      _progress = 0.50;
    });

    await Future.delayed(const Duration(seconds: 8));

    // Step 3: Syncing device with backend server
    setState(() {
      _progress = 0.80;
      _loadingMessage = "Syncing device with server...";
    });

    await syncDevice(serialNumber);
  }

  Future<bool> requestPermission() async {
    // 1. Check if the device's Location Service (GPS) is physically turned on
    bool serviceEnabled = await Permission.location.serviceStatus.isEnabled;

    if (!serviceEnabled) {
      if (!mounted) return false;

      // Show dialog asking user to turn on GPS
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF161F33),
          title: const Text(
            "Location is off",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Please turn on your device's Location (GPS) from the quick settings menu to fetch the Wi-Fi name.",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          ],
        ),
      );
      return false;
    }

    // 2. Request Location Permission if GPS is on
    var status = await Permission.location.request();

    if (status.isGranted) {
      return true;
    }
    // 3. Handle if the user clicked "Don't ask again" (Permanently Denied)
    else if (status.isPermanentlyDenied) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF161F33),
          title: const Text(
            "Permission Required",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Location permission is required to detect the connected Wi-Fi. Please allow it in the App Settings.",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Opens device settings for your app
              },
              child: const Text("Open Settings", style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          ],
        ),
      );
    }

    return false;
  }

  Future<void> loadWifi() async {
    bool granted = await requestPermission();

    if (!granted) {
      print("Permission denied");
      return;
    }
    await getConnectedWifi();
  }

  Future<void> getConnectedWifi() async {
    try {
      final info = NetworkInfo();
      final wifiName = (await info.getWifiName())?.replaceAll('"', '');
      if (!mounted) return;
      setState(() {
        ssid = wifiName ?? "";
        ssidController.text = ssid;
      });
    } catch (e) {
      print("Error getting WiFi info: $e");
    }
  }

  Future<void> syncDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 0;
    String currentRole = prefs.getString("current_role") ?? "";

    try {
      String apiEndpoint =
      currentRole == "Installer" ? "syncDeviceByInstaller" : "syncDevice";

      final response = await ApiService().post(apiEndpoint, {
        "device_id": deviceId,
        "user_id": userId.toString(),
      });

      final data = response.data;
      bool success = data["success"] ?? false;
      String message = data["message"] ?? "";

      // Set progress complete
      setState(() {
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 300)); // Brief pause to complete progress bar animation

      if (!mounted) return;

      /// ALWAYS HIDE LOADING OVERLAY regardless of success or failure
      setState(() {
        _isLoading = false;
      });

      if (success == true || message.contains("already sync")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedScreen(serial_number: deviceId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      print("Sync Error => $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _serialnumberController.dispose();
    ssidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 15,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Connect",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "System notifications & diagnostics",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        child: const Text("A", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Aether Home", style: TextStyle(color: Colors.white, fontSize: 16)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(width: 6),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Set Wi-Fi Details", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                _buildTextField(controller: _serialnumberController, hint: "Enter Serial Number", icon: Icons.device_thermostat),
                const SizedBox(height: 12),
                _buildTextField(controller: ssidController, hint: "SSID", icon: Icons.wifi),
                const SizedBox(height: 16),
                const Text("PASSWORD", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF00B4D8), size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF00B4D8), size: 14),
                    SizedBox(width: 8),
                    Expanded(child: Text("Your password is sent over an encrypted Wi-Fi link directly to your device. We never store it.", style: TextStyle(color: Colors.grey, fontSize: 9))),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    ),
                    child: const Text("Connect device", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Custom Progress Bar Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F33),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: const Color(0xFF00B4D8).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pairing Device",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${(_progress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Color(0xFF00B4D8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF0C101B),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00B4D8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00B4D8), size: 18),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF121A2F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
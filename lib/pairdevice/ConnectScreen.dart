import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:untitled/pairdevice/ConnectedScreen.dart';
import 'package:untitled/pairdevice/StepSixScreen.dart';

import '../authentication/rest/APIService.dart';

class ConnectScreen extends StatefulWidget {
  final bool fromNoDevice;
  final bool manualEnter;
  final String serial_number;

  ConnectScreen({
    super.key,
    this.fromNoDevice = false,
    this.manualEnter = false,
    required this.serial_number,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isLoading = false;
  final TextEditingController _serialnumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController ssidController = TextEditingController();
  String ssid = "";
  final Color cardBg = const Color(0xFF0F1726);
  String serialNumber = "";
  static const Color blue = Color(0xFF4CA6FF);

  @override
  void initState() {
    super.initState();
    _serialnumberController.text = widget.serial_number;
    serialNumber= widget.serial_number;
    print(widget.serial_number);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadWifi();
    });
  }

  Future<void> sendWifiCredentials() async {
    String ssid = ssidController.text.trim();
    String password = _passwordController.text.trim();
    if ( ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }
    if(widget.manualEnter&&_serialnumberController.text.trim().isEmpty){
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }else{
      serialNumber=_serialnumberController.text;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
         StepSixScreen(ssid: ssid, password: password, serialnumber: serialNumber),
      ),
    );  }

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
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFF00B4D8)),
              ),
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
              child: const Text(
                "Open Settings",
                style: TextStyle(color: Color(0xFF00B4D8)),
              ),
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
        leadingWidth: widget.fromNoDevice ? 56 : 0,
        leading: widget.fromNoDevice
            ? Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ),
              )
            : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Wi-Fi network",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Step 5 of 6",
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 15.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1533C2FF), Color(0xFF1533C2FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: blue.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      // 1. Glowing Wi-Fi Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF57BAFF), Color(0xFF3886FF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CA6FF).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.wifi,
                          color: Color(0xFF001A33), // Dark navy icon color
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // 2. Text Information Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Label
                            Text(
                              "DETECTED NETWORK",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Wi-Fi SSID
                            Text(
                              ssid.isNotEmpty
                                  ? "$ssid"
                                  : "Not connected to Wi-Fi",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              "Pairing with ${widget.serial_number}",
                              // Ensure you pass the serial number variable here
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
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
                if(widget.manualEnter)
                 const SizedBox(height: 12),
                if(widget.manualEnter)
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
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFF39AEFB),
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
                    Icon(
                      Icons.lock_outline,
                      color: Color(0xFF39AEFB),
                      size: 14,
                    ),
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
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF57BAFF), Color(0xFF3886FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CA6FF).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _isLoading ? null : sendWifiCredentials();
                        // TODO: Navigate to Step 4
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Color(0xFF001A33), // Dark navy text
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF001A33),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        prefixIcon: Icon(icon, color: const Color(0xFF39AEFB), size: 18),
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

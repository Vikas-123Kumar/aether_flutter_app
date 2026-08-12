import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../authentication/rest/APIService.dart';
import 'ConnectedScreen.dart';

class StepSixScreen extends StatefulWidget {
  String ssid = "";
  String password = "";
  String serialnumber = "";

  StepSixScreen({
    super.key,
    required this.ssid,
    required this.password,
    required this.serialnumber,
  });

  @override
  State<StepSixScreen> createState() => _StepSixScreenState();
}

class _StepSixScreenState extends State<StepSixScreen>
    with WidgetsBindingObserver {
  static const Color bgColorStart = Color(0xFF0F1725);
  static const Color bgColorEnd = Color(0xFF0A101A);
  bool _isLoading = false;

  static const Color blue = Color(0xFF4CA6FF);

  // Change this according to your actual device SSID.
  final String deviceWifiName = "AL-0000000";
  String ssid = "";
  bool isConnected = false;
  bool hasReturnedFromSettings = false;
  double _progress = 0.0; // Tracks progress from 0.0 to 1.0
  String _loadingMessage = ""; // Track current step description
  @override
  void initState() {
    super.initState();
    ssid = widget.ssid;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> sendWifiCredentials() async {
    if (widget.ssid.isEmpty || widget.password.isEmpty) {
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
        "http://192.168.4.1/wifisave?s=${Uri.encodeComponent(widget.ssid)}&p=${Uri.encodeComponent(widget.password)}";

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

    await syncDevice(widget.serialnumber);
  }

  Future<void> syncDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 0;
    String currentRole = prefs.getString("current_role") ?? "";

    try {
      String apiEndpoint = currentRole == "Installer"
          ? "syncDeviceByInstaller"
          : "syncDevice";

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

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Brief pause to complete progress bar animation

      if (!mounted) return;

      /// ALWAYS HIDE LOADING OVERLAY regardless of success or failure
      setState(() {
        _isLoading = false;
      });

      if (success == true || message.contains("already sync")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedScreen(serial_number: deviceId),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      print("Sync Error => $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _openWifiSettings() async {
    final Uri settingsUri = Uri(
      scheme: 'android.settings',
      host: 'WIFI_SETTINGS',
    );
    try {
      await launchUrl(settingsUri);
    } catch (e) {
      debugPrint('Unable to open Wi-Fi settings: $e');
    }
  }

  // ----------------------------------------------------------
  // Detect when user returns from Wi-Fi settings
  // ----------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (hasReturnedFromSettings) {
        // User has returned from Wi-Fi settings.
        setState(() {
          hasReturnedFromSettings = false;
        });

        _checkWifiConnection();
      }
    }
  }

  // ----------------------------------------------------------
  // Open Wi-Fi Settings
  // ----------------------------------------------------------

  // ----------------------------------------------------------
  // Check Wi-Fi connection
  // ----------------------------------------------------------

  Future<void> _checkWifiConnection() async {
    /*
     * IMPORTANT:
     *
     * Put your actual Wi-Fi checking logic here.
     *
     * Example:
     *
     * final ssid = await getConnectedWifi();
     *
     * if (ssid == deviceWifiName) {
     *   setState(() {
     *     isConnected = true;
     *   });
     * }
     */

    // Temporary example.
    //
    // Do NOT automatically mark it connected in production.
    // Instead, check the actual connected SSID.

    debugPrint("Checking Wi-Fi connection...");
  }

  // ----------------------------------------------------------
  // Continue
  // ----------------------------------------------------------

  void _continue() {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please connect to the device Wi-Fi first."),
        ),
      );

      return;
    }

    // Navigate to next step.
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => const NextScreen(),
    //   ),
    // );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColorEnd,
      body: Stack(
        children: [
          // =====================================================
          // 1. MAIN SCREEN CONTENT
          // =====================================================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColorStart, bgColorEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final double wifiCardHeight = screenHeight < 700 ? 130 : 146;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Join the device Wi-Fi",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Step 6 of 6",
                                  style: TextStyle(
                                    color: Color(0xFF9298A3),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // DESCRIPTION
                        const Text(
                          "Your heat pump broadcasts its own temporary network. "
                              "Connect your phone to it once, and we'll hand over "
                              "your home Wi-Fi details automatically.",
                          style: TextStyle(
                            color: Color(0xFF9298A3),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // WIFI MOCKUP
                        Container(
                          width: double.infinity,
                          height: wifiCardHeight,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.phone_android,
                                    color: Color(0xFF9298A3),
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Phone · Settings › Wi-Fi",
                                    style: TextStyle(
                                      color: Color(0xFF9298A3),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15191F),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.wifi, color: blue, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deviceWifiName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                const Text(
                                                  "Aether heat pump · no password",
                                                  style: TextStyle(color: Color(0xFF777D87), fontSize: 8),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Color(0xFF20242A), height: 18),
                                      Row(
                                        children: [
                                          const Icon(Icons.wifi, color: Color(0xFF4C535E), size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              ssid,
                                              style: const TextStyle(color: Color(0xFF777D87), fontSize: 12),
                                            ),
                                          ),
                                          const Icon(Icons.check, color: Color(0xFF4C535E), size: 16),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // HOW TO DO IT
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2432),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "How to do it",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              _instruction("1.", "Tap the button below to open your phone's Wi-Fi settings."),
                              _instruction("2.", "Choose Aether Heat Pump Wi-Fi"),
                              _instruction("3.", 'Ignore "no internet" warnings, then come back to this app.'),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // OPEN WIFI SETTINGS BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF182534),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.white.withOpacity(0.07)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () {
                                  AppSettings.openAppSettings(type: AppSettingsType.wifi);
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.settings_outlined, color: blue, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      "Open phone Wi-Fi settings",
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CONNECTED BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF57BAFF), Color(0xFF3886FF)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: blue.withOpacity(0.30),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () => sendWifiCredentials(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Connect",
                                      style: const TextStyle(color: Color(0xFF001A33), fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, color: Color(0xFF001A33), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Notice the _isLoading UI is NO LONGER HERE
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // =====================================================
          // 2. LOADING PROGRESS OVERLAY (Appears on top)
          // =====================================================
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.8), // Darkens the background
              child: Center( // Centers the dialog on the screen
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
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
  // ============================================================
  // INSTRUCTION WIDGET
  // ============================================================

  Widget _instruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              number,
              style: const TextStyle(color: Color(0xFF68717D), fontSize: 10),
            ),
          ),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF808995),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

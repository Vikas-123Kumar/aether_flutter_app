import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Ensure these imports match your project structure
import 'package:untitled/CustomerInformation.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../authentication/model/DeviceDataModel.dart';

class Installerdeviceinfoscreen extends StatefulWidget {
  final String deviceId;

  const Installerdeviceinfoscreen({super.key, required this.deviceId});

  @override
  State<Installerdeviceinfoscreen> createState() =>
      _InstallerdeviceinfoscreenState();
}

class _InstallerdeviceinfoscreenState extends State<Installerdeviceinfoscreen> {
  // --- STATE VARIABLES ---
  String currentTemp = "0";
  String unit = "°C";
  int targetTemp = 52;
  String selectedMode = "Standard";
  String runtime = "";
  bool isUpdatingTemp = false;
  bool isLoading = true;
  bool isPowerOn = false;
  bool isCheckingDevices = false;
  List<DeviceDataModel> deviceData = [];
  bool isDeviceActive = false;
  String deviceName = "Loading...";

  // --- DESIGN COLORS ---
  final Color bgDark = const Color(0xFF090D14);
  final Color cardBorder = const Color(0xFF1E293B);
  final Color cardBg = const Color(0xFF0F1724);
  final Color neonBlue = const Color(0xFF38B6FF);
  final Color neonCyan = const Color(0xFF00F0FF);
  final Color textGrey = const Color(0xFF8B9CB6);

  @override
  void initState() {
    super.initState();
    deviceName = DeviceInformations.selectedDeviceName ?? "Unknown Device";
    getDeviceData(); // Fetch live data on init
  }


  String formatTemperature(String value) {
    final temp = double.tryParse(value);
    if (temp == null) return value;

    return temp == temp.roundToDouble()
        ? temp.toInt().toString()
        : temp.toStringAsFixed(1);
  }
  // --- API METHODS (From your original code) ---

  DeviceDataModel? getItem(String alias) {
    try {
      return deviceData.firstWhere((e) => e.alias == alias);
    } catch (e) {
      return null;
    }
  }

  Future<void> getDeviceData() async {
    try {
      setState(() {
        isLoading = true;
        deviceName = DeviceInformations.selectedDeviceName ?? "";
      });

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      String deviceId = DeviceInformations.act_device_id;

      print("device in installer $deviceId");
      final response = await http.get(
        Uri.parse(
          "https://aetherone.com.au/api/v1/heat-pump-2/devices/$deviceId/current-data",
        ),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List dataList = decoded['data']['data'];

        setState(() {
          if (DeviceInformations.is_online == "1") {
            isDeviceActive = true;
          }
          deviceData = dataList
              .map((e) => DeviceDataModel.fromJson(e))
              .toList();

          final setPointData = deviceData.firstWhere(
            (item) => item.itemid == "3",
          );
          final setPointDataMode = deviceData.firstWhere(
            (item) => item.itemid == "2",
          );
          final setPointDataModemiddle = deviceData.firstWhere(
            (item) => item.itemid == "15",
          );
          final setPointDataPower = deviceData.firstWhere(
            (item) => item.itemid == "1",
          );
          final dc_runtime = deviceData.firstWhere(
            (item) => item.itemid == "25",
          );

          if (setPointDataMode.val == "2") {
            selectedMode = "Eco";
          } else if (setPointDataMode.val == "0") {
            selectedMode = "Standard";
          } else if (setPointDataMode.val == "1") {
            selectedMode = "Boost";
          }

          currentTemp = setPointDataModemiddle.val;
          targetTemp = int.parse(setPointData.val);
          unit = setPointData.unit;
          isPowerOn = setPointDataPower.val == "1";
          runtime = dc_runtime.val;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // --- URL LAUNCHER HELPERS ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the phone dialer.")),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the email client.")),
        );
      }
    }
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    if (isCheckingDevices || isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // 1. Background Grid Pattern
          // Positioned.fill(
          //   child: CustomPaint(
          //     painter: GridPainter(),
          //   ),
          // ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildCustomerCard(), // Uses live customer data
                  const SizedBox(height: 40),
                  _buildMainDial(), // Uses live temp data
                  const SizedBox(height: 24),
                  _buildStatusPills(), // Uses live status data
                  const SizedBox(height: 30),
                  _buildDataGrid(), // Live + mock data grid
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Back Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cardBg,
            border: Border.all(color: cardBorder),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),

        // Title & Subtitle (Live Device Name)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Diagnostics",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(deviceName, style: TextStyle(color: textGrey, fontSize: 12)),
            ],
          ),
        ),

        // Assist Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF22B4F8), Color(0xFF00D4FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Assist action
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.black87, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Assist",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard() {
    // Safely parse Customer Name & Initial
    String custName = CustomerInformation.customerName.isNotEmpty
        ? CustomerInformation.customerName
        : "Unknown Customer";
    String initial = custName.isNotEmpty ? custName[0].toUpperCase() : "U";

    String custEmail = CustomerInformation.customerEmail.isNotEmpty
        ? CustomerInformation.customerEmail
        : "";
    String custPhone = CustomerInformation.customerPhone.isNotEmpty
        ? CustomerInformation.customerPhone
        : "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      custName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${custEmail.isNotEmpty ? custEmail : 'No Email Provided'}\n${custPhone.isNotEmpty ? custPhone : 'No Phone Provided'}",
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              // --- CALL BUTTON ---
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (custPhone.isNotEmpty) {
                      _makePhoneCall(custPhone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No phone number available"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    "Call",
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.02),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // --- MESSAGE (EMAIL) BUTTON ---
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (custEmail.isNotEmpty) {
                      _sendEmail(custEmail);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No email address available"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    "Message",
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.02),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainDial() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgDark,
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.15),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: neonBlue.withOpacity(0.3), width: 2),
            ),
          ),
          // Inner Ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 6),
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                "TANK",
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTemp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      unit,
                      style: TextStyle(color: textGrey, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Horizontal glowing line cutting through
          Positioned(
            bottom: 60,
            child: Container(
              width: 140,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    neonBlue.withOpacity(0.0),
                    neonBlue,
                    neonBlue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPills() {
    return Column(
      children: [
        // Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPowerOn ? const Color(0xFFFF6D00) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPowerOn ? "Heating" : "Standby",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Connectivity Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDeviceActive
                ? const Color(0xFF0F3D2E).withOpacity(0.5)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDeviceActive
                  ? const Color(0xFF1E6E5B)
                  : Colors.redAccent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDeviceActive ? const Color(0xFF00E676) : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isDeviceActive ? "Live - streaming telemetry" : "Offline",
                style: TextStyle(
                  color: isDeviceActive ? const Color(0xFF00E676) : Colors.red,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataGrid() {
    // Finding specific values if available in deviceData array, otherwise using defaults/placeholders
    String currentDefrost = getItem("Defrost")?.val ?? "Idle";

    return Column(
      children: [
        Row(
          children: [
            _buildGridCard(
              Icons.thermostat,
              "TANK",
              "${formatTemperature(currentTemp)}$unit",
              "target $targetTemp°",
              neonBlue,
            ),
            const SizedBox(width: 10),
            _buildGridCard(
              Icons.show_chart,
              "MODE",
              selectedMode,
              "auto-balanced",
              neonBlue,
            ),
            const SizedBox(width: 10),
            _buildGridCard(
              Icons.ac_unit,
              "DEFROST",
              currentDefrost,
              "last 11:08",
              neonBlue,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildGridCard(Icons.speed, "COP", "3.84", "last 24h", neonBlue),
            const SizedBox(width: 10),
            _buildGridCard(
              Icons.access_time,
              "RUNTIME",
              runtime,
              "since install",
              neonBlue,
            ),
            const SizedBox(width: 10),
            _buildGridCard(
              Icons.flash_on,
              "POWER",
              "1.6 kW",
              "current draw",
              neonBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textGrey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: textGrey.withOpacity(0.6), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw the faint blueprint-style grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.3)
      ..strokeWidth = 1.0;

    const double step = 20.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw subtle reddish overlay lines matching the image's matrix feel
    final redPaint = Paint()
      ..color = Colors.red.withOpacity(0.03)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += step * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), redPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

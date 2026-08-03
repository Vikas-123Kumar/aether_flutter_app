import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/authentication/rest/APIService.dart';
import '../authentication/model/AlertModel.dart';

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<AlertModel>> alertsFuture;
  var api = ApiService();

  // Background and primary theme colors based on the design
  final Color bgColor = const Color(0xFF09101C);
  final Color cardBgColor = const Color(0xFF131A2A);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    alertsFuture = api.fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _header(),
            const SizedBox(height: 24),
            _criticalStats(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<AlertModel>>(
                future: alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("No alerts found.",
                            style: TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("No alerts found.",
                            style: TextStyle(color: Colors.white54)));
                  } else {
                    final alerts = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        return AlertCard(alert: alerts[index]);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Alerts",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "System notifications & diagnostics",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criticalStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _box("CRITICAL", "0", const Color(0xFFE54B4B)),
          const SizedBox(width: 12),
          _box("WARNING", "0", const Color(0xFFF7B731)),
          const SizedBox(width: 12),
          _box("INFO", "0", const Color(0xFF4B7BEC)),
        ],
      ),
    );
  }

  Widget _box(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final AlertModel alert;

  const AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    // Determine colors and icons based on the string type
    // Make sure your API returns "critical", "warning", or "info"
    Color typeColor;
    IconData typeIcon;
    String typeText = alert.type.toUpperCase();

    switch (alert.type.toLowerCase()) {
      case 'critical':
        typeColor = const Color(0xFFE54B4B);
        typeIcon = Icons.wifi_off; // Matching the connectivity loss icon
        break;
      case 'warning':
        typeColor = const Color(0xFFF7B731);
        typeIcon = Icons.build_outlined; // Matching the wrench icon
        break;
      case 'info':
      default:
        typeColor = const Color(0xFF4B7BEC);
        typeIcon = Icons.thermostat_outlined; // Matching the defrost icon
        typeText = 'INFO';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.04), // Slight tint of the background
        border: Border.all(color: typeColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert.time,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

import '../DeviceInformations.dart';
import '../authentication/NewLoginScreen.dart';
import '../authentication/model/Device.dart';
import '../authentication/model/DeviceDataModel.dart';
import '../authentication/rest/APIService.dart';

class Installerlist extends StatefulWidget {
  const Installerlist({super.key});

  @override
  State<Installerlist> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<Installerlist> {
  final ApiService apiService = ApiService();
  String currentTemp = "0";
  String unit = "";
  int targetTemp = 52;
  String selectedMode = "Comfort";
  bool isUpdatingTemp = false;
  String mode = "ECO"; // standard / eco / boost
  bool isPowerOn = false;
  bool isCheckingDevices = true;
  List<DeviceDataModel> deviceData = [];
  bool isDeviceActive = false;
  String device_name = "";
  List devices = [];
  bool isLoading = true;
  int totalDevices = 0;
  int onlineDevices = 0;
  Future<void> loadUserDeviceList() async {
    try {
      final response = await ApiService().get("listUserDevices");

      final data = response.data;

      if (data["message"] == "Unauthenticated." || response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NewLoginScreen()),
          (route) => false,
        );
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          devices = data["devices"] ?? [];
          isLoading = false;
          totalDevices = devices.length;
          onlineDevices = devices
              .where((d) => d["is_online"] == 1)
              .length;

        });
      }
    } catch (e) {
      print("Error => $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              _statsRow(),
              const SizedBox(height: 16),
              _linkDeviceCard(context),
              const SizedBox(height: 16),
              _searchBar(),
              const SizedBox(height: 16),

              /// LIST FROM API
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : devices.isEmpty
                    ? const Center(
                        child: Text(
                          "No Devices Found",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return _deviceCard(device);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.build, color: Colors.white),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INSTALLED",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "Greenline Tech",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {},
            child: const Text("Assist"),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS ----------------
  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statCard("SYSTEMS",totalDevices, "$onlineDevices online")),
        const SizedBox(width: 10),
        Expanded(child: _statCard("OPEN ALERTS", 5, "3 need attention")),
      ],
    );
  }

  Widget _statCard(String title, int value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  // ---------------- LINK DEVICE ----------------
  Widget _linkDeviceCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConnectScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7DFF), Color(0xFF4FC3F7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.add_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Link a new device",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ---------------- SEARCH ----------------
  Widget _searchBar() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search...",
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF121A2F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- DEVICE CARD ----------------
  Widget _deviceCard(dynamic device) {
    bool isOnline = device["is_online"] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.warning,
            color: isOnline ? Colors.green : Colors.orange,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device["name"] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  device["serial_number"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOnline ? "Online" : "Offline",
                style: TextStyle(color: isOnline ? Colors.green : Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- COMMON ----------------
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF121A2F),
      borderRadius: BorderRadius.circular(16),
    );
  }
}

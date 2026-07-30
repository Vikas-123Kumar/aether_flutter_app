import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/CustomerInformation.dart';
import 'package:untitled/installer/InstallerDeviceInfoScreen.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

import '../DeviceInformations.dart';
import '../DeviceListItem.dart';
import '../InternetService.dart';
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
  String device_name = "", company_name = "";
  List devices = [];
  List filteredDevices = []; // Holds the filtered list for the UI

  bool isLoading = true;
  int totalDevices = 0;
  int onlineDevices = 0;

  Future<void> loadUserDeviceList() async {
    try {
      bool connected = await InternetService().hasInternet();
      final prefs = await SharedPreferences.getInstance();
      int user_id = prefs.getInt("user_id") ?? 0;
      print("user id: " + user_id.toString());
      company_name =
          prefs.getString("company_name") ??
          prefs.getString("installer_company") ??
          "";
      if (!connected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Internet Connection")));
        return;
      }

      final response = await ApiService().get("listInstallerInstalledDevices");
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
          filteredDevices = List.from(devices); // Initialize the filtered list

          isLoading = false;
          totalDevices = devices.length;
          onlineDevices = devices.where((d) => d["is_online"] == 1).length;
        });
      }
    } catch (e) {
      print("Error => $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getDeviceData(String deviceId) async {
    try {
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
        int length = dataList.length;
        print("list size$length");
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
          final setPointDataPower = deviceData.firstWhere(
            (item) => item.itemid == "1",
          );
          print(" data points${setPointData.val}${setPointData.unit}");
          currentTemp = setPointData.val;
          targetTemp = int.parse(setPointData.val);
          unit = setPointData.unit;
          isPowerOn = setPointDataPower.val == "1";
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

  // --- FILTER LOGIC ---
  void _runFilter(String enteredKeyword) {
    List results = [];
    if (enteredKeyword.isEmpty) {
      // If the search field is empty, show all devices
      results = List.from(devices);
    } else {
      results = devices.where((device) {
        final customer = device["customer"];

        // Safely extract fields to search against and convert them to lowercase
        final customerName = customer?["name"]?.toString().toLowerCase() ?? "";
        final address = customer?["address"]?.toString().toLowerCase() ?? "";
        final serialNumber =
            device["serial_number"]?.toString().toLowerCase() ?? "";
        final deviceName = device["name"]?.toString().toLowerCase() ?? "";

        final query = enteredKeyword.toLowerCase();

        // Return true if any of the fields contain the search query
        return customerName.contains(query) ||
            address.contains(query) ||
            serialNumber.contains(query) ||
            deviceName.contains(query);
      }).toList();
    }

    // Refresh the UI with the new filtered list
    setState(() {
      filteredDevices = results;
    });
  }

  @override
  void initState() {
    super.initState();

    loadUserDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B111E), // Deep dark background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerCard(),
                    const SizedBox(height: 24),
                    _statsRow(),
                    const SizedBox(height: 24),
                    _linkDeviceCard(context),
                    const SizedBox(height: 24),
                    _searchBar(),
                    const SizedBox(height: 24),
                    _installationsHeader(),
                    const SizedBox(height: 12),
                    _buildDeviceList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _headerCard() {
    return Row(
      children: [
        // Left Icon
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF161F33),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.build_outlined,
            color: Color(0xFF4299E1),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Middle Text (Wrapped in Expanded to fix overflow)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "INSTALLER",
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                company_name.isNotEmpty ? company_name : "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right Buttons
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4299E1).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF41BAFF),
              // Bright Blue
              foregroundColor: const Color(0xFF0B111E),
              // Dark Text
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.auto_awesome, size: 18),
            onPressed: () {},
            label: const Text(
              "Assist",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- STATS ----------------
  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "SYSTEMS",
            icon: Icons.show_chart,
            value: totalDevices,
            subtitle: "$onlineDevices online",
            subtitleColor: const Color(0xFF38A169),
            // Green
            iconColor: const Color(0xFF4299E1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "OPEN ALERTS",
            icon: Icons.notifications_none,
            value: 0,
            // Static fallback for UI parity
            subtitle: "0 need attention",
            subtitleColor: const Color(0xFFD69E2E),
            // Yellow/Orange
            iconColor: const Color(0xFFD69E2E),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required int value,
    required String subtitle,
    required Color subtitleColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF46B5FF), Color(0xFF3B82F6)],
            // Bright blue gradient
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF0B111E),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Link a new device",
                    style: TextStyle(
                      color: Color(0xFF0B111E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Pair · configure · transfer to customer",
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF0B111E),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SEARCH ----------------
  Widget _searchBar() {
    return TextField(
      onChanged: (value) => _runFilter(value), // Triggers filter on every keystroke
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search by customer, address, serial...",
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
        suffixIcon: const Icon(
          Icons.filter_alt_outlined,
          color: Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFF161F33),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- HEADER FOR LIST ----------------
  Widget _installationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "YOUR INSTALLATIONS",
          style: TextStyle(
            color: Color(0xFF8A94A6),
            fontSize: 12,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- LIST VIEW ----------------
  Widget _buildDeviceList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF41BAFF)),
        ),
      );
    }

    if (filteredDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            "No Devices Found",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredDevices.length, // Build from filtered list
      itemBuilder: (context, index) {
        final device = filteredDevices[index]; // Fetch from filtered list
        final customer = device["customer"];

        return DeviceListItem(
          device: device,
          customer: customer,
          onTap: () {
            String deviceId = device["serial_number"].toString();
            String deviceName = device["name"].toString();
            String serialNumber = device["device_id"].toString();
            String isOnline = device["is_online"].toString();

            DeviceInformations.act_device_id = deviceId;
            DeviceInformations.selectedDeviceName = deviceName;
            DeviceInformations.selectedSerialNumber = serialNumber;
            DeviceInformations.is_online = isOnline;

            CustomerInformation.customerName = customer?["name"] ?? "";
            CustomerInformation.customerEmail = customer?["email"] ?? "";
            CustomerInformation.customerPhone = customer?["phone"] ?? "";

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Installerdeviceinfoscreen(deviceId: deviceId),
              ),
            );
          },
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF161F33), // Slightly lighter than scaffold bg
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 4),
          blurRadius: 10,
        ),
      ],
    );
  }
}

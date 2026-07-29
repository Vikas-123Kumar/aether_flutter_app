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

class InstallerFulllist extends StatefulWidget {
  const InstallerFulllist({super.key});

  @override
  State<InstallerFulllist> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<InstallerFulllist> {
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

  // --- LISTS FOR SEARCH LOGIC ---
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
          if (setPointDataMode.val == "0") {
            selectedMode = "Eco";
          } else if (setPointDataMode.val == "1") {
            selectedMode = "Comfort";
          } else if (setPointDataMode.val == "2") {
            selectedMode = "Boost";
          }
          print(" mode points${setPointDataMode.val}   $selectedMode");

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
        final serialNumber = device["serial_number"]?.toString().toLowerCase() ?? "";
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
                    _searchBar(),
                    const SizedBox(height: 24),
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
              const Text(
                "Installations",
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                devices.isNotEmpty ? "${devices.length} Systems" : "",
                style: const TextStyle(
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

}
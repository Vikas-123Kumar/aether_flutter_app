import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/authentication/model/Device.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/model/DeviceDataModel.dart';
import '../authentication/rest/APIService.dart';

class NewDeviceControlScreen extends StatefulWidget {
  @override
  State<NewDeviceControlScreen> createState() => _ThermostatUIState();
}

class _ThermostatUIState extends State<NewDeviceControlScreen> {
  String currentTemp = "0";
  String unit = "";
  int targetTemp = 52;
  String selectedMode = "Comfort";
  bool isUpdatingTemp = false;
  String mode = "ECO"; // standard / eco / boost
  bool isLoading = false;
  bool isPowerOn = false;
  bool isCheckingDevices = true;
  List<DeviceDataModel> deviceData = [];
  bool isDeviceActive = false;
  String device_name = "";

  @override
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserDeviceList();
  }

  DeviceDataModel? getItem(String alias) {
    try {
      return deviceData.firstWhere((e) => e.alias == alias);
    } catch (e) {
      return null;
    }
  }

  Future<void> getDeviceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      String deviceId = DeviceInformations.act_device_id;
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
          deviceData = dataList
              .map((e) => DeviceDataModel.fromJson(e))
              .toList();
          final setPointData = deviceData.firstWhere(
            (item) => item.alias == "Setpoint DHW",
          );
          final setPointDataMode = deviceData.firstWhere(
            (item) => item.alias == "mode",
          );
          final setPointDataPower = deviceData.firstWhere(
            (item) => item.alias == "on/off",
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

  Future<void> loadUserDeviceList() async {
    try {
      final response = await ApiService().get("listUserDevices");

      final data = response.data;

      print("Response Data => $data");

      /// 🔐 HANDLE UNAUTHENTICATED
      if (data["message"] == "Unauthenticated." || response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NewLoginScreen()),
          (route) => false,
        );
        return;
      }
      if (response.statusCode == 200) {
        List devices = data["devices"] ?? [];

        /// NO DEVICE
        if (devices.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ConnectScreen()),
          );
          return;
        }

        /// FIRST DEVICE
        Map firstDevice = devices[0];

        DeviceInformations.selectedDeviceId = firstDevice["device_id"]
            .toString();
        setState(() {
          isDeviceActive = firstDevice["is_online"] == 1;
          print("device status$isDeviceActive");
        });

        DeviceInformations.selectedSerialNumber = firstDevice["serial_number"]
            .toString();

        DeviceInformations.selectedDeviceName = firstDevice["name"] ?? "";

        DeviceInformations.act_device_id = firstDevice["act_device_id"] ?? "";

        print("Selected Device ID => ${DeviceInformations.selectedDeviceId}");

        getDeviceData();

        setState(() {
          device_name=firstDevice["name"] ?? "";
          isCheckingDevices = false;
        });
      }
    } catch (e) {
      print("Catch Error => $e");

      setState(() {
        isCheckingDevices = false;
      });
    }
  }

  Future<void> updateMode(String mode) async {
    String device_id = DeviceInformations.act_device_id;
    final modeItem = getItem("mode");
    if (modeItem == null) return;
    String api_mode = "0";
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    if (mode == "ECO") {
      api_mode = "0";
    } else if (mode == "Comfort") {
      api_mode = "1";
    } else if (mode == "Boost") {
      api_mode = "2";
    }
    final response = await http.put(
      Uri.parse("https://aetherone.com.au/api/v1/heat-pump-2/control"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "devid": device_id,
        "itemid": "",
        "value": "mode=$api_mode",
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        selectedMode = mode;
      });
      getDeviceData();
    } else {
      setState(() {
        selectedMode = mode;
      });
    }
  }

  Future<void> togglePower(bool value) async {
    String device_id = DeviceInformations.act_device_id;

    final powerItem = getItem("on/off");
    if (powerItem == null) return;

    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    int power = value ? 1 : 0;
    final response = await http.put(
      Uri.parse("https://aetherone.com.au/api/v1/heat-pump-2/control"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"devid": device_id, "itemid": "1", "value": "$power"}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isPowerOn = value;
      });
      print("power status${response.body}");
      getDeviceData(); // refresh
    } else {
      print(response.body);
    }
  }

  Future<void> updateTemperature(int value) async {
    if (isUpdatingTemp) return;
    String device_id = DeviceInformations.act_device_id;

    setState(() {
      isUpdatingTemp = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final tempItem = deviceData.firstWhere(
        (item) => item.alias == "Setpoint DHW",
      );

      final response = await http.put(
        Uri.parse("https://aetherone.com.au/api/v1/heat-pump-2/control"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "devid": device_id,
          "itemid": tempItem.itemid,
          "value": value.toString(),
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["data"] != null && data["data"]["status"] == "106") {
          final apiMsg = data['data']?['msg'] ?? "Something went wrong";

          // check device status code
          if (data['data']?['status'] == "106") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiMsg), backgroundColor: Colors.red),
            );
            return;
          }
          return;
        }
        setState(() {
          targetTemp = value;
        });

        /// keep loader visible for 10 seconds
        await Future.delayed(const Duration(seconds: 10));

        await getDeviceData();
      }
    } catch (e) {
      print("TEMP UPDATE ERROR => $e");
    } finally {
      setState(() {
        isUpdatingTemp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingDevices) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1A2F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A2F), Color(0xFF0F2A4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      /// Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage("assets/aether_4.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      /// Text Column (Top + Bottom)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Top Text
                          const Text(
                            "Device Name",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 2),
                          /// Bottom Text
                          Text(
                            device_name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  /// 🔌 POWER SWITCH
                  SizedBox(height: 20),
                  Row(
                    children: [
                      /// POWER CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Left Content
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Power",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),

                              /// Toggle
                              GestureDetector(
                                onTap: () {
                                  togglePower(!isPowerOn);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 45,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: isPowerOn
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF00C853),
                                              Color(0xFF64DD17),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey.shade700,
                                              Colors.grey.shade800,
                                            ],
                                          ),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedPositioned(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        left: isPowerOn ? 20 : 4,
                                        top: 3,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: Icon(
                                            Icons.power_settings_new,
                                            size: 14,
                                            color: isPowerOn
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// STATUS CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Left Title
                              const Text(
                                "Status",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              /// Right Status
                              Row(
                                children: [
                                  /// Dot
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDeviceActive
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF5252),

                                      boxShadow: [
                                        BoxShadow(
                                          color: isDeviceActive
                                              ? const Color(
                                                  0xFF00E676,
                                                ).withOpacity(0.7)
                                              : const Color(
                                                  0xFFFF5252,
                                                ).withOpacity(0.7),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// Status Text
                                  Text(
                                    isDeviceActive ? "Active" : "Offline",
                                    style: TextStyle(
                                      color: isDeviceActive
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF5252),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// 🔵 BIG GLOWING CIRCLE
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF1E4FA3),
                          Color(0xFF0B2A5B),
                          Color(0xFF050F1E),
                        ],
                        stops: [0.2, 0.6, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 50,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // outer glow ring
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.2),
                              width: 8,
                            ),
                          ),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "MAINTAINING",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "$currentTemp$unit",
                              style: const TextStyle(
                                fontSize: 60,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ➖ ➕ BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleBtn(Icons.remove, () {
                        if (targetTemp >= 36) {
                          updateTemperature(targetTemp - 1);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Minimum temperature is 35"),
                            ),
                          );
                          return;
                        }
                      }),
                      const SizedBox(width: 25),
                      isUpdatingTemp
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "$targetTemp°C",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                      const SizedBox(width: 25),
                      _circleBtn(Icons.add, () {
                        if (targetTemp <= 74) {
                          updateTemperature(targetTemp + 1);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Maximum temperature is 75"),
                            ),
                          );
                          return;
                        }
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// 🔘 MODE BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _modeCard("Eco", () => updateMode("Eco")),
                      SizedBox(width: 10),
                      _modeCard("Comfort", () => updateMode("Comfort")),
                      SizedBox(width: 10),
                      _modeCard("Boost", () => updateMode("Boost")),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// INFO CARDS
                  // _infoCard("Defrost cycle", "Tap to start manual defrost"),
                  // _infoCard("Next Schedule", "Morning shower - Tomorrow 05:30"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔵 Round Button
  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: isUpdatingTemp ? null : onTap,

      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF4DA3FF), Color(0xFF2D6CDF)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Center(
          child: isUpdatingTemp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  /// 🔘 Mode Card
  Widget _modeCard(String text, VoidCallback onTap) {
    final isSelected = selectedMode == text;

    String getIcon() {
      if (text == "Eco") return "assets/comfort.png";
      if (text == "Boost") return "assets/comfort.png";
      return "assets/comfort.png";
    }

    String getImage() {
      if (text == "Eco") return "assets/eco_mode.png";
      if (text == "Boost") return "assets/boost_mode.png";
      return "assets/comfort.png";
    }

    LinearGradient getGradient() {
      if (text == "Eco") {
        return const LinearGradient(
          colors: [
            Color(0xFF1D6957),
            Color(0x501E6E5B),
            Color(0x502EB989),
            Color(0x3036E2A3),
            Color(0x707B889E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (text == "Boost") {
        return const LinearGradient(
          colors: [
            Color(0xFF6A3C2A),
            Color(0x707B889E),
            Color(0x60EEEEED),
            Color(0x50F17637),
            Color(0x35FA7938),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return const LinearGradient(
          colors: [
            Color(0xFF1E2A3E),
            Color(0xFF215D82),
            Color(0x505CD2FF),
            Color(0x607B889E),
            Color(0x20FFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }

    Color getTextColor() {
      if (!isSelected) {
        return const Color(0x99FFFFFF); // unselected common color
      }

      if (text == "Eco") {
        return const Color(0xFF2EB989); // light green tint
      } else if (text == "Boost") {
        return const Color(0xFFF17637); // light orange tint
      } else {
        return const Color(0xFFFFFFFF); // light blue tint (Comfort)
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          // Selected gradient per mode
          gradient: isSelected ? getGradient() : null,

          // Default background
          color: isSelected ? null : Colors.white.withOpacity(0.08),

          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.35)
                : Colors.white.withOpacity(0.1),
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Image switch
            isSelected
                ? Image.asset(getImage(), width: 30, height: 30)
                : Image.asset(getIcon(), width: 30, height: 30),

            const SizedBox(height: 10),

            Text(
              text,
              style: TextStyle(
                color: getTextColor(),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📦 Info Card
  Widget _infoCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit, color: Colors.white),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

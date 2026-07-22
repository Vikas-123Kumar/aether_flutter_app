import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/CustomerInformation.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/authentication/model/Device.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/model/DeviceDataModel.dart';
import '../authentication/rest/APIService.dart';
import '../device_details/ThermostateDial.dart';
import 'TransferScreen.dart';

class Installerdeviceinfoscreen extends StatefulWidget {
  final String deviceId;

  const Installerdeviceinfoscreen({super.key, required this.deviceId});

  @override
  State<Installerdeviceinfoscreen> createState() => _ThermostatUIState();
}

class _ThermostatUIState extends State<Installerdeviceinfoscreen> {
  String currentTemp = "0";
  String unit = "";
  int targetTemp = 52;
  String selectedMode = "";
  bool isUpdatingTemp = false;
  String mode = "ECO"; // standard / eco / boost
  bool isLoading = false;
  bool isPowerOn = false;
  bool isCheckingDevices = false;
  List<DeviceDataModel> deviceData = [];
  bool isDeviceActive = false;
  String device_name = "";

  Color get activeThemeColor {
    if (selectedMode == "Eco") {
      return const Color(0xFF1E6E5B); // Neon Green
    } else if (selectedMode == "Boost") {
      return const Color(0xFF6A3C2A); // Bright Orange
    } else {
      return const Color(0xFF38B6FF); // Comfort Blue
    }
  }

  final Color bgColorStart = const Color(0xFF0F1725);
  final Color bgColorEnd = const Color(0xFF0A101A);
  final Color cardColor = const Color(0xFF131F33);
  final Color accentBlue = const Color(0xFF38B6FF);
  final Color textGrey = const Color(0xFF8B9CB6);

  Color get activeSolidColor {
    if (selectedMode == "Eco") return const Color(0xFF1E6E5B); // Neon Green
    if (selectedMode == "Boost") return const Color(0xFFF17637); // Deep Orange
    return const Color(0xFF215D82); // Comfort Blue
  }

  // 2. Define the gradient colors for the dial and backgrounds
  // 2. Define the gradient colors for the dial and backgrounds
  List<Color> get activeGradientColors {
    if (selectedMode == "Eco") {
      // Vivid Green fading into Bright Cyan/Teal
      return [const Color(0xFF36E2A3), const Color(0xFF377E99)];
    } else if (selectedMode == "Boost") {
      // Deep Orange fading into Bright Yellow
      return [const Color(0xFFD4926C), const Color(0xFF377E99)];
    } else {
      // Rich Blue fading into Light Neon Blue
      return [const Color(0xFF5CD2FF), const Color(0x505CD2FF)];
    }
  }

  @override
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDeviceData();
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
      device_name = DeviceInformations.selectedDeviceName!;
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
                      /// Left Section
                      Expanded(
                        child: Row(
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

                            /// Text Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Device Name",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 2),

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
                      ),

                      /// Right Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Transfer",
                          style: TextStyle(color: Colors.white),
                        ),
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
                                // onTap: () {
                                //   togglePower(!isPowerOn);
                                // },
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
                  ThermostatDial(
                    temperature: currentTemp,
                    solidColor: activeSolidColor,
                    gradientColors: activeGradientColors,
                  ),

                  const SizedBox(height: 30),

                  /// ➖ ➕ BUTTONS
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     _circleBtn(Icons.remove, () {
                  //       if (targetTemp >= 36) {
                  //         updateTemperature(targetTemp - 1);
                  //       } else {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(
                  //             content: Text("Minimum temperature is 35"),
                  //           ),
                  //         );
                  //         return;
                  //       }
                  //     }),
                  //     const SizedBox(width: 25),
                  //     isUpdatingTemp
                  //         ? const SizedBox(
                  //             width: 30,
                  //             height: 30,
                  //             child: CircularProgressIndicator(
                  //               color: Colors.white,
                  //               strokeWidth: 3,
                  //             ),
                  //           )
                  //         : Text(
                  //             "$targetTemp°C",
                  //             style: const TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 22,
                  //             ),
                  //           ),
                  //     const SizedBox(width: 25),
                  //     _circleBtn(Icons.add, () {
                  //       if (targetTemp <= 74) {
                  //         updateTemperature(targetTemp + 1);
                  //       } else {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(
                  //             content: Text("Maximum temperature is 75"),
                  //           ),
                  //         );
                  //         return;
                  //       }
                  //     }),
                  //   ],
                  // ),
                  const SizedBox(height: 30),

                  /// 🔘 MODE BUTTONS
                  Row(
                    children: [
                      _buildModeCard(
                        "Eco",
                        "Save energy",
                        Icons.energy_savings_leaf_outlined,
                        selectedMode == "Eco",
                      ),
                      const SizedBox(width: 10),
                      _buildModeCard(
                        "Comfort",
                        "Everyday balance",
                        Icons.shield_outlined,
                        selectedMode == "Comfort",
                      ),
                      const SizedBox(width: 10),
                      _buildModeCard(
                        "Boost",
                        "Fast heat",
                        Icons.local_fire_department_outlined,
                        selectedMode == "Boost",
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  buildCustomerCard(),
                  const SizedBox(height: 15),
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

  Widget buildCustomerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162544),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person,
                color: Color(0xFF00B4D8),
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                "Customer Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          buildInfoRow(
            Icons.person_outline,
            "Name",
            CustomerInformation.customerName.isNotEmpty
                ? CustomerInformation.customerName
                : "-",
          ),

          const Divider(color: Colors.white24),

          buildInfoRow(
            Icons.email_outlined,
            "Email",
            CustomerInformation.customerEmail.isNotEmpty
                ? CustomerInformation.customerEmail
                : "-",
          ),

          const Divider(color: Colors.white24),

          buildInfoRow(
            Icons.phone_outlined,
            "Phone",
            CustomerInformation.customerPhone.isNotEmpty
                ? CustomerInformation.customerPhone
                : "-",
          ),
        ],
      ),
    );
  }
  Widget buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00B4D8), size: 22),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔘 Mode Card
  Widget _buildModeCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // UPDATED: Stronger start color, fading out
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      activeGradientColors.first.withOpacity(0.25),
                      // Brighter top-left
                      activeGradientColors.last.withOpacity(0.05),
                      // Darker bottom-right
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeSolidColor
                  : Colors.white.withOpacity(0.03),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeSolidColor.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeSolidColor : textGrey,
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: textGrey, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

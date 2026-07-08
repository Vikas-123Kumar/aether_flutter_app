import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/authentication/model/Device.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/model/DeviceDataModel.dart';
import '../authentication/rest/APIService.dart';
import 'ThermostateDial.dart';

class NewDeviceControlScreen extends StatefulWidget {
  @override
  State<NewDeviceControlScreen> createState() => _ThermostatUIState();
}

class _ThermostatUIState extends State<NewDeviceControlScreen> {
  String currentTemp = "0";
  String unit = "";
  int targetTemp = 52;
  String selectedMode = "Comfort"; // Set a default to match design
  bool isUpdatingTemp = false;
  String mode = "ECO";
  bool isLoading = false;
  bool isPowerOn = false;
  bool isCheckingDevices = true;
  List<DeviceDataModel> deviceData = [];
  bool isDeviceActive = false;
  String device_name = "";
  Timer? _deviceDataTimer;
  bool isMinusPressed = false;
  bool isPlusPressed = false;
  // Design Colors
  final Color bgColorStart = const Color(0xFF0F1725);
  final Color bgColorEnd = const Color(0xFF0A101A);
  final Color cardColor = const Color(0xFF131F33);
  final Color accentBlue = const Color(0xFF38B6FF);
  final Color textGrey = const Color(0xFF8B9CB6);
  String selectedButton = '';

  Color get activeThemeColor {
    if (selectedMode == "Eco") {
      return const Color(0xFF1E6E5B); // Neon Green
    } else if (selectedMode == "Boost") {
      return const Color(0xFF6A3C2A); // Bright Orange
    } else {
      return const Color(0xFF38B6FF); // Comfort Blue
    }
  }

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
  void initState() {
    super.initState();
    loadUserDeviceList();
    _deviceDataTimer = Timer.periodic(
      const Duration(seconds: 15),
          (timer) {
        getDeviceData();
      },
    );
  }

  DeviceDataModel? getItem(String alias) {
    try {
      return deviceData.firstWhere((e) => e.alias == alias);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _deviceDataTimer?.cancel();
    super.dispose();
  }

  Future<void> getDeviceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      String deviceId = DeviceInformations.act_device_id;
      print("token"+token+","+deviceId);
      final response = await http.get(
        Uri.parse(
          "https://aetherone.com.au/api/v1/heat-pump-2/devices/$deviceId/current-data",
        ),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List dataList = decoded['data']['data'];
        setState(() {
          print(" get response"+dataList.length.toString());

          deviceData = dataList.map((e) => DeviceDataModel.fromJson(e)).toList();
          final setPointData = deviceData.firstWhere((item) => item.itemid == "3");
          final setPointDataMode = deviceData.firstWhere((item) => item.itemid == "2");
          final setPointDataPower = deviceData.firstWhere((item) => item.itemid == "1");

          if (setPointDataMode.val == "0") {
            selectedMode = "Eco";
          } else if (setPointDataMode.val == "1") {
            selectedMode = "Comfort";
          } else if (setPointDataMode.val == "2") {
            selectedMode = "Boost";
          }
print("current temp"+currentTemp);
          currentTemp = setPointData.val;
          targetTemp = int.parse(setPointData.val);
          unit = setPointData.unit;
          isPowerOn = setPointDataPower.val == "1";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadUserDeviceList() async {
    try {
      final response = await ApiService().get("listUserDevices");
      final data = response.data;

      if (data["message"] == "Unauthenticated." || response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => NewLoginScreen()), (route) => false);
        return;
      }
      if (response.statusCode == 200) {
        List devices = data["devices"] ?? [];
        if (devices.isEmpty) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConnectScreen()));
          return;
        }
         print("installer list"+devices.length.toString());
        Map firstDevice = devices[0];
        DeviceInformations.selectedDeviceId = firstDevice["device_id"].toString();
        DeviceInformations.selectedSerialNumber = firstDevice["serial_number"].toString();
        DeviceInformations.selectedDeviceName = firstDevice["name"] ?? "";
        DeviceInformations.act_device_id = firstDevice["act_device_id"] ?? "";
        if (!mounted) return;

        setState(() {
          isDeviceActive = firstDevice["is_online"] == 1;
          device_name = firstDevice["name"] ?? "";
        });

        getDeviceData();
        if (!mounted) return;

        setState(() {
          isCheckingDevices = false;
        });

      }
    } catch (e) {
      if (!mounted) return;

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
    if (mode == "Eco") api_mode = "0";
    else if (mode == "Comfort") api_mode = "1";
    else if (mode == "Boost") api_mode = "2";

    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    setState(() => selectedMode = mode); // Optimistic UI update

    final response = await http.put(
      Uri.parse("https://aetherone.com.au/api/v1/heat-pump-2/control"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "devid": device_id,
        "itemid": "2",
        "value": api_mode,
      }),
    );
    if (response.statusCode == 200) {
      getDeviceData();
    }
  }

  Future<void> updateTemperature(int value) async {
    if (isUpdatingTemp) return;
    String device_id = DeviceInformations.act_device_id;

    setState(() {
      isUpdatingTemp = true;
      targetTemp = value; // Optimistic UI update
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      final tempItem = deviceData.firstWhere((item) => item.itemid == "3");

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null && data["data"]["status"] == "106") {
          final apiMsg = data['data']?['msg'] ?? "Something went wrong";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiMsg), backgroundColor: Colors.red));
        }
        await Future.delayed(const Duration(seconds: 2));
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
      return Scaffold(
        backgroundColor: bgColorStart,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF38B6FF))),
      );
    }
    return Scaffold(
      backgroundColor: bgColorStart,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColorStart, bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                /// 🟢 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                            color: cardColor,
                          ),
                          child: const Icon(Icons.heat_pump, color: Colors.lightBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AETHER SMART",
                              style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              device_name.isEmpty ? "Alex's Home" : device_name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDeviceActive ? const Color(0xFF00E676) : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: isDeviceActive ? const Color(0xFF00E676).withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ]
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDeviceActive ? "ONLINE" : "OFFLINE",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// 🔵 CIRCULAR DIAL
                ThermostatDial(
                  temperature: currentTemp,
                  solidColor: activeSolidColor,
                  gradientColors: activeGradientColors,
                ),
                const SizedBox(height: 20),

                /// ➖ ➕ TARGET CONTROLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// Minus Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedButton = 'minus';
                        });

                        if (targetTemp > 35) {
                          updateTemperature(targetTemp - 1);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedButton == 'minus'
                              ? accentBlue
                              : cardColor,
                          border: Border.all(
                            color: selectedButton == 'minus'
                                ? accentBlue
                                : Colors.white.withOpacity(0.05),
                          ),
                          boxShadow: selectedButton == 'minus'
                              ? [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                              : [],
                        ),
                        child: Icon(
                          Icons.remove,
                          color: selectedButton == 'minus'
                              ? Colors.white
                              : accentBlue,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    /// Target Pill
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "TARGET",
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          isUpdatingTemp
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            "$targetTemp°C",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    /// Plus Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedButton = 'plus';
                        });

                        if (targetTemp < 75) {
                          updateTemperature(targetTemp + 1);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedButton == 'plus'
                              ? accentBlue
                              : cardColor,
                          border: Border.all(
                            color: selectedButton == 'plus'
                                ? accentBlue
                                : Colors.white.withOpacity(0.05),
                          ),
                          boxShadow: selectedButton == 'plus'
                              ? [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                              : [],
                        ),
                        child: Icon(
                          Icons.add,
                          color: selectedButton == 'plus'
                              ? Colors.white
                              : accentBlue,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// 🔘 MODE BUTTONS
                Row(
                  children: [
                    _buildModeCard("Eco", "Save energy", Icons.energy_savings_leaf_outlined, selectedMode == "Eco"),
                    const SizedBox(width: 10),
                    _buildModeCard("Comfort", "Everyday balance", Icons.shield_outlined, selectedMode == "Comfort"),
                    const SizedBox(width: 10),
                    _buildModeCard("Boost", "Fast heat", Icons.local_fire_department_outlined, selectedMode == "Boost"),
                  ],
                ),

                const SizedBox(height: 20),

                /// 📋 LIST TILES
                _buildListTile(
                    icon: Icons.ac_unit,
                    title: "Defrost cycle",
                    subtitle: "Tap to start a manual defrost",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Text("OFF", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ),
                _buildListTile(
                  icon: Icons.cloud_outlined,
                  title: "OUTSIDE - SYDNEY",
                  subtitle: "12°C • Clear • drops to 8° tonight",
                  trailing: const Icon(Icons.diamond_outlined, color: Colors.amber, size: 20),
                ),
                _buildListTile(
                  icon: Icons.calendar_today_outlined,
                  title: "NEXT SCHEDULE",
                  subtitle: "Daytime eco • Today • 09:00",
                  trailing: Icon(Icons.chevron_right, color: textGrey),
                ),
                _buildListTile(
                  icon: Icons.notifications_none,
                  title: "1 ACTIVE ALERT",
                  subtitle: "Annual service due in 14 days",
                  trailing: Icon(Icons.chevron_right, color: Colors.orangeAccent),
                  outlineColor: Colors.orangeAccent,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      /// 📱 BOTTOM NAVIGATION BAR
      // bottomNavigationBar: Theme(
      //   data: ThemeData(
      //     splashColor: Colors.transparent,
      //     highlightColor: Colors.transparent,
      //   ),
      //   child: BottomNavigationBar(
      //     backgroundColor: bgColorEnd,
      //     type: BottomNavigationBarType.fixed,
      //     selectedItemColor: accentBlue,
      //     unselectedItemColor: textGrey,
      //     showSelectedLabels: true,
      //     showUnselectedLabels: true,
      //     selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      //     unselectedLabelStyle: const TextStyle(fontSize: 10),
      //     elevation: 0,
      //     items: const [
      //       BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_filled)), label: "Home"),
      //       BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.timer_outlined)), label: "Timer"),
      //       BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications_outlined)), label: "Alerts"),
      //       BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)), label: "Profile"),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildModeCard(String title, String subtitle, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => updateMode(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // UPDATED: Stronger start color, fading out
            gradient: isSelected ? LinearGradient(
              colors: [
                activeGradientColors.first.withOpacity(0.25), // Brighter top-left
                activeGradientColors.last.withOpacity(0.05),  // Darker bottom-right
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: isSelected ? null : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeSolidColor : Colors.white.withOpacity(0.03),
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: activeSolidColor.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)
            ] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeSolidColor : textGrey, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
  /// Helper to build the List Tiles
  Widget _buildListTile({required IconData icon, required String title, required String subtitle, Widget? trailing, Color? outlineColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: outlineColor?.withOpacity(0.4) ?? Colors.white.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: outlineColor ?? accentBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(color: outlineColor ?? textGrey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing
        ],
      ),
    );
  }
}
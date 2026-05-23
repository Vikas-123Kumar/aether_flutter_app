import 'package:flutter/material.dart';

import '../authentication/rest/APIService.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  int currentTemp = 0;
  int targetTemp = 0;
  String mode = "standard"; // standard / eco / boost
  bool isLoading = false;
  bool isPowerOn = false;

  @override
  void initState() {
    super.initState();
    //loadDeviceData();
  }

  // 🔥 GET DATA FROM API
  Future<void> loadDeviceData() async {
    try {
      final response = await ApiService().get("deviceDetails");

      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          currentTemp = data["current_temp"] ?? 0;
          targetTemp = data["target_temp"] ?? 0;
          mode = data["mode"] ?? "standard";
          isPowerOn = data["power"] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updatePower(bool value) async {
    setState(() => isPowerOn = value);

    try {
      await ApiService().post("setPower", {"power": value});
    } catch (e) {
      print(e);
    }
  }

  // 🔥 UPDATE TEMP API
  Future<void> updateTemperature(int temp) async {
    setState(() => targetTemp = temp);
    try {
      await ApiService().post("setTemperature", {"temperature": temp});
    } catch (e) {
      print(e);
    }
  }

  // 🔥 UPDATE MODE API
  Future<void> updateMode(String selectedMode) async {
    setState(() => mode = selectedMode);

    try {
      await ApiService().post("setMode", {"mode": selectedMode});
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Device Control",style: TextStyle(color: Colors.white),),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Logo
                Row(
                  children: [
                    Image.asset(
                      "assets/aether_logo.png", // 🔥 your logo
                      height: 40,
                    ),
                  ],
                ),
                // 🔹 ON/OFF Toggle
                Row(
                  children: [
                    Text(
                      isPowerOn ? "ON" : "OFF",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),

                    Switch(
                      value: isPowerOn,
                      activeColor: Colors.blueAccent,
                      onChanged: (value) {
                        updatePower(value);
                      },
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 15,),
            // 🔹 Current Temperature Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF122844),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Current Temperature",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$currentTemp°C",
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Temperature Control
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF122844),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Temperature Control",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _roundButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (targetTemp > 0) {
                            updateTemperature(targetTemp - 1);
                          }
                        },
                      ),

                      Text(
                        "$targetTemp",
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      _roundButton(
                        icon: Icons.add,
                        onTap: () {
                          updateTemperature(targetTemp + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Mode Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF122844),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Operating Mode",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _modeButton("standard", "Standard"),
                      _modeButton("eco", "Eco"),
                      _modeButton("boost", "Boost"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Round Button
  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // 🔹 Mode Button
  Widget _modeButton(String value, String label) {
    bool isSelected = mode == value;

    return GestureDetector(
      onTap: () => updateMode(value),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.whatshot, color: Colors.white), // you can change icons
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

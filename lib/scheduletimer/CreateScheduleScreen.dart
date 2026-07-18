import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'dart:convert';

import '../InternetService.dart';
import '../authentication/model/ScheduleTime.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<CreateScheduleScreen> {
  TimeOfDay _turnOnTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _turnOffTime = const TimeOfDay(hour: 8, minute: 0);
  double _targetWaterTemp = 30.0;
  String _selectedMode = 'Eco';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<bool> _selectedDays = List.filled(7, false);
  bool _isScheduleActive = true;
  bool _isLoading = false;
  final Map<String, Color> modeColors = {
    'Eco': const Color(0xFF00E5A8),      // Green
    'Boost': const Color(0xFF3FA9F5),    // Blue
    'Comfort': const Color(0xFFFF8A3D),  // Orange
  };
  final Map<String, List<Color>> modeGradients = {
    'Eco': const [
      Color(0xFF1B4D46),
      Color(0xFF173A49),
      Color(0xFF162B45),
    ],
    'Boost': const [
      Color(0xFF184B73),
      Color(0xFF1B3B5E),
      Color(0xFF162B45),
    ],
    'Comfort': const [
      Color(0xFF5A3828),
      Color(0xFF403244),
      Color(0xFF162B45),
    ],
  };
  // Custom Colors Matching the design
  final Color bgColor = const Color(0xFF0C101B);
  final Color cardColor = const Color(0xFF161F33);
  final Color accentBlue = const Color(0xFF39AEFB);

  Future<void> setSchedule({
    required String deviceId,
    required int temperature,
    required String timezone,
    required Map<String, List<ScheduleTime>> schedule,
  }) async {
    try {
      // NOTE: Make sure DeviceScheduleRequest is properly imported/implemented in your project structure
      String api_mode = "0";
      if (_selectedMode == "Eco")
        api_mode = "0";
      else if (_selectedMode == "Comfort")
        api_mode = "1";
      else if (_selectedMode == "Boost")
        api_mode = "2";
      final body = DeviceScheduleRequest(
        deviceId: deviceId,
        temperature: temperature,
        timezones: timezone,
        mode: api_mode,
        schedule: schedule,
      );
      print(body);
      bool connected = await InternetService().hasInternet();
      if (!connected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Internet Connection")));
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/deviceTimeSchedule"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode(body.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Success: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Schedule created successfully!")),
          );
          Navigator.of(context).pop(); // Go back home after successful create
        }
      } else {
        print("Failed: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    }
  }

  Future<void> _createSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> selectedDays = [];
      for (int i = 0; i < _days.length; i++) {
        if (_selectedDays[i]) {
          selectedDays.add(_days[i]);
        }
      }

      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one day")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, List<ScheduleTime>> scheduleMap = {};
      for (String day in selectedDays) {
        scheduleMap[day] = [
          ScheduleTime(
            start: formatTime(_turnOnTime),
            end: formatTime(_turnOffTime),
          ),
        ];
      }
      String device_id = DeviceInformations.selectedDeviceId;

      await setSchedule(
        deviceId: device_id,
        temperature: _targetWaterTemp.toInt(),
        timezone: "Australia/Sydney",
        schedule: scheduleMap,
      );
    } catch (e) {
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _selectTime(BuildContext context, bool isTurnOn) async {
    if (_isLoading) return; // Prevent picking time while saving

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isTurnOn ? _turnOnTime : _turnOffTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentBlue,
              onPrimary: Colors.white,
              surface: cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isTurnOn) {
          _turnOnTime = picked;
        } else {
          _turnOffTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Schedule",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Heat your water on autopilot",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NEW SCHEDULE",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "New schedule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color: accentBlue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "TURN ON",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _turnOnTime.format(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color: accentBlue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "TURN OFF",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _turnOffTime.format(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TARGET WATER TEMP",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_targetWaterTemp.toInt()}°C",
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accentBlue,
                          inactiveTrackColor: Colors.grey,
                          thumbColor: accentBlue,
                          overlayColor: accentBlue.withOpacity(0.3),
                        ),
                        child: Slider(
                          value: _targetWaterTemp,
                          min: 30.0,
                          max: 75.0,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _targetWaterTemp = value;
                                  });
                                },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "30°",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              "75°",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "HEATING MODE",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Eco', 'Boost', 'Comfort'].map((mode) {
                    final isSelected = _selectedMode == mode;
                    final accentColor = modeColors[mode]!;
                    final gradient = modeGradients[mode]!;
                    return Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(() => _selectedMode = mode),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient,
                            )
                                : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E3154),
                                Color(0xFF162B45),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mode == 'Eco'
                                    ? Icons.eco_outlined
                                    : mode == 'Boost'
                                    ? Icons.bolt_outlined
                                    : Icons.air,
                                color: isSelected ? accentColor : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mode,
                                style: TextStyle(
                                  color: isSelected ? accentColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  "REPEAT ON",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final isSelected = _selectedDays[index];
                      return GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(
                                () => _selectedDays[index] =
                                    !_selectedDays[index],
                              ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accentBlue : cardColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            _days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Schedule active",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Aether will run this automatically",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isScheduleActive,
                        activeColor: accentBlue,
                        inactiveTrackColor: Colors.grey,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _isScheduleActive = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      "Create Schedule",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          /// ⏳ Centered Full-Screen Dimming Loader Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Subtle dimming effect
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentBlue.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: accentBlue,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Creating Schedule...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Sending rules to hardware",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

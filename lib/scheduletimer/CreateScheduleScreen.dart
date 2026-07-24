import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:untitled/DeviceInformations.dart';
import '../InternetService.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  TimeOfDay _turnOnTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _turnOffTime = const TimeOfDay(hour: 8, minute: 0);
  double _targetWaterTemp = 30.0;
  String _selectedMode = 'Eco';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<bool> _selectedDays = List.filled(7, false);
  bool _isScheduleActive = true;
  bool _isLoading = false;

  final TextEditingController scheduleController = TextEditingController();

  // Figma Theme Base Colors
  final Color bgColor = const Color(0xFF070B12);
  final Color cardBg = const Color(0xFF0F1726);
  final Color innerCardBg = const Color(0xFF142033);
  final Color accentBlue = const Color(0xFF38B6FF);
  final Color subTextColor = const Color(0xFF7A8B9E);

  // Distinct Accent Colors for Each Mode
  final Map<String, Color> modeColors = {
    'Eco': const Color(0xFF00E5A8), // Green
    'Boost': const Color(0xFFFF6B35), // Orange/Red
    'Comfort': const Color(0xFF38B6FF), // Cyan Blue
  };

  // Distinct Background Card Colors when Selected
  final Map<String, Color> modeSelectedBgs = {
    'Eco': const Color(0xFF0D2823),
    'Boost': const Color(0xFF2C1C17),
    'Comfort': const Color(0xFF10283B),
  };

  final Map<String, String> _dayNameMap = {
    'Mon': 'monday',
    'Tue': 'tuesday',
    'Wed': 'wednesday',
    'Thu': 'thursday',
    'Fri': 'friday',
    'Sat': 'saturday',
    'Sun': 'sunday',
  };

  int _getModeValue(String mode) {
    switch (mode) {
      case 'Eco':
        return 0;
      case 'Comfort':
        return 1;
      case 'Boost':
        return 2;
      default:
        return 1;
    }
  }

  void _selectPresetDays(String type) {
    setState(() {
      if (type == 'Weekdays') {
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = i < 5;
        }
      } else if (type == 'Weekends') {
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = i >= 5;
        }
      } else if (type == 'Daily') {
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = true;
        }
      }
    });
  }

  Future<void> setSchedule(Map<String, dynamic> payload) async {
    try {
      bool connected = await InternetService().hasInternet();
      if (!connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No Internet Connection")),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/timerSchedules"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Schedule created successfully!")),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    }
  }

  Future<void> _createSchedule() async {
    List<String> selectedDays = [];
    for (int i = 0; i < _days.length; i++) {
      if (_selectedDays[i]) {
        selectedDays.add(_dayNameMap[_days[i]]!);
      }
    }

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one day")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String timezone = prefs.getString("timezone") ?? "Asia/Kolkata";

      final Map<String, dynamic> payload = {
        "device_id": DeviceInformations.selectedDeviceId,
        "name": scheduleController.text.isEmpty
            ? "New schedule"
            : scheduleController.text,
        "schedule_type": "schedule",
        "tag": _selectedMode.toUpperCase(),
        "mode": _getModeValue(_selectedMode),
        "start_time": formatTime24(_turnOnTime),
        "end_time": formatTime24(_turnOffTime),
        "temperature": _targetWaterTemp.toInt(),
        "timezone": timezone,
        "days": selectedDays,
        "is_enabled": _isScheduleActive,
        "sort_order": 1,
      };

      await setSchedule(payload);
    } catch (e) {
      print("Error creating schedule: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String formatTime12(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    final minute = time.minute.toString().padLeft(2, '0');
    return "${hour.toString().padLeft(2, '0')}:$minute$period";
  }

  Future<void> _selectTime(BuildContext context, bool isTurnOn) async {
    if (_isLoading) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isTurnOn ? _turnOnTime : _turnOffTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentBlue,
              onPrimary: Colors.white,
              surface: innerCardBg,
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Container(
            decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Heat your water on autopilot",
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Card Container
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "NEW SCHEDULE",
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      buildField(
                        controller: scheduleController,
                        hint: "Enter schedule",
                        icon: Icons.schedule,
                      ),
                      const SizedBox(height: 16),

                      // Turn ON / OFF Cards
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 14.0,
                                ),
                                decoration: BoxDecoration(
                                  color: innerCardBg,
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color: accentBlue,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "TURN ON",
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatTime12(_turnOnTime),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 14.0,
                                ),
                                decoration: BoxDecoration(
                                  color: innerCardBg,
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.power_settings_new,
                                          color: accentBlue,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "TURN OFF",
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatTime12(_turnOffTime),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Temperature Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TARGET WATER TEMP",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "${_targetWaterTemp.toInt()}°C",
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: accentBlue,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: accentBlue,
                          overlayColor: accentBlue.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "30°",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              "75°",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Text(
                  "HEATING MODE",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),

                // Heating Modes with Dynamic Mode Colors
                Row(
                  children: ['Eco', 'Boost', 'Comfort'].map((mode) {
                    final isSelected = _selectedMode == mode;
                    final activeColor = modeColors[mode]!;
                    final selectedBg = modeSelectedBgs[mode]!;

                    return Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(() => _selectedMode = mode),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedBg : cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? activeColor
                                  : Colors.transparent,
                              width: 1.2,
                            ),
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
                                color: isSelected
                                    ? activeColor
                                    : activeColor.withOpacity(0.6),
                                size: 18,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mode,
                                style: TextStyle(
                                  color: isSelected
                                      ? activeColor
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),
                Text(
                  "REPEAT ON",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),

                // Days Selection Row
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
                          margin: const EdgeInsets.only(right: 6.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accentBlue : cardBg,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            _days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : subTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // Days Quick Selection Presets
                Row(
                  children: ['Weekdays', 'Weekends', 'Daily'].map((preset) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => _selectPresetDays(preset),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              preset,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Switch Active Row
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Schedule active",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Aether will run this automatically",
                            style: TextStyle(color: subTextColor, fontSize: 10),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isScheduleActive,
                        activeColor: Colors.white,
                        activeTrackColor: accentBlue,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
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

                const SizedBox(height: 24),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      shadowColor: accentBlue.withOpacity(0.5),
                    ),
                    child: const Text(
                      "Create Schedule",
                      style: TextStyle(
                        color: Colors.black,
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

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          color: accentBlue,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Creating Schedule...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: accentBlue),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.blueAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

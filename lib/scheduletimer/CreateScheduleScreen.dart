import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'dart:convert';

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

  Future<void> setSchedule({
    required String deviceId,
    required int temperature,
    required String timezone,

    /// Dynamic schedule map
    required Map<String, List<ScheduleTime>> schedule,
  }) async {
    try {
      final body = DeviceScheduleRequest(
        deviceId: deviceId,
        temperature: temperature,
        timezones: timezone,
        schedule: schedule,
      );
      final prefs = await SharedPreferences.getInstance();

      String token = prefs.getString("token") ?? "";
      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/deviceTimeSchedule"),
        headers: {
          "Content-Type": "application/json",
          /// TOKEN
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode(body.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Success");
        print(response.body);
      } else {
        print("Failed");
        print(response.body);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _createSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      /// SELECTED DAYS
      List<String> selectedDays = [];

      for (int i = 0; i < _days.length; i++) {
        if (_selectedDays[i]) {
          selectedDays.add(_days[i]);
        }
      }

      /// VALIDATION
      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one day")),
        );

        setState(() {
          _isLoading = false;
        });

        return;
      }

      /// CREATE SCHEDULE MAP
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

      /// API CALL
      await setSchedule(
        deviceId: device_id, // YOUR DEVICE ID
        temperature: _targetWaterTemp.toInt(),
        timezone: "Australia/Sydney",
        schedule: scheduleMap,
      );
    } catch (e) {
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }

  Future<void> _selectTime(BuildContext context, bool isTurnOn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isTurnOn ? _turnOnTime : _turnOffTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00B4D8),
              onPrimary: Colors.white,
              surface: Color(0xFF161F33),
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
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
      body: SingleChildScrollView(
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
                color: const Color(0xFF161F33),
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
                              color: const Color(0xFF0C101B),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.power_settings_new,
                                      color: Color(0xFF00B4D8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
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
                              color: const Color(0xFF0C101B),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.power_settings_new,
                                      color: Color(0xFF00B4D8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
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
                        style: const TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00B4D8),
                      inactiveTrackColor: Colors.grey,
                      thumbColor: const Color(0xFF00B4D8),
                      overlayColor: const Color(0xFF00B4D8).withOpacity(0.3),
                    ),
                    child: Slider(
                      value: _targetWaterTemp,
                      min: 30.0,
                      max: 75.0,
                      onChanged: (value) {
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
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        Text(
                          "75°",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
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
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00B4D8).withOpacity(0.2)
                            : const Color(0xFF161F33),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00B4D8)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          mode,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00B4D8)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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
                    onTap: () => setState(
                      () => _selectedDays[index] = !_selectedDays[index],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00B4D8)
                            : const Color(0xFF161F33),
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
                color: const Color(0xFF161F33),
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
                    activeColor: const Color(0xFF00B4D8),
                    inactiveTrackColor: Colors.grey,
                    onChanged: (value) {
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
                  backgroundColor: const Color(0xFF00B4D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
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
    );
  }
}

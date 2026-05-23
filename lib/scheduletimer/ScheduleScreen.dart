import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/scheduletimer/CreateScheduleScreen.dart';

class Schedule {
  final int id;
  final String day;
  final String start;
  final String end;
  final String temperature;
  final String timezone;
  bool status;

  Schedule({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    required this.temperature,
    required this.timezone,
    required this.status,
  });
}

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Schedule> schedules = [];

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    try {
      String deviceId = DeviceInformations.selectedDeviceId;
      print("device id$deviceId");
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response = await http.get(
        Uri.parse(
          "https://aetherone.com.au/api/v1/getDeviceSchedule?device_id=$deviceId",
        ),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("Status Code => ${response.statusCode}");
      print("Response => ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        final scheduleData = decodedData["schedule"] as List;

        List<Schedule> loadedSchedules = [];

        for (var dayData in scheduleData) {
          String id = dayData["id"] ?? "";
          String day = dayData["name"] ?? "";

          List schedulesList = dayData["schedules"] ?? [];

          for (var item in schedulesList) {
            loadedSchedules.add(
              Schedule(
                id: item["id"] ?? "",
                day: day,
                start: item["start"] ?? "",
                end: item["end"] ?? "",
                temperature: item["temperature"].toString(),
                timezone: item["timezone"] ?? "",
                status: item["status"] == 1,
              ),
            );
          }
        }

        setState(() {
          schedules = loadedSchedules;
        });

        print("Schedules Length => ${schedules.length}");
      } else {
        print("Failed API");
      }
    } catch (e) {
      print("Error => $e");
    }
  }

  Future<void> toggleSchedule(int index, bool value,int id) async {
    final schedule = schedules[index];
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/enableDisableTime"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "id": id.toString(),
          "status": value ? 1 : 0,
        }),
      );
      int valuedata=value ? 1 : 0;
      print("log id$id$valuedata");

      if (response.statusCode == 200) {
        // Change toggle only after API success
        setState(() {
          schedules[index].status = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schedule updated successfully.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update schedule")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B1C2C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // _buildUpNextCard(),
                  // SizedBox(height: 20),
                  // _buildQuickStart(),
                  // SizedBox(height: 20),
                  _buildScheduleList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [

              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Schedule",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    "Heat your water on autopilot",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateScheduleScreen()),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF12263A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("UP NEXT", style: TextStyle(color: Colors.lightBlueAccent)),
          SizedBox(height: 10),
          Text(
            "Daytime eco",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 5),
          Text("Today · 09:00", style: TextStyle(color: Colors.white54)),
          SizedBox(height: 10),
          Row(children: [_chip("Eco"), _chip("Eco"), _chip("Weekdays")]),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: Colors.greenAccent)),
    );
  }

  Widget _buildQuickStart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "QUICK START",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _quickCard("Morning shower", "BOOST"),
            _quickCard("Daytime away", "ECO"),
            _quickCard("Evening bath", "COMFORT"),
            _quickCard("Night setback", "ECO"),
          ],
        ),
      ],
    );
  }

  Widget _quickCard(String title, String type) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF142C44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: TextStyle(color: Colors.orangeAccent)),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            "06:00 - 07:30",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ALL SCHEDULES",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        SizedBox(height: 10),

        ...List.generate(schedules.length, (index) {
          final item = schedules[index];

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF142C44),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.day, style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        "${item.start} - ${item.end}",

                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: item.status,
                  onChanged: (val) => toggleSchedule(index, val,item.id),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

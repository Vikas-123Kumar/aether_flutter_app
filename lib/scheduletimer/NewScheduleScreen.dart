import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../DeviceInformations.dart';
import 'CreateScheduleScreen.dart';

// NOTE: Make sure to import your InternetService here
// import '../InternetService.dart';

// ==========================================
// 1. DATA MODELS & API RESPONSE PARSER
// ==========================================

class ScheduleItem {
  final int id;
  final String deviceId;
  final String title;
  final String mode; // e.g., 'Eco', 'Boost', 'Comfort'
  final int modeInt; // Raw mode ID from backend (e.g. 1)
  final String tag; // e.g., 'COMFORT'
  final String startTime; // "10:20"
  final String endTime; // "11:00"
  final int targetTemp; // 43
  final String timezone;
  final List<String> days; // ["sunday", "monday", ...]
  final List<bool>
  repeatDays; // Formatted for UI: [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
  bool isActive;

  ScheduleItem({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.mode,
    required this.modeInt,
    required this.tag,
    required this.startTime,
    required this.endTime,
    required this.targetTemp,
    required this.timezone,
    required this.days,
    required this.repeatDays,
    required this.isActive,
  });

  /// Factory constructor to parse directly from the backend JSON response
  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    List<String> rawDays = json['days'] != null
        ? List<String>.from(json['days'].map((d) => d.toString().toLowerCase()))
        : [];

    // Maps string days to Sunday–Saturday boolean flags for UI rendering
    List<bool> formattedRepeatDays = [
      rawDays.contains('sunday'),
      rawDays.contains('monday'),
      rawDays.contains('tuesday'),
      rawDays.contains('wednesday'),
      rawDays.contains('thursday'),
      rawDays.contains('friday'),
      rawDays.contains('saturday'),
    ];

    // Helper map to normalize numerical mode values to readable display names
    String mappedMode;
    switch (json['mode']) {
      case 0:
        mappedMode = 'Eco';
        break;
      case 1:
        mappedMode = 'Comfort';
        break;
      case 2:
        mappedMode = 'Boost';
        break;
      default:
        mappedMode =
            (json['tag'] as String?)?.toLowerCase().capitalize() ?? 'Comfort';
    }

    return ScheduleItem(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      title: json['name'] ?? 'Schedule',
      mode: mappedMode,
      modeInt: json['mode'] ?? 1,
      tag: json['tag'] ?? 'COMFORT',
      startTime: json['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? '00:00',
      targetTemp: json['temperature'] ?? 40,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      days: rawDays,
      repeatDays: formattedRepeatDays,
      isActive: json['is_enabled'] ?? true, // maps to switch status
    );
  }
}

class DashboardData {
  final ScheduleItem? upNext;
  final List<ScheduleItem> quickStart;
  final List<ScheduleItem> allSchedules;

  DashboardData({
    required this.upNext,
    required this.quickStart,
    required this.allSchedules,
  });
}

// Helper extension to capitalize mode names safely
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ==========================================
// 2. LIVE API SERVICE
// ==========================================

class ApiService1 {
  static const String baseUrl = "https://aetherone.com.au/api/v1";

  /// Fetch schedule items from backend API
  /// Fetch schedule items from backend API
  /// Fetch schedule items from backend API
  static Future<DashboardData> fetchSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    // Safely construct the URL with both device_id and type as query parameters
    final uri = Uri.parse("$baseUrl/timerSchedules").replace(
      queryParameters: {
        "device_id": DeviceInformations.selectedDeviceId,
        "type": "schedule",
      },
    );

    print("Fetching schedules from: $uri");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print("GET Schedule Status Code: ${response.statusCode}");
    print("GET Schedule Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      List<ScheduleItem> parsedSchedules = [];

      // Flexible extraction to account for single objects or arrays in response data
      if (body['data'] is List) {
        parsedSchedules = (body['data'] as List)
            .map((item) => ScheduleItem.fromJson(item))
            .toList();
      } else if (body['data'] is Map<String, dynamic>) {
        parsedSchedules = [ScheduleItem.fromJson(body['data'])];
      }

      if (parsedSchedules.isEmpty) {
        return DashboardData(upNext: null, quickStart: [], allSchedules: []);
      }

      return DashboardData(
        upNext: parsedSchedules.first,
        quickStart: parsedSchedules.length > 1
            ? parsedSchedules.sublist(1, parsedSchedules.length.clamp(1, 5))
            : [],
        allSchedules: parsedSchedules,
      );
    } else {
      throw Exception("Failed to load schedules: ${response.statusCode}");
    }
  }

  static Future<bool> toggleScheduleStatus(
    int scheduleId,
    bool isEnabled,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/enableDisableTime"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "id": scheduleId.toString(),
          "status": isEnabled ? 1 : 0,
        }),
      );

      print("Toggle Status: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Toggle status error: $e");
      return false;
    }
  }

  /// Delete a schedule item from backend
  static Future<bool> deleteSchedule(int scheduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.delete(
        Uri.parse("$baseUrl/timerSchedules/$scheduleId"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Delete Status: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error deleting schedule: $e");
      return false;
    }
  }
}

// ==========================================
// 3. MAIN USER INTERFACE
// ==========================================

class ScheduleDashboardScreen extends StatefulWidget {
  const ScheduleDashboardScreen({super.key});

  @override
  State<ScheduleDashboardScreen> createState() =>
      _ScheduleDashboardScreenState();
}

class _ScheduleDashboardScreenState extends State<ScheduleDashboardScreen> {
  // Theme Colors
  final Color bgColor = const Color(0xFF0A101A);
  final Color cardColor = const Color(0xFF131F33);
  final Color highlightCardColor = const Color(0xFF162A45);
  final Color textGrey = const Color(0xFF8B9CB6);
  final Color accentBlue = const Color(0xFF38B6FF);

  bool _isLoading = true;
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF0C101B),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService1.fetchSchedules();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching schedules: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'eco':
        return const Color(0xff00E676);
      case 'boost':
        return const Color(0xFFF17637);
      case 'comfort':
        return const Color(0xFF38B6FF);
      default:
        return Colors.white;
    }
  }

  String _formatDaysSummary(List<String> days) {
    if (days.isEmpty) return "Once";
    if (days.length == 7) return "Everyday";
    if (days.length == 5 &&
        !days.contains("saturday") &&
        !days.contains("sunday")) {
      return "Weekdays";
    }
    if (days.length == 2 &&
        days.contains("saturday") &&
        days.contains("sunday")) {
      return "Weekends";
    }
    return days.map((d) => d.substring(0, 3).capitalize()).join(", ");
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: accentBlue)),
      );
    }
    final int activeCount =
        _data?.allSchedules.where((e) => e.isActive).length ?? 0;
    final int totalCount = _data?.allSchedules.length ?? 0;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Heat your water on autopilot",
              style: TextStyle(color: textGrey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBlue,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.black, size: 24),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateScheduleScreen(),
                    ),
                  );

                  // 2. ONLY reload if the result is true
                  if (result == true) {
                    _loadDashboardData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: accentBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              /// 🔵 SECTION 1: UP NEXT CARD
              if (_data?.upNext != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: highlightCardColor,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: accentBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "UP NEXT",
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _data!.upNext!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Starts · ${_data!.upNext!.startTime}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            _data!.upNext!.mode,
                            _getModeColor(_data!.upNext!.mode),
                            true,
                          ),
                          _buildBadge(
                            "${_data!.upNext!.targetTemp}°C",
                            textGrey,
                            false,
                          ),
                          _buildBadge(
                            _formatDaysSummary(_data!.upNext!.days),
                            Colors.white,
                            false,
                            showDot: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "⬇ $activeCount active  -  $totalCount total",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              /// 🔵 SECTION 2: QUICK START GRID
              if (_data?.quickStart.isNotEmpty ?? false) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "QUICK START",
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _data!.quickStart.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final item = _data!.quickStart[index];
                    final modeColor = _getModeColor(item.mode);
                    return Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgColor,
                                ),
                                child: Icon(
                                  Icons.flash_on,
                                  color: modeColor,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.mode.toUpperCase(),
                                style: TextStyle(
                                  color: modeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.startTime} - ${item.endTime} · ${item.targetTemp}°C",
                                style: TextStyle(color: textGrey, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              /// 🔵 SECTION 3: ALL SCHEDULES LIST
              Text(
                "ALL SCHEDULES",
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              if (_data?.allSchedules.isEmpty ?? true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      "No schedules created yet.",
                      style: TextStyle(color: textGrey, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _data!.allSchedules.length,
                  itemBuilder: (context, index) {
                    final item = _data!.allSchedules[index];
                    final modeColor = _getModeColor(item.mode);

                    return Dismissible(
                      key: Key(item.id.toString()),
                      direction: DismissDirection.endToStart,

                      // 1. CONFIRMATION DIALOG FOR DELETE
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    "Delete Schedule",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete '${item.title}'?",
                                    style: TextStyle(color: textGrey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(color: textGrey),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;
                      },

                      // 2. ACTION TO RUN ON DELETE
                      onDismissed: (direction) async {
                        // Remove from UI instantly
                        setState(() {
                          _data!.allSchedules.removeAt(index);
                        });

                        // Make API request
                        bool success = await ApiService1.deleteSchedule(
                          item.id,
                        );

                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Schedule deleted successfully"),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to delete schedule"),
                              ),
                            );
                          }
                        }
                        // Refresh data to ensure UI matches Database state
                        _loadDashboardData();
                      },

                      // 3. RED BACKGROUND WHEN SWIPING
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. MAIN SCHEDULE CARD UI
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: modeColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.mode.toUpperCase(),
                                        style: TextStyle(
                                          color: modeColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // 5. TOGGLE SWITCH IMPLEMENTATION
                                Switch(
                                  value: item.isActive,
                                  activeColor: Colors.white,
                                  activeTrackColor: accentBlue,
                                  inactiveTrackColor: Colors.grey.withOpacity(
                                    0.3,
                                  ),
                                  onChanged: (val) async {
                                    // Update UI immediately
                                    setState(() {
                                      item.isActive = val;
                                    });

                                    // Make API Call
                                    bool success =
                                        await ApiService1.toggleScheduleStatus(
                                          item.id,
                                          val,
                                        );

                                    if (success) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Schedule updated successfully.",
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Revert UI if API fails
                                      setState(() {
                                        item.isActive = !val;
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Failed to update schedule",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: modeColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${item.startTime}  —  ",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.stop_circle_outlined,
                                  color: textGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${item.endTime}  ·  ${item.targetTemp}°C",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            /// Horizontal Weekday Circles (S, M, T, W, T, F, S)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(7, (dayIdx) {
                                final daysLetters = [
                                  'S',
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                ];
                                final isHighlighted = item.repeatDays[dayIdx];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isHighlighted
                                        ? accentBlue.withOpacity(0.2)
                                        : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      daysLetters[dayIdx],
                                      style: TextStyle(
                                        color: isHighlighted
                                            ? accentBlue
                                            : textGrey.withOpacity(0.4),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    String label,
    Color color,
    bool filled, {
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white54,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? color : textGrey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

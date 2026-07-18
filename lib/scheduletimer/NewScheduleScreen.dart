import 'package:flutter/material.dart';

// ==========================================
// 1. DATA MODELS & MOCK API SERVICE
// ==========================================

class ScheduleItem {
  final String id;
  final String title;
  final String mode; // 'Eco', 'Boost', 'Comfort'
  final String startTime; // "05:30"
  final String endTime; // "07:30"
  final int targetTemp; // 58
  final List<bool> repeatDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  bool isActive;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.mode,
    required this.startTime,
    required this.endTime,
    required this.targetTemp,
    required this.repeatDays,
    this.isActive = true,
  });
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

class ApiService1 {
  // Simulate fetching data from your backend
  static Future<DashboardData> fetchSchedules() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate networking

    final sampleSchedules = [
      ScheduleItem(
        id: "1",
        title: "Daytime eco",
        mode: "Eco",
        startTime: "09:00",
        endTime: "17:00",
        targetTemp: 52,
        repeatDays: [true, true, true, true, true, false, false], // Weekdays
      ),
      ScheduleItem(
        id: "2",
        title: "Morning shower",
        mode: "Boost",
        startTime: "06:00",
        endTime: "07:30",
        targetTemp: 58,
        repeatDays: [false, true, true, true, true, true, false],
      ),
      ScheduleItem(
        id: "3",
        title: "Daytime away",
        mode: "Eco",
        startTime: "06:00",
        endTime: "07:30",
        targetTemp: 58,
        repeatDays: [true, true, true, true, true, true, true],
      ),
      ScheduleItem(
        id: "4",
        title: "Evening bath",
        mode: "Comfort",
        startTime: "06:00",
        endTime: "07:30",
        targetTemp: 58,
        repeatDays: [true, true, true, true, true, true, true],
      ),
      ScheduleItem(
        id: "5",
        title: "Night setback",
        mode: "Eco",
        startTime: "06:00",
        endTime: "07:30",
        targetTemp: 58,
        repeatDays: [true, true, true, true, true, true, true],
      ),
    ];

    return DashboardData(
      upNext: sampleSchedules[0],
      quickStart: sampleSchedules.sublist(1, 5),
      allSchedules: sampleSchedules.sublist(1), // Show lower list items
    );
  }
}

// ==========================================
// 2. MAIN USER INTERFACE
// ==========================================

class ScheduleDashboardScreen extends StatefulWidget {
  const ScheduleDashboardScreen({super.key});

  @override
  State<ScheduleDashboardScreen> createState() => _ScheduleDashboardScreenState();
}

class _ScheduleDashboardScreenState extends State<ScheduleDashboardScreen> {
  // UI Theme Styling constants matching image precisely
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
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await ApiService1.fetchSchedules();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'eco':
        return const Color(0xff00E676); // Vibrant Green
      case 'boost':
        return const Color(0xFFF17637); // Deep Orange
      case 'comfort':
        return const Color(0xFF38B6FF); // System Neon Blue
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: accentBlue)),
      );
    }

    final int activeCount = _data?.allSchedules.where((e) => e.isActive).length ?? 0;
    final int totalCount = _data?.allSchedules.length ?? 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
                onPressed: () {
                  // Route out to CreateScheduleScreen
                },
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            /// 🔵 SECTION 1: UP NEXT LARGE CARD
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
                        Icon(Icons.share_arrival_time_outlined, color: accentBlue, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "UP NEXT",
                          style: TextStyle(color: accentBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _data!.upNext!.title,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Today · ${_data!.upNext!.startTime}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBadge(_data!.upNext!.mode, _getModeColor(_data!.upNext!.mode), true),
                        const SizedBox(width: 8),
                        _buildBadge("${_data!.upNext!.targetTemp}°C", textGrey, false),
                        const SizedBox(width: 8),
                        _buildBadge("Weekdays", Colors.white, false, showDot: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "⬇ $activeCount active  -  $totalCount total",
                      style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            /// 🔵 SECTION 2: QUICK START GRID HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "QUICK START",
                  style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                Text(
                  "Tap to add",
                  style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// QUICK START MATRIX
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _data?.quickStart.length ?? 0,
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
                            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
                            child: Icon(Icons.arrow_back, color: textGrey, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.mode.toUpperCase(),
                            style: TextStyle(color: modeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item.startTime}-${item.endTime} -${item.targetTemp}°",
                            style: TextStyle(color: textGrey, fontSize: 10),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            /// 🔵 SECTION 3: ALL SCHEDULES LIST
            Text(
              "ALL SCHEDULES",
              style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _data?.allSchedules.length ?? 0,
              itemBuilder: (context, index) {
                final item = _data!.allSchedules[index];
                final modeColor = _getModeColor(item.mode);
                return Container(
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
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: modeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.mode.toUpperCase(),
                                  style: TextStyle(color: modeColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          Switch(
                            value: item.isActive,
                            activeColor: Colors.white,
                            activeTrackColor: accentBlue,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                            onChanged: (val) {
                              setState(() {
                                item.isActive = val;
                              });
                              // Push dynamic changes to your server if needed
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.ac_unit, color: modeColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${item.startTime}  —  ",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.wb_sunny_outlined, color: textGrey, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${item.endTime}  ·  ${item.targetTemp}°",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      /// Horizontal Row of Weekday Circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(7, (dayIdx) {
                          final daysLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                          // Convert Mon-Sun data array map shifts
                          final isHighlighted = item.repeatDays[dayIdx];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHighlighted ? accentBlue.withOpacity(0.2) : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                daysLetters[dayIdx],
                                style: TextStyle(
                                  color: isHighlighted ? accentBlue : textGrey.withOpacity(0.5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Pill Badges for Main Top View
  Widget _buildBadge(String label, Color color, bool filled, {bool showDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54),
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
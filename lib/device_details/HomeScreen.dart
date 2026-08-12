import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled/authentication/NewProfileScreen.dart';
import 'package:untitled/erroralert/AlertsScreen.dart';
import 'package:untitled/installer/InstallerList.dart';
import 'package:untitled/installer/InstallerProfile.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';
import 'package:untitled/scheduletimer/NewScheduleScreen.dart';

import '../installer/InstallerFullList.dart';
import '../pairdevice/NewControlScreen.dart';
import 'NewDeviceControlScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String roleType = "end_user";

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      roleType = prefs.getString("current_role") ?? "Installer";
    });
  }

  List<Widget> getPages() {
    if (roleType == "Installer") {
      return [
        const Installerlist(),
        InstallerFulllist(),
        NewControlDevice(),
        const Installerprofile(),
      ];
    }

    return [
       NewDeviceControlScreen(),
      const ScheduleDashboardScreen(),
       AlertsScreen(),
      const NewProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = getPages();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),

      body: SafeArea(
        child: pages[_currentIndex],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF15233F),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: roleType == "Installer"
                ? [
              _navItem(Icons.home_rounded, "Home", 0),
              _navItem(Icons.dashboard_outlined, "System", 1),
              _navItem(Icons.add_circle_outline, "Link", 2),
              _navItem(Icons.person_outline, "Profile", 3),
            ]
                : [
              _navItem(Icons.home_rounded, "Home", 0),
              _navItem(Icons.calendar_month_rounded, "Schedule", 1),
              _navItem(Icons.notifications_none_rounded, "Alerts", 2),
              _navItem(Icons.person_outline, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String title,
      int index,
      ) {
    bool selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2DAEFF).withOpacity(.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2DAEFF).withOpacity(.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF3BC2FF)
                      : Colors.white54,
                  size: 21,
                ),
              ),

              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF3BC2FF)
                      : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/scheduletimer/ScheduleScreen.dart';
import 'package:untitled/authentication/NewProfileScreen.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/model/ProfileInfo.dart';
import '../authentication/rest/APIService.dart';

import '../erroralert/AlertsScreen.dart';
import '../installer/InstallerList.dart';
import '../installer/InstallerProfile.dart';
import 'NewDeviceControlScreen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String roleType = "end_user";

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return NewDeviceControlScreen();

      case 1:
        return ScheduleScreen();

      case 2:
        return AlertsScreen();

      case 3:
        return NewProfileScreen();

      default:
        return NewDeviceControlScreen();
    }
  }
  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      roleType = prefs.getString("current_role") ?? "installer";
    });
  }
  List<Widget> getPages() {
    if (roleType == "installer") {
      return [
        Installerlist(),
        Installerprofile(),
      ];
    }

    return [
      NewDeviceControlScreen(),
      ScheduleScreen(),
      AlertsScreen(),
      NewProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> getBottomItems() {
    if (roleType == "installer") {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Schedule',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications_none),
        label: 'Error',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Me',
      ),
    ];
  }
  @override
  void initState() {
    super.initState();
    loadRole();
  }
  @override
  Widget build(BuildContext context) {
    final pages = getPages();

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: getBottomItems(),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Dashboard"));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Settings"));
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String userId = "";
  String firstLetter = "";

  @override
  void initState() {
    super.initState();
    loadProfile(); // 🔥 CALL HERE
  }

  // 🔹 Load Profile
  void loadProfile() async {
    final profile = await getProfileInfo();

    if (profile != null) {
      final data = profile.data;

      setState(() {
        name = data.name;
        email = data.email;
        userId = data.id.toString();
        firstLetter = data.name.isNotEmpty
            ? data.name.substring(0, 1).toUpperCase()
            : "";
      });
    }
  }

  // 🔹 API Call
  Future<ProfileInfo?> getProfileInfo() async {
    final api = ApiService();

    try {
      final response = await api.get("profile");

      if (response.statusCode == 200) {
        return ProfileInfo.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => NewLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF051139),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // 👈 FIX
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // FIXED: blur_on (lowercase 'b')
                    Image.asset("assets/aether_logo.png", height: 40),
                  ],
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1D4D).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 60,
                            width: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF64B5F6), Color(0xFF9575CD)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            // FIXED: Added Expanded to prevent overflow
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      _buildInfoTile("User ID", userId, Icons.person_outline),
                      SizedBox(height: 15),
                      _buildInfoTile("Device ID", "", Icons.lock_outline),
                      SizedBox(height: 15),
                      _buildInfoTile(
                        "Email Address",
                        email,
                        Icons.email_outlined,
                      ),
                      const SizedBox(height: 30),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 20),
                      _buildButton("Sign Out", context, "logout"),
                      const SizedBox(height: 15),
                      _buildButton("Remove Device", context, "device"),
                      const SizedBox(height: 15),
                      _buildButton("Setup Wi-Fi", context, "wifi_setup"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, BuildContext context, String clicktype) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () async {
          if (clicktype == "logout") {
            bool? confirm = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Logout"),
                content: Text("Are you sure?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("No"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("Yes"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              logout();
            }
          } else if (clicktype == "device") {
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

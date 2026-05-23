import 'package:flutter/material.dart';
import 'package:untitled/WelcomeScreen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/NewProfileScreen.dart';
import '../authentication/rest/APIService.dart';
import '../device_details/HomeScreen.dart';
import '../installer/InstallerList.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("token $token");
    await Future.delayed(const Duration(seconds: 2)); // optional splash delay

    if (token != null && token.isNotEmpty) {
      // 🔥 Restore token into Dio
      ApiService().setToken(token);

      // ✅ Go to Home
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      });
    } else {
      // ❌ Go to Login
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NewLoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        // 🔥 full screen
        child: Image.asset(
          "assets/aether_4.png",
          fit: BoxFit.cover, // 🔥 fill entire screen
        ),
      ),
    );
  }
}

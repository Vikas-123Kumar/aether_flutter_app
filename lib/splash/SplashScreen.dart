import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../authentication/NewLoginScreen.dart';
import '../authentication/rest/APIService.dart';
import '../device_details/HomeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Timer? _dotTimer;
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();

    // Start dot animation
    _dotTimer = Timer.periodic(
      const Duration(milliseconds: 400),
          (timer) {
        if (mounted) {
          setState(() {
            _currentDot = (_currentDot + 1) % 3;
          });
        }
      },
    );

    checkLogin();
  }

  Future<void> checkLogin() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Get saved token
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    print("token $token");

    // Keep splash visible for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Restore token into Dio
      ApiService().setToken(token);

      // Go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(),
        ),
      );
    } else {
      // Go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NewLoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF12324B),
              Color(0xFF0D1E2F),
              Color(0xFF09121D),
            ],
            stops: [
              0.0,
              0.50,
              1.0,
            ],
          ),
        ),

        child: SafeArea(
          child: Stack(
            children: [

              // ------------------------------------------------
              // CENTER LOGO / TEXT
              // ------------------------------------------------
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Aether',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),

                          TextSpan(
                            text: ' Smart',
                            style: TextStyle(
                              color: Color(0xFF00A8E8),
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Heat, intelligently controlled.',
                      style: TextStyle(
                        color: Color(0xFFE1E6EA),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // LOADING DOTS
              // ------------------------------------------------
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (index) {
                      final bool isActive = index == _currentDot;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),

                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),

                        width: isActive ? 7 : 6,
                        height: isActive ? 7 : 6,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00A8E8).withOpacity(
                            isActive ? 1.0 : 0.45,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/authentication/InstallerLogin.dart';
import 'dart:convert';

import 'package:untitled/authentication/NewLoginScreen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  String _selectedRole = '';

  Future<void> _submitRole(String role) async {
    if (role == "Installer") {
      Navigator.push(context,  MaterialPageRoute(builder: (context) => InstallerLoginScreen()));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 70,
                    height: 70,

                    child:  Image.asset("assets/aether_logo.png", height: 120),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome to a smarter\nhot water',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to control your heat pump — or\nas an installer to commission and service\nunits in the field.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _buildRoleOption(
                    title: "I'm a Homeowner",
                    subtitle: "Control & monitor your heat pump",
                    icon: Icons.home,
                    isSelected: _selectedRole == "Homeowner",
                    onTap: () => _submitRole("Homeowner"),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleOption(
                    title: "I'm an Installer",
                    subtitle: "Commission, service & transfer units",
                    icon: Icons.build,
                    isSelected: _selectedRole == "Installer",
                    onTap: () => _submitRole("Installer"),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Aether Energy - Melbourne, Australia · v1.0',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF161F33),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2C47),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: const Color(0xFF00A8E8)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

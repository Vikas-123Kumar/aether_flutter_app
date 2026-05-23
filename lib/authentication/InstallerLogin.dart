import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/authentication/rest/APIService.dart';

import '../common_function/SnackBar.dart';
import '../device_details/HomeScreen.dart';

class InstallerLoginScreen extends StatefulWidget {
  const InstallerLoginScreen({super.key});

  @override
  State<InstallerLoginScreen> createState() => _LoginScreenState();
}
// key password: aether123
//name Aether Smart
// organization Aether
// state Guajarat
//City Gandhinagar
class _LoginScreenState extends State<InstallerLoginScreen> {
  bool isPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController technicianController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final api = ApiService();

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String technician = technicianController.text.trim();
    final String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    try {
      final response = await api.post("userLogin", {
        "email": email,
        "password": password,
        "technician": technician,
      });

      final data = response.data;

      if (data["success"] == true) {
        // ✅ SUCCESS
        showSnack(context, data["message"],"success");

        String token = data["token"];
        print("Token: $token");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        // Navigate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        // ❌ ERROR
        showSnack(context, data["message"],"fail");
      }
    } catch (e) {
      print("Error: $e");
      showSnack(context, "Something went wrong","fail");
    }
  }


  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1A2A), Color(0xFF020C1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    /// Back Button
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),

                    const SizedBox(height: 30),

                    /// Icon Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.home, color: Colors.blue, size: 30),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Installer Access",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign in with your Aether technician credentials.",
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),

                    const SizedBox(height: 30),

                    /// Email Field
                    buildField(
                      controller: emailController,
                      hint: "alex@home.com",
                      icon: Icons.email,
                    ),

                    const SizedBox(height: 15),

                    /// Password Field
                    buildField(
                      controller: passwordController,
                      hint: "******",
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 15),
                    buildField(
                      controller: technicianController,
                      hint: "Technician ID (optional)",
                      icon: Icons.engineering,
                    ),
                    const SizedBox(height: 25),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Sign in →",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Signup Text
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Need an account? ",
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          children: const [
                            TextSpan(
                              text: "Get started",
                              style: TextStyle(color: Colors.blue),
                            )
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: Text(
                        "Protected by Aether Secure · End-to-end encryption",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
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
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
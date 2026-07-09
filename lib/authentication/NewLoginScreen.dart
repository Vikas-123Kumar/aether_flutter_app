import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/authentication/SetPasswordScreen.dart';
import 'package:untitled/authentication/rest/APIService.dart';

import '../InternetService.dart';
import '../common_function/SnackBar.dart';
import '../device_details/HomeScreen.dart';
import 'SignupScreen.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<NewLoginScreen> {
  bool isPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final api = ApiService();

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    bool connected = await InternetService().hasInternet();
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection"),
        ),
      );
      return;
    }
    try {
      final response = await api.post("userLogin", {
        "email": email,
        "password": password,
      });

      final data = response.data;

      if (data["success"] == true) {
        showSnack(context, data["message"], "success");

        String token = data["token"];
        int userId = data["user"]["id"];

        ApiService().setToken(token);

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", token);
        await prefs.setInt("user_id", userId);
        await prefs.setString("current_role", data["current_role"]);
        String role = data["current_role"];
        print("User ID: $userId  $role");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        // ❌ ERROR
        showSnack(context, data["message"], "fail");
      }
    } catch (e) {
      print("Error: $e");
      showSnack(context, "Something went wrong", "fail");
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/inside_bg.png"),
            fit: BoxFit.cover, // important
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
                    const SizedBox(height:50),
                    /// Icon Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Welcome back",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign in to control your Aether heat pump.",
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),

                    const SizedBox(height: 30),

                    /// Email Field
                    buildField(
                      controller: emailController,
                      hint: "Enter address",
                      icon: Icons.email,
                    ),

                    const SizedBox(height: 15),

                    /// Password Field
                    buildField(
                      controller: passwordController,
                      hint: "password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SetPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF00B4D8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Sign in",
                                style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Signup Text
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Register",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Signupscreen(), // 👈 your next screen
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: Text(
                        "Protected by Aether Secure · End-to-end encryption",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
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
          prefixIcon: Icon(icon,  color: Colors.blueAccent),
          hintText: hint,
          hintStyle: const TextStyle( color: Colors.blueAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

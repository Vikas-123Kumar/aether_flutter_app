import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/authentication/NewLoginScreen.dart';
import 'dart:convert';

import 'package:untitled/authentication/OtpScreen.dart';
import 'package:untitled/authentication/rest/APIService.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final stateController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final timeZoneController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool acceptedTerms = false;

  // 🔥 API CALL
  Future<void> sendData() async {
    final String name = fullNameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String address = addressController.text.trim();
    final String state = stateController.text.trim();
    final String timeZone = timeZoneController.text.trim();
    final String phone_number = phoneController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        address.isEmpty ||
        phone_number.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    final api = ApiService();
    try {
      final body = {
        "name": name,
        "state": state,
        "email": email,
        "password": password,
        "phone_number": phone_number,
        "address": address,
        "timezone": timeZone,
        "type": "end_user",
      };

      print("REQUEST JSON: $body");

      final response = await api.post("signUp", {
        "name": name,
        "state": state,
        "email": email,
        "password": password,
        "phone_number": phone_number,
        "address": address,
        "timezone": timeZone,
        "type": "end_user",
      });
      final responseOtp = await api.post("sendOtp", {
        "state": state,
        "email": email,
      });
      print("response $response");
      print("response otp  $responseOtp");

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Success")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${response.data}")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/inside_bg.png"),
            fit: BoxFit.cover, // important
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    "Create account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _input(fullNameController, "Full name"),
                  _input(emailController, "Email"),
                  _input(stateController, "State"),
                  _input(phoneController, "Phone"),
                  _input(addressController, "Address"),
                  _input(timeZoneController, "Time zone"),

                  _passwordField(passwordController, "Password", true),
                  _passwordField(
                    confirmPasswordController,
                    "Confirm password",
                    false,
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (v) {
                          setState(() => acceptedTerms = v!);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "I agree to the Terms and Privacy Policy",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: isLoading ? null : sendData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Create account"),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign in",
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
                                        NewLoginScreen(), // 👈 your next screen
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF121A2F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint,
    bool isMain,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isMain ? obscurePassword : obscureConfirm,
        style: const TextStyle(color: Colors.white),
        validator: (v) {
          if (v!.isEmpty) return "Required";
          if (!isMain && v != passwordController.text) {
            return "Passwords do not match";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF121A2F),
          suffixIcon: IconButton(
            icon: Icon(
              (isMain ? obscurePassword : obscureConfirm)
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                if (isMain) {
                  obscurePassword = !obscurePassword;
                } else {
                  obscureConfirm = !obscureConfirm;
                }
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

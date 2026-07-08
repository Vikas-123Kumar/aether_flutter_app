import 'package:dropdown_button2/dropdown_button2.dart';
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
  String selectedUserType = "end_user";

  final installerIdController = TextEditingController();
  final companyNameController = TextEditingController();
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
  List<dynamic> states = [];
  @override
  void initState() {
    super.initState();
    getStates();
  }
  Map<String, dynamic>? selectedState;

  Future<void> getStates() async {
    try {
      final api = ApiService();

      final response = await api.get("listState");

      print("STATE RESPONSE => ${response.data}");

      if (response.statusCode == 200) {
        setState(() {
          states = List<Map<String, dynamic>>.from(
            response.data["states"] ?? [],
          );
        });

        print("States Length => ${states.length}");
        print("States Data => $states");
      }
    } catch (e) {
      print("State API Error: $e");
    }
  }
  // 🔥 API CALL
  Future<void> sendData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = fullNameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String state = stateController.text.trim();
    final String phoneNumber = phoneController.text.trim();

    final String address = addressController.text.trim();
    final String timeZone = timeZoneController.text.trim();

    final String installerId = installerIdController.text.trim();
    final String companyName = companyNameController.text.trim();

    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms and Privacy Policy")),
      );
      return;
    }

    if (selectedUserType == "end_user") {
      if (address.isEmpty || timeZone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all End User fields")),
        );
        return;
      }
    }

    if (selectedUserType == "installer") {
      if (installerId.isEmpty || companyName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill Installer ID and Company Name"),
          ),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final api = ApiService();

      Map<String, dynamic> body = {
        "name": name,
        "state": state,
        "email": email,
        "password": password,
        "phone_number": phoneNumber,
        "type": selectedUserType,
      };

      if (selectedUserType == "end_user") {
        body["address"] = address;
        body["timezone"] = timeZone;
      }

      if (selectedUserType == "installer") {
        body["licence_no"] = installerId;
        body["company_name"] = companyName;
        body["address"] = address;
        body["timezone"] = timeZone;
      }

      print("REQUEST JSON => $body");

      final response = await api.post("signUp", body);

      final responseOtp = await api.post("sendOtp", {"email": email});

      print("Signup Response => $response");
      print("OTP Response => $responseOtp");

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data.toString())));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedUserType = "end_user";
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedUserType == "end_user"
                                  ? Colors.blue
                                  : const Color(0xFF121A2F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "End User",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedUserType = "installer";
                            });
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedUserType == "installer"
                                  ? Colors.blue
                                  : const Color(0xFF121A2F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "Installer",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _input(
                    fullNameController,
                    "Full Name",
                    Icons.person_outline,
                  ),

                  _input(
                    emailController,
                    "Email",
                    Icons.email_outlined,
                  ),
                  _input(
                    phoneController,
                    "Phone",
                    Icons.phone_outlined,
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField2<Map<String, dynamic>>(
                      isExpanded: true,
                      value: selectedState,

                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF121A2F),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 1,
                          vertical: 14,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 1.2,
                          ),
                        ),
                      ),

                      hint: Row(
                        children: const [
                          Icon(
                            Icons.location_city_outlined,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          SizedBox(width: 15),
                          Text(
                            "Select State",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      buttonStyleData: const ButtonStyleData(
                        height: 32,
                        padding: EdgeInsets.zero,
                      ),

                      iconStyleData: const IconStyleData(
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                      ),

                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          color: const Color(0xFF121A2F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      menuItemStyleData: const MenuItemStyleData(
                        height: 50,
                      ),

                      items: states.map((state) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: state,
                          child: Row(
                            children: [

                              Expanded(
                                child: Text(
                                  state["state_name"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      selectedItemBuilder: (context) {
                        return states.map<Widget>((state) {
                          return Row(
                            children: [
                              const Icon(
                                Icons.location_city_outlined,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  state["state_name"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },

                      onChanged: (value) {
                        setState(() {
                          selectedState = value;

                          stateController.text =
                              value?["state_name"] ?? "";

                          timeZoneController.text =
                              value?["time_zone"] ?? "";
                        });
                      },
                    ),
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: timeZoneController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        hintText: "Time Zone",
                        hintStyle: const TextStyle(color: Colors.grey),

                        prefixIcon: const Icon(
                          Icons.access_time_outlined,
                          color: Colors.blueAccent,
                          size: 22,
                        ),

                        filled: true,
                        fillColor: const Color(0xFF121A2F),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  _input(
                    addressController,
                    "Address",
                    Icons.home_outlined,
                  ),

                  if (selectedUserType == "installer") ...[
                    _input(
                      installerIdController,
                      "Installer ID",
                      Icons.badge_outlined,
                    ),

                    _input(
                      companyNameController,
                      "Company Name",
                      Icons.business_outlined,
                    ),
                  ],
                  _passwordField(passwordController, "Password", true, Icons.lock,),
                  _passwordField(
                    confirmPasswordController,
                    "Confirm password",
                    false,
                    Icons.lock,
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
                        : const Text("Create account",style: TextStyle(color: Colors.white)),
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

  Widget _input(
      TextEditingController controller,
      String hint,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),

          prefixIcon: Icon(
            icon,
            color: Colors.blueAccent,
            size: 22,
          ),

          filled: true,
          fillColor: const Color(0xFF121A2F),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.blueAccent,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
  Widget _passwordField(
    TextEditingController controller,
    String hint,
    bool isMain,
      IconData icon,
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
          prefixIcon: Icon(
            icon,
            color: Colors.blueAccent,
          ),
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

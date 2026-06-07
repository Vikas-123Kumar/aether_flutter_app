import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/authentication/rest/APIService.dart';

import '../common_function/SnackBar.dart';
import 'NewLoginScreen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  int seconds = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    seconds = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  String getOtp() {
    return controllers.map((e) => e.text).join();
  }

  final api = ApiService();

  Future<void> verifyOtp() async {
    String otp = getOtp();
    if (otp.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter 6 digit otp")));
      return;
    }
    try {
      final response = await api.post("verifyOtp", {
        "email": widget.email,
        "otp": otp,
      });

      final data = response.data;
      if (data["message"] == "OTP verified successfully") {
        showSnack(context, data["message"], "success");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const NewLoginScreen(),
          ),
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

  Future<void> resendOtp() async {
    print("Resend OTP");

    try {
      final response = await api.post("resendOTP", {"email": widget.email});

      final data = response.data;

      if (data["success"] == true) {
        // ✅ SUCCESS
        showSnack(context, data["message"], "success");
        // Navigate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NewLoginScreen()),
        );
      } else {
        // ❌ ERROR
        showSnack(context, data["message"], "fail");
      }
    } catch (e) {
      print("Error: $e");
      showSnack(context, "Something went wrong", "fail");
    }

    startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP Resent")));
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06142E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Enter Verification Code",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, otpBox),
            ),

            const SizedBox(height: 20),

            Text(
              "A verification code has been sent to your email address.",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),

            const SizedBox(height: 5),

            Text(widget.email, style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "Didn't get code? ",
                  style: TextStyle(color: Colors.white70),
                ),
                GestureDetector(
                  onTap: seconds == 0 ? resendOtp : null,
                  child: Text(
                    seconds == 0 ? "Resend" : "Resend in $seconds s",
                    style: TextStyle(
                      color: seconds == 0 ? Colors.blueAccent : Colors.white38,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

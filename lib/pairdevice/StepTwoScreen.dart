import 'package:flutter/material.dart';
import 'StepThreeScreen.dart';

class StepTwoScreen extends StatelessWidget {
  const StepTwoScreen({Key? key}) : super(key: key);

  static const Color bgColorStart = Color(0xFF0F1725);
  static const Color bgColorEnd = Color(0xFF0A101A);
  static const Color blue = Color(0xFF4CA6FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColorEnd,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColorStart,
              bgColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 5.0,
              vertical: 2.0,
            ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------------
                // HEADER
                // ----------------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock the controller',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Step 2 of 6',
                          style: TextStyle(
                            color: Color(0xFF9298A3),
                            fontSize: 13,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // INSTRUCTION
                // ----------------------------------------------------------
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Color(0xFFB7BBC3),
                      fontSize: 14,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: 'On your heat pump controller, ',
                      ),
                      TextSpan(
                        text: 'press and hold the power button',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                        ' and wait for the lock icon to disappear.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // CONTROLLER IMAGE
                // ----------------------------------------------------------
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: blue.withOpacity(0.20),
                          blurRadius: 100,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/lock_screen.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ----------------------------------------------------------
                // INFO BOX
                // ----------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [

                        Color(0xFF1533C2FF),
                        Color(0xFF1533C2FF),

                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1533C2FF),
                              Color(0xFF1533C2FF),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: blue.withOpacity(0.20),
                          ),
                        ),
                        child: const Icon(
                          Icons.power_settings_new,
                          color: blue,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Text
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Color(0xFFB3B7BF),
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: 'Hold for about ',
                              ),
                              TextSpan(
                                text: '5-10 seconds',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text:
                                '. The padlock at the top of the display will fade out — that means the child lock is off and the keypad is live.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // PRIMARY BUTTON
                // ----------------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF57BAFF),
                          Color(0xFF3886FF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withOpacity(0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const StepThreeScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_open_outlined,
                              color: Color(0xFF001A33),
                              size: 18,
                            ),

                            SizedBox(width: 8),

                            Text(
                              'Lock icon has now disappeared',
                              style: TextStyle(
                                color: Color(0xFF001A33),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            SizedBox(width: 6),

                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF001A33),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ----------------------------------------------------------
                // FOOTER
                // ----------------------------------------------------------
                Center(
                  child: Text(
                    'Still showing the lock? Hold the power button a little longer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),),
    );
  }
}
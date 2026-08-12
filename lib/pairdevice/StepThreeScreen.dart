import 'package:flutter/material.dart';
import 'package:untitled/pairdevice/StepFourScreen.dart';

class StepThreeScreen extends StatelessWidget {
  const StepThreeScreen({Key? key}) : super(key: key);
  static const Color bgColorStart = Color(0xFF0F1725);
  static const Color bgColorEnd = Color(0xFF0A101A);
  static const Color blue = Color(0xFF4CA6FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517), // Dark background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColorStart, bgColorEnd],
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
                horizontal: 15.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CUSTOM APP BAR / HEADER
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enable pairing mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step 3 of 6',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // 2. INSTRUCTION TEXT
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: 'Now '),
                        TextSpan(
                          text: 'press and hold the M and + buttons together',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' until the Wi-Fi signal starts flashing on the display.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. CONTROLLER IMAGE WITH GLOW
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
                          'assets/wifi_screen.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  const SizedBox(height: 5),

                  // 4. "WHAT YOU SHOULD SEE" INFO BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1533C2FF), Color(0xFF1533C2FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What you should see',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint('A short beep from the controller'),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'The Wi-Fi symbol appears at the top of the screen',
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'It blinks about once per second — that\'s pairing mode',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. PRIMARY BUTTON
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF57BAFF), Color(0xFF3886FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CA6FF).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StepFourScreen(),
                            ),
                          );
                          // TODO: Navigate to Step 4
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.wifi,
                              color: Color(0xFF001A33),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Wi-Fi icon is now flashing',
                              style: TextStyle(
                                color: Color(0xFF001A33), // Dark navy text
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),),
    );
  }

  // Helper widget to cleanly build bullet points
  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '- ',
          style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

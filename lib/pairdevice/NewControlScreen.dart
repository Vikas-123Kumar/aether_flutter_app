import 'package:flutter/material.dart';
import 'StepTwoScreen.dart';
class NewControlDevice extends StatelessWidget {
  const NewControlDevice({Key? key}) : super(key: key);
  final Color bgColorStart = const Color(0xFF0F1725);
  final Color bgColorEnd = const Color(0xFF0A101A);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We apply the gradient to the body instead of a solid Scaffold background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(

            colors: [bgColorStart, bgColorEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 2.0,
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // 1. TEXT SECTION (Wrapped in Padding)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      'SETUP • STEP 1 OF 6',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFamily: 'Roboto',
                        ),
                        children: [
                          TextSpan(
                            text: "Let's connect your\n",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "Aether heat pump",
                            style: TextStyle(color: Color(0xFF4CA6FF)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "It takes about 3 minutes. Stand near your unit\nwith the controller screen visible — we'll\nguide you through every tap.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. HEAT PUMP IMAGE (No Padding = Edge-to-Edge)
               SizedBox(
                 height: 380,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/container.png',
                    fit: BoxFit.contain, // Ensures the image stretches to fill width
                    alignment: Alignment.topCenter,
                  ),
                ),

              // 3. BUTTON & FOOTER SECTION (Wrapped in Padding)
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 44,
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
                              MaterialPageRoute(builder: (context) => const StepTwoScreen()),
                            );
                            // TODO: Add navigation here
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Start setup',
                                style: TextStyle(
                                  color: Color(0xFF001A33),
                                  fontSize: 16,
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
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // TODO: Handle installer invite tap
                      },
                      child: Text(
                        "",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),),
      ),
    );
  }
}
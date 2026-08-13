import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:untitled/pairdevice/ConnectScreen.dart';

class StepFourScreen extends StatefulWidget {
  const StepFourScreen({Key? key}) : super(key: key);

  @override
  State<StepFourScreen> createState() => _StepFourScreenState();
}

class _StepFourScreenState extends State<StepFourScreen> {
  bool showManualEntry = false;
  static const Color bgColorStart = Color(0xFF0F1725);
  static const Color bgColorEnd = Color(0xFF0A101A);
  static const Color blue = Color(0xFF4CA6FF);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131517),
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
              horizontal: 15.0,
              vertical: 2.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // 1. HEADER
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
                          'Scan the serial number',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step 4 of 6',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // 2. WHERE TO LOOK CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1533C2FF), Color(0xFF1533C2FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF4CA6FF),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Where to look',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 350,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/qr_code_image.png',
                            width: double.infinity,
                            height: 400,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: const [
                            TextSpan(text: 'Look at the '),
                            TextSpan(
                              text: 'lower right',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' of the unit. You\'ll find a small white sticker with a barcode and QR code.',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Model Label
                            const Text(
                              'SL-WIFI-W',
                              style: TextStyle(
                                color: Color(0xFF1E242B), // Very dark blue/grey
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // 2. Serial Number
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Roboto', // Matches Android default sans-serif
                                ),
                                children: [
                                  TextSpan(
                                    text: 'SN: ',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280), // Medium grey
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '0000000',
                                    style: TextStyle(
                                      color: Color(0xFF1E242B),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0, // Adds the slight gap between digits
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),

                            // 3. Verification Code
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Verification: ',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280), // Medium grey
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'xxxxxx',
                                    style: TextStyle(
                                      color: Color(0xFF1E242B),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0, // Adds the slight gap between chars
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. SELECTION BUTTONS
                Row(
                  children: [
                    // Open Camera Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Open the dedicated full-screen scanner
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FullScreenScannerPage(),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF263D5C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CA6FF).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Color(0xFF4CA6FF),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Scan QR / label',
                                style: TextStyle(
                                  color: Color(0xFF4CA6FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Manual Entry Toggle Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConnectScreen(
                                fromNoDevice: true,
                                manualEnter:true,
                                serial_number: "",
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: showManualEntry
                                ? const Color(0xFF1E242B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_alt_outlined,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enter manually',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// DEDICATED FULL-SCREEN SCANNER PAGE
// ==========================================
class FullScreenScannerPage extends StatefulWidget {
  const FullScreenScannerPage({Key? key}) : super(key: key);

  @override
  State<FullScreenScannerPage> createState() => _FullScreenScannerPageState();
}

class _FullScreenScannerPageState extends State<FullScreenScannerPage> {
  bool isNavigating = false;

  // 1. Define the controller and restrict the format to qrCode only
  final MobileScannerController cameraController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    // 2. Remember to dispose of the controller to free up resources
    cameraController.dispose();
    super.dispose();
  }

  void _showInvalidQrDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1E2F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1E4563),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF299DEB).withOpacity(0.20),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF132F45),
                    border: Border.all(
                      color: const Color(0xFF299DEB).withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Color(0xFF38B6F6),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 18),

                // Title
                const Text(
                  'Invalid QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                // Message
                const Text(
                  'The scanned QR code is not valid.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB8C6D1),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                // OK button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF38B6F6),
                          Color(0xFF4C8FFB),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF299DEB).withOpacity(0.30),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => isNavigating = false);
                        },
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'OK',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 7),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3. Pass the controller to the MobileScanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                if (isNavigating) return;

                String rawData = barcodes.first.rawValue!;
                bool isValid = false;
                String extractedSerialNumber = "";

                if (rawData.contains(';')) {
                  List<String> parts = rawData.split(';');
                  if (parts.length > 1) {
                    String secondPart = parts[1].trim();

                    if (RegExp(r'^[0-9]+$').hasMatch(secondPart)) {
                      isValid = true;
                      extractedSerialNumber = secondPart;
                    }
                  }
                }

                setState(() => isNavigating = true);

                if (isValid) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectScreen(
                        fromNoDevice: true,
                        manualEnter: false,
                        serial_number: extractedSerialNumber,
                      ),
                    ),
                  );
                } else {
                  _showInvalidQrDialog();
                }
              }
            },
          ),

          // Custom Overlay (Darkened edges with a clear center cutout)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF4CA6FF),
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: 250,
                overlayColor: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          // UI Elements (Back button and instructions)
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Custom Shape to create the dark overlay with a transparent hole in the middle
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.addRect(rect);
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ),
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final borderLength = this.borderLength;
    final cutOutSize = this.cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      boxPaint,
    );
    canvas.restore();

    // Draw Corners
    final double left = cutOutRect.left;
    final double top = cutOutRect.top;
    final double right = cutOutRect.right;
    final double bottom = cutOutRect.bottom;

    // Top left
    canvas.drawLine(
      Offset(left, top + borderRadius),
      Offset(left, top + borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, top),
      Offset(left + borderLength, top),
      borderPaint,
    );
    // Top right
    canvas.drawLine(
      Offset(right, top + borderRadius),
      Offset(right, top + borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, top),
      Offset(right - borderLength, top),
      borderPaint,
    );
    // Bottom left
    canvas.drawLine(
      Offset(left, bottom - borderRadius),
      Offset(left, bottom - borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, bottom),
      Offset(left + borderLength, bottom),
      borderPaint,
    );
    // Bottom right
    canvas.drawLine(
      Offset(right, bottom - borderRadius),
      Offset(right, bottom - borderLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, bottom),
      Offset(right - borderLength, bottom),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

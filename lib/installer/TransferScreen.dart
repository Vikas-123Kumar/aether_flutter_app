import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _contactController = TextEditingController();
  bool _isEmailSelected = true;
  bool _isLoading = false;
  String device_name = "Aether Home Heat Pump";
  String model = "Aether Home 270L - AE-HP-2402-7841";

  Future<void> _transferDevice() async {
    if (_contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEmailSelected
                ? 'Please enter an email address'
                : 'Please enter a phone number',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://your-api-endpoint.com/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': 'AE-HP-2402-7841',
          'type': _isEmailSelected ? 'email' : 'sms',
          'contact': _contactController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer initiated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate transfer.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer to customer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Aether Home Heat Pump',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF131C31),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'READY TO TRANSFER',
                    style: TextStyle(
                      color: Color(0xFF00B4D8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    device_name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _isEmailSelected
                          ? const Color(0xFF00B4D8)
                          : const Color(0xFF131C31),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEmailSelected = true;
                      });
                    },
                    child: Text(
                      'Email',
                      style: TextStyle(
                        color: _isEmailSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: !_isEmailSelected
                          ? const Color(0xFF00B4D8)
                          : const Color(0xFF131C31),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEmailSelected = false;
                      });
                    },
                    child: Text(
                      'SMS',
                      style: TextStyle(
                        color: !_isEmailSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _isEmailSelected ? 'CUSTOMER EMAIL' : 'CUSTOMER PHONE',
              style: const TextStyle(
                color: Color(0xFF00B4D8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              keyboardType: _isEmailSelected
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131C31),
                hintText: _isEmailSelected
                    ? 'customer@example.com'
                    : '+1234567890',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  _isEmailSelected ? Icons.email : Icons.phone,
                  color: const Color(0xFF00B4D8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEmailSelected
                  ? "We'll email the customer a one-tap link to claim the device. Until they accept you keep diagnostic access."
                  : "We'll text the customer a one-tap link to claim the device. Until they accept you keep diagnostic access.",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isLoading ? null : _transferDevice,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEmailSelected ? 'Email' : 'SMS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF131C31),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
              ),
              child: const Text(
                'This unit is only linked to the installer workspace right now. Ownership transfers only after you send an invite and the customer accepts it.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

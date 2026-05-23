import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConfirmTransferScreen extends StatefulWidget {
  final String deviceName;
  final String serialNumber;
  final String customerName;

  const ConfirmTransferScreen({
    super.key,
    required this.deviceName,
    required this.serialNumber,
    required this.customerName,
  });

  @override
  State<ConfirmTransferScreen> createState() => _ConfirmTransferScreenState();
}

class _ConfirmTransferScreenState extends State<ConfirmTransferScreen> {
  bool _isLoading = false;

  // API Call function
  Future<void> confirmTransfer() async {
    setState(() => _isLoading = true);

    const String apiUrl = 'https://api.example.com/confirm-transfer'; // Replace with real API

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'device': widget.deviceName,
          'serial': widget.serialNumber,
          'customer': widget.customerName,
        }),
      );

      if (response.statusCode == 200) {
        // Success Logic
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transfer Successful!")),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Transfer Failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000D1D), // Dark Blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyan),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30),
                SizedBox(width: 10),
                Text(
                  "Confirm Transfer",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              "Please review the transfer details carefully before proceeding.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Device info card
            _buildInfoCard("Device to Transfer", [
              "Device: ${widget.deviceName}",
              "Serial: ${widget.serialNumber}",
            ]),

            const SizedBox(height: 20),

            // Customer info card
            _buildInfoCard(
              "Transfer To",
              ["Customer: ${widget.customerName}"],
              showEdit: true,
            ),

            const Spacer(),

            // Back Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Back", style: TextStyle(color: Colors.cyan, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 15),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : confirmTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm Transfer", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> details, {bool showEdit = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1929),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              if (showEdit) const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          ...details.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          )),
        ],
      ),
    );
  }
}
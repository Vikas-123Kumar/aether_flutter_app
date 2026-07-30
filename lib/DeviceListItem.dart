import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceListItem extends StatefulWidget {
  final dynamic device;
  final dynamic customer;
  final VoidCallback onTap;

  const DeviceListItem({
    Key? key,
    required this.device,
    required this.customer,
    required this.onTap,
  }) : super(key: key);

  @override
  State<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<DeviceListItem> {
  bool isFetchingStatus = true;
  String currentTemp = "--";
  String unit = "";
  String selectedMode = "--";

  @override
  void initState() {
    super.initState();
    String deviceId = widget.device["serial_number"] ?? "";
    if (deviceId.isNotEmpty) {
      _fetchDeviceData(deviceId);
    } else {
      setState(() {
        isFetchingStatus = false;
      });
    }
  }

  Future<void> _fetchDeviceData(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.get(
        Uri.parse("https://aetherone.com.au/api/v1/heat-pump-2/devices/$deviceId/current-data"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List dataList = decoded['data']['data'];

        if (mounted) {
          setState(() {
            // Find temperature (itemid == "3")
            final setPointData = dataList.firstWhere(
                    (item) => item["itemid"] == "3",
                orElse: () => null
            );

            // Find mode (itemid == "2")
            final setPointDataMode = dataList.firstWhere(
                    (item) => item["itemid"] == "2",
                orElse: () => null
            );

            if (setPointData != null) {
              currentTemp = setPointData["val"].toString();
              unit = setPointData["unit"] ?? "°";
            }

            if (setPointDataMode != null) {
              if (setPointDataMode["val"] == "2") {
                selectedMode = "Eco";
              } else if (setPointDataMode["val"] == "0") {
                selectedMode = "Comfort";
              } else if (setPointDataMode["val"] == "1") {
                selectedMode = "Boost";
              }
            }

            isFetchingStatus = false;
          });
        }
      } else {
        if (mounted) setState(() => isFetchingStatus = false);
      }
    } catch (e) {
      print("Error fetching item status: $e");
      if (mounted) setState(() => isFetchingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOnline = widget.device["is_online"] == 1;
    String deviceName = widget.device["product_name"] ?? "";
    // UI Fallbacks
    String customerName = widget.customer?["name"] ?? widget.device["name"] ?? "";
    String address = widget.customer?["address"] ?? "";
    String modelDetails = "$deviceName - ${widget.device["device_id"] ?? ""}";

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161F33),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon Status
            Stack(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF132A29) : const Color(0xFF2A211D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOnline ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isOnline ? const Color(0xFF38A169) : const Color(0xFFD69E2E),
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF38A169) : const Color(0xFF718096),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF161F33), width: 2),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(width: 14),

            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isOnline)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFB7791F),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            "1",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modelDetails,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right Temp & Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    isFetchingStatus
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF41BAFF),
                      ),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$currentTemp$unit",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          selectedMode,
                          style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 14),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
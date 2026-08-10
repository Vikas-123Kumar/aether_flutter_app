import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/authentication/rest/APIService.dart';

import '../common_function/SnackBar.dart';

// Import your ApiService file here
// import 'path_to_your_api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String name, email, phone, address, state, timezone;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.timezone,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _timezoneCtrl;
  String firstLetter = "";
  bool _isLoading = false;
  bool _isLoadingStates = true;
  final Color cardBg = const Color(0xFF0F1726);

  // Dynamic state list from API
  List<Map<String, dynamic>> states = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _emailCtrl = TextEditingController(text: widget.email);
    _phoneCtrl = TextEditingController(text: widget.phone);
    _addressCtrl = TextEditingController(text: widget.address);
    _stateCtrl = TextEditingController(text: widget.state);
    _timezoneCtrl = TextEditingController(text: widget.timezone);
    firstLetter = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "";

    // Fetch states from API when screen loads
    getStates();
  }

  // --- FETCH STATES FROM API ---
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
          _isLoadingStates = false;
        });

        print("States Length => ${states.length}");
      }
    } catch (e) {
      print("State API Error: $e");
      setState(() {
        _isLoadingStates = false;
      });
    }
  }

  // --- UPDATE PROFILE API CALL ---
  Future<void> _updateProfileAPI() async {
    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> updatePayload = {
      "name": _nameCtrl.text,
      "email": _emailCtrl.text,
      "phone_number": _phoneCtrl.text,
      "address": _addressCtrl.text,
      "state": _stateCtrl.text,
      "timezone": _timezoneCtrl.text,
      "company_name": "",
      "licence_no": "",
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response = await http.post(
        Uri.parse('https://aetherone.com.au/api/v1/updateProfile'),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updatePayload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 1. Decode the response body
        final responseData = jsonDecode(response.body);

        // 2. Check if the API returned success: true
        if (responseData['success'] == true) {
          // 3. Extract the updated full name from the 'data' object
          final updatedFullName = responseData['data']['full_name'];

          // 4. Save the updated full name to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("full_name", updatedFullName);
          showSnack(context, responseData["message"] ?? "Login successful", "success");

          // Return the updated payload back to the main Profile Page
          if (mounted) {
            Navigator.pop(context, updatePayload);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['message'] ?? 'Failed to update profile',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _timezoneCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Container(
            decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Your system & account",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          child: Column(
            children: [
              _buildUserHeader(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "CONTACT DETAILS",
                    style: TextStyle(
                      color: Color(0xff758194),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Navigate to Edit Screen and wait for returned dat
                      // If user saved data, update the UI
                    },
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              Navigator.pop(context);
                              // Optional: Reset controllers to original values here
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.close,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _updateProfileAPI();
                              // TODO: Add your API call here to save the updated JSON details
                            });
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEditRow("FULL NAME", Icons.person_outline, _nameCtrl),
                    _buildDivider(),
                    _buildEditRow("EMAIL", Icons.email_outlined, _emailCtrl),
                    _buildDivider(),
                    _buildEditRow(
                      "PHONE NUMBER",
                      Icons.phone_android_outlined,
                      _phoneCtrl,
                    ),
                    _buildDivider(),
                    _buildEditRow(
                      "ADDRESS",
                      Icons.location_on_outlined,
                      _addressCtrl,
                    ),
                    _buildDivider(),

                    // STATE DROPDOWN
                    _buildStateDropdownRow("STATE", Icons.map_outlined),
                    _buildDivider(),

                    // READ-ONLY TIMEZONE / ZONE FIELD
                    _buildReadOnlyRow(
                      "TIMEZONE",
                      Icons.access_time,
                      _timezoneCtrl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),

      decoration: BoxDecoration(
        color: const Color(0xFF161F33),
        borderRadius: BorderRadius.circular(16.0),
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF5AB2FF), Color(0xFF3282FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),

                  child: const Text(
                    "Active subscription",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC STATE DROPDOWN ROW ---
  Widget _buildStateDropdownRow(String title, IconData icon) {
    // Helper to get state name string from map item (handles common key names like 'name' or 'state_name')
    String getStateName(Map<String, dynamic> item) {
      return item['name'] ?? item['state_name'] ?? item['state'] ?? '';
    }

    // Helper to get timezone string from state map item
    String getZoneName(Map<String, dynamic> item) {
      return item['timezone'] ?? item['zone'] ?? item['time_zone'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.lightBlueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _isLoadingStates
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.lightBlueAccent,
                        ),
                      )
                    : SizedBox(
                        height: 48,
                        child: DropdownButtonFormField<String>(
                          value:
                              states.any(
                                (item) => getStateName(item) == _stateCtrl.text,
                              )
                              ? _stateCtrl.text
                              : null,
                          dropdownColor: const Color(0xFF101726),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            fillColor: Colors.white.withOpacity(0.05),
                            filled: true,
                            hintText: "Select State",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: states.map((Map<String, dynamic> item) {
                            final stateName = getStateName(item);
                            return DropdownMenuItem<String>(
                              value: stateName,
                              child: Text(stateName),
                            );
                          }).toList(),
                          onChanged: (selectedStateName) {
                            if (selectedStateName != null) {
                              setState(() {
                                _stateCtrl.text = selectedStateName;

                                // Find the matching state object to update timezone automatically
                                final selectedStateMap = states.firstWhere(
                                  (item) =>
                                      getStateName(item) == selectedStateName,
                                  orElse: () => {},
                                );

                                // Auto-populate non-editable Timezone
                                if (selectedStateMap.isNotEmpty) {
                                  _timezoneCtrl.text = getZoneName(
                                    selectedStateMap,
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- READ-ONLY ROW (FOR TIMEZONE) ---
  Widget _buildReadOnlyRow(
    String title,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.lightBlueAccent,
              size: 20,
            ), // Dimmed icon to show it's disabled
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: controller,
                    enabled: false, // Disables user input
                    style: TextStyle(
                      color: Colors.white,
                      // Dimmed text styling
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      fillColor: Colors.white.withOpacity(0.02),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STANDARD EDITABLE ROW ---
  Widget _buildEditRow(
    String title,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.lightBlueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      fillColor: Colors.white.withOpacity(0.05),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.05));
}

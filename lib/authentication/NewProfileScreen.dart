import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/authentication/NewLoginScreen.dart';
import 'package:untitled/authentication/rest/APIService.dart';
import 'dart:convert';

import '../common_function/SnackBar.dart';
import '../invite/InviteDialog.dart';
import '../pairdevice/ConnectScreen.dart';
import 'model/FamilyMember.dart';

class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({super.key});

  @override
  State<NewProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<NewProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _profileData = {};
  String name = "Vikas";
  String email = "vikas@gmail.com";
  String userId = "";
  String firstLetter = "";
  String mobile = "9927010683";
  List<FamilyMember> familyMembers = [];
  bool isFamilyLoading = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    getFamilyMembers();
  }

  Future<void> getFamilyMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      String deviceId = DeviceInformations.selectedDeviceId;
      final response = await http.get(
        Uri.parse(
          "https://aetherone.com.au/api/v1/deviceUsers?device_id=$deviceId",
        ),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("STATUS : ${response.statusCode}");
      print("BODY : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          familyMembers = (data['users'] as List)
              .map((e) => FamilyMember.fromJson(e))
              .toList();

          isFamilyLoading = false;
        });
      } else {
        setState(() {
          isFamilyLoading = false;
        });
      }
    } catch (e) {
      print("ERROR : $e");

      setState(() {
        isFamilyLoading = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    const String apiUrl = 'https://aetherone.com.au/api/v1/profile';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      print("token $token");
      final response = await http.get(
        Uri.parse(apiUrl),

        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Status Code => ${response.statusCode}");
      print("Body => ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        print("Decoded Data => $decodedData");

        /// API main data object
        final userData = decodedData["data"];

        setState(() {
          _profileData = userData;

          /// Set values from API
          name = userData["full_name"] ?? "";

          email = userData["email"] ?? "";

          mobile = userData["phone_number"] ?? "";

          userId = userData["id"].toString();

          /// First letter for avatar
          firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "U";
        });
      } else {
        print("API Failed");
      }
    } catch (e) {
      print("Error => $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void moveConnect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectScreen()),
    );
  }

  Future<Map<String, dynamic>> deleteUserFromDevice({
    required String deviceId,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.delete(
        Uri.parse(
          "https://aetherone.com.au/api/v1/deleteUserFromDevice",
        ),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"device_id": deviceId, "user_id": userId}),
      );

      final data = jsonDecode(response.body);

      return {
        "success": response.statusCode == 200,
        "message": data["message"] ?? "Unknown error",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<void> logout() async {
    final api = ApiService();
    try {
      final response = await api.post("logout", {});
      final data = response.data;

      if (data["success"] == true) {
        showSnack(context, data["message"], "success");

        final prefs = await SharedPreferences.getInstance();

        // ✅ CLEAR TOKEN
        await prefs.remove("token");
        await prefs.clear(); // optional (clears all saved data)

        // ✅ NAVIGATE TO LOGIN
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NewLoginScreen()),
          (route) => false,
        );
      } else {
        showSnack(context, data["message"], "fail");
      }
    } catch (e) {
      print("Error: $e");

      showSnack(context, "Something went wrong", "fail");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NewLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF162544),
                foregroundColor: const Color(0xFF00B4D8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.star_border, size: 16),
              label: const Text("Assist"),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserHeader(),
                  const SizedBox(height: 20),
                  const Text(
                    "CONTACT DETAILS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  _buildContactDetails(name, "Full Name"),
                  const SizedBox(height: 4),
                  _buildContactDetails(email, "Email"),
                  const SizedBox(height: 4),
                  _buildContactDetails(mobile, "Mobile No."),
                  const SizedBox(height: 4),
                  _buildFamilyAndGuests(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : moveConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Update Wifi Credential",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  //_buildInstallerAndSupport(),
                ],
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
          CircleAvatar(
            radius: 28,

            backgroundColor: const Color(0xFF00B4D8).withOpacity(0.2),

            child: Text(
              firstLetter,

              style: const TextStyle(
                color: Color(0xFF00B4D8),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,

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

  Widget _buildContactDetails(String name, String title1) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...List.generate(1, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title1,
                      style: TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                    SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFamilyAndGuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "FAMILY & GUESTS",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => InviteDialog(),
                );
              },
              icon: const Icon(
                Icons.person_add,
                size: 14,
                color: Color(0xFF00B4D8),
              ),
              label: const Text(
                "Invite",
                style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161F33),
            borderRadius: BorderRadius.circular(16),
          ),

          child: isFamilyLoading
              ? const Center(child: CircularProgressIndicator())
              : familyMembers.isEmpty
              ? const Center(
                  child: Text(
                    "No family members found",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Column(
                  children: List.generate(familyMembers.length, (index) {
                    final member = familyMembers[index];

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,

                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF162544),
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          title: Text(
                            member.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            member.email,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRoleTag(member.role),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  _showDeleteDialog(member);
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (index != familyMembers.length - 1)
                          const Divider(color: Colors.white10),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(FamilyMember member) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161F33),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Remove User",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Are you sure you want to remove\n${member.name} from this device?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          final result = await deleteUserFromDevice(
                            deviceId: DeviceInformations.selectedDeviceId,
                            userId: member.id.toString(),
                          );

                          if (!mounted) return;

                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor:
                              result["success"] ? Colors.green : Colors.red,
                              content: Text(result["message"]),
                            ),
                          );

                          if (result["success"]) {
                            getFamilyMembers();
                          }
                        },
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF162544),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 9),
      ),
    );
  }

  Widget _buildInstallerAndSupport() {
    return const Padding(
      padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Text(
        "INSTALLER & SUPPORT",
        style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161F33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, "Home", false),
          _navItem(Icons.calendar_month_outlined, "Timer", false),
          _navItem(Icons.notifications_outlined, "Alert", false),
          _navItem(Icons.person_outline, "Profile", true),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF00B4D8) : Colors.grey),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00B4D8) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/DeviceInformations.dart';
import 'package:untitled/NotificationScreen.dart';
import 'package:untitled/assist/AssistScreen.dart';
import 'package:untitled/authentication/NewLoginScreen.dart';
import 'package:untitled/authentication/rest/APIService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../InternetService.dart';
import '../common_function/SnackBar.dart';
import '../invite/InviteDialog.dart';
import '../invite/SyncDevice.dart';
import '../pairdevice/ConnectScreen.dart';
import '../pairdevice/ConnectedScreen.dart';
import 'model/FamilyMember.dart';

class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({super.key});

  @override
  State<NewProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<NewProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _profileData = {};
  String name = "";
  String email = "";
  String userId = "";
  String firstLetter = "";
  String mobile = "";
  List<FamilyMember> familyMembers = [];
  bool isFamilyLoading = true;
  bool isLoading = false;
  String deviceId = DeviceInformations.selectedDeviceId;
  String installerName = "";
  String companyName = "";
  String installerEmail = "";
  String installerPhone = "";
  String licenceNo = "";
  bool isSettingEnable = false;
  bool _smartNotificationEnabled = false;
  bool _isLoadingSettings = true;
  bool _isUpdatingSetting = false;
  @override
  void initState() {
    super.initState();
    _fetchProfile();
    getFamilyMembers();
    getdeviceDetails();
    _fetchSettings();
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

  Future<void> getdeviceDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      String deviceId = DeviceInformations.selectedDeviceId;
      final response = await http.post(
        Uri.parse("https://aetherone.com.au/api/v1/deviceDetails"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {"device_id": deviceId},
      );

      print("STATUS : ${response.statusCode}");
      print("BODY : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          final installer = data["device"]["installer"];
          if (installer != null) {
            setState(() {
              installerName = installer["installer_name"] ?? "";
              companyName = installer["company_name"] ?? "";
              installerEmail = installer["email"] ?? "";
              installerPhone = installer["phone_number"] ?? "";
              licenceNo = installer["licence_no"] ?? "";
            });
          }
        });
      } else {
        setState(() {
          isFamilyLoading = false;
        });
      }
    } catch (e) {
      print("ERROR : $e");
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
      bool connected = await InternetService().hasInternet();

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No Internet Connection")),
        );
        return {
          "success": false,
          "message": "No Internet Connection",
        };
      }
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";

      final response = await http.delete(
        Uri.parse("https://aetherone.com.au/api/v1/deleteUserFromDevice"),
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
      bool connected = await InternetService().hasInternet();
      if (!connected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Internet Connection")));
        return;
      }
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
    }
  }

  Future<void> _fetchSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      final response = await http.get(
        Uri.parse('https://aetherone.com.au/api/v1/settings'),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['settings'] ?? data['data'];
        final String value = settings['smartNotification'] ?? 'No';

        setState(() {
          _smartNotificationEnabled = (value.toLowerCase() == 'yes');
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingSettings = false);
    }
  }

  // --- API 2: Update Setting Value ---
  Future<void> _toggleSmartNotification(bool newValue) async {
    setState(() {
      _smartNotificationEnabled = newValue;
      _isUpdatingSetting = true;
    });

    try {
      bool connected = await InternetService().hasInternet();

      if (!connected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Internet Connection")));
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? "";
      final response = await http.post(
        Uri.parse('https://aetherone.com.au/api/v1/settings'),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'smartNotification': newValue ? 'Yes' : 'No'}),
      );

      if (response.statusCode != 200) {
        // Revert on failure
        setState(() => _smartNotificationEnabled = !newValue);
      }
    } catch (e) {
      // Revert on network error
      setState(() => _smartNotificationEnabled = !newValue);
    } finally {
      setState(() => _isUpdatingSetting = false);
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
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
                  const Text(
                    "INSTALLER & SUPPORT",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  companyName.isNotEmpty
                      ? _buildInstallerAndSupport()
                      : _buildNoInstallerCard(),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child:
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132A4C),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A4B73), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "PREFERENCES",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color: _smartNotificationEnabled
                                          ? Colors.blue.withOpacity(.15)
                                          : Colors.grey.withOpacity(.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_active_outlined,
                                      color: _smartNotificationEnabled
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Smart Notifications",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Receive weather alerts and smart warnings.",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  _isUpdatingSetting
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : Switch(
                                    value: _smartNotificationEnabled,
                                    activeColor: Colors.blue,
                                    onChanged: (value) async {
                                      _toggleSmartNotification(value);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => showLogoutDialog(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF14213D),
                        side: BorderSide(
                          color: Colors.blueGrey.shade700,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                          : const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: Text(
                        _isLoading ? "" : "Sign out",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : moveConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39AEFB),
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
                  const SizedBox(height: 15),
                  if (deviceId.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool connected = await InternetService()
                              .hasInternet();

                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No Internet Connection"),
                              ),
                            );
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Syncdevice(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39AEFB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                          "Sync Device",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
                color: Color(0xFF39AEFB),
              ),
              label: const Text(
                "Invite",
                style: TextStyle(color: Color(0xFF39AEFB), fontSize: 12),
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
                              backgroundColor: result["success"]
                                  ? Colors.green
                                  : Colors.red,
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

  Future<void> showLogoutDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF162B45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Are you sure you want to logout from your account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    /// Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    /// Logout Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);

                          // TODO: Perform Logout
                          logout();
                        },
                        child: const Text(
                          "Logout",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildInstallerAndSupport() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF132A4C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A4B73), width: 1),
      ),
      child: Column(
        children: [
          ///==================== TOP ====================///
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2DB8FF), width: 1),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: Color(0xFF33C2FF),
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "Technician: $installerName",
                      style: const TextStyle(
                        color: Color(0xFFA2B3D1),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "AU-LIC $licenceNo",
                      style: const TextStyle(
                        color: Color(0xFF7484A3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ///==================== BUTTONS ====================///
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => makePhoneCall(installerPhone),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C665D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2D8E83)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Color(0xFF56F0AE),
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "CALL",
                                style: TextStyle(
                                  color: Color(0xFF62E6C5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                installerPhone,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => sendEmail(installerEmail),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A416D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2D8BD2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF38C7FF),
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "EMAIL",
                                style: TextStyle(
                                  color: Color(0xFF38C7FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                installerEmail,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoInstallerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162544),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.handyman_outlined, color: Colors.grey, size: 30),
          SizedBox(height: 10),
          Text(
            "No Installer Assigned",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "This device doesn't have an installer linked yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> makePhoneCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint("Could not launch $uri");
    }
  }

  Future<void> sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email application found.")),
      );
    }
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../model/AlertModel.dart';
import '../model/Device.dart';
import '../model/ThermostatData.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late Dio dio;

  String? _token; // 🔹 store token

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: "https://aetherone.com.au/api/v1/",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        followRedirects: true,
        validateStatus: (status) {
          return status != null && status < 600;
        },
      ),
    );

    // 🔥 Interceptor (like Retrofit)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers["Authorization"] = "Bearer $_token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  // 🔹 Set token after login
  void setToken(String token) {
    _token = token;
  }

  // 🔹 Clear token on logout
  void clearToken() {
    _token = null;
  }

  // 🔹 GET API
  Future<Response> get(String endpoint) async {
    return await dio.get(endpoint);
  }

  // 🔹 POST API
  Future<Response> post(String endpoint, dynamic data) async {
    return await dio.post(endpoint, data: data);
  }

  static Future<ThermostatData> getThermostat() async {
    final response = await http.get(
        Uri.parse("https://aether.com.au/api/v1/status"));

    if (response.statusCode == 200) {
      return ThermostatData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load data");
    }
  }

  static Future<void> updateTemperature(int temp) async {
    await http.post(
      Uri.parse("https://aether.com.au/api/v1/set-temp"),
      body: jsonEncode({"target_temp": temp}),
      headers: {"Content-Type": "application/json"},
    );
  }

  static Future<void> updateMode(String mode) async {
    await http.post(
      Uri.parse("https://aether.com.au/api/v1/set-mode"),
      body: jsonEncode({"mode": mode}),
      headers: {"Content-Type": "application/json"},
    );
  }

  Future<List<AlertModel>> fetchAlerts() async {
    final response = await http.get(Uri.parse("https://yourapi.com/alerts"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => AlertModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load alerts");
    }
  }

  Future<List<Device>> fetchDevices() async {
    // Replace with your real API
    await Future.delayed(const Duration(seconds: 1));

    final response = [
      {
        "name": "Alex Marsden",
        "address": "12 Linden Ave, Bondi NSW 2026",
        "model": "Aether Home 270L",
        "temperature": 51.4,
        "mode": "Comfort",
        "isOnline": true,
        "alerts": 1
      },
      {
        "name": "Priya Shah",
        "address": "4 Riverdale Rd, Brunswick VIC 3056",
        "model": "Aether Core 220L",
        "temperature": 47.8,
        "mode": "Eco",
        "isOnline": true,
        "alerts": 0
      },
      {
        "name": "Tom & Lisa Reid",
        "address": "78 Oak St, Paddington QLD 4064",
        "model": "Aether Max 320L",
        "temperature": 39.2,
        "mode": "Boost",
        "isOnline": false,
        "alerts": 2
      },
    ];

    return response.map((e) => Device.fromJson(e)).toList();
  }
}
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


  Future<List<AlertModel>> fetchAlerts() async {
    final response = await http.get(Uri.parse("https://yourapi.com/alerts"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => AlertModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load alerts");
    }
  }
}
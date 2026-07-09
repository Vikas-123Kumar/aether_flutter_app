import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();

  factory InternetService() => _instance;

  InternetService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternet() async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return await InternetConnection().hasInternetAccess;
  }

  Stream<bool> get internetStatus =>
      InternetConnection().onStatusChange.map(
            (status) => status == InternetStatus.connected,
      );
}
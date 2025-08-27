import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    String url;
    if (Platform.isAndroid) {
      url = "http://10.0.2.2:8002"; // Android emulator
    } else {
      url = "http://192.168.1.18:8002"; // Physical devices
    }
    debugPrint("Base URL: $url");
    return url;
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle; 
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();

  factory AppConfigService() {
    return _instance;
  }

  AppConfigService._internal();

  String? _openWeatherApiKey; 
  Future<void> loadConfig() async {
    try {
      final String envContent = await rootBundle.loadString('key.env');
      final List<String> lines = envContent.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty || line.trim().startsWith('#')) {
          continue;
        }
        final parts = line.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (key == 'OPENWEATHER_API_KEY') {
            _openWeatherApiKey = value;
          }
        }
      }
    }
    catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  String? get openWeatherApiKey => _openWeatherApiKey;
}
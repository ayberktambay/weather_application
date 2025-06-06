import 'dart:convert'; 
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:weather_application/model/current_weather_model.dart'; 
import 'package:weather_application/service/app_config_service.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String? _apiKey = AppConfigService().openWeatherApiKey;
  Future<CurrentWeatherModel?> getCurrentWeather(double lat,double lon,) async {
    CurrentWeatherModel? weatherData ;
    if (_apiKey == null) {
      if (kDebugMode) {
        print('Error: API Key is null. Cannot make API request.');
      }
      return weatherData;
    }
    final Uri url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {

         final Map<String, dynamic> responseData = json.decode(response.body);
          weatherData = CurrentWeatherModel.fromJson(responseData);
        if (kDebugMode) {
          print('Weather data fetched successfully for ${weatherData.name}: ${weatherData.main?.temp}°K');
        
        }
        return weatherData;
      }
      else {
        if (kDebugMode) {
          print('Failed to load weather data. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        
        return null;
      }
    } catch (e) {
      
      if (kDebugMode) {
        print('Error fetching weather data: $e');
      }
      return null;
    }
  }

   double? _convertKelvinToCelsius(num? kelvin) {
    if (kelvin == null) return null;
    return kelvin.toDouble() - 273.15;
  }
  double? getTemperatureCelsius(CurrentWeatherModel? model) {
    return _convertKelvinToCelsius(model?.main?.temp);
  }

  double? getFeelsLikeCelsius(CurrentWeatherModel? model) {
    return _convertKelvinToCelsius(model?.main?.feelsLike);
  }

  String? getWeatherDescription(CurrentWeatherModel? model) {
    return model?.weather?.isNotEmpty == true ? model!.weather![0].description : null;
  }

  String? getCityName(CurrentWeatherModel? model) {
    return model?.name;
  }

  String? getWeatherIconUrl(CurrentWeatherModel? model) {
    if (model?.weather?.isNotEmpty == true && model!.weather![0].icon != null) {
      return 'https://openweathermap.org/img/wn/${model.weather![0].icon}@2x.png';
    }
    return null;
  }

  double? getWindSpeed(CurrentWeatherModel? model) {
    return (model?.wind?.speed as num?)?.toDouble();
  }

  int? getHumidity(CurrentWeatherModel? model) {
    return (model?.main?.humidity)?.toInt();
  }
}
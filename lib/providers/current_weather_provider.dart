// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:weather_application/model/current_weather_model.dart';
// import 'package:weather_application/service/weather_service.dart';

// final currentWeatherProvider = FutureProvider.autoDispose.family<CurrentWeatherModel, LatLon>(
//   (ref, latLon) {
//     return WeatherApiService.getCurrentWeather(latLon.lat, latLon.lon);
//   },
// );


// class LatLon {
//   final num lat;
//   final num lon;

//   LatLon(this.lat, this.lon);
// }
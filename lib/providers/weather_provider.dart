import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/model/current_weather_model.dart';
import 'package:weather/model/city_model.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/service/app_config_service.dart';
import 'package:weather/constants/cities.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherState {
  final CurrentWeatherModel? weather;
  final bool isLoading;
  final String? errorMessage;
  final double lat;
  final double lon;
  final String locationName;

  final Map<String, dynamic> cityWeatherData;
  final int currentPage;
  final bool isLoadingMore;
  final String searchQuery;

  WeatherState({
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.lat = 41.0082,
    this.lon = 28.9784,
    this.locationName = 'Istanbul',
    this.cityWeatherData = const {},
    this.currentPage = 0,
    this.isLoadingMore = false,
    this.searchQuery = '',
  });

  WeatherState copyWith({
    CurrentWeatherModel? weather,
    bool? isLoading,
    String? errorMessage,
    double? lat,
    double? lon,
    String? locationName,
    Map<String, dynamic>? cityWeatherData,
    int? currentPage,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      locationName: locationName ?? this.locationName,
      cityWeatherData: cityWeatherData ?? this.cityWeatherData,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherApiService _weatherApiService;

  WeatherNotifier(this._weatherApiService) : super(WeatherState()) {
    fetchWeather(state.lat, state.lon);
    loadMoreCities(); // İlk sayfa yüklenir
  }

  Future<void> fetchWeather(double lat, double lon, {String? cityName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _weatherApiService.getCurrentWeather(lat, lon);
      final city = cityName ?? _weatherApiService.getCityName(data) ?? 'Unknown Location';

      state = state.copyWith(
        weather: data,
        lat: lat,
        lon: lon,
        locationName: city,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
    }
  }

Future<void> fetchCurrentLocationWeather(BuildContext context, WidgetRef ref) async {
  state = state.copyWith(isLoading: true, errorMessage: null, locationName: 'Current Location');
  final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationServiceEnabled) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Location services are disabled. Please enable them.',
    );
    await _showEnableLocationDialog(context);
    return;
  }

  // Handle location permission
  final hasPermission = await _handleLocationPermission();
  if (!hasPermission) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Location permission denied. Please allow access in app settings.',
    );
    return;
  }

  // Try to get current position and fetch weather
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    await fetchWeather(position.latitude, position.longitude);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Failed to get location: $e',
    );
  }
}

Future<void> _showEnableLocationDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Location Services Disabled"),
      content: const Text("Please enable location services in your device settings to fetch weather data."),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Geolocator.openLocationSettings();
          },
          child: const Text("Open Settings"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
      ],
    ),
  );
}


  Future<void> loadMoreCities() async {
    if (state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    final pageSize = 6;
    final start = state.currentPage * pageSize;
    final end = start + pageSize;

    final filteredCities = _filteredCities(state.searchQuery);
    final citiesToLoad = filteredCities.sublist(start, end > filteredCities.length ? filteredCities.length : end);

    final updatedData = Map<String, dynamic>.from(state.cityWeatherData);
    final String apiKey = AppConfigService().openWeatherApiKey!;

    for (var city in citiesToLoad) {
      if (updatedData.containsKey(city.name)) continue;

      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${city.latitude}&lon=${city.longitude}&appid=$apiKey&units=metric&lang=en';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        updatedData[city.name] = data;
      }
    }

    state = state.copyWith(
      cityWeatherData: updatedData,
      currentPage: state.currentPage + 1,
      isLoadingMore: false,
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 0,
      cityWeatherData: {},
    );
    loadMoreCities();
  }

  List<City> _filteredCities(String query) {
    final filtered = query.isEmpty
        ? cities
        : cities.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    return filtered;
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>(
  (ref) => WeatherNotifier(WeatherApiService()),
);

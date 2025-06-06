import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localization/localization.dart';
import 'package:weather_application/constants/cities.dart';
import 'package:weather_application/model/city_model.dart';
import 'package:weather_application/model/current_weather_model.dart';
import 'package:weather_application/service/weather_service.dart';
import 'package:weather_application/providers/theme_provider.dart';
import 'package:weather_application/view/utils/clock.dart';
import 'package:weather_application/view/utils/loader.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  CurrentWeatherModel? weatherModel;
  final WeatherApiService _weatherApiService = WeatherApiService();
  bool _isLoading = true;
  String? _errorMessage;

  double _currentLat = 41.0082;
  double _currentLon = 28.9784;
  String _currentLocationName = 'Istanbul';

  @override
  void initState() {
    super.initState();
    fetchData(_currentLat, _currentLon);
  }

  Future<void> _determinePositionAndFetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentLocationName = "Current Location";
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location permissions not granted.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      _currentLat = position.latitude;
      _currentLon = position.longitude;

      await fetchData(_currentLat, _currentLon);
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  Future<void> fetchData(double lat, double lon, {String? cityName}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _weatherApiService.getCurrentWeather(lat, lon);
      setState(() {
        weatherModel = data;
        _isLoading = false;
        if (weatherModel == null) {
          _errorMessage = 'Failed to load weather data.';
        } else {
          _currentLat = lat;
          _currentLon = lon;
          _currentLocationName = cityName ?? _weatherApiService.getCityName(weatherModel) ?? 'Unknown Location';

          if (weatherModel?.sys?.sunrise != null && weatherModel?.sys?.sunset != null) {
            ref.read(backgroundGradientProvider.notifier).setGradientBasedOnSunriseSunset(
              weatherModel!.sys!.sunrise!,
              weatherModel!.sys!.sunset!,
            );
          } else {
            ref.read(backgroundGradientProvider.notifier).updateGradientBasedOnCurrentTime();
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather data: $e';
        _isLoading = false;
      });
    }
  }

  void _onCitySelected(City selectedCity) {
    Navigator.of(context).pop();
    fetchData(selectedCity.latitude, selectedCity.longitude, cityName: selectedCity.name);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = ref.watch(backgroundGradientProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: currentGradient),
        child: _isLoading
            ? LoaderWidget()
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                : _buildWeatherDisplay(),
      ),
    );
  }

  Widget _buildWeatherDisplay() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    final String cityName = _weatherApiService.getCityName(weatherModel) ?? _currentLocationName;
    final num? tempCelsius = _weatherApiService.getTemperatureCelsius(weatherModel);
    final num? feelsLikeCelsius = _weatherApiService.getFeelsLikeCelsius(weatherModel);
    final String weatherDescription = _weatherApiService.getWeatherDescription(weatherModel) ?? 'N/A';
    final String? weatherIconUrl = _weatherApiService.getWeatherIconUrl(weatherModel);
    final num? windSpeed = _weatherApiService.getWindSpeed(weatherModel);
    final num? humidity = _weatherApiService.getHumidity(weatherModel);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const ClockWidget(), 
            const SizedBox(height: 10),
            Text(
              cityName,
              style: TextStyle(
                fontSize: isSmallScreen ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (weatherIconUrl != null)
              Image.network(
                weatherIconUrl,
                width: size.width * 0.3,
                height: size.width * 0.3,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.cloud, size: 120, color: Colors.white),
              ),
            Text(
              weatherDescription.i18n().toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tempCelsius != null ? '${tempCelsius.toStringAsFixed(0)}°C' : 'N/A',
              style: TextStyle(
                fontSize: isSmallScreen ? 60 : 80,
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
            ),
            if (feelsLikeCelsius != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${"Feels like".i18n()}: ${feelsLikeCelsius.toStringAsFixed(0)}°C',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildDetailRow(icon: Icons.air, label: 'Wind Speed'.i18n(), value: windSpeed != null ? '${windSpeed.toStringAsFixed(1)} m/s' : 'N/A'),
                  const Divider(color: Colors.white54),
                  _buildDetailRow(icon: Icons.opacity, label: 'Humidity'.i18n(), value: humidity != null ? '$humidity%' : 'N/A'),
                  const Divider(color: Colors.white54),
                  _buildDetailRow(icon: Icons.compress, label: 'Pressure'.i18n(), value: weatherModel?.main?.pressure != null ? '${weatherModel!.main!.pressure!.toInt()} hPa' : 'N/A'),
                  const Divider(color: Colors.white54),
                  _buildDetailRow(icon: Icons.location_on, label: 'Lat/Lon'.i18n(), value: '${_currentLat.toStringAsFixed(2)}, ${_currentLon.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

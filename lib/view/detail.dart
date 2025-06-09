import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:weather/utils/util_functions.dart';

class WeatherDetailView extends StatelessWidget {
  final String cityName;
  final num? tempCelsius;
  final num? feelsLikeCelsius;
  final String weatherDescription;
  final String? weatherIconCode;
  final num? windSpeed;
  final num? humidity;
  final num? pressure;
  final num? latitude;
  final num? longitude;

  const WeatherDetailView({
    super.key,
    required this.cityName,
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.weatherDescription,
    required this.weatherIconCode,
    required this.windSpeed,
    required this.humidity,
    required this.pressure,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF1A2A55),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(cityName.i18n(), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000020), Color(0xFF1A2A55), Color(0xFF334F8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             if (weatherIconCode != null)
                Image.asset(
                  UtilFunctions.getWeatherAssetPath(weatherIconCode.toString().replaceAll("n", "d")),
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 60, color: Colors.white),
                ),
              const SizedBox(height: 20),
              Text(
                '${tempCelsius?.round()}°C',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${"Feels like".i18n()} ${feelsLikeCelsius?.round()}°C',
                style: TextStyle(fontSize: 18, color: Colors.white.withAlpha(180)),
              ),
              const SizedBox(height: 12),
              Text(
                weatherDescription.i18n(),
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.white.withAlpha(100)),
              const SizedBox(height: 20),

              // Expanded for details to use vertical space evenly
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _infoRow(Icons.wind_power, 'Wind Speed'.i18n(), '${windSpeed ?? 'N/A'} m/s'),
                    const SizedBox(height: 12),
                    _infoRow(Icons.water_drop, 'Humidity'.i18n(), '${humidity?.round() ?? 'N/A'} %'),
                    const SizedBox(height: 12),
                    _infoRow(Icons.compress, 'Pressure'.i18n(), '${pressure?.round() ?? 'N/A'} hPa'),
                    const SizedBox(height: 12),
                    _infoRow(Icons.location_on, 'Latitude'.i18n(), '${latitude?.toStringAsFixed(2) ?? 'N/A'}'),
                    const SizedBox(height: 12),
                    _infoRow(Icons.location_on_outlined, 'Longitude'.i18n(), '${longitude?.toStringAsFixed(2) ?? 'N/A'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withAlpha(200)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(200)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

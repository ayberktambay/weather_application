import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:weather/model/current_weather_model.dart';
import 'package:weather/providers/weather_provider.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/providers/theme_provider.dart';
import 'package:weather/view/utils/clock.dart';
import 'package:weather/view/utils/loader.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  CurrentWeatherModel? weatherModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(weatherProvider.notifier).fetchCurrentLocationWeather(context,ref);
  });
  }

@override
Widget build(BuildContext context) {
  final weatherState = ref.watch(weatherProvider);
  final weatherModel = weatherState.weather;
  final currentGradient = ref.watch(backgroundGradientProvider);
  final screenSize = MediaQuery.of(context).size;

 if (weatherModel?.sys?.sunrise != null && weatherModel?.sys?.sunset != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(backgroundGradientProvider.notifier)
          .setGradientBasedOnSunriseSunset(
            weatherModel!.sys!.sunrise!,
            weatherModel.sys!.sunset!,
          );
    });
  }

  return Scaffold(
    extendBodyBehindAppBar: true,
    body: Container(
      height: screenSize.height,
      width: screenSize.width,
      decoration: BoxDecoration(gradient: currentGradient),
      child: weatherState.isLoading
          ? LoaderWidget()
          : weatherState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      weatherState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(weatherProvider.notifier).fetchCurrentLocationWeather(context,ref);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildWeatherDisplay(screenSize, weatherModel, weatherState),
                  ),
                ),
    ),
  );
}

Widget _buildWeatherDisplay(Size size, CurrentWeatherModel? weatherModel, WeatherState state) {
  final screenWidth = size.width;
  final isTablet = screenWidth > 600;
  final String cityName = state.locationName;
  final num? tempCelsius = WeatherApiService().getTemperatureCelsius(weatherModel);
  final num? feelsLikeCelsius = WeatherApiService().getFeelsLikeCelsius(weatherModel);
  final String weatherDescription = WeatherApiService().getWeatherDescription(weatherModel) ?? 'N/A';
  final String? weatherIconUrl = WeatherApiService().getWeatherIconUrl(weatherModel);
  final num? windSpeed = WeatherApiService().getWindSpeed(weatherModel);
  final num? humidity = WeatherApiService().getHumidity(weatherModel);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
    child: Column(
      children: [
        const SizedBox(height: kToolbarHeight),
        const ClockWidget(),
        const SizedBox(height: 10),
        Text(cityName, style: TextStyle(fontSize: isTablet ? 42 : 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        if (weatherIconUrl != null)
          Image.network(weatherIconUrl, width: isTablet ? 160 : screenWidth * 0.3),
        Text(weatherDescription.i18n().toUpperCase(), style: TextStyle(fontSize: isTablet ? 20 : 16, color: Colors.white)),
        const SizedBox(height: 20),
        Text(tempCelsius != null ? '${tempCelsius.toStringAsFixed(0)}°C' : 'N/A',
            style: TextStyle(fontSize: isTablet ? 100 : 80, fontWeight: FontWeight.w200, color: Colors.white)),
        if (feelsLikeCelsius != null)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withAlpha(40), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${"Feels like".i18n()}: ${feelsLikeCelsius.toStringAsFixed(0)}°C',
              style: TextStyle(fontSize: isTablet ? 20 : 16, color: Colors.white),
            ),
          ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: Colors.black.withAlpha(40), borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              _buildDetailRow(icon: Icons.air, label: 'Wind Speed'.i18n(), value: windSpeed != null ? '${windSpeed.toStringAsFixed(1)} m/s' : 'N/A'),
              const Divider(color: Colors.white54),
              _buildDetailRow(icon: Icons.opacity, label: 'Humidity'.i18n(), value: humidity != null ? '$humidity%' : 'N/A'),
              const Divider(color: Colors.white54),
              _buildDetailRow(icon: Icons.compress, label: 'Pressure'.i18n(), value: weatherModel?.main?.pressure != null ? '${weatherModel!.main!.pressure!.toInt()} hPa' : 'N/A'),
              const Divider(color: Colors.white54),
              _buildDetailRow(icon: Icons.location_on, label: 'Lat/Lon'.i18n(), value: '${state.lat.toStringAsFixed(2)}, ${state.lon.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
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

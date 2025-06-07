import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:weather/constants/text_styles.dart';
import 'package:weather/model/city_model.dart';
import 'package:weather/constants/cities.dart';
import 'package:http/http.dart' as http;
import 'package:weather/model/current_weather_model.dart';
import 'dart:convert';

import 'package:weather/service/app_config_service.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/view/detail.dart';
import 'package:weather/view/utils/loader.dart';

class CityWeatherSearchWidget extends StatefulWidget {
  const CityWeatherSearchWidget({super.key});

  @override
  State<CityWeatherSearchWidget> createState() =>
      _CityWeatherSearchWidgetState();
}

class _CityWeatherSearchWidgetState extends State<CityWeatherSearchWidget> {
  String query = '';
  Map<String, dynamic> weatherData = {};
  bool isLoading = false;
  bool isLoadingMore = false;
  int currentPage = 0;
  final int pageSize = 6;
  late ScrollController _scrollController;

  List<City> get _filteredCities {
    final filtered = query.isEmpty
        ? cities
        : cities
            .where((city) =>
                city.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return filtered.take((currentPage + 1) * pageSize).toList();
  }

  // Helper function to get asset path based on OpenWeatherMap icon code
  String _getWeatherAssetPath(String iconCode) {
    return 'assets/weather_icons/$iconCode.png';
  }

  Future<void> fetchWeatherForCities(List<City> citiesToFetch) async {
    final String apiKey = AppConfigService().openWeatherApiKey!;
    // Only fetch for cities that haven't been fetched yet
    final List<City> unfetchedCities = citiesToFetch
        .where((city) => !weatherData.containsKey(city.name))
        .toList();

    for (var city in unfetchedCities) {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${city.latitude}&lon=${city.longitude}&appid=$apiKey&units=metric&lang=en';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            weatherData[city.name] = data;
          });
        } else {
          // Handle API errors, e.g., log the error or show a message
          print('Failed to load weather for ${city.name}: ${response.statusCode}');
        }
      } catch (e) {
        // Handle network or parsing errors
        print('Error fetching weather for ${city.name}: $e');
      }
    }
  }

  void _loadMore() async {
    if (isLoadingMore || _scrollController.position.maxScrollExtent == _scrollController.position.pixels) {
      // Prevent multiple calls if already loading or at the very end
      return;
    }

    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchWeatherForCities(_filteredCities);
    setState(() => isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10) { // Adjusted threshold
      _loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    isLoading = true;
    fetchWeatherForCities(_filteredCities).then((_) {
      setState(() => isLoading = false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dW = MediaQuery.sizeOf(context).width;
    var dH = MediaQuery.sizeOf(context).height;
    final visibleCities = _filteredCities;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withAlpha(50)),
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(10)),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
               isDense: true,
              labelStyle: const TextStyle(color: Colors.white),
              labelText: 'Search city'.i18n(),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
            onChanged: (value) async {
              setState(() {
                query = value;
                currentPage = 0;
                weatherData.clear(); // Clear weather data for new search
              });
              // Fetch only visible cities after search
              await fetchWeatherForCities(_filteredCities);
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Color(0xFF000020),Color(0xFF1A2A55),Color(0xFF334F8C)]),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + dH*.05),
            if (isLoading)
              const Expanded( // Use Expanded to center loader
                child: Center(child: LoaderWidget()),
              )
            else
              Expanded( // Wrap GridView.builder with Expanded
                child: Column(
                  children: [
                    Expanded( // Ensure GridView takes available space
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          childAspectRatio: 1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 16,
                          maxCrossAxisExtent: dW / 2),
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: visibleCities.length,
                        itemBuilder: (context, index) {
                          final city = visibleCities[index];
                          final data = weatherData[city.name];
                          final String? weatherIconCode = data != null
                              ? data['weather'][0]['icon']
                              : null;

                          return GestureDetector(
                            onTap: () {
                              if (data != null) {
                          CurrentWeatherModel cwm = CurrentWeatherModel.fromJson(data);
                          Navigator.push(context,MaterialPageRoute(
                           builder: (_) => WeatherDetailView(
                            cityName: city.name,
                            tempCelsius: cwm.main!.temp!,
                            feelsLikeCelsius: cwm.main!.feelsLike,
                            weatherDescription: WeatherApiService().getWeatherDescription(cwm) ?? 'N/A',
                            weatherIconUrl: WeatherApiService().getWeatherIconUrl(cwm),
                            windSpeed: WeatherApiService().getWindSpeed(cwm),
                            humidity: WeatherApiService().getHumidity(cwm),
                            pressure: cwm.main?.pressure,
                            latitude: data['coord']['lat'],
                            longitude: data['coord']['lon'],
                          ),
                        ),);
                        }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                              color: Colors.white.withAlpha(60),
                              borderRadius: BorderRadius.circular(15)
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Use Image.asset if weatherIconCode is available
                                  if (weatherIconCode != null)
                                    Image.asset(
                                      _getWeatherAssetPath(weatherIconCode.toString().replaceAll("n", "d")),
                                      height: 100,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.cloud, size: 60, color: Colors.white),
                                    )
                                  else
                                    const CircularProgressIndicator(), // Show loading for icon
                                  if(data != null)
                                   Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(city.name.toString().i18n(), style: w600TS(15,Colors.white)),
                                        Container(
                                          margin: EdgeInsets.symmetric(vertical: dH*0.005),
                                          child: Text('${data['main']['temp'].round()}°C', style: w600TS(14,Colors.white))),
                                        Text(data['weather'][0]['description'].toString().i18n(), style: w400TS(14, Colors.white)),
                                      ],
                                    )
                                  else
                                  Text('Loading...'.i18n(), style: TextStyle(color: Colors.white.withAlpha(150)))

                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
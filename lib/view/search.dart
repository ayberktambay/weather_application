import 'package:flutter/material.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:localization/localization.dart';
import 'package:weather/constants/text_styles.dart';
import 'package:weather/model/city_model.dart';
import 'package:weather/constants/cities.dart';
import 'package:http/http.dart' as http;
import 'package:weather/model/current_weather_model.dart';
import 'dart:convert';

import 'package:weather/service/app_config_service.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/utils/util_functions.dart';
import 'package:weather/view/detail.dart';
import 'package:weather/view/utils/loader.dart';

class CityWeatherSearchWidget extends StatefulWidget {
  const CityWeatherSearchWidget({super.key});

  @override
  State<CityWeatherSearchWidget> createState() => _CityWeatherSearchWidgetState();
}

class _CityWeatherSearchWidgetState extends State<CityWeatherSearchWidget> {
  Map<String, dynamic> weatherData = {};
  final int pageSize = 6;
  late PagewiseLoadController<City> _pagewiseController;
  TextEditingController searchController = TextEditingController();
  bool isSearched = false;

  @override
  void initState() {
    super.initState();
    _pagewiseController = PagewiseLoadController<City>(
      pageSize: pageSize,
      pageFuture: _getPage,
    );
  }

  @override
  void dispose() {
    _pagewiseController.dispose();
    super.dispose();
  }

  Future<List<City>> _getPage(int? pageIndex) async {
    final allFiltered = searchController.text.isEmpty
        ? cities
        : cities.where((city) =>
            city.name.toLowerCase().contains(searchController.text.toLowerCase())).toList();

    final start = (pageIndex ?? 0) * pageSize;
    final end = (start + pageSize > allFiltered.length) ? allFiltered.length : start + pageSize;

    final pageCities = allFiltered.sublist(start, end);
    await fetchWeatherForCities(pageCities);
    return pageCities;
  }

  Future<void> fetchWeatherForCities(List<City> citiesToFetch) async {
    final String apiKey = AppConfigService().openWeatherApiKey!;
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
        }
      } catch (e) {
        print('Error fetching weather for ${city.name}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var dW = MediaQuery.sizeOf(context).width;
    var dH = MediaQuery.sizeOf(context).height;

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
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  controller: searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    labelStyle: const TextStyle(color: Colors.white),
                    labelText: 'Search city'.i18n(),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      weatherData.clear();
                      _pagewiseController.reset();
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  isSearched ? Icons.close : Icons.search,
                  size: 30,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (isSearched) {
                      searchController.clear();
                    }
                    weatherData.clear();
                    _pagewiseController.reset();
                    isSearched = !isSearched;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000020), Color(0xFF1A2A55), Color(0xFF334F8C)],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + dH * .05),
            
            Expanded(
              child: PagewiseGridView.count(
                pageLoadController: _pagewiseController,
                
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.all(8),
               itemBuilder: (context, city, index) {
  final cityData = weatherData[city.name];
  final weatherIconCode = cityData != null ? cityData['weather'][0]['icon'] : null;

  return GestureDetector(
    onTap: () {
      if (cityData != null) {
        final cwm = CurrentWeatherModel.fromJson(cityData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeatherDetailView(
              cityName: city.name,
              tempCelsius: cwm.main!.temp!,
              feelsLikeCelsius: cwm.main!.feelsLike,
              weatherDescription:
                  WeatherApiService().getWeatherDescription(cwm) ?? 'N/A',
              weatherIconCode: weatherIconCode,
              windSpeed: WeatherApiService().getWindSpeed(cwm),
              humidity: WeatherApiService().getHumidity(cwm),
              pressure: cwm.main?.pressure,
              latitude: cityData['coord']['lat'],
              longitude: cityData['coord']['lon'],
            ),
          ),
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withAlpha(40), Colors.white.withAlpha(20)],
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            UtilFunctions.getWeatherAssetPath(
              weatherIconCode?.replaceAll("n", "d") ?? "",
            ),
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.question_mark_rounded, size: 50, color: Colors.white),
          ),
          if (cityData != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(city.name.toString().i18n(), style: w600TS(13, Colors.white)),
                const SizedBox(height: 4),
                Text('${cityData['main']['temp'].round()}°C', style: w600TS(16, Colors.white)),
                const SizedBox(height: 2),
                Text(cityData['weather'][0]['description'].toString().i18n(), style: w500TS(13, Colors.white)),
              ],
            )
          else
            Text('Loading...'.i18n(), style: TextStyle(color: Colors.white.withAlpha(150))),
        ],
      ),
    ),
  );
},

              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  State<CityWeatherSearchWidget> createState() =>
      _CityWeatherSearchWidgetState();
}

class _CityWeatherSearchWidgetState extends State<CityWeatherSearchWidget> {
  Map<String, dynamic> weatherData = {};
  bool isLoading = false;
  bool isLoadingMore = false;
  int currentPage = 0;
  final int pageSize = 6;
  late ScrollController _scrollController;
late PagewiseLoadController<City> _pagewiseController;
  TextEditingController searchController = TextEditingController();
  List<City> get _filteredCities {
    final filtered = searchController.text.isEmpty
        ? cities
        : cities
            .where((city) =>
                city.name.toLowerCase().contains(searchController.text.toLowerCase()))
            .toList();
    return filtered.take((currentPage + 1) * pageSize).toList();
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
      return;
    }
    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchWeatherForCities(_filteredCities);
    setState(() => isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) { 
      _loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    isLoading = true;
    fetchWeatherForCities(_filteredCities).then((_) {
        isLoading = false;
        _loadMore();
      setState(() {});  
    });
    _pagewiseController = PagewiseLoadController<City>(
  pageSize: pageSize,
  pageFuture: _getPage,
);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
Future<List<City>> _getPage(int? pageIndex) async {
  final allFiltered = searchController.text.isEmpty
      ? cities
      : cities
          .where((city) => city.name.toLowerCase().contains(searchController.text.toLowerCase()))
          .toList();

  final start = (pageIndex ?? 0) * pageSize;
  final end = (start + pageSize > allFiltered.length) ? allFiltered.length : start + pageSize;

  final pageCities = allFiltered.sublist(start, end);
  await fetchWeatherForCities(pageCities);

  return pageCities;
}
bool isSearched = false;
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
        title:Container(
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
          onChanged: (value) {
            searchController.text = value; 
          },
          onSubmitted: (value) {
            setState(() {
              searchController.text = value;
              weatherData.clear();
              _pagewiseController.reset();
            });
          },
        ),
      ),
      IconButton(
        icon:  Icon(isSearched ? Icons.close : Icons.search,size: 30, color: Colors.white),
        onPressed: () {
          setState(() {
            if(isSearched){
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
          gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors: [Color(0xFF000020),Color(0xFF1A2A55),Color(0xFF334F8C)]),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + dH*.05),
            if (isLoading)
              const Expanded( 
                child: Center(child: LoaderWidget()),
              )
            else
              Expanded( 
                child: Column(
                  children: [
                 Expanded(
                   child: PagewiseGridView.count(
                    loadingBuilder: (context) {
                     return LoaderWidget();
                    },
                   pageLoadController: _pagewiseController,
                   crossAxisCount: (dW / 200).floor(), 
                   mainAxisSpacing: 8,
                   crossAxisSpacing: 16,
                   padding: const EdgeInsets.all(12),
                   itemBuilder: (context, city, index) {
                   final cityData = weatherData[city.name];
                   final weatherIconCode = cityData != null
                       ? cityData['weather'][0]['icon']
                       : null;
                   return GestureDetector(
                                              onTap: () {
                   if (cityData != null) {
                     final cwm = CurrentWeatherModel.fromJson(cityData);
                     Navigator.push(context, MaterialPageRoute(
                       builder: (_) => WeatherDetailView(
                         cityName: city.name,
                         tempCelsius: cwm.main!.temp!,
                         feelsLikeCelsius: cwm.main!.feelsLike,
                         weatherDescription: WeatherApiService().getWeatherDescription(cwm) ?? 'N/A',
                         weatherIconCode: weatherIconCode,
                         windSpeed: WeatherApiService().getWindSpeed(cwm),
                         humidity: WeatherApiService().getHumidity(cwm),
                         pressure: cwm.main?.pressure,
                         latitude: cityData['coord']['lat'],
                         longitude: cityData['coord']['lon'],
                       ),
                     ));
                   }
                                              },
                                              child: Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(15),
                     gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.white.withAlpha(40),Colors.white.withAlpha(20)]
                      ),
                   ),
                   margin: const EdgeInsets.only(bottom: 12),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                   
                         Image.asset(
                         UtilFunctions.getWeatherAssetPath(weatherIconCode.toString().replaceAll("n", "d")),
                         height: 50,
                         fit: BoxFit.contain,
                         errorBuilder: (_, __, ___) => const Icon(Icons.question_mark_rounded, size: 50, color: Colors.white),
                         ),
                       if (cityData != null)
                         Column(
                                       crossAxisAlignment: CrossAxisAlignment.center,
                                       children: [
                                         Text(city.name.toString().i18n(), style: w600TS(16, Colors.white)),
                                         Container(
                                           margin: EdgeInsets.symmetric(vertical: dH * 0.005),
                                           child: Text('${cityData['main']['temp'].round()}°C', style: w600TS(18, Colors.white)),
                                         ),
                                         Text(cityData['weather'][0]['description'].toString().i18n(), style: w500TS(16, Colors.white)),
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
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(
                          color: Colors.red,
                          backgroundColor: Colors.white,
                        )),
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
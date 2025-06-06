import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:weather_application/model/city_model.dart';
import 'package:weather_application/constants/cities.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weather_application/service/app_config_service.dart';
import 'package:weather_application/view/utils/loader.dart';

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

  Future<void> fetchWeatherForCities(List<City> citiesToFetch) async {
    final String apiKey = AppConfigService().openWeatherApiKey!;
    for (var city in citiesToFetch) {
      if (weatherData.containsKey(city.name)) continue;

      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${city.latitude}&lon=${city.longitude}&appid=$apiKey&units=metric&lang=en';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weatherData[city.name] = data;
        });
      }
    }
  }

  void _loadMore() async {
    if (isLoadingMore) return;

    setState(() => isLoadingMore = true);
    currentPage++;
    await fetchWeatherForCities(_filteredCities);
    setState(() => isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
                weatherData.clear();
              });
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
            SizedBox(height: kToolbarHeight+20),
            if (isLoading)
              LoaderWidget()
            else
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: dW / 2,
                    mainAxisSpacing:  16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: visibleCities.length,
                  itemBuilder: (context, index) {
                    final city = visibleCities[index];
                    final data = weatherData[city.name];
                    final weatherIconUrl = data != null
                        ? 'https://openweathermap.org/img/wn/${data['weather'][0]['icon']}@2x.png'
                        : null;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(60),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(100)),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (weatherIconUrl != null)
                            Image.network(
                              weatherIconUrl,
                              width:  60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.cloud,
                                      size: 30, color: Colors.white),
                            ),
                          const SizedBox(height: 4),
                          Text(city.name.toString().i18n(),
                              style: const TextStyle(
                                fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          if (data != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                 Text(
                                  '${data['main']['temp'].round()}°C ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 13),
                                ),
                                Text(
                                  data['weather'][0]['description'].toString().i18n(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 12),
                                ),
                               
                              ],
                            ),
                          if (data == null)
                            Text(
                              'Loading...'.i18n(),
                              style: TextStyle(
                                  color: Colors.white.withAlpha(150)),
                            ),
                        ],
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
    );
  }
}

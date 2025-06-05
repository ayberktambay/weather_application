import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:weather_application/constants/cities.dart';
import 'package:weather_application/model/city_model.dart';
import 'package:weather_application/model/current_weather_model.dart';
import 'package:weather_application/service/weather_service.dart';
import 'package:weather_application/providers/theme_provider.dart'; 

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

      await fetchData(_currentLat, _currentLon); // Call fetchData with new coordinates
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar(
          'Location services are disabled. Please enable the services.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar(
          'Location permissions are permanently denied, we cannot request permissions. Please enable from app settings.');
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
          _errorMessage = 'Failed to load weather data for coordinates ($lat, $lon).';
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = ref.watch(backgroundGradientProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  backgroundColor: Colors.black.withOpacity(0.3), // Better contrast for white icons
  elevation: 0,
  title: Text(
    "Weather App",
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      letterSpacing: 0.5,
      shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
    ),
  ),
  actionsIconTheme: const IconThemeData(
    color: Colors.white,
    size: 24,
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
  actions: [
    Tooltip(
      message: 'Use Current Location',
      child: IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: () async {
          await _determinePositionAndFetchWeather();
        },
      ),
    ),
    Tooltip(
      message: 'Search for a City',
      child: IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          showSearch(
            context: context,
            delegate: CitySearchDelegate(_onCitySelected),
          );
        },
      ),
    ),
    Tooltip(
      message: 'Refresh Weather',
      child: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => fetchData(_currentLat, _currentLon, cityName: _currentLocationName),
      ),
    ),
  ],
),
      body: Container(
        decoration: BoxDecoration(
          gradient: currentGradient
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                : weatherModel == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No weather data available. Tap refresh or search for a city.',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _determinePositionAndFetchWeather,
                              icon: const Icon(Icons.location_on),
                              label: const Text('Get My Location Weather'),
                            ),
                          ],
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
          SizedBox(height: kToolbarHeight + 20),
          Text(
            cityName,
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(blurRadius: 5, color: Colors.black38, offset: Offset(2, 2)),
              ],
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
            weatherDescription.toUpperCase(),
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tempCelsius != null ? '${tempCelsius.toStringAsFixed(0)}°C' : 'N/A',
            style: TextStyle(
              fontSize: isSmallScreen ? 60 : 80,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              shadows: const [
                Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(3, 3)),
              ],
            ),
          ),
          if (feelsLikeCelsius != null)
            Text(
              'Feels like: ${feelsLikeCelsius.toStringAsFixed(0)}°C',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
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
                _buildDetailRow(
                  icon: Icons.air,
                  label: 'Wind Speed',
                  value: windSpeed != null ? '${windSpeed.toStringAsFixed(1)} m/s' : 'N/A',
                ),
                const Divider(color: Colors.white54),
                _buildDetailRow(
                  icon: Icons.opacity,
                  label: 'Humidity',
                  value: humidity != null ? '$humidity%' : 'N/A',
                ),
                const Divider(color: Colors.white54),
                _buildDetailRow(
                  icon: Icons.compress,
                  label: 'Pressure',
                  value: weatherModel?.main?.pressure != null
                      ? '${weatherModel!.main!.pressure!.toInt()} hPa'
                      : 'N/A',
                ),
                const Divider(color: Colors.white54),
                _buildDetailRow(
                  icon: Icons.location_on,
                  label: 'Lat/Lon',
                  value: '${_currentLat.toStringAsFixed(2)}, ${_currentLon.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
  }

 Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );
  }
}

// Your existing CitySearchDelegate and City model remains the same
// --- CitySearchDelegate ---
class CitySearchDelegate extends SearchDelegate<City?> {
  final Function(City) onCitySelected;

  CitySearchDelegate(this.onCitySelected);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<City> searchResults = cities
        .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final City city = searchResults[index];
        return ListTile(
          title: Text(city.name),
          subtitle: Text('Lat: ${city.latitude.toStringAsFixed(2)}, Lon: ${city.longitude.toStringAsFixed(2)}'),
          onTap: () {
            onCitySelected(city);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<City> suggestionList = query.isEmpty
        ? cities
        : cities
            .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final City city = suggestionList[index];
        return ListTile(
          title: Text(city.name),
          subtitle: Text('Lat: ${city.latitude.toStringAsFixed(2)}, Lon: ${city.longitude.toStringAsFixed(2)}'),
          onTap: () {
            query = city.name;
            showResults(context);
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late WeatherFactory _wf;
  
  Map<String, dynamic>? _offlineCurrent;
  List<Map<String, dynamic>> _offlineForecast = [];
  
  Weather? _currentWeather;
  List<Weather> _forecast = [];
  bool _isLoading = true;
  bool _isOffline = false;

  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";
  final String _city = "Layyah,PK";

  @override
  void initState() {
    super.initState();
    _wf = WeatherFactory(_apiKey, language: Language.ENGLISH);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Weather current = await _wf.currentWeatherByCityName(_city);
      List<Weather> forecast = await _wf.fiveDayForecastByCityName(_city);

      List<Weather> filteredForecast = [];
      Set<String> uniqueDays = {};
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var w in forecast) {
        if (w.date != null) {
          String dayKey = DateFormat('yyyy-MM-dd').format(w.date!);
          if (!uniqueDays.contains(dayKey) && dayKey != todayKey) {
            uniqueDays.add(dayKey);
            filteredForecast.add(w);
          }
        }
      }

      setState(() {
        _currentWeather = current;
        _forecast = filteredForecast;
        _isOffline = false;
        _isLoading = false;
      });

      Map<String, dynamic> currentCache = {
        'temp': current.temperature?.celsius?.toStringAsFixed(0) ?? '--',
        'desc': current.weatherDescription ?? 'Clear',
        'icon': current.weatherIcon ?? '01d',
        'humidity': current.humidity?.toString() ?? '0',
        'wind': (current.windSpeed != null ? (current.windSpeed! * 3.6).toStringAsFixed(1) : '0.0'),
        'clouds': current.cloudiness?.toString() ?? '0',
      };
      await prefs.setString('cache_current_data', jsonEncode(currentCache));

      List<Map<String, dynamic>> forecastCache = filteredForecast.map((w) {
        return {
          'day': w.date != null ? DateFormat('EEEE').format(w.date!) : 'Day',
          'tempMax': w.tempMax?.celsius?.toStringAsFixed(0) ?? '--',
          'tempMin': w.tempMin?.celsius?.toStringAsFixed(0) ?? '--',
          'icon': w.weatherIcon ?? '01d',
        };
      }).toList();
      await prefs.setString('cache_forecast_data', jsonEncode(forecastCache));

    } catch (e) {
      debugPrint("Weather Main Error: $e. Loading safe offline data...");
      
      final String? cachedCurrentStr = prefs.getString('cache_current_data');
      final String? cachedForecastStr = prefs.getString('cache_forecast_data');

      if (cachedCurrentStr != null && cachedForecastStr != null) {
        setState(() {
          _offlineCurrent = jsonDecode(cachedCurrentStr);
          final List<dynamic> decodedList = jsonDecode(cachedForecastStr);
          _offlineForecast = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
          _isOffline = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
    }
  }

  // Sahi visual icons nikalne k liye smart function jo internet k bina b perfect chalta ha
  Widget _getWeatherIcon(String? iconCode, {required double size}) {
    if (iconCode == null) {
      return Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: size);
    }
    
    IconData iconData;
    Color iconColor;
    
    // Icon codes ko check karne ka clean system (01d, 02n, etc.)
    String code = iconCode.replaceAll('d', '').replaceAll('n', '');
    bool isNight = iconCode.contains('n');
    
    switch (code) {
      case '01': // Clear sky / Saaf Mausam
        iconData = isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded;
        iconColor = isNight ? Colors.indigo.shade100 : Colors.amber;
        break;
      case '02': // Few clouds / Halke Badal
        iconData = isNight ? Icons.cloudy_snowing : Icons.wb_cloudy_rounded;
        iconColor = isNight ? Colors.blueGrey.shade200 : Colors.lightBlue.shade300;
        break;
      case '03': // Scattered clouds
      case '04': // Broken clouds / Gehray Badal
        iconData = Icons.cloud_rounded;
        iconColor = Colors.blue.shade400; // Bright colorful cloud instead of dark/black
        break;
      case '09': // Shower rain
      case '10': // Rain / Barish
        iconData = Icons.beach_access_rounded;
        iconColor = Colors.blue.shade700; // Deep water drop blue
        break;
      case '11': // Thunderstorm / Toofan
        iconData = Icons.thunderstorm_rounded;
        iconColor = Colors.orangeAccent;
        break;
      case '13': // Snow / Barf
        iconData = Icons.ac_unit_rounded;
        iconColor = Colors.cyan.shade300;
        break;
      case '50': // Mist / Dhund
        iconData = Icons.waves_rounded;
        iconColor = Colors.teal.shade300;
        break;
      default:
        iconData = Icons.wb_sunny_rounded;
        iconColor = Colors.amber;
    }

    // Agar app offline ho to network image load krne ki koshish b na kro, aur bright local icons dikhao!
    if (_isOffline) {
      Color adjustedColor = iconColor;
      
      // White card (Next Days Forecast) par white icons chup na jayein, isliye use bright vivid colors!
      if (size < 40) {
        if (iconColor == Colors.white || iconColor == Colors.white70 || iconColor == Colors.blueGrey.shade200) {
          adjustedColor = Colors.blue.shade400; // Glowing blue clouds on white background
        } else if (iconColor == Colors.amber) {
          adjustedColor = Colors.orange.shade700; // Warm amber sun on white background
        }
      }
      return Icon(iconData, color: adjustedColor, size: size);
    }

    // Online hone par openweather se high-res image load karo, crash hone par errorBuilder local colourful icon show karega
    return Image.network(
      "https://openweathermap.org/img/wn/$iconCode${size > 40 ? '@4x' : ''}.png",
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        Color adjustedColor = iconColor;
        if (size < 40) {
          if (iconColor == Colors.white || iconColor == Colors.white70 || iconColor == Colors.blueGrey.shade200) {
            adjustedColor = Colors.blue.shade400;
          } else if (iconColor == Colors.amber) {
            adjustedColor = Colors.orange.shade700;
          }
        }
        return Icon(iconData, color: adjustedColor, size: size);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFBC02D),
              Color(0xFF388E3C),
              Color(0xFF1B5E20),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                  onRefresh: _fetchWeatherData,
                  color: const Color(0xFF388E3C),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildAppBar(context),
                        const SizedBox(height: 10),
                        _buildTodayWeatherCard(),
                        const SizedBox(height: 30),
                        _buildForecastSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const Text("Mausam ki Tafseel",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          if (_isOffline) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Offline Mode",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayWeatherCard() {
    final String temp = _isOffline 
        ? "${_offlineCurrent?['temp'] ?? '--'}°C" 
        : (_currentWeather?.temperature?.celsius != null ? "${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°C" : "--°C");
        
    final String description = _isOffline 
        ? (_offlineCurrent?['desc'] ?? "Clear").toUpperCase() 
        : (_currentWeather?.weatherDescription?.toUpperCase() ?? "CLEAR");

    String? iconCode;
    if (_isOffline) {
      iconCode = _offlineCurrent != null ? _offlineCurrent!['icon'] : null;
    } else {
      iconCode = _currentWeather?.weatherIcon;
    }

    final String humidity = _isOffline ? "${_offlineCurrent?['humidity'] ?? 0}%" : "${_currentWeather?.humidity ?? 0}%";
    final String wind = _isOffline ? "${_offlineCurrent?['wind'] ?? 0.0} km/h" : "${_currentWeather?.windSpeed != null ? (_currentWeather!.windSpeed! * 3.6).toStringAsFixed(1) : 0.0} km/h";
    final String clouds = _isOffline ? "${_offlineCurrent?['clouds'] ?? 0}%" : "${_currentWeather?.cloudiness ?? 0}%";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                    Text(temp, style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)),
                    Text(description, style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                height: 80,
                child: _getWeatherIcon(iconCode, size: 65), // Custom error-free offline mapper used here
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Divider(color: Colors.white24),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherDetailItem(Icons.water_drop, humidity, "Humidity"),
              _weatherDetailItem(Icons.air, wind, "Wind"),
              _weatherDetailItem(Icons.cloud_outlined, clouds, "Clouds"),
            ],
          )
        ],
      ),
    );
  }

  Widget _weatherDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildForecastSection() {
    bool hasData = _isOffline ? _offlineForecast.isNotEmpty : _forecast.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Next Days Forecast",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("No forecast available offline.", style: TextStyle(color: Colors.black54)),
            )
          else if (_isOffline)
            ..._offlineForecast.map((w) => _forecastRow(
                  w['day'] ?? "Day",
                  "${w['tempMax']}° / ${w['tempMin']}°",
                  w['icon'] ?? "01d",
                )).toList()
          else
            ..._forecast.map((w) => _forecastRow(
                  w.date != null ? DateFormat('EEEE').format(w.date!) : "Day",
                  w.tempMax?.celsius != null && w.tempMin?.celsius != null
                      ? "${w.tempMax!.celsius!.toStringAsFixed(0)}° / ${w.tempMin!.celsius!.toStringAsFixed(0)}°"
                      : "--° / --°",
                  w.weatherIcon ?? "01d",
                )).toList(),
        ],
      ),
    );
  }

  Widget _forecastRow(String day, String temp, String iconCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: _getWeatherIcon(iconCode, size: 30), // Sahi offline mapper row me lag gaya
            ),
          ),
          Expanded(
            child: Text(temp,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
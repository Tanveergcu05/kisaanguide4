import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late WeatherFactory _wf;
  Weather? _currentWeather;
  List<Weather> _forecast = [];
  bool _isLoading = true;

  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";
  final String _city = "Layyah,PK";

  @override
  void initState() {
    super.initState();
    _wf = WeatherFactory(_apiKey);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      Weather current = await _wf.currentWeatherByCityName(_city);
      List<Weather> forecast = await _wf.fiveDayForecastByCityName(_city);

      setState(() {
        _currentWeather = current;
        _forecast = forecast.where((w) => w.date!.hour >= 11 && w.date!.hour <= 13).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Weather Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Overflow se bachne ke liye background Scaffold par hi gradient set kiya
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Full screen height
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
                        const SizedBox(height: 30), // Extra space bottom ke liye
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
        ],
      ),
    );
  }

  Widget _buildTodayWeatherCard() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                  Text("${_currentWeather?.temperature?.celsius?.toStringAsFixed(0)}°C",
                      style: const TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.bold)),
                  Text(_currentWeather?.weatherDescription?.toUpperCase() ?? "Clear",
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              if (_currentWeather?.weatherIcon != null)
                Image.network("https://openweathermap.org/img/wn/${_currentWeather!.weatherIcon}@4x.png", width: 80)
              else
                const Icon(Icons.wb_sunny_rounded, color: Colors.yellowAccent, size: 80),
            ],
          ),
          const SizedBox(height: 25),
          const Divider(color: Colors.white24),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherDetailItem(Icons.water_drop, "${_currentWeather?.humidity}%", "Humidity"),
              _weatherDetailItem(Icons.air, "${_currentWeather?.windSpeed?.toStringAsFixed(1)} km/h", "Wind"),
              _weatherDetailItem(Icons.cloud_outlined, "${_currentWeather?.cloudiness}%", "Clouds"),
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
          ..._forecast.map((w) => _forecastRow(
                DateFormat('EEEE').format(w.date!),
                "${w.tempMax?.celsius?.toStringAsFixed(0)}° / ${w.tempMin?.celsius?.toStringAsFixed(0)}°",
                w.weatherIcon!,
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
            child: Image.network("https://openweathermap.org/img/wn/$iconCode.png", width: 35),
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
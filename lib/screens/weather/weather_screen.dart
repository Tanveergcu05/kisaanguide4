import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/config/app_config.dart';

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

  final String _apiKey = AppConfig.openWeatherApiKey;
  final String _city = AppConfig.defaultWeatherCity;

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
    final String cityLabel = _city.replaceAll(',PK', '');
    final String temp = _isOffline
        ? "${_offlineCurrent?['temp'] ?? '--'}°"
        : (_currentWeather?.temperature?.celsius != null
            ? "${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°"
            : "--°");

    final String feelsLike = _isOffline
        ? "--"
        : (_currentWeather?.tempFeelsLike?.celsius != null
            ? "${_currentWeather!.tempFeelsLike!.celsius!.toStringAsFixed(0)}°"
            : "--");

    final String description = _isOffline
        ? (_offlineCurrent?['desc'] ?? "Clear").toString()
        : (_currentWeather?.weatherDescription ?? "Clear");

    final String humidity = _isOffline ? "${_offlineCurrent?['humidity'] ?? 0}%" : "${_currentWeather?.humidity ?? 0}%";
    final String wind = _isOffline
        ? "${_offlineCurrent?['wind'] ?? 0.0} km/h"
        : "${_currentWeather?.windSpeed != null ? (_currentWeather!.windSpeed! * 3.6).toStringAsFixed(1) : 0.0} km/h";

    String? iconCode = _isOffline ? (_offlineCurrent != null ? _offlineCurrent!['icon'] : null) : _currentWeather?.weatherIcon;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWeatherData,
              color: Colors.white,
              backgroundColor: const Color(0xFF0B6FFF),
              child: Stack(
                children: [
                  const _SkyBackground(),
                  // Bottom illustration
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 220,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _HillsPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      children: [
                        // Top bar (share + menu)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _roundIconButton(
                              icon: Icons.ios_share_rounded,
                              onTap: () => Navigator.maybePop(context),
                            ),
                            _roundIconButton(
                              icon: Icons.more_horiz_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            cityLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Weather hero (icon + temp)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 76,
                              height: 76,
                              child: Center(child: _getWeatherIcon(iconCode, size: 64)),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  temp,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Feels $feelsLike",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            description.toUpperCase(),
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              "Make the most of this nice weather.\nAaj ka mausam behtareen hai — apni fasal ka kaam plan karein.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_isOffline) ...[
                          _playfulBanner(
                            icon: Icons.cloud_off_rounded,
                            text: "Offline mode: cached data is shown",
                            tint: const Color(0xFFFFD54F),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Quick stats chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statChip(icon: Icons.water_drop_rounded, label: "Humidity", value: humidity),
                            const SizedBox(width: 10),
                            _statChip(icon: Icons.air_rounded, label: "Wind", value: wind),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _forecastStrip(iconCode),
                        const SizedBox(height: 200), // keep space above hills illustration
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            "$label ",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _playfulBanner({required IconData icon, required String text, required Color tint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastStrip(String? iconCode) {
    final bool hasData = _isOffline ? _offlineForecast.isNotEmpty : _forecast.isNotEmpty;
    if (!hasData) return const SizedBox.shrink();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _isOffline ? _offlineForecast.length : _forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          String day;
          String hi;
          String lo;
          String icon;
          if (_isOffline) {
            final w = _offlineForecast[index];
            day = (w['day'] ?? "Day").toString().substring(0, 3);
            hi = "${w['tempMax'] ?? '--'}°";
            lo = "${w['tempMin'] ?? '--'}°";
            icon = (w['icon'] ?? "01d").toString();
          } else {
            final w = _forecast[index];
            day = w.date != null ? DateFormat('EEE').format(w.date!) : "Day";
            hi = w.tempMax?.celsius != null ? "${w.tempMax!.celsius!.toStringAsFixed(0)}°" : "--°";
            lo = w.tempMin?.celsius != null ? "${w.tempMin!.celsius!.toStringAsFixed(0)}°" : "--°";
            icon = w.weatherIcon ?? "01d";
          }

          return Container(
            width: 92,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _getWeatherIcon(icon, size: 18),
                    const SizedBox(width: 6),
                    Text(hi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Text(lo, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SkyBackground extends StatelessWidget {
  const _SkyBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B6FFF),
            Color(0xFF178BFF),
            Color(0xFF1FA0FF),
          ],
        ),
      ),
      child: Stack(
        children: const [
          // soft clouds
          _CloudBlob(top: 80, left: 30, scale: 1.0, opacity: 0.18),
          _CloudBlob(top: 140, right: 20, scale: 1.2, opacity: 0.16),
          _CloudBlob(top: 210, left: 70, scale: 0.9, opacity: 0.14),
          _CloudBlob(top: 260, right: 80, scale: 0.95, opacity: 0.12),
        ],
      ),
    );
  }
}

class _CloudBlob extends StatelessWidget {
  final double top;
  final double? left;
  final double? right;
  final double scale;
  final double opacity;

  const _CloudBlob({
    required this.top,
    this.left,
    this.right,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 150,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Positioned(
                  left: 58,
                  bottom: 28,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBack = Paint()..color = const Color(0xFF39D67E);
    final paintFront = Paint()..color = const Color(0xFF1EC16E);
    final paintGround = Paint()..color = const Color(0xFF16A85D);

    final pathBack = Path()
      ..moveTo(0, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.38, size.width * 0.55, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.72, size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathBack, paintBack);

    final pathFront = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.55, size.width * 0.46, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.74, size.height * 0.90, size.width, size.height * 0.66)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathFront, paintFront);

    final pathGround = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.70, size.width * 0.60, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.86, size.height, size.width, size.height * 0.82)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathGround, paintGround);

    // simple trees
    _drawTree(canvas, const Offset(50, 160));
    _drawTree(canvas, const Offset(92, 172), scale: 0.9);
    _drawTree(canvas, const Offset(size.width - 70, 168), scale: 0.95);
    _drawTree(canvas, const Offset(size.width - 110, 182), scale: 0.85);
  }

  void _drawTree(Canvas canvas, Offset base, {double scale = 1.0}) {
    final trunk = Paint()..color = const Color(0xFF7A4A2A);
    final leaf1 = Paint()..color = const Color(0xFF0F7A44);
    final leaf2 = Paint()..color = const Color(0xFF14A85D);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx, base.dy, 10 * scale, 22 * scale),
        const Radius.circular(4),
      ),
      trunk,
    );

    final p1 = Path()
      ..moveTo(base.dx - 14 * scale, base.dy + 6 * scale)
      ..lineTo(base.dx + 5 * scale, base.dy - 30 * scale)
      ..lineTo(base.dx + 24 * scale, base.dy + 6 * scale)
      ..close();
    canvas.drawPath(p1, leaf1);

    final p2 = Path()
      ..moveTo(base.dx - 10 * scale, base.dy - 4 * scale)
      ..lineTo(base.dx + 5 * scale, base.dy - 44 * scale)
      ..lineTo(base.dx + 20 * scale, base.dy - 4 * scale)
      ..close();
    canvas.drawPath(p2, leaf2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

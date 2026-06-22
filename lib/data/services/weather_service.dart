import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/config/app_config.dart';

class WeatherScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final bool isUrdu;
  const WeatherScreen({super.key, this.onMenuPressed, this.isUrdu = false});

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
  int _selectedForecastIndex = -1; // -1 means actual current weather, >=0 means a forecast day

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
        'feelsLike': current.tempFeelsLike?.celsius?.toStringAsFixed(0) ?? '--',
      };
      await prefs.setString('cache_current_data', jsonEncode(currentCache));

      List<Map<String, dynamic>> forecastCache = filteredForecast.map((w) {
        return {
          'day': w.date != null ? DateFormat('EEEE').format(w.date!) : 'Day',
          'tempMax': w.tempMax?.celsius?.toStringAsFixed(0) ?? '--',
          'tempMin': w.tempMin?.celsius?.toStringAsFixed(0) ?? '--',
          'temp': w.temperature?.celsius?.toStringAsFixed(0) ?? w.tempMax?.celsius?.toStringAsFixed(0) ?? '--',
          'icon': w.weatherIcon ?? '01d',
          'desc': w.weatherDescription ?? 'Clear',
          'humidity': w.humidity?.toString() ?? '60',
          'wind': (w.windSpeed != null ? (w.windSpeed! * 3.6).toStringAsFixed(1) : '10.0'),
          'clouds': w.cloudiness?.toString() ?? '10',
          'feelsLike': w.tempFeelsLike?.celsius?.toStringAsFixed(0) ?? w.temperature?.celsius?.toStringAsFixed(0) ?? '--',
          'formattedDate': w.date != null ? DateFormat('dd MMM, yyyy').format(w.date!) : '',
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

  // Bilingual translation mapper for weather status descriptions
  String _translateCondition(String desc) {
    if (!widget.isUrdu) return desc.toUpperCase();
    final lowercase = desc.toLowerCase();
    if (lowercase.contains('clear') || lowercase.contains('sunny')) return "صاف اور سہانا آسمان";
    if (lowercase.contains('cloud')) {
      if (lowercase.contains('few') || lowercase.contains('scattered')) return "ہلکے اور بکھرے بادل";
      return "گہرے ابر آلود بادل";
    }
    if (lowercase.contains('rain') || lowercase.contains('drizzle')) return "ہلکی بارش اور بوندہ باندی";
    if (lowercase.contains('thunderstorm')) return "گرج چمک کے ساتھ شدید طوفان";
    if (lowercase.contains('snow')) return "برف باری کا امکان";
    if (lowercase.contains('mist') || lowercase.contains('fog') || lowercase.contains('haze')) return "دھند (کم بصارت کی وارننگ)";
    return desc;
  }

  // Translate days of the week beautifully for agricultural forecast panels
  String _translateDay(String englishDay) {
    if (!widget.isUrdu) return englishDay;
    final dayLower = englishDay.toLowerCase();
    Map<String, String> dayNames = {
      'monday': 'پیر', 'mon': 'پیر',
      'tuesday': 'منگل', 'tue': 'منگل',
      'wednesday': 'بدھ', 'wed': 'بدھ',
      'thursday': 'جمعرات', 'thu': 'جمعرات',
      'friday': 'جمعہ', 'fri': 'جمعہ',
      'saturday': 'ہفتہ', 'sat': 'ہفتہ',
      'sunday': 'اتوار', 'sun': 'اتوار'
    };
    return dayNames[dayLower] ?? englishDay;
  }

  // Dynamic weatherproof ag-recommender
  Widget _buildSmartAgAdvisory(String desc, double humidityVal, double windSpeedVal) {
    String advisoryTitle = widget.isUrdu ? "فصل کے لیے خصوصی زرعی مشورہ" : "Smart Agricultural Advisory";
    String advisoryDeets = "";
    IconData advisoryIcon = Icons.agriculture_rounded;
    Color advisoryColor = const Color(0xFFAC3400); // Earth Terracotta

    final lowercase = desc.toLowerCase();
    if (lowercase.contains('rain') || lowercase.contains('drizzle') || lowercase.contains('storm')) {
      advisoryDeets = widget.isUrdu
          ? "بارش کا امکان ہے! پودوں پر کیمیائی سپرے اور کھاد ڈالنے کا کام روک دیں۔ باغات میں اضافی پانی نکالنے کے راستے کھلے رکھیں۔"
          : "Rain expected! Postpone pesticide spray and solid fertilizer setups. Ensure orchard soil gullies are cleared of blockages.";
      advisoryIcon = Icons.umbrella_rounded;
    } else if (windSpeedVal > 15) {
      advisoryDeets = widget.isUrdu
          ? "ہوا کی رفتار قدرے زیادہ ہے (${windSpeedVal.toStringAsFixed(1)} km/h)۔ اس موسم میں سپرے کرنے سے گریز کریں تاکہ زہر ضائع نہ ہو۔"
          : "Breezy conditions detected (${windSpeedVal.toStringAsFixed(1)} km/h). Avoid spraying today to prevent chemical drift.";
      advisoryIcon = Icons.air_rounded;
    } else if (humidityVal > 80) {
      advisoryDeets = widget.isUrdu
          ? "ہوا میں نمی زیادہ ہے (${humidityVal.toStringAsFixed(0)}%)۔ باغات میں فنگس (پھپھوندی) کے حملے کا خطرہ ہے۔ باقاعدگی سے نگرانی کریں۔"
          : "High humidity (${humidityVal.toStringAsFixed(0)}%). Increases fungal disease pressure. Inspect orchard tree leaves regularly.";
      advisoryIcon = Icons.bug_report_rounded;
    } else if (lowercase.contains('clear') || lowercase.contains('sunny')) {
      advisoryDeets = widget.isUrdu
          ? "آج دھوپ اور صاف موسم ہے۔ پودوں کو وقت پر پانی دینے اور باغات میں صفائی ستھرائی شروع کرنے کا بہترین موقع ہے۔"
          : "Sunny and clear! Perfect window for scheduled tree irrigation, manual weed control, and general orchard maintenance.";
      advisoryIcon = Icons.wb_sunny_rounded;
    } else {
      advisoryDeets = widget.isUrdu
          ? "موسم معتدل رہے گا۔ اپنی زمین کی نمی کی جانچ کریں اور پودوں کی ضرورت کے مطابق معمول کی دیکھ بھال جاری رکھیں۔"
          : "Stable weather conditions. Keep checking soil moisture and proceed with regular protective ag operations.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF003527).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: advisoryColor.withValues(alpha: 0.40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: advisoryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(advisoryIcon, color: advisoryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advisoryTitle,
                  style: TextStyle(
                    color: advisoryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  advisoryDeets,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Returns weather-appropriate icons
  Widget _getWeatherIcon(String? iconCode, {required double size}) {
    if (iconCode == null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: size * 0.4,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.wb_sunny_rounded, color: Colors.amber.shade400, size: size),
      );
    }
    
    String code = iconCode.replaceAll('d', '').replaceAll('n', '');
    bool isNight = iconCode.contains('n');
    
    switch (code) {
      case '01': // Clear sky / Sunny
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isNight ? Colors.indigoAccent : Colors.orangeAccent).withValues(alpha: 0.4),
                    blurRadius: size * 0.4,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            Icon(
              isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
              color: isNight ? Colors.indigo.shade100 : Colors.amber.shade400,
              size: size,
            ),
          ],
        );

      case '02': // Few clouds
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                color: isNight ? Colors.indigo.shade200 : Colors.amber.shade400,
                size: size * 0.7,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 4,
              child: Icon(
                Icons.cloud_rounded,
                color: Colors.white,
                size: size * 0.75,
              ),
            ),
          ],
        );

      case '03': // Scattered clouds
      case '04': // Broken/Heavy clouds
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              right: 2,
              child: Icon(
                Icons.cloud_rounded,
                color: Colors.blue.shade200.withValues(alpha: 0.6),
                size: size * 0.8,
              ),
            ),
            Positioned(
              top: 0,
              left: 2,
              child: Icon(
                Icons.cloud_rounded,
                color: Colors.cyan.shade300,
                size: size * 0.82,
              ),
            ),
          ],
        );

      case '09': // Shower rain
      case '10': // Rain
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.cloud_rounded,
              color: Colors.blue.shade300,
              size: size * 0.85,
            ),
            Positioned(
              bottom: -2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, color: Colors.cyanAccent.shade400, size: size * 0.32),
                  const SizedBox(width: 2),
                  Icon(Icons.water_drop_rounded, color: Colors.cyanAccent.shade400, size: size * 0.32),
                ],
              ),
            ),
          ],
        );

      case '11': // Thunderstorm
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.cloud_rounded,
              color: Colors.indigo.shade300,
              size: size * 0.88,
            ),
            Positioned(
              bottom: -size * 0.15,
              child: Icon(
                Icons.flash_on_rounded,
                color: Colors.yellowAccent,
                size: size * 0.58,
              ),
            ),
          ],
        );

      case '13': // Snow
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.cloud_rounded,
              color: Colors.cyan.shade200,
              size: size * 0.85,
            ),
            Positioned(
              bottom: 0,
              child: Icon(
                Icons.ac_unit_rounded,
                color: Colors.white,
                size: size * 0.38,
              ),
            ),
          ],
        );

      case '50': // Mist / Fog
        return Icon(
          Icons.waves_rounded,
          color: Colors.teal.shade300,
          size: size,
        );

      default:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: size * 0.4,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.wb_sunny_rounded, color: Colors.amber.shade400, size: size),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String cityLabel = widget.isUrdu ? "لیہ، پاکستان" : _city.replaceAll(',PK', '');
    
    final bool isViewingForecast = _selectedForecastIndex >= 0;

    // Date computation
    String displayDate;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          displayDate = _offlineForecast[_selectedForecastIndex]['formattedDate'] ?? '';
        } else {
          displayDate = '';
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          final w = _forecast[_selectedForecastIndex];
          displayDate = w.date != null ? DateFormat('dd MMM, yyyy').format(w.date!) : '';
        } else {
          displayDate = '';
        }
      }
    } else {
      displayDate = DateFormat('dd MMM, yyyy').format(DateTime.now());
    }

    // Day or Temp Title computation
    String targetDayName = "";
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          targetDayName = _translateDay((_offlineForecast[_selectedForecastIndex]['day'] ?? "Day").toString());
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          final w = _forecast[_selectedForecastIndex];
          targetDayName = _translateDay(w.date != null ? DateFormat('EEEE').format(w.date!) : "Day");
        }
      }
    }
    final String tempTitle = isViewingForecast
        ? (widget.isUrdu ? "$targetDayName کا درجہ حرارت" : "$targetDayName Temp")
        : (widget.isUrdu ? "درجہ حرارت" : "Current Temp");

    // Temperature
    final String temp;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          final w = _offlineForecast[_selectedForecastIndex];
          temp = "${w['temp'] ?? w['tempMax'] ?? '--'}°C";
        } else {
          temp = "--°C";
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          final w = _forecast[_selectedForecastIndex];
          final fTemp = w.temperature?.celsius ?? w.tempMax?.celsius;
          temp = fTemp != null ? "${fTemp.toStringAsFixed(0)}°C" : "--°C";
        } else {
          temp = "--°C";
        }
      }
    } else {
      temp = _isOffline
          ? "${_offlineCurrent?['temp'] ?? '--'}°C"
          : (_currentWeather?.temperature?.celsius != null
              ? "${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°C"
              : "--°C");
    }

    final double rawTempNum;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          rawTempNum = double.tryParse(_offlineForecast[_selectedForecastIndex]['temp']?.toString() ?? '') ?? 30.0;
        } else {
          rawTempNum = 30.0;
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          rawTempNum = _forecast[_selectedForecastIndex].temperature?.celsius ?? _forecast[_selectedForecastIndex].tempMax?.celsius ?? 30.0;
        } else {
          rawTempNum = 30.0;
        }
      }
    } else {
      rawTempNum = _isOffline
          ? double.tryParse(_offlineCurrent?['temp']?.toString() ?? '') ?? 30.0
          : (_currentWeather?.temperature?.celsius ?? 30.0);
    }

    // Feels Like
    final String feelsLike;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          feelsLike = "${_offlineForecast[_selectedForecastIndex]['feelsLike'] ?? '--'}°C";
        } else {
          feelsLike = "--°C";
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          final w = _forecast[_selectedForecastIndex];
          final fFeels = w.tempFeelsLike?.celsius ?? w.temperature?.celsius ?? w.tempMax?.celsius;
          feelsLike = fFeels != null ? "${fFeels.toStringAsFixed(0)}°C" : "--°C";
        } else {
          feelsLike = "--°C";
        }
      }
    } else {
      feelsLike = _isOffline
          ? "${_offlineCurrent?['feelsLike'] ?? '--'}°C"
          : (_currentWeather?.tempFeelsLike?.celsius != null
              ? "${_currentWeather!.tempFeelsLike!.celsius!.toStringAsFixed(0)}°C"
              : "--°C");
    }

    // Condition Description
    final String description;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          description = (_offlineForecast[_selectedForecastIndex]['desc'] ?? "Clear").toString();
        } else {
          description = "Clear";
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          description = _forecast[_selectedForecastIndex].weatherDescription ?? "Clear";
        } else {
          description = "Clear";
        }
      }
    } else {
      description = _isOffline
          ? (_offlineCurrent?['desc'] ?? "Clear").toString()
          : (_currentWeather?.weatherDescription ?? "Clear");
    }

    // Relative Air Humidity
    final String humidity;
    final double rawHumidityNum;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          humidity = "${_offlineForecast[_selectedForecastIndex]['humidity'] ?? 0}%";
          rawHumidityNum = double.tryParse(_offlineForecast[_selectedForecastIndex]['humidity']?.toString() ?? '') ?? 60.0;
        } else {
          humidity = "0%";
          rawHumidityNum = 60.0;
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          humidity = "${_forecast[_selectedForecastIndex].humidity ?? 0}%";
          rawHumidityNum = (_forecast[_selectedForecastIndex].humidity ?? 60.0).toDouble();
        } else {
          humidity = "0%";
          rawHumidityNum = 60.0;
        }
      }
    } else {
      humidity = _isOffline ? "${_offlineCurrent?['humidity'] ?? 0}%" : "${_currentWeather?.humidity ?? 0}%";
      rawHumidityNum = _isOffline
          ? double.tryParse(_offlineCurrent?['humidity']?.toString() ?? '') ?? 60.0
          : (_currentWeather?.humidity ?? 60.0).toDouble();
    }

    // Wind Speed
    final String wind;
    final double rawWindNum;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          wind = "${_offlineForecast[_selectedForecastIndex]['wind'] ?? 0.0} km/h";
          rawWindNum = double.tryParse(_offlineForecast[_selectedForecastIndex]['wind']?.toString() ?? '') ?? 10.0;
        } else {
          wind = "0.0 km/h";
          rawWindNum = 10.0;
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          final w = _forecast[_selectedForecastIndex];
          wind = "${w.windSpeed != null ? (w.windSpeed! * 3.6).toStringAsFixed(1) : 0.0} km/h";
          rawWindNum = w.windSpeed != null ? (w.windSpeed! * 3.6) : 10.0;
        } else {
          wind = "0.0 km/h";
          rawWindNum = 10.0;
        }
      }
    } else {
      wind = _isOffline
          ? "${_offlineCurrent?['wind'] ?? 0.0} km/h"
          : "${_currentWeather?.windSpeed != null ? (_currentWeather!.windSpeed! * 3.6).toStringAsFixed(1) : 0.0} km/h";
      rawWindNum = _isOffline
          ? double.tryParse(_offlineCurrent?['wind']?.toString() ?? '') ?? 10.0
          : (_currentWeather?.windSpeed != null ? (_currentWeather!.windSpeed! * 3.6) : 10.0);
    }

    // Cloudiness
    final String clouds;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          clouds = "${_offlineForecast[_selectedForecastIndex]['clouds'] ?? 0}%";
        } else {
          clouds = "0%";
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          clouds = "${_forecast[_selectedForecastIndex].cloudiness ?? 0}%";
        } else {
          clouds = "0%";
        }
      }
    } else {
      clouds = _isOffline ? "${_offlineCurrent?['clouds'] ?? 0}%" : "${_currentWeather?.cloudiness ?? 0}%";
    }

    // Weather Icon Code
    String? iconCode;
    if (isViewingForecast) {
      if (_isOffline) {
        if (_selectedForecastIndex < _offlineForecast.length) {
          iconCode = _offlineForecast[_selectedForecastIndex]['icon'];
        }
      } else {
        if (_selectedForecastIndex < _forecast.length) {
          iconCode = _forecast[_selectedForecastIndex].weatherIcon;
        }
      }
    } else {
      iconCode = _isOffline ? (_offlineCurrent != null ? _offlineCurrent!['icon'] : null) : _currentWeather?.weatherIcon;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchWeatherData,
              color: Colors.white,
              backgroundColor: const Color(0xFF003527),
              child: Stack(
                children: [
                  // Sleek, high-contrast dark forest background matching Dashboard style
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF003527),
                          Color(0xFF002219),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      children: [
                        // Custom Interactive Header matching the App UX System
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.onMenuPressed != null)
                              GestureDetector(
                                onTap: widget.onMenuPressed,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                  ),
                                  child: const Icon(Icons.menu_open_rounded, color: Colors.white, size: 24),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFAC3400).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFAC3400).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                widget.isUrdu ? "موسمی اسٹیشن" : "AGRI-WEATHER STATION",
                                style: const TextStyle(
                                  color: Color(0xFFFBC02D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Location Display Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFAC3400), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              cityLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (isViewingForecast) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedForecastIndex = -1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAC3400),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.today_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.isUrdu ? "آج کا موسم دکھائیں" : "Show Today's Weather",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        // VIP Sleek Glassmorphism Interactive Hero Weather Block
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
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
                                        Text(
                                          tempTitle,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          temp,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 54,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _translateCondition(description),
                                          style: const TextStyle(
                                            color: Color(0xFFFBC02D),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                         ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: Center(child: _getWeatherIcon(iconCode, size: 85)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${widget.isUrdu ? 'محسوس درجہ حرارت' : 'Feels like'} $feelsLike",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 30, thickness: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isUrdu ? "فارمنگ ونڈو کھلی ہے" : "Safe Spray Window Active",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    displayDate,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_isOffline) ...[
                          _playfulBanner(
                            icon: Icons.cloud_off_rounded,
                            text: widget.isUrdu 
                                ? "آف لائن موڈ: محفوظ شدہ ڈیٹا دکھایا جا رہا ہے"
                                : "Offline Mode: displaying cached data",
                            tint: const Color(0xFFFBC02D),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // 5-Day Forecast Translucent Slider Panel (Moved directly below the main weather display elements)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isUrdu ? "آئندہ 5 دنوں کی پیشگوئی" : "5-Day Agronomic Forecast",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _forecastStrip(),
                        const SizedBox(height: 24),

                        // VIP Dynamic Soil-Ag Bento Dashboard Grid
                        Text(
                          widget.isUrdu ? "مٹی اور ماحولیاتی پیرا میٹرز" : "Soil & Atmosphere parameters",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            _bentoGridCard(
                              icon: Icons.water_drop_rounded,
                              label: widget.isUrdu ? "فضا میں نمی" : "Air Humidity",
                              value: humidity,
                              subtext: widget.isUrdu 
                                  ? (rawHumidityNum > 70 ? "زیادہ (کیڑے کا خطرہ)" : "نارمل")
                                  : (rawHumidityNum > 70 ? "High (Pest threat)" : "Optimal"),
                              iconColor: Colors.blueAccent,
                            ),
                            _bentoGridCard(
                              icon: Icons.wind_power_rounded,
                              label: widget.isUrdu ? "ہوا کی رفتار" : "Wind Speed",
                              value: wind,
                              subtext: widget.isUrdu 
                                  ? (rawWindNum > 15 ? "تیز ہوا (سپرے مت کریں)" : "محفوظ")
                                  : (rawWindNum > 15 ? "Strong (Delay spray)" : "Safe to Spray"),
                              iconColor: const Color(0xFFAC3400),
                            ),
                            _bentoGridCard(
                              icon: Icons.wb_sunny_outlined,
                              label: widget.isUrdu ? "بادلوں کی کثافت" : "Cloud Cover",
                              value: clouds,
                              subtext: widget.isUrdu 
                                  ? (clouds.contains('0%') ? "مکمل دھوپ" : "جزوی ابر آلود")
                                  : (clouds.contains('0%') ? "Full Sunshine" : "Partly Cloudy"),
                              iconColor: Colors.amberAccent,
                            ),
                            _bentoGridCard(
                              icon: Icons.thermostat_rounded,
                              label: widget.isUrdu ? "محسوس درجہ حرارت" : "Real Feel",
                              value: feelsLike,
                              subtext: widget.isUrdu ? "مٹی کا درجہ حرارت باثوق" : "Reliable soil correlation",
                              iconColor: Colors.redAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // VIP Terracotta-framed Agricultural smart advisory
                        _buildSmartAgAdvisory(description, rawHumidityNum, rawWindNum),
                        const SizedBox(height: 100), // comfortable viewport padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _playfulBanner({required IconData icon, required String text, required Color tint}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF003527).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoGridCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white24, size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastStrip() {
    final bool hasData = _isOffline ? _offlineForecast.isNotEmpty : _forecast.isNotEmpty;
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text("No forecast data", style: TextStyle(color: Colors.white70)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _isOffline ? _offlineForecast.length : _forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          String day;
          String hi;
          String lo;
          String icon;
          if (_isOffline) {
            final w = _offlineForecast[index];
            day = _translateDay((w['day'] ?? "Day").toString().substring(0, 3));
            hi = "${w['tempMax'] ?? '--'}°";
            lo = "${w['tempMin'] ?? '--'}°";
            icon = (w['icon'] ?? "01d").toString();
          } else {
            final w = _forecast[index];
            day = _translateDay(w.date != null ? DateFormat('EEE').format(w.date!) : "Day");
            hi = w.tempMax?.celsius != null ? "${w.tempMax!.celsius!.toStringAsFixed(0)}°" : "--°";
            lo = w.tempMin?.celsius != null ? "${w.tempMin!.celsius!.toStringAsFixed(0)}°" : "--°";
            icon = w.weatherIcon ?? "01d";
          }

          final bool isSelected = _selectedForecastIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedForecastIndex = index;
              });
            },
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected
                      ? [
                          const Color(0xFFAC3400).withValues(alpha: 0.35),
                          const Color(0xFFAC3400).withValues(alpha: 0.12),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFAC3400) : Colors.white.withValues(alpha: 0.14),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFAC3400).withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFBC02D) : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(child: _getWeatherIcon(icon, size: 28)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hi,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lo,
                        style: TextStyle(
                          color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

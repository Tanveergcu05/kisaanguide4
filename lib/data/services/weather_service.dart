import 'package:weather/weather.dart';
import '../../core/config/app_config.dart';

class MyWeatherService {
  final String _apiKey = AppConfig.openWeatherApiKey;
  late WeatherFactory _wf;

  MyWeatherService() {
    _wf = WeatherFactory(_apiKey);
  }

  Future<Weather?> getLayyahWeather() async {
    try {
      return await _wf.currentWeatherByCityName(AppConfig.defaultWeatherCity);
    } catch (e) {
      return null;
    }
  }
}
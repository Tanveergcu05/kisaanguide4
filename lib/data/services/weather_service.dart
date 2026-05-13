import 'package:weather/weather.dart';

class MyWeatherService {
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";
  late WeatherFactory _wf;

  MyWeatherService() {
    _wf = WeatherFactory(_apiKey);
  }

  Future<Weather?> getLayyahWeather() async {
    try {
      return await _wf.currentWeatherByCityName("Layyah,PK");
    } catch (e) {
      return null;
    }
  }
}
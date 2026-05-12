import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:weather/weather.dart'; // Weather package add kiya

// In paths ko apni app ke mutabiq check kar lein
import '../../weather/screens/weather_screen.dart'; 
import '../../orchard/screens/orchard_details_screen.dart'; 
import '../../crops/screens/add_crop_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 0;

  // --- Screens List ---
  final List<Widget> _screens = [
    const HomeContent(),           // Index 0: Home
    const WeatherScreen(),        // Index 1: Weather
    const OrchardDetailsScreen(), // Index 2: Baghaat
    const AddCropScreen(),        // Index 3: Fasal
  ];

  final List<IconData> iconList = [
    Icons.grid_view_rounded,
    Icons.wb_cloudy_outlined,
    Icons.park_rounded,
    Icons.assignment_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
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
          ),
          IndexedStack(
            index: _bottomNavIndex,
            children: _screens,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 8,
        backgroundColor: const Color(0xFFFBC02D),
        onPressed: () {},
        child: const Icon(Icons.add, color: Color(0xFF1B5E20), size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        backgroundColor: Colors.white,
        activeColor: const Color(0xFF2E7D32),
        inactiveColor: Colors.grey.shade400,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }
}

// --- HomeContent Widget (Ab Live Weather ke sath) ---
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Weather Variables
  Weather? _weather;
  bool _isLoading = true;
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6"; // Aapki API Key

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
  }

  void _fetchLiveWeather() async {
    try {
      WeatherFactory wf = WeatherFactory(_apiKey);
      Weather w = await wf.currentWeatherByCityName("Layyah,PK");
      setState(() {
        _weather = w;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Home Weather Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchLiveWeather(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainWeatherCard(),
                    const Padding(
                      padding: EdgeInsets.only(left: 25, top: 30, bottom: 15),
                      child: Text(
                        "Important Updates", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 22,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 10)]
                        ),
                      ),
                    ),
                    _buildNotificationSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.person_rounded, color: Color(0xFF2E7D32), size: 30),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("ID: KG-9901", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Layyah, Pakistan", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  Text(
                    "${_weather?.temperature?.celsius?.toStringAsFixed(0) ?? "36"}°C", 
                    style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    _weather?.weatherDescription?.toUpperCase() ?? "CLEAR SKY", 
                    style: const TextStyle(color: Colors.white, fontSize: 16)
                  ),
                ],
              ),
              Column(
                children: [
                  if (_weather?.weatherIcon != null)
                    Image.network(
                      "https://openweathermap.org/img/wn/${_weather!.weatherIcon}@2x.png",
                      width: 80,
                    )
                  else
                    const Icon(Icons.wb_sunny_rounded, color: Colors.yellowAccent, size: 80),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Advisory & Alerts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          const SizedBox(height: 20),
          _updateRow(Icons.warning_amber_rounded, "Weather Alert", "High temperature expected in Layyah.", Colors.orange),
          const Divider(height: 30),
          _updateRow(Icons.eco, "Crop Advisory", "Best time to sow Sehar-2022 variety.", Colors.green),
          const Divider(height: 30),
          _updateRow(Icons.water_drop, "Irrigation", "Next watering cycle starts tomorrow.", Colors.blue),
        ],
      ),
    );
  }

  Widget _updateRow(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
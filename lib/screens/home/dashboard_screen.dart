import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:weather/weather.dart';

// Sahi paths ensure karein
import '../../screens/weather/weather_screen.dart'; 
import '../../screens/crops/orchard_details_screen.dart'; 
import '../../screens/crops/add_crop_screen.dart'; 
import '../../data/models/expense_tracker/screens/expense_main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),           
    const WeatherScreen(),         
    const OrchardDetailsScreen(),  
    const AddCropScreen(),         
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseMainScreen()),
          );
        },
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

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Weather? _weather;
  bool _isLoading = true;
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6"; 

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
  }

  void _fetchLiveWeather() async {
    try {
      WeatherFactory wf = WeatherFactory(_apiKey);
      Weather w = await wf.currentWeatherByCityName("Layyah,PK");
      if (mounted) {
        setState(() {
          _weather = w;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          Expanded( // Header row ko wrap kiya taake ID/Location overflow na karein
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded( // Column ko expanded kiya taake lambay naam screen ke andar rahein
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "ID: KG-9901", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Layyah, Pakistan", 
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_active, color: Colors.white),
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
      ),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // Weather details ko expanded kiya taake bara text icon ko push na kare
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today", style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text(
                      "${_weather?.temperature?.celsius?.toStringAsFixed(0) ?? "36"}°C", 
                      style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      _weather?.weatherDescription?.toUpperCase() ?? "CLEAR SKY", 
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.wb_sunny_rounded, color: Colors.yellowAccent, size: 80),
            ],
          ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        children: [
          const Text(
            "Advisory & Alerts", 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
          ),
          const SizedBox(height: 15),
          _updateRow(Icons.warning_amber_rounded, "Weather Alert", "High temperature.", Colors.orange),
          const Divider(),
          _updateRow(Icons.eco, "Crop Advisory", "Sowing season started.", Colors.green),
        ],
      ),
    );
  }

  Widget _updateRow(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 15),
        Expanded( // Alert text ko expanded kiya taake right overflow na ho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub, 
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
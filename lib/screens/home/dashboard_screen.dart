import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:weather/weather.dart';
import 'dart:math' as math;

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

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  
  // VIP Sidebar Animation Controls
  late AnimationController _sidebarAnimationController;
  bool _isSidebarOpen = false;
  
  // Global Language Configuration (Default: Urdu)
  bool _isUrdu = true;

  final List<IconData> iconList = [
    Icons.grid_view_rounded,
    Icons.wb_cloudy_outlined,
    Icons.park_rounded,
    Icons.assignment_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeContent(onMenuPressed: _toggleSidebar, isUrdu: _isUrdu),           
      const WeatherScreen(),         
      const OrchardDetailsScreen(),  
      AddCropScreen(isUrdu: _isUrdu), // FIXED: Passed the language parameter here
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Background color for sidebar reveal
      body: Stack(
        children: [
          // VIP 1. SIDEBAR BACKGROUND LAYER (Piche wala menu)
          _buildVIPSidebarMenu(),

          // VIP 2. MAIN APP CONTENT LAYER WITH 3D TRANSFORM ANIMATION
          AnimatedBuilder(
            animation: _sidebarAnimationController,
            builder: (context, child) {
              // Mathematical matrix computations for 3D scale and side fluid drift
              double slideValue = _sidebarAnimationController.value * 260.0;
              double scaleValue = 1.0 - (_sidebarAnimationController.value * 0.18);
              double rotateValue = _sidebarAnimationController.value * (-math.pi / 24);

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slideValue, _sidebarAnimationController.value * 30)
                  ..scale(scaleValue)
                  ..setEntry(3, 2, 0.001) // Adds depth matrix perception
                  ..rotateY(rotateValue),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isSidebarOpen ? 35 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: _isSidebarOpen
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 5,
                                offset: const Offset(-10, 10),
                              )
                            ]
                          : [],
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Scaffold(
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
                    children: screens,
                  ),
                  // If sidebar is open, intercept touches on content to tap-to-close
                  if (_isSidebarOpen)
                    GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(
                        color: Colors.transparent,
                      ),
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
                onTap: (index) {
                  if (_isSidebarOpen) _toggleSidebar();
                  setState(() => _bottomNavIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // VIP Custom Sidebar Layout Builder
  Widget _buildVIPSidebarMenu() {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // User Meta Data Brand Block
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBC02D),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, color: Color(0xFF1B5E20), size: 35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isUrdu ? "تانجیر بھائی" : "Tanveer Bhai",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "ID: KG-9901",
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Sidebar Menu Items Navigation Configurations
            _buildSidebarTile(Icons.grid_view_rounded, _isUrdu ? "ڈیش بورڈ" : "Dashboard", 0),
            _buildSidebarTile(Icons.wb_cloudy_outlined, _isUrdu ? "موسم کی تفصیل" : "Weather Info", 1),
            _buildSidebarTile(Icons.park_rounded, _isUrdu ? "باغات کی تفصیل" : "Orchard Details", 2),
            _buildSidebarTile(Icons.assignment_outlined, _isUrdu ? "فصلوں کی گائیڈ" : "Crops Management", 3),

            const Spacer(),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 20),

            // GLOBAL DYNAMIC PREMIUM LANGUAGE SWITCHER SWITCH TILE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.g_translate_rounded, color: Color(0xFFFBC02D), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _isUrdu ? "اردو زبان" : "English",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isUrdu,
                    activeColor: const Color(0xFFFBC02D),
                    activeTrackColor: Colors.white24,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.black26,
                    onChanged: (value) {
                      setState(() {
                        _isUrdu = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // LOGOUT BUTTON IMPLEMENTATION
            InkWell(
              onTap: () {
                // Apna Logout logic yahan implement karein (e.g., Prefs update karke Navigator clear)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isUrdu ? "لاگ آؤٹ ہو رہا ہے..." : "Logging out...")),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 15),
                    Text(
                      _isUrdu ? "لاگ آؤٹ" : "Logout",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, int index) {
    bool isSelected = _bottomNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
          setState(() => _bottomNavIndex = index);
          _toggleSidebar();
        },
        leading: Icon(icon, color: isSelected ? const Color(0xFFFBC02D) : Colors.white70, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        horizontalTitleGap: 5,
        dense: true,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isUrdu;
  const HomeContent({super.key, required this.onMenuPressed, required this.isUrdu});

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
                    Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, top: 30, bottom: 15),
                      child: Text(
                        widget.isUrdu ? "اہم اپڈیٹس" : "Important Updates", 
                        style: const TextStyle(
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
          Expanded( 
            child: Row(
              children: [
                // VIP Trigger Menu Controller Custom Animated Button
                GestureDetector(
                  onTap: widget.onMenuPressed,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_open_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 15),
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ID: KG-9901", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.isUrdu ? "لیہ، پاکستان" : "Layyah, Pakistan", 
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              Expanded( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.isUrdu ? "آج کا موسم" : "Today", style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Text(
                      "${_weather?.temperature?.celsius?.toStringAsFixed(0) ?? "36"}°C", 
                      style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      _weather?.weatherDescription?.toUpperCase() ?? (widget.isUrdu ? "صاف آسمان" : "CLEAR SKY"), 
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
          Text(
            widget.isUrdu ? "صلاح اور الرٹس" : "Advisory & Alerts", 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
          ),
          const SizedBox(height: 15),
          _updateRow(
            Icons.warning_amber_rounded, 
            widget.isUrdu ? "شدید موسم کا الرٹ" : "Weather Alert", 
            widget.isUrdu ? "درجہ حرارت زیادہ ہے۔" : "High temperature.", 
            Colors.orange
          ),
          const Divider(),
          _updateRow(
            Icons.eco, 
            widget.isUrdu ? "زرعی مشورہ" : "Crop Advisory", 
            widget.isUrdu ? "کاشت کا سیزن شروع ہو گیا ہے۔" : "Sowing season started.", 
            Colors.green
          ),
        ],
      ),
    );
  }

  Widget _updateRow(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 15),
        Expanded( 
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
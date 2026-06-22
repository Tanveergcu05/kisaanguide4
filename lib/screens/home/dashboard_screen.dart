import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:weather/weather.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sahi paths ensure karein - Kisaan Guide Dashboard
import '../../screens/weather/weather_screen.dart'; 
import '../../screens/crops/orchard_details_screen.dart'; 
import '../../screens/crops/add_crop_screen.dart'; 
import '../../data/models/expense_tracker/screens/expense_main_screen.dart';
import '../../core/app_router.dart';
import '../../core/config/app_config.dart';
import '../auth/phone_input_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart' hide TextDirection;
import '../../models/crop_land.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<_HomeContentState> homeContentKey = GlobalKey<_HomeContentState>();
  int _bottomNavIndex = 0;
  
  // VIP Sidebar Animation Controls
  late AnimationController _sidebarAnimationController;
  bool _isSidebarOpen = false;
  
  // Global Language Configuration (Default: Urdu)
  bool _isUrdu = true;

  // Real-time synced Profile variables
  String _userNameEng = "Tanveer Bhai";
  String _userNameUrdu = "تنویر بھائی";
  String _userLocationEng = "Layyah, Pakistan";
  String _userLocationUrdu = "لیہ، پاکستان";
  String _userAvatar = "person_rounded";
  String _userLandArea = "12";
  String _userLandUnit = "Acre";
  String _userMainCrop = "Wheat (Gandum)";

  StreamSubscription<DocumentSnapshot>? _userSubscription;

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
    _loadLocalProfile();
    _listenToUserProfile();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNameEng = prefs.getString('userNameEnglish') ?? _userNameEng;
      _userNameUrdu = prefs.getString('userNameUrdu') ?? _userNameUrdu;
      _userLocationEng = prefs.getString('userLocationEnglish') ?? _userLocationEng;
      _userLocationUrdu = prefs.getString('userLocationUrdu') ?? _userLocationUrdu;
      _userAvatar = prefs.getString('userAvatar') ?? _userAvatar;
    });
  }

  void _listenToUserProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _userNameEng = data['nameEnglish'] ?? data['name'] ?? _userNameEng;
          _userNameUrdu = data['nameUrdu'] ?? data['name'] ?? _userNameUrdu;
          _userLocationEng = data['locationEnglish'] ?? data['location'] ?? _userLocationEng;
          _userLocationUrdu = data['locationUrdu'] ?? data['location'] ?? _userLocationUrdu;
          _userAvatar = data['avatar'] ?? _userAvatar;
          _userLandArea = data['landArea'] ?? _userLandArea;
          _userLandUnit = data['landUnit'] ?? _userLandUnit;
          _userMainCrop = data['mainCrop'] ?? _userMainCrop;
        });

        // Sync to SharedPreferences land_total and reload HomeContent State in real-time
        SharedPreferences.getInstance().then((prefs) {
          final double? parsedArea = double.tryParse(_userLandArea);
          if (parsedArea != null) {
            prefs.setDouble('land_total', parsedArea);
            homeContentKey.currentState?._loadSavedLandValues();
          }
        });
      }
    }, onError: (err) {
      debugPrint("Firestore Stream Error: $err");
    });
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
      HomeContent(
        key: homeContentKey,
        onMenuPressed: _toggleSidebar, 
        isUrdu: _isUrdu,
        onWeatherTap: () {
          setState(() {
            _bottomNavIndex = 1;
          });
        },
        onProfileTap: () {
          _showProfileDialog();
        },
        onNotificationTap: () {
          _showNotificationsDialog();
        },
        userName: _isUrdu ? _userNameUrdu : _userNameEng,
        userLocation: _isUrdu ? _userLocationUrdu : _userLocationEng,
        userAvatarType: _userAvatar,
      ),           
      WeatherScreen(onMenuPressed: _toggleSidebar, isUrdu: _isUrdu),         
      OrchardDetailsScreen(initialIsEnglish: !_isUrdu),
      AddCropScreen(isUrdu: _isUrdu), // FIXED: Passed the language parameter here
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF003527), // Background color for sidebar reveal
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
                          Color(0xFF003527), 
                          Color(0xFF005B41), 
                          Color(0xFF002219), 
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
                backgroundColor: const Color(0xFFAC3400),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRouter.expenses);
                  homeContentKey.currentState?._loadSavedLandValues();
                },
                child: const Icon(Icons.add, color: Colors.white, size: 30),
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
                activeColor: const Color(0xFF003527),
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
            // User Meta Data Brand Block (Clickable to Edit)
            InkWell(
              onTap: () {
                _toggleSidebar(); // Close sidebar first
                _showProfileDialog();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAC3400),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: HomeContent._getProfileAvatarIcon(_userAvatar, color: const Color(0xFF003527), size: 35),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isUrdu ? _userNameUrdu : _userNameEng,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.edit_rounded, color: Colors.white70, size: 14),
                            ],
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
              ),
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
                      const Icon(Icons.g_translate_rounded, color: Color(0xFFAC3400), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _isUrdu ? "اردو زبان" : "English",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isUrdu,
                    activeColor: const Color(0xFFAC3400),
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
                _logout();
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
        leading: Icon(icon, color: isSelected ? const Color(0xFFAC3400) : Colors.white70, size: 22),
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

  Future<void> _logout() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_isUrdu ? "لاگ آؤٹ ناکام رہا" : "Logout failed")),
      );
    }
  }

  void _showProfileDialog() {
    final nameEngController = TextEditingController(text: _userNameEng);
    final nameUrduController = TextEditingController(text: _userNameUrdu);
    final locEngController = TextEditingController(text: _userLocationEng);
    final locUrduController = TextEditingController(text: _userLocationUrdu);
    final landAreaController = TextEditingController(text: _userLandArea);
    String tempAvatar = _userAvatar;
    String selectedCrop = _userMainCrop;
    String selectedUnit = _userLandUnit;

    final crops = ['Wheat (Gandum)', 'Rice (Chawal)', 'Cotton (Kapaas)', 'Sugarcane (Gana)', 'Mango Orchard (Aam ka Baagh)'];
    final units = ['Acre', 'Bigha', 'Kanal'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF003527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isUrdu ? "پروفائل تبدیل کریں" : "Profile Settings",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),

                      // Avatar Selector Box
                      Text(
                        _isUrdu ? "پروفائل تصویر منتخب کریں" : "Select Profile Icon",
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAvatarOption(context, setDialogState, 'person_rounded', Icons.person_rounded, tempAvatar, (val) => tempAvatar = val),
                          _buildAvatarOption(context, setDialogState, 'agriculture_rounded', Icons.agriculture_rounded, tempAvatar, (val) => tempAvatar = val),
                          _buildAvatarOption(context, setDialogState, 'sunny', Icons.wb_sunny_rounded, tempAvatar, (val) => tempAvatar = val),
                          _buildAvatarOption(context, setDialogState, 'grass_rounded', Icons.grass_rounded, tempAvatar, (val) => tempAvatar = val),
                          _buildAvatarOption(context, setDialogState, 'eco_rounded', Icons.eco_rounded, tempAvatar, (val) => tempAvatar = val),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name (English)
                      _buildTextField(
                        controller: nameEngController,
                        label: _isUrdu ? "نام (انگلش)" : "Name (English)",
                        hint: "Enter English Name",
                        icon: Icons.abc_rounded,
                      ),
                      const SizedBox(height: 12),

                      // Name (Urdu)
                      _buildTextField(
                        controller: nameUrduController,
                        label: _isUrdu ? "نام (اردو)" : "Name (Urdu)",
                        hint: "نام درج کریں",
                        icon: Icons.person_outline_rounded,
                        alignRight: true,
                      ),
                      const SizedBox(height: 12),

                      // Location (English)
                      _buildTextField(
                        controller: locEngController,
                        label: _isUrdu ? "علاقہ (انگلش)" : "Location (English)",
                        hint: "e.g. Layyah, Pakistan",
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Location (Urdu)
                      _buildTextField(
                        controller: locUrduController,
                        label: _isUrdu ? "علاقہ (اردو)" : "Location (Urdu)",
                        hint: "علاقہ درج کریں، جیسے لیہ، پاکستان",
                        icon: Icons.map_rounded,
                        alignRight: true,
                      ),
                      const SizedBox(height: 12),

                      // Land Area and Unit
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: landAreaController,
                              label: _isUrdu ? "رقبہ" : "Land Area",
                              hint: "e.g. 12",
                              icon: Icons.crop_free_rounded,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isUrdu ? "یونٹ" : "Unit",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedUnit,
                                      dropdownColor: const Color(0xFF003527),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      onChanged: (String? newVal) {
                                        if (newVal != null) {
                                          setDialogState(() {
                                            selectedUnit = newVal;
                                          });
                                        }
                                      },
                                      items: units.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Main Crop
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isUrdu ? "بنیادی فصل" : "Main Crop",
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedCrop,
                                dropdownColor: const Color(0xFF003527),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                onChanged: (String? newVal) {
                                  if (newVal != null) {
                                    setDialogState(() {
                                      selectedCrop = newVal;
                                    });
                                  }
                                },
                                items: crops.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC3400),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          final nEng = nameEngController.text.trim();
                          final nUrdu = nameUrduController.text.trim();
                          final lEng = locEngController.text.trim();
                          final lUrdu = locUrduController.text.trim();
                          final area = landAreaController.text.trim();

                          if (nEng.isEmpty || nUrdu.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_isUrdu ? "براہ کرم نام درج کریں۔" : "Please enter a name")),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          
                          // Show loading overlay
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_isUrdu ? "فائربیس میں مخفوظ کیا جا رہا ہے..." : "Saving to Firebase..."),
                                ],
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );

                          try {
                            final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'uid': uid,
                              'name': nEng,
                              'nameUrdu': nUrdu,
                              'locationEnglish': lEng,
                              'locationUrdu': lUrdu,
                              'avatar': tempAvatar,
                              'landArea': area,
                              'landUnit': selectedUnit,
                              'mainCrop': selectedCrop,
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            // Also save locally
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('userNameEnglish', nEng);
                            await prefs.setString('userNameUrdu', nUrdu);
                            await prefs.setString('userLocationEnglish', lEng);
                            await prefs.setString('userLocationUrdu', lUrdu);
                            await prefs.setString('userAvatar', tempAvatar);
                            final double? parsedArea = double.tryParse(area);
                            if (parsedArea != null) {
                              await prefs.setDouble('land_total', parsedArea);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(_isUrdu ? "پروفائل کامیابی سے تبدیل کر دی گئی ہے!" : "Profile updated successfully!"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(_isUrdu ? "خرابی: دوبارہ کوشش کریں" : "Error: ${e.toString()}"),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          _isUrdu ? "تبدیلی محفوظ کریں" : "Save Changes",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarOption(
    BuildContext context, 
    StateSetter setDialogState, 
    String avatarName, 
    IconData icon, 
    String currentSelected,
    ValueChanged<String> onChange,
  ) {
    final bool isSelected = currentSelected == avatarName;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          onChange(avatarName);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAC3400) : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool alignRight = false,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.white60),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF003527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: Color(0xFFAC3400), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _isUrdu ? "اعلان اور الرٹس" : "Alerts & Notifications",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 16),

                    // Add Notification Button (Highly highlighted, professional look)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                      icon: const Icon(Icons.add_alert_rounded, color: Color(0xFFFBC02D), size: 20),
                      label: Text(
                        _isUrdu ? "نیا الرٹ جاری کریں" : "Issue New Alert",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        _showAddNotificationDialog();
                      },
                    ),
                    const SizedBox(height: 15),

                    // Real-time updates list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          }
                          
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            // Empty state (or show local ones beautifully)
                            return ListView(
                              children: [
                                _buildPreseededNotificationTile(
                                  Icons.warning_amber_rounded, 
                                  _isUrdu ? "شدید موسم کا الرٹ" : "Weather Alert", 
                                  _isUrdu ? "درجہ حرارت زیادہ ہے۔ اگلے کچھ دن دوپہر میں باہر جانے سے گریز کریں۔" : "High temperature. Avoid unnecessary outdoor movement.", 
                                  Colors.orange,
                                ),
                                const SizedBox(height: 8),
                                _buildPreseededNotificationTile(
                                  Icons.eco, 
                                  _isUrdu ? "زرعی مشورہ" : "Crop Advisory", 
                                  _isUrdu ? "کاشت کا بہترین سیزن شروع ہو چکا ہے۔ گندم کی بوائی کے لیے بیج اور کھاد کا بندوبست کریں۔" : "Sowing season is active. Prepare high quality seed and fertilizer.", 
                                  Colors.green,
                                ),
                              ],
                            );
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final title = _isUrdu ? (data['titleUrdu'] ?? data['title'] ?? '') : (data['titleEnglish'] ?? data['title'] ?? '');
                              final desc = _isUrdu ? (data['descUrdu'] ?? data['desc'] ?? '') : (data['descEnglish'] ?? data['desc'] ?? '');
                              final type = data['type'] ?? 'alert';
                              
                              IconData icon;
                              Color color;
                              if (type == 'weather') {
                                icon = Icons.warning_amber_rounded;
                                color = Colors.orange;
                              } else if (type == 'eco') {
                                icon = Icons.eco;
                                color = Colors.green;
                              } else {
                                icon = Icons.notifications_active_rounded;
                                color = const Color(0xFFAC3400);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreseededNotificationTile(IconData icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNotificationDialog() {
    final titleEngController = TextEditingController();
    final titleUrduController = TextEditingController();
    final descEngController = TextEditingController();
    final descUrduController = TextEditingController();
    String selectedType = 'eco'; // 'weather' or 'eco'

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Dialog(
              backgroundColor: const Color(0xFF003527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isUrdu ? "نیا الرٹ لکھیں" : "Create New Alert",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white60),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      
                      // Title English
                      _buildTextField(
                        controller: titleEngController,
                        label: _isUrdu ? "عنوان (انگلش)" : "Title (English)",
                        hint: "e.g. New Crop Rain Warning",
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 10),

                      // Title Urdu
                      _buildTextField(
                        controller: titleUrduController,
                        label: _isUrdu ? "عنوان (اردو)" : "Title (Urdu)",
                        hint: "مثلاً گندم کی تیار فصل کی کٹائی کا مشورہ",
                        icon: Icons.edit_note_rounded,
                        alignRight: true,
                      ),
                      const SizedBox(height: 10),

                      // Desc English
                      _buildTextField(
                        controller: descEngController,
                        label: _isUrdu ? "تفصیل الرٹ (انگلش)" : "Description (English)",
                        hint: "Rain expected inside layyah in next 2 hours.",
                        icon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 10),

                      // Desc Urdu
                      _buildTextField(
                        controller: descUrduController,
                        label: _isUrdu ? "تفصیل الرٹ (اردو)" : "Description (Urdu)",
                        hint: "لیہ اور مضافات میں اگلے ۲ گھنٹوں میں بارش کا امکان ہے",
                        icon: Icons.waves_outlined,
                        alignRight: true,
                      ),
                      const SizedBox(height: 15),

                      // Selection Type
                      Text(
                        _isUrdu ? "الرٹ کی قسم" : "Alert Category",
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(_isUrdu ? "موسم کا الرٹ" : "Weather", style: const TextStyle(color: Colors.white, fontSize: 13)),
                              value: 'weather',
                              groupValue: selectedType,
                              activeColor: Colors.orange,
                              onChanged: (val) {
                                if (val != null) setInnerState(() => selectedType = val);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(_isUrdu ? "زرعی مشورہ" : "Advisory", style: const TextStyle(color: Colors.white, fontSize: 13)),
                              value: 'eco',
                              groupValue: selectedType,
                              activeColor: Colors.green,
                              onChanged: (val) {
                                if (val != null) setInnerState(() => selectedType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Button Save
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC3400),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          final tEng = titleEngController.text.trim();
                          final tUrdu = titleUrduController.text.trim();
                          final dEng = descEngController.text.trim();
                          final dUrdu = descUrduController.text.trim();

                          if (tEng.isEmpty || tUrdu.isEmpty || dEng.isEmpty || dUrdu.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_isUrdu ? "تمام ڈبے پُر کریں۔" : "Please fill all fields")),
                            );
                            return;
                          }

                          Navigator.pop(context); // Close add notification dialog
                          
                          try {
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'titleEnglish': tEng,
                              'titleUrdu': tUrdu,
                              'descEnglish': dEng,
                              'descUrdu': dUrdu,
                              'type': selectedType,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(_isUrdu ? "نیا الرٹ فائربیس میں محفوظ کر دیا گیا ہے!" : "New alert synced with Firebase!"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(_isUrdu ? "خرابی پیش آئی" : "Error writing alert: ${e.toString()}"),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          _isUrdu ? "الرٹ جاری کریں" : "Publish Alert",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HomeContent extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isUrdu;
  final VoidCallback onWeatherTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final String userName;
  final String userLocation;
  final String userAvatarType;

  const HomeContent({
    super.key,
    required this.onMenuPressed,
    required this.isUrdu,
    required this.onWeatherTap,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.userName,
    required this.userLocation,
    required this.userAvatarType,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();

  static Widget _getProfileAvatarIcon(String type, {Color? color, double? size}) {
    if (type.startsWith('http://') || type.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          type,
          width: (size ?? 24) * 2,
          height: (size ?? 24) * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: color, size: size),
        ),
      );
    }
    
    IconData iconData;
    switch (type) {
      case 'agriculture_rounded':
        iconData = Icons.agriculture_rounded;
        break;
      case 'sunny':
        iconData = Icons.wb_sunny_rounded;
        break;
      case 'grass_rounded':
        iconData = Icons.grass_rounded;
        break;
      case 'eco_rounded':
        iconData = Icons.eco_rounded;
        break;
      case 'person_rounded':
      default:
        iconData = Icons.person_rounded;
    }
    return Icon(iconData, color: color, size: size);
  }
}

class _HomeContentState extends State<HomeContent> {
  Weather? _weather;
  bool _isLoading = true;
  final String _apiKey = AppConfig.openWeatherApiKey;

  double _savedTotal = 0;
  double _savedCrops = 0;
  double _savedOrchards = 0;
  double _savedFallow = 0;

  List<ZaraiRecord> _financeRecords = [];
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;

  final List<Color> _chartColors = [
    const Color(0xFF0F9D58), // Emerald Green
    const Color(0xFF4285F4), // Muted Blue
    const Color(0xFFF4B400), // Amber Gold
    const Color(0xFFDB4437), // Crimson Red
    const Color(0xFF00ACC1), // Deep Cyan
    const Color(0xFFAB47BC), // Muted Purple
    const Color(0xFF8D6E63), // Wood Brown
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
    _loadSavedLandValues();
  }

  String _formatDisplay(double val) {
    if (val == 0) return "0";
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  void _loadSavedLandValues() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load crops/orchards to support calculation
    final String? rawCrops = prefs.getString('crop_lands_v2');
    List<CropLand> tempCrops = [];
    if (rawCrops != null && rawCrops.trim().isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(rawCrops);
        tempCrops = jsonList.map((c) => CropLand.fromJson(c)).toList();
      } catch (e) {
        debugPrint("Error loading crop lands: $e");
      }
    }

    // Load finance records
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String storageKey = 'finance_records_v1_${uid ?? 'local'}';
    final rawFinance = prefs.getString(storageKey);
    List<ZaraiRecord> tempFinance = [];
    if (rawFinance != null && rawFinance.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFinance);
        if (decoded is List) {
          tempFinance = decoded
              .whereType<Map>()
              .map((m) => ZaraiRecord.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (_) {}
    }

    double expensesSum = tempFinance
        .where((r) => r.type == EntryType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    double incomeSum = tempFinance
        .where((r) => r.type == EntryType.income)
        .fold(0.0, (sum, item) => sum + item.amount);

    if (mounted) {
      setState(() {
        _savedTotal = prefs.getDouble('land_total') ?? 12.0;
        
        // Dynamic re-sync
        _savedCrops = tempCrops
            .where((c) => !c.isHarvested && !c.isOrchard)
            .fold(0.0, (sum, item) => sum + item.acres);
        _savedOrchards = tempCrops
            .where((c) => !c.isHarvested && c.isOrchard)
            .fold(0.0, (sum, item) => sum + item.acres);
        final double activeSum = _savedCrops + _savedOrchards;
        _savedFallow = _savedTotal - activeSum;
        if (_savedFallow < 0) _savedFallow = 0.0;

        _financeRecords = tempFinance;
        _totalExpenses = expensesSum;
        _totalIncome = incomeSum;
      });
    }
  }

  void _fetchLiveWeather() async {
    try {
      WeatherFactory wf = WeatherFactory(_apiKey);
      Weather w = await wf.currentWeatherByCityName(AppConfig.defaultWeatherCity);
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "صبح بخیر، کسان دوست!";
    } else if (hour < 18) {
      return "خوش آمدید، کسان دوست!";
    } else {
      return "شام بخیر، کسان دوست!";
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap inside a Container utilizing VIP style gradient background mixing premium vibrant rich agricultural green, yellow, and red
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFACD6BC), // Premium Rich Emerald Botanical Green
            Color(0xFFFCE195), // Premium Rich Harvest Warm Gold Yellow
            Color(0xFFFABF9B), // Premium Sunset Terracotta Rose Red
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _fetchLiveWeather();
                  _loadSavedLandValues();
                },
                color: const Color(0xFF003527),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Greetings
                      Text(
                        _getGreeting(),
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1D),
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isUrdu ? "آج آپ کی فصلوں کی صورتحال بہتر ہے۔" : "Your crops are in better condition today.",
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF404944),
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary HUD (Total Active Expense / Kul Kharcha)
                      _buildPrimaryHUD(),
                      const SizedBox(height: 24),

                      // Weather Widget (Large Modern Card)
                      _buildModernWeatherCard(),
                      const SizedBox(height: 24),

                      // Visual Analytics Chart (PieChart of Expenditures)
                      _buildCropExpenditureChart(),
                      const SizedBox(height: 24),

                      // Primary Navigation Button (Apni Zameen & Fasal Manage Karein)
                      _buildPrimaryNavigationButton(),
                      const SizedBox(height: 32),

                      // Advisory & Alerts Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            widget.isUrdu ? "صلاح اور الرٹس" : "Advisory & Alerts",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003527),
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNotificationTap,
                            child: Text(
                              widget.isUrdu ? "سب دیکھیں" : "See All",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003527),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Advice Cards
                      _buildAlertsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl, // Keeps top navbar structured properly
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // Logo/Title on right
              const Text(
                "Zarai",
                style: TextStyle(
                  color: Color(0xFF003527),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 15),
              // Mobile Notification trigger
              GestureDetector(
                onTap: widget.onNotificationTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF404944),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                // Location Text Block & User ID Card
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF003527),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "KG-9901",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF404944),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Avatar
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB0F0D6), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        "https://lh3.googleusercontent.com/aida-public/AB6AXuBzmtEYm5yZdGGheW_Ow_tzQocJxJEgkC9VIrd77fOwNNtBgOWEFT7O9L41ntIza5eNGqzXfhJnD4SiQTAO1hD4HNn1HAh9qc8E3WXFv4aW9JmAQKPinp0cMD4oTnE_sqx75VVVL_z5p1ZkBoYv_Jr4txzp_Fp7L3bI7Xtu3P6AnR1B0Npc6-WJexrjG4TKl0MxOP2ntvsVZy2WNUiixE9jMC76iMaByS1LMoLN-97ntxoQ_Jqbj-4sOYZP-Y6m6ICpGkRl83cOuno",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => HomeContent._getProfileAvatarIcon(widget.userAvatarType, color: const Color(0xFF003527), size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Menu trigger
                GestureDetector(
                  onTap: widget.onMenuPressed,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Color(0xFF003527),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWeatherCard() {
    final tempStr = _weather?.temperature?.celsius?.toStringAsFixed(0) ?? "37";
    final descStr = _weather?.weatherDescription != null 
        ? (widget.isUrdu ? "Layyah میں ${_weather!.weatherDescription}" : "Sunny in Layyah")
        : (widget.isUrdu ? "Layyah میں صاف دھوپ" : "Clear sunny in Layyah");
    final humStr = _weather?.humidity != null ? "${_weather!.humidity!.toStringAsFixed(0)}%" : "36%";
    final windStr = _weather?.windSpeed != null ? "${(_weather!.windSpeed! * 3.6).toStringAsFixed(0)}km/h" : "10km/h";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003527).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              // Temp and text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tempStr,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003527),
                          height: 1.1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, right: 2),
                        child: Text(
                          "°C",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B6954),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    descStr,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF404944),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ],
              ),
              // Large Amber icon block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDB8).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFF653E00),
                  size: 48,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Sub metrics
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF003527).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.water_drop_outlined, color: Color(0xFF003527)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isUrdu ? "نمی" : "Humidity",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF404944),
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                            Text(
                              humStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003527),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF003527).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.air_rounded, color: Color(0xFF003527)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isUrdu ? "ہوا" : "Wind",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF404944),
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                            Text(
                              windStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003527),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryHUD() {
    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.red.shade100, width: 1.5),
      ),
      color: Colors.red.shade50.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.rtl,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.isUrdu ? "کل فعال اخراجات (Kul Kharcha)" : "Total Active Expense",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(_totalExpenses),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.trending_up, color: Colors.red.shade900, size: 28),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCropExpenditureChart() {
    Map<String, double> cropExpenses = {};
    for (var r in _financeRecords) {
      if (r.type == EntryType.expense) {
        cropExpenses[r.subType] = (cropExpenses[r.subType] ?? 0.0) + r.amount;
      }
    }

    if (cropExpenses.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pie_chart_outline_rounded, color: Colors.grey.shade400, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isUrdu ? "ابھی تک کوئی خرچہ درج نہیں کیا گیا" : "Abhi tak koi kharcha darj nahi kiya gaya",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isUrdu 
                    ? "نیچے دیئے گئے بٹن سے نیا خرچہ درج کریں" 
                    : "Use the action button to record agricultural expenses",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double totalExp = cropExpenses.values.fold(0.0, (sum, val) => sum + val);
    List<PieChartSectionData> sections = [];
    int index = 0;
    cropExpenses.forEach((cropName, amount) {
      final percentage = (amount / totalExp) * 100;
      sections.add(
        PieChartSectionData(
          color: _chartColors[index % _chartColors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 35,
          showTitle: true,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
      index++;
    });

    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      color: Colors.white.withOpacity(0.955),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  widget.isUrdu ? "اخراجات کی تفصیل" : "Expenses distribution",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003527),
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                Icon(Icons.analytics_outlined, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isUrdu ? "کل خرچہ" : "Expenses",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Text(
                          currency.format(_totalExpenses),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFAC3400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legends formatted elegantly
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(cropExpenses.length, (idx) {
                final entry = cropExpenses.entries.elementAt(idx);
                final col = _chartColors[idx % _chartColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${entry.key}: ${currency.format(entry.value)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F3233),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryNavigationButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003527).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRouter.landManagement,
            arguments: {'isUrdu': widget.isUrdu},
          );
          _loadSavedLandValues();
        },
        icon: const Icon(Icons.landscape, color: Colors.white, size: 24),
        label: Text(
          widget.isUrdu ? "اپنی زمین اور فصل مینیج کریں" : "Apni Zameen & Fasal Manage Karein",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'Noto Sans Arabic',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003527),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      children: [
        // Warning Card (Weather)
        _buildAlertCard(
          backgroundColor: const Color(0xFFFFF4F2),
          borderColor: const Color(0xFFFFDAD6),
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFBA1A1A),
          iconBgColor: const Color(0xFFFFDAD6),
          title: widget.isUrdu ? "شدید موسم کا الرٹ" : "Severe Weather Alert",
          desc: widget.isUrdu 
              ? "آج دوپہر کے وقت شدید گرمی کی لہر کا خدشہ ہے، فصلوں کو وافر پانی دیں۔"
              : "Excessive heat warning today noon, water your crops sufficiently.",
          titleColor: const Color(0xFFBA1A1A),
        ),
        const SizedBox(height: 12),
        // Recommendation Card (Agriculture)
        _buildAlertCard(
          backgroundColor: const Color(0xFFF2FAF7),
          borderColor: const Color(0xFF95D3BA).withOpacity(0.3),
          icon: Icons.agriculture_rounded,
          iconColor: const Color(0xFF003527),
          iconBgColor: const Color(0xFFB0F0D6),
          title: widget.isUrdu ? "کاشتکاری کے مشورے" : "Farming Recommendation",
          desc: widget.isUrdu 
              ? "کپاس کی فصل میں کھاد ڈالنے کا بہترین وقت ہے۔ اس ہفتے نائٹروجن کا استعمال کریں۔"
              : "Optimal time for cotton crop fertilization. Utilize nitrogen this week.",
          titleColor: const Color(0xFF003527),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String desc,
    required Color titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Block
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Content block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF404944),
                    height: 1.4,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter supporting exact donut segments matching SVG arcs
class DonutChartPainter extends CustomPainter {
  final double cropPercentage;
  final double orchardPercentage;
  final double fallowPercentage;

  DonutChartPainter({
    required this.cropPercentage,
    required this.orchardPercentage,
    required this.fallowPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final strokeWidth = size.width * 0.12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Initial base background full track
    final bgPaint = Paint()
      ..color = const Color(0xFFF3F4F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Sweep starting at top: -90 degrees (-math.pi / 2)
    double startAngle = -math.pi / 2;

    // Fallow draw (15%) => color E5E7EB
    final fallowArcPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    double fallowSweep = 2 * math.pi * fallowPercentage;
    canvas.drawArc(rect, startAngle, fallowSweep, false, fallowArcPaint);
    startAngle += fallowSweep;

    // Orchards draw (25%) => color F97316
    final orchardArcPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    double orchardSweep = 2 * math.pi * orchardPercentage;
    canvas.drawArc(rect, startAngle, orchardSweep, false, orchardArcPaint);
    startAngle += orchardSweep;

    // Crops draw (40%) => color 064E3B / 003527 (matched primary agricultural green)
    final cropArcPaint = Paint()
      ..color = const Color(0xFF003527)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    double cropSweep = 2 * math.pi * cropPercentage;
    canvas.drawArc(rect, startAngle, cropSweep, false, cropArcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

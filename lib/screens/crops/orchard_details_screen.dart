import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrchardDetailsScreen extends StatefulWidget {
  const OrchardDetailsScreen({super.key});

  @override
  State<OrchardDetailsScreen> createState() => _OrchardDetailsScreenState();
}

class _OrchardDetailsScreenState extends State<OrchardDetailsScreen> with TickerProviderStateMixin {
  // Weather Variables
  late WeatherFactory _wf;
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  bool _isOffline = false;

  // Selection & Controllers
  int _selectedFruitIndex = 2; // Default Mango
  late TabController _tabController;

  static const Color primaryGreen = Color(0xFF5D8C4C);
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";

  // Fruits List
  final List<Map<String, dynamic>> _fruits = [
    {"name": "Citrus", "urdu": "Kinnu / Malta", "icon": Icons.lens_blur},
    {"name": "Mosambi", "urdu": "Mosambi", "icon": Icons.circle_outlined},
    {"name": "Mango", "urdu": "Aam ka Baag", "icon": Icons.energy_savings_leaf},
    {"name": "Guava", "urdu": "Amrood", "icon": Icons.eco},
    {"name": "Lemon", "urdu": "Leemo", "icon": Icons.brightness_high},
    {"name": "Orange", "urdu": "Malta", "icon": Icons.wb_sunny},
    {"name": "Pomegranate", "urdu": "Anar", "icon": Icons.grain},
    {"name": "Peach", "urdu": "Aroo", "icon": Icons.bubble_chart},
  ];

  // Professional Fruits Complete Data (A to Z Details)
  final Map<String, Map<String, dynamic>> _orchardDetailsData = {
    "Mango": {
      "kasht": "Aam ke naye poday lagane ka behtareen waqt February-March aur August-September hai. Podon ka fasla 25 se 30 feet hona chahiye.",
      "pani": "Baray darakhton ko her 10-15 din baad pani dein. Phool nikalte waqt (Burr) pani band kar dein, aur phal bante hi dubara shuru karein.",
      "khaad": "Gobar ki khaad December me dein. Nitrogen, Phosphorus aur Potash ki khuraak phal utarne ke baad (July) me dena behtareen hai.",
      "spray": "Teila (Jassid) aur Mango Hopper ke bachao ke liye burr nikalne se pehle aur baad me makhsoos spray lazmi karein.",
      "bimariyan": [
        {
          "name": "Mango Malformation / Burr ka Gucha Banna",
          "symptoms": "Phool aur naye patte guchay ki shakal ikhtiyar kar lete hain aur phal nahi banta.",
          "treatment": "Mutaasira guchon ko 2 feet piche se kaat kar jala dein aur Copper Fungicide ka spray karein."
        },
        {
          "name": "Powdery Mildew / Safaid Phoondi",
          "symptoms": "Burr aur phoolon par safaid powder jesa jala ban jata hai jis se phool gir jate hain.",
          "treatment": "Phool khulne se pehle Sulphate ya Topas fungicide ka spray karein."
        }
      ]
    },
    "Citrus": {
      "kasht": "Kinnu aur malte ke poday lagane ka behtareen waqt bahaar (Feb-March) ya monsoon (August-September) ka mausam hai.",
      "pani": "Garmiyon me har 7-10 din baad aur sardiyon me 20-25 din ke fasle par pani lagayein. Phal pakne ke waqt pani munasib rakhein.",
      "khaad": "Jan-Feb me DAP aur Urea dein. Zinc Sulphate aur Boron ka spray darakht ki sehat aur phal ki chamak ke liye nihayat zaroori hai.",
      "spray": "Citrus Psylla aur Leaf Miner ke khilaf naye patte nikalte hi Bifenthrin ya Imidacloprid ka spray karein.",
      "bimariyan": [
        {
          "name": "Citrus Canker / Khattay ka Jholas",
          "symptoms": "Patton, tehniyon aur phal par khurdaray, bhore (brown) rang ke dhabbe bante hain.",
          "treatment": "Mutaasira tehniyan kaat dein aur Copper Oxychloride ka 2-3 dafa spray karein."
        }
      ]
    },
    "Guava": {
      "kasht": "Amrood ki kasht saal me do dafa hoti hai. Iske liye 15x15 feet ya 20x20 feet ka fasla behtareen samjha jata hai.",
      "pani": "Amrood ko khule pani ki zaroorat hoti hai. Phal bante waqt pani ki kami se phal chota reh jata hai aur sakht ho jata hai.",
      "khaad": "Saal me do dafa gobar ki khaad ke sath 1 bora DAP aur half bora Urea fi darakht umar ke mutabiq takseem karein.",
      "spray": "Phal ki makhi (Fruit Fly) ke liye June aur September me Sex Pheromone Traps lagayein aur Trichlorfon spray karein.",
      "bimariyan": [
        {
          "name": "Guava Wilt / Amrood ka Sookha",
          "symptoms": "Poday ke patte achanak peelay hokar sukhne lagte hain aur poora darakht mar jata hai.",
          "treatment": "Zameen me pani khada na hone dein. Mutaasira darakht ki jaron me Thiophanate-Methyl flood karein."
        }
      ]
    },
  };

  @override
  void initState() {
    super.initState();
    _wf = WeatherFactory(_apiKey);
    _tabController = TabController(length: 5, vsync: this);
    _fetchWeather();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchWeather() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Weather weather = await _wf.currentWeatherByCityName("Layyah");
      setState(() {
        _currentWeather = weather;
        _isLoadingWeather = false;
        _isOffline = false;
      });
      if (weather.toJson() != null) {
        await prefs.setString('cached_weather', jsonEncode(weather.toJson()));
      }
    } catch (e) {
      debugPrint("Weather Offline Cache Check: $e");
      final String? cachedData = prefs.getString('cached_weather');
      if (cachedData != null) {
        setState(() {
          _currentWeather = Weather(jsonDecode(cachedData));
          _isLoadingWeather = false;
          _isOffline = true;
        });
      } else {
        setState(() {
          _isLoadingWeather = false;
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentFruitName = _fruits[_selectedFruitIndex]['name'];
    var currentDetails = _orchardDetailsData[currentFruitName] ?? {
      "kasht": "$currentFruitName ki kasht ki maloomat jald add ki jayengi.",
      "pani": "$currentFruitName ke pani ki maloomat jald available hongi.",
      "khaad": "$currentFruitName ki khaad ka schedule jald add hoga.",
      "spray": "$currentFruitName ki spray ki details jald di jayengi.",
      "bimariyan": []
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Capsule Type Weather Header
            _buildLiveWeatherHeader(),
            
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: const Text(
                        "My Orchard Management",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fruit Type Selection
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFruitSelectionCard(),
                    ),
                    const SizedBox(height: 25),

                    // Dynamic Section Heading for Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(_fruits[_selectedFruitIndex]['icon'], color: primaryGreen, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${_fruits[_selectedFruitIndex]['urdu']} Ki Tafseel aur Deghbhaat",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Custom TabBar Container with Roman Urdu Text & Small Icons
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: primaryGreen,
                        labelColor: primaryGreen,
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.wb_twilight, size: 18),
                            iconMargin: EdgeInsets.only(bottom: 4),
                            text: "Kasht",
                          ),
                          Tab(
                            icon: Icon(Icons.water_drop, size: 18),
                            iconMargin: EdgeInsets.only(bottom: 4),
                            text: "Pani",
                          ),
                          Tab(
                            icon: Icon(Icons.compost, size: 18),
                            iconMargin: EdgeInsets.only(bottom: 4),
                            text: "Khaad",
                          ),
                          Tab(
                            icon: Icon(Icons.clean_hands, size: 18),
                            iconMargin: EdgeInsets.only(bottom: 4),
                            text: "Spray",
                          ),
                          Tab(
                            icon: Icon(Icons.coronavirus, size: 18),
                            iconMargin: EdgeInsets.only(bottom: 4),
                            text: "Bimariyan",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // TabBarView Content Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 380, // Height optimized since form is removed
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildTextTabContent(currentDetails['kasht']),
                              _buildTextTabContent(currentDetails['pani']),
                              _buildTextTabContent(currentDetails['khaad']),
                              _buildTextTabContent(currentDetails['spray']),
                              _buildDiseasesTabContent(currentDetails['bimariyan'] ?? []),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWeatherHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingWeather
          ? const Center(child: Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator(color: Colors.white)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text("Layyah, Pakistan",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        if (_isOffline) ...[
                          const SizedBox(width: 6),
                          const Text("(Offline)", style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    Text(
                      _isOffline 
                          ? "LAST UPDATED" 
                          : (_currentWeather?.weatherDescription?.toUpperCase() ?? "LOADING..."),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.air, color: Colors.white70, size: 14),
                        Text(" Wind: ${_currentWeather?.windSpeed?.toStringAsFixed(1)} m/s", 
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentWeather?.weatherIcon != null && !_isOffline)
                      Image.network(
                        "http://openweathermap.org/img/wn/${_currentWeather!.weatherIcon}@2x.png",
                        width: 45,
                        height: 45,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, color: Colors.yellow, size: 30),
                      )
                    else
                      const Icon(Icons.cloud_queue, color: Colors.white70, size: 35),
                    Text(
                      _currentWeather?.temperature?.celsius != null 
                          ? "${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°C" 
                          : "--°C",
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildFruitSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Fruit Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85, 
            ),
            itemCount: _fruits.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedFruitIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFruitIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? primaryGreen : Colors.black12),
                      ),
                      child: Icon(
                        _fruits[index]['icon'],
                        color: isSelected ? Colors.white : primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fruits[index]['name'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primaryGreen : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextTabContent(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Text(
        content,
        style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDiseasesTabContent(List<dynamic> diseases) {
    if (diseases.isEmpty) {
      return const Center(child: Text("Is phal ki bimariyon ka data jald add kia jayega."));
    }

    return ListView.builder(
      itemCount: diseases.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      itemBuilder: (context, index) {
        var disease = diseases[index];
        return Card(
          color: Colors.grey.shade50,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black12),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.bug_report, color: Colors.redAccent),
            title: Text(
              disease['name'] ?? 'Unknown Disease',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
            iconColor: primaryGreen,
            collapsedIconColor: Colors.black54,
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.black12),
              const SizedBox(height: 5),
              const Text(
                "Alamaat / Symptoms:",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                disease['symptoms'] ?? 'Nishaniyan available nahi hain.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 15),
              const Text(
                "Ilaaj / Treatment:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                disease['treatment'] ?? 'Ilaaj available nahi hai.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}
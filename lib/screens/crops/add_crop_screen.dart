import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> with TickerProviderStateMixin {
  // Weather Variables
  late WeatherFactory _wf;
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  bool _isOffline = false;
  
  // App Variables
  int _selectedCropIndex = 0;
  late TabController _tabController;

  static const Color primaryGreen = Color(0xFF5D8C4C);
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";

  // Crops List
  final List<Map<String, dynamic>> _crops = [
    {"name": "Wheat", "urdu": "Gandum", "icon": Icons.grass},
    {"name": "Cotton", "urdu": "Kapaas", "icon": Icons.opacity},
    {"name": "Sesame", "urdu": "Til", "icon": Icons.grain},
    {"name": "Maize", "urdu": "Makai", "icon": Icons.agriculture},
    {"name": "Rice", "urdu": "Chawal", "icon": Icons.waves},
    {"name": "Sugarcane", "urdu": "Ganna", "icon": Icons.reorder},
  ];

  // Professional Crops Complete Data (A to Z Details)
  final Map<String, Map<String, dynamic>> _cropDetailsData = {
    "Wheat": {
      "kasht": "Gandum ki kasht ka behtareen waqt 1 November se 30 November tak hai. Zameen ko 2-3 dafa hal chala kar achhi tarah tayar karein.",
      "pani": "Gandum ko aam tor par 4 se 5 pani chahiye hote hain:\n\n1. Pehla Pani: Kor Paani (Sowing ke 20-25 din baad).\n2. Dusra Pani: Shakhain nikalte waqt (40-45 din baad).\n3. Tisra Pani: Gof stage/Sitta bante waqt (70-80 din baad).\n4. Chotha Pani: Doodhia stage par (90-100 din baad).",
      "khaad": "Sowing ke waqt: 1 Bora DAP aur 1 Bora Potassium Sulphate per acre.\nPehle Pani par: 1 Bora Urea.\nDusre Pani par: Half Bora Urea daalein.",
      "spray": "Jari-bootiyon (Weeds) ke khatme ke liye kasht ke 24 se 48 ghante ke andar pre-emergence spray karein, ya pehle pani ke baad makhsoos spray lazmi karein.",
      "bimariyan": [
        {
          "name": "Rust / Kangi (پیلی کنگی)",
          "symptoms": "Patton par peelay ya surkh rang ke dhabbe bante hain jo powder ki tarah jhadte hain.",
          "treatment": "Tilt (200ml) ya Nativo (65gm) per acre 100 liter pani me mix kar ke spray karein."
        },
        {
          "name": "Loose Smut / Kani (کانگڑی)",
          "symptoms": "Sitte ke andar danon ki jagah siyah powder (black dust) ban jati hai.",
          "treatment": "Sowing se pehle beej ko fungicide (e.g., Homai ya Dyno) lazmi lagayein."
        }
      ]
    },
    "Cotton": {
      "kasht": "Kapaas ki kasht April se May ke darmiyan hoti hai. Lino ka fasla 2.5 feet aur podon ka fasla 9 se 12 inch hona chahiye.",
      "pani": "Kapaas ko mausam ke mutabiq 6 se 8 pani lagte hain. Pehla pani kasht ke 30-35 din baad lagayein, phir har 12-15 din ke fasle par pani dein.",
      "khaad": "Kasht ke waqt: 1 Bora DAP.\nShukufe nikalte waqt (Flowering): 1 Bora Urea.\nGul aur Tiddi bante waqt: 1 Bora Urea + Ammonium Nitrate.",
      "spray": "Safaid Makhi, Jassid, aur Thrips ke liye 40-50 din baad monitoring shuru karein aur zarorat parne par makhsoos insecticide spray karein.",
      "bimariyan": [
        {
          "name": "Cotton Leaf Curl Virus / CLCuV (پتہ مروڑ وائرس)",
          "symptoms": "Patte niche se upar ki taraf mud jate hain aur rabein moti ho jati hain.",
          "treatment": "Iska koi direct ilaaj nahi hai. Safaid Makhi (Whitefly) ko control karein kyunki wo ye virus phelati hai. Neem Extract ya Pyriproxyfen spray karein."
        },
        {
          "name": "Boll Rot / Tiddi ka Galna",
          "symptoms": "Kapaas ke tinde kharab hokar kale ho jate hain aur rui kharab ho jati hai.",
          "treatment": "Fungicide spray jese Copper Oxychloride 500gm per acre karein."
        }
      ]
    },
    "Sesame": {
      "kasht": "Til ki kasht June ke aakhri hafte se July ke darmiyan hoti hai. Mera zameen iske liye behtareen hai.",
      "pani": "Til ko bohot kam pani chahiye hota hai. Aam tor par 2 se 3 pani kafi hote hain. Siyadh (Waterlogging) se fasal tabah ho sakti hai.",
      "khaad": "Zameen ki tayari me 1 Bora DAP daalein. Flowering stage par half bora Urea dena faide-mand hota hai.",
      "spray": "Sowing ke foran baad jari-bootiyon ke bachao ka spray karein taake til ke naye podon ko poori khorak mil sake.",
      "bimariyan": [
        {
          "name": "Phyllody / Patta Numa Sitta",
          "symptoms": "Phoolon ki jagah chote chote sabz patte nikal aate hain aur sitta nahi banta.",
          "treatment": "Ye beej aur joshilay ke zariye phelti hai. Jassid ko control karne ke liye Imidacloprid spray karein."
        }
      ]
    },
    "Maize": {
      "kasht": "Baharia Makai: Jan se Feb. Tilaumi/Khareef Makai: July se August. Khelion (Ridges) par kasht behtareen tareeqa hai.",
      "pani": "Makai ko pani ki sakht zaroorat hoti hai, khaskar Tassel (Phool) bante waqt. Har 7 se 10 din baad zaroorat ke mutabiq pani dein.",
      "khaad": "1.5 Bora DAP zameen me, aur har dusre pani ke sath thodi thodi Urea (Total 2-3 bore) lazmi daalein.",
      "spray": "Makai ki konpal ki sundi (Fall Armyworm) ke liye kasht ke 15 din baad se hi Chloantraniliprole ya Emamectin ka spray lazmi karein.",
      "bimariyan": [
        {
          "name": "Shoot Fly / Konpal ki Makhi",
          "symptoms": "Chote podon ki darmiyani konpal sukh jati hai jise 'Dead Heart' kehte hain.",
          "treatment": "Furon ya Carbofuran granules 3kg per acre khelion me daalein."
        }
      ]
    },
    "Rice": {
      "kasht": "Chawal ki paneeri May-June me lagayi jati hai aur July me kaddu kar ke muntaqil ki jati hai.",
      "pani": "Pehle 25-30 din khet me pani khada rakhna lazmi hai. Fasal pakne se 2 hafte pehle pani band kar diya jata hai.",
      "khaad": "Paneeri lagate waqt 1 Bora DAP, 1 Bora Ammonium Sulphate aur 5kg Zinc Sulphate (33%) lazmi dein.",
      "spray": "Jari-booti mar spray (e.g. Butachlor) paneeri lagane ke 3 se 5 din ke andar khade pani me daalein.",
      "bimariyan": [
        {
          "name": "Rice Blast / Jhulsa0 (دھان کا جھلساؤ)",
          "symptoms": "Patton par darmiyan se chode aur kinaro se tikhay (Spindle-shaped) dhabbe bante hain.",
          "treatment": "Tricyclazole ya Nativo spray 100gm per acre ke hisab se karein."
        }
      ]
    },
    "Sugarcane": {
      "kasht": "Kamad ki kasht saal me do dafa hoti hai: September-October (Behtareen) aur February-March.",
      "pani": "Ganne ko poore saal me 16 se 20 pani chahiye hote hain. Garmiyon me har 8-10 din baad pani lagana parta hai.",
      "khaad": "Kasht ke waqt 2 Bora DAP. Garmiyon ke aagaz me 3 se 4 bore Urea mukhtalif aqsat me dein.",
      "spray": "Deemak (Termites) aur Gurdaspur borer ke bachao ke liye Chlorpyrifos pani ke sath flood karein.",
      "bimariyan": [
        {
          "name": "Red Rot / Ganne ka Ratta (گنے کا رتہ)",
          "symptoms": "Ganna andar se surkh ho jata hai aur pharne par sharaab jesi boo aati hai.",
          "treatment": "Mutaasira podon ko nikal kar jala dein aur hamesha sehat-mand aur bemaron se pak beej kasht karein."
        }
      ]
    }
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
    String currentCropName = _crops[_selectedCropIndex]['name'];
    var currentDetails = _cropDetailsData[currentCropName] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Capsule Type Weather Header
            _buildLiveWeatherHeader(),
            const SizedBox(height: 15),
            
            // Fixed Section for Selecting Crop
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Crop Type", 
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  _buildCropGrid(),
                  const SizedBox(height: 20),
                  
                  // Dynamic Section Heading
                  Row(
                    children: [
                      Icon(_crops[_selectedCropIndex]['icon'], color: primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "${_crops[_selectedCropIndex]['urdu']} (${currentCropName}) Ki Tafseel",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildTextTabContent(currentDetails['kasht'] ?? "No Data available"),
                        _buildTextTabContent(currentDetails['pani'] ?? "No Data available"),
                        _buildTextTabContent(currentDetails['khaad'] ?? "No Data available"),
                        _buildTextTabContent(currentDetails['spray'] ?? "No Data available"),
                        _buildDiseasesTabContent(currentDetails['bimariyan'] ?? []),
                      ],
                    ),
                  ),
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

  Widget _buildCropGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
      ),
      itemCount: _crops.length,
      itemBuilder: (context, index) {
        bool isSelected = _selectedCropIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedCropIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? primaryGreen : Colors.black12),
              boxShadow: isSelected ? [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 8)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_crops[index]['icon'], color: isSelected ? Colors.white : primaryGreen, size: 28),
                const SizedBox(height: 5),
                Text(_crops[index]['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Common Widget for General Text Tabs
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

  // Custom Widget for Diseases Tab using ExpansionTile System
  Widget _buildDiseasesTabContent(List<dynamic> diseases) {
    if (diseases.isEmpty) {
      return const Center(child: Text("Is fasal ki bimariyon ka data jald add kia jayega."));
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
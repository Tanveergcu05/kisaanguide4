import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  // Weather Variables
  late WeatherFactory _wf;
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  
  // App Variables
  int _selectedCropIndex = 0;
  String _selectedMethod = 'Chatta';
  String _selectedVariety = 'Sehar-2022';
  DateTime _sowingDate = DateTime.now();
  final TextEditingController _customSeedController = TextEditingController();

  static const Color primaryGreen = Color(0xFF5D8C4C);
  
  // Aapki Di Hui API Key Yahan Add Kar Di Hai
  final String _apiKey = "ec9d2ead2f16649d2ef771223db591c6";

  final List<Map<String, dynamic>> _crops = [
    {"name": "Wheat", "urdu": "Gandum", "icon": Icons.grass},
    {"name": "Cotton", "urdu": "Kapaas", "icon": Icons.opacity},
    {"name": "Sesame", "urdu": "Til", "icon": Icons.grain},
    {"name": "Maize", "urdu": "Makai", "icon": Icons.agriculture},
    {"name": "Rice", "urdu": "Chawal", "icon": Icons.waves},
    {"name": "Sugarcane", "urdu": "Ganna", "icon": Icons.reorder},
  ];

  @override
  void initState() {
    super.initState();
    _wf = WeatherFactory(_apiKey);
    _fetchWeather();
  }

  // Layyah ka live weather fetch karne wala function
  void _fetchWeather() async {
    try {
      // Shehar ka naam Layyah set kar diya
      Weather weather = await _wf.currentWeatherByCityName("Layyah");
      setState(() {
        _currentWeather = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() => _isLoadingWeather = false);
      debugPrint("Weather Error: $e");
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _sowingDate = picked);
  }

  void _showAddSeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Seed Variety"),
        content: TextField(
          controller: _customSeedController,
          decoration: const InputDecoration(hintText: "Enter variety name (e.g. Inqilab-91)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () {
              if (_customSeedController.text.isNotEmpty) {
                setState(() => _selectedVariety = _customSeedController.text);
                _customSeedController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("New Crop Field Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildLiveWeatherHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Crop Type", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildCropGrid(),
                  const SizedBox(height: 25),
                  Text("${_crops[_selectedCropIndex]['name']} Field Details",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildFormCard(),
                  const SizedBox(height: 25),
                  _buildSaveButton(),
                  const SizedBox(height: 100), // Navigation bar ke liye space
                ],
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
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: _isLoadingWeather
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Layyah, Pakistan",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_currentWeather?.weatherDescription?.toUpperCase() ?? "Loading...",
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
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
                  children: [
                    if (_currentWeather?.weatherIcon != null)
                      Image.network(
                        "http://openweathermap.org/img/wn/${_currentWeather!.weatherIcon}@2x.png",
                        width: 60,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, color: Colors.yellow, size: 40),
                      ),
                    Text("${_currentWeather?.temperature?.celsius?.toStringAsFixed(0)}°C",
                      style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
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
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
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
                Icon(_crops[index]['icon'], color: isSelected ? Colors.white : primaryGreen, size: 30),
                const SizedBox(height: 5),
                Text(_crops[index]['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Date of Sowing", Icons.event),
          GestureDetector(onTap: _pickDate, child: _inputBox(DateFormat('dd MMM yyyy').format(_sowingDate), Icons.calendar_month)),
          const SizedBox(height: 20),
          _fieldLabel("Seed Variety", Icons.search),
          GestureDetector(onTap: _showAddSeedDialog, child: _inputBox(_selectedVariety, Icons.add_circle_outline, isAction: true)),
          const SizedBox(height: 20),
          _fieldLabel("Sowing Method", Icons.architecture),
          const SizedBox(height: 10),
          _buildMethodChips(),
        ],
      ),
    );
  }

  Widget _fieldLabel(String l, IconData i) => Row(children: [Icon(i, size: 16, color: primaryGreen), const SizedBox(width: 8), Text(l, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))]);

  Widget _inputBox(String t, IconData i, {bool isAction = false}) => Container(
    height: 55, margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: isAction ? Colors.white : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isAction ? primaryGreen : Colors.black12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Icon(i, color: primaryGreen)]),
  );

  Widget _buildMethodChips() {
    return Wrap(
      spacing: 8,
      children: ['Drill', 'Kera', 'Chatta'].map((m) {
        bool s = _selectedMethod == m;
        return ChoiceChip(
          label: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Text(m)), 
          selected: s, 
          onSelected: (val) => setState(() => _selectedMethod = m), 
          selectedColor: primaryGreen, 
          labelStyle: TextStyle(color: s ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Field Details Saved Successfully!")));
        },
        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4),
        child: const Text("SAVE FIELD DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
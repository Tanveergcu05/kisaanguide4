import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrchardDetailsScreen extends StatefulWidget {
  const OrchardDetailsScreen({super.key});

  @override
  State<OrchardDetailsScreen> createState() => _OrchardDetailsScreenState();
}

class _OrchardDetailsScreenState extends State<OrchardDetailsScreen> {
  int _selectedFruitIndex = 0;
  int _selectedSoilIndex = 2;
  DateTime _selectedDate = DateTime(2026, 5, 15);

  final TextEditingController _ageController = TextEditingController(text: "4-10");
  final TextEditingController _areaController = TextEditingController(text: "12");
  final TextEditingController _treeController = TextEditingController(text: "2400");

  static const Color primaryGreen = Color(0xFF558B2F);
  static const Color lightGrey = Color(0xFFF5F5F5);

  final List<Map<String, dynamic>> _fruits = [
    {"name": "Citrus", "icon": Icons.bakery_dining},
    {"name": "Mosambi", "icon": Icons.circle_outlined},
    {"name": "Mango", "icon": Icons.energy_savings_leaf},
    {"name": "Guava", "icon": Icons.eco},
    {"name": "Lemon", "icon": Icons.shield},
    {"name": "Orange", "icon": Icons.wb_sunny},
    {"name": "Pomegranate", "icon": Icons.grain},
    {"name": "Peach", "icon": Icons.icecream_outlined},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Kisaan Orchard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFruitSelectionCard(),
                    const SizedBox(height: 15),
                    _buildGardenDetailsForm(),
                    const SizedBox(height: 20),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          const Text("Select Fruit Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Ratio ko 0.8 se barha kar 0.9 kiya taake height overflow na kare
              childAspectRatio: 0.9, 
            ),
            itemCount: _fruits.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedFruitIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFruitIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Content ko minimum space pe rakhega
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Padding thodi kam ki
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? primaryGreen : Colors.black12),
                      ),
                      child: Icon(
                        _fruits[index]['icon'],
                        color: isSelected ? Colors.white : Colors.orangeAccent,
                        size: 24, // Size 28 se 24 kiya
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fruits[index]['name'],
                      style: TextStyle(
                        fontSize: 11, // Font size 12 se 11 kiya
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

  Widget _buildGardenDetailsForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: lightGrey, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_fruits[_selectedFruitIndex]['name']} Details",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildFieldLabel("Garden Age (Years):", Icons.calendar_today),
          _buildInputTextField(_ageController, "Enter years"),
          const SizedBox(height: 10),
          _buildFieldLabel("Total Area (Acres):", Icons.square_foot),
          _buildInputTextField(_areaController, "Enter acres"),
          const SizedBox(height: 10),
          _buildFieldLabel("Tree Count:", Icons.park),
          _buildInputTextField(_treeController, "Enter count"),
          const SizedBox(height: 10),
          _buildFieldLabel("Soil Type:", Icons.terrain),
          _buildSoilTypes(),
          const SizedBox(height: 10),
          _buildFieldLabel("Last Watering Date:", Icons.water_drop),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildInputTextField(TextEditingController controller, String hint) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSoilTypes() {
    final types = ["Clay", "Loamy", "Sandy", "Other"];
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        children: List.generate(types.length, (index) {
          bool isSelected = _selectedSoilIndex == index;
          return ChoiceChip(
            label: Text(types[index]),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedSoilIndex = index),
            selectedColor: primaryGreen,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        }),
      ),
    );
  }

  Widget _buildDateField() {
    String formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 45,
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
            ),
            const Icon(Icons.calendar_month, color: primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${_fruits[_selectedFruitIndex]['name']} Data Saved!")),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text(
          "SAVE DATA",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/dashboard_screen.dart'; 

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  int _currentStep = 0;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  
  // Form Selections
  String _selectedUnit = 'Acre';
  String _selectedSoil = 'Loamy (Meera)';
  String _selectedCrop = 'Wheat (Gandum)';
  
  // Multiple Selection ke liye List use ki hai
  List<String> _selectedWater = []; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 48, 177, 55), AppColors.gradientBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            // Header Section
            const Text(
              "Kisaan Profile", 
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep == 0 ? "Add Your Details" : "Zaraat ki tafseelat",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            
            // White Card Section
            Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40), 
                  topRight: Radius.circular(40)
                ),
              ),
              child: Column(
                children: [
                  // Step Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(0),
                      const SizedBox(width: 10),
                      _buildStepDot(1),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Form Switcher with Slide Animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final inAnimation = Tween<Offset>(
                        begin: const Offset(1.0, 0.0), 
                        end: Offset.zero
                      ).animate(animation);
                      
                      final outAnimation = Tween<Offset>(
                        begin: const Offset(-1.0, 0.0), 
                        end: Offset.zero
                      ).animate(animation);

                      return SlideTransition(
                        position: child.key == ValueKey<int>(_currentStep) 
                            ? inAnimation 
                            : outAnimation,
                        child: child,
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_currentStep),
                      child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Action Button (Capsule Shape)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 0) {
                          setState(() => _currentStep = 1);
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        // StadiumBorder lagane se button perfect capsule ban jata hai
                        shape: const StadiumBorder(), 
                        elevation: 5,
                      ),
                      child: Text(
                        _currentStep == 0 ? "Agla Marhala (Next)" : "Finish", 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int step) {
    return CircleAvatar(
      radius: 6, 
      backgroundColor: _currentStep == step ? AppColors.primaryGreen : Colors.grey.shade300
    );
  }

  // Step 1: Farmer Name & Land Area
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Farmer Name"),
        TextField(
          controller: _nameController, 
          decoration: _inputStyle("Poora Naam", Icons.person_outline)
        ),
        const SizedBox(height: 20),
        _label("Total Land Area (Kul Raqba)"),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _areaController, 
                keyboardType: TextInputType.number, 
                decoration: _inputStyle("e.g. 10", Icons.landscape_outlined)
              )
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.softGrey, 
                  borderRadius: BorderRadius.circular(15)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    items: ['Acre', 'Kanal'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Agriculture Details (Updated for Multi-Selection)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Main Crop (Asal Fasal)"),
        _customDropdown(
          value: _selectedCrop,
          items: ['Wheat (Gandum)', 'Cotton (Kapas)', 'Rice (Chawal)', 'Mango Orchard (Aam)'],
          onChanged: (val) => setState(() => _selectedCrop = val!),
        ),
        const SizedBox(height: 20),
        
        _label("Soil Type (Zameen ki Qisam)"),
        _customDropdown(
          value: _selectedSoil,
          items: ['Loamy (Meera)', 'Clayey (Chikni)', 'Sandy (Retili)'],
          onChanged: (val) => setState(() => _selectedSoil = val!),
        ),
        const SizedBox(height: 20),
        
        _label("Water Source (Multiple Selectable)"),
        Wrap(
          spacing: 10,
          children: ['Tube-well', 'Canal', 'Rain'].map((source) {
            final isSelected = _selectedWater.contains(source);
            return ChoiceChip(
              label: Text(source),
              selected: isSelected,
              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedWater.add(source);
                  } else {
                    _selectedWater.remove(source);
                  }
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGreen : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper Styles
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 5),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
  );

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primaryGreen),
    filled: true,
    fillColor: AppColors.softGrey,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primaryGreen)),
  );

  Widget _customDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: AppColors.softGrey, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
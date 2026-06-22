import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../home/dashboard_screen.dart'; 

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  int _currentStep = 0;
  bool _isLoading = false; 
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  
  // Form Selections
  String _selectedUnit = 'Acre';
  String _selectedSoil = 'Loamy (Meera)';
  String _selectedCrop = 'Wheat (Gandum)';
  
  // Multiple Selection
  final List<String> _selectedWater = []; 

  Future<void> _saveFarmerDetails() async {
    if (_nameController.text.trim().isEmpty || _areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تفصیلات مکمل درج کریں۔ (Please fill all fields)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'phoneNumber': currentUser.phoneNumber ?? '',
          'name': _nameController.text.trim(),
          'landArea': _areaController.text.trim(),
          'landUnit': _selectedUnit,
          'mainCrop': _selectedCrop,
          'soilType': _selectedSoil,
          'waterSources': _selectedWater,
          'createdAt': FieldValue.serverTimestamp(),
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        throw Exception("حساب سیشن نہیں ملا۔ دوبارہ کوشش کریں۔");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خرابی: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'کسان پروفائل',
          style: TextStyle(
            color: Color(0xFF003527),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Beautiful Top Badge Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF003527),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF003527).withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(Icons.person_pin, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'اپنی تفصیلات درج کریں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003527),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'بہتر زرعی مشوروں اور رہنمائی کے لیے نیچے دی گئی معلومات فراہم کریں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Elegant Step Container Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step progress indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(0, 'بنیادی معلومات'),
                        const SizedBox(width: 12),
                        Container(width: 24, height: 1.5, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        _buildStepIndicator(1, 'زرعی تفصیلات'),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Wizard steps switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<int>(_currentStep),
                        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        if (_currentStep == 1) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _currentStep = 0),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF003527), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'پیچھے',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003527),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onContinuePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003527),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _currentStep == 0 ? 'اگلا مرحلہ' : 'رجسٹریشن مکمل کریں',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final bool isActive = _currentStep == stepIndex;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF003527) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF003527) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  void _onContinuePressed() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _areaController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('براہ کرم تمام بنیادی معلومات درج کریں')),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else {
      _saveFarmerDetails();
    }
  }

  // Step 1 Layout: Profile basic indicators
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'نام (Farmer Name)',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _nameController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'اپنا مکمل نام لکھیے',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF003527)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'کل رقبہ (Total Land Area)',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF003527)),
                    items: ['Acre', 'Kanal'].map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          e == 'Acre' ? 'ایکڑ (Acre)' : 'کنال (Kanal)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _areaController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'رقبہ درج کریں (جیسے 10)',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2 Layout: Crops & soil details
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'بنیادی فصل (Main Crop)',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        _buildCustomDropdown(
          value: _selectedCrop,
          items: ['Wheat (Gandum)', 'Cotton (Kapas)', 'Rice (Chawal)', 'Mango Orchard (Aam)'],
          onChanged: (val) => setState(() => _selectedCrop = val!),
          urduMapping: {
            'Wheat (Gandum)': 'گندم (Wheat)',
            'Cotton (Kapas)': 'کپاس (Cotton)',
            'Rice (Chawal)': 'چاول (Rice)',
            'Mango Orchard (Aam)': 'آم کا باغ (Mango)',
          },
        ),
        const SizedBox(height: 20),
        
        const Text(
          'زمین کی قسم (Soil Type)',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        _buildCustomDropdown(
          value: _selectedSoil,
          items: ['Loamy (Meera)', 'Clayey (Chikni)', 'Sandy (Retili)'],
          onChanged: (val) => setState(() => _selectedSoil = val!),
          urduMapping: {
            'Loamy (Meera)': 'میرا زمین (Loamy)',
            'Clayey (Chikni)': 'چکنی مٹی (Clayey)',
            'Sandy (Retili)': 'ریتیلی زمین (Sandy)',
          },
        ),
        const SizedBox(height: 20),
        
        const Text(
          'پانی کا ذریعہ (Water Sources)',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: ['Tube-well', 'Canal', 'Rain'].map((source) {
            final isSelected = _selectedWater.contains(source);
            String urduLabel = source;
            if (source == 'Tube-well') urduLabel = 'ٹیوب ویل';
            if (source == 'Canal') urduLabel = 'نہر';
            if (source == 'Rain') urduLabel = 'بارش';

            return FilterChip(
              label: Text(
                urduLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF003527),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? const Color(0xFF003527) : Colors.grey.shade300),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedWater.add(source);
                  } else {
                    _selectedWater.remove(source);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required Map<String, String> urduMapping,
  }) {
    String validatedValue = items.contains(value) ? value : items.first;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: validatedValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF003527)),
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              alignment: Alignment.centerRight,
              child: Text(
                urduMapping[e] ?? e,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kisaanguide4/models/crop_land.dart';

class LandManagementScreen extends StatefulWidget {
  final bool isUrdu;

  const LandManagementScreen({
    super.key,
    this.isUrdu = true,
  });

  @override
  State<LandManagementScreen> createState() => _LandManagementScreenState();
}

class _LandManagementScreenState extends State<LandManagementScreen> {
  // Land Total Setup
  final TextEditingController _totalLandController = TextEditingController();
  double _totalLand = 10.0; // Default total land in acres

  // Add Crop Form Controllers
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _acresController = TextEditingController();
  bool _isOrchard = false; // ChoiceChip selection (false: Crop/Fasal, true: Orchard/Bagh)
  String _cultivationType = "Alag Alag"; // "Alag Alag" or "Mix"

  // Data List
  List<CropLand> _cropLandsList = [];
  bool _isLoading = true;

  // Chart Styling Colors
  final List<Color> _chartColors = [
    const Color(0xFF0F9D58), // Emerald Green
    const Color(0xFF4285F4), // Muted Blue
    const Color(0xFFF4B400), // Amber Gold
    const Color(0xFFDB4437), // Crimson Red
    const Color(0xFF00ACC1), // Deep Cyan
    const Color(0xFFAB47BC), // Muted Purple
    const Color(0xFF8D6E63), // Brown Wood
    const Color(0xFFC0CA33), // Olive Green
  ];

  @override
  void initState() {
    super.initState();
    _loadStateData();
  }

  @override
  void dispose() {
    _totalLandController.dispose();
    _cropNameController.dispose();
    _acresController.dispose();
    super.dispose();
  }

  // Load state from local storage & cloud synchronized sources
  Future<void> _loadStateData() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Load Total Land
    double totalLand = prefs.getDouble('land_total') ?? 12.0;

    // 2. Load CropLands List
    final String? rawList = prefs.getString('crop_lands_v2');
    List<CropLand> tempCrops = [];
    if (rawList != null && rawList.trim().isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(rawList);
        tempCrops = jsonList.map((c) => CropLand.fromJson(c)).toList();
      } catch (e) {
        debugPrint("Error decoding crop lands: $e");
      }
    }

    setState(() {
      _totalLand = totalLand;
      _totalLandController.text = _totalLand == _totalLand.toInt() 
          ? _totalLand.toInt().toString() 
          : _totalLand.toString();
      _cropLandsList = tempCrops;
      _isLoading = false;
    });
  }

  // Persist state changes locally & sync with Firestore asynchronously
  Future<void> _persistStateData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('land_total', _totalLand);
    
    final String dataStr = jsonEncode(_cropLandsList.map((c) => c.toJson()).toList());
    await prefs.setString('crop_lands_v2', dataStr);

    // Sync variables with the original dashboard and user config so no breaking occurs
    await prefs.setDouble('land_crops', totalActiveCropsLand);
    await prefs.setDouble('land_orchards', totalActiveOrchardsLand);
    await prefs.setDouble('land_fallow', freeAcres);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'landArea': _totalLand.toStringAsFixed(1),
        'cropLandsRaw': dataStr,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Sync Error: $e");
    }
  }

  // Calculate stats
  List<CropLand> get activeCrops => _cropLandsList.where((c) => !c.isHarvested).toList();

  double get totalActiveCropsLand => activeCrops
      .where((c) => !c.isOrchard)
      .fold(0.0, (sum, item) => sum + item.acres);

  double get totalActiveOrchardsLand => activeCrops
      .where((c) => c.isOrchard)
      .fold(0.0, (sum, item) => sum + item.acres);

  double get freeAcres {
    final double activeSum = activeCrops.fold(0.0, (sum, item) => sum + item.acres);
    final double free = _totalLand - activeSum;
    return free < 0 ? 0.0 : free;
  }

  // Form Submission
  void _addCrop() {
    final String name = _cropNameController.text.trim();
    final double? acres = double.tryParse(_acresController.text.trim());

    if (name.isEmpty) {
      _showWarning(widget.isUrdu ? "برائے مہربانی فصل یا باغ کا نام لکھیں" : "Please enter a Crop/Orchard name!");
      return;
    }
    if (acres == null || acres <= 0) {
      _showWarning(widget.isUrdu ? "برائے مہربانی رقبہ کی درست مقدار لکھیں" : "Please enter a valid acres amount!");
      return;
    }

    final double available = freeAcres;
    if (acres > available) {
      final String urduMsg = "آپ کے پاس صرف ${available.toStringAsFixed(1)} ایکڑ خالی رقبہ دستیاب ہے۔ ٹھیک کریں!";
      final String engMsg = "Insufficient free land! Only ${available.toStringAsFixed(1)} acres available.";
      _showWarning(widget.isUrdu ? urduMsg : engMsg);
      return;
    }

    // Add new CropLand Entry
    final newCrop = CropLand(
      id: "crop_${DateTime.now().millisecondsSinceEpoch}",
      cropName: name,
      acres: acres,
      isOrchard: _isOrchard,
      cultivationType: _cultivationType,
      isHarvested: false,
      income: 0.0,
    );

    setState(() {
      _cropLandsList.add(newCrop);
      _cropNameController.clear();
      _acresController.clear();
      _isOrchard = false;
      _cultivationType = "Alag Alag";
    });

    _persistStateData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isUrdu ? "فصل کامیابی سے شامل کر دی گئی ہے!" : "Crop added successfully!",
          style: const TextStyle(fontFamily: 'NotoSerif'),
        ),
        backgroundColor: const Color(0xFF0F9D58),
      ),
    );
  }

  // Delete Crop Entry (Releases land)
  void _deleteCrop(String id) {
    setState(() {
      _cropLandsList.removeWhere((c) => c.id == id);
    });
    _persistStateData();
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDB4437),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF003527))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text(
          widget.isUrdu ? 'رقبہ اور کاشت مینجمنٹ' : 'Land & Crop Allocation',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003527),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Card Setup (Total Land Input)
              _buildTotalLandSetupCard(),
              const SizedBox(height: 16),

              // 2. Allocation Visualization Donut Chart
              _buildAllocationDonutChartCard(),
              const SizedBox(height: 16),

              // 3. Add Crop / Orchard Form
              _buildAddCropFormCard(),
              const SizedBox(height: 16),

              // 4. Currently Growing Crops List
              _buildGrowingCropsListCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalLandSetupCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.landscape, color: Color(0xFF003527), size: 28),
                const SizedBox(width: 8),
                Text(
                  widget.isUrdu ? 'میرا کل رقبہ (کل زمین)' : 'Land Account Setup',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003527)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalLandController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      hintText: widget.isUrdu ? 'کل زمین ایکڑ میں درج کریں' : 'Total Land in Acres',
                      prefixIcon: const Icon(Icons.line_weight_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      if (parsed >= 0) {
                        setState(() {
                          _totalLand = parsed;
                        });
                        _persistStateData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003527).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.isUrdu ? 'ایکڑ' : 'Acres',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003527)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isUrdu ? 'باقی رقبہ (اور کاشت کے لیے خالی ہے):' : 'Free Acres (Khali Raqba):',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${freeAcres.toStringAsFixed(1)} Akar",
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F9D58), fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationDonutChartCard() {
    final active = activeCrops;
    final double activeSum = active.fold(0.0, (sum, item) => sum + item.acres);
    final double free = freeAcres;

    List<PieChartSectionData> sections = [];
    
    // Add sections for each crop
    for (int i = 0; i < active.length; i++) {
      final crop = active[i];
      if (crop.acres > 0) {
        sections.add(
          PieChartSectionData(
            color: _chartColors[i % _chartColors.length],
            value: crop.acres,
            title: '${crop.acres.toStringAsFixed(0)}',
            radius: 40,
            showTitle: true,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      }
    }

    // Add section for free land
    if (free > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade200,
          value: free,
          title: free > 1 ? '${free.toStringAsFixed(0)}' : '',
          radius: 35,
          showTitle: free > 1,
          titleStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    }

    // If zero total land or anything, draw a dummy section to avoid crash and show nice empty space
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade100,
          value: 10,
          title: "",
          radius: 35,
          showTitle: false,
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.isUrdu ? 'زمین کی تقسیم کا نقشہ' : 'Donut Chart Visualization',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003527)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: sections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isUrdu ? 'کل رقبہ' : 'Total Acres',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _totalLand.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF003527)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Custom dynamic legends
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ...List.generate(active.length, (index) {
                  final crop = active[index];
                  final col = _chartColors[index % _chartColors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Icon(crop.isOrchard ? Icons.park : Icons.grass, size: 14, color: col),
                      const SizedBox(width: 4),
                      Text(
                        "${crop.cropName} (${crop.acres.toStringAsFixed(1)} Akar)",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                }),
                if (free > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.crop_free, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.isUrdu 
                            ? "خالی رقبہ (${free.toStringAsFixed(1)} Akar)" 
                            : "Free Land (${free.toStringAsFixed(1)} Acres)",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddCropFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isUrdu ? 'نئی فصل یا باغ شامل کریں' : 'Add New Crop / Orchard',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003527)),
            ),
            const SizedBox(height: 16),
            // Crop vs Orchard toggle chips
            Row(
              children: [
                Text(
                  widget.isUrdu ? "ٹائپ منتخب کریں:" : "Choose Type:",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(widget.isUrdu ? "فصل (Crop)" : "Crop (Fasal)"),
                  selected: !_isOrchard,
                  onSelected: (val) {
                    if (val) setState(() => _isOrchard = false);
                  },
                  selectedColor: const Color(0xFF003527).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: !_isOrchard ? const Color(0xFF003527) : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(widget.isUrdu ? "باغ (Orchard)" : "Orchard (Bagh)"),
                  selected: _isOrchard,
                  onSelected: (val) {
                    if (val) setState(() => _isOrchard = true);
                  },
                  selectedColor: const Color(0xFF003527).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _isOrchard ? const Color(0xFF003527) : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cropNameController,
              decoration: InputDecoration(
                hintText: _isOrchard 
                    ? (widget.isUrdu ? 'جیسے: آم کا باغ، کینو باغ' : 'e.g. Mango, Citrus')
                    : (widget.isUrdu ? 'جیسے: گندم، چاول، کپاس' : 'e.g. Wheat, Rice, Cotton'),
                labelText: widget.isUrdu ? 'نام لکھیں' : 'Name',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_isOrchard ? Icons.park : Icons.grass, color: const Color(0xFF003527)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _acresController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      hintText: widget.isUrdu ? 'درکار زمین (ایکڑ)' : 'Required Acres',
                      labelText: widget.isUrdu ? 'ایکڑ تعداد' : 'Acres',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cultivationType,
                    items: ["Alag Alag", "Mix"]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e == "Mix" ? "Intercropped (Mix)" : "Separate (Alag)"),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _cultivationType = val);
                    },
                    decoration: InputDecoration(
                      labelText: widget.isUrdu ? 'طریقہ کاشت' : 'Style',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addCrop,
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: Text(
                widget.isUrdu ? 'کاشت ریکارڈ کریں' : 'Save Growing Crop',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003527),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowingCropsListCard() {
    final active = activeCrops;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isUrdu ? 'میری موجودہ کاشتی فصلیں' : 'Currently Growing Crops',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003527)),
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  widget.isUrdu ? "ابھی تک کوئی فصل شامل نہیں کی گئی ہے۔" : "No active crops/orchards documented yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: active.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final crop = active[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: (crop.isOrchard ? const Color(0xFFF4B400) : const Color(0xFF0F9D58)).withOpacity(0.12),
                      child: Icon(
                        crop.isOrchard ? Icons.park : Icons.grass,
                        color: crop.isOrchard ? const Color(0xFFD48000) : const Color(0xFF0F9D58),
                      ),
                    ),
                    title: Text(
                      crop.cropName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      "${crop.acres.toStringAsFixed(1)} Akar • ${crop.cultivationType == 'Mix' ? 'Intercropped' : 'Separate'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Show nice confirmation first
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(widget.isUrdu ? "فصل ہٹائیں؟" : "Delete crop?"),
                            content: Text(widget.isUrdu
                                ? "کیا آپ واقعی '${crop.cropName}' کو ہٹانا چاہتے ہیں؟ اس سے متعلقہ رقبہ خالی ہو جائے گا۔"
                                : "Are you sure you want to remove '${crop.cropName}'? This will free up its land."),
                            actions: [
                              TextButton(
                                child: Text(widget.isUrdu ? "کینسل" : "Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: Text(widget.isUrdu ? "ہٹائیں" : "Remove", style: const TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteCrop(crop.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
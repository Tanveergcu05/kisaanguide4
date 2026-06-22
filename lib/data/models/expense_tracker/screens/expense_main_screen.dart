import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kisaanguide4/models/crop_land.dart';

// --- DATA MODELS ---
enum FarmType { baghaat, crops }
enum EntryType { expense, income }

class ZaraiRecord {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final EntryType type;
  final FarmType farmType;
  final String subType; // Crop or Orchard Name
  final String cropId; // Reference to CropLand ID

  ZaraiRecord({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
    required this.farmType,
    required this.subType,
    this.cropId = "",
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
      'farmType': farmType.name,
      'subType': subType,
      'cropId': cropId,
    };
  }

  static ZaraiRecord fromJson(Map<String, dynamic> json) {
    return ZaraiRecord(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 0,
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      note: (json['note'] ?? '').toString(),
      type: EntryType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'expense'),
        orElse: () => EntryType.expense,
      ),
      farmType: FarmType.values.firstWhere(
        (e) => e.name == (json['farmType'] ?? 'crops'),
        orElse: () => FarmType.crops,
      ),
      subType: (json['subType'] ?? '').toString(),
      cropId: (json['cropId'] ?? '').toString(),
    );
  }
}

class ExpenseMainScreen extends StatefulWidget {
  const ExpenseMainScreen({super.key});

  @override
  State<ExpenseMainScreen> createState() => _ExpenseMainScreenState();
}

class _ExpenseMainScreenState extends State<ExpenseMainScreen> {
  // Selection and State Variables
  EntryType selectedEntryType = EntryType.expense;
  DateTime selectedDate = DateTime.now();
  String searchQuery = "";
  
  // Custom Linked Crop Selection
  CropLand? selectedCropLink;

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Data Lists
  List<ZaraiRecord> recordsList = [];
  List<CropLand> cropLandsList = [];
  bool _isLoading = true;

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

  // Constants
  final List<String> expenseCategories = [
    'Seed & Nursery (Beej)',
    'Fertilizers (Khaad)',
    'Pesticides (Sprays)',
    'Labor (Mazdoori)',
    'Fuel & Machinery',
    'Irrigation (Paani)',
    'Land Lease (Theka)',
    'Multiple Kharcha',
    'Other Expense'
  ];

  final List<String> incomeCategories = [
    'Fasal Sale (Aamdani)',
    'Milk / Livestock (Aamdani)',
    'Subsidy / Support (Aamdani)',
    'Other Income'
  ];

  String? selectedExpenseCat;

  // Theme Colors
  final Color premiumDarkGreen = const Color(0xFF003527); 
  final Color premiumMidGreen = const Color(0xFFAC3400);

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return 'finance_records_v1_${uid ?? 'local'}';
  }

  @override
  void initState() {
    super.initState();
    _loadStateData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load both Finance Records and CropLands in unison
  Future<void> _loadStateData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Load CropLands List
    final String? rawCrops = prefs.getString('crop_lands_v2');
    List<CropLand> tempCrops = [];
    if (rawCrops != null && rawCrops.trim().isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(rawCrops);
        tempCrops = jsonList.map((c) => CropLand.fromJson(c)).toList();
      } catch (e) {
        debugPrint("Error loading crop lands in finance: $e");
      }
    }

    // 2. Load Finance Records List
    final rawFinance = prefs.getString(_storageKey);
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
    tempFinance.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      cropLandsList = tempCrops;
      recordsList = tempFinance;
      _isLoading = false;
    });
  }

  // Persist State to local store and synchronizing properties
  Future<void> _persistStateData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Save Finance Records
    final dataFinance = recordsList.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(dataFinance));

    // 2. Save CropLands
    final dataCrops = jsonEncode(cropLandsList.map((c) => c.toJson()).toList());
    await prefs.setString('crop_lands_v2', dataCrops);

    // Sync variables with standard values
    await prefs.setDouble('land_crops', totalActiveCropsLand);
    await prefs.setDouble('land_orchards', totalActiveOrchardsLand);
    await prefs.setDouble('land_fallow', freeAcres);
  }

  // Active growing crops (where isHarvested == false)
  List<CropLand> get activeCrops => cropLandsList.where((c) => !c.isHarvested).toList();

  double get totalActiveCropsLand => cropLandsList
      .where((c) => !c.isHarvested && !c.isOrchard)
      .fold(0.0, (sum, item) => sum + item.acres);

  double get totalActiveOrchardsLand => cropLandsList
      .where((c) => !c.isHarvested && c.isOrchard)
      .fold(0.0, (sum, item) => sum + item.acres);

  double get freeAcres {
    final double total = prefsLandTotal;
    final double activeSum = cropLandsList.where((c) => !c.isHarvested).fold(0.0, (sum, item) => sum + item.acres);
    final double free = total - activeSum;
    return free < 0 ? 0.0 : free;
  }

  double prefsLandTotal = 12.0;

  double get totalExpenses => recordsList
      .where((r) => r.type == EntryType.expense)
      .fold(0, (sum, item) => sum + item.amount);
  
  double get totalIncome => recordsList
      .where((r) => r.type == EntryType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get netProfit => totalIncome - totalExpenses;

  // Search filter
  List<ZaraiRecord> get filteredRecords {
    if (searchQuery.isEmpty) return recordsList;
    return recordsList.where((r) => 
      r.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
      r.subType.toLowerCase().contains(searchQuery.toLowerCase()) ||
      r.note.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // Addition of Entry: Handle dual-entry workflow
  void _saveEntry() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError("برائے مہربانی درست رقم درج کریں! (Please enter a valid amount)");
      return;
    }

    if (selectedCropLink == null) {
      _showError("برائے مہربانی فصل منتخب کریں! (Please select a Crop/Orchard)");
      return;
    }

    if (selectedEntryType == EntryType.expense && selectedExpenseCat == null) {
      _showError("برائے مہربانی کیٹیگری منتخب کریں! (Please select a category)");
      return;
    }

    // Capture detail values
    final String targetCropId = selectedCropLink!.id;
    final String targetCropName = selectedCropLink!.cropName;
    final bool orchardFlag = selectedCropLink!.isOrchard;

    if (selectedEntryType == EntryType.expense) {
      // 1) SAVE EXPENSE
      setState(() {
        recordsList.insert(0, ZaraiRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          category: selectedExpenseCat!,
          amount: amount,
          date: selectedDate,
          note: _noteController.text.trim(),
          type: EntryType.expense,
          farmType: orchardFlag ? FarmType.baghaat : FarmType.crops,
          subType: targetCropName,
          cropId: targetCropId,
        ));
        _amountController.clear();
        _noteController.clear();
        selectedCropLink = null;
        selectedExpenseCat = null;
      });

      _persistStateData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خرچہ کامیابی سے محفوظ ہوگیا! (Expense Saved Successfully)"),
          backgroundColor: Color(0xFF003527),
        ),
      );
    } else {
      // 2) HARVEST INCOME STATE TRANSITION
      // Complete state changes for the CropLand Entity
      setState(() {
        // Change CropLand attributes
        final idx = cropLandsList.indexWhere((c) => c.id == targetCropId);
        if (idx != -1) {
          final oldCrop = cropLandsList[idx];
          cropLandsList[idx] = CropLand(
            id: oldCrop.id,
            cropName: oldCrop.cropName,
            acres: oldCrop.acres,
            isOrchard: oldCrop.isOrchard,
            cultivationType: oldCrop.cultivationType,
            isHarvested: true,
            income: amount,
          );
        }

        // Save entry as income record
        recordsList.insert(0, ZaraiRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          category: 'Fasal Sale (Aamdani)',
          amount: amount,
          date: selectedDate,
          note: _noteController.text.isNotEmpty 
              ? _noteController.text.trim() 
              : "فصل کی کٹائی اور آمدنی کا اندراج",
          type: EntryType.income,
          farmType: orchardFlag ? FarmType.baghaat : FarmType.crops,
          subType: targetCropName,
          cropId: targetCropId,
        ));

        _amountController.clear();
        _noteController.clear();
        selectedCropLink = null;
        selectedExpenseCat = null;
      });

      _persistStateData();

      // Successful state alteration popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 50),
          title: const Text(
            "فصل کٹائی اور آمدنی مکمل!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "آمدنی کا کامیابی سے اندراج ہو گیا ہے۔ یہ فصل کٹائی ریکارڈ میں چلی گئی ہے اور اس کا رقبہ آزاد ہوکر کل رقبہ میں واپس شامل ہوگیا ہے!",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003527)),
                child: const Text("ٹھیک ہے (OK)", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      );
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent,
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

    final categories = selectedEntryType == EntryType.expense ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F6),
      appBar: AppBar(
        title: const Text("Khata Jaat & Amdani (Fasal)"),
        backgroundColor: premiumDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Clear all history',
            onPressed: recordsList.isEmpty ? null : _confirmClearAll,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("1. اندراج کا انتخاب (Kharcha vs Amdani)"),
            _buildEntryTypeToggle(),
            const SizedBox(height: 16),

            _buildSectionHeader("2. فارم کی تفصیلات (Detail Form)"),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // A. Linked Crop Selection Dropdown
                    DropdownButtonFormField<CropLand>(
                      value: selectedCropLink,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "فصل منتخب کریں (Select Active Crop)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grass_rounded, color: Colors.green),
                      ),
                      hint: const Text("کاشت شدہ فصل منتخب کریں"),
                      items: activeCrops.map((crop) {
                        return DropdownMenuItem<CropLand>(
                          value: crop,
                          child: Text(
                            "${crop.cropName} (${crop.acres.toStringAsFixed(1)} Akar) ${crop.isOrchard ? '• Bagh' : ''}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (CropLand? val) {
                        setState(() {
                          selectedCropLink = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // B. Category Dropdown
                    if (selectedEntryType == EntryType.expense) ...[
                      DropdownButtonFormField<String>(
                        value: selectedExpenseCat,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "کیٹیگری منتخب کریں (Select Category)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_rounded, color: Colors.indigo),
                        ),
                        hint: const Text("خرچے کی کیٹگری منتخب کریں"),
                        items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => selectedExpenseCat = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // C. Date picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "تاریخ (Date): ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: CircleAvatar(
                        backgroundColor: premiumMidGreen.withOpacity(0.1),
                        child: Icon(Icons.calendar_today, color: premiumMidGreen, size: 18),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // D. Amount (PKR) input
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedEntryType == EntryType.expense 
                            ? "خرچے کی رقم (Expense Amount Rs.)" 
                            : "فصل کی کل آمدنی (Final Sales Value Rs.)",
                        prefixText: "Rs. ",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.payments_rounded, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // E. Remarks / Note
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "کیسان نوٹ (Remarks/Tafseel)",
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sticky_note_2_rounded, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // F. Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveEntry,
                        icon: Icon(
                          selectedEntryType == EntryType.expense 
                              ? Icons.check_circle_outline 
                              : Icons.monetization_on_rounded, 
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedEntryType == EntryType.expense 
                              ? premiumDarkGreen 
                              : const Color(0xFF0F9D58), 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: Text(
                          selectedEntryType == EntryType.expense 
                              ? "خرچہ محفوظ کریں (Save Expense)" 
                              : "فصل کٹائی اور آمدنی درج کریں",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("3. موازنہ اور منافع (Agricultural Balance)"),
            _buildSummaryCard(),
            const SizedBox(height: 24),

            _buildSectionHeader("4. ہسٹری تلاش کریں (Search History)"),
            _buildSearchBar(),
            const SizedBox(height: 12),

            _buildSectionHeader("5. ریکارڈز کی مکمل تفصیلات (Full History)"),
            _buildHistoryTable(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: premiumDarkGreen),
      ),
    );
  }

  Widget _buildEntryTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pillButton(
              isActive: selectedEntryType == EntryType.expense,
              label: 'فصل کا خرچہ (Expense)',
              icon: Icons.remove_circle_outline_rounded,
              activeColor: Colors.redAccent,
              onTap: () {
                setState(() {
                  selectedEntryType = EntryType.expense;
                  selectedCropLink = null;
                  selectedExpenseCat = null;
                });
              },
            ),
          ),
          Expanded(
            child: _pillButton(
              isActive: selectedEntryType == EntryType.income,
              label: 'آمدنی اور کٹائی (Income)',
              icon: Icons.add_circle_outline_rounded,
              activeColor: Colors.green,
              onTap: () {
                setState(() {
                  selectedEntryType = EntryType.income;
                  selectedCropLink = null;
                  selectedExpenseCat = 'Fasal Sale (Aamdani)';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required bool isActive,
    required String label,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : Colors.black45),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isActive ? activeColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double total = totalIncome + totalExpenses;
    final double incomeShare = total == 0 ? 0 : (totalIncome / total);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [premiumDarkGreen, const Color(0xFF0D5E4A)]), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow("کل اخراجات (Total Expenses):", totalExpenses, Colors.redAccent.shade100),
          const Divider(color: Colors.white24),
          _summaryRow("کل آمدنی (Total Income):", totalIncome, Colors.greenAccent.shade100),
          const Divider(color: Colors.white24),
          _summaryRow("خالص منافع / نقصان (Profit):", netProfit, netProfit >= 0 ? Colors.greenAccent.shade400 : Colors.orangeAccent, isBold: true),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text("آمدنی بمقابلہ اخراجات کا گراف", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: incomeShare,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
        Text(_currency.format(val), style: TextStyle(color: color, fontSize: isBold ? 18 : 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => searchQuery = val),
      decoration: InputDecoration(
        hintText: "ہسٹری میں تلاش کریں (wheat, seed etc)...",
        prefixIcon: Icon(Icons.search, color: premiumDarkGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildHistoryTable() {
    final records = filteredRecords;
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text("کوئی ریکارڈ دستیاب نہیں ہے۔", style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('تاریخ')),
            DataColumn(label: Text('فصل کا نام')),
            DataColumn(label: Text('نوعیت')),
            DataColumn(label: Text('کل رقم')),
            DataColumn(label: Text('نوٹ (Kisaan Note)')),
            DataColumn(label: Text('عمل (Action)')),
          ],
          rows: records.map((r) => DataRow(cells: [
            DataCell(Text("${r.date.day}/${r.date.month}/${r.date.year}")),
            DataCell(Text(r.subType)),
            DataCell(Text(r.category)),
            DataCell(Text(
              _currency.format(r.amount),
              style: TextStyle(color: r.type == EntryType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            )),
            DataCell(SizedBox(width: 150, child: Text(r.note.isEmpty ? '-' : r.note, overflow: TextOverflow.ellipsis))),
            DataCell(
              IconButton(
                tooltip: 'Delete Entry',
                onPressed: () => _confirmDelete(r),
                icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
              ),
            ),
          ])).toList(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ZaraiRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ڈیلیٹ کریں؟'),
        content: Text('نام: ${record.subType}\nشرح: ${record.category}\nرقم: ${_currency.format(record.amount)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('کینسل')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ہٹائیں', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => recordsList.removeWhere((r) => r.id == record.id));
    _persistStateData();
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمام ریکارڈز صاف کریں؟'),
        content: const Text('کیا آپ واقعی اپنے تمام کھاتہ ریکارڈز صاف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں لیا جا سکتا۔'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('کینسل')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('صاف کریں', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => recordsList.clear());
    _persistStateData();
  }
}

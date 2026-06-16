import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final String subType;

  ZaraiRecord({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
    required this.farmType,
    required this.subType,
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
    );
  }
}

class ExpenseMainScreen extends StatefulWidget {
  const ExpenseMainScreen({super.key});

  @override
  State<ExpenseMainScreen> createState() => _ExpenseMainScreenState();
}

class _ExpenseMainScreenState extends State<ExpenseMainScreen> with TickerProviderStateMixin {
  // Selection States
  FarmType selectedType = FarmType.crops;
  String? selectedSubType; 
  String? selectedExpenseCat;
  EntryType selectedEntryType = EntryType.expense;
  DateTime selectedDate = DateTime.now();
  String searchQuery = "";
  
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _plantsController = TextEditingController(); 
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Data Lists
  List<ZaraiRecord> recordsList = [];

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

  // Constants
  final List<String> orchardTypes = [
    'Kinnow', 'Musami', 'Grapefruit', 'Meetha', 'Fruiter', 
    'Lemon', 'Sangtra', 'Aam (Mango)', 'Amrood (Guava)', 'Khajoor'
  ];

  final List<String> cropTypes = [
    'Gandum (Wheat)', 'Kapas (Cotton)', 'Makai (Maize)', 'Mongi (Mung Bean)', 
    'Kamad (Sugarcane)', 'Rice (Chawal)', 'Channy (Gram)', 'Jao (Barley)', 
    'Tilli (Sesame)', 'Bajra', 'Gwara', 'Canola', 'Sarson (Mustard)'
  ];

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

  // Premium Darker Green Theme Colors
  final Color premiumDarkGreen = const Color(0xFF1E5E3A); 
  final Color premiumMidGreen = const Color(0xFF2D8A4E);

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return 'finance_records_v1_${uid ?? 'local'}';
  }

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _areaController.dispose();
    _ageController.dispose();
    _plantsController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Calculations
  double get totalExpenses => recordsList
      .where((r) => r.type == EntryType.expense)
      .fold(0, (sum, item) => sum + item.amount);
  
  double get totalIncome => recordsList
      .where((r) => r.type == EntryType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get netProfit => totalIncome - totalExpenses;

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = decoded
          .whereType<Map>()
          .map((m) => ZaraiRecord.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      loaded.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() => recordsList = loaded);
    } catch (_) {
      // Ignore corrupt cache; user can continue with fresh data.
    }
  }

  Future<void> _persistRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = recordsList.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // Search Logic
  List<ZaraiRecord> get filteredRecords {
    if (searchQuery.isEmpty) return recordsList;
    return recordsList.where((r) => 
      r.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
      r.subType.toLowerCase().contains(searchQuery.toLowerCase()) ||
      r.note.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F6),
      appBar: AppBar(
        title: const Text("Zarai Expense Tracker"),
        backgroundColor: premiumDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Clear all',
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
            _buildSectionHeader("1. Type Select Karein"),
            _buildTypeToggle(),
            const SizedBox(height: 20),

            // --- ALL IN ONE COHESIVE ANIMATION BLOCK ---
            AnimatedSize(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("2. Detail Bharrein"),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOutCubic, // Sahi parameter fixed here
                    switchOutCurve: Curves.easeInOutCubic, // Sahi parameter fixed here
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.0, -0.1), 
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: selectedType == FarmType.baghaat
                        ? _buildFarmDetailCard(key: const ValueKey('baghaat_sync_view'))
                        : _buildFarmDetailCard(key: const ValueKey('crops_sync_view')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader("3. Kharcha / Aamdani Add Karein"),
            _buildEntryForm(),
            const SizedBox(height: 20),

            _buildSectionHeader("4. Summary (Profit/Loss)"),
            _buildSummaryCard(),
            const SizedBox(height: 25),

            _buildSectionHeader("5. Record Search Karein"),
            _buildSearchBar(),
            const SizedBox(height: 10),

            _buildSectionHeader("6. Mukammal History"),
            _buildHistoryTable(),
            const SizedBox(height: 50),
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: premiumDarkGreen),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Container(
          height: 54,
          width: width,
          padding: const EdgeInsets.all(4), 
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30), 
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic, 
                alignment: selectedType == FarmType.baghaat
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: (width - 8) / 2,
                  height: 46,
                  decoration: BoxDecoration(
                    color: premiumMidGreen, 
                    borderRadius: BorderRadius.circular(25), 
                    boxShadow: [
                      BoxShadow(
                        color: premiumMidGreen.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selectedType != FarmType.baghaat) {
                          setState(() {
                            selectedType = FarmType.baghaat;
                            selectedSubType = null;
                          });
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: selectedType == FarmType.baghaat ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: const Text("Baghaat"),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selectedType != FarmType.crops) {
                          setState(() {
                            selectedType = FarmType.crops;
                            selectedSubType = null;
                          });
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: selectedType == FarmType.crops ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: const Text("Faslein"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmDetailCard({required Key key}) {
    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedSubType,
              isExpanded: true,
              hint: const Text("Fasal ya Bagh ki Qism"),
              items: (selectedType == FarmType.baghaat ? orchardTypes : cropTypes)
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedSubType = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            if (selectedType == FarmType.baghaat) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Area (Acre)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _plantsController, 
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Podon ki Tadad", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Bagh ki Umar (Saal)", border: OutlineInputBorder()),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Area (Acre)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
    final categories = selectedEntryType == EntryType.expense ? expenseCategories : incomeCategories;
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEntryTypeToggle(),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Tareekh: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
              trailing: Icon(Icons.calendar_today, color: premiumMidGreen),
              onTap: () => _selectDate(context),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              isExpanded: true,
              hint: const Text("Category Chunrein"),
              value: categories.contains(selectedExpenseCat) ? selectedExpenseCat : null,
              items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedExpenseCat = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Raqam (PKR)", prefixText: "Rs. ", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Kisaan Note (Tafseel)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumMidGreen, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(selectedEntryType == EntryType.expense ? "Kharcha Save Karein" : "Aamdani Save Karein"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || selectedExpenseCat == null || selectedSubType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tamam fields bharrein!")));
      return;
    }

    setState(() {
      recordsList.insert(0, ZaraiRecord(
        id: '${DateTime.now().microsecondsSinceEpoch}_${recordsList.length}',
        category: selectedExpenseCat!,
        amount: amount,
        date: selectedDate,
        note: _noteController.text,
        type: selectedEntryType,
        farmType: selectedType,
        subType: selectedSubType!,
      ));
      _amountController.clear();
      _noteController.clear();
    });

    _persistRecords();
  }

  Widget _buildSummaryCard() {
    final double total = totalIncome + totalExpenses;
    final double incomeShare = total == 0 ? 0 : (totalIncome / total);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [premiumDarkGreen, premiumMidGreen]), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _summaryRow("Kul Kharcha:", totalExpenses, Colors.redAccent.shade100),
          const Divider(color: Colors.white24),
          _summaryRow("Kul Aamdani:", totalIncome, Colors.greenAccent.shade100),
          const Divider(color: Colors.white24),
          _summaryRow("Net Munafa:", netProfit, netProfit >= 0 ? Colors.greenAccent.shade400 : Colors.orangeAccent, isBold: true),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text("Income vs Expense", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
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
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        Text(_currency.format(val), style: TextStyle(color: color, fontSize: isBold ? 20 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => searchQuery = val),
      decoration: InputDecoration(
        hintText: "History mein talash karein...",
        prefixIcon: Icon(Icons.search, color: premiumMidGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildHistoryTable() {
    if (filteredRecords.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Koi record nahi mila.")));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Tareekh')),
            DataColumn(label: Text('Fasal/Bagh')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Raqam')),
            DataColumn(label: Text('Note')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filteredRecords.map((r) => DataRow(cells: [
            DataCell(Text("${r.date.day}/${r.date.month}/${r.date.year}")),
            DataCell(Text(r.subType)),
            DataCell(Text(r.category)),
            DataCell(Text(
              _currency.format(r.amount),
              style: TextStyle(color: r.type == EntryType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            )),
            DataCell(SizedBox(width: 180, child: Text(r.note.isEmpty ? '-' : r.note, overflow: TextOverflow.ellipsis))),
            DataCell(Row(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditDialog(r),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(r),
                  icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                ),
              ],
            )),
          ])).toList(),
        ),
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
              label: 'Kharcha',
              icon: Icons.remove_circle_outline_rounded,
              activeColor: Colors.redAccent,
              onTap: () {
                setState(() {
                  selectedEntryType = EntryType.expense;
                  selectedExpenseCat = null;
                });
              },
            ),
          ),
          Expanded(
            child: _pillButton(
              isActive: selectedEntryType == EntryType.income,
              label: 'Aamdani',
              icon: Icons.add_circle_outline_rounded,
              activeColor: Colors.green,
              onTap: () {
                setState(() {
                  selectedEntryType = EntryType.income;
                  selectedExpenseCat = null;
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
        duration: const Duration(milliseconds: 220),
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : Colors.black45),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ZaraiRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Category: ${record.category}\nAmount: ${_currency.format(record.amount)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => recordsList.removeWhere((r) => r.id == record.id));
    _persistRecords();
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all records?'),
        content: const Text('This will remove all saved finance records from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => recordsList.clear());
    _persistRecords();
  }

  Future<void> _openEditDialog(ZaraiRecord record) async {
    final amountController = TextEditingController(text: record.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: record.note);
    EntryType editType = record.type;
    DateTime editDate = record.date;
    String editCategory = record.category;

    final categoriesFor = (EntryType t) => t == EntryType.expense ? expenseCategories : incomeCategories;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final cats = categoriesFor(editType);
            return AlertDialog(
              title: const Text('Edit record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<EntryType>(
                            value: editType,
                            items: const [
                              DropdownMenuItem(value: EntryType.expense, child: Text('Kharcha')),
                              DropdownMenuItem(value: EntryType.income, child: Text('Aamdani')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setLocalState(() {
                                editType = v;
                                final newCats = categoriesFor(editType);
                                if (!newCats.contains(editCategory)) {
                                  editCategory = newCats.first;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2101),
                              );
                              if (picked == null) return;
                              setLocalState(() => editDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text("${editDate.day}/${editDate.month}/${editDate.year}"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: cats.contains(editCategory) ? editCategory : cats.first,
                      items: cats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setLocalState(() => editCategory = v ?? editCategory),
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs. ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      amountController.dispose();
      noteController.dispose();
      return;
    }

    final newAmount = double.tryParse(amountController.text.trim());
    if (newAmount == null || newAmount <= 0) {
      amountController.dispose();
      noteController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    setState(() {
      final idx = recordsList.indexWhere((r) => r.id == record.id);
      if (idx == -1) return;
      recordsList[idx] = ZaraiRecord(
        id: record.id,
        category: editCategory,
        amount: newAmount,
        date: editDate,
        note: noteController.text,
        type: editType,
        farmType: record.farmType,
        subType: record.subType,
      );
      recordsList.sort((a, b) => b.date.compareTo(a.date));
    });
    _persistRecords();

    amountController.dispose();
    noteController.dispose();
  }
}

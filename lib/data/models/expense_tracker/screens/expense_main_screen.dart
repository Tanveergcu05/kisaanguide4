import 'package:flutter/material.dart';

// --- DATA MODELS ---
enum FarmType { baghaat, crops }
enum EntryType { expense, income }

class ZaraiRecord {
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final EntryType type;
  final FarmType farmType;
  final String subType;

  ZaraiRecord({
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
    required this.farmType,
    required this.subType,
  });
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
    'Fasal Sale (Income/Aamdani)'
  ];

  // Premium Darker Green Theme Colors
  final Color premiumDarkGreen = const Color(0xFF1E5E3A); 
  final Color premiumMidGreen = const Color(0xFF2D8A4E);

  // Calculations
  double get totalExpenses => recordsList
      .where((r) => r.type == EntryType.expense)
      .fold(0, (sum, item) => sum + item.amount);
  
  double get totalIncome => recordsList
      .where((r) => r.type == EntryType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get netProfit => totalIncome - totalExpenses;

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
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
              items: expenseCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                child: const Text("Record Save Karein"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    if (_amountController.text.isEmpty || selectedExpenseCat == null || selectedSubType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tamam fields bharrein!")));
      return;
    }

    EntryType type = (selectedExpenseCat!.contains('Income') || selectedExpenseCat!.contains('Aamdani')) 
        ? EntryType.income 
        : EntryType.expense;

    setState(() {
      recordsList.insert(0, ZaraiRecord(
        category: selectedExpenseCat!,
        amount: double.parse(_amountController.text),
        date: selectedDate,
        note: _noteController.text,
        type: type,
        farmType: selectedType,
        subType: selectedSubType!,
      ));
      _amountController.clear();
      _noteController.clear();
    });
  }

  Widget _buildSummaryCard() {
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
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        Text("Rs. ${val.toStringAsFixed(0)}", style: TextStyle(color: color, fontSize: isBold ? 20 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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
          ],
          rows: filteredRecords.map((r) => DataRow(cells: [
            DataCell(Text("${r.date.day}/${r.date.month}")),
            DataCell(Text(r.subType)),
            DataCell(Text(r.category)),
            DataCell(Text("Rs. ${r.amount.toStringAsFixed(0)}", style: TextStyle(color: r.type == EntryType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
            DataCell(SizedBox(width: 100, child: Text(r.note, overflow: TextOverflow.ellipsis))),
          ])).toList(),
        ),
      ),
    );
  }
}
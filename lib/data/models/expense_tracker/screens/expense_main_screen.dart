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

class _ExpenseMainScreenState extends State<ExpenseMainScreen> {
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
  final TextEditingController _plantsController = TextEditingController(); // Naya controller
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
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Zarai Expense Tracker"),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("1. Type Select Karein"),
            _buildTypeToggle(),
            const SizedBox(height: 20),

            _buildSectionHeader("2. Detail Bharrein"),
            _buildFarmDetailCard(),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        _typeButton("Baghaat", FarmType.baghaat, const Color(0xFF52B788)),
        const SizedBox(width: 12),
        _typeButton("Faslein", FarmType.crops, const Color(0xFFBC6C25)),
      ],
    );
  }

  Widget _typeButton(String label, FarmType type, Color activeColor) {
    bool isSelected = selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
            selectedSubType = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildFarmDetailCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedSubType,
              isExpanded: true,
              hint: const Text("Fasal ya Bagh ki Qism"),
              items: (selectedType == FarmType.baghaat ? orchardTypes : cropTypes)
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedSubType = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
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
                if (selectedType == FarmType.baghaat) ...[
                  Expanded(
                    child: TextField(
                      controller: _plantsController, // Podon ki tadad ka field
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Podon ki Tadad", border: OutlineInputBorder()),
                    ),
                  ),
                ] else ...[
                   const Spacer(), // Faslein ke liye jagah khaali chhorne ke liye
                ]
              ],
            ),
            if (selectedType == FarmType.baghaat) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Bagh ki Umar (Saal)", border: OutlineInputBorder()),
              ),
            ]
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
              trailing: const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white),
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
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _summaryRow("Kul Kharcha:", totalExpenses, Colors.redAccent),
          const Divider(color: Colors.white24),
          _summaryRow("Kul Aamdani:", totalIncome, Colors.lightGreenAccent),
          const Divider(color: Colors.white24),
          _summaryRow("Net Munafa:", netProfit, netProfit >= 0 ? Colors.greenAccent : Colors.orangeAccent, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
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
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
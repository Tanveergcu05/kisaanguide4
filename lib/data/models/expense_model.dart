class ExpenseModel {
  final String id;
  final String title;     // Maslan: Khad, Diesel, Spray
  final double amount;    // Kitne paise lage
  final DateTime date;    // Kab kharcha hua
  final String category;  // Baag ke liye ya Fasal ke liye

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}
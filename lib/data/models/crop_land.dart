import 'dart:convert';

class CropLand {
  final String id;
  final String cropName;
  final double acres;
  final bool isOrchard;
  final String cultivationType; // "Alag Alag" or "Mix"
  bool isHarvested;
  double income;

  CropLand({
    required this.id,
    required this.cropName,
    required this.acres,
    required this.isOrchard,
    required this.cultivationType,
    this.isHarvested = false,
    this.income = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropName': cropName,
    'acres': acres,
    'isOrchard': isOrchard,
    'cultivationType': cultivationType,
    'isHarvested': isHarvested,
    'income': income,
  };

  factory CropLand.fromJson(Map<String, dynamic> json) {
    return CropLand(
      id: json['id'] ?? '',
      cropName: json['cropName'] ?? '',
      acres: (json['acres'] as num?)?.toDouble() ?? 0.0,
      isOrchard: json['isOrchard'] ?? false,
      cultivationType: json['cultivationType'] ?? 'Alag Alag',
      isHarvested: json['isHarvested'] ?? false,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
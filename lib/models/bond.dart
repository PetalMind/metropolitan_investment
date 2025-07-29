import 'package:cloud_firestore/cloud_firestore.dart';

class Bond {
  final String id;
  final String productType; // typ_produktu
  final double investmentAmount; // kwota_inwestycji
  final double realizedCapital; // kapital_zrealizowany
  final double remainingCapital; // kapital_pozostaly
  final double realizedInterest; // odsetki_zrealizowane
  final double remainingInterest; // odsetki_pozostale
  final double realizedTax; // podatek_zrealizowany
  final double remainingTax; // podatek_pozostaly
  final double transferToOtherProduct; // przekaz_na_inny_produkt
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at
  final Map<String, dynamic> additionalInfo;

  Bond({
    required this.id,
    required this.productType,
    required this.investmentAmount,
    this.realizedCapital = 0.0,
    this.remainingCapital = 0.0,
    this.realizedInterest = 0.0,
    this.remainingInterest = 0.0,
    this.realizedTax = 0.0,
    this.remainingTax = 0.0,
    this.transferToOtherProduct = 0.0,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    this.additionalInfo = const {},
  });

  // Calculated properties
  double get totalRealized => realizedCapital + realizedInterest;
  double get totalRemaining => remainingCapital + remainingInterest;
  double get totalValue => totalRealized + totalRemaining;
  double get profitLoss => totalValue - investmentAmount;
  double get profitLossPercentage =>
      investmentAmount > 0 ? (profitLoss / investmentAmount) * 100 : 0.0;

  factory Bond.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper function to parse date strings
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return Bond(
      id: doc.id,
      productType: data['typ_produktu'] ?? '',
      investmentAmount: safeToDouble(data['kwota_inwestycji']),
      realizedCapital: safeToDouble(data['kapital_zrealizowany']),
      remainingCapital: safeToDouble(data['kapital_pozostaly']),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      remainingInterest: safeToDouble(data['odsetki_pozostale']),
      realizedTax: safeToDouble(data['podatek_zrealizowany']),
      remainingTax: safeToDouble(data['podatek_pozostaly']),
      transferToOtherProduct: safeToDouble(data['przekaz_na_inny_produkt']),
      sourceFile: data['source_file'] ?? '',
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      uploadedAt: parseDate(data['uploaded_at']) ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere((key, value) => [
              'typ_produktu',
              'kwota_inwestycji',
              'kapital_zrealizowany',
              'kapital_pozostaly',
              'odsetki_zrealizowane',
              'odsetki_pozostale',
              'podatek_zrealizowany',
              'podatek_pozostaly',
              'przekaz_na_inny_produkt',
              'source_file',
              'created_at',
              'uploaded_at'
            ].contains(key)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'typ_produktu': productType,
      'kwota_inwestycji': investmentAmount,
      'kapital_zrealizowany': realizedCapital,
      'kapital_pozostaly': remainingCapital,
      'odsetki_zrealizowane': realizedInterest,
      'odsetki_pozostale': remainingInterest,
      'podatek_zrealizowany': realizedTax,
      'podatek_pozostaly': remainingTax,
      'przekaz_na_inny_produkt': transferToOtherProduct,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      ...additionalInfo,
    };
  }

  Bond copyWith({
    String? id,
    String? productType,
    double? investmentAmount,
    double? realizedCapital,
    double? remainingCapital,
    double? realizedInterest,
    double? remainingInterest,
    double? realizedTax,
    double? remainingTax,
    double? transferToOtherProduct,
    String? sourceFile,
    DateTime? createdAt,
    DateTime? uploadedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Bond(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      realizedCapital: realizedCapital ?? this.realizedCapital,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      realizedInterest: realizedInterest ?? this.realizedInterest,
      remainingInterest: remainingInterest ?? this.remainingInterest,
      realizedTax: realizedTax ?? this.realizedTax,
      remainingTax: remainingTax ?? this.remainingTax,
      transferToOtherProduct: transferToOtherProduct ?? this.transferToOtherProduct,
      sourceFile: sourceFile ?? this.sourceFile,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

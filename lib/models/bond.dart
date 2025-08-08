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
  final double? capitalForRestructuring; // kapital_do_restrukturyzacji
  final double?
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
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
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    this.additionalInfo = const {},
  });

  // Calculated properties - uwzględniamy tylko kapital_pozostaly
  double get totalRealized => realizedCapital + realizedInterest;
  double get totalRemaining => remainingCapital + remainingInterest;
  double get totalValue => remainingCapital; // tylko kapital_pozostaly
  double get profitLoss => 0.0; // nie uwzględniamy profit/loss
  double get profitLossPercentage => 0.0; // nie uwzględniamy performance

  factory Bond.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle comma-separated numbers like "305,700.00"
        final cleaned = value.replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
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
      productType: data['typ_produktu'] ?? data['Typ_produktu'] ?? 'Obligacje',
      investmentAmount: safeToDouble(
        data['kwota_inwestycji'] ?? data['Kwota_inwestycji'],
      ),
      realizedCapital: safeToDouble(
        data['kapital_zrealizowany'] ?? data['Kapital zrealizowany'],
      ),
      remainingCapital: safeToDouble(
        data['kapital_pozostaly'] ?? data['Kapital Pozostaly'],
      ),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      remainingInterest: safeToDouble(data['odsetki_pozostale']),
      realizedTax: safeToDouble(data['podatek_zrealizowany']),
      remainingTax: safeToDouble(data['podatek_pozostaly']),
      transferToOtherProduct: safeToDouble(
        data['przekaz_na_inny_produkt'] ?? data['Przekaz na inny produkt'],
      ),
      capitalForRestructuring: safeToDouble(
        data['kapital_do_restrukturyzacji'],
      ),
      capitalSecuredByRealEstate: safeToDouble(
        data['kapital_zabezpieczony_nieruchomoscia'],
      ),
      sourceFile: data['source_file'] ?? 'imported_data.json',
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      uploadedAt: parseDate(data['uploaded_at']) ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'typ_produktu',
            'Typ_produktu',
            'kwota_inwestycji',
            'Kwota_inwestycji',
            'kapital_zrealizowany',
            'Kapital zrealizowany',
            'kapital_pozostaly',
            'Kapital Pozostaly',
            'odsetki_zrealizowane',
            'odsetki_pozostale',
            'podatek_zrealizowany',
            'podatek_pozostaly',
            'przekaz_na_inny_produkt',
            'Przekaz na inny produkt',
            'kapital_do_restrukturyzacji',
            'kapital_zabezpieczony_nieruchomoscia',
            'source_file',
            'created_at',
            'uploaded_at',
          ].contains(key),
        ),
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
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
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
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
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
      transferToOtherProduct:
          transferToOtherProduct ?? this.transferToOtherProduct,
      capitalForRestructuring:
          capitalForRestructuring ?? this.capitalForRestructuring,
      capitalSecuredByRealEstate:
          capitalSecuredByRealEstate ?? this.capitalSecuredByRealEstate,
      sourceFile: sourceFile ?? this.sourceFile,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

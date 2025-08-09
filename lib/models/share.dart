import 'package:cloud_firestore/cloud_firestore.dart';

class Share {
  final String id;
  final String productType; // typ_produktu
  final double investmentAmount; // kwota_inwestycji
  final int sharesCount; // ilosc_udzialow
  final double remainingCapital; // kapital_pozostaly
  final double? capitalForRestructuring; // kapital_do_restrukturyzacji
  final double?
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at
  final Map<String, dynamic> additionalInfo;

  Share({
    required this.id,
    required this.productType,
    required this.investmentAmount,
    this.sharesCount = 0,
    this.remainingCapital = 0.0,
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    this.additionalInfo = const {},
  });

  // Calculated properties
  double get pricePerShare =>
      sharesCount > 0 ? investmentAmount / sharesCount : 0.0;
  double get totalValue => remainingCapital;

  factory Share.fromFirestore(DocumentSnapshot doc) {
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

    // Helper function to safely convert to int
    int safeToInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
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

    return Share(
      id: doc.id,
      productType: data['typ_produktu'] ?? data['Typ_produktu'] ?? 'Udziały',
      investmentAmount: safeToDouble(
        data['kwota_inwestycji'] ?? data['Kwota_inwestycji'],
      ),
      sharesCount: safeToInt(data['ilosc_udzialow'] ?? data['Ilosc_Udzialow']),
      remainingCapital: safeToDouble(
        data['kapital_pozostaly'] ?? data['Kapital Pozostaly'],
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
            'ilosc_udzialow',
            'Ilosc_Udzialow',
            'kapital_pozostaly',
            'Kapital Pozostaly',
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
      'Typ_produktu': productType,
      'Kwota_inwestycji': investmentAmount,
      'Ilosc_Udzialow': sharesCount,
      'Kapital Pozostaly': remainingCapital,
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      ...additionalInfo,
    };
  }

  Share copyWith({
    String? id,
    String? productType,
    double? investmentAmount,
    int? sharesCount,
    double? remainingCapital,
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
    String? sourceFile,
    DateTime? createdAt,
    DateTime? uploadedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Share(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      sharesCount: sharesCount ?? this.sharesCount,
      remainingCapital: remainingCapital ?? this.remainingCapital,
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

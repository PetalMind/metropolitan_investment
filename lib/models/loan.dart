import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String productType; // typ_produktu
  final double investmentAmount; // kwota_inwestycji
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at
  final Map<String, dynamic> additionalInfo;

  Loan({
    required this.id,
    required this.productType,
    required this.investmentAmount,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    this.additionalInfo = const {},
  });

  factory Loan.fromFirestore(DocumentSnapshot doc) {
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

    return Loan(
      id: doc.id,
      productType: data['typ_produktu'] ?? '',
      investmentAmount: safeToDouble(data['kwota_inwestycji']),
      sourceFile: data['source_file'] ?? '',
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      uploadedAt: parseDate(data['uploaded_at']) ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere((key, value) => [
              'typ_produktu',
              'kwota_inwestycji',
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
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      ...additionalInfo,
    };
  }

  Loan copyWith({
    String? id,
    String? productType,
    double? investmentAmount,
    String? sourceFile,
    DateTime? createdAt,
    DateTime? uploadedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Loan(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      sourceFile: sourceFile ?? this.sourceFile,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String productType; // typ_produktu
  final double investmentAmount; // kwota_inwestycji
  final double remainingCapital; // kapital_pozostaly
  final double? capitalForRestructuring; // kapital_do_restrukturyzacji
  final double?
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at

  // Loan specific fields from Firebase
  final String? loanNumber; // pozyczka_numer
  final String? borrower; // pozyczkobiorca
  final String? creditorCompany; // wierzyciel_spolka
  final String? interestRate; // oprocentowanie
  final DateTime? disbursementDate; // data_udzielenia
  final DateTime? repaymentDate; // data_splaty
  final double accruedInterest; // odsetki_naliczone
  final String? collateral; // zabezpieczenie
  final String? status; // status

  final Map<String, dynamic> additionalInfo;

  Loan({
    required this.id,
    required this.productType,
    this.investmentAmount = 0.0,
    this.remainingCapital = 0.0,
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    this.loanNumber,
    this.borrower,
    this.creditorCompany,
    this.interestRate,
    this.disbursementDate,
    this.repaymentDate,
    this.accruedInterest = 0.0,
    this.collateral,
    this.status,
    this.additionalInfo = const {},
  });

  // Calculated properties
  double get totalValue => remainingCapital;

  factory Loan.fromFirestore(DocumentSnapshot doc) {
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

    // Helper function to parse date strings with multiple formats
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == 'NULL') return null;
      try {
        // Handle different date formats
        if (dateStr.contains('-')) {
          // ISO format like "2018-08-29 00:00:00"
          return DateTime.parse(dateStr.split(' ')[0]);
        } else if (dateStr.contains('/')) {
          // Format like "9/18/18" or "3/18/20"
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final month = int.parse(parts[0]);
            final day = int.parse(parts[1]);
            var year = int.parse(parts[2]);

            // Convert 2-digit year to 4-digit
            if (year < 100) {
              year += year < 30 ? 2000 : 1900;
            }

            return DateTime(year, month, day);
          }
        }
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $dateStr - $e');
        return null;
      }
    }

    return Loan(
      id: doc.id,
      productType: data['typ_produktu'] ?? data['Typ_produktu'] ?? 'Pożyczki',
      investmentAmount: safeToDouble(
        data['kwota_inwestycji'] ?? data['Kwota_inwestycji'],
      ),
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

      // Loan specific fields
      loanNumber: data['pozyczka_numer'],
      borrower: data['pozyczkobiorca'],
      creditorCompany: data['wierzyciel_spolka'],
      interestRate: data['oprocentowanie'],
      disbursementDate: parseDate(data['data_udzielenia']),
      repaymentDate: parseDate(data['data_splaty']),
      accruedInterest: safeToDouble(data['odsetki_naliczone']),
      collateral: data['zabezpieczenie'],
      status: data['status'],

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'typ_produktu',
            'Typ_produktu',
            'kwota_inwestycji',
            'Kwota_inwestycji',
            'kapital_pozostaly',
            'Kapital Pozostaly',
            'kapital_do_restrukturyzacji',
            'kapital_zabezpieczony_nieruchomoscia',
            'source_file',
            'created_at',
            'uploaded_at',
            'pozyczka_numer',
            'pozyczkobiorca',
            'wierzyciel_spolka',
            'oprocentowanie',
            'data_udzielenia',
            'data_splaty',
            'odsetki_naliczone',
            'zabezpieczenie',
            'status',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'typ_produktu': productType,
      'kwota_inwestycji': investmentAmount,
      'kapital_pozostaly': remainingCapital,
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),

      // Loan specific fields
      'pozyczka_numer': loanNumber,
      'pozyczkobiorca': borrower,
      'wierzyciel_spolka': creditorCompany,
      'oprocentowanie': interestRate,
      'data_udzielenia': disbursementDate?.toIso8601String(),
      'data_splaty': repaymentDate?.toIso8601String(),
      'odsetki_naliczone': accruedInterest,
      'zabezpieczenie': collateral,
      'status': status,

      ...additionalInfo,
    };
  }

  Loan copyWith({
    String? id,
    String? productType,
    double? investmentAmount,
    double? remainingCapital,
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
    String? sourceFile,
    DateTime? createdAt,
    DateTime? uploadedAt,
    String? loanNumber,
    String? borrower,
    String? interestRate,
    DateTime? disbursementDate,
    DateTime? repaymentDate,
    double? accruedInterest,
    String? collateral,
    String? status,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Loan(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      capitalForRestructuring:
          capitalForRestructuring ?? this.capitalForRestructuring,
      capitalSecuredByRealEstate:
          capitalSecuredByRealEstate ?? this.capitalSecuredByRealEstate,
      sourceFile: sourceFile ?? this.sourceFile,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      loanNumber: loanNumber ?? this.loanNumber,
      borrower: borrower ?? this.borrower,
      interestRate: interestRate ?? this.interestRate,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      accruedInterest: accruedInterest ?? this.accruedInterest,
      collateral: collateral ?? this.collateral,
      status: status ?? this.status,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

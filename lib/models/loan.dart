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

  // Client identification fields
  final String? clientId; // ID_Klient (Excel numeryczne ID)
  final String? clientName; // Klient (nazwa klienta)

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
    this.clientId,
    this.clientName,
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
      productType:
          data['productType'] ??
          data['typ_produktu'] ??
          data['Typ_produktu'] ??
          'Pożyczki',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ??
            data['kwota_inwestycji'] ??
            data['Kwota_inwestycji'],
      ),
      remainingCapital: safeToDouble(
        data['remainingCapital'] ??
            data['kapital_pozostaly'] ??
            data['Kapital Pozostaly'],
      ),
      capitalForRestructuring: safeToDouble(
        data['capitalForRestructuring'] ?? data['kapital_do_restrukturyzacji'],
      ),
      capitalSecuredByRealEstate: safeToDouble(
        data['realEstateSecuredCapital'] ??
            data['kapital_zabezpieczony_nieruchomoscia'],
      ),
      sourceFile:
          data['sourceFile'] ?? data['source_file'] ?? 'imported_data.json',
      createdAt:
          parseDate(data['createdAt']) ??
          parseDate(data['created_at']) ??
          DateTime.now(),
      uploadedAt:
          parseDate(data['uploadedAt']) ??
          parseDate(data['uploaded_at']) ??
          DateTime.now(),

      // Client identification fields
      clientId: data['clientId'] ?? data['ID_Klient'],
      clientName: data['clientName'] ?? data['Klient'],

      // Loan specific fields
      loanNumber: data['loanNumber'] ?? data['pozyczka_numer'],
      borrower: data['borrower'] ?? data['pozyczkobiorca'],
      creditorCompany: data['creditorCompany'] ?? data['wierzyciel_spolka'],
      interestRate: data['interestRate'] ?? data['oprocentowanie'],
      disbursementDate: parseDate(
        data['disbursementDate'] ?? data['data_udzielenia'],
      ),
      repaymentDate: parseDate(data['repaymentDate'] ?? data['data_splaty']),
      accruedInterest: safeToDouble(
        data['accruedInterest'] ?? data['odsetki_naliczone'],
      ),
      collateral: data['collateral'] ?? data['zabezpieczenie'],
      status: data['status'],

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'productType',
            'typ_produktu',
            'Typ_produktu',
            'investmentAmount',
            'kwota_inwestycji',
            'Kwota_inwestycji',
            'remainingCapital',
            'kapital_pozostaly',
            'Kapital Pozostaly',
            'capitalForRestructuring',
            'kapital_do_restrukturyzacji',
            'realEstateSecuredCapital',
            'kapital_zabezpieczony_nieruchomoscia',
            'sourceFile',
            'source_file',
            'createdAt',
            'created_at',
            'uploadedAt',
            'uploaded_at',
            'clientId',
            'ID_Klient',
            'clientName',
            'Klient',
            'loanNumber',
            'pozyczka_numer',
            'borrower',
            'pozyczkobiorca',
            'creditorCompany',
            'wierzyciel_spolka',
            'interestRate',
            'oprocentowanie',
            'disbursementDate',
            'data_udzielenia',
            'repaymentDate',
            'data_splaty',
            'accruedInterest',
            'odsetki_naliczone',
            'collateral',
            'zabezpieczenie',
            'status',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // Znormalizowane nazwy (priorytet)
      'productType': productType,
      'investmentAmount': investmentAmount,
      'remainingCapital': remainingCapital,
      'capitalForRestructuring': capitalForRestructuring,
      'realEstateSecuredCapital': capitalSecuredByRealEstate,
      'sourceFile': sourceFile,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'clientId': clientId,
      'clientName': clientName,
      'loanNumber': loanNumber,
      'borrower': borrower,
      'creditorCompany': creditorCompany,
      'interestRate': interestRate,
      'disbursementDate': disbursementDate?.toIso8601String(),
      'repaymentDate': repaymentDate?.toIso8601String(),
      'accruedInterest': accruedInterest,
      'collateral': collateral,
      'status': status,

      // Stare nazwy dla kompatybilności wstecznej
      'typ_produktu': productType,
      'kwota_inwestycji': investmentAmount,
      'kapital_pozostaly': remainingCapital,
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      'ID_Klient': clientId,
      'Klient': clientName,
      'pozyczka_numer': loanNumber,
      'pozyczkobiorca': borrower,
      'wierzyciel_spolka': creditorCompany,
      'oprocentowanie': interestRate,
      'data_udzielenia': disbursementDate?.toIso8601String(),
      'data_splaty': repaymentDate?.toIso8601String(),
      'odsetki_naliczone': accruedInterest,
      'zabezpieczenie': collateral,

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

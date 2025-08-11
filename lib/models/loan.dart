import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String productType;
  final double investmentAmount;
  final double remainingCapital;
  final double? capitalForRestructuring;
  final double? capitalSecuredByRealEstate;
  final String sourceFile;
  final DateTime createdAt;
  final DateTime uploadedAt;

  // Client and transaction info
  final String? clientId;
  final String? clientName;
  final String? companyId;
  final String? salesId;
  final double? paymentAmount;
  final String? branch;
  final String? advisor;
  final String? productName;
  final String? productStatusEntry;
  final String? productStatus;
  final DateTime? signedDate;
  final DateTime? investmentEntryDate;
  final DateTime? issueDate;
  final DateTime? maturityDate;

  // Loan specific fields
  final String? loanNumber;
  final String? borrower;
  final String? creditorCompany;
  final String? interestRate;
  final DateTime? disbursementDate;
  final DateTime? repaymentDate;
  final double accruedInterest;
  final String? collateral;
  final String? status;

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
    this.companyId,
    this.salesId,
    this.paymentAmount,
    this.branch,
    this.advisor,
    this.productName,
    this.productStatusEntry,
    this.productStatus,
    this.signedDate,
    this.investmentEntryDate,
    this.issueDate,
    this.maturityDate,
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
      productType: data['productType'] ?? data['Typ_produktu'] ?? 'Pożyczka',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ?? data['Kwota_inwestycji'],
      ),
      remainingCapital: safeToDouble(
        data['remainingCapital'] ?? data['Kapital Pozostaly'],
      ),
      capitalForRestructuring: safeToDouble(
        data['capitalForRestructuring'] ?? data['Kapitał do restrukturyzacji'],
      ),
      capitalSecuredByRealEstate: safeToDouble(
        data['capitalSecuredByRealEstate'] ??
            data['Kapitał zabezpieczony nieruchomością'],
      ),
      sourceFile:
          data['sourceFile'] ?? data['source_file'] ?? 'imported_data.json',
      createdAt:
          parseDate(data['createdAt'] ?? data['created_at']) ?? DateTime.now(),
      uploadedAt:
          parseDate(data['uploadedAt'] ?? data['uploaded_at']) ??
          DateTime.now(),

      // Client and transaction info
      clientId: data['clientId'] ?? data['ID_Klient'],
      clientName: data['clientName'] ?? data['Klient'],
      companyId: data['companyId'] ?? data['ID_Spolka'],
      salesId: data['salesId'] ?? data['ID_Sprzedaz'],
      paymentAmount: safeToDouble(data['paymentAmount'] ?? data['Kwota_wplat']),
      branch: data['branch'] ?? data['Oddzial'],
      advisor: data['advisor'] ?? data['Opiekun z MISA'],
      productName: data['productName'] ?? data['Produkt_nazwa'],
      productStatusEntry:
          data['productStatusEntry'] ?? data['Produkt_status_wejscie'],
      productStatus: data['productStatus'] ?? data['Status_produktu'],
      signedDate: parseDate(data['signedDate'] ?? data['Data_podpisania']),
      investmentEntryDate: parseDate(
        data['investmentEntryDate'] ?? data['Data_wejscia_do_inwestycji'],
      ),
      issueDate: parseDate(data['issueDate'] ?? data['data_emisji']),
      maturityDate: parseDate(data['maturityDate'] ?? data['data_wykupu']),

      // Loan specific fields
      loanNumber: data['loanNumber'] ?? data['pozyczka_numer'],
      borrower: data['borrower'] ?? data['pozyczkobiorca'] ?? data['Klient'],
      creditorCompany: data['creditorCompany'] ?? data['wierzyciel_spolka'],
      interestRate: data['interestRate'] ?? data['oprocentowanie'],
      disbursementDate: parseDate(
        data['disbursementDate'] ??
            data['data_udzielenia'] ??
            data['Data_wejscia_do_inwestycji'],
      ),
      repaymentDate: parseDate(
        data['repaymentDate'] ?? data['data_splaty'] ?? data['data_wykupu'],
      ),
      accruedInterest: safeToDouble(
        data['accruedInterest'] ?? data['odsetki_naliczone'],
      ),
      collateral: data['collateral'] ?? data['zabezpieczenie'],
      status: data['status'] ?? data['Status_produktu'],

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            // English field names
            'productType',
            'investmentAmount',
            'remainingCapital',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt',
            'uploadedAt',
            'clientId', 'clientName', 'companyId', 'salesId', 'paymentAmount',
            'branch',
            'advisor',
            'productName',
            'productStatusEntry',
            'productStatus',
            'signedDate', 'investmentEntryDate', 'issueDate', 'maturityDate',
            'loanNumber', 'borrower', 'creditorCompany', 'interestRate',
            'disbursementDate',
            'repaymentDate',
            'accruedInterest',
            'collateral',
            'status',
            // Polish field names (legacy)
            'Typ_produktu',
            'typ_produktu',
            'Kwota_inwestycji',
            'kwota_inwestycji',
            'Kapital Pozostaly',
            'kapital_pozostaly',
            'Kapitał do restrukturyzacji',
            'kapital_do_restrukturyzacji',
            'Kapitał zabezpieczony nieruchomością',
            'kapital_zabezpieczony_nieruchomoscia',
            'source_file',
            'created_at',
            'uploaded_at',
            'ID_Klient', 'Klient', 'ID_Spolka', 'ID_Sprzedaz', 'Kwota_wplat',
            'Oddzial',
            'Opiekun z MISA',
            'Produkt_nazwa',
            'Produkt_status_wejscie',
            'Status_produktu', 'Data_podpisania', 'Data_wejscia_do_inwestycji',
            'data_emisji', 'data_wykupu', 'pozyczka_numer', 'pozyczkobiorca',
            'wierzyciel_spolka',
            'oprocentowanie',
            'data_udzielenia',
            'data_splaty',
            'odsetki_naliczone', 'zabezpieczenie',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productType': productType,
      'investmentAmount': investmentAmount,
      'remainingCapital': remainingCapital,
      'capitalForRestructuring': capitalForRestructuring,
      'capitalSecuredByRealEstate': capitalSecuredByRealEstate,
      'sourceFile': sourceFile,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'clientId': clientId,
      'clientName': clientName,
      'companyId': companyId,
      'salesId': salesId,
      'paymentAmount': paymentAmount,
      'branch': branch,
      'advisor': advisor,
      'productName': productName,
      'productStatusEntry': productStatusEntry,
      'productStatus': productStatus,
      'signedDate': signedDate?.toIso8601String(),
      'investmentEntryDate': investmentEntryDate?.toIso8601String(),
      'issueDate': issueDate?.toIso8601String(),
      'maturityDate': maturityDate?.toIso8601String(),
      'loanNumber': loanNumber,
      'borrower': borrower,
      'creditorCompany': creditorCompany,
      'interestRate': interestRate,
      'disbursementDate': disbursementDate?.toIso8601String(),
      'repaymentDate': repaymentDate?.toIso8601String(),
      'accruedInterest': accruedInterest,
      'collateral': collateral,
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
    String? clientId,
    String? clientName,
    String? companyId,
    String? salesId,
    double? paymentAmount,
    String? branch,
    String? advisor,
    String? productName,
    String? productStatusEntry,
    String? productStatus,
    DateTime? signedDate,
    DateTime? investmentEntryDate,
    DateTime? issueDate,
    DateTime? maturityDate,
    String? loanNumber,
    String? borrower,
    String? creditorCompany,
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
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      companyId: companyId ?? this.companyId,
      salesId: salesId ?? this.salesId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      branch: branch ?? this.branch,
      advisor: advisor ?? this.advisor,
      productName: productName ?? this.productName,
      productStatusEntry: productStatusEntry ?? this.productStatusEntry,
      productStatus: productStatus ?? this.productStatus,
      signedDate: signedDate ?? this.signedDate,
      investmentEntryDate: investmentEntryDate ?? this.investmentEntryDate,
      issueDate: issueDate ?? this.issueDate,
      maturityDate: maturityDate ?? this.maturityDate,
      loanNumber: loanNumber ?? this.loanNumber,
      borrower: borrower ?? this.borrower,
      creditorCompany: creditorCompany ?? this.creditorCompany,
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

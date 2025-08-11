import 'package:cloud_firestore/cloud_firestore.dart';

class Share {
  final String id;
  final String productType;
  final double investmentAmount;
  final int sharesCount;
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

    return Share(
      id: doc.id,
      productType: data['productType'] ?? data['Typ_produktu'] ?? 'Udziały',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ?? data['Kwota_inwestycji'],
      ),
      sharesCount: safeToInt(data['sharesCount'] ?? data['Ilosc_Udzialow']),
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
      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            // English field names
            'productType',
            'investmentAmount',
            'sharesCount',
            'remainingCapital',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile',
            'createdAt', 'uploadedAt', 'clientId', 'clientName', 'companyId',
            'salesId', 'paymentAmount', 'branch', 'advisor', 'productName',
            'productStatusEntry',
            'productStatus',
            'signedDate',
            'investmentEntryDate',
            'issueDate', 'maturityDate',
            // Polish field names (legacy)
            'Typ_produktu',
            'typ_produktu',
            'Kwota_inwestycji',
            'kwota_inwestycji',
            'Ilosc_Udzialow',
            'ilosc_udzialow',
            'Kapital Pozostaly',
            'kapital_pozostaly',
            'Kapitał do restrukturyzacji', 'kapital_do_restrukturyzacji',
            'Kapitał zabezpieczony nieruchomością',
            'kapital_zabezpieczony_nieruchomoscia',
            'source_file', 'created_at', 'uploaded_at', 'ID_Klient', 'Klient',
            'ID_Spolka',
            'ID_Sprzedaz',
            'Kwota_wplat',
            'Oddzial',
            'Opiekun z MISA',
            'Produkt_nazwa', 'Produkt_status_wejscie', 'Status_produktu',
            'Data_podpisania',
            'Data_wejscia_do_inwestycji',
            'data_emisji',
            'data_wykupu',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productType': productType,
      'investmentAmount': investmentAmount,
      'sharesCount': sharesCount,
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
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

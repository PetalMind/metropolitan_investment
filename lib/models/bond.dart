import 'package:cloud_firestore/cloud_firestore.dart';

class Bond {
  final String id;
  final String productType;
  final double investmentAmount;
  final double realizedCapital;
  final double remainingCapital;
  final double realizedInterest;
  final double remainingInterest;
  final double realizedTax;
  final double remainingTax;
  final double transferToOtherProduct;
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
  final int? sharesCount;
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
  final DateTime? redemptionDate;
  final String? interestRate;

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
    this.clientId,
    this.clientName,
    this.companyId,
    this.salesId,
    this.sharesCount,
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
    this.redemptionDate,
    this.interestRate,
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

    // Helper function to safely convert string to int
    int? safeToIntNullable(dynamic value) {
      if (value == null || value == 'NULL') return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String && value.isNotEmpty && value != 'NULL') {
        return int.tryParse(value);
      }
      return null;
    }

    return Bond(
      id: doc.id,
      productType: data['productType'] ?? data['Typ_produktu'] ?? 'Obligacje',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ?? data['Kwota_inwestycji'],
      ),
      realizedCapital: safeToDouble(
        data['realizedCapital'] ?? data['Kapital zrealizowany'],
      ),
      remainingCapital: safeToDouble(
        data['remainingCapital'] ?? data['Kapital Pozostaly'],
      ),
      realizedInterest: safeToDouble(
        data['realizedInterest'] ?? data['odsetki_zrealizowane'],
      ),
      remainingInterest: safeToDouble(
        data['remainingInterest'] ?? data['odsetki_pozostale'],
      ),
      realizedTax: safeToDouble(
        data['realizedTax'] ?? data['podatek_zrealizowany'],
      ),
      remainingTax: safeToDouble(
        data['remainingTax'] ?? data['podatek_pozostaly'],
      ),
      transferToOtherProduct: safeToDouble(
        data['transferToOtherProduct'] ?? data['Przekaz na inny produkt'],
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
      sharesCount: safeToIntNullable(
        data['sharesCount'] ?? data['Ilosc_Udzialow'],
      ),
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
      maturityDate: parseDate(
        data['maturityDate'] ?? data['data_splaty'] ?? data['data_wykupu'],
      ),
      redemptionDate: parseDate(data['redemptionDate'] ?? data['data_wykupu']),
      interestRate: data['interestRate'] ?? data['oprocentowanie'],

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            // English field names
            'productType',
            'investmentAmount',
            'realizedCapital',
            'remainingCapital',
            'realizedInterest',
            'remainingInterest',
            'realizedTax',
            'remainingTax',
            'transferToOtherProduct',
            'capitalForRestructuring',
            'capitalSecuredByRealEstate',
            'sourceFile', 'createdAt', 'uploadedAt', 'clientId', 'clientName',
            'companyId', 'salesId', 'sharesCount', 'paymentAmount', 'branch',
            'advisor', 'productName', 'productStatusEntry', 'productStatus',
            'signedDate', 'investmentEntryDate', 'issueDate', 'maturityDate',
            'redemptionDate', 'interestRate',
            // Polish field names (legacy)
            'Typ_produktu',
            'typ_produktu',
            'Kwota_inwestycji',
            'kwota_inwestycji',
            'Kapital zrealizowany',
            'kapital_zrealizowany',
            'Kapital Pozostaly',
            'kapital_pozostaly',
            'odsetki_zrealizowane',
            'odsetki_pozostale',
            'podatek_zrealizowany',
            'podatek_pozostaly',
            'Przekaz na inny produkt',
            'przekaz_na_inny_produkt',
            'Kapitał do restrukturyzacji',
            'kapital_do_restrukturyzacji',
            'Kapitał zabezpieczony nieruchomością',
            'kapital_zabezpieczony_nieruchomoscia',
            'source_file',
            'created_at',
            'uploaded_at',
            'ID_Klient', 'Klient', 'ID_Spolka', 'ID_Sprzedaz', 'Ilosc_Udzialow',
            'Kwota_wplat', 'Oddzial', 'Opiekun z MISA', 'Produkt_nazwa',
            'Produkt_status_wejscie', 'Status_produktu', 'Data_podpisania',
            'Data_wejscia_do_inwestycji', 'data_emisji', 'data_splaty',
            'data_wykupu', 'oprocentowanie',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productType': productType,
      'investmentAmount': investmentAmount,
      'realizedCapital': realizedCapital,
      'remainingCapital': remainingCapital,
      'realizedInterest': realizedInterest,
      'remainingInterest': remainingInterest,
      'realizedTax': realizedTax,
      'remainingTax': remainingTax,
      'transferToOtherProduct': transferToOtherProduct,
      'capitalForRestructuring': capitalForRestructuring,
      'capitalSecuredByRealEstate': capitalSecuredByRealEstate,
      'sourceFile': sourceFile,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),

      // Client and transaction info
      'clientId': clientId,
      'clientName': clientName,
      'companyId': companyId,
      'salesId': salesId,
      'sharesCount': sharesCount,
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
      'redemptionDate': redemptionDate?.toIso8601String(),
      'interestRate': interestRate,

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
    String? clientId,
    String? clientName,
    String? companyId,
    String? salesId,
    int? sharesCount,
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
    DateTime? redemptionDate,
    String? interestRate,
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
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      companyId: companyId ?? this.companyId,
      salesId: salesId ?? this.salesId,
      sharesCount: sharesCount ?? this.sharesCount,
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
      redemptionDate: redemptionDate ?? this.redemptionDate,
      interestRate: interestRate ?? this.interestRate,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

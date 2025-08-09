import 'package:cloud_firestore/cloud_firestore.dart';

class Bond {
  final String id;
  final String productType; // Typ_produktu
  final double investmentAmount; // Kwota_inwestycji
  final double realizedCapital; // Kapital zrealizowany
  final double remainingCapital; // Kapital Pozostaly
  final double realizedInterest; // odsetki_zrealizowane
  final double remainingInterest; // odsetki_pozostale
  final double realizedTax; // podatek_zrealizowany
  final double remainingTax; // podatek_pozostaly
  final double transferToOtherProduct; // Przekaz na inny produkt
  final double? capitalForRestructuring; // kapital_do_restrukturyzacji
  final double?
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at

  // Dodatne pola z Firebase
  final String? clientId; // ID_Klient
  final String? clientName; // Klient
  final String? companyId; // ID_Spolka
  final String? salesId; // ID_Sprzedaz
  final int? sharesCount; // Ilosc_Udzialow
  final double? paymentAmount; // Kwota_wplat
  final String? branch; // Oddzial
  final String? advisor; // Opiekun z MISA
  final String? productName; // Produkt_nazwa
  final String? productStatusEntry; // Produkt_status_wejscie
  final String? productStatus; // Status_produktu
  final DateTime? signedDate; // Data_podpisania
  final DateTime? investmentEntryDate; // Data_wejscia_do_inwestycji
  final DateTime? issueDate; // data_emisji
  final DateTime? maturityDate; // data_splaty
  final DateTime? redemptionDate; // data_wykupu
  final String? interestRate; // oprocentowanie

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
      productType: data['Typ_produktu'] ?? data['typ_produktu'] ?? 'Obligacje',
      investmentAmount: safeToDouble(
        data['Kwota_inwestycji'] ?? data['kwota_inwestycji'],
      ),
      realizedCapital: safeToDouble(
        data['Kapital zrealizowany'] ?? data['kapital_zrealizowany'],
      ),
      remainingCapital: safeToDouble(
        data['Kapital Pozostaly'] ?? data['kapital_pozostaly'],
      ),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      remainingInterest: safeToDouble(data['odsetki_pozostale']),
      realizedTax: safeToDouble(data['podatek_zrealizowany']),
      remainingTax: safeToDouble(data['podatek_pozostaly']),
      transferToOtherProduct: safeToDouble(
        data['Przekaz na inny produkt'] ?? data['przekaz_na_inny_produkt'],
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

      // Nowe pola z Firebase
      clientId: data['ID_Klient'],
      clientName: data['Klient'],
      companyId: data['ID_Spolka'],
      salesId: data['ID_Sprzedaz'],
      sharesCount: safeToIntNullable(data['Ilosc_Udzialow']),
      paymentAmount: safeToDouble(data['Kwota_wplat']),
      branch: data['Oddzial'],
      advisor: data['Opiekun z MISA'],
      productName: data['Produkt_nazwa'],
      productStatusEntry: data['Produkt_status_wejscie'],
      productStatus: data['Status_produktu'],
      signedDate: parseDate(data['Data_podpisania']),
      investmentEntryDate: parseDate(data['Data_wejscia_do_inwestycji']),
      issueDate: parseDate(data['data_emisji']),
      maturityDate: parseDate(data['data_splaty']),
      redemptionDate: parseDate(data['data_wykupu']),
      interestRate: data['oprocentowanie'],

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
            'ID_Klient',
            'Klient',
            'ID_Spolka',
            'ID_Sprzedaz',
            'Ilosc_Udzialow',
            'Kwota_wplat',
            'Oddzial',
            'Opiekun z MISA',
            'Produkt_nazwa',
            'Produkt_status_wejscie',
            'Status_produktu',
            'Data_podpisania',
            'Data_wejscia_do_inwestycji',
            'data_emisji',
            'data_splaty',
            'data_wykupu',
            'oprocentowanie',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'Typ_produktu': productType,
      'Kwota_inwestycji': investmentAmount,
      'Kapital zrealizowany': realizedCapital,
      'Kapital Pozostaly': remainingCapital,
      'odsetki_zrealizowane': realizedInterest,
      'odsetki_pozostale': remainingInterest,
      'podatek_zrealizowany': realizedTax,
      'podatek_pozostaly': remainingTax,
      'Przekaz na inny produkt': transferToOtherProduct,
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),

      // Nowe pola
      'ID_Klient': clientId,
      'Klient': clientName,
      'ID_Spolka': companyId,
      'ID_Sprzedaz': salesId,
      'Ilosc_Udzialow': sharesCount,
      'Kwota_wplat': paymentAmount,
      'Oddzial': branch,
      'Opiekun z MISA': advisor,
      'Produkt_nazwa': productName,
      'Produkt_status_wejscie': productStatusEntry,
      'Status_produktu': productStatus,
      'Data_podpisania': signedDate?.toIso8601String(),
      'Data_wejscia_do_inwestycji': investmentEntryDate?.toIso8601String(),
      'data_emisji': issueDate?.toIso8601String(),
      'data_splaty': maturityDate?.toIso8601String(),
      'data_wykupu': redemptionDate?.toIso8601String(),
      'oprocentowanie': interestRate,

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

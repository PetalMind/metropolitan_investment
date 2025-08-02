import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

enum InvestmentStatus {
  active('Aktywny'),
  inactive('Nieaktywny'),
  earlyRedemption('Wykup wczesniejszy'),
  completed('Zakończony');

  const InvestmentStatus(this.displayName);
  final String displayName;
}

enum MarketType {
  primary('Rynek pierwotny'),
  secondary('Rynek wtórny'),
  clientRedemption('Odkup od Klienta');

  const MarketType(this.displayName);
  final String displayName;
}

class Investment {
  final String id;
  final String clientId;
  final String clientName;
  final String employeeId;
  final String employeeFirstName;
  final String employeeLastName;
  final String branchCode;
  final InvestmentStatus status;
  final bool isAllocated;
  final MarketType marketType;
  final DateTime signedDate;
  final DateTime? entryDate;
  final DateTime? exitDate;
  final String proposalId;
  final ProductType productType;
  final String productName;
  final String creditorCompany;
  final String companyId;
  final DateTime? issueDate;
  final DateTime? redemptionDate;
  final int? sharesCount;
  final double investmentAmount;
  final double paidAmount;
  final double realizedCapital;
  final double realizedInterest;
  final double transferToOtherProduct;
  final double remainingCapital;
  final double remainingInterest;
  final double plannedTax;
  final double realizedTax;
  final String currency;
  final double? exchangeRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> additionalInfo;

  Investment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.employeeId,
    required this.employeeFirstName,
    required this.employeeLastName,
    required this.branchCode,
    required this.status,
    this.isAllocated = false,
    required this.marketType,
    required this.signedDate,
    this.entryDate,
    this.exitDate,
    required this.proposalId,
    required this.productType,
    required this.productName,
    required this.creditorCompany,
    required this.companyId,
    this.issueDate,
    this.redemptionDate,
    this.sharesCount,
    required this.investmentAmount,
    required this.paidAmount,
    this.realizedCapital = 0.0,
    this.realizedInterest = 0.0,
    this.transferToOtherProduct = 0.0,
    this.remainingCapital = 0.0,
    this.remainingInterest = 0.0,
    this.plannedTax = 0.0,
    this.realizedTax = 0.0,
    this.currency = 'PLN',
    this.exchangeRate,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo = const {},
  });

  String get employeeFullName => '$employeeFirstName $employeeLastName';

  double get totalRealized => realizedCapital + realizedInterest;
  double get totalRemaining => remainingCapital + remainingInterest;

  // ⭐ WARTOŚĆ CAŁKOWITA = TYLKO kapitał pozostały
  double get totalValue => remainingCapital;

  // ⭐ ZYSK/STRATA = TYLKO na podstawie kapitału pozostałego
  double get profitLoss => remainingCapital - investmentAmount;
  double get profitLossPercentage =>
      investmentAmount > 0 ? (profitLoss / investmentAmount) * 100 : 0.0;

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to parse date strings
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Helper function to map status from Polish to enum
    InvestmentStatus mapStatus(String? status) {
      switch (status) {
        case 'Aktywny':
          return InvestmentStatus.active;
        case 'Nieaktywny':
          return InvestmentStatus.inactive;
        case 'Wykup wczesniejszy':
          return InvestmentStatus.earlyRedemption;
        case 'Zakończony':
          return InvestmentStatus.completed;
        default:
          return InvestmentStatus.active;
      }
    }

    // Helper function to map market type from Polish to enum
    MarketType mapMarketType(String? marketType) {
      switch (marketType) {
        case 'Rynek pierwotny':
          return MarketType.primary;
        case 'Rynek wtórny':
          return MarketType.secondary;
        case 'Odkup od Klienta':
          return MarketType.clientRedemption;
        default:
          return MarketType.primary;
      }
    }

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

    // Helper function to map product type from Polish to enum
    ProductType mapProductType(String? productType) {
      if (productType == null || productType.isEmpty) {
        return ProductType.bonds;
      }

      final type = productType.toLowerCase();

      // Sprawdź zawartość stringa dla rozpoznania typu
      if (type.contains('pożyczka') || type.contains('pozyczka')) {
        return ProductType.loans;
      } else if (type.contains('udział') || type.contains('udziały')) {
        return ProductType.shares;
      } else if (type.contains('apartament')) {
        return ProductType.apartments;
      } else if (type.contains('obligacje') || type.contains('obligacja')) {
        return ProductType.bonds;
      }

      // Fallback dla dokładnych dopasowań
      switch (productType) {
        case 'Obligacje':
          return ProductType.bonds;
        case 'Udziały':
          return ProductType.shares;
        case 'Pożyczki':
          return ProductType.loans;
        case 'Apartamenty':
          return ProductType.apartments;
        default:
          return ProductType.bonds;
      }
    }

    return Investment(
      id: doc.id,
      clientId: data['id_klient']?.toString() ?? '',
      clientName: data['klient'] ?? '',
      employeeId: '', // Not directly available in Firebase structure
      employeeFirstName: data['pracownik_imie'] ?? '',
      employeeLastName: data['pracownik_nazwisko'] ?? '',
      branchCode: data['oddzial'] ?? '',
      status: mapStatus(data['status_produktu']),
      isAllocated: (data['przydzial'] ?? 0) == 1,
      marketType: mapMarketType(data['produkt_status_wejscie']),
      signedDate: parseDate(data['data_podpisania']) ?? DateTime.now(),
      entryDate: parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: parseDate(data['data_wyjscia_z_inwestycji']),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? '',
      productType: mapProductType(data['typ_produktu']),
      productName: data['produkt_nazwa'] ?? '',
      creditorCompany: data['wierzyciel_spolka'] ?? '',
      companyId: data['id_spolka'] ?? '',
      issueDate: parseDate(data['data_emisji']),
      redemptionDate: parseDate(data['data_wykupu']),
      sharesCount: data['ilosc_udzialow'],
      investmentAmount: safeToDouble(data['kwota_inwestycji']),
      paidAmount: safeToDouble(data['kwota_wplat']),
      realizedCapital: safeToDouble(data['kapital_zrealizowany']),
      realizedInterest: safeToDouble(data['odsetki_zrealizowane']),
      transferToOtherProduct: safeToDouble(data['przekaz_na_inny_produkt']),
      remainingCapital: safeToDouble(data['kapital_pozostaly']),
      remainingInterest: safeToDouble(data['odsetki_pozostale']),
      plannedTax: safeToDouble(data['planowany_podatek']),
      realizedTax: safeToDouble(data['zrealizowany_podatek']),
      currency: 'PLN', // Default currency
      exchangeRate: null, // Not available in Firebase structure
      createdAt: parseDate(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(data['uploaded_at']) ?? DateTime.now(),
      additionalInfo: {
        'source_file': data['source_file'],
        'id_sprzedaz': data['id_sprzedaz'],
      },
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_klient': int.tryParse(clientId) ?? 0,
      'klient': clientName,
      'pracownik_imie': employeeFirstName,
      'pracownik_nazwisko': employeeLastName,
      'oddzial': branchCode,
      'status_produktu': status.displayName,
      'przydzial': isAllocated ? 1 : 0,
      'produkt_status_wejscie': marketType.displayName,
      'data_podpisania': signedDate.toIso8601String(),
      'data_wejscia_do_inwestycji': entryDate?.toIso8601String(),
      'data_wyjscia_z_inwestycji': exitDate?.toIso8601String(),
      'id_propozycja_nabycia': int.tryParse(proposalId) ?? 0,
      'typ_produktu': productType.displayName,
      'produkt_nazwa': productName,
      'wierzyciel_spolka': creditorCompany,
      'id_spolka': companyId,
      'data_emisji': issueDate?.toIso8601String(),
      'data_wykupu': redemptionDate?.toIso8601String(),
      'ilosc_udzialow': sharesCount,
      'kwota_inwestycji': investmentAmount,
      'kwota_wplat': paidAmount,
      'kapital_zrealizowany': realizedCapital,
      'odsetki_zrealizowane': realizedInterest,
      'przekaz_na_inny_produkt': transferToOtherProduct,
      'kapital_pozostaly': remainingCapital,
      'odsetki_pozostale': remainingInterest,
      'planowany_podatek': plannedTax,
      'zrealizowany_podatek': realizedTax,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': updatedAt.toIso8601String(),
      'source_file': additionalInfo['source_file'] ?? 'manual_entry',
      'id_sprzedaz': additionalInfo['id_sprzedaz'],
    };
  }

  Investment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? employeeId,
    String? employeeFirstName,
    String? employeeLastName,
    String? branchCode,
    InvestmentStatus? status,
    bool? isAllocated,
    MarketType? marketType,
    DateTime? signedDate,
    DateTime? entryDate,
    DateTime? exitDate,
    String? proposalId,
    ProductType? productType,
    String? productName,
    String? creditorCompany,
    String? companyId,
    DateTime? issueDate,
    DateTime? redemptionDate,
    int? sharesCount,
    double? investmentAmount,
    double? paidAmount,
    double? realizedCapital,
    double? realizedInterest,
    double? transferToOtherProduct,
    double? remainingCapital,
    double? remainingInterest,
    double? plannedTax,
    double? realizedTax,
    String? currency,
    double? exchangeRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Investment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      employeeId: employeeId ?? this.employeeId,
      employeeFirstName: employeeFirstName ?? this.employeeFirstName,
      employeeLastName: employeeLastName ?? this.employeeLastName,
      branchCode: branchCode ?? this.branchCode,
      status: status ?? this.status,
      isAllocated: isAllocated ?? this.isAllocated,
      marketType: marketType ?? this.marketType,
      signedDate: signedDate ?? this.signedDate,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      proposalId: proposalId ?? this.proposalId,
      productType: productType ?? this.productType,
      productName: productName ?? this.productName,
      creditorCompany: creditorCompany ?? this.creditorCompany,
      companyId: companyId ?? this.companyId,
      issueDate: issueDate ?? this.issueDate,
      redemptionDate: redemptionDate ?? this.redemptionDate,
      sharesCount: sharesCount ?? this.sharesCount,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      realizedCapital: realizedCapital ?? this.realizedCapital,
      realizedInterest: realizedInterest ?? this.realizedInterest,
      transferToOtherProduct:
          transferToOtherProduct ?? this.transferToOtherProduct,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      remainingInterest: remainingInterest ?? this.remainingInterest,
      plannedTax: plannedTax ?? this.plannedTax,
      realizedTax: realizedTax ?? this.realizedTax,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

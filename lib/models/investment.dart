import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';
import 'client.dart' show VotingStatus;

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
  final String?
  productId; // Dodane nowe pole - ID produktu dla precyzyjnego mapowania
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
  final double capitalSecuredByRealEstate;
  final double capitalForRestructuring;
  final VotingStatus
  votingStatus; // Status głosowania dla konkretnej inwestycji
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
    this.productId, // Dodane nowe opcjonalne pole
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
    // 🔥 POLA Z GŁÓWNEGO POZIOMU FIREBASE
    this.capitalSecuredByRealEstate = 0.0,
    this.capitalForRestructuring = 0.0,
    this.votingStatus = VotingStatus.undecided, // Domyślny status głosowania
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

  // 🚀 NOWE: Obliczony kapitał zabezpieczony (frontend calculation)
  // Backend zwraca zawsze 0, więc obliczamy: remainingCapital - capitalForRestructuring
  double get calculatedCapitalSecuredByRealEstate {
    final secured = (remainingCapital - capitalForRestructuring).clamp(0.0, double.infinity);
    return secured;
  }

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to parse date strings and Timestamps
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;

      // Handle Firestore Timestamp
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }

      // Handle string dates
      if (dateValue is String) {
        if (dateValue.isEmpty) return null;
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return null;
        }
      }

      // Handle DateTime
      if (dateValue is DateTime) {
        return dateValue;
      }

      return null;
    } // Helper function to map status from Polish to enum

    // Helper function to parse voting status
    VotingStatus _parseVotingStatus(dynamic status) {
      if (status == null) return VotingStatus.undecided;

      final statusStr = status.toString().toLowerCase();
      switch (statusStr) {
        case 'yes':
        case 'tak':
        case 'za':
          return VotingStatus.yes;
        case 'no':
        case 'nie':
        case 'przeciw':
          return VotingStatus.no;
        case 'abstain':
        case 'wstrzymuje':
        case 'wstrzymuje_sie':
        case 'wstrzymuje się':
          return VotingStatus.abstain;
        default:
          return VotingStatus.undecided;
      }
    }

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

    // ⭐ Helper function to parse capital values with commas
    double parseCapitalValue(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle string values like "200,000.00" from Firebase
        final cleaned = value.toString().replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
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
      id: data['id']?.toString() ?? doc.id, // Użyj logicznego ID z pola 'id', fallback do UUID
      // ⭐ NOWE MAPOWANIE PÓL FIREBASE - znormalizowane nazwy mają priorytet
      clientId:
          data['clientId']?.toString() ??
          data['ID_Klient']?.toString() ??
          data['id_klient']?.toString() ??
          '',
      clientName: data['clientName'] ?? data['Klient'] ?? data['klient'] ?? '',
      employeeId: '', // Not directly available in Firebase structure
      employeeFirstName:
          data['employeeFirstName'] ?? data['pracownik_imie'] ?? '',
      employeeLastName:
          data['employeeLastName'] ?? data['pracownik_nazwisko'] ?? '',
      branchCode: data['branch'] ?? data['Oddzial'] ?? data['oddzial'] ?? '',
      status: mapStatus(
        data['productStatus'] ??
            data['Status_produktu'] ??
            data['status_produktu'] ??
            data['status'],
      ),
      isAllocated: (data['allocation'] ?? data['przydzial'] ?? 0) == 1,
      marketType: mapMarketType(
        data['productStatusEntry'] ??
            data['Produkt_status_wejscie'] ??
            data['produkt_status_wejscie'],
      ),
      signedDate:
          parseDate(data['signingDate']) ??
          parseDate(data['Data_podpisania']) ??
          parseDate(data['data_podpisania']) ??
          DateTime.now(),
      entryDate:
          parseDate(data['investmentEntryDate']) ??
          parseDate(data['Data_wejscia_do_inwestycji']) ??
          parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: parseDate(
        data['investmentExitDate'] ?? data['data_wyjscia_z_inwestycji'],
      ),
      proposalId:
          data['saleId']?.toString() ??
          data['ID_Sprzedaz']?.toString() ??
          data['id_sprzedaz']?.toString() ??
          data['id_propozycja_nabycia']?.toString() ??
          '',
      productType: mapProductType(
        data['productType'] ?? data['Typ_produktu'] ?? data['typ_produktu'],
      ),
      productName:
          data['productName'] ??
          data['Produkt_nazwa'] ??
          data['produkt_nazwa'] ??
          '',
      productId:
          data['productId'] ??
          data['product_id'] ??
          data['id_produktu'] ??
          data['ID_Produktu'],
      creditorCompany:
          data['creditorCompany'] ?? data['wierzyciel_spolka'] ?? '',
      companyId:
          data['companyId'] ?? data['ID_Spolka'] ?? data['id_spolka'] ?? '',
      issueDate:
          parseDate(data['issueDate']) ??
          parseDate(data['data_emisji']) ??
          parseDate(data['emisja_data']),
      redemptionDate:
          parseDate(data['redemptionDate']) ??
          parseDate(data['data_wykupu']) ??
          parseDate(data['wykup_data']),
      sharesCount: data['shareCount'] != null && data['shareCount'] != 'NULL'
          ? int.tryParse(data['shareCount'].toString())
          : data['Ilosc_Udzialow'] != null && data['Ilosc_Udzialow'] != 'NULL'
          ? int.tryParse(data['Ilosc_Udzialow'].toString())
          : data['ilosc_udzialow'],
      // ⭐ KWOTA INWESTYCJI - znormalizowane nazwy mają priorytet, obsługa stringów z przecinkami
      investmentAmount: parseCapitalValue(data['investmentAmount']) != 0
          ? parseCapitalValue(data['investmentAmount'])
          : parseCapitalValue(data['Kwota_inwestycji']) != 0
          ? parseCapitalValue(data['Kwota_inwestycji'])
          : parseCapitalValue(data['kwota_inwestycji']),
      paidAmount: parseCapitalValue(data['paidAmount']) != 0
          ? parseCapitalValue(data['paidAmount'])
          : parseCapitalValue(data['Kwota_wplat']) != 0
          ? parseCapitalValue(data['Kwota_wplat'])
          : parseCapitalValue(data['kwota_wplat']),
      // ⭐ KAPITAŁ ZREALIZOWANY - obsługa stringów z przecinkami
      realizedCapital: parseCapitalValue(
        data['realizedCapital'] ??
            data['Kapital zrealizowany'] ??
            data['kapital_zrealizowany'],
      ),
      realizedInterest: parseCapitalValue(data['realizedInterest']) != 0
          ? parseCapitalValue(data['realizedInterest'])
          : parseCapitalValue(data['odsetki_zrealizowane']),
      transferToOtherProduct: parseCapitalValue(
        data['transferToOtherProduct'] ??
            data['Przekaz na inny produkt'] ??
            data['przekaz_na_inny_produkt'],
      ),
      // ⭐ KAPITAŁ POZOSTAŁY - obsługa stringów z przecinkami
      remainingCapital: parseCapitalValue(
        data['remainingCapital'] ??
            data['Kapital Pozostaly'] ??
            data['kapital_pozostaly'],
      ),
      remainingInterest: parseCapitalValue(data['remainingInterest']) != 0
          ? parseCapitalValue(data['remainingInterest'])
          : parseCapitalValue(data['odsetki_pozostale']),
      plannedTax: parseCapitalValue(
        data['plannedTax'] ?? data['podatek_pozostaly'],
      ),
      realizedTax: parseCapitalValue(
        data['realizedTax'] ?? data['podatek_zrealizowany'],
      ),
      currency: 'PLN', // Default currency
      exchangeRate: null, // Not available in Firebase structure
      createdAt:
          parseDate(data['createdAt']) ??
          parseDate(data['created_at']) ??
          DateTime.now(),
      updatedAt:
          parseDate(data['updatedAt']) ??
          parseDate(data['uploadedAt']) ??
          parseDate(data['uploaded_at']) ??
          DateTime.now(),
      // 🔥 POLA Z GŁÓWNEGO POZIOMU FIREBASE
      capitalSecuredByRealEstate: parseCapitalValue(
        data['capitalSecuredByRealEstate'] ??
            data['realEstateSecuredCapital'] ??
            data['Kapitał zabezpieczony nieruchomością'] ??
            data['Kapital zabezpieczony nieruchomoscia'] ??
            data['kapital_zabezpieczony_nieruchomoscia'],
      ),
      capitalForRestructuring: parseCapitalValue(
        data['capitalForRestructuring'] ??
            data['kapital_do_restrukturyzacji'] ??
            data['Kapitał do restrukturyzacji'] ??
            data['Kapital do restrukturyzacji'],
      ),
      votingStatus: _parseVotingStatus(
        data['votingStatus'] ??
            data['voting_status'] ??
            data['status_glosowania'],
      ),
      additionalInfo: {
        'sourceFile': data['sourceFile'] ?? data['source_file'],
        'saleId': data['saleId'] ?? data['ID_Sprzedaz'] ?? data['id_sprzedaz'],
        'misaGuardian': data['misaGuardian'] ?? data['Opiekun z MISA'],
        'bondName': data['bondName'] ?? data['nazwa_obligacji'],
        'interestRate': data['interestRate'] ?? data['oprocentowanie'],
        'issuer': data['issuer'] ?? data['emitent'],
        'loanNumber': data['loanNumber'] ?? data['pozyczka_numer'],
        'borrower': data['borrower'] ?? data['pozyczkobiorca'],
        'collateral': data['collateral'] ?? data['zabezpieczenie'],
        'repaymentDate': data['repaymentDate'] ?? data['data_splaty'],
        'disbursementDate': data['disbursementDate'] ?? data['data_udzielenia'],
        'accruedInterest': data['accruedInterest'] ?? data['odsetki_naliczone'],
      },
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // ⭐ LOGICAL ID - saved in document (not UUID)
      'id': id, // Logical ID like bond_0194, loan_0005
      // ⭐ NORMALIZED NAMES (priority) - according to new schema
      'clientId': clientId,
      'clientName': clientName,
      'branch': branchCode,
      'productStatus': status.displayName,
      'productStatusEntry': marketType.displayName,
      'signingDate': signedDate.toIso8601String(),
      'investmentEntryDate': entryDate?.toIso8601String(),
      'saleId': proposalId,
      'productType': productType.displayName,
      'productName': productName,
      'productId': productId, // Added new field
      'companyId': companyId,
      'shareCount': sharesCount, // Numeric value instead of string
      'investmentAmount': investmentAmount, // Numeric value
      'paidAmount': paidAmount, // Numeric value
      'realizedCapital': realizedCapital, // Numeric value
      'realizedInterest': realizedInterest, // Numeric value
      'transferToOtherProduct': transferToOtherProduct, // Numeric value
      'remainingCapital': remainingCapital, // Numeric value
      'remainingInterest': remainingInterest, // Numeric value
      'plannedTax': plannedTax, // Numeric value
      'realizedTax': realizedTax, // Numeric value
      // 🔥 ADD CAPITAL FIELDS FROM MAIN LEVEL
      'capitalSecuredByRealEstate': capitalSecuredByRealEstate,
      'capitalForRestructuring': capitalForRestructuring,
      'votingStatus': votingStatus.name, // Zapisujemy status głosowania
      'status_glosowania': votingStatus.displayName, // Dla kompatybilności
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'uploadedAt': updatedAt.toIso8601String(),
      'sourceFile': additionalInfo['sourceFile'] ?? 'manual_entry',
      'employeeId': employeeId,
      'employeeFirstName': employeeFirstName,
      'employeeLastName': employeeLastName,
      'creditorCompany': creditorCompany,
      'issueDate': issueDate?.toIso8601String(),
      'redemptionDate': redemptionDate?.toIso8601String(),
      'currency': currency,
      'exchangeRate': exchangeRate,
      'isAllocated': isAllocated,
      'investmentExitDate': exitDate?.toIso8601String(),

      // Additional info with normalized names
      'misaGuardian': additionalInfo['misaGuardian'],
      'bondName': additionalInfo['bondName'],
      'interestRate': additionalInfo['interestRate'],
      'issuer': additionalInfo['issuer'],
      'loanNumber': additionalInfo['loanNumber'],
      'borrower': additionalInfo['borrower'],
      'collateral': additionalInfo['collateral'],
      'realEstateSecuredCapital': capitalSecuredByRealEstate, // Numeric value
      'repaymentDate': additionalInfo['repaymentDate'],
      'disbursementDate': additionalInfo['disbursementDate'],
      'accruedInterest': additionalInfo['accruedInterest'],

      // Additional fields from new structure
      'investmentType': productType.name.toLowerCase(),
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
    double? capitalSecuredByRealEstate,
    double? capitalForRestructuring,
    VotingStatus? votingStatus,
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
      capitalSecuredByRealEstate:
          capitalSecuredByRealEstate ?? this.capitalSecuredByRealEstate,
      capitalForRestructuring:
          capitalForRestructuring ?? this.capitalForRestructuring,
      votingStatus: votingStatus ?? this.votingStatus,
      plannedTax: plannedTax ?? this.plannedTax,
      realizedTax: realizedTax ?? this.realizedTax,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Konstruktor do konwersji z danych serwera (Firebase Functions)
  factory Investment.fromServerMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is String && date.isNotEmpty) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return null;
        }
      }
      if (date is DateTime) return date;
      return null;
    }

    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle empty strings and NULL values
        if (value.isEmpty ||
            value.trim().isEmpty ||
            value.toUpperCase() == 'NULL') {
          return 0.0;
        }

        // Debug logging for problematic values
        if (value.contains(',')) {
          print(
            '🔍 [Investment.fromServerMap] Parsowanie wartości z przecinkiem: "$value"',
          );
        }
        // Handle Polish number format with comma as thousands separator
        final cleaned = value.toString().replaceAll(',', '');
        final parsed = double.tryParse(cleaned);
        if (parsed == null) {
          print(
            '❌ [Investment.fromServerMap] Nie można sparsować: "$value" -> "$cleaned"',
          );
        }
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    ProductType mapProductType(String? type) {
      switch (type?.toLowerCase()) {
        case 'bonds':
        case 'obligacje':
          return ProductType.bonds;
        case 'shares':
        case 'udziały':
          return ProductType.shares;
        case 'loans':
        case 'pożyczki':
          return ProductType.loans;
        case 'apartments':
        case 'apartamenty':
          return ProductType.apartments;
        default:
          return ProductType.bonds;
      }
    }

    InvestmentStatus mapStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'active':
        case 'aktywny':
          return InvestmentStatus.active;
        case 'inactive':
        case 'nieaktywny':
          return InvestmentStatus.inactive;
        case 'completed':
        case 'zakończony':
          return InvestmentStatus.completed;
        default:
          return InvestmentStatus.active;
      }
    }

    MarketType mapMarketType(String? type) {
      switch (type?.toLowerCase()) {
        case 'secondary':
        case 'rynek wtórny':
        case 'wtorny':
          return MarketType.secondary;
        case 'client':
        case 'odkup':
        case 'odkup od klienta':
          return MarketType.clientRedemption;
        case 'primary':
        case 'rynek pierwotny':
        case 'pierwotny':
        default:
          return MarketType.primary;
      }
    }

    VotingStatus _parseVotingStatusStatic(dynamic status) {
      if (status == null) return VotingStatus.undecided;

      final statusStr = status.toString().toLowerCase();
      switch (statusStr) {
        case 'yes':
        case 'tak':
        case 'za':
          return VotingStatus.yes;
        case 'no':
        case 'nie':
        case 'przeciw':
          return VotingStatus.no;
        case 'abstain':
        case 'wstrzymuje':
        case 'wstrzymuje_sie':
        case 'wstrzymuje się':
          return VotingStatus.abstain;
        default:
          return VotingStatus.undecided;
      }
    }

    return Investment(
      id: map['id']?.toString() ?? '',
      clientId: map['clientId']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeFirstName: map['employeeFirstName']?.toString() ?? '',
      employeeLastName: map['employeeLastName']?.toString() ?? '',
      branchCode: map['branchCode']?.toString() ?? '',
      status: mapStatus(map['status']?.toString()),
      marketType: mapMarketType(map['marketType']?.toString()),
      signedDate: parseDate(map['signedDate']) ?? DateTime.now(),
      proposalId: map['proposalId']?.toString() ?? '',
      productType: mapProductType(map['productType']?.toString()),
      productName: map['productName']?.toString() ?? '',
      productId: map['productId']?.toString(), // Dodane nowe pole
      companyId: map['companyId']?.toString() ?? '',
      creditorCompany: map['creditorCompany']?.toString() ?? '',
      investmentAmount: safeToDouble(map['investmentAmount']),
      paidAmount: safeToDouble(map['paidAmount']),
      realizedCapital: safeToDouble(map['realizedCapital']),
      realizedInterest: safeToDouble(map['realizedInterest']),
      transferToOtherProduct: safeToDouble(map['transferToOtherProduct']),
      remainingCapital: safeToDouble(map['remainingCapital']),
      remainingInterest: safeToDouble(map['remainingInterest']),
      plannedTax: safeToDouble(map['plannedTax']),
      realizedTax: safeToDouble(map['realizedTax']),
      currency: map['currency']?.toString() ?? 'PLN',
      exchangeRate: safeToDouble(map['exchangeRate']),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      capitalForRestructuring: safeToDouble(map['capitalForRestructuring']),
      capitalSecuredByRealEstate: safeToDouble(
        map['capitalSecuredByRealEstate'],
      ),
      votingStatus: _parseVotingStatusStatic(map['votingStatus']),
      additionalInfo: {},
    );
  }
}

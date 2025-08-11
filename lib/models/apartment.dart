import 'package:cloud_firestore/cloud_firestore.dart';

enum ApartmentStatus {
  available('Dostępny'),
  reserved('Zarezerwowany'),
  sold('Sprzedany'),
  underConstruction('W budowie'),
  ready('Gotowy');

  const ApartmentStatus(this.displayName);
  final String displayName;
}

enum ApartmentType {
  studio('Kawalerka'),
  apartment2Room('2 pokoje'),
  apartment3Room('3 pokoje'),
  apartment4Room('4 pokoje'),
  penthouse('Penthouse'),
  other('Inny');

  const ApartmentType(this.displayName);
  final String displayName;
}

class Apartment {
  final String id;
  final String productType;
  final double investmentAmount;
  final double? capitalForRestructuring;
  final double? capitalSecuredByRealEstate;
  final String sourceFile;
  final DateTime createdAt;
  final DateTime uploadedAt;

  // Investment fields from JSON data
  final String saleId;
  final String clientId;
  final String clientName;
  final String advisor;
  final String branch;
  final String productStatus;
  final String marketEntry;
  final DateTime? signedDate;
  final DateTime? investmentEntryDate;
  final String projectName;
  final String creditorCompany;
  final String companyId;
  final DateTime? issueDate;
  final DateTime? redemptionDate;
  final String? shareCount;
  final double paymentAmount;
  final double realizedCapital;
  final double transferToOtherProduct;
  final double remainingCapital;
  final Map<String, dynamic> additionalInfo;

  // Apartment-specific fields
  final String apartmentNumber;
  final String building;
  final String address;
  final double area;
  final int roomCount;
  final int floor;
  final ApartmentStatus status;
  final ApartmentType apartmentType;
  final double pricePerSquareMeter;
  final bool hasBalcony;
  final bool hasParkingSpace;
  final bool hasStorage;
  final String developer;

  Apartment({
    required this.id,
    required this.productType,
    required this.investmentAmount,
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    required this.saleId,
    required this.clientId,
    required this.clientName,
    required this.advisor,
    required this.branch,
    required this.productStatus,
    required this.marketEntry,
    this.signedDate,
    this.investmentEntryDate,
    required this.projectName,
    required this.creditorCompany,
    required this.companyId,
    this.issueDate,
    this.redemptionDate,
    this.shareCount,
    required this.paymentAmount,
    required this.realizedCapital,
    required this.transferToOtherProduct,
    required this.remainingCapital,
    this.additionalInfo = const {},
    // Apartment-specific fields
    required this.apartmentNumber,
    required this.building,
    required this.address,
    required this.area,
    required this.roomCount,
    required this.floor,
    required this.status,
    required this.apartmentType,
    required this.pricePerSquareMeter,
    required this.hasBalcony,
    required this.hasParkingSpace,
    required this.hasStorage,
    required this.developer,
  });

  // Calculated properties
  double get totalValue => investmentAmount;
  double get remainingValue => capitalForRestructuring ?? remainingCapital;

  factory Apartment.fromFirestore(DocumentSnapshot doc) {
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

    // Helper function to safely convert to bool
    bool safeToBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is int) return value == 1;
      return defaultValue;
    }

    // Helper function to parse date strings
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == 'NULL') return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Helper function to map apartment status
    ApartmentStatus mapApartmentStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'sprzedany':
        case 'sold':
          return ApartmentStatus.sold;
        case 'zarezerwowany':
        case 'reserved':
          return ApartmentStatus.reserved;
        case 'w budowie':
        case 'under construction':
        case 'underConstruction':
          return ApartmentStatus.underConstruction;
        case 'gotowy':
        case 'ready':
          return ApartmentStatus.ready;
        case 'dostępny':
        case 'available':
        default:
          return ApartmentStatus.available;
      }
    }

    // Helper function to map apartment type
    ApartmentType mapApartmentType(String? type) {
      switch (type?.toLowerCase()) {
        case 'kawalerka':
        case 'studio':
          return ApartmentType.studio;
        case '2 pokoje':
        case '2-room':
        case '2room':
          return ApartmentType.apartment2Room;
        case '3 pokoje':
        case '3-room':
        case '3room':
          return ApartmentType.apartment3Room;
        case '4 pokoje':
        case '4-room':
        case '4room':
          return ApartmentType.apartment4Room;
        case 'penthouse':
          return ApartmentType.penthouse;
        default:
          return ApartmentType.other;
      }
    }

    return Apartment(
      id: doc.id,
      productType: data['productType'] ?? data['Typ_produktu'] ?? 'Apartamenty',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ?? data['Kwota_inwestycji'],
      ),
      capitalForRestructuring: safeToDouble(
        data['capitalForRestructuring'] ?? data['Kapitał do restrukturyzacji'],
      ),
      capitalSecuredByRealEstate: safeToDouble(
        data['capitalSecuredByRealEstate'] ??
            data['Kapitał zabezpieczony nieruchomością'],
      ),
      sourceFile: data['sourceFile'] ?? 'imported_data.json',
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      uploadedAt: parseDate(data['uploadedAt']) ?? DateTime.now(),

      // Investment fields mapped from JSON
      saleId: data['saleId'] ?? data['ID_Sprzedaz'] ?? '',
      clientId: data['clientId'] ?? data['ID_Klient'] ?? '',
      clientName: data['clientName'] ?? data['Klient'] ?? '',
      advisor: data['advisor'] ?? data['Opiekun z MISA'] ?? '',
      branch: data['branch'] ?? data['Oddzial'] ?? '',
      productStatus: data['productStatus'] ?? data['Status_produktu'] ?? '',
      marketEntry: data['marketEntry'] ?? data['Produkt_status_wejscie'] ?? '',
      signedDate: parseDate(data['signedDate'] ?? data['Data_podpisania']),
      investmentEntryDate: parseDate(
        data['investmentEntryDate'] ?? data['Data_wejscia_do_inwestycji'],
      ),
      projectName: data['projectName'] ?? data['Produkt_nazwa'] ?? '',
      creditorCompany:
          data['creditorCompany'] ?? data['wierzyciel_spolka'] ?? '',
      companyId: data['companyId'] ?? data['ID_Spolka'] ?? '',
      issueDate: parseDate(data['issueDate'] ?? data['data_emisji']),
      redemptionDate: parseDate(data['redemptionDate'] ?? data['data_wykupu']),
      shareCount: data['shareCount'] ?? data['Ilosc_Udzialow'],
      paymentAmount: safeToDouble(data['paymentAmount'] ?? data['Kwota_wplat']),
      realizedCapital: safeToDouble(
        data['realizedCapital'] ?? data['Kapital zrealizowany'],
      ),
      transferToOtherProduct: safeToDouble(
        data['transferToOtherProduct'] ?? data['Przekaz na inny produkt'],
      ),
      remainingCapital: safeToDouble(
        data['remainingCapital'] ?? data['Kapital Pozostaly'],
      ),

      // Apartment-specific fields with fallback values
      apartmentNumber:
          data['apartmentNumber']?.toString() ??
          data['Numer_apartamentu']?.toString() ??
          data['numer_apartamentu']?.toString() ??
          'N/A',
      building:
          data['building']?.toString() ??
          data['Budynek']?.toString() ??
          data['budynek']?.toString() ??
          'N/A',
      address:
          data['address']?.toString() ??
          data['Adres']?.toString() ??
          data['adres']?.toString() ??
          'N/A',
      area: safeToDouble(
        data['area'] ?? data['Powierzchnia'] ?? data['powierzchnia'],
      ),
      roomCount: safeToInt(
        data['roomCount'] ?? data['Ilosc_pokoi'] ?? data['ilosc_pokoi'],
      ),
      floor: safeToInt(data['floor'] ?? data['Pietro'] ?? data['pietro']),
      status: mapApartmentStatus(
        data['apartmentStatus'] ?? data['status'] ?? data['Status'],
      ),
      apartmentType: mapApartmentType(
        data['apartmentType'] ??
            data['Typ_apartamentu'] ??
            data['typ_apartamentu'],
      ),
      pricePerSquareMeter: safeToDouble(
        data['pricePerSquareMeter'] ?? data['Cena_za_m2'] ?? data['cena_za_m2'],
      ),
      hasBalcony: safeToBool(
        data['hasBalcony'] ?? data['Ma_balkon'] ?? data['ma_balkon'],
      ),
      hasParkingSpace: safeToBool(
        data['hasParkingSpace'] ?? data['Ma_parking'] ?? data['ma_parking'],
      ),
      hasStorage: safeToBool(
        data['hasStorage'] ?? data['Ma_komorkę'] ?? data['ma_komorke'],
      ),
      developer:
          data['developer']?.toString() ??
          data['Deweloper']?.toString() ??
          data['deweloper']?.toString() ??
          'N/A',

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'productType',
            'Typ_produktu',
            'investmentAmount',
            'Kwota_inwestycji',
            'capitalForRestructuring',
            'Kapitał do restrukturyzacji',
            'capitalSecuredByRealEstate',
            'Kapitał zabezpieczony nieruchomością',
            'sourceFile',
            'createdAt',
            'uploadedAt',
            'saleId',
            'ID_Sprzedaz',
            'clientId',
            'ID_Klient',
            'clientName',
            'Klient',
            'advisor',
            'Opiekun z MISA',
            'branch',
            'Oddzial',
            'productStatus',
            'Status_produktu',
            'marketEntry',
            'Produkt_status_wejscie',
            'signedDate',
            'Data_podpisania',
            'investmentEntryDate',
            'Data_wejscia_do_inwestycji',
            'projectName',
            'Produkt_nazwa',
            'creditorCompany',
            'wierzyciel_spolka',
            'companyId',
            'ID_Spolka',
            'issueDate',
            'data_emisji',
            'redemptionDate',
            'data_wykupu',
            'shareCount',
            'Ilosc_Udzialow',
            'paymentAmount',
            'Kwota_wplat',
            'realizedCapital',
            'Kapital zrealizowany',
            'transferToOtherProduct',
            'Przekaz na inny produkt',
            'remainingCapital',
            'Kapital Pozostaly',
            // New apartment fields
            'apartmentNumber', 'Numer_apartamentu', 'numer_apartamentu',
            'building', 'Budynek', 'budynek',
            'address', 'Adres', 'adres',
            'area', 'Powierzchnia', 'powierzchnia',
            'roomCount', 'Ilosc_pokoi', 'ilosc_pokoi',
            'floor', 'Pietro', 'pietro',
            'apartmentStatus', 'status', 'Status',
            'apartmentType', 'Typ_apartamentu', 'typ_apartamentu',
            'pricePerSquareMeter', 'Cena_za_m2', 'cena_za_m2',
            'hasBalcony', 'Ma_balkon', 'ma_balkon',
            'hasParkingSpace', 'Ma_parking', 'ma_parking',
            'hasStorage', 'Ma_komorkę', 'ma_komorke',
            'developer', 'Deweloper', 'deweloper',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // English field names only
      'productType': productType,
      'investmentAmount': investmentAmount,
      'capitalForRestructuring': capitalForRestructuring,
      'capitalSecuredByRealEstate': capitalSecuredByRealEstate,
      'sourceFile': sourceFile,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'saleId': saleId,
      'clientId': clientId,
      'clientName': clientName,
      'advisor': advisor,
      'branch': branch,
      'productStatus': productStatus,
      'marketEntry': marketEntry,
      'signedDate': signedDate?.toIso8601String(),
      'investmentEntryDate': investmentEntryDate?.toIso8601String(),
      'projectName': projectName,
      'creditorCompany': creditorCompany,
      'companyId': companyId,
      'issueDate': issueDate?.toIso8601String(),
      'redemptionDate': redemptionDate?.toIso8601String(),
      'shareCount': shareCount,
      'paymentAmount': paymentAmount,
      'realizedCapital': realizedCapital,
      'transferToOtherProduct': transferToOtherProduct,
      'remainingCapital': remainingCapital,

      // Apartment-specific fields
      'apartmentNumber': apartmentNumber,
      'building': building,
      'address': address,
      'area': area,
      'roomCount': roomCount,
      'floor': floor,
      'apartmentStatus': status.displayName,
      'apartmentType': apartmentType.displayName,
      'pricePerSquareMeter': pricePerSquareMeter,
      'hasBalcony': hasBalcony,
      'hasParkingSpace': hasParkingSpace,
      'hasStorage': hasStorage,
      'developer': developer,

      ...additionalInfo,
    };
  }

  Apartment copyWith({
    String? id,
    String? productType,
    double? investmentAmount,
    double? capitalForRestructuring,
    double? capitalSecuredByRealEstate,
    String? sourceFile,
    DateTime? createdAt,
    DateTime? uploadedAt,
    String? saleId,
    String? clientId,
    String? clientName,
    String? advisor,
    String? branch,
    String? productStatus,
    String? marketEntry,
    DateTime? signedDate,
    DateTime? investmentEntryDate,
    String? projectName,
    String? creditorCompany,
    String? companyId,
    DateTime? issueDate,
    DateTime? redemptionDate,
    String? shareCount,
    double? paymentAmount,
    double? realizedCapital,
    double? transferToOtherProduct,
    double? remainingCapital,
    Map<String, dynamic>? additionalInfo,
    // Apartment-specific fields
    String? apartmentNumber,
    String? building,
    String? address,
    double? area,
    int? roomCount,
    int? floor,
    ApartmentStatus? status,
    ApartmentType? apartmentType,
    double? pricePerSquareMeter,
    bool? hasBalcony,
    bool? hasParkingSpace,
    bool? hasStorage,
    String? developer,
  }) {
    return Apartment(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      capitalForRestructuring:
          capitalForRestructuring ?? this.capitalForRestructuring,
      capitalSecuredByRealEstate:
          capitalSecuredByRealEstate ?? this.capitalSecuredByRealEstate,
      sourceFile: sourceFile ?? this.sourceFile,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      saleId: saleId ?? this.saleId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      advisor: advisor ?? this.advisor,
      branch: branch ?? this.branch,
      productStatus: productStatus ?? this.productStatus,
      marketEntry: marketEntry ?? this.marketEntry,
      signedDate: signedDate ?? this.signedDate,
      investmentEntryDate: investmentEntryDate ?? this.investmentEntryDate,
      projectName: projectName ?? this.projectName,
      creditorCompany: creditorCompany ?? this.creditorCompany,
      companyId: companyId ?? this.companyId,
      issueDate: issueDate ?? this.issueDate,
      redemptionDate: redemptionDate ?? this.redemptionDate,
      shareCount: shareCount ?? this.shareCount,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      realizedCapital: realizedCapital ?? this.realizedCapital,
      transferToOtherProduct:
          transferToOtherProduct ?? this.transferToOtherProduct,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      // Apartment-specific fields
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      building: building ?? this.building,
      address: address ?? this.address,
      area: area ?? this.area,
      roomCount: roomCount ?? this.roomCount,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      apartmentType: apartmentType ?? this.apartmentType,
      pricePerSquareMeter: pricePerSquareMeter ?? this.pricePerSquareMeter,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasParkingSpace: hasParkingSpace ?? this.hasParkingSpace,
      hasStorage: hasStorage ?? this.hasStorage,
      developer: developer ?? this.developer,
    );
  }
}

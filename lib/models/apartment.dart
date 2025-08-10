import 'package:cloud_firestore/cloud_firestore.dart';

enum ApartmentStatus {
  available('Dostępny'),
  sold('Sprzedany'),
  reserved('Zarezerwowany'),
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
  other('Inne');

  const ApartmentType(this.displayName);
  final String displayName;
}

class Apartment {
  final String id;
  final String productType; // typ_produktu
  final double investmentAmount; // kwota_inwestycji
  final double? capitalForRestructuring; // kapital_do_restrukturyzacji
  final double?
  capitalSecuredByRealEstate; // kapital_zabezpieczony_nieruchomoscia
  final String sourceFile; // source_file
  final DateTime createdAt; // created_at
  final DateTime uploadedAt; // uploaded_at

  // Specific apartment fields
  final String apartmentNumber; // numer_apartamentu
  final String building; // budynek
  final String address; // adres
  final double area; // powierzchnia
  final int roomCount; // liczba_pokoi
  final int floor; // pietro
  final ApartmentType apartmentType; // typ_apartamentu
  final ApartmentStatus status; // status
  final double pricePerSquareMeter; // cena_za_m2
  final DateTime? deliveryDate; // data_oddania
  final String? developer; // deweloper
  final String? projectName; // nazwa_projektu
  final bool hasBalcony; // balkon
  final bool hasParkingSpace; // miejsce_parkingowe
  final bool hasStorage; // komórka_lokatorska
  final Map<String, dynamic> additionalInfo;

  Apartment({
    required this.id,
    required this.productType,
    required this.investmentAmount,
    this.capitalForRestructuring,
    this.capitalSecuredByRealEstate,
    required this.sourceFile,
    required this.createdAt,
    required this.uploadedAt,
    required this.apartmentNumber,
    required this.building,
    required this.address,
    required this.area,
    required this.roomCount,
    required this.floor,
    required this.apartmentType,
    required this.status,
    required this.pricePerSquareMeter,
    this.deliveryDate,
    this.developer,
    this.projectName,
    this.hasBalcony = false,
    this.hasParkingSpace = false,
    this.hasStorage = false,
    this.additionalInfo = const {},
  });

  // Calculated properties
  double get totalValue => area * pricePerSquareMeter;
  double get remainingValue => capitalForRestructuring ?? totalValue;

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

    // Helper function to parse date strings
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Helper function to map apartment status
    ApartmentStatus mapStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'dostępny':
        case 'available':
          return ApartmentStatus.available;
        case 'sprzedany':
        case 'sold':
          return ApartmentStatus.sold;
        case 'zarezerwowany':
        case 'reserved':
          return ApartmentStatus.reserved;
        case 'w budowie':
        case 'under construction':
          return ApartmentStatus.underConstruction;
        case 'gotowy':
        case 'ready':
          return ApartmentStatus.ready;
        default:
          return ApartmentStatus.available;
      }
    }

    // Helper function to map apartment type
    ApartmentType mapApartmentType(int roomCount) {
      switch (roomCount) {
        case 1:
          return ApartmentType.studio;
        case 2:
          return ApartmentType.apartment2Room;
        case 3:
          return ApartmentType.apartment3Room;
        case 4:
          return ApartmentType.apartment4Room;
        default:
          if (roomCount > 4) {
            return ApartmentType.penthouse;
          }
          return ApartmentType.other;
      }
    }

    return Apartment(
      id: doc.id,
      productType:
          data['productType'] ??
          data['typ_produktu'] ??
          data['Typ_produktu'] ??
          'Apartamenty',
      investmentAmount: safeToDouble(
        data['investmentAmount'] ??
            data['kwota_inwestycji'] ??
            data['Kwota_inwestycji'],
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

      apartmentNumber:
          data['apartmentNumber'] ?? data['numer_apartamentu'] ?? '',
      building: data['building'] ?? data['budynek'] ?? '',
      address: data['address'] ?? data['adres'] ?? '',
      area: safeToDouble(data['area'] ?? data['powierzchnia']),
      roomCount: safeToInt(data['roomCount'] ?? data['liczba_pokoi']),
      floor: safeToInt(data['floor'] ?? data['pietro']),
      apartmentType: mapApartmentType(
        safeToInt(data['roomCount'] ?? data['liczba_pokoi']),
      ),
      status: mapStatus(data['status']),
      pricePerSquareMeter: safeToDouble(
        data['pricePerM2'] ?? data['cena_za_m2'],
      ),
      deliveryDate: parseDate(data['deliveryDate'] ?? data['data_oddania']),
      developer: data['developer'] ?? data['deweloper'],
      projectName:
          data['projectName'] ??
          data['nazwa_projektu'] ??
          data['Produkt_nazwa'],
      hasBalcony:
          data['balcony'] == 1 ||
          data['balcony'] == true ||
          data['balkon'] == 1 ||
          data['balkon'] == true,
      hasParkingSpace:
          data['parkingSpace'] == 1 ||
          data['parkingSpace'] == true ||
          data['miejsce_parkingowe'] == 1 ||
          data['miejsce_parkingowe'] == true,
      hasStorage:
          data['storageRoom'] == 1 ||
          data['storageRoom'] == true ||
          data['komorka_lokatorska'] == 1 ||
          data['komorka_lokatorska'] == true,

      additionalInfo: Map<String, dynamic>.from(data)
        ..removeWhere(
          (key, value) => [
            'productType',
            'typ_produktu',
            'Typ_produktu',
            'investmentAmount',
            'kwota_inwestycji',
            'Kwota_inwestycji',
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
            'apartmentNumber',
            'numer_apartamentu',
            'building',
            'budynek',
            'address',
            'adres',
            'area',
            'powierzchnia',
            'roomCount',
            'liczba_pokoi',
            'floor',
            'pietro',
            'status',
            'pricePerM2',
            'cena_za_m2',
            'deliveryDate',
            'data_oddania',
            'developer',
            'deweloper',
            'projectName',
            'nazwa_projektu',
            'Produkt_nazwa',
            'balcony',
            'balkon',
            'parkingSpace',
            'miejsce_parkingowe',
            'storageRoom',
            'komorka_lokatorska',
          ].contains(key),
        ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // Znormalizowane nazwy (priorytet)
      'productType': productType,
      'investmentAmount': investmentAmount,
      'capitalForRestructuring': capitalForRestructuring,
      'realEstateSecuredCapital': capitalSecuredByRealEstate,
      'sourceFile': sourceFile,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'apartmentNumber': apartmentNumber,
      'building': building,
      'address': address,
      'area': area,
      'roomCount': roomCount,
      'floor': floor,
      'apartmentType': apartmentType.name,
      'status': status.displayName,
      'pricePerM2': pricePerSquareMeter,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'developer': developer,
      'projectName': projectName,
      'balcony': hasBalcony ? 1 : 0,
      'parkingSpace': hasParkingSpace ? 1 : 0,
      'storageRoom': hasStorage ? 1 : 0,

      // Stare nazwy dla kompatybilności wstecznej
      'typ_produktu': productType,
      'kwota_inwestycji': investmentAmount,
      'kapital_do_restrukturyzacji': capitalForRestructuring,
      'kapital_zabezpieczony_nieruchomoscia': capitalSecuredByRealEstate,
      'source_file': sourceFile,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      'numer_apartamentu': apartmentNumber,
      'budynek': building,
      'adres': address,
      'powierzchnia': area,
      'liczba_pokoi': roomCount,
      'pietro': floor,
      'typ_apartamentu': apartmentType.name,
      'cena_za_m2': pricePerSquareMeter,
      'data_oddania': deliveryDate?.toIso8601String(),
      'deweloper': developer,
      'nazwa_projektu': projectName,
      'balkon': hasBalcony ? 1 : 0,
      'miejsce_parkingowe': hasParkingSpace ? 1 : 0,
      'komorka_lokatorska': hasStorage ? 1 : 0,

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
    String? apartmentNumber,
    String? building,
    String? address,
    double? area,
    int? roomCount,
    int? floor,
    ApartmentType? apartmentType,
    ApartmentStatus? status,
    double? pricePerSquareMeter,
    DateTime? deliveryDate,
    String? developer,
    String? projectName,
    bool? hasBalcony,
    bool? hasParkingSpace,
    bool? hasStorage,
    Map<String, dynamic>? additionalInfo,
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
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      building: building ?? this.building,
      address: address ?? this.address,
      area: area ?? this.area,
      roomCount: roomCount ?? this.roomCount,
      floor: floor ?? this.floor,
      apartmentType: apartmentType ?? this.apartmentType,
      status: status ?? this.status,
      pricePerSquareMeter: pricePerSquareMeter ?? this.pricePerSquareMeter,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      developer: developer ?? this.developer,
      projectName: projectName ?? this.projectName,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasParkingSpace: hasParkingSpace ?? this.hasParkingSpace,
      hasStorage: hasStorage ?? this.hasStorage,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

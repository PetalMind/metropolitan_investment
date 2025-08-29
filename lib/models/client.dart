import 'package:cloud_firestore/cloud_firestore.dart';

enum VotingStatus {
  undecided('Niezdecydowany'),
  yes('Tak'),
  no('Nie'),
  abstain('Wstrzymuje się');

  const VotingStatus(this.displayName);
  final String displayName;
}

enum ClientType {
  individual('Osoba fizyczna'),
  marriage('Małżeństwo'),
  company('Spółka'),
  other('Inne');

  const ClientType(this.displayName);
  final String displayName;
}

enum ContactPreference {
  email('Email'),
  phone('Telefon'),
  sms('SMS'),
  postal('Poczta tradycyjna'),
  none('Brak kontaktu');

  const ContactPreference(this.displayName);
  final String displayName;
}

enum CommunicationLanguage {
  polish('Polski'),
  english('Angielski'),
  german('Niemiecki'),
  french('Francuski');

  const CommunicationLanguage(this.displayName);
  final String displayName;
}

class ContactPreferences {
  final ContactPreference primary;
  final ContactPreference? secondary;
  final CommunicationLanguage language;
  final bool allowMarketing;
  final bool allowNotifications;
  final List<String> availableHours; // np. ["09:00-17:00"]
  final String? notes;

  const ContactPreferences({
    this.primary = ContactPreference.email,
    this.secondary,
    this.language = CommunicationLanguage.polish,
    this.allowMarketing = true,
    this.allowNotifications = true,
    this.availableHours = const ["09:00-17:00"],
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'primaryContact': primary.name,
      'secondaryContact': secondary?.name,
      'language': language.name,
      'allowMarketing': allowMarketing,
      'allowNotifications': allowNotifications,
      'availableHours': availableHours,
      'notes': notes,
    };
  }

  factory ContactPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const ContactPreferences();

    return ContactPreferences(
      primary: ContactPreference.values.firstWhere(
        (e) => e.name == data['primaryContact'],
        orElse: () => ContactPreference.email,
      ),
      secondary: data['secondaryContact'] != null
          ? ContactPreference.values.firstWhere(
              (e) => e.name == data['secondaryContact'],
              orElse: () => ContactPreference.phone,
            )
          : null,
      language: CommunicationLanguage.values.firstWhere(
        (e) => e.name == data['language'],
        orElse: () => CommunicationLanguage.polish,
      ),
      allowMarketing: data['allowMarketing'] ?? true,
      allowNotifications: data['allowNotifications'] ?? true,
      availableHours: List<String>.from(
        data['availableHours'] ?? ["09:00-17:00"],
      ),
      notes: data['notes'],
    );
  }
}

class Client {
  final String id; // UUID from Firestore doc.id
  final String? excelId; // Original numeric ID from Excel
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? pesel;
  final String? companyName;
  final ClientType type;
  final String notes;
  final VotingStatus votingStatus;
  final String colorCode;
  final List<String> unviableInvestments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> additionalInfo;
  final ContactPreferences contactPreferences; // 🚀 NOWE POLE

  Client({
    required this.id,
    this.excelId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.pesel,
    this.companyName,
    this.type = ClientType.individual,
    this.notes = '',
    this.votingStatus = VotingStatus.undecided,
    this.colorCode = '#FFFFFF',
    this.unviableInvestments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.additionalInfo = const {},
    this.contactPreferences =
        const ContactPreferences(), // 🚀 DOMYŚLNE WARTOŚCI
  });

  factory Client.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 🔍 DEBUG: Sprawdź mapowanie pól z Firebase
    final fullName =
        data['fullName'] ?? data['imie_nazwisko'] ?? data['name'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? data['telefon'] ?? '';
    final address = data['address'] ?? '';

    // Helper function to parse date strings or Timestamp
    DateTime parseDateTime(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }

      if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print(
            '⚠️ [Client.fromFirestore] Błąd parsowania daty "$dateValue": $e',
          );
          return DateTime.now();
        }
      }

      print(
        '🔍 [Client.fromFirestore] Nieznany typ daty: $dateValue (${dateValue.runtimeType})',
      );
      return DateTime.now();
    }

    return Client(
      id: doc.id,
      excelId:
          data['excelId']?.toString() ??
          data['original_id']?.toString() ??
          data['id']
              ?.toString(), // DODAJ MAPOWANIE 'id' number z twoich danych!
      name: fullName, // Użyj zmapowanej nazwy
      email: email, // Użyj zmapowanego emaila
      phone: phone, // Użyj zmapowanego telefonu
      address: address, // Użyj zmapowanego adresu
      pesel: data['pesel']?.toString(), // PESEL jest teraz obsługiwany
      companyName: data['companyName'] ?? data['nazwa_firmy'],
      type: ClientType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ClientType.individual,
      ),
      notes: data['notes'] ?? '',
      votingStatus: VotingStatus.values.firstWhere(
        (e) => e.name == data['votingStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      colorCode: data['colorCode'] ?? '#FFFFFF',
      unviableInvestments: List<String>.from(data['unviableInvestments'] ?? []),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDateTime(data['updatedAt'] ?? data['uploaded_at']),
      isActive: data['isActive'] ?? true,
      additionalInfo:
          data['additionalInfo'] ??
          {'sourceFile': data['sourceFile'] ?? data['source_file']},
      contactPreferences: ContactPreferences.fromFirestore(
        data['contactPreferences'] as Map<String, dynamic>?,
      ), // 🎯 NOWE: ContactPreferences
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': name,
      'name': name,
      'imie_nazwisko': name, // Dla kompatybilności z Excel
      'excelId': excelId, // Przechowaj oryginalne numeryczne ID
      'original_id': excelId, // Dodatkowa kompatybilność
      'email': email,
      'phone': phone,
      'telefon': phone, // Dla kompatybilności z Excel
      'address': address,
      'pesel': pesel,
      'companyName': companyName,
      'nazwa_firmy': companyName ?? '', // Dla kompatybilności z Excel
      'type': type.name,
      'notes': notes,
      'votingStatus': votingStatus.name,
      'colorCode': colorCode,
      'unviableInvestments': unviableInvestments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'created_at': createdAt.toIso8601String(), // Dla kompatybilności z Excel
      'uploaded_at': updatedAt.toIso8601String(), // Dla kompatybilności z Excel
      'uploadedAt': updatedAt.toIso8601String(), // Znormalizowana nazwa
      'isActive': isActive,
      'additionalInfo': additionalInfo,
      'sourceFile':
          additionalInfo['sourceFile'] ??
          additionalInfo['source_file'] ??
          'manual_entry',
      'source_file':
          additionalInfo['sourceFile'] ??
          additionalInfo['source_file'] ??
          'manual_entry', // Kompatybilność
      'contactPreferences': contactPreferences
          .toFirestore(), // 🎯 NOWE: ContactPreferences
    };
  }

  Client copyWith({
    String? id,
    String? excelId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? pesel,
    String? companyName,
    ClientType? type,
    String? notes,
    VotingStatus? votingStatus,
    String? colorCode,
    List<String>? unviableInvestments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
    ContactPreferences? contactPreferences, // 🎯 NOWE
  }) {
    return Client(
      id: id ?? this.id,
      excelId: excelId ?? this.excelId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      pesel: pesel ?? this.pesel,
      companyName: companyName ?? this.companyName,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      votingStatus: votingStatus ?? this.votingStatus,
      colorCode: colorCode ?? this.colorCode,
      unviableInvestments: unviableInvestments ?? this.unviableInvestments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      contactPreferences:
          contactPreferences ?? this.contactPreferences, // 🎯 NOWE
    );
  }

  /// Konstruktor do konwersji z danych serwera (Firebase Functions)
  factory Client.fromServerMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;

      // Handle Firestore Timestamp
      if (date is Timestamp) {
        return date.toDate();
      }

      // Handle string dates
      if (date is String && date.isNotEmpty) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return null;
        }
      }

      // Handle DateTime
      if (date is DateTime) return date;

      return null;
    }

    VotingStatus parseVotingStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'yes':
        case 'tak':
          return VotingStatus.yes;
        case 'no':
        case 'nie':
          return VotingStatus.no;
        case 'abstain':
        case 'wstrzymuje się':
          return VotingStatus.abstain;
        default:
          return VotingStatus.undecided;
      }
    }

    ClientType parseClientType(String? type) {
      switch (type?.toLowerCase()) {
        case 'marriage':
        case 'małżeństwo':
          return ClientType.marriage;
        case 'company':
        case 'spółka':
          return ClientType.company;
        case 'other':
        case 'inne':
          return ClientType.other;
        default:
          return ClientType.individual;
      }
    }

    return Client(
      id: map['id']?.toString() ?? '',
      excelId: map['excelId']?.toString() ?? map['original_id']?.toString(),
      name:
          map['fullName'] ??
          map['imie_nazwisko'] ??
          map['name'] ??
          map['clientName'] ??
          map['client_name'] ??
          map['client'] ??
          map['klient'] ??
          '',
      email: map['email']?.toString() ?? '',
      phone: map['phone'] ?? map['telefon'] ?? '',
      address: map['address']?.toString() ?? '',
      pesel: map['pesel']?.toString(),
      companyName: map['companyName'] ?? map['nazwa_firmy'],
      type: parseClientType(map['type']?.toString()),
      notes: map['notes']?.toString() ?? '',
      votingStatus: parseVotingStatus(map['votingStatus']?.toString()),
      colorCode: map['colorCode']?.toString() ?? '#FFFFFF',
      unviableInvestments: (map['unviableInvestments'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>? ?? {},
      contactPreferences: ContactPreferences.fromFirestore(
        map['contactPreferences'] as Map<String, dynamic>?,
      ), // 🎯 NOWE
    );
  }
}

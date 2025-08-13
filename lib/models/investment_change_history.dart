import 'package:cloud_firestore/cloud_firestore.dart';

/// Model dla historii zmian inwestycji
class InvestmentChangeHistory {
  final String id;
  final String investmentId;
  final String userId; // ID użytkownika który wprowadził zmiany
  final String userEmail; // Email użytkownika
  final String userName; // Imię i nazwisko użytkownika
  final DateTime changedAt;
  final String
  changeType; // 'field_update', 'bulk_update', 'import', 'manual_entry'
  final String changeDescription; // Opis ogólny zmiany
  final List<FieldChange> fieldChanges; // Lista konkretnych zmian pól
  final Map<String, dynamic>
  metadata; // Dodatkowe informacje (np. źródło zmiany, wersja aplikacji)

  const InvestmentChangeHistory({
    required this.id,
    required this.investmentId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.changedAt,
    required this.changeType,
    required this.changeDescription,
    required this.fieldChanges,
    this.metadata = const {},
  });

  factory InvestmentChangeHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InvestmentChangeHistory(
      id: doc.id,
      investmentId: data['investmentId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      changedAt: (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changeType: data['changeType'] ?? 'field_update',
      changeDescription: data['changeDescription'] ?? '',
      fieldChanges:
          (data['fieldChanges'] as List<dynamic>?)
              ?.map((item) => FieldChange.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'investmentId': investmentId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'changedAt': Timestamp.fromDate(changedAt),
      'changeType': changeType,
      'changeDescription': changeDescription,
      'fieldChanges': fieldChanges.map((change) => change.toMap()).toList(),
      'metadata': metadata,
    };
  }

  /// Tworzy historię zmian na podstawie porównania starych i nowych wartości
  factory InvestmentChangeHistory.fromChanges({
    required String investmentId,
    required String userId,
    required String userEmail,
    required String userName,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
    String changeType = 'field_update',
    String? customDescription,
    Map<String, dynamic> metadata = const {},
  }) {
    final fieldChanges = <FieldChange>[];
    final changedFields = <String>[];

    // Porównaj wszystkie pola i znajdź zmiany
    for (final key in newValues.keys) {
      final oldValue = oldValues[key];
      final newValue = newValues[key];

      if (oldValue != newValue) {
        fieldChanges.add(
          FieldChange(
            fieldName: key,
            fieldDisplayName: _getFieldDisplayName(key),
            oldValue: oldValue,
            newValue: newValue,
            dataType: _getDataType(newValue),
          ),
        );
        changedFields.add(_getFieldDisplayName(key));
      }
    }

    final description =
        customDescription ?? 'Zaktualizowano pola: ${changedFields.join(', ')}';

    return InvestmentChangeHistory(
      id: '', // Będzie wygenerowane przez Firestore
      investmentId: investmentId,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      changedAt: DateTime.now(),
      changeType: changeType,
      changeDescription: description,
      fieldChanges: fieldChanges,
      metadata: {
        ...metadata,
        'appVersion': '1.0.0',
        'platform': 'flutter',
        'fieldsChanged': changedFields.length,
      },
    );
  }

  /// Mapuje nazwy pól na czytelne etykiety
  static String _getFieldDisplayName(String fieldName) {
    const fieldNames = {
      'investmentAmount': 'Kwota inwestycji',
      'paidAmount': 'Kwota wpłat',
      'remainingCapital': 'Kapitał pozostały',
      'realizedCapital': 'Kapitał zrealizowany',
      'realizedInterest': 'Odsetki zrealizowane',
      'remainingInterest': 'Odsetki pozostałe',
      'transferToOtherProduct': 'Transfer na inny produkt',
      'capitalForRestructuring': 'Kapitał do restrukturyzacji',
      'capitalSecuredByRealEstate': 'Kapitał zabezp. nieruchomościami',
      'plannedTax': 'Planowany podatek',
      'realizedTax': 'Zrealizowany podatek',
      'status': 'Status',
      'marketType': 'Typ rynku',
      'productName': 'Nazwa produktu',
      'clientName': 'Nazwa klienta',
    };

    return fieldNames[fieldName] ?? fieldName;
  }

  /// Określa typ danych dla poprawnego formatowania
  static String _getDataType(dynamic value) {
    if (value is double || value is int) return 'currency';
    if (value is DateTime) return 'date';
    if (value is bool) return 'boolean';
    return 'text';
  }
}

/// Model dla pojedynczej zmiany pola
class FieldChange {
  final String fieldName;
  final String fieldDisplayName;
  final dynamic oldValue;
  final dynamic newValue;
  final String dataType; // 'currency', 'text', 'date', 'boolean'

  const FieldChange({
    required this.fieldName,
    required this.fieldDisplayName,
    required this.oldValue,
    required this.newValue,
    required this.dataType,
  });

  factory FieldChange.fromMap(Map<String, dynamic> map) {
    return FieldChange(
      fieldName: map['fieldName'] ?? '',
      fieldDisplayName: map['fieldDisplayName'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      dataType: map['dataType'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'fieldDisplayName': fieldDisplayName,
      'oldValue': oldValue,
      'newValue': newValue,
      'dataType': dataType,
    };
  }

  /// Formatuje wartość według typu danych
  String formatValue(dynamic value, {bool isOld = false}) {
    if (value == null) return 'Brak wartości';

    switch (dataType) {
      case 'currency':
        if (value is num) {
          return '${value.toStringAsFixed(2)} PLN';
        }
        return value.toString();
      case 'date':
        if (value is DateTime) {
          return '${value.day}.${value.month}.${value.year}';
        }
        return value.toString();
      case 'boolean':
        return value == true ? 'Tak' : 'Nie';
      default:
        return value.toString();
    }
  }

  /// Zwraca opis zmiany w czytelnej formie
  String get changeDescription {
    final oldFormatted = formatValue(oldValue, isOld: true);
    final newFormatted = formatValue(newValue);

    return '$fieldDisplayName: $oldFormatted → $newFormatted';
  }
}

/// Typy zmian dla łatwiejszej kategoryzacji
enum InvestmentChangeType {
  fieldUpdate('field_update', 'Aktualizacja pól'),
  bulkUpdate('bulk_update', 'Aktualizacja masowa'),
  import('import', 'Import z pliku'),
  manualEntry('manual_entry', 'Ręczne wprowadzenie'),
  systemUpdate('system_update', 'Aktualizacja systemowa'),
  correction('correction', 'Korekta danych');

  const InvestmentChangeType(this.value, this.displayName);

  final String value;
  final String displayName;

  static InvestmentChangeType fromValue(String value) {
    return InvestmentChangeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InvestmentChangeType.fieldUpdate,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model dla importowanego klienta z Excel
class ExcelClientData {
  final String rawName;
  final String rawEmail;
  final String rawPhone;
  final String rawAddress;
  final Map<String, dynamic> additionalFields;
  final String sourceFile;
  final String sourceSheet;
  final int sourceRow;

  ExcelClientData({
    required this.rawName,
    required this.rawEmail,
    required this.rawPhone,
    required this.rawAddress,
    this.additionalFields = const {},
    required this.sourceFile,
    required this.sourceSheet,
    required this.sourceRow,
  });

  /// Konwertuje surowe dane Excel na standardowy Client
  Map<String, dynamic> toClientData() {
    return {
      'name': _cleanName(rawName),
      'email': _cleanEmail(rawEmail),
      'phone': _cleanPhone(rawPhone),
      'address': _cleanAddress(rawAddress),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isActive': true,
      'additionalInfo': {
        'source': {
          'file': sourceFile,
          'sheet': sourceSheet,
          'row': sourceRow,
          'importDate': Timestamp.now(),
        },
        'originalData': {
          'rawName': rawName,
          'rawEmail': rawEmail,
          'rawPhone': rawPhone,
          'rawAddress': rawAddress,
        },
        ...additionalFields,
      },
    };
  }

  String _cleanName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _cleanEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _cleanPhone(String phone) {
    // Usuń wszystkie znaki oprócz cyfr, +, -, (, ), spacji
    return phone.replaceAll(RegExp(r'[^\d\+\-\(\)\s]'), '').trim();
  }

  String _cleanAddress(String address) {
    return address.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Model dla importowanej inwestycji z Excel
class ExcelInvestmentData {
  final String clientName;
  final String clientId;
  final String employeeName;
  final String productName;
  final String productType;
  final double amount;
  final DateTime? investmentDate;
  final String status;
  final Map<String, dynamic> additionalFields;
  final String sourceFile;
  final String sourceSheet;
  final int sourceRow;

  ExcelInvestmentData({
    required this.clientName,
    this.clientId = '',
    required this.employeeName,
    required this.productName,
    required this.productType,
    required this.amount,
    this.investmentDate,
    required this.status,
    this.additionalFields = const {},
    required this.sourceFile,
    required this.sourceSheet,
    required this.sourceRow,
  });

  Map<String, dynamic> toInvestmentData() {
    return {
      'clientName': clientName.trim(),
      'clientId': clientId,
      'productName': productName.trim(),
      'productType': _mapProductType(productType),
      'investmentAmount': amount,
      'signedDate': investmentDate != null
          ? Timestamp.fromDate(investmentDate!)
          : Timestamp.now(),
      'status': _mapStatus(status),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'additionalInfo': {
        'source': {
          'file': sourceFile,
          'sheet': sourceSheet,
          'row': sourceRow,
          'importDate': Timestamp.now(),
        },
        'originalData': additionalFields,
      },
    };
  }

  String _mapProductType(String type) {
    final typeMap = {
      'udziały': 'shares',
      'udział': 'shares',
      'obligacje': 'bonds',
      'obligacja': 'bonds',
      'pożyczka': 'loans',
      'pożyczki': 'loans',
      'apartament': 'apartments',
      'apartamenty': 'apartments',
    };

    return typeMap[type.toLowerCase()] ?? 'bonds';
  }

  String _mapStatus(String status) {
    final statusMap = {
      'aktywny': 'active',
      'nieaktywny': 'inactive',
      'zakończony': 'completed',
      'wykup wcześniejszy': 'earlyRedemption',
    };

    return statusMap[status.toLowerCase()] ?? 'active';
  }
}

/// Model dla wyników importu
class ImportResult {
  final int totalProcessed;
  final int successfulImports;
  final int failedImports;
  final int duplicatesSkipped;
  final List<ImportError> errors;
  final DateTime importDate;
  final String sourceFile;

  ImportResult({
    required this.totalProcessed,
    required this.successfulImports,
    required this.failedImports,
    required this.duplicatesSkipped,
    required this.errors,
    required this.importDate,
    required this.sourceFile,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalProcessed': totalProcessed,
      'successfulImports': successfulImports,
      'failedImports': failedImports,
      'duplicatesSkipped': duplicatesSkipped,
      'errors': errors.map((e) => e.toJson()).toList(),
      'importDate': importDate.toIso8601String(),
      'sourceFile': sourceFile,
    };
  }
}

class ImportError {
  final int row;
  final String error;
  final Map<String, dynamic> rowData;

  ImportError({required this.row, required this.error, required this.rowData});

  Map<String, dynamic> toJson() {
    return {'row': row, 'error': error, 'rowData': rowData};
  }
}

/// Konfiguracja mapowania kolumn Excel
class ExcelColumnMapping {
  final Map<String, String> clientFields;
  final Map<String, String> investmentFields;
  final Map<String, String> dateFields;
  final Map<String, String> numericFields;

  ExcelColumnMapping({
    required this.clientFields,
    required this.investmentFields,
    required this.dateFields,
    required this.numericFields,
  });

  static ExcelColumnMapping getDefaultMapping() {
    return ExcelColumnMapping(
      clientFields: {
        'name': 'Nazwa|Imię|Nazwisko|Klient|Client',
        'email': 'Email|E-mail|Mail|Adres email',
        'phone': 'Telefon|Tel|Phone|Numer telefonu',
        'address': 'Adres|Address|Ulica',
      },
      investmentFields: {
        'productName': 'Produkt|Product|Nazwa produktu',
        'productType': 'Typ|Type|Rodzaj',
        'amount': 'Kwota|Amount|Wartość|Suma',
        'status': 'Status|Stan',
      },
      dateFields: {
        'investmentDate': 'Data|Date|Data inwestycji',
        'signedDate': 'Data podpisania|Podpisano',
        'issueDate': 'Data emisji|Emisja',
      },
      numericFields: {
        'amount': 'Kwota|Amount|Wartość|Suma',
        'shares': 'Udziały|Shares|Liczba udziałów',
        'interestRate': 'Oprocentowanie|Rate|Stopa',
      },
    );
  }
}

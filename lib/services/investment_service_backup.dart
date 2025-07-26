import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/employee_service.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmployeeService _employeeService = EmployeeService();
  final String _collection = 'investments';
  
  // Cache pracowników dla lepszej wydajności
  static Map<String, String> _employeeNameToIdCache = {};
  static bool _isCacheLoaded = false;

  // Ładowanie cache'u pracowników
  Future<void> _loadEmployeeCache() async {
    if (_isCacheLoaded) return;
    
    try {
      final snapshot = await _firestore.collection('employees').get();
      _employeeNameToIdCache.clear();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        
        if (fullName.isNotEmpty) {
          _employeeNameToIdCache[fullName] = doc.id;
        }
      }
      
      _isCacheLoaded = true;
    } catch (e) {
      print('Błąd podczas ładowania cache\'u pracowników: $e');
    }
  }

  // Znajdź ID pracownika na podstawie imienia i nazwiska
  Future<String?> _findEmployeeId(String firstName, String lastName) async {
    await _loadEmployeeCache();
    
    final fullName = '$firstName $lastName'.trim();
    return _employeeNameToIdCache[fullName];
  }
  Future<String> createInvestment(Investment investment) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(investment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create investment: $e');
    }
  }

  // Read
  Future<Investment?> getInvestment(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Investment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get investment: $e');
    }
  }

  // Read all - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestments() {
    return _firestore
        .collection(_collection)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get by client - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByClient(String clientName) {
    return _firestore
        .collection(_collection)
        .where('klient', isEqualTo: clientName)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Search - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> searchInvestments(String query) {
    return _firestore
        .collection(_collection)
        .where('klient', isGreaterThanOrEqualTo: query)
        .where('klient', isLessThan: query + '\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investments by employee - NOWE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByEmployee(String employeeName) {
    return _firestore
        .collection(_collection)
        .where('praconwnik_imie', isEqualTo: employeeName)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investment summary - NOWE dla Dashboard
  Future<Map<String, dynamic>> getInvestmentSummary() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalCount = snapshot.docs.length;
    double totalAmount = 0;
    double totalPaid = 0;
    double totalRealized = 0;

    Map<ProductType, int> byProduct = {};
    Map<InvestmentStatus, int> byStatus = {};
    Map<ProductType, double> amountByProduct = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      double amount = _parseDouble(data['kwota_inwestycji']) ?? 0;
      double paid = _parseDouble(data['kwota_wplat']) ?? 0;
      double realized = _parseDouble(data['kapital_zrealizowany']) ?? 0;

      totalAmount += amount;
      totalPaid += paid;
      totalRealized += realized;

      // Mapowanie typu produktu do enum
      ProductType productType = ProductType.bonds;
      final typeStr = data['typ_produktu']?.toString() ?? '';
      if (typeStr == 'Udziały') productType = ProductType.shares;
      if (typeStr == 'Apartamenty') productType = ProductType.apartments;

      byProduct[productType] = (byProduct[productType] ?? 0) + 1;
      amountByProduct[productType] =
          (amountByProduct[productType] ?? 0) + amount;

      // Mapowanie statusu do enum
      InvestmentStatus status = InvestmentStatus.active;
      final statusStr = data['status_produktu']?.toString() ?? '';
      if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
        status = InvestmentStatus.inactive;
      } else if (statusStr == 'Wykup wczesniejszy') {
        status = InvestmentStatus.earlyRedemption;
      }

      byStatus[status] = (byStatus[status] ?? 0) + 1;
    }

    return {
      'totalCount': totalCount,
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalRealized': totalRealized,
      'byProduct': byProduct,
      'byStatus': byStatus,
      'amountByProduct': amountByProduct,
      'averageInvestment': totalCount > 0 ? totalAmount / totalCount : 0,
    };
  }

  // Get investments with pagination - NOWE dla Dashboard
  Future<List<Investment>> getInvestmentsPaginated({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('data_podpisania', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(_collection)
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get investments with pagination: $e');
    }
  }

  // Get investments requiring attention - NOWE dla Dashboard
  Future<List<Investment>> getInvestmentsRequiringAttention() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'data_wykupu',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow),
          )
          .where('data_wykupu', isGreaterThan: Timestamp.fromDate(now))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get investments requiring attention: $e');
    }
  }

  // Get investment statistics - NOWE dla danych z Excel
  Future<Map<String, dynamic>> getInvestmentStats() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalCount = snapshot.docs.length;
    double totalAmount = 0;
    double totalPaid = 0;
    Map<String, int> byProduct = {};
    Map<String, int> byStatus = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      totalAmount += _parseDouble(data['kwota_inwestycji']) ?? 0;
      totalPaid += _parseDouble(data['kwota_wplat']) ?? 0;

      String productType = data['typ_produktu']?.toString() ?? 'Nieznany';
      byProduct[productType] = (byProduct[productType] ?? 0) + 1;

      String status = data['status_produktu']?.toString() ?? 'Nieznany';
      byStatus[status] = (byStatus[status] ?? 0) + 1;
    }

    return {
      'totalCount': totalCount,
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'byProduct': byProduct,
      'byStatus': byStatus,
    };
  }

  // Konwersja danych z Excel do modelu Investment
  Investment _convertExcelDataToInvestment(
    String id,
    Map<String, dynamic> data,
  ) {
    // Mapowanie statusu
    InvestmentStatus status = InvestmentStatus.active;
    final statusStr = data['status_produktu']?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      status = InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      status = InvestmentStatus.earlyRedemption;
    }

    // Mapowanie typu produktu
    ProductType productType = ProductType.bonds;
    final typeStr = data['typ_produktu']?.toString() ?? '';
    if (typeStr == 'Udziały') productType = ProductType.shares;
    if (typeStr == 'Apartamenty') productType = ProductType.apartments;

    return Investment(
      id: id,
      clientId: '', // Nie mamy bezpośredniego mapowania
      clientName: data['klient']?.toString() ?? '',
      employeeId: '',
      employeeFirstName: data['praconwnik_imie']?.toString() ?? '',
      employeeLastName: data['pracownik_nazwisko']?.toString() ?? '',
      contractNumber: data['numer_kontraktu']?.toString() ?? '',
      productName: data['nazwa_produktu']?.toString() ?? '',
      productType: productType,
      amount: double.tryParse(data['wartosc_kontraktu']?.toString() ?? '0') ?? 0.0,
      currency: data['waluta']?.toString() ?? 'PLN',
      status: status,
      contractDate: DateTime.tryParse(data['data_podpisania']?.toString() ?? '') ?? DateTime.now(),
      startDate: DateTime.tryParse(data['data_zawarcia']?.toString() ?? '') ?? DateTime.now(),
      maturityDate: DateTime.tryParse(data['data_wymagalnosci']?.toString() ?? ''),
      notes: '',
      commission: double.tryParse(data['prowizja']?.toString() ?? '0') ?? 0.0,
      commissionRate: double.tryParse(data['procent_prowizji']?.toString() ?? '0') ?? 0.0,
      branch: data['kod_oddzialu']?.toString() ?? '',
    );
  }

  // Konwersja danych z Excel do modelu Investment - ASYNC z wyszukiwaniem Employee ID
  Future<Investment> _convertExcelDataToInvestmentAsync(
    String id,
    Map<String, dynamic> data,
  ) async {
    // Mapowanie statusu
    InvestmentStatus status = InvestmentStatus.active;
    final statusStr = data['status_produktu']?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      status = InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      status = InvestmentStatus.earlyRedemption;
    }

    // Mapowanie typu produktu
    ProductType productType = ProductType.bonds;
    final typeStr = data['typ_produktu']?.toString() ?? '';
    if (typeStr == 'Udziały') productType = ProductType.shares;
    if (typeStr == 'Apartamenty') productType = ProductType.apartments;

    // Znajdź ID pracownika
    final firstName = data['praconwnik_imie']?.toString() ?? '';
    final lastName = data['pracownik_nazwisko']?.toString() ?? '';
    String? employeeId;
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      employeeId = await _findEmployeeId(firstName, lastName);
    }

    return Investment(
      id: id,
      clientId: '', // Nie mamy bezpośredniego mapowania
      clientName: data['klient']?.toString() ?? '',
      employeeId: employeeId ?? '',
      employeeFirstName: firstName,
      employeeLastName: lastName,
      contractNumber: data['numer_kontraktu']?.toString() ?? '',
      productName: data['nazwa_produktu']?.toString() ?? '',
      productType: productType,
      amount: double.tryParse(data['wartosc_kontraktu']?.toString() ?? '0') ?? 0.0,
      currency: data['waluta']?.toString() ?? 'PLN',
      status: status,
      contractDate: DateTime.tryParse(data['data_podpisania']?.toString() ?? '') ?? DateTime.now(),
      startDate: DateTime.tryParse(data['data_zawarcia']?.toString() ?? '') ?? DateTime.now(),
      maturityDate: DateTime.tryParse(data['data_wymagalnosci']?.toString() ?? ''),
      notes: '',
      commission: double.tryParse(data['prowizja']?.toString() ?? '0') ?? 0.0,
      commissionRate: double.tryParse(data['procent_prowizji']?.toString() ?? '0') ?? 0.0,
      branch: data['kod_oddzialu']?.toString() ?? '',
    );
  }
      employeeLastName: data['pracownik_nazwisko']?.toString() ?? '',
      branchCode: data['oddzial']?.toString() ?? '',
      status: status,
      isAllocated: data['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate: _parseDate(data['data_podpisania']) ?? DateTime.now(),
      entryDate: _parseDate(data['data_wejscia_do_inwestycji']),
      exitDate: _parseDate(data['data_wyjscia_z_inwestycji']),
      proposalId: data['id_propozycja_nabycia']?.toString() ?? '',
      productType: productType,
      productName: data['produkt_nazwa']?.toString() ?? '',
      creditorCompany: data['wierzyciel_spolka']?.toString() ?? '',
      companyId: data['id_spolka']?.toString() ?? '',
      issueDate: _parseDate(data['data_emisji']),
      redemptionDate: _parseDate(data['data_wykupu']),
      sharesCount: data['ilosc_udzialow']?.toInt(),
      investmentAmount: _parseDouble(data['kwota_inwestycji']) ?? 0,
      paidAmount: _parseDouble(data['kwota_wplat']) ?? 0,
      realizedCapital: _parseDouble(data['kapital_zrealizowany']) ?? 0,
      realizedInterest: _parseDouble(data['odsetki_zrealizowane']) ?? 0,
      transferToOtherProduct:
          _parseDouble(data['przekaz_na_inny_produkt']) ?? 0,
      remainingCapital: _parseDouble(data['kapital_pozostaly']) ?? 0,
      remainingInterest: _parseDouble(data['odsetki_pozostale']) ?? 0,
      plannedTax: _parseDouble(data['planowany_podatek']) ?? 0,
      realizedTax: _parseDouble(data['zrealizowany_podatek']) ?? 0,
      currency: 'PLN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'source_file': data['source_file'] ?? 'Excel import',
        'original_sale_id': data['id_sprzedaz']?.toString() ?? '',
        'original_client_id': data['id_klient']?.toString() ?? '',
      },
    );
  }

  // Update
  Future<void> updateInvestment(Investment investment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(investment.id)
          .update(investment.toFirestore());
    } catch (e) {
      throw Exception('Failed to update investment: $e');
    }
  }

  // Delete
  Future<void> deleteInvestment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete investment: $e');
    }
  }

  // Funkcje pomocnicze
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue.toString().isEmpty || dateValue.toString() == 'null')
      return null;

    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get investments by branch - NOWE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByBranch(String branchCode) {
    return _firestore
        .collection(_collection)
        .where('oddzial', isEqualTo: branchCode)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investments by product type - NOWE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByProductType(String productType) {
    return _firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: productType)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investments by status - NOWE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status_produktu', isEqualTo: status)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }
}

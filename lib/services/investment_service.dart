import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/product.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      print('Załadowano ${_employeeNameToIdCache.length} pracowników do cache');
    } catch (e) {
      print('Błąd podczas ładowania cache\'u pracowników: $e');
    }
  }

  // Znajdź ID pracownika na podstawie imienia i nazwiska
  Future<String?> _findEmployeeId(String firstName, String lastName) async {
    await _loadEmployeeCache();

    final fullName = '$firstName $lastName'.trim();
    String? employeeId = _employeeNameToIdCache[fullName];

    // Jeśli nie znaleziono dokładnego dopasowania, spróbuj częściowego
    if (employeeId == null && fullName.isNotEmpty) {
      for (var entry in _employeeNameToIdCache.entries) {
        if (entry.key.toLowerCase().contains(fullName.toLowerCase()) ||
            fullName.toLowerCase().contains(entry.key.toLowerCase())) {
          employeeId = entry.value;
          break;
        }
      }
    }

    return employeeId;
  }

  // CRUD Operations
  Future<String> createInvestment(Investment investment) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(investment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Błąd podczas tworzenia inwestycji: $e');
    }
  }

  // Get all investments with pagination - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getAllInvestments({int? limit}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('data_podpisania', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
        .orderBy('klient')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get by status - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByStatus(InvestmentStatus status) {
    String statusStr = 'Aktywny';
    if (status == InvestmentStatus.inactive) statusStr = 'Nieaktywny';
    if (status == InvestmentStatus.earlyRedemption)
      statusStr = 'Wykup wczesniejszy';

    return _firestore
        .collection(_collection)
        .where('status_produktu', isEqualTo: statusStr)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Update investment
  Future<void> updateInvestment(String id, Investment investment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(investment.toFirestore());
    } catch (e) {
      throw Exception('Błąd podczas aktualizacji inwestycji: $e');
    }
  }

  // Delete investment
  Future<void> deleteInvestment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Błąd podczas usuwania inwestycji: $e');
    }
  }

  // Get single investment by ID - ZAKTUALIZOWANE dla danych z Excel
  Future<Investment?> getInvestment(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return _convertExcelDataToInvestment(doc.id, data);
      }
      return null;
    } catch (e) {
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  }

  // Alias dla getInvestmentStatistics - dla kompatybilności
  Future<Map<String, dynamic>> getInvestmentSummary() async {
    return getInvestmentStatistics();
  }

  // Paginated investments - nowa metoda
  Future<List<Investment>> getInvestmentsPaginated({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('data_podpisania', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else if (lastDocumentId != null) {
        // Pobierz DocumentSnapshot na podstawie ID
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
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  } // Investments requiring attention - nowa metoda

  Future<List<Investment>> getInvestmentsRequiringAttention() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'data_wymagalnosci',
            isLessThanOrEqualTo: thirtyDaysFromNow.toIso8601String(),
          )
          .where('status_produktu', isEqualTo: 'Aktywny')
          .orderBy('data_wymagalnosci')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();
    } catch (e) {
      print('Błąd podczas pobierania inwestycji wymagających uwagi: $e');
      return [];
    }
  }

  // Analytics methods - ZAKTUALIZOWANE dla danych z Excel
  Future<Map<String, dynamic>> getInvestmentStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      double totalValue = 0;
      int activeCount = 0;
      int inactiveCount = 0;
      Map<String, int> productTypes = {};
      Map<String, double> employeeCommissions = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final investment = _convertExcelDataToInvestment(doc.id, data);

        totalValue += investment.investmentAmount;

        if (investment.status == InvestmentStatus.active) {
          activeCount++;
        } else {
          inactiveCount++;
        }

        // Count product types
        final productTypeName = investment.productType
            .toString()
            .split('.')
            .last;
        productTypes[productTypeName] =
            (productTypes[productTypeName] ?? 0) + 1;

        // Sum employee commissions
        final employeeName =
            '${investment.employeeFirstName} ${investment.employeeLastName}'
                .trim();
        if (employeeName.isNotEmpty) {
          employeeCommissions[employeeName] =
              (employeeCommissions[employeeName] ?? 0) +
              (investment.realizedInterest * 0.05); // Przykładowa prowizja
        }
      }

      return {
        'totalValue': totalValue,
        'totalCount': snapshot.docs.length,
        'activeCount': activeCount,
        'inactiveCount': inactiveCount,
        'productTypes': productTypes,
        'employeeCommissions': employeeCommissions,
      };
    } catch (e) {
      throw Exception('Błąd podczas pobierania statystyk: $e');
    }
  }

  // Get investments by employee - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByEmployee(
    String employeeFirstName,
    String employeeLastName,
  ) {
    return _firestore
        .collection(_collection)
        .where('praconwnik_imie', isEqualTo: employeeFirstName)
        .where('pracownik_nazwisko', isEqualTo: employeeLastName)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investments by product type - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByProductType(
    ProductType productType,
  ) {
    String typeStr = 'Obligacje';
    if (productType == ProductType.shares) typeStr = 'Udziały';
    if (productType == ProductType.apartments) typeStr = 'Apartamenty';

    return _firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: typeStr)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Get investments within date range - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where(
          'data_podpisania',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        )
        .where(
          'data_podpisania',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        )
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
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
      employeeId: '', // Zostanie wypełnione asynchronicznie
      employeeFirstName: data['praconwnik_imie']?.toString() ?? '',
      employeeLastName: data['pracownik_nazwisko']?.toString() ?? '',
      branchCode: data['kod_oddzialu']?.toString() ?? '',
      status: status,
      isAllocated: data['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate:
          DateTime.tryParse(data['data_podpisania']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: DateTime.tryParse(data['data_zawarcia']?.toString() ?? ''),
      exitDate: DateTime.tryParse(data['data_wymagalnosci']?.toString() ?? ''),
      proposalId: data['numer_kontraktu']?.toString() ?? '',
      productType: productType,
      productName: data['nazwa_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: '',
      issueDate: DateTime.tryParse(data['data_podpisania']?.toString() ?? ''),
      redemptionDate: DateTime.tryParse(
        data['data_wymagalnosci']?.toString() ?? '',
      ),
      sharesCount: null,
      investmentAmount:
          double.tryParse(data['wartosc_kontraktu']?.toString() ?? '0') ?? 0.0,
      paidAmount:
          double.tryParse(data['wartosc_kontraktu']?.toString() ?? '0') ?? 0.0,
      realizedCapital: 0.0,
      realizedInterest: 0.0,
      transferToOtherProduct: 0.0,
      remainingCapital:
          double.tryParse(data['wartosc_kontraktu']?.toString() ?? '0') ?? 0.0,
      remainingInterest: 0.0,
      plannedTax: 0.0,
      realizedTax: 0.0,
      currency: data['waluta']?.toString() ?? 'PLN',
      exchangeRate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'numer_kontraktu': data['numer_kontraktu']?.toString() ?? '',
        'prowizja': data['prowizja']?.toString() ?? '',
        'procent_prowizji': data['procent_prowizji']?.toString() ?? '',
      },
    );
  }

  // Metoda do aktualizacji employeeId w istniejących inwestycjach
  Future<void> updateEmployeeIdsInInvestments() async {
    try {
      await _loadEmployeeCache();
      print('Rozpoczynam aktualizację Employee ID w inwestycjach...');

      final snapshot = await _firestore.collection(_collection).get();
      int updated = 0;
      int total = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final firstName = data['praconwnik_imie']?.toString() ?? '';
        final lastName = data['pracownik_nazwisko']?.toString() ?? '';

        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          final employeeId = await _findEmployeeId(firstName, lastName);
          if (employeeId != null && employeeId.isNotEmpty) {
            await doc.reference.update({'employeeId': employeeId});
            updated++;
            if (updated % 10 == 0) {
              print('Zaktualizowano $updated/$total inwestycji...');
            }
          }
        }
      }

      print(
        'Aktualizacja zakończona: $updated/$total inwestycji zostało zaktualizowanych',
      );
    } catch (e) {
      print('Błąd podczas aktualizacji Employee ID: $e');
    }
  }
}

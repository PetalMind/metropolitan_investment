import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';

class OptimizedInvestmentService extends BaseService {
  final String _collection = 'investments';

  // CRUD Operations
  Future<String> createInvestment(Investment investment) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(investment.toFirestore());
      clearCache('investment_stats');
      return docRef.id;
    } catch (e) {
      logError('createInvestment', e);
      throw Exception('Błąd podczas tworzenia inwestycji: $e');
    }
  }

  // Optymalizowana paginacja z filtrami
  Future<PaginationResult<Investment>> getInvestmentsPaginated({
    PaginationParams params = const PaginationParams(),
    FilterParams? filters,
  }) async {
    try {
      Query query = firestore.collection(_collection);

      // Aplikuj filtry
      if (filters != null) {
        // Filtry where
        filters.whereConditions.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });

        // Filtry dat
        if (filters.startDate != null && filters.dateField != null) {
          query = query.where(
            filters.dateField!,
            isGreaterThanOrEqualTo: filters.startDate!.toIso8601String(),
          );
        }
        if (filters.endDate != null && filters.dateField != null) {
          query = query.where(
            filters.dateField!,
            isLessThanOrEqualTo: filters.endDate!.toIso8601String(),
          );
        }
      }

      query = query
          .orderBy(
            params.orderBy ?? 'data_podpisania',
            descending: params.descending,
          )
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final investments = snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();

      return PaginationResult<Investment>(
        items: investments,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getInvestmentsPaginated', e);
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  }

  // Stream z limitami dla lepszej wydajności
  Stream<List<Investment>> getAllInvestments({int limit = 50}) {
    return firestore
        .collection(_collection)
        .orderBy('data_podpisania', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Wyszukiwanie z optymalizacją
  Stream<List<Investment>> searchInvestments(String query, {int limit = 30}) {
    if (query.isEmpty) return getAllInvestments(limit: limit);

    return firestore
        .collection(_collection)
        .where('klient', isGreaterThanOrEqualTo: query)
        .where('klient', isLessThan: query + '\uf8ff')
        .orderBy('klient')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Inwestycje według klienta z limitami
  Stream<List<Investment>> getInvestmentsByClient(
    String clientName, {
    int limit = 20,
  }) {
    return firestore
        .collection(_collection)
        .where('klient', isEqualTo: clientName)
        .orderBy('data_podpisania', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList(),
        );
  }

  // Inwestycje według statusu z optymalizacją - używa indeksu compound (status_produktu + data_podpisania DESC)
  Stream<List<Investment>> getInvestmentsByStatus(
    InvestmentStatus status, {
    int limit = 50,
  }) {
    // Mapuj status do polskiego stringa używanego w Firebase
    String statusStr = 'Aktywny';
    if (status == InvestmentStatus.inactive) statusStr = 'Nieaktywny';
    if (status == InvestmentStatus.earlyRedemption)
      statusStr = 'Wykup wczesniejszy';
    if (status == InvestmentStatus.completed) statusStr = 'Zakończony';

    print(
      '🔍 [OptimizedInvestmentService] Stream inwestycji dla statusu: $statusStr',
    );

    // Używa compound indeksu: status_produktu + data_podpisania DESC
    return firestore
        .collection(_collection)
        .where('status_produktu', isEqualTo: statusStr)
        .orderBy('data_podpisania', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print(
            '🔍 [OptimizedInvestmentService] Stream otrzymał ${snapshot.docs.length} dokumentów dla statusu: $statusStr',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return _convertExcelDataToInvestment(doc.id, data);
          }).toList();
        });
  }

  // Statystyki z cache
  Future<Map<String, dynamic>> getInvestmentStatistics() async {
    return getCachedData('investment_stats', () async {
      try {
        // Używamy aggregate queries dla lepszej wydajności
        final activeSnapshot = await firestore
            .collection(_collection)
            .where('status_produktu', isEqualTo: 'Aktywny')
            .count()
            .get();

        final inactiveSnapshot = await firestore
            .collection(_collection)
            .where('status_produktu', isEqualTo: 'Nieaktywny')
            .count()
            .get();

        // Pobierz próbkę danych dla obliczeń wartości
        final sampleSnapshot = await firestore
            .collection(_collection)
            .limit(1000) // Próbka dla szybszych obliczeń
            .get();

        double totalValue = 0;
        Map<String, int> productTypes = {};
        Map<String, double> employeeCommissions = {};

        for (var doc in sampleSnapshot.docs) {
          final data = doc.data();
          final investment = _convertExcelDataToInvestment(doc.id, data);

          // ⭐ TYLKO KAPITAŁ POZOSTAŁY - dla wszystkich typów produktów
          totalValue += investment.remainingCapital;

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
                (investment.realizedInterest * 0.05);
          }
        }

        // Oszacuj całkowitą wartość na podstawie próbki
        final totalCount =
            (activeSnapshot.count ?? 0) + (inactiveSnapshot.count ?? 0);
        if (sampleSnapshot.docs.length > 0) {
          totalValue = totalValue * (totalCount / sampleSnapshot.docs.length);
        }

        return {
          'totalValue': totalValue,
          'totalCount': totalCount,
          'activeCount': activeSnapshot.count ?? 0,
          'inactiveCount': inactiveSnapshot.count ?? 0,
          'productTypes': productTypes,
          'employeeCommissions': employeeCommissions,
          'isSample': sampleSnapshot.docs.length < totalCount,
        };
      } catch (e) {
        logError('getInvestmentStatistics', e);
        throw Exception('Błąd podczas pobierania statystyk: $e');
      }
    });
  }

  // Inwestycje wymagające uwagi - używa indeksu compound (data_wymagalnosci + status_produktu)
  Future<List<Investment>> getInvestmentsRequiringAttention({
    int limit = 50,
  }) async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      print(
        '🔍 [OptimizedInvestmentService] Pobieranie inwestycji wymagających uwagi do daty: ${thirtyDaysFromNow.toIso8601String()}',
      );

      // Używa compound indeksu: data_wymagalnosci + status_produktu
      final snapshot = await firestore
          .collection(_collection)
          .where(
            'data_wymagalnosci',
            isLessThanOrEqualTo: thirtyDaysFromNow.toIso8601String(),
          )
          .where('status_produktu', isEqualTo: 'Aktywny')
          .orderBy('data_wymagalnosci')
          .orderBy('status_produktu')
          .limit(limit)
          .get();

      final investments = snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();

      print(
        '🔍 [OptimizedInvestmentService] Pobrano ${investments.length} inwestycji wymagających uwagi',
      );
      return investments;
    } catch (e) {
      logError('getInvestmentsRequiringAttention', e);
      print('❌ Błąd getInvestmentsRequiringAttention: $e');
      return []; // Zwróć pustą listę zamiast rzucać wyjątek
    }
  }

  // Standardowe operacje CRUD
  Future<void> updateInvestment(String id, Investment investment) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(investment.toFirestore());
      clearCache('investment_stats');
    } catch (e) {
      logError('updateInvestment', e);
      throw Exception('Błąd podczas aktualizacji inwestycji: $e');
    }
  }

  Future<void> deleteInvestment(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('investment_stats');
    } catch (e) {
      logError('deleteInvestment', e);
      throw Exception('Błąd podczas usuwania inwestycji: $e');
    }
  }

  Future<Investment?> getInvestment(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return _convertExcelDataToInvestment(doc.id, data);
      }
      return null;
    } catch (e) {
      logError('getInvestment', e);
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  }

  // Konwersja danych z Excel do modelu Investment
  Investment _convertExcelDataToInvestment(String id, Object? data) {
    final Map<String, dynamic> dataMap = data as Map<String, dynamic>;
    // Mapowanie statusu
    InvestmentStatus status = InvestmentStatus.active;
    final statusStr = dataMap['status_produktu']?.toString() ?? '';
    if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
      status = InvestmentStatus.inactive;
    } else if (statusStr == 'Wykup wczesniejszy') {
      status = InvestmentStatus.earlyRedemption;
    }

    // Mapowanie typu produktu
    ProductType productType = ProductType.bonds;
    final typeStr = dataMap['typ_produktu']?.toString() ?? '';
    if (typeStr == 'Udziały') productType = ProductType.shares;
    if (typeStr == 'Apartamenty') productType = ProductType.apartments;

    return Investment(
      id: id,
      clientId: '',
      clientName: dataMap['klient']?.toString() ?? '',
      employeeId: '',
      employeeFirstName: dataMap['pracownik_imie']?.toString() ?? '',
      employeeLastName: dataMap['pracownik_nazwisko']?.toString() ?? '',
      branchCode: dataMap['kod_oddzialu']?.toString() ?? '',
      status: status,
      isAllocated: dataMap['przydzial']?.toString() == '1',
      marketType: MarketType.primary,
      signedDate:
          DateTime.tryParse(dataMap['data_podpisania']?.toString() ?? '') ??
          DateTime.now(),
      entryDate: DateTime.tryParse(dataMap['data_zawarcia']?.toString() ?? ''),
      exitDate: DateTime.tryParse(
        dataMap['data_wymagalnosci']?.toString() ?? '',
      ),
      proposalId: dataMap['numer_kontraktu']?.toString() ?? '',
      productType: productType,
      productName: dataMap['nazwa_produktu']?.toString() ?? '',
      creditorCompany: '',
      companyId: '',
      issueDate: DateTime.tryParse(
        dataMap['data_podpisania']?.toString() ?? '',
      ),
      redemptionDate: DateTime.tryParse(
        dataMap['data_wymagalnosci']?.toString() ?? '',
      ),
      sharesCount: null,
      investmentAmount:
          double.tryParse(dataMap['wartosc_kontraktu']?.toString() ?? '0') ??
          0.0,
      paidAmount:
          double.tryParse(dataMap['wartosc_kontraktu']?.toString() ?? '0') ??
          0.0,
      realizedCapital: 0.0,
      realizedInterest: 0.0,
      transferToOtherProduct: 0.0,
      remainingCapital:
          double.tryParse(dataMap['wartosc_kontraktu']?.toString() ?? '0') ??
          0.0,
      remainingInterest: 0.0,
      plannedTax: 0.0,
      realizedTax: 0.0,
      currency: dataMap['waluta']?.toString() ?? 'PLN',
      exchangeRate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: {
        'numer_kontraktu': dataMap['numer_kontraktu']?.toString() ?? '',
        'prowizja': dataMap['prowizja']?.toString() ?? '',
        'procent_prowizji': dataMap['procent_prowizji']?.toString() ?? '',
      },
    );
  }

  /// Pobiera top inwestycje według wartości - używa indeksu compound (wartosc_kontraktu DESC + status_produktu)
  Future<List<Investment>> getTopInvestments(
    InvestmentStatus status, {
    int limit = 10,
  }) async {
    try {
      // Mapuj status do polskiego stringa używanego w Firebase
      String statusStr = 'Aktywny';
      if (status == InvestmentStatus.inactive) statusStr = 'Nieaktywny';
      if (status == InvestmentStatus.earlyRedemption)
        statusStr = 'Wykup wczesniejszy';
      if (status == InvestmentStatus.completed) statusStr = 'Zakończony';

      print(
        '🔍 [OptimizedInvestmentService] Pobieranie top inwestycji dla statusu: $statusStr',
      );

      // Używa compound indeksu: wartosc_kontraktu DESC + status_produktu
      final snapshot = await firestore
          .collection(_collection)
          .where('status_produktu', isEqualTo: statusStr)
          .orderBy('wartosc_kontraktu', descending: true)
          .limit(limit)
          .get();

      final investments = snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();

      print(
        '🔍 [OptimizedInvestmentService] Pobrano ${investments.length} top inwestycji',
      );
      return investments;
    } catch (e) {
      logError('getTopInvestments', e);
      print('❌ Błąd getTopInvestments: $e');
      return []; // Zwróć pustą listę zamiast rzucać wyjątek
    }
  }

  /// Pobiera najnowsze inwestycje (ostatnie N dni) - używa indeksu data_podpisania + data_wymagalnosci
  Future<List<Investment>> getRecentInvestments({int days = 30}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffDateStr = cutoffDate.toIso8601String();

      print(
        '🔍 [OptimizedInvestmentService] Pobieranie inwestycji od daty: $cutoffDateStr',
      );

      // Używa indeksu: data_podpisania + data_wymagalnosci
      final snapshot = await firestore
          .collection(_collection)
          .where('data_podpisania', isGreaterThanOrEqualTo: cutoffDateStr)
          .orderBy('data_podpisania', descending: true)
          .orderBy('data_wymagalnosci')
          .get();

      final investments = snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertExcelDataToInvestment(doc.id, data);
      }).toList();

      print(
        '🔍 [OptimizedInvestmentService] Pobrano ${investments.length} najnowszych inwestycji',
      );
      return investments;
    } catch (e) {
      logError('getRecentInvestments', e);
      print('❌ Błąd getRecentInvestments: $e');
      return []; // Zwróć pustą listę zamiast rzucać wyjątek
    }
  }
}

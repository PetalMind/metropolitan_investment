import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';
import '../models/product.dart';
import 'base_service.dart';
import 'data_cache_service.dart';

class InvestmentService extends BaseService {
  final String _collection = 'investments';
  final DataCacheService _dataCacheService = DataCacheService();

  // CRUD Operations
  Future<String> createInvestment(Investment investment) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(investment.toFirestore());
      clearCache('investment_stats');
      _dataCacheService.invalidateCollectionCache('investments');
      return docRef.id;
    } catch (e) {
      logError('createInvestment', e);
      throw Exception('Błąd podczas tworzenia inwestycji: $e');
    }
  }

  // Load all investments with progress tracking
  Future<List<Investment>> loadAllInvestmentsWithProgress({
    required Function(double progress, String stage) onProgress,
  }) async {
    try {
      onProgress(0.1, 'Łączenie z bazą danych...');
      await Future.delayed(const Duration(milliseconds: 300));

      onProgress(0.2, 'Pobieranie liczby rekordów...');
      final countSnapshot = await firestore
          .collection(_collection)
          .count()
          .get();
      final totalCount = countSnapshot.count ?? 0;

      onProgress(0.3, 'Rozpoczynanie pobierania danych...');
      await Future.delayed(const Duration(milliseconds: 200));

      const batchSize = 500;
      List<Investment> allInvestments = [];
      DocumentSnapshot? lastDoc;
      int processedCount = 0;

      while (true) {
        Query query = firestore
            .collection(_collection)
            .orderBy('data_podpisania', descending: true)
            .limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) break;

        // Process batch
        for (var doc in snapshot.docs) {
          allInvestments.add(Investment.fromFirestore(doc));
          processedCount++;

          // Update progress
          final progress = 0.3 + (processedCount / totalCount) * 0.6;
          if (processedCount % 50 == 0) {
            onProgress(
              progress,
              'Przetwarzanie danych: $processedCount/$totalCount inwestycji',
            );
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }

        lastDoc = snapshot.docs.last;

        if (snapshot.docs.length < batchSize) break;
      }

      onProgress(0.95, 'Finalizacja ładowania...');
      await Future.delayed(const Duration(milliseconds: 200));

      onProgress(1.0, 'Gotowe!');
      return allInvestments;
    } catch (e) {
      logError('loadAllInvestmentsWithProgress', e);
      throw Exception('Błąd podczas ładowania inwestycji: $e');
    }
  }

  // Get all investments with pagination i optymalizacją - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getAllInvestments({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .orderBy('data_podpisania', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return Investment.fromFirestore(doc);
      }).toList(),
    );
  }

  // Paginowana wersja z pełną optymalizacją
  Future<PaginationResult<Investment>> getAllInvestmentsPaginated({
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
        return Investment.fromFirestore(doc);
      }).toList();

      return PaginationResult<Investment>(
        items: investments,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getAllInvestmentsPaginated', e);
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  }

  // Get by client - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByClient(String clientName) {
    return firestore
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
    return firestore
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

    return firestore
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
      await firestore
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
      await firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Błąd podczas usuwania inwestycji: $e');
    }
  }

  // Get single investment by ID - ZAKTUALIZOWANE dla danych z Excel
  Future<Investment?> getInvestment(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
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
      Query query = firestore
          .collection(_collection)
          .orderBy('data_podpisania', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else if (lastDocumentId != null) {
        // Pobierz DocumentSnapshot na podstawie ID
        final lastDoc = await firestore
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

      final snapshot = await firestore
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

  // Analytics methods - ZOPTYMALIZOWANA WERSJA (używa cache)
  Future<Map<String, dynamic>> getInvestmentStatistics() async {
    return getCachedData('investment_stats', () async {
      try {
        // Pobierz wszystkie inwestycje z cache'a
        final allInvestments = await _dataCacheService.getAllInvestments();
        
        if (allInvestments.isEmpty) {
          return {
            'totalValue': 0.0,
            'totalCount': 0,
            'activeCount': 0,
            'inactiveCount': 0,
            'productTypes': <String, int>{},
            'employeeCommissions': <String, double>{},
          };
        }

        double totalValue = 0;
        int activeCount = 0;
        int inactiveCount = 0;
        Map<String, int> productTypes = {};
        Map<String, double> employeeCommissions = {};

        for (final investment in allInvestments) {
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

        print('📊 [InvestmentService] Statystyki inwestycji: ${allInvestments.length} pozycji, ${totalValue.toStringAsFixed(0)} PLN');

        return {
          'totalValue': totalValue,
          'totalCount': allInvestments.length,
          'activeCount': activeCount,
          'inactiveCount': inactiveCount,
          'productTypes': productTypes,
          'employeeCommissions': employeeCommissions,
        };
      } catch (e) {
        logError('getInvestmentStatistics', e);
        return {
          'totalValue': 0.0,
          'totalCount': 0,
          'activeCount': 0,
          'inactiveCount': 0,
          'productTypes': <String, int>{},
          'employeeCommissions': <String, double>{},
        };
      }
    });
  }

  // Get investments by employee - ZAKTUALIZOWANE dla danych z Excel
  Stream<List<Investment>> getInvestmentsByEmployee(
    String employeeFirstName,
    String employeeLastName,
  ) {
    return firestore
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

    return firestore
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
    return firestore
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

  // Konwersja danych z Firebase do modelu Investment - używa bezpośrednio danych
  Investment _convertExcelDataToInvestment(
    String id,
    Map<String, dynamic> data,
  ) {
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

    // Helper function to map product type from Polish to enum
    ProductType mapProductType(String? productType) {
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

    return defaultValue;
    }

    return Investment(
      id: id,
      clientId: data['id_klient']?.toString() ?? '',
      clientName: data['klient'] ?? '',
      employeeId: '', // Not directly available in Firebase structure
      employeeFirstName: data['praconwnik_imie'] ?? '',
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

  // Invalidate cache when data changes
  void invalidateCache() {
    clearCache('investment_stats');
    _dataCacheService.invalidateCollectionCache('investments');
  }
}

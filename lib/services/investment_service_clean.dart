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

  // Update investment
  Future<void> updateInvestment(String id, Investment investment) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(investment.toFirestore());
      clearCache('investment_stats');
      _dataCacheService.invalidateCollectionCache('investments');
    } catch (e) {
      logError('updateInvestment', e);
      throw Exception('Błąd podczas aktualizacji inwestycji: $e');
    }
  }

  // Delete investment
  Future<void> deleteInvestment(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
      clearCache('investment_stats');
      _dataCacheService.invalidateCollectionCache('investments');
    } catch (e) {
      logError('deleteInvestment', e);
      throw Exception('Błąd podczas usuwania inwestycji: $e');
    }
  }

  // Get single investment by ID
  Future<Investment?> getInvestment(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Investment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getInvestment', e);
      throw Exception('Błąd podczas pobierania inwestycji: $e');
    }
  }

  // Get all investments
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

  // Statystyki z cache - ZOPTYMALIZOWANA WERSJA
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

        print(
          '📊 [InvestmentService] Statystyki inwestycji: ${allInvestments.length} pozycji, ${totalValue.toStringAsFixed(0)} PLN',
        );

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

  // Alias dla getInvestmentStatistics - dla kompatybilności
  Future<Map<String, dynamic>> getInvestmentSummary() async {
    return getInvestmentStatistics();
  }

  // Get investments by client
  Stream<List<Investment>> getInvestmentsByClient(String clientName) {
    return firestore
        .collection(_collection)
        .where('klient', isEqualTo: clientName)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Search investments
  Stream<List<Investment>> searchInvestments(String query) {
    return firestore
        .collection(_collection)
        .where('klient', isGreaterThanOrEqualTo: query)
        .where('klient', isLessThan: query + '\uf8ff')
        .orderBy('klient')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Get investments by status
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
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Get investments by product type
  Stream<List<Investment>> getInvestmentsByProductType(
    ProductType productType,
  ) {
    String typeStr = 'Obligacje';
    if (productType == ProductType.shares) typeStr = 'Udziały';
    if (productType == ProductType.loans) typeStr = 'Pożyczki';
    if (productType == ProductType.apartments) typeStr = 'Apartamenty';

    return firestore
        .collection(_collection)
        .where('typ_produktu', isEqualTo: typeStr)
        .orderBy('data_podpisania', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Get investments by employee
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
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Get investments within date range
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
            return Investment.fromFirestore(doc);
          }).toList(),
        );
  }

  // Investments requiring attention
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
        return Investment.fromFirestore(doc);
      }).toList();
    } catch (e) {
      logError('getInvestmentsRequiringAttention', e);
      return [];
    }
  }

  // Invalidate cache when data changes
  void invalidateCache() {
    clearCache('investment_stats');
    _dataCacheService.invalidateCollectionCache('investments');
  }
}

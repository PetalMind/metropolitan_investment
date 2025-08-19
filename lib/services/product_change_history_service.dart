import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Serwis do zarządzania historią zmian produktów
/// Pobiera historię zmian wszystkich inwestycji powiązanych z produktem
class ProductChangeHistoryService extends BaseService {
  final InvestmentChangeHistoryService _investmentHistoryService =
      InvestmentChangeHistoryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pobiera historię zmian dla produktu
  /// Wyszukuje wszystkie inwestycje z danym productId/productName
  /// i zwraca ich historię zmian
  Future<List<InvestmentChangeHistory>> getProductHistory(
    String productId, {
    String? productName,
    int limit = 100,
  }) async {
    try {
      print('📚 [ProductChangeHistory] Pobieranie historii produktu: $productId');
      
      // Znajdź wszystkie inwestycje powiązane z tym produktem
      final investmentIds = await _findRelatedInvestments(
        productId: productId,
        productName: productName,
      );

      if (investmentIds.isEmpty) {
        print('   - Brak powiązanych inwestycji dla produktu');
        return [];
      }

      print('   - Znaleziono ${investmentIds.length} powiązanych inwestycji');

      // Pobierz historię zmian dla wszystkich powiązanych inwestycji
      final allHistory = <InvestmentChangeHistory>[];

      // Firestore 'whereIn' ma limit 10 elementów, więc podziel na batche
      const batchSize = 10;
      for (int i = 0; i < investmentIds.length; i += batchSize) {
        final batch = investmentIds
            .skip(i)
            .take(batchSize)
            .toList();

        final batchHistory = await _getHistoryForInvestmentBatch(batch);
        allHistory.addAll(batchHistory);
      }

      // Posortuj według daty (najnowsze pierwsz)
      allHistory.sort((a, b) => b.changedAt.compareTo(a.changedAt));

      // Ogranicz do podanej liczby wyników
      final limitedHistory = allHistory.take(limit).toList();

      print('✅ [ProductChangeHistory] Pobrano ${limitedHistory.length} wpisów historii');
      return limitedHistory;

    } catch (e) {
      print('❌ [ProductChangeHistory] Błąd podczas pobierania historii: $e');
      logError('getProductHistory', 'Błąd podczas pobierania historii produktu: $e');
      return [];
    }
  }

  /// Znajdź wszystkie inwestycje powiązane z produktem
  Future<List<String>> _findRelatedInvestments({
    required String productId,
    String? productName,
  }) async {
    final investmentIds = <String>[];

    try {
      // Strategia 1: Szukaj po productId
      if (productId.isNotEmpty) {
        final queryByProductId = await _firestore
            .collection('investments')
            .where('productId', isEqualTo: productId)
            .get();

        investmentIds.addAll(queryByProductId.docs.map((doc) => doc.id));
      }

      // Strategia 2: Szukaj po productName (jeśli podano i jeszcze nie znaleziono)
      if (investmentIds.isEmpty && productName != null && productName.isNotEmpty) {
        final queryByProductName = await _firestore
            .collection('investments')
            .where('productName', isEqualTo: productName)
            .get();

        investmentIds.addAll(queryByProductName.docs.map((doc) => doc.id));
      }

      // Strategia 3: Szukaj po nazwie produktu w różnych formatach
      if (investmentIds.isEmpty && productName != null && productName.isNotEmpty) {
        // Próbuj różne warianty nazwy produktu
        final nameVariants = [
          productName,
          productName.toLowerCase(),
          productName.toUpperCase(),
        ];

        for (final nameVariant in nameVariants) {
          final query = await _firestore
              .collection('investments')
              .where('Produkt_nazwa', isEqualTo: nameVariant)
              .get();

          if (query.docs.isNotEmpty) {
            investmentIds.addAll(query.docs.map((doc) => doc.id));
            break;
          }
        }
      }

    } catch (e) {
      print('❌ [ProductChangeHistory] Błąd podczas wyszukiwania inwestycji: $e');
    }

    return investmentIds.toSet().toList(); // Usuń duplikaty
  }

  /// Pobiera historię dla grupy inwestycji
  Future<List<InvestmentChangeHistory>> _getHistoryForInvestmentBatch(
    List<String> investmentIds,
  ) async {
    if (investmentIds.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('investment_change_history')
          .where('investmentId', whereIn: investmentIds)
          .orderBy('changedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvestmentChangeHistory.fromFirestore(doc))
          .toList();

    } catch (e) {
      print('❌ [ProductChangeHistory] Błąd podczas pobierania historii batch: $e');
      return [];
    }
  }

  /// Pobiera statystyki historii zmian dla produktu
  Future<ProductHistoryStats> getProductHistoryStats(
    String productId, {
    String? productName,
  }) async {
    try {
      final history = await getProductHistory(
        productId,
        productName: productName,
        limit: 1000, // Pobierz więcej dla statystyk
      );

      final stats = ProductHistoryStats.fromHistory(history);
      return stats;

    } catch (e) {
      print('❌ [ProductChangeHistory] Błąd podczas pobierania statystyk: $e');
      return ProductHistoryStats.empty();
    }
  }
}

/// Statystyki historii zmian produktu
class ProductHistoryStats {
  final int totalChanges;
  final int uniqueUsers;
  final DateTime? lastChange;
  final DateTime? firstChange;
  final Map<String, int> changesByType;
  final List<String> mostActiveUsers;

  const ProductHistoryStats({
    required this.totalChanges,
    required this.uniqueUsers,
    this.lastChange,
    this.firstChange,
    required this.changesByType,
    required this.mostActiveUsers,
  });

  factory ProductHistoryStats.fromHistory(List<InvestmentChangeHistory> history) {
    if (history.isEmpty) {
      return ProductHistoryStats.empty();
    }

    final userChanges = <String, int>{};
    final typeChanges = <String, int>{};

    for (final entry in history) {
      // Zlicz zmiany według użytkowników
      userChanges[entry.userName] = (userChanges[entry.userName] ?? 0) + 1;
      
      // Zlicz zmiany według typów
      typeChanges[entry.changeType] = (typeChanges[entry.changeType] ?? 0) + 1;
    }

    // Sortuj użytkowników według aktywności
    final sortedUsers = userChanges.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ProductHistoryStats(
      totalChanges: history.length,
      uniqueUsers: userChanges.length,
      lastChange: history.first.changedAt,
      firstChange: history.last.changedAt,
      changesByType: typeChanges,
      mostActiveUsers: sortedUsers.take(5).map((e) => e.key).toList(),
    );
  }

  factory ProductHistoryStats.empty() {
    return const ProductHistoryStats(
      totalChanges: 0,
      uniqueUsers: 0,
      changesByType: {},
      mostActiveUsers: [],
    );
  }

  bool get hasHistory => totalChanges > 0;

  String get lastChangeText {
    if (lastChange == null) return 'Brak zmian';
    
    final now = DateTime.now();
    final difference = now.difference(lastChange!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dni temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} godzin temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minut temu';
    } else {
      return 'Przed chwilą';
    }
  }
}
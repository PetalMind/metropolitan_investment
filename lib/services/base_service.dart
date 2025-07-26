import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Klasa bazowa dla wszystkich serwisów z optymalizacjami wydajnościowymi
abstract class BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache dla lepszej wydajności
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Pobiera Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Sprawdza czy cache jest aktualny
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Pobiera dane z cache lub wykonuje query
  Future<T> getCachedData<T>(
    String cacheKey,
    Future<T> Function() query,
  ) async {
    if (_isCacheValid(cacheKey) && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as T;
    }

    final result = await query();
    _cache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return result;
  }

  /// Czyści cache dla danego klucza
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Czyści cały cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Loguje błędy w trybie debug
  void logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('[$runtimeType] Błąd w $operation: $error');
    }
  }
}

/// Klasa pomocnicza dla paginacji
class PaginationResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalCount;

  const PaginationResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    this.totalCount = 0,
  });
}

/// Parametry paginacji
class PaginationParams {
  final int limit;
  final DocumentSnapshot? startAfter;
  final String? orderBy;
  final bool descending;

  const PaginationParams({
    this.limit = 20,
    this.startAfter,
    this.orderBy,
    this.descending = false,
  });
}

/// Parametry filtrowania
class FilterParams {
  final Map<String, dynamic> whereConditions;
  final Map<String, dynamic> arrayContains;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateField;

  const FilterParams({
    this.whereConditions = const {},
    this.arrayContains = const {},
    this.startDate,
    this.endDate,
    this.dateField,
  });
}

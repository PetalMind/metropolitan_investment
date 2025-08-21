import 'package:cloud_functions/cloud_functions.dart';
import '../models_and_services.dart';

/// 🚀 Enhanced Client Service - używa Firebase Functions do optymalizacji
///
/// Przenosi ciężkie operacje pobierania klientów na serwer,
/// co znacznie poprawia wydajność przy dużej liczbie klientów
class EnhancedClientService extends BaseService {
  // Singleton pattern
  static final EnhancedClientService _instance =
      EnhancedClientService._internal();
  factory EnhancedClientService() => _instance;
  EnhancedClientService._internal();

  /// Pobiera pełne dane klientów na podstawie listy ID (server-side optimization)
  Future<EnhancedClientsResult> getClientsByIds(
    List<String> clientIds, {
    bool includeStatistics = true,
    int? maxClients,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey =
          'clients_by_ids_${clientIds.length}_${clientIds.take(5).join('_')}';

      if (!forceRefresh) {
        final cached = await getCachedData<EnhancedClientsResult>(
          cacheKey,
          () => _fetchClientsByIds(clientIds, includeStatistics, maxClients),
        );
        print(
          '🎯 [EnhancedClientService] Zwracam z cache: ${cached.clients.length} klientów',
        );
        return cached;
      }

      return await _fetchClientsByIds(clientIds, includeStatistics, maxClients);
    } catch (e) {
      logError('getClientsByIds', e);
      return EnhancedClientsResult.error('Błąd pobierania klientów: $e');
    }
  }

  /// Pobiera wszystkich aktywnych klientów (server-side optimization)
  Future<EnhancedClientsResult> getAllActiveClients({
    int limit = 10000,
    bool includeInactive = true, // 🚀 ZMIANA: Domyślnie pobierz wszystkich
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'all_active_clients_${limit}_$includeInactive';

      if (!forceRefresh) {
        final cached = await getCachedData<EnhancedClientsResult>(
          cacheKey,
          () => _fetchAllActiveClients(limit, includeInactive),
        );
        print(
          '🎯 [EnhancedClientService] Zwracam wszystkich z cache: ${cached.clients.length} klientów',
        );
        return cached;
      }

      return await _fetchAllActiveClients(limit, includeInactive);
    } catch (e) {
      logError('getAllActiveClients', e);
      return EnhancedClientsResult.error(
        'Błąd pobierania wszystkich klientów: $e',
      );
    }
  }

  /// Prywatna metoda pobierania klientów po ID
  Future<EnhancedClientsResult> _fetchClientsByIds(
    List<String> clientIds,
    bool includeStatistics,
    int? maxClients,
  ) async {
    final startTime = DateTime.now();
    print(
      '🚀 [EnhancedClientService] Rozpoczynam Firebase Functions getEnhancedClients...',
    );
    print('   - Klient IDs: ${clientIds.length}');
    print('   - Max clients: $maxClients');
    print('   - Include stats: $includeStatistics');
    print('   - 🔍 Pierwsze 10 ID: ${clientIds.take(10).join(', ')}');

    try {
      final requestData = {
        'clientIds': clientIds,
        'options': {
          'includeStatistics': includeStatistics,
          'maxClients': maxClients ?? 1000,
          'batchSize': 50,
        },
      };

      print(
        '🔧 [EnhancedClientService] Wysyłam request: ${requestData.toString().length > 500 ? requestData.toString().substring(0, 500) + '...' : requestData}',
      );

      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('getEnhancedClients').call(requestData);

      final duration = DateTime.now().difference(startTime);
      print(
        '✅ [EnhancedClientService] Firebase Functions zakończone w ${duration.inMilliseconds}ms',
      );

      if (result.data == null) {
        throw Exception('Brak danych z Firebase Functions');
      }

      final data = result.data as Map<String, dynamic>;
      print(
        '🔍 [EnhancedClientService] Otrzymane dane: success=${data['success']}, clients=${(data['clients'] as List?)?.length ?? 0}',
      );

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Firebase Functions zwróciły błąd');
      }

      final result_obj = EnhancedClientsResult.fromFirebaseFunction(data);
      print(
        '🎯 [EnhancedClientService] Sparsowano ${result_obj.clients.length} klientów',
      );
      print(
        '🎯 [EnhancedClientService] Meta: requested=${result_obj.requestedCount}, found=${result_obj.foundCount}, notFound=${result_obj.notFoundCount}',
      );

      return result_obj;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print(
        '❌ [EnhancedClientService] Błąd po ${duration.inMilliseconds}ms: $e',
      );
      throw e;
    }
  }

  /// Prywatna metoda pobierania wszystkich aktywnych klientów
  Future<EnhancedClientsResult> _fetchAllActiveClients(
    int limit,
    bool includeInactive,
  ) async {
    final startTime = DateTime.now();
    print(
      '🚀 [EnhancedClientService] Rozpoczynam Firebase Functions getAllActiveClientsFunction...',
    );
    print('   - Limit: $limit');
    print('   - Include inactive: $includeInactive');

    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('getAllActiveClientsFunction')
          .call({
            'options': {'limit': limit, 'includeInactive': includeInactive},
          });

      final duration = DateTime.now().difference(startTime);
      print(
        '✅ [EnhancedClientService] Firebase Functions zakończone w ${duration.inMilliseconds}ms',
      );

      if (result.data == null) {
        throw Exception('Brak danych z Firebase Functions');
      }

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Firebase Functions zwróciły błąd');
      }

      return EnhancedClientsResult.fromFirebaseFunction(data);
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print(
        '❌ [EnhancedClientService] Błąd po ${duration.inMilliseconds}ms: $e',
      );
      throw e;
    }
  }
}

/// Model wyników z Enhanced Client Service
class EnhancedClientsResult {
  final bool success;
  final List<Client> clients;
  final EnhancedClientStatistics? statistics;
  final String? error;
  final Map<String, dynamic> meta;

  EnhancedClientsResult({
    required this.success,
    required this.clients,
    this.statistics,
    this.error,
    this.meta = const {},
  });

  factory EnhancedClientsResult.fromFirebaseFunction(
    Map<String, dynamic> data,
  ) {
    try {
      final clientsData = data['clients'] as List<dynamic>? ?? [];
      final clients = clientsData
          .map(
            (clientData) =>
                Client.fromServerMap(clientData as Map<String, dynamic>),
          )
          .toList();

      EnhancedClientStatistics? statistics;
      if (data['statistics'] != null) {
        statistics = EnhancedClientStatistics.fromMap(
          data['statistics'] as Map<String, dynamic>,
        );
      }

      return EnhancedClientsResult(
        success: data['success'] as bool? ?? false,
        clients: clients,
        statistics: statistics,
        meta: data['meta'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ [EnhancedClientsResult] Błąd parsowania: $e');
      return EnhancedClientsResult.error('Błąd parsowania danych: $e');
    }
  }

  factory EnhancedClientsResult.error(String error) {
    return EnhancedClientsResult(
      success: false,
      clients: [],
      error: error,
      meta: {'timestamp': DateTime.now().toIso8601String(), 'source': 'error'},
    );
  }

  bool get hasError => !success || error != null;

  int get foundCount => meta['foundCount'] as int? ?? clients.length;
  int get requestedCount => meta['requestedCount'] as int? ?? 0;
  int get notFoundCount => meta['notFoundCount'] as int? ?? 0;
  String get duration => meta['duration'] as String? ?? '0ms';
}

/// Model statystyk klientów z Enhanced Client Service
class EnhancedClientStatistics {
  final int totalClients;
  final int activeClients;
  final int clientsWithEmail;
  final int clientsWithPhone;
  final Map<String, int> clientTypes;
  final Map<String, int> votingStatus;

  EnhancedClientStatistics({
    required this.totalClients,
    required this.activeClients,
    required this.clientsWithEmail,
    required this.clientsWithPhone,
    required this.clientTypes,
    required this.votingStatus,
  });

  factory EnhancedClientStatistics.fromMap(Map<String, dynamic> map) {
    return EnhancedClientStatistics(
      totalClients: map['totalClients'] as int? ?? 0,
      activeClients: map['activeClients'] as int? ?? 0,
      clientsWithEmail: map['clientsWithEmail'] as int? ?? 0,
      clientsWithPhone: map['clientsWithPhone'] as int? ?? 0,
      clientTypes: Map<String, int>.from(map['clientTypes'] as Map? ?? {}),
      votingStatus: Map<String, int>.from(map['votingStatus'] as Map? ?? {}),
    );
  }

  /// Konwertuje do ClientStats dla kompatybilności
  ClientStats toClientStats() {
    return ClientStats(
      totalClients: totalClients,
      totalInvestments: 0, // Nie dostępne w tym kontekście
      totalRemainingCapital: 0.0, // Nie dostępne w tym kontekście
      averageCapitalPerClient: 0.0, // Nie dostępne w tym kontekście
      lastUpdated: DateTime.now().toIso8601String(),
      source: 'EnhancedClientService',
    );
  }
}

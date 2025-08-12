import 'package:cloud_functions/cloud_functions.dart';
import '../models/client.dart';
import 'base_service.dart';

/// Serwis klientów wykorzystujący Firebase Functions
/// Zapewnia szybsze ładowanie poprzez przetwarzanie po stronie serwera
class FirebaseFunctionsClientService extends BaseService {
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Pobiera wszystkich klientów z wykorzystaniem Firebase Functions
  /// Obsługuje paginację, wyszukiwanie i sortowanie po stronie serwera
  Future<ClientsResult> getAllClients({
    int page = 1,
    int pageSize = 5000,
    String? searchQuery,
    String sortBy =
        'fullName', // Zmieniono z 'imie_nazwisko' na rzeczywiste pole w Firestore
    bool forceRefresh = false,
  }) async {
    try {
      logError(
        'getAllClients',
        'Pobieranie klientów: page=$page, pageSize=$pageSize, search="$searchQuery"',
      );

      // Wywołaj Firebase Function
      final result = await _functions.httpsCallable('getAllClients').call({
        'page': page,
        'pageSize': pageSize,
        'searchQuery': searchQuery?.trim().isEmpty == true
            ? null
            : searchQuery?.trim(),
        'sortBy': sortBy,
        'forceRefresh': forceRefresh,
      });

      final data = result.data;

      // Sprawdź czy data nie jest null i zawiera clients
      if (data == null) {
        logError('getAllClients', 'Otrzymano null z Firebase Functions');
        throw Exception('Otrzymano puste dane z serwera');
      }

      // Bezpieczne konwertowanie danych na obiekty Client
      final clientsData = data['clients'];
      if (clientsData == null) {
        logError(
          'getAllClients',
          'Pole clients jest null w odpowiedzi serwera',
        );
        return ClientsResult(
          clients: [],
          totalCount: 0,
          currentPage: page,
          pageSize: pageSize,
          hasNextPage: false,
          hasPreviousPage: false,
          source: 'firebase-functions-empty',
        );
      }

      final clients = (clientsData as List)
          .map((clientData) => _convertToClient(clientData))
          .toList();

      logError(
        'getAllClients',
        'Pobrano ${clients.length} z ${data['totalCount']} klientów',
      );

      return ClientsResult(
        clients: clients,
        totalCount: data['totalCount'],
        currentPage: data['currentPage'],
        pageSize: data['pageSize'],
        hasNextPage: data['hasNextPage'],
        hasPreviousPage: data['hasPreviousPage'],
        source: data['source'] ?? 'firebase-functions',
      );
    } catch (e) {
      logError('getAllClients', e);
      throw Exception('Błąd podczas pobierania klientów: $e');
    }
  }

  /// Pobiera aktywnych klientów z optymalizacją cache
  Future<List<Client>> getActiveClients({bool forceRefresh = false}) async {
    try {
      // Wykorzystaj dedykowaną funkcję Firebase Functions dla aktywnych klientów
      final result = await _functions.httpsCallable('getActiveClients').call({
        'forceRefresh': forceRefresh,
      });

      final data = result.data;

      // Sprawdź czy data nie jest null i zawiera clients
      if (data == null) {
        logError('getActiveClients', 'Otrzymano null z Firebase Functions');
        throw Exception('Otrzymano puste dane z serwera');
      }

      final clientsData = data['clients'];
      if (clientsData == null) {
        logError(
          'getActiveClients',
          'Pole clients jest null w odpowiedzi serwera',
        );
        return [];
      }

      // Konwertuj dane na obiekty Client
      final activeClients = (clientsData as List)
          .map((clientData) => _convertToClient(clientData))
          .toList();

      logError(
        'getActiveClients',
        'Pobrano ${activeClients.length} aktywnych klientów (wskaźnik aktywności: ${data['activityRate']}%)',
      );

      return activeClients;
    } catch (e) {
      logError('getActiveClients', e);
      throw Exception('Błąd podczas pobierania aktywnych klientów: $e');
    }
  }

  /// Pobiera statystyki klientów z Firebase Functions
  Future<ClientStats> getClientStats({bool forceRefresh = false}) async {
    try {
      final result = await _functions.httpsCallable('getSystemStats').call({
        'forceRefresh': forceRefresh,
      });

      final data = result.data;

      final stats = ClientStats(
        totalClients: data['totalClients'] ?? 0,
        totalInvestments: data['totalInvestments'] ?? 0,
        totalRemainingCapital: (data['totalRemainingCapital'] ?? 0.0)
            .toDouble(),
        averageCapitalPerClient: (data['averageCapitalPerClient'] ?? 0.0)
            .toDouble(),
        lastUpdated: data['lastUpdated'] ?? DateTime.now().toIso8601String(),
        source: data['source'] ?? 'firebase-functions',
      );

      return stats;
    } catch (e) {
      logError('getClientStats', e);
      throw Exception('Błąd podczas pobierania statystyk: $e');
    }
  }

  /// Wyszukuje klientów z wykorzystaniem pełnotekstowego wyszukiwania po stronie serwera
  Future<List<Client>> searchClients(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final result = await getAllClients(
        page: 1,
        pageSize: limit,
        searchQuery: query,
        forceRefresh: false,
      );

      logError(
        'searchClients',
        'Wyszukiwanie "${query}" zwróciło ${result.clients.length} wyników',
      );

      return result.clients;
    } catch (e) {
      logError('searchClients', e);
      throw Exception('Błąd podczas wyszukiwania klientów: $e');
    }
  }

  /// Pobiera klienta po ID
  Future<Client?> getClientById(String clientId) async {
    try {
      // Użyj wyszukiwania po ID (Firebase Functions mogą optymalizować to zapytanie)
      final result = await getAllClients(
        page: 1,
        pageSize: 1,
        searchQuery: clientId, // Wyszukaj po ID
      );

      if (result.clients.isNotEmpty) {
        final client = result.clients.first;
        return client;
      }

      return null;
    } catch (e) {
      logError('getClientById', e);
      return null;
    }
  }

  /// Testowa funkcja do diagnozowania problemów z Firebase Functions
  Future<Map<String, dynamic>> debugTest() async {
    try {
      final result = await _functions.httpsCallable('debugClientsTest').call();

      logError('debugTest', 'Test Firebase Functions zakończony pomyślnie');
      logError('debugTest', 'Wynik: ${result.data}');

      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      logError('debugTest', e);
      throw Exception('Błąd podczas testu Firebase Functions: $e');
    }
  }

  /// Czyszczenie cache po aktualizacji danych
  Future<void> clearAllCaches() async {
    try {
      // Wyczyść lokalne cache
      clearAllCache();

      // Wyczyść cache w Firebase Functions
      await _functions.httpsCallable('clearAnalyticsCache').call();

      logError('clearAllCaches', 'Cache wyczyszczony pomyślnie');
    } catch (e) {
      logError('clearAllCaches', e);
    }
  }

  /// Konwertuje dane z Firebase na obiekt Client
  Client _convertToClient(Map<String, dynamic> data) {
    // Helper do parsowania dat
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;

      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return null;
        }
      }

      if (dateValue is Map && dateValue.containsKey('_seconds')) {
        // Timestamp z Firestore
        final seconds = dateValue['_seconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }

      return null;
    }

    return Client(
      id: data['id'] ?? '',
      excelId: data['excelId']?.toString() ?? data['original_id']?.toString(),
      name: data['imie_nazwisko'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['telefon'] ?? data['phone'] ?? '',
      address: data['address'] ?? '',
      pesel: data['pesel'],
      companyName: data['nazwa_firmy'] ?? data['companyName'],
      type: ClientType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ClientType.individual,
      ),
      notes: data['notes'] ?? '',
      votingStatus: VotingStatus.values.firstWhere(
        (e) => e.name == data['votingStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      colorCode: data['colorCode'] ?? '#FFFFFF',
      unviableInvestments: List<String>.from(data['unviableInvestments'] ?? []),
      createdAt:
          parseDate(data['createdAt']) ??
          parseDate(data['created_at']) ??
          DateTime.now(),
      updatedAt:
          parseDate(data['updatedAt']) ??
          parseDate(data['uploaded_at']) ??
          DateTime.now(),
      isActive: data['isActive'] ?? true,
      additionalInfo: Map<String, dynamic>.from(
        data['additionalInfo'] ?? {'source_file': data['source_file']},
      ),
    );
  }
}

/// Rezultat pobierania klientów z paginacją
class ClientsResult {
  final List<Client> clients;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String source;

  ClientsResult({
    required this.clients,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.source,
  });

  int get totalPages => (totalCount / pageSize).ceil();

  bool get isEmpty => clients.isEmpty;
  bool get isNotEmpty => clients.isNotEmpty;
}

/// Statystyki klientów
class ClientStats {
  final int totalClients;
  final int totalInvestments;
  final double totalRemainingCapital;
  final double averageCapitalPerClient;
  final String lastUpdated;
  final String source;

  ClientStats({
    required this.totalClients,
    required this.totalInvestments,
    required this.totalRemainingCapital,
    required this.averageCapitalPerClient,
    required this.lastUpdated,
    required this.source,
  });
}

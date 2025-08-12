import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import 'base_service.dart';
import 'client_service.dart';
import 'firebase_functions_client_service.dart'
    show ClientStats; // Import tylko dla ClientStats

/// Zintegrowany serwis klientów
/// Używa Firebase Functions jako głównej metody z fallbackiem do standardowego ClientService
class IntegratedClientService extends BaseService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  static final ClientService _fallbackService = ClientService();

  /// Pobiera wszystkich klientów - próbuje Firebase Functions, fallback to ClientService
  Future<List<Client>> getAllClients({
    int page = 1,
    int pageSize = 10000, // Zwiększony domyślny limit
    String? searchQuery,
    String sortBy = 'fullName',
    bool forceRefresh = false,
    Function(double progress, String stage)? onProgress,
  }) async {
    print('🚀 [getAllClients] START - pageSize: $pageSize');
    try {
      onProgress?.call(0.1, 'Próba połączenia z Firebase Functions...');

      // Najpierw spróbuj Firebase Functions
      final result = await _functions
          .httpsCallable('getAllClients')
          .call({
            'page': page,
            'pageSize': pageSize,
            'searchQuery': searchQuery?.trim().isEmpty == true
                ? null
                : searchQuery?.trim(),
            'sortBy': sortBy,
            'forceRefresh': forceRefresh,
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firebase Functions timeout'),
          );

      final data = result.data;
      if (data == null || data['clients'] == null) {
        throw Exception('Brak danych z Firebase Functions');
      }

      onProgress?.call(0.7, 'Przetwarzanie danych z Firebase Functions...');

      final clients = (data['clients'] as List)
          .map((clientData) => _convertFirebaseFunctionToClient(clientData))
          .toList();

      print(
        '🎉 [getAllClients] Firebase Functions SUCCESS - pobranych ${clients.length} klientów',
      );
      logError(
        'getAllClients',
        'Pobrano ${clients.length} klientów z Firebase Functions',
      );
      onProgress?.call(1.0, 'Zakończono (Firebase Functions)');

      return clients;
    } catch (e) {
      logError(
        'getAllClients',
        'Firebase Functions nie działają: $e, przechodzę na fallback',
      );

      // Fallback do standardowego ClientService
      onProgress?.call(0.3, 'Przełączanie na standardowy serwis...');

      try {
        final clients = await _fallbackService.loadAllClientsWithProgress(
          onProgress: (progress, stage) {
            onProgress?.call(0.3 + (progress * 0.7), 'Fallback: $stage');
          },
        );

        print(
          '🔍 [getAllClients] Fallback pobrał ${clients.length} klientów z bazy',
        );

        // Zastosuj filtrację jeśli jest searchQuery
        List<Client> filteredClients = clients;
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          onProgress?.call(0.9, 'Filtrowanie wyników...');
          final query = searchQuery.toLowerCase();
          filteredClients = clients.where((client) {
            return client.name.toLowerCase().contains(query) ||
                client.email.toLowerCase().contains(query) ||
                client.phone.toLowerCase().contains(query) ||
                (client.pesel?.toLowerCase().contains(query) ?? false);
          }).toList();
          print(
            '🔍 [getAllClients] Po filtrowaniu: ${filteredClients.length} klientów',
          );
        }

        // Zastosuj sortowanie
        if (sortBy == 'fullName' || sortBy == 'name') {
          filteredClients.sort((a, b) => a.name.compareTo(b.name));
        }

        // USUNIĘTE OGRANICZENIE PAGINACJI - zwracamy wszystkich gdy pageSize >= 1000
        List<Client> finalClients;
        if (pageSize >= 1000) {
          print(
            '🔍 [getAllClients] Zwracam wszystkich ${filteredClients.length} klientów (pageSize=$pageSize)',
          );
          finalClients = filteredClients;
        } else {
          // Zastosuj paginację tylko dla małych pageSize
          final startIndex = (page - 1) * pageSize;
          final endIndex = (startIndex + pageSize).clamp(
            0,
            filteredClients.length,
          );
          finalClients = filteredClients.sublist(
            startIndex.clamp(0, filteredClients.length),
            endIndex,
          );
          print(
            '🔍 [getAllClients] Paginacja: ${finalClients.length} z ${filteredClients.length} (strona $page, rozmiar $pageSize)',
          );
        }

        logError(
          'getAllClients',
          'Fallback: Zwracam ${finalClients.length} klientów z ${filteredClients.length} dostępnych',
        );
        onProgress?.call(1.0, 'Zakończono (Fallback)');

        return finalClients;
      } catch (fallbackError) {
        logError('getAllClients', 'Fallback też nie działa: $fallbackError');
        onProgress?.call(1.0, 'Błąd');
        throw Exception(
          'Nie można pobrać klientów: Firebase Functions ($e), Fallback ($fallbackError)',
        );
      }
    }
  }

  /// Pobiera aktywnych klientów - próbuje Firebase Functions, fallback to ClientService
  Future<List<Client>> getActiveClients({bool forceRefresh = false}) async {
    print('🚀 [getActiveClients] Rozpoczynam pobieranie aktywnych klientów...');
    try {
      // Najpierw spróbuj Firebase Functions
      print('   - Próbuję Firebase Functions...');
      final result = await _functions
          .httpsCallable('getActiveClients')
          .call({'forceRefresh': forceRefresh})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firebase Functions timeout'),
          );

      final data = result.data;
      if (data == null || data['clients'] == null) {
        throw Exception('Brak danych z Firebase Functions');
      }

      final activeClients = (data['clients'] as List)
          .map((clientData) => _convertFirebaseFunctionToClient(clientData))
          .toList();

      print(
        '🎉 [getActiveClients] Firebase Functions - pobrano ${activeClients.length} aktywnych klientów',
      );
      logError(
        'getActiveClients',
        'Pobrano ${activeClients.length} aktywnych klientów z Firebase Functions',
      );
      return activeClients;
    } catch (e) {
      print('⚠️ [getActiveClients] Firebase Functions błąd: $e');
      logError(
        'getActiveClients',
        'Firebase Functions nie działają: $e, przechodzę na fallback',
      );

      // Fallback do standardowego ClientService
      try {
        print('   - Próbuję fallback ClientService z limitem 10000...');
        final stream = _fallbackService.getActiveClients(
          limit: 10000,
        ); // Zwiększony limit
        final activeClients = await stream.first;

        print(
          '� [getActiveClients] Fallback pobrał ${activeClients.length} aktywnych klientów',
        );

        logError(
          'getActiveClients',
          'Fallback: Pobrano ${activeClients.length} aktywnych klientów',
        );
        return activeClients;
      } catch (fallbackError) {
        print('❌ [getActiveClients] Fallback też nie działa: $fallbackError');
        logError('getActiveClients', 'Fallback też nie działa: $fallbackError');
        throw Exception(
          'Nie można pobrać aktywnych klientów: Firebase Functions ($e), Fallback ($fallbackError)',
        );
      }
    }
  }

  /// Pobiera statystyki klientów - próbuje Firebase Functions, fallback to ClientService
  Future<ClientStats> getClientStats({bool forceRefresh = false}) async {
    print('🔍 [IntegratedClientService] Pobieranie statystyk klientów...');

    try {
      // Najpierw spróbuj Firebase Functions
      print('   - Próba Firebase Functions...');
      final result = await _functions
          .httpsCallable('getSystemStats')
          .call({'forceRefresh': forceRefresh})
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Firebase Functions timeout'),
          );

      final data = result.data;
      print('   - Raw Firebase Functions data: $data');

      if (data == null) {
        throw Exception('Brak danych z Firebase Functions');
      }

      print('   - Firebase Functions response:');
      print(
        '     * totalClients: ${data['totalClients']} (${data['totalClients'].runtimeType})',
      );
      print(
        '     * totalInvestments: ${data['totalInvestments']} (${data['totalInvestments'].runtimeType})',
      );
      print(
        '     * totalRemainingCapital: ${data['totalRemainingCapital']} (${data['totalRemainingCapital'].runtimeType})',
      );
      print('     * source: ${data['source']}');

      // Sprawdź czy dane są prawidłowe (nie null)
      if (data['totalClients'] == null ||
          data['totalInvestments'] == null ||
          data['totalRemainingCapital'] == null) {
        print(
          '⚠️ [WARNING] Firebase Functions zwróciły null dla kluczowych pól',
        );
        print('   - totalClients null: ${data['totalClients'] == null}');
        print(
          '   - totalInvestments null: ${data['totalInvestments'] == null}',
        );
        print(
          '   - totalRemainingCapital null: ${data['totalRemainingCapital'] == null}',
        );
        print('   - Wymuszam fallback...');
        throw Exception('Nieprawidłowe dane z Firebase Functions - pola null');
      }

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

      // Dodatkowa walidacja - sprawdź czy dane wyglądają sensownie
      if (stats.totalRemainingCapital == 0 && stats.totalClients > 0) {
        print(
          '⚠️ [WARNING] Firebase Functions zwróciły 0 kapitału dla ${stats.totalClients} klientów',
        );
        print('   - Wymuszam fallback...');
        throw Exception('Nieprawidłowe dane z Firebase Functions - 0 kapitału');
      }

      logError('getClientStats', 'Pobrano statystyki z Firebase Functions');
      return stats;
    } catch (e) {
      print('❌ [IntegratedClientService] Firebase Functions błąd: $e');
      logError(
        'getClientStats',
        'Firebase Functions nie działają: $e, przechodzę na zaawansowany fallback',
      );

      // Zaawansowany fallback - pobierz rzeczywiste dane
      try {
        print('   - Próba zaawansowanego fallback...');
        // Pobierz statystyki klientów i zunifikowane statystyki inwestycji
        final unifiedStats = await _getUnifiedClientStats();
        final clientsStats = await _fallbackService.getClientStats();

        final totalClients =
            (clientsStats['total_clients'] as int?) ??
            unifiedStats.totalClients;
        final totalInvestments = unifiedStats.totalInvestments;
        final totalRemainingCapital = unifiedStats.totalRemainingCapital;

        print('   - Zaawansowany fallback response:');
        print('     * totalClients: $totalClients');
        print('     * totalInvestments: $totalInvestments');
        print('     * totalRemainingCapital: $totalRemainingCapital');

        final stats = ClientStats(
          totalClients: totalClients,
          totalInvestments: totalInvestments,
          totalRemainingCapital: totalRemainingCapital,
          averageCapitalPerClient: totalClients > 0
              ? totalRemainingCapital / totalClients
              : 0.0,
          lastUpdated: DateTime.now().toIso8601String(),
          source: 'advanced-fallback',
        );

        logError(
          'getClientStats',
          'Zaawansowany fallback: ${totalClients} klientów, ${totalInvestments} inwestycji, ${totalRemainingCapital.toStringAsFixed(0)} PLN',
        );
        return stats;
      } catch (fallbackError) {
        print(
          '❌ [IntegratedClientService] Zaawansowany fallback błąd: $fallbackError',
        );
        logError(
          'getClientStats',
          'Zaawansowany fallback też nie działa: $fallbackError',
        );

        // Podstawowy fallback
        try {
          print('   - Próba podstawowego fallback...');
          final clientsStats = await _fallbackService.getClientStats();
          final totalClients = clientsStats['total_clients'] ?? 0;

          print('   - Podstawowy fallback response:');
          print('     * totalClients: $totalClients');

          final stats = ClientStats(
            totalClients: totalClients,
            totalInvestments: 0,
            totalRemainingCapital: 0.0,
            averageCapitalPerClient: 0.0,
            lastUpdated: DateTime.now().toIso8601String(),
            source: 'basic-fallback',
          );

          logError(
            'getClientStats',
            'Podstawowy fallback: ${totalClients} klientów',
          );
          return stats;
        } catch (basicError) {
          print(
            '❌ [IntegratedClientService] Wszystkie fallbacki zawiodły: $basicError',
          );
          logError(
            'getClientStats',
            'Wszystkie fallbacki zawiodły: $basicError',
          );
          throw Exception(
            'Nie można pobrać statystyk: Firebase Functions ($e), Zaawansowany fallback ($fallbackError), Podstawowy ($basicError)',
          );
        }
      }
    }
  }

  /// Pozostałe metody delegowane do ClientService
  Future<String> createClient(Client client) =>
      _fallbackService.createClient(client);

  Future<Client?> getClient(String id) => _fallbackService.getClient(id);

  Future<bool> clientExists(String id) => _fallbackService.clientExists(id);

  Future<void> updateClient(String id, Client client) =>
      _fallbackService.updateClient(id, client);

  Future<void> updateClientFields(String id, Map<String, dynamic> fields) =>
      _fallbackService.updateClientFields(id, fields);

  Future<void> deleteClient(String id) => _fallbackService.deleteClient(id);

  Future<void> hardDeleteClient(String id) =>
      _fallbackService.hardDeleteClient(id);

  Future<int> getClientsCount() => _fallbackService.getClientsCount();

  Stream<List<Client>> getAllClientsStream() =>
      _fallbackService.getAllClientsStream();

  Stream<List<Client>> getClients({int? limit}) =>
      _fallbackService.getClients(limit: limit);

  Stream<List<Client>> searchClients(String query, {int limit = 30}) =>
      _fallbackService.searchClients(query, limit: limit);

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

  /// Konwertuje dane z Firebase Functions do obiektu Client
  Client _convertFirebaseFunctionToClient(Map<String, dynamic> data) {
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
      name: data['fullName'] ?? data['name'] ?? data['imie_nazwisko'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? data['telefon'] ?? '',
      address: data['address'] ?? '',
      pesel: data['pesel'],
      companyName: data['companyName'] ?? data['nazwa_firmy'],
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

  /// Pobiera statystyki klientów używając zunifikowanych metod
  Future<ClientStats> _getUnifiedClientStats() async {
    print('🔍 [_getUnifiedClientStats] Rozpoczynam obliczenia...');

    // Pobierz wszystkie inwestycje z Firestore
    final investmentsSnapshot = await FirebaseFirestore.instance
        .collection('investments')
        .get();

    print('   - Znaleziono ${investmentsSnapshot.docs.length} inwestycji');

    double totalRemainingCapital = 0.0;
    int validInvestments = 0;

    for (final doc in investmentsSnapshot.docs) {
      final data = doc.data();

      // Spróbuj różne nazwy pól dla pozostałego kapitału
      dynamic capitalValue =
          data['kapital_pozostaly'] ??
          data['remainingCapital'] ??
          data['capital_remaining'] ??
          0;

      double parsedCapital = 0.0;

      if (capitalValue is num) {
        parsedCapital = capitalValue.toDouble();
      } else if (capitalValue is String && capitalValue.isNotEmpty) {
        // Wyczyść string i spróbuj sparsować
        final cleanValue = capitalValue.replaceAll(',', '').replaceAll(' ', '');
        parsedCapital = double.tryParse(cleanValue) ?? 0.0;
      }

      if (parsedCapital > 0) {
        totalRemainingCapital += parsedCapital;
        validInvestments++;

        if (validInvestments <= 5) {
          // Log pierwszych 5 dla debugowania
          print(
            '   - Doc ${doc.id}: kapital=$parsedCapital (${data.keys.toList()})',
          );
        }
      }
    }

    // Pobierz liczbę klientów
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('clients')
        .get();

    final totalClients = clientsSnapshot.docs.length;

    print(
      '   - Wyniki: $totalClients klientów, $validInvestments inwestycji, ${totalRemainingCapital.toStringAsFixed(2)} PLN',
    );

    return ClientStats(
      totalClients: totalClients,
      totalInvestments: investmentsSnapshot.docs.length,
      totalRemainingCapital: totalRemainingCapital,
      averageCapitalPerClient: totalClients > 0
          ? totalRemainingCapital / totalClients
          : 0.0,
      lastUpdated: DateTime.now().toIso8601String(),
      source: 'unified-statistics-direct',
    );
  }
}

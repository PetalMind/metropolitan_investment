import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import 'base_service.dart';
import 'client_service.dart';
import 'firebase_functions_client_service.dart'; // Importujemy tylko dla ClientStats

/// Zintegrowany serwis klientów
/// Używa Firebase Functions jako głównej metody z fallbackiem do standardowego ClientService
class IntegratedClientService extends BaseService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  static final ClientService _fallbackService = ClientService();

  /// Pobiera wszystkich klientów - używa bezpośrednio ClientService (Firebase Functions wyłączone ze względu na błędy)
  Future<List<Client>> getAllClients({
    int page = 1,
    int pageSize = 10000,
    String? searchQuery,
    String sortBy = 'fullName',
    bool forceRefresh = false,
    Function(double progress, String stage)? onProgress,
  }) async {
    print('🚀 [getAllClients] START - używam bezpośrednio ClientService (Firebase Functions wyłączone)');
    
    try {
      onProgress?.call(0.1, 'Pobieranie klientów z Firestore...');

      // Używaj bezpośrednio ClientService zamiast problematycznych Firebase Functions
      final clients = await _fallbackService.loadAllClientsWithProgress(
        onProgress: (progress, stage) {
          onProgress?.call(0.1 + (progress * 0.7), stage);
        },
      );

      print('🔍 [getAllClients] Pobrał ${clients.length} klientów z bazy');

      // Zastosuj filtrację jeśli jest searchQuery
      List<Client> filteredClients = clients;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        onProgress?.call(0.8, 'Filtrowanie wyników...');
        final query = searchQuery.toLowerCase();
        filteredClients = clients.where((client) {
          return client.name.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query) ||
              client.phone.toLowerCase().contains(query) ||
              (client.pesel?.toLowerCase().contains(query) ?? false);
        }).toList();
        print('🔍 [getAllClients] Po filtrowaniu: ${filteredClients.length} klientów');
      }

      // Zastosuj sortowanie
      if (sortBy == 'fullName' || sortBy == 'name') {
        filteredClients.sort((a, b) => a.name.compareTo(b.name));
      }

      // Zastosuj paginację jeśli pageSize < 1000
      List<Client> finalClients;
      if (pageSize >= 1000) {
        print('🔍 [getAllClients] Zwracam wszystkich ${filteredClients.length} klientów (pageSize=$pageSize)');
        finalClients = filteredClients;
      } else {
        final startIndex = (page - 1) * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, filteredClients.length);
        finalClients = filteredClients.sublist(
          startIndex.clamp(0, filteredClients.length),
          endIndex,
        );
        print('🔍 [getAllClients] Paginacja: ${finalClients.length} z ${filteredClients.length} (strona $page, rozmiar $pageSize)');
      }

      onProgress?.call(1.0, 'Zakończono');
      logError('getAllClients', 'SUCCESS: Zwrócono ${finalClients.length} klientów z ${filteredClients.length} dostępnych');
      
      return finalClients;
    } catch (e) {
      print('❌ [getAllClients] Błąd: $e');
      logError('getAllClients', 'Błąd pobierania klientów: $e');
      onProgress?.call(1.0, 'Błąd');
      throw Exception('Nie można pobrać klientów: $e');
    }
  }

  /// Pobiera aktywnych klientów - używa bezpośrednio ClientService (Firebase Functions wyłączone)
  Future<List<Client>> getActiveClients({bool forceRefresh = false}) async {
    print('🚀 [getActiveClients] START - używam bezpośrednio ClientService (Firebase Functions wyłączone)');
    try {
      // Używaj bezpośrednio ClientService zamiast problematycznych Firebase Functions
      final stream = _fallbackService.getActiveClients(limit: 10000);
      final activeClients = await stream.first;

      print('🔍 [getActiveClients] Pobrał ${activeClients.length} aktywnych klientów z bazy');
      logError('getActiveClients', 'SUCCESS: Pobrano ${activeClients.length} aktywnych klientów');
      
      return activeClients;
    } catch (e) {
      print('❌ [getActiveClients] Błąd: $e');
      logError('getActiveClients', 'Błąd pobierania aktywnych klientów: $e');
      throw Exception('Nie można pobrać aktywnych klientów: $e');
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

      // Bezpieczne parsowanie z null-safety
      final totalClients = _safeParseInt(data['totalClients']);
      final totalInvestments = _safeParseInt(data['totalInvestments']);
      final totalRemainingCapital = _safeParseDouble(
        data['totalRemainingCapital'],
      );

      print('   - Firebase Functions response (parsed):');
      print('     * totalClients: $totalClients (${totalClients.runtimeType})');
      print(
        '     * totalInvestments: $totalInvestments (${totalInvestments.runtimeType})',
      );
      print(
        '     * totalRemainingCapital: $totalRemainingCapital (${totalRemainingCapital.runtimeType})',
      );
      print('     * source: ${data['source'] ?? 'unknown'}');

      // Sprawdź czy dane mają sens biznesowo
      if (totalClients < 0 ||
          totalInvestments < 0 ||
          totalRemainingCapital < 0) {
        print(
          '⚠️ [WARNING] Firebase Functions zwróciły nieprawidłowe wartości',
        );
        print('   - totalClients: $totalClients');
        print('   - totalInvestments: $totalInvestments');
        print('   - totalRemainingCapital: $totalRemainingCapital');
        print('   - Wymuszam fallback...');
        throw Exception(
          'Nieprawidłowe dane z Firebase Functions - negatywne wartości',
        );
      }

      // Sprawdź logikę biznesową - czy klienci mają inwestycje
      if (totalClients > 0 &&
          totalInvestments == 0 &&
          totalRemainingCapital == 0) {
        print(
          '⚠️ [WARNING] Firebase Functions zwróciły 0 kapitału i inwestycji dla $totalClients klientów',
        );
        print('   - To może wskazywać na błąd w logice serwera');
        print('   - Wymuszam fallback...');
        throw Exception(
          'Nieprawidłowe dane z Firebase Functions - brak inwestycji dla klientów',
        );
      }

      final stats = ClientStats(
        totalClients: totalClients,
        totalInvestments: totalInvestments,
        totalRemainingCapital: totalRemainingCapital,
        averageCapitalPerClient: totalClients > 0
            ? totalRemainingCapital / totalClients
            : 0.0,
        lastUpdated: _safeParseString(
          data['lastUpdated'],
          DateTime.now().toIso8601String(),
        ),
        source: _safeParseString(data['source'], 'firebase-functions'),
      );

      // Dodatkowa walidacja - sprawdź czy dane wyglądają sensownie
      if (totalRemainingCapital == 0 && totalClients > 0) {
        print(
          '⚠️ [WARNING] Firebase Functions zwróciły 0 kapitału dla $totalClients klientów',
        );
        print('   - Wymuszam fallback...');
        throw Exception('Nieprawidłowe dane z Firebase Functions - 0 kapitału');
      }

      print(
        '✅ [IntegratedClientService] Pomyślnie pobrano statystyki z Firebase Functions:',
      );
      print('   - Klienci: ${stats.totalClients}');
      print('   - Inwestycje: ${stats.totalInvestments}');
      print(
        '   - Kapitał: ${stats.totalRemainingCapital.toStringAsFixed(2)} PLN',
      );
      print(
        '   - Średnia na klienta: ${stats.averageCapitalPerClient.toStringAsFixed(2)} PLN',
      );
      print('   - Źródło: ${stats.source}');

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

        // Bezpieczne parsowanie danych z fallback
        final totalClients = _safeParseInt(clientsStats['total_clients']) != 0
            ? _safeParseInt(clientsStats['total_clients'])
            : unifiedStats.totalClients;
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

        print(
          '✅ [IntegratedClientService] Pomyślnie pobrano z zaawansowanego fallback:',
        );
        print('   - Klienci: ${stats.totalClients}');
        print('   - Inwestycje: ${stats.totalInvestments}');
        print(
          '   - Kapitał: ${stats.totalRemainingCapital.toStringAsFixed(2)} PLN',
        );
        print(
          '   - Średnia na klienta: ${stats.averageCapitalPerClient.toStringAsFixed(2)} PLN',
        );

        logError(
          'getClientStats',
          'Zaawansowany fallback: $totalClients klientów, $totalInvestments inwestycji, ${totalRemainingCapital.toStringAsFixed(0)} PLN',
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
          final totalClients = _safeParseInt(clientsStats['total_clients']);

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
            'Podstawowy fallback: $totalClients klientów',
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

  /// Testowa funkcja do diagnozowania problemów z Firebase Functions (wyłączona ze względu na błędy)
  Future<Map<String, dynamic>> debugTest() async {
    logError('debugTest', 'Firebase Functions są wyłączone - zwracam mock response');
    
    return {
      'status': 'disabled',
      'message': 'Firebase Functions zostały wyłączone w IntegratedClientService ze względu na błędy',
      'fallback': 'Używamy bezpośrednio ClientService',
      'timestamp': DateTime.now().toIso8601String(),
    };
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

      // Użyj bezpiecznej metody parsowania
      final parsedCapital = _safeParseDouble(
        data['kapital_pozostaly'] ??
            data['remainingCapital'] ??
            data['capital_remaining'] ??
            data['Kapital Pozostaly'] ??
            data['Remaining Capital'] ??
            0,
      );

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

  /// Bezpieczne parsowanie int z null-safety
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;

      // Wyczyść string z niepotrzebnych znaków
      String cleanValue = value
          .replaceAll(' ', '') // usuń spacje
          .replaceAll(',', '') // usuń przecinki
          .trim();

      final parsed = int.tryParse(cleanValue);
      if (parsed != null) {
        return parsed;
      }

      // Spróbuj jako double i przekształć
      final parsedDouble = double.tryParse(cleanValue);
      if (parsedDouble != null && parsedDouble.isFinite) {
        return parsedDouble.toInt();
      }

      print(
        '⚠️ [WARNING] Nie można sparsować int z: "$value" -> "$cleanValue"',
      );
      return 0;
    }
    print('⚠️ [WARNING] Nieznany typ dla int: $value (${value.runtimeType})');
    return 0;
  }

  /// Bezpieczne parsowanie double z null-safety
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;

      // Wyczyść string z polskich separatorów i białych znaków
      String cleanValue = value
          .replaceAll(' ', '') // usuń spacje
          .replaceAll(',', '.') // zamień przecinek na kropkę
          .replaceAll('zł', '') // usuń symbol waluty
          .replaceAll('PLN', '') // usuń symbol waluty
          .trim();

      final parsed = double.tryParse(cleanValue);
      if (parsed != null && parsed.isFinite) {
        return parsed;
      }

      print(
        '⚠️ [WARNING] Nie można sparsować double z: "$value" -> "$cleanValue"',
      );
      return 0.0;
    }
    print(
      '⚠️ [WARNING] Nieznany typ dla double: $value (${value.runtimeType})',
    );
    return 0.0;
  }

  /// Bezpieczne parsowanie String z null-safety
  String _safeParseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }
}

import 'package:cloud_functions/cloud_functions.dart';
import '../models_and_services.dart';

/// Serwis do diagnostyki mapowania ID klientów przez Firebase Functions
class ClientMappingDiagnosticService extends BaseService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Przeprowadź pełną diagnostykę mapowania klientów
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      print('🔍 [Diagnostic] Uruchamianie diagnostyki mapowania...');

      final callable = _functions.httpsCallable('diagnosticClientMapping');
      final result = await callable.call();

      final data = result.data['data'] as Map<String, dynamic>;

      print('✅ [Diagnostic] Diagnostyka zakończona:');
      print('   - Klienci: ${data['clients']['total']}');
      print('   - Produkty: ${data['products']['total']}');
      print('   - Zmapowane: ${data['products']['mapped']}');
      print('   - Procent mapowania: ${data['products']['mappingRate']}');

      return data;
    } catch (e) {
      print('❌ [Diagnostic] Błąd diagnostyki: $e');
      logError('runFullDiagnostic', e);
      rethrow;
    }
  }

  /// Test mapowania konkretnego klienta
  Future<Map<String, dynamic>> testClientMapping({
    String? excelId,
    String? clientName,
  }) async {
    if (excelId == null && clientName == null) {
      throw ArgumentError('Wymagane excelId lub clientName');
    }

    try {
      print(
        '🧪 [Diagnostic] Test mapowania: Excel ID: $excelId, Nazwa: $clientName',
      );

      final callable = _functions.httpsCallable('testClientMapping');
      final result = await callable.call({
        if (excelId != null) 'excelId': excelId,
        if (clientName != null) 'clientName': clientName,
      });

      final data = result.data;

      if (data['success'] == true) {
        final client = data['client'];
        final stats = data['stats'];

        print('✅ [Diagnostic] Test zakończony pomyślnie:');
        print('   - Klient: ${client['imie_nazwisko'] ?? client['name']}');
        print('   - Firestore ID: ${client['id']}');
        print('   - Produkty: ${stats['totalProducts']}');
      } else {
        print('❌ [Diagnostic] Test nieudany: ${data['message']}');
      }

      return data;
    } catch (e) {
      print('❌ [Diagnostic] Błąd testu: $e');
      logError('testClientMapping', e);
      rethrow;
    }
  }

  /// Wyświetl raport diagnostyki w konsoli
  void printDiagnosticReport(Map<String, dynamic> report) {
    print('\n📊 === RAPORT DIAGNOSTYKI MAPOWANIA KLIENTÓW ===');

    final clients = report['clients'] as Map<String, dynamic>;
    final products = report['products'] as Map<String, dynamic>;
    final recommendations = report['recommendations'] as List;

    print('\n👥 KLIENCI:');
    print('   - Łącznie: ${clients['total']}');
    print('   - Z Excel ID: ${clients['withExcelId']}');
    print('   - Z nazwą: ${clients['withName']}');
    print('   - Duplikaty Excel ID: ${clients['duplicateExcelIds'].length}');
    print('   - Duplikaty nazw: ${clients['duplicateNames'].length}');

    print('\n💼 PRODUKTY:');
    print('   - Łącznie: ${products['total']}');
    print('   - Z ID klienta: ${products['withClientId']}');
    print('   - Z nazwą klienta: ${products['withClientName']}');
    print('   - Zmapowane: ${products['mapped']}');
    print('   - Niezmapowane: ${products['unmapped']}');
    print('   - Procent mapowania: ${products['mappingRate']}');

    print('\n📋 WEDŁUG KOLEKCJI:');
    final byCollection = products['byCollection'] as Map<String, dynamic>;
    for (final entry in byCollection.entries) {
      final collection = entry.key;
      final stats = entry.value as Map<String, dynamic>;
      final mappingRate = stats['total'] > 0
          ? ((stats['mapped'] / stats['total']) * 100).toStringAsFixed(1)
          : '0.0';
      print(
        '   - $collection: ${stats['mapped']}/${stats['total']} ($mappingRate%)',
      );
    }

    if (recommendations.isNotEmpty) {
      print('\n💡 REKOMENDACJE:');
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i] as Map<String, dynamic>;
        final icon = rec['type'] == 'error' ? '❌' : '⚠️';
        print('   $icon ${rec['message']}');
        print('      Działanie: ${rec['action']}');
      }
    }

    print('\n⏱️ Czas wykonania: ${report['executionTime']}ms');
    print('═══════════════════════════════════════════════════\n');
  }
}

/// Globalna funkcja do uruchomienia diagnostyki z konsoli
Future<void> runClientMappingDiagnostic() async {
  final service = ClientMappingDiagnosticService();
  try {
    final report = await service.runFullDiagnostic();
    service.printDiagnosticReport(report);
  } catch (e) {
    print('❌ Błąd podczas diagnostyki: $e');
  }
}

/// Test mapowania konkretnego klienta z konsoli
Future<void> testSpecificClientMapping(
  String excelId, [
  String? clientName,
]) async {
  final service = ClientMappingDiagnosticService();
  try {
    final result = await service.testClientMapping(
      excelId: excelId,
      clientName: clientName,
    );

    if (result['success'] == true) {
      print('\n🎯 === WYNIKI TESTU MAPOWANIA ===');

      final client = result['client'];
      print('✅ Znaleziono klienta:');
      print('   - Firestore ID: ${client['id']}');
      print('   - Nazwa: ${client['imie_nazwisko'] ?? client['name']}');
      print('   - Excel ID: ${client['excelId']}');
      print('   - Email: ${client['email'] ?? 'brak'}');
      print('   - Status głosowania: ${client['votingStatus']}');

      final stats = result['stats'];
      print('\n📊 Produkty klienta:');
      print('   - Łącznie: ${stats['totalProducts']}');

      final byCollection = stats['productsByCollection'];
      for (final entry in byCollection.entries) {
        if (entry.value > 0) {
          print('   - ${entry.key}: ${entry.value}');
        }
      }

      print('═══════════════════════════════════════\n');
    } else {
      print('❌ ${result['message']}');
    }
  } catch (e) {
    print('❌ Błąd podczas testu: $e');
  }
}

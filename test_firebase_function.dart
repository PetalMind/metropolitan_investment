import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Test funkcji Firebase - uruchom to w konsoli
Future<void> testFirebaseFunction() async {
  try {
    print('🧪 [Test] Rozpoczynam test funkcji Firebase Functions...');

    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final callable = functions.httpsCallable('getUnifiedProducts');

    print('🧪 [Test] Wywołuję getUnifiedProducts...');

    final result = await callable.call({
      'page': 1,
      'pageSize': 10,
      'sortBy': 'createdAt',
      'sortAscending': false,
      'forceRefresh': true,
    });

    print('🧪 [Test] Otrzymano odpowiedź:');
    print('   - Type: ${result.data.runtimeType}');

    if (result.data is Map) {
      final data = result.data as Map<String, dynamic>;
      print('   - Keys: ${data.keys.toList()}');

      if (data.containsKey('products')) {
        final products = data['products'] as List?;
        print('   - Products count: ${products?.length ?? 0}');
      }

      if (data.containsKey('pagination')) {
        print('   - Pagination: ${data['pagination']}');
      }

      if (data.containsKey('metadata')) {
        final metadata = data['metadata'] as Map?;
        print('   - Metadata: ${metadata}');
        if (metadata?.containsKey('warning') == true) {
          print('   - ⚠️ WARNING: ${metadata!['warning']}');
        }
      }
    }

    print('✅ [Test] Test zakończony pomyślnie');
  } catch (e, stackTrace) {
    print('❌ [Test] Błąd podczas testu:');
    print('   Error: $e');
    print('   Stack: $stackTrace');
  }
}

void main() {
  testFirebaseFunction();
}

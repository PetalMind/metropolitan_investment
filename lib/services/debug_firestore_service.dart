import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Debug service for testing Firestore connection and operations
class DebugFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test basic Firestore connection
  static Future<bool> testFirestoreConnection() async {
    if (kDebugMode) {
      print('🔍 [DebugFirestore] Testing Firestore connection...');
    }

    try {
      // Try to read a simple document or collection
      final testQuery = await _firestore
          .collection('clients')
          .limit(1)
          .get(const GetOptions(source: Source.server));

      final isConnected = testQuery.docs.isNotEmpty || testQuery.size == 0;

      if (kDebugMode) {
        print(
          '✅ [DebugFirestore] Connection test ${isConnected ? 'PASSED' : 'FAILED'}',
        );
        print(
          '📊 [DebugFirestore] Test query returned ${testQuery.size} documents',
        );
      }

      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DebugFirestore] Connection test FAILED: $e');
      }
      return false;
    }
  }

  /// Test reading from investments collection
  static Future<Map<String, dynamic>> testInvestmentsCollection() async {
    if (kDebugMode) {
      print('🔍 [DebugFirestore] Testing investments collection...');
    }

    try {
      final snapshot = await _firestore
          .collection('investments')
          .limit(5)
          .get();

      final result = {
        'success': true,
        'documentCount': snapshot.size,
        'sampleData': snapshot.docs
            .map((doc) => {'id': doc.id, 'fields': doc.data().keys.toList()})
            .toList(),
      };

      if (kDebugMode) {
        print('✅ [DebugFirestore] Investments collection test PASSED');
        print(
          '📊 [DebugFirestore] Found ${snapshot.size} investment documents',
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DebugFirestore] Investments collection test FAILED: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'documentCount': 0,
        'sampleData': [],
      };
    }
  }

  /// Test reading from clients collection
  static Future<Map<String, dynamic>> testClientsCollection() async {
    if (kDebugMode) {
      print('🔍 [DebugFirestore] Testing clients collection...');
    }

    try {
      final snapshot = await _firestore.collection('clients').limit(5).get();

      final result = {
        'success': true,
        'documentCount': snapshot.size,
        'sampleData': snapshot.docs
            .map((doc) => {'id': doc.id, 'fields': doc.data().keys.toList()})
            .toList(),
      };

      if (kDebugMode) {
        print('✅ [DebugFirestore] Clients collection test PASSED');
        print('📊 [DebugFirestore] Found ${snapshot.size} client documents');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DebugFirestore] Clients collection test FAILED: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'documentCount': 0,
        'sampleData': [],
      };
    }
  }

  /// Comprehensive Firestore health check
  static Future<Map<String, dynamic>> performHealthCheck() async {
    if (kDebugMode) {
      print('🏥 [DebugFirestore] Performing comprehensive health check...');
    }

    final results = <String, dynamic>{};

    // Test basic connection
    results['connection'] = await testFirestoreConnection();

    // Test collections
    results['investments'] = await testInvestmentsCollection();
    results['clients'] = await testClientsCollection();

    // Overall health status
    results['overallHealth'] =
        results['connection'] &&
        results['investments']['success'] &&
        results['clients']['success'];

    results['timestamp'] = DateTime.now().toIso8601String();

    if (kDebugMode) {
      print(
        '🏥 [DebugFirestore] Health check completed. Overall: ${results['overallHealth'] ? 'HEALTHY' : 'ISSUES DETECTED'}',
      );
    }

    return results;
  }

  /// Test Firestore security rules (if applicable)
  static Future<Map<String, dynamic>> testSecurityRules() async {
    if (kDebugMode) {
      print('🔒 [DebugFirestore] Testing security rules...');
    }

    try {
      // Try to access different collections to test rules
      final tests = <String, bool>{};

      // Test read access to clients
      try {
        await _firestore.collection('clients').limit(1).get();
        tests['clients_read'] = true;
      } catch (e) {
        tests['clients_read'] = false;
        if (kDebugMode) {
          print('❌ [DebugFirestore] Clients read access denied: $e');
        }
      }

      // Test read access to investments
      try {
        await _firestore.collection('investments').limit(1).get();
        tests['investments_read'] = true;
      } catch (e) {
        tests['investments_read'] = false;
        if (kDebugMode) {
          print('❌ [DebugFirestore] Investments read access denied: $e');
        }
      }

      return {
        'success': true,
        'tests': tests,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DebugFirestore] Security rules test FAILED: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'tests': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get Firestore settings info
  static Map<String, dynamic> getFirestoreInfo() {
    return {
      'persistenceEnabled': _firestore.settings.persistenceEnabled,
      'host': _firestore.settings.host,
      'sslEnabled': _firestore.settings.sslEnabled,
      'cacheSizeBytes': _firestore.settings.cacheSizeBytes,
    };
  }
}

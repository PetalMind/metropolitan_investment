/// 🔧 UTILITY: FIX SCHEDULED EMAILS WITH EMPTY RECIPIENTS
///
/// Ten skrypt naprawia istniejące zaplanowane emaile, które mają puste listy odbiorców.
/// Uruchom go, aby automatycznie oznaczyć takie emaile jako nieudane.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  print('🔧 Fixing Scheduled Emails with Empty Recipients...');

  try {
    // Inicjalizacja Firestore (wymaga odpowiedniej konfiguracji)
    final firestore = FirebaseFirestore.instance;

    // Znajdź wszystkie oczekujące emaile
    final querySnapshot = await firestore
        .collection('scheduled_emails')
        .where('status', isEqualTo: 'pending')
        .get();

    print('📅 Found ${querySnapshot.docs.length} pending scheduled emails');

    int fixedCount = 0;
    int validCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final recipientsData = data['recipientsData'] as List<dynamic>? ?? [];
      final recipientsEmails = data['recipientsEmails'] as List<dynamic>? ?? [];

      print('\n📧 Checking email: ${doc.id}');
      print('   Subject: ${data['subject'] ?? 'N/A'}');
      print('   Recipients data count: ${recipientsData.length}');
      print('   Recipients emails count: ${recipientsEmails.length}');

      if (recipientsData.isEmpty && recipientsEmails.isEmpty) {
        // Email z pustymi recipientami - oznacz jako failed
        await doc.reference.update({
          'status': 'failed',
          'errorMessage':
              'Email zaplanowany bez odbiorców - automatycznie anulowany przez narzędzie naprawcze',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        fixedCount++;
        print('   ❌ FIXED: Marked as failed due to empty recipients');
      } else if (recipientsData.isEmpty && recipientsEmails.isNotEmpty) {
        // Email ma tylko emaile, ale nie ma pełnych danych - też oznacz jako failed
        await doc.reference.update({
          'status': 'failed',
          'errorMessage':
              'Email ma tylko adresy email ale brak pełnych danych odbiorców - wymagana ponowna konfiguracja',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        fixedCount++;
        print('   ⚠️  FIXED: Has emails but missing recipient data');
      } else {
        validCount++;
        print('   ✅ VALID: Has proper recipient data');
      }
    }

    print('\n🎉 Fix Complete!');
    print('   ✅ Valid emails: $validCount');
    print('   🔧 Fixed emails: $fixedCount');
    print('   📊 Total processed: ${querySnapshot.docs.length}');

    if (fixedCount > 0) {
      print('\n💡 Recommendation:');
      print('   - Review the fixed emails in your application');
      print('   - Reschedule them with proper recipient data if needed');
      print('   - The fix ensures future emails will work correctly');
    }
  } catch (e) {
    print('❌ Error fixing scheduled emails: $e');
    print('\n💡 This script requires:');
    print('   - Firebase project configuration');
    print('   - Proper authentication setup');
    print('   - Run from a Flutter/Dart environment with Firebase initialized');

    exit(1);
  }
}

/// Helper function to format timestamps
String formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return 'N/A';

  try {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp).toString();
    }
    return timestamp.toString();
  } catch (e) {
    return 'Invalid timestamp';
  }
}

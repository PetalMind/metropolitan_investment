import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 DEBUGOWANIE FUNKCJONALNOŚCI ZAPLANOWANYCH EMAILI
/// 
/// Ten skrypt sprawdza:
/// 1. Czy są zaplanowane emaile w Firestore
/// 2. Czy mają prawidłowy status i datę
/// 3. Czy Cloud Functions może je znaleźć

void main() async {
  print('🧪 Debugowanie zaplanowanych emaili...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('\n📋 SPRAWDZENIE 1: Wszystkie zaplanowane emaile');
    final allScheduled = await firestore
        .collection('scheduled_emails')
        .get();
    
    print('   Znalezione dokumenty: ${allScheduled.docs.length}');
    
    for (final doc in allScheduled.docs) {
      final data = doc.data();
      print('   📧 ID: ${doc.id}');
      print('      Status: ${data['status']}');
      print('      Scheduled: ${data['scheduledDateTime']}');
      print('      Recipients: ${data['recipientsCount'] ?? 'brak'}');
    }
    
    print('\n📋 SPRAWDZENIE 2: Emaile ze statusem pending');
    final pendingQuery = await firestore
        .collection('scheduled_emails')
        .where('status', isEqualTo: 'pending')
        .get();
    
    print('   Pending emaile: ${pendingQuery.docs.length}');
    
    print('\n📋 SPRAWDZENIE 3: Emaile gotowe do wysłania (≤ now)');
    final now = DateTime.now();
    final readyToSendQuery = await firestore
        .collection('scheduled_emails')
        .where('status', isEqualTo: 'pending')
        .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();
    
    print('   Gotowe do wysłania: ${readyToSendQuery.docs.length}');
    print('   Obecny czas: $now');
    
    for (final doc in readyToSendQuery.docs) {
      final data = doc.data();
      final scheduledTime = (data['scheduledDateTime'] as Timestamp).toDate();
      print('   📧 Gotowy email:');
      print('      ID: ${doc.id}');
      print('      Zaplanowany na: $scheduledTime');
      print('      Różnica: ${now.difference(scheduledTime).inMinutes} minut temu');
    }
    
    print('\n📋 SPRAWDZENIE 4: Test dodania nowego zaplanowanego emaila');
    final testDateTime = now.add(const Duration(minutes: 2));
    
    final testEmail = {
      'recipientsCount': 1,
      'recipientsEmails': ['test@example.com'],
      'recipientsData': [
        {
          'clientId': 'test_client_001',
          'clientName': 'Test Client',
          'clientEmail': 'test@example.com',
          'clientPhone': '+48123456789',
          'totalInvestmentAmount': 10000.0,
          'totalRemainingCapital': 8000.0,
          'totalSharesValue': 2000.0,
          'investmentCount': 1,
          'capitalSecuredByRealEstate': 5000.0,
        }
      ],
      'subject': 'Test zaplanowanego emaila',
      'htmlContent': '<h1>To jest test zaplanowanego emaila</h1>',
      'scheduledDateTime': Timestamp.fromDate(testDateTime),
      'senderEmail': 'noreply@metropolitan-investment.com',
      'senderName': 'Metropolitan Investment Test',
      'includeInvestmentDetails': true,
      'additionalRecipients': <String, String>{},
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'createdBy': 'debug_test',
      'notes': 'Email utworzony przez debugowanie - można usunąć',
    };
    
    final docRef = await firestore
        .collection('scheduled_emails')
        .add(testEmail);
    
    print('   ✅ Utworzono testowy email: ${docRef.id}');
    print('   📅 Zaplanowany na: $testDateTime');
    print('   ⏰ Za: ${testDateTime.difference(now).inMinutes} minut');
    
    print('\n🎯 WYNIKI DEBUGOWANIA:');
    print('   • Cloud Functions działa (widać w logach co minutę)');
    print('   • Kolekcja scheduled_emails: ${allScheduled.docs.length} dokumentów');
    print('   • Pending emaile: ${pendingQuery.docs.length}');
    print('   • Gotowe do wysłania: ${readyToSendQuery.docs.length}');
    print('   • Testowy email zostanie wysłany za ~2 minuty');
    
    print('\n💡 ZALECENIA:');
    if (allScheduled.docs.isEmpty) {
      print('   ❌ PROBLEM: Brak zaplanowanych emaili w bazie!');
      print('      • Sprawdź czy EmailSchedulingWidget zapisuje do Firestore');
      print('      • Sprawdź czy scheduleEmail() w EmailSchedulingService działa');
    } else if (pendingQuery.docs.isEmpty) {
      print('   ⚠️  Wszystkie emaile mają status inny niż "pending"');
    } else if (readyToSendQuery.docs.isEmpty) {
      print('   ⚠️  Wszystkie pending emaile są zaplanowane na przyszłość');
    } else {
      print('   ❓ Emaile są gotowe, ale Cloud Functions ich nie przetwarza');
      print('      • Sprawdź query w processScheduledEmails');
      print('      • Sprawdź strefy czasowe (Europe/Warsaw vs UTC)');
    }
    
  } catch (e) {
    print('❌ Błąd debugowania: $e');
  }
}
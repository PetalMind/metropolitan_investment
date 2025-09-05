import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Tworzy testowy zaplanowany email do weryfikacji funkcjonalności

void main() async {
  print('🧪 Tworzenie testowego zaplanowanego emaila...');
  
  try {
    // Inicjalizuj Firebase (potrzebne przed pierwszym użyciem Firestore)
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final testDateTime = now.add(const Duration(minutes: 2)); // Za 2 minuty
    
    print('📅 Obecny czas: $now');
    print('📅 Zaplanowany na: $testDateTime');
    print('⏰ Za: ${testDateTime.difference(now).inMinutes} minut');
    
    final testEmail = {
      'recipientsCount': 1,
      'recipientsEmails': ['dominikjaros99@icloud.com'],
      'recipientsData': [
        {
          'clientId': 'test_client_${now.millisecondsSinceEpoch}',
          'clientName': 'Test Scheduled Email Client',
          'clientEmail': 'dominikjaros99@icloud.com',
          'clientPhone': '+48123456789',
          'totalInvestmentAmount': 10000.0,
          'totalRemainingCapital': 8000.0,
          'totalSharesValue': 2000.0,
          'investmentCount': 1,
          'capitalSecuredByRealEstate': 5000.0,
        }
      ],
      'subject': '🧪 Test zaplanowanego emaila - ${now.minute}:${now.second}',
      'htmlContent': '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Scheduled Email</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #3b82f6; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9fafb; padding: 20px; border-radius: 0 0 8px 8px; }
        .success { background: #10b981; color: white; padding: 15px; border-radius: 6px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Test Zaplanowanego Emaila</h1>
        </div>
        <div class="content">
            <div class="success">
                ✅ <strong>SUKCES!</strong> Funkcjonalność opóźnionej wysyłki emaili działa prawidłowo!
            </div>
            <p>Szanowni Państwo,</p>
            <p>Ten email został automatycznie wysłany przez Cloud Functions w zaplanowanym czasie.</p>
            <h3>📊 Szczegóły testu:</h3>
            <ul>
                <li><strong>Utworzony:</strong> $now</li>
                <li><strong>Zaplanowany na:</strong> $testDateTime</li>
                <li><strong>Opóźnienie:</strong> 2 minuty</li>
                <li><strong>Funkcja:</strong> processScheduledEmails (Cloud Functions)</li>
            </ul>
            <p>Jeśli otrzymali Państwo ten email, oznacza to że:</p>
            <ol>
                <li>✅ EmailSchedulingService prawidłowo zapisuje do Firestore</li>
                <li>✅ Cloud Functions prawidłowo znajdują zaplanowane emaile</li>
                <li>✅ Integracja z custom-email-service działa</li>
                <li>✅ SMTP configuration jest prawidłowa</li>
            </ol>
            <hr>
            <p><em>Ten email można bezpiecznie usunąć - był częścią testów funkcjonalności.</em></p>
            <p>Z poważaniem,<br>Metropolitan Investment - System testowy</p>
        </div>
    </div>
</body>
</html>
      ''',
      'scheduledDateTime': Timestamp.fromDate(testDateTime),
      'senderEmail': 'noreply@metropolitan-investment.com',
      'senderName': 'Metropolitan Investment - Test',
      'includeInvestmentDetails': false,
      'additionalRecipients': <String, String>{},
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'createdBy': 'test_automation',
      'notes': 'Testowy email do weryfikacji funkcjonalności - ${now.toIso8601String()}',
    };
    
    final docRef = await firestore
        .collection('scheduled_emails')
        .add(testEmail);
    
    print('\n✅ Utworzono testowy email:');
    print('   📧 ID: ${docRef.id}');
    print('   📅 Zaplanowany na: $testDateTime');
    print('   ⏰ Za: ${testDateTime.difference(now).inMinutes} minut');
    print('   📬 Odbiorca: dominikjaros99@icloud.com');
    print('   💌 Temat: ${testEmail['subject']}');
    
    print('\n🎯 MONITOROWANIE:');
    print('   • Sprawdź logi Cloud Functions za ~2 minuty:');
    print('     firebase functions:log --only processScheduledEmails');
    print('   • Sprawdź status w Firestore:');
    print('     Kolekcja: scheduled_emails');
    print('     Dokument: ${docRef.id}');
    
    print('\n⌛ Czekam na wysłanie emaila...');
    
  } catch (e) {
    print('❌ Błąd tworzenia testowego emaila: $e');
    exit(1);
  }
}
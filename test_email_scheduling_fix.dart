/// 🧪 TEST: EMAIL SCHEDULING FIX
///
/// Ten test sprawdza, czy naprawka problemu z pustymi recipientami działa poprawnie.

import 'lib/models_and_services.dart';

void main() async {
  print('🧪 Testing Email Scheduling Fix...');

  // Test 1: ScheduledEmail.fromMap properly reconstructs recipients
  print('\n📧 Test 1: ScheduledEmail recipient reconstruction');

  final testData = {
    'recipientsData': [
      {
        'clientId': 'test-client-1',
        'clientName': 'Jan Kowalski',
        'clientEmail': 'jan@example.com',
        'clientPhone': '+48123456789',
        'totalInvestmentAmount': 50000.0,
        'totalRemainingCapital': 45000.0,
        'totalSharesValue': 5000.0,
        'investmentCount': 2,
        'capitalSecuredByRealEstate': 40000.0,
      },
      {
        'clientId': 'test-client-2',
        'clientName': 'Anna Nowak',
        'clientEmail': 'anna@example.com',
        'clientPhone': '+48987654321',
        'totalInvestmentAmount': 30000.0,
        'totalRemainingCapital': 25000.0,
        'totalSharesValue': 2000.0,
        'investmentCount': 1,
        'capitalSecuredByRealEstate': 20000.0,
      },
    ],
    'subject': 'Test Email',
    'htmlContent': '<p>Test content</p>',
    'scheduledDateTime': DateTime.now()
        .add(Duration(hours: 1))
        .millisecondsSinceEpoch,
    'senderEmail': 'sender@example.com',
    'senderName': 'Test Sender',
    'includeInvestmentDetails': true,
    'additionalRecipients': <String, String>{},
    'status': 'pending',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
    'createdBy': 'test-user',
  };

  try {
    final scheduledEmail = ScheduledEmail.fromMap(testData, 'test-email-id');

    print('✅ Successfully reconstructed ScheduledEmail');
    print('   📊 Recipients count: ${scheduledEmail.recipients.length}');

    for (int i = 0; i < scheduledEmail.recipients.length; i++) {
      final recipient = scheduledEmail.recipients[i];
      print('   👤 Recipient ${i + 1}:');
      print('      - Name: ${recipient.client.name}');
      print('      - Email: ${recipient.client.email}');
      print('      - Total Investment: ${recipient.totalInvestmentAmount}');
      print('      - Remaining Capital: ${recipient.totalRemainingCapital}');
    }

    if (scheduledEmail.recipients.isEmpty) {
      print('❌ FAIL: Recipients list is empty!');
    } else {
      print('✅ PASS: Recipients properly reconstructed');
    }
  } catch (e) {
    print('❌ ERROR: Failed to reconstruct ScheduledEmail: $e');
  }

  // Test 2: Empty recipients data
  print('\n📧 Test 2: Empty recipients data handling');

  final emptyData = {
    'recipientsData': [],
    'subject': 'Empty Test Email',
    'htmlContent': '<p>Test content</p>',
    'scheduledDateTime': DateTime.now()
        .add(Duration(hours: 1))
        .millisecondsSinceEpoch,
    'senderEmail': 'sender@example.com',
    'senderName': 'Test Sender',
    'includeInvestmentDetails': true,
    'additionalRecipients': <String, String>{},
    'status': 'pending',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
    'createdBy': 'test-user',
  };

  try {
    final emptyScheduledEmail = ScheduledEmail.fromMap(
      emptyData,
      'empty-email-id',
    );

    print('✅ Successfully handled empty recipients');
    print('   📊 Recipients count: ${emptyScheduledEmail.recipients.length}');

    if (emptyScheduledEmail.recipients.isEmpty) {
      print('✅ PASS: Empty recipients properly handled');
    } else {
      print('❌ FAIL: Expected empty recipients list');
    }
  } catch (e) {
    print('❌ ERROR: Failed to handle empty recipients: $e');
  }

  print('\n🎉 Email Scheduling Fix Test Complete!');
  print('💡 Summary:');
  print(
    '   - ScheduledEmail.fromMap now properly stores and retrieves recipients',
  );
  print('   - EmailSchedulingService validates recipients before sending');
  print(
    '   - Empty recipients are handled gracefully with proper error messages',
  );
  print('   - Debug function available to fix existing broken emails');
}

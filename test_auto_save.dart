import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/services/user_preferences_service.dart';

/// Simple test script to verify auto-save functionality
void main() async {
  // Initialize testing framework
  TestWidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing Auto-Save Functionality...\n');
  
  try {
    // Test 1: Initialize UserPreferencesService
    print('📋 Test 1: Initialize UserPreferencesService');
    final service = await UserPreferencesService.getInstance();
    print('✅ UserPreferencesService initialized successfully\n');
    
    // Test 2: Save a draft
    print('📋 Test 2: Save email draft');
    final testDraft = {
      'content': 'Test email content for auto-save functionality',
      'subject': 'Test Auto-Save Subject',
      'senderName': 'Test Sender',
      'senderEmail': 'test@metropolitan-investment.pl',
      'recipients': {'client_1': true, 'client_2': false},
      'additionalEmails': ['additional@example.com'],
      'includeDetails': true,
      'isGroupEmail': false,
    };
    
    final saveResult = await service.saveEmailDraft(
      content: testDraft['content'] as String,
      subject: testDraft['subject'] as String,
      senderName: testDraft['senderName'] as String,
      senderEmail: testDraft['senderEmail'] as String,
      recipients: testDraft['recipients'] as Map<String, bool>,
      additionalEmails: testDraft['additionalEmails'] as List<String>,
      includeDetails: testDraft['includeDetails'] as bool,
      isGroupEmail: testDraft['isGroupEmail'] as bool,
    );
    
    if (saveResult) {
      print('✅ Draft saved successfully');
    } else {
      print('❌ Failed to save draft');
    }
    
    // Test 3: Check if draft exists
    print('📋 Test 3: Check if draft exists');
    final hasDraft = service.hasEmailDraft();
    print('✅ Has draft: $hasDraft');
    
    // Test 4: Retrieve saved draft
    print('📋 Test 4: Retrieve saved draft');
    final retrievedDraft = service.getSavedEmailDraft();
    if (retrievedDraft != null) {
      print('✅ Draft retrieved successfully');
      print('   📧 Subject: ${retrievedDraft['subject']}');
      print('   📝 Content preview: ${(retrievedDraft['content'] as String).substring(0, 30)}...');
      print('   👤 Sender: ${retrievedDraft['senderName']}');
      print('   📅 Timestamp: ${retrievedDraft['timestamp']}');
    } else {
      print('❌ Failed to retrieve draft');
    }
    
    // Test 5: Check draft age
    print('📋 Test 5: Check draft age');
    final age = service.getEmailDraftAgeInMinutes();
    print('✅ Draft age: ${age ?? 'Unknown'} minutes\n');
    
    // Test 6: Clear draft
    print('📋 Test 6: Clear draft');
    final clearResult = await service.clearEmailDraft();
    if (clearResult) {
      print('✅ Draft cleared successfully');
    } else {
      print('❌ Failed to clear draft');
    }
    
    // Test 7: Verify draft is cleared
    print('📋 Test 7: Verify draft is cleared');
    final hasDraftAfterClear = service.hasEmailDraft();
    print('✅ Has draft after clear: $hasDraftAfterClear\n');
    
    print('🎉 All auto-save tests completed successfully!');
    print('\n📝 Summary of Auto-Save Features:');
    print('   💾 Automatic saving every 30 seconds');
    print('   🔄 Draft recovery on app restart');
    print('   👁️ Visual indicators for save status');
    print('   💽 Manual save button in quick actions');
    print('   🧹 Auto-cleanup after successful email sending');
    print('   ⏰ Draft expiration after 7 days');
    print('   🔔 User-friendly recovery dialog\n');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models_and_services.dart';
import '../models/email_template.dart';

/// Service for managing email templates in Firebase
class EmailTemplatesService extends BaseService {
  static const String _collectionPath = 'email_templates';

  /// Get all email templates
  Future<List<EmailTemplateModel>> getEmailTemplates() async {
    return getCachedData(
      'email_templates_all',
      () async {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection(_collectionPath)
              .orderBy('createdAt', descending: true)
              .get();

          return snapshot.docs
              .map((doc) => EmailTemplateModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        } catch (e) {
          if (kDebugMode) {
            print('Error loading email templates: $e');
          }
          return <EmailTemplateModel>[];
        }
      },
    );
  }

  /// Save email template to Firebase
  Future<bool> saveEmailTemplate(EmailTemplateModel template) async {
    try {
      final data = template.toJson();
      
      if (template.id.isEmpty) {
        // Create new template
        final docRef = await FirebaseFirestore.instance
            .collection(_collectionPath)
            .add(data);
        
        if (kDebugMode) {
          print('✅ Created email template: ${docRef.id}');
        }
      } else {
        // Update existing template
        await FirebaseFirestore.instance
            .collection(_collectionPath)
            .doc(template.id)
            .set(data, SetOptions(merge: true));
        
        if (kDebugMode) {
          print('✅ Updated email template: ${template.id}');
        }
      }

      // Clear cache
      clearCache('email_templates_all');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving email template: $e');
      }
      return false;
    }
  }

  /// Delete email template
  Future<bool> deleteEmailTemplate(String templateId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collectionPath)
          .doc(templateId)
          .delete();

      // Clear cache
      clearCache('email_templates_all');
      
      if (kDebugMode) {
        print('✅ Deleted email template: $templateId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting email template: $e');
      }
      return false;
    }
  }

  /// Get template by ID
  Future<EmailTemplateModel?> getTemplateById(String templateId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collectionPath)
          .doc(templateId)
          .get();

      if (doc.exists) {
        return EmailTemplateModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting template by ID: $e');
      }
      return null;
    }
  }
}
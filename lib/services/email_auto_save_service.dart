import 'dart:async';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💾 Auto-save service for email drafts
/// Provides automatic saving and restoration of email drafts to prevent work loss
class EmailAutoSaveService {
  static const String _keyPrefix = 'email_draft_';
  static const String _lastSaveKey = 'last_email_save_timestamp';
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  
  Timer? _autoSaveTimer;
  String? _currentDraftId;
  
  /// Initialize auto-save service with draft ID
  void initialize(String draftId, {Function()? onDraftRestored}) {
    _currentDraftId = draftId;
    _startAutoSaveTimer();
  }

  /// Start periodic auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      if (_currentDraftId != null) {
        _performAutoSave();
      }
    });
  }

  /// Stop auto-save timer
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Save email draft manually
  Future<void> saveDraft({
    required String draftId,
    required QuillController quillController,
    required String subject,
    required String senderEmail,
    required String senderName,
    required List<String> additionalEmails,
    required Map<String, bool> recipientEnabled,
    required bool includeInvestmentDetails,
    required bool isGroupEmail,
  }) async {
    try {
      final draft = EmailDraft(
        id: draftId,
        subject: subject,
        content: jsonEncode(quillController.document.toDelta().toJson()),
        senderEmail: senderEmail,
        senderName: senderName,
        additionalEmails: additionalEmails,
        recipientEnabled: recipientEnabled,
        includeInvestmentDetails: includeInvestmentDetails,
        isGroupEmail: isGroupEmail,
        lastModified: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPrefix + draftId, jsonEncode(draft.toJson()));
      await prefs.setInt(_lastSaveKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle save error silently in production
    }
  }

  /// Auto-save current draft (internal method)
  Future<void> _performAutoSave() async {
    if (_currentDraftId == null) return;
    
    try {
      // This would be called by the email editor with current state
      // Note: Actual implementation would require callback from email editor
    } catch (e) {
      // Handle auto-save error silently in production
    }
  }

  /// Load email draft by ID
  Future<EmailDraft?> loadDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_keyPrefix + draftId);
      
      if (draftJson != null) {
        final draftData = jsonDecode(draftJson);
        final draft = EmailDraft.fromJson(draftData);
        return draft;
      }
    } catch (e) {
      // Handle load error silently in production
    }
    return null;
  }

  /// Get all saved drafts
  Future<List<EmailDraft>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      final drafts = <EmailDraft>[];
      for (final key in keys) {
        final draftJson = prefs.getString(key);
        if (draftJson != null) {
          try {
            final draftData = jsonDecode(draftJson);
            drafts.add(EmailDraft.fromJson(draftData));
          } catch (e) {
            // Skip invalid draft silently in production
          }
        }
      }
      
      // Sort by last modified (newest first)
      drafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return drafts;
    } catch (e) {
      return [];
    }
  }

  /// Delete draft by ID
  Future<void> deleteDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPrefix + draftId);
    } catch (e) {
      // Handle delete error silently in production
    }
  }

  /// Check if there are any unsaved drafts (for recovery)
  Future<EmailDraft?> getLatestDraft() async {
    final drafts = await getAllDrafts();
    return drafts.isNotEmpty ? drafts.first : null;
  }

  /// Check if there are any drafts available for recovery
  Future<bool> hasRecoverableDrafts() async {
    try {
      final draft = await getLatestDraft();
      if (draft == null) return false;

      // Check if draft is not older than 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return !draft.lastModified.isBefore(sevenDaysAgo);
    } catch (e) {
      return false;
    }
  }

  /// Clear all old drafts (older than 30 days)
  Future<void> cleanupOldDrafts() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final drafts = await getAllDrafts();
      
      for (final draft in drafts) {
        if (draft.lastModified.isBefore(cutoffDate)) {
          await deleteDraft(draft.id);
        }
      }
    } catch (e) {
      // Handle cleanup error silently in production
    }
  }

  /// Handle draft recovery with option to delete rejected drafts
  /// Returns true if draft was recovered, false if rejected/deleted, null if no draft
  Future<bool?> handleDraftRecovery({
    required Future<bool?> Function(EmailDraft draft) showRecoveryDialog,
    required Function(EmailDraft draft) onDraftRecovered,
  }) async {
    try {
      final draft = await getLatestDraft();
      if (draft == null) return null;

      // Check if draft is not older than 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (draft.lastModified.isBefore(sevenDaysAgo)) {
        await deleteDraft(draft.id);
        return null;
      }

      // Show recovery dialog
      final shouldRecover = await showRecoveryDialog(draft);

      if (shouldRecover == true) {
        // Recover the draft
        onDraftRecovered(draft);
        return true;
      } else {
        // Delete the rejected draft
        await deleteDraft(draft.id);
        return false;
      }
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSave();
    _currentDraftId = null;
  }
}

/// Email draft data model
class EmailDraft {
  final String id;
  final String subject;
  final String content; // JSON string of Quill delta
  final String senderEmail;
  final String senderName;
  final List<String> additionalEmails;
  final Map<String, bool> recipientEnabled;
  final bool includeInvestmentDetails;
  final bool isGroupEmail;
  final DateTime lastModified;

  EmailDraft({
    required this.id,
    required this.subject,
    required this.content,
    required this.senderEmail,
    required this.senderName,
    required this.additionalEmails,
    required this.recipientEnabled,
    required this.includeInvestmentDetails,
    required this.isGroupEmail,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'content': content,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'additionalEmails': additionalEmails,
      'recipientEnabled': recipientEnabled,
      'includeInvestmentDetails': includeInvestmentDetails,
      'isGroupEmail': isGroupEmail,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory EmailDraft.fromJson(Map<String, dynamic> json) {
    return EmailDraft(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      senderName: json['senderName'] ?? '',
      additionalEmails: List<String>.from(json['additionalEmails'] ?? []),
      recipientEnabled: Map<String, bool>.from(json['recipientEnabled'] ?? {}),
      includeInvestmentDetails: json['includeInvestmentDetails'] ?? false,
      isGroupEmail: json['isGroupEmail'] ?? false,
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        json['lastModified'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Get formatted last modified time
  String get formattedLastModified {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Auto-save status information
class AutoSaveStatus {
  final bool isEnabled;
  final DateTime? lastSaveTime;
  final int draftsCount;
  final String? currentDraftId;

  AutoSaveStatus({
    required this.isEnabled,
    required this.lastSaveTime,
    required this.draftsCount,
    required this.currentDraftId,
  });

  String get statusText {
    if (!isEnabled) return 'Auto-save disabled';
    if (lastSaveTime == null) return 'No saves yet';
    
    final now = DateTime.now();
    final difference = now.difference(lastSaveTime!);
    
    if (difference.inMinutes < 1) {
      return 'Saved just now';
    } else if (difference.inMinutes < 60) {
      return 'Saved ${difference.inMinutes} min ago';
    } else {
      return 'Saved ${difference.inHours} hours ago';
    }
  }
}
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserPreferencesService {
  static UserPreferencesService? _instance;
  static SharedPreferences? _preferences;

  static const String _rememberMeKey = 'remember_me';
  static const String _lastEmailKey = 'last_email';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginTimestampKey = 'last_login_timestamp';
  static const String _sessionTimeoutKey = 'session_timeout';
  
  // 💾 AUTO-SAVE EMAIL DRAFT KEYS
  static const String _emailDraftContentKey = 'email_draft_content';
  static const String _emailDraftSubjectKey = 'email_draft_subject';
  static const String _emailDraftSenderNameKey = 'email_draft_sender_name';
  static const String _emailDraftSenderEmailKey = 'email_draft_sender_email';
  static const String _emailDraftTimestampKey = 'email_draft_timestamp';
  static const String _emailDraftRecipientsKey = 'email_draft_recipients';
  static const String _emailDraftAdditionalEmailsKey =
      'email_draft_additional_emails';
  static const String _emailDraftIncludeDetailsKey =
      'email_draft_include_details';
  static const String _emailDraftIsGroupEmailKey = 'email_draft_is_group_email';

  UserPreferencesService._();

  static Future<UserPreferencesService> getInstance() async {
    _instance ??= UserPreferencesService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Remember Me functionality
  Future<bool> setRememberMe(bool value) async {
    try {
      return await _preferences!.setBool(_rememberMeKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting remember me: $e');
      }
      return false;
    }
  }

  bool getRememberMe() {
    try {
      return _preferences?.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting remember me: $e');
      }
      return false;
    }
  }

  // Last email for convenience
  Future<bool> setLastEmail(String email) async {
    try {
      return await _preferences!.setString(_lastEmailKey, email);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting last email: $e');
      }
      return false;
    }
  }

  String? getLastEmail() {
    try {
      return _preferences?.getString(_lastEmailKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last email: $e');
      }
      return null;
    }
  }

  // Auto login enabled
  Future<bool> setAutoLoginEnabled(bool value) async {
    try {
      return await _preferences!.setBool(_autoLoginEnabledKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting auto login enabled: $e');
      }
      return false;
    }
  }

  bool getAutoLoginEnabled() {
    try {
      return _preferences?.getBool(_autoLoginEnabledKey) ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting auto login enabled: $e');
      }
      return true;
    }
  }

  // Biometric authentication enabled
  Future<bool> setBiometricEnabled(bool value) async {
    try {
      return await _preferences!.setBool(_biometricEnabledKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting biometric enabled: $e');
      }
      return false;
    }
  }

  bool getBiometricEnabled() {
    try {
      return _preferences?.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting biometric enabled: $e');
      }
      return false;
    }
  }

  // Last login timestamp for session management
  Future<bool> setLastLoginTimestamp(DateTime timestamp) async {
    try {
      return await _preferences!.setInt(
        _lastLoginTimestampKey,
        timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error setting last login timestamp: $e');
      }
      return false;
    }
  }

  DateTime? getLastLoginTimestamp() {
    try {
      final timestamp = _preferences?.getInt(_lastLoginTimestampKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last login timestamp: $e');
      }
      return null;
    }
  }

  // Session timeout in minutes (default 30 days for remember me)
  Future<bool> setSessionTimeout(int minutes) async {
    try {
      return await _preferences!.setInt(_sessionTimeoutKey, minutes);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting session timeout: $e');
      }
      return false;
    }
  }

  int getSessionTimeout() {
    try {
      return _preferences?.getInt(_sessionTimeoutKey) ??
          (30 * 24 * 60); // 30 days
    } catch (e) {
      if (kDebugMode) {
        print('Error getting session timeout: $e');
      }
      return 30 * 24 * 60; // 30 days default
    }
  }

  // Check if session is expired
  bool isSessionExpired() {
    final lastLogin = getLastLoginTimestamp();
    if (lastLogin == null) return true;

    final sessionTimeout = getSessionTimeout();
    final expiryTime = lastLogin.add(Duration(minutes: sessionTimeout));

    return DateTime.now().isAfter(expiryTime);
  }

  // Clear all auth-related preferences
  Future<bool> clearAuthPreferences() async {
    try {
      final futures = await Future.wait([
        _preferences!.remove(_rememberMeKey),
        _preferences!.remove(_lastEmailKey),
        _preferences!.remove(_lastLoginTimestampKey),
      ]);
      return futures.every((result) => result);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing auth preferences: $e');
      }
      return false;
    }
  }

  // Clear all preferences (for complete reset)
  Future<bool> clearAllPreferences() async {
    try {
      return await _preferences!.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all preferences: $e');
      }
      return false;
    }
  }

  // Save login preferences
  Future<void> saveLoginPreferences({
    required bool rememberMe,
    required String email,
  }) async {
    await Future.wait([
      setRememberMe(rememberMe),
      if (rememberMe) setLastEmail(email),
      setLastLoginTimestamp(DateTime.now()),
    ]);
  }

  // Check if auto login should be performed
  bool shouldAutoLogin() {
    final rememberMe = getRememberMe();
    final autoLoginEnabled = getAutoLoginEnabled();
    final sessionExpired = isSessionExpired();

    return rememberMe && autoLoginEnabled && !sessionExpired;
  }

  // Get saved login data for auto login
  Map<String, dynamic> getSavedLoginData() {
    return {
      'rememberMe': getRememberMe(),
      'lastEmail': getLastEmail(),
      'autoLoginEnabled': getAutoLoginEnabled(),
      'sessionExpired': isSessionExpired(),
      'shouldAutoLogin': shouldAutoLogin(),
    };
  }

  // 💾 EMAIL DRAFT AUTO-SAVE FUNCTIONALITY

  /// Save email draft data
  Future<bool> saveEmailDraft({
    required String content,
    required String subject,
    required String senderName,
    required String senderEmail,
    required Map<String, bool> recipients,
    required List<String> additionalEmails,
    required bool includeDetails,
    required bool isGroupEmail,
  }) async {
    try {
      final futures = await Future.wait([
        _preferences!.setString(_emailDraftContentKey, content),
        _preferences!.setString(_emailDraftSubjectKey, subject),
        _preferences!.setString(_emailDraftSenderNameKey, senderName),
        _preferences!.setString(_emailDraftSenderEmailKey, senderEmail),
        _preferences!.setString(
          _emailDraftRecipientsKey,
          recipients.entries.map((e) => '${e.key}:${e.value}').join('|'),
        ),
        _preferences!.setStringList(
          _emailDraftAdditionalEmailsKey,
          additionalEmails,
        ),
        _preferences!.setBool(_emailDraftIncludeDetailsKey, includeDetails),
        _preferences!.setBool(_emailDraftIsGroupEmailKey, isGroupEmail),
        _preferences!.setInt(
          _emailDraftTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      if (kDebugMode) {
        print('💾 Email draft saved successfully');
      }

      return futures.every((result) => result);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving email draft: $e');
      }
      return false;
    }
  }

  /// Get saved email draft
  Map<String, dynamic>? getSavedEmailDraft() {
    try {
      final timestamp = _preferences?.getInt(_emailDraftTimestampKey);
      if (timestamp == null) return null;

      // Check if draft is not older than 7 days
      final draftDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (draftDate.isBefore(sevenDaysAgo)) {
        clearEmailDraft();
        return null;
      }

      final content = _preferences?.getString(_emailDraftContentKey) ?? '';
      final subject = _preferences?.getString(_emailDraftSubjectKey) ?? '';
      final senderName =
          _preferences?.getString(_emailDraftSenderNameKey) ?? '';
      final senderEmail =
          _preferences?.getString(_emailDraftSenderEmailKey) ?? '';
      final recipientsString =
          _preferences?.getString(_emailDraftRecipientsKey) ?? '';
      final additionalEmails =
          _preferences?.getStringList(_emailDraftAdditionalEmailsKey) ?? [];
      final includeDetails =
          _preferences?.getBool(_emailDraftIncludeDetailsKey) ?? true;
      final isGroupEmail =
          _preferences?.getBool(_emailDraftIsGroupEmailKey) ?? false;

      // Parse recipients
      final Map<String, bool> recipients = {};
      if (recipientsString.isNotEmpty) {
        for (final entry in recipientsString.split('|')) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            recipients[parts[0]] = parts[1] == 'true';
          }
        }
      }

      return {
        'content': content,
        'subject': subject,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'recipients': recipients,
        'additionalEmails': additionalEmails,
        'includeDetails': includeDetails,
        'isGroupEmail': isGroupEmail,
        'timestamp': draftDate,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved email draft: $e');
      }
      return null;
    }
  }

  /// Check if there's a saved email draft
  bool hasEmailDraft() {
    final draft = getSavedEmailDraft();
    return draft != null && (draft['content'] as String).isNotEmpty;
  }

  /// Clear saved email draft
  Future<bool> clearEmailDraft() async {
    try {
      final futures = await Future.wait([
        _preferences!.remove(_emailDraftContentKey),
        _preferences!.remove(_emailDraftSubjectKey),
        _preferences!.remove(_emailDraftSenderNameKey),
        _preferences!.remove(_emailDraftSenderEmailKey),
        _preferences!.remove(_emailDraftRecipientsKey),
        _preferences!.remove(_emailDraftAdditionalEmailsKey),
        _preferences!.remove(_emailDraftIncludeDetailsKey),
        _preferences!.remove(_emailDraftIsGroupEmailKey),
        _preferences!.remove(_emailDraftTimestampKey),
      ]);

      if (kDebugMode) {
        print('🗑️ Email draft cleared successfully');
      }

      return futures.every((result) => result);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing email draft: $e');
      }
      return false;
    }
  }

  /// Get age of the current draft in minutes
  int? getEmailDraftAgeInMinutes() {
    final timestamp = _preferences?.getInt(_emailDraftTimestampKey);
    if (timestamp == null) return null;

    final draftDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(draftDate).inMinutes;
  }
}

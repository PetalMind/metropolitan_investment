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
      return _preferences?.getInt(_sessionTimeoutKey) ?? (30 * 24 * 60); // 30 days
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
}

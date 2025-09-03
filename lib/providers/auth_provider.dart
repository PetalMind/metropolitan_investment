import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  UserPreferencesService? _preferencesService;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userProfile?.isAdmin ?? false;
  bool get isSuperAdmin => _userProfile?.isSuperAdmin ?? false;
  bool get isVisibleAdmin => _userProfile?.isVisibleAdmin ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    _setInitializing(true);

    try {
      // Initialize preferences service
      _preferencesService = await UserPreferencesService.getInstance();

      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) async {
        _user = user;
        if (user != null) {
          _userProfile = await _authService.getUserProfile(user.uid);

          // Update last login timestamp if user is signing in
          if (_preferencesService != null) {
            final now = DateTime.now();
            await _preferencesService!.setLastLoginTimestamp(now);

            // Update last login timestamp in Firebase
            await _authService.updateLastLoginInFirebase(user.uid);
          }
        } else {
          _userProfile = null;
        }
        _setInitializing(false);
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing auth: $e');
      }
      _setInitializing(false);
    }
  }

  // Get saved login data for auto-filling forms
  Future<Map<String, dynamic>> getSavedLoginData() async {
    _preferencesService ??= await UserPreferencesService.getInstance();
    return _preferencesService!.getSavedLoginData();
  }

  // Check if should perform auto login
  Future<bool> shouldAutoLogin() async {
    return await _authService.shouldAutoLogin();
  }

  // Sign in
  Future<bool> signIn(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (result.isSuccess) {
        _user = result.user;
        if (_user != null) {
          _userProfile = await _authService.getUserProfile(_user!.uid);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Nieznany błąd');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Wystąpił nieoczekiwany błąd');
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? company,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        company: company,
        phone: phone,
      );

      if (result.isSuccess) {
        _user = result.user;
        if (_user != null) {
          _userProfile = await _authService.getUserProfile(_user!.uid);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Nieznany błąd');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Wystąpił nieoczekiwany błąd');
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.resetPassword(email: email);

      if (result.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Nieznany błąd');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Wystąpił nieoczekiwany błąd');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut({bool clearRememberMe = false}) async {
    _setLoading(true);

    try {
      await _authService.signOut(clearRememberMe: clearRememberMe);
      _user = null;
      _userProfile = null;
    } catch (e) {
      _setError('Błąd podczas wylogowywania');
    }

    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? company,
    String? phone,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.updateUserProfile(
        uid: _user!.uid,
        firstName: firstName,
        lastName: lastName,
        company: company,
        phone: phone,
      );

      if (success) {
        _userProfile = await _authService.getUserProfile(_user!.uid);
      } else {
        _setError('Nie udało się zaktualizować profilu');
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Wystąpił nieoczekiwany błąd');
      _setLoading(false);
      return false;
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setInitializing(bool initializing) {
    _isInitializing = initializing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}

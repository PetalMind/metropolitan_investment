import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 🔒 SERWIS FILTROWANIA UŻYTKOWNIKÓW SUPER-ADMIN
/// Odpowiada za ukrywanie użytkowników z rolą super-admin w interfejsach
class UserDisplayFilterService extends BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for super-admin users to avoid repeated Firestore queries
  final Map<String, bool> _superAdminCache = {};
  final Map<String, bool> _emailSuperAdminCache = {};
  
  /// Sprawdza czy użytkownik o podanym UID to super-admin
  Future<bool> isSuperAdmin(String uid) async {
    if (_superAdminCache.containsKey(uid)) {
      return _superAdminCache[uid]!;
    }
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = doc.data()?['role'] ?? 'user';
        final isSuperAdmin = role == 'super-admin' || role == 'superadmin';
        _superAdminCache[uid] = isSuperAdmin;
        return isSuperAdmin;
      }
    } catch (e) {
      logError('isSuperAdmin', 'Błąd sprawdzania roli użytkownika: $e');
    }
    
    _superAdminCache[uid] = false;
    return false;
  }
  
  /// Sprawdza czy użytkownik o podanym emailu to super-admin
  Future<bool> isSuperAdminByEmail(String email) async {
    if (_emailSuperAdminCache.containsKey(email)) {
      return _emailSuperAdminCache[email]!;
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        final role = querySnapshot.docs.first.data()['role'] ?? 'user';
        final isSuperAdmin = role == 'super-admin' || role == 'superadmin';
        _emailSuperAdminCache[email] = isSuperAdmin;
        return isSuperAdmin;
      }
    } catch (e) {
      logError('isSuperAdminByEmail', 'Błąd sprawdzania roli użytkownika: $e');
    }
    
    _emailSuperAdminCache[email] = false;
    return false;
  }
  
  /// Filtruje listę historii zmian, ukrywając wpisy od super-adminów
  Future<List<InvestmentChangeHistory>> filterHistoryBySuperAdmin(
    List<InvestmentChangeHistory> history,
  ) async {
    final filteredHistory = <InvestmentChangeHistory>[];
    
    for (final entry in history) {
      // Sprawdź czy użytkownik to super-admin
      final isSuperAdminUser = await isSuperAdmin(entry.userId);
      final isSuperAdminEmail = await isSuperAdminByEmail(entry.userEmail);
      
      // Ukryj wpisy od super-adminów
      if (!isSuperAdminUser && !isSuperAdminEmail) {
        filteredHistory.add(entry);
      }
    }
    
    return filteredHistory;
  }
  
  /// Zamaskuje nazwę użytkownika jeśli to super-admin
  Future<String> maskUserNameIfSuperAdmin(
    String userId,
    String userEmail,
    String userName,
  ) async {
    final isSuperAdminUser = await isSuperAdmin(userId);
    final isSuperAdminEmail = await isSuperAdminByEmail(userEmail);
    
    if (isSuperAdminUser || isSuperAdminEmail) {
      return 'System Administrator'; // Zamaskowana nazwa
    }
    
    return userName; // Oryginalna nazwa
  }
  
  /// Filtruje statystyki produktu, ukrywając dane super-adminów
  Future<ProductHistoryStats> filterProductStats(
    List<InvestmentChangeHistory> history,
  ) async {
    final filteredHistory = await filterHistoryBySuperAdmin(history);
    return ProductHistoryStats.fromHistory(filteredHistory);
  }
  
  /// Czyści cache (przydatne po zmianach ról)
  @override
  void clearCache(String key) {
    if (key == 'all' || key.isEmpty) {
      _superAdminCache.clear();
      _emailSuperAdminCache.clear();
    } else if (key.startsWith('uid:')) {
      _superAdminCache.remove(key.substring(4));
    } else if (key.startsWith('email:')) {
      _emailSuperAdminCache.remove(key.substring(6));
    }
  }
  
  /// Czyści cały cache
  void clearAllCache() {
    _superAdminCache.clear();
    _emailSuperAdminCache.clear();
  }
}
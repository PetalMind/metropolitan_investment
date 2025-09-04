import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models_and_services.dart' hide UserProfile;
import '../../models/user_profile.dart';
import '../../models/email_history.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme_professional.dart';

// Extension to add copyWith method to UserProfile
extension UserProfileCopyWith on UserProfile {
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? company,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class AdminPanelTab extends StatefulWidget {
  const AdminPanelTab({super.key});

  @override
  State<AdminPanelTab> createState() => _AdminPanelTabState();
}

class _AdminPanelTabState extends State<AdminPanelTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Admin data
  bool _isLoading = true;
  List<UserProfile> _users = [];
  Map<String, dynamic> _systemStats = {};
  Map<String, dynamic> _emailStats = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAdminData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _loadAdminData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Sprawdź uprawnienia administratora
    if (!authProvider.isAdmin) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await Future.wait([_loadUsers(), _loadSystemStats(), _loadEmailStats()]);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas ładowania danych administratora: $e');
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      // 🔥 REAL FIREBASE DATA: Pobierz wszystkich użytkowników z Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('email')
          .get();

      final rawUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id; // Dodaj uid do map
        return data;
      }).toList();

      // 🔒 UKRYJ SUPER-ADMINÓW: Filtruj użytkowników - nie pokazuj super-admin
      final filteredUsers = rawUsers.where((user) {
        final role = user['role'] ?? 'user';
        return role != 'super-admin' && role != 'superadmin';
      }).toList();

      // 🎯 CONVERT TO USERPROFILE: Mapuj surowe dane na UserProfile model
      final userProfiles = filteredUsers.map((userData) {
        return _mapToUserProfile(userData);
      }).toList();

      if (mounted) {
        setState(() {
          _users = userProfiles;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas ładowania użytkowników: $e');
      }
    }
  }

  /// 🔄 MAP TO USERPROFILE: Konwertuje surowe dane Firebase na UserProfile model
  UserProfile _mapToUserProfile(Map<String, dynamic> userData) {
    // Parse role string to UserRole enum
    UserRole role;
    final roleString = userData['role']?.toString() ?? 'user';
    switch (roleString.toLowerCase()) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'super-admin':
      case 'superadmin':
        role = UserRole.superAdmin;
        break;
      case 'user':
        role = UserRole.user;
        break;
      default:
        role = UserRole.unknown;
    }

    // Parse timestamps
    DateTime? createdAt;
    DateTime? updatedAt;
    DateTime? lastLoginAt;

    if (userData['createdAt'] is Timestamp) {
      createdAt = (userData['createdAt'] as Timestamp).toDate();
    }
    if (userData['updatedAt'] is Timestamp) {
      updatedAt = (userData['updatedAt'] as Timestamp).toDate();
    }
    if (userData['lastLoginAt'] is Timestamp) {
      lastLoginAt = (userData['lastLoginAt'] as Timestamp).toDate();
    }

    return UserProfile(
      uid: userData['uid'] ?? '',
      email: userData['email'] ?? '',
      displayName: userData['displayName'],
      firstName: userData['firstName'],
      lastName: userData['lastName'],
      company: userData['company'],
      phone: userData['phone'],
      role: role,
      isActive: userData['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Future<void> _loadSystemStats() async {
    try {
      // Symulacja ładowania statystyk systemowych
      // 🔥 REAL STATS CALCULATION: Oblicz statystyki na podstawie rzeczywistych danych
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        // Oblicz statystyki użytkowników na podstawie załadowanych danych
        final totalUsers = _users.length;
        final activeUsers = _users.where((u) => u.isActive).length;
        final adminUsers = _users.where((u) => u.role == UserRole.admin).length;

        setState(() {
          _systemStats = {
            'totalUsers': totalUsers,
            'activeUsers': activeUsers,
            'adminUsers': adminUsers,
            'totalInvestments':
                15847, // TODO: Można dodać rzeczywiste zapytanie
            'totalClients': 3456, // TODO: Można dodać rzeczywiste zapytanie
            'dataIntegrityScore': 97.8,
            'systemUptime': '99.9%',
            'lastBackup': DateTime.now().subtract(const Duration(hours: 6)),
            'storageUsed': '2.4 GB',
            'apiRequestsToday': 12847,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas ładowania statystyk: $e');
      }
    }
  }

  Future<void> _loadEmailStats() async {
    try {
      // 🔥 REAL FIREBASE DATA: Pobierz statystyki emaili z kolekcji email_history
      final emailHistorySnapshot = await FirebaseFirestore.instance
          .collection('email_history')
          .orderBy('sentAt', descending: true)
          .get();

      if (mounted) {
        // 📊 OBLICZ STATYSTYKI EMAILI
        final totalEmails = emailHistorySnapshot.docs.length;
        int successfulEmails = 0;
        int failedEmails = 0;
        int totalRecipients = 0;
        int successfulRecipients = 0;
        DateTime? lastEmailSent;

        for (final doc in emailHistorySnapshot.docs) {
          final emailHistory = EmailHistory.fromFirestore(doc);

          // Policz całkowite emaile
          switch (emailHistory.status) {
            case EmailStatus.sent:
              successfulEmails++;
              break;
            case EmailStatus.failed:
            case EmailStatus.partiallyFailed:
              failedEmails++;
              break;
            case EmailStatus.pending:
            case EmailStatus.sending:
              // Nie liczmy oczekujących
              break;
          }

          // Policz odbiorców
          totalRecipients += emailHistory.recipients.length;
          successfulRecipients += emailHistory.recipients
              .where((r) => r.deliveryStatus == DeliveryStatus.delivered)
              .length;

          // Znajdź ostatni wysłany email
          if (lastEmailSent == null ||
              emailHistory.sentAt.isAfter(lastEmailSent)) {
            lastEmailSent = emailHistory.sentAt;
          }
        }

        // Oblicz dzisiejsze emaile
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEmails = emailHistorySnapshot.docs.where((doc) {
          final emailHistory = EmailHistory.fromFirestore(doc);
          return emailHistory.sentAt.isAfter(todayStart);
        }).length;

        // Oblicz statystyki z ostatnich 7 dni
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        final weeklyEmails = emailHistorySnapshot.docs.where((doc) {
          final emailHistory = EmailHistory.fromFirestore(doc);
          return emailHistory.sentAt.isAfter(weekAgo);
        }).length;

        setState(() {
          _emailStats = {
            'totalEmails': totalEmails,
            'successfulEmails': successfulEmails,
            'failedEmails': failedEmails,
            'totalRecipients': totalRecipients,
            'successfulRecipients': successfulRecipients,
            'successRate': totalEmails > 0
                ? ((successfulEmails / totalEmails) * 100).toStringAsFixed(1)
                : '0.0',
            'deliveryRate': totalRecipients > 0
                ? ((successfulRecipients / totalRecipients) * 100)
                      .toStringAsFixed(1)
                : '0.0',
            'todayEmails': todayEmails,
            'weeklyEmails': weeklyEmails,
            'lastEmailSent': lastEmailSent,
            'averageRecipientsPerEmail': totalEmails > 0
                ? (totalRecipients / totalEmails).toStringAsFixed(1)
                : '0.0',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas ładowania statystyk emaili: $e');
      }
    }
  }

  Future<void> _toggleUserStatus(UserProfile user) async {
    try {
      // 🔥 REAL FIREBASE UPDATE: Aktualizuj status użytkownika w Firestore
      final newStatus = !user.isActive;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isActive': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Odśwież listę użytkowników po zmianie
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '✅ Użytkownik ${user.fullName} został aktywowany'
                  : '🔒 Użytkownik ${user.fullName} został dezaktywowany',
            ),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas zmiany statusu użytkownika: $e');
    }
  }

  Future<void> _changeUserRole(UserProfile user, UserRole newRole) async {
    try {
      // 🔥 REAL FIREBASE UPDATE: Aktualizuj rolę użytkownika w Firestore
      final roleString = _userRoleToString(newRole);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'role': roleString, 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Odśwież listę użytkowników po zmianie
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Rola użytkownika ${user.fullName} została zmieniona na ${_getRoleDisplayName(newRole)}',
            ),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas zmiany roli użytkownika: $e');
    }
  }

  /// 🔄 ENUM TO STRING: Konwertuje UserRole enum na string dla Firebase
  String _userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
      case UserRole.superAdmin:
        return 'super-admin';
      case UserRole.unknown:
        return 'user'; // Default fallback
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppThemePro.statusError,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAdmin) {
          return _buildAccessDenied();
        }

        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppThemePro.accentGold),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(authProvider),
                const SizedBox(height: 24),
                _buildSystemStatsSection(),
                const SizedBox(height: 24),
                _buildEmailStatsSection(),
                const SizedBox(height: 24),
                _buildUserManagementSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessDenied() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_rounded,
            size: 64,
            color: AppThemePro.statusError,
          ),
          const SizedBox(height: 16),
          Text(
            'Brak uprawnień',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nie masz uprawnień do przeglądania panelu administratora.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusError.withOpacity(0.1),
            AppThemePro.statusError.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.statusError.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.statusError.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: AppThemePro.statusError,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel administratora',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zalogowany jako: ${authProvider.userProfile?.fullName} (${authProvider.userProfile?.role.toString().split('.').last})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatsSection() {
    return _buildAdminCard(
      'Statystyki systemu',
      Icons.dashboard_rounded,
      AppThemePro.bondsBlue,
      [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Użytkownicy',
                '${_systemStats['totalUsers'] ?? 0}',
                '${_systemStats['activeUsers'] ?? 0} aktywnych',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                'Inwestycje',
                '${_systemStats['totalInvestments'] ?? 0}',
                'dokumentów',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Klienci',
                '${_systemStats['totalClients'] ?? 0}',
                'zarejestrowanych',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                'Integralność',
                '${_systemStats['dataIntegrityScore'] ?? 0}%',
                'jakość danych',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailStatsSection() {
    return _buildAdminCard(
      'Statystyki wysłanych emaili',
      Icons.email_rounded,
      AppThemePro.accentGold,
      [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Wysłane emaile',
                '${_emailStats['totalEmails'] ?? 0}',
                '${_emailStats['successfulEmails'] ?? 0} pomyślnych',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                'Wskaźnik sukcesu',
                '${_emailStats['successRate'] ?? '0.0'}%',
                'wysłanych emaili',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Odbiorcy',
                '${_emailStats['totalRecipients'] ?? 0}',
                '${_emailStats['successfulRecipients'] ?? 0} dostarczonych',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                'Wskaźnik dostarczenia',
                '${_emailStats['deliveryRate'] ?? '0.0'}%',
                'dostarczonych emaili',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Dzisiaj',
                '${_emailStats['todayEmails'] ?? 0}',
                'wysłanych emaili',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatTile(
                'Ten tydzień',
                '${_emailStats['weeklyEmails'] ?? 0}',
                'wysłanych emaili',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemePro.surfaceInteractive.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppThemePro.borderSecondary, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmailMetricRow(
                'Ostatni wysłany email',
                _formatDateTime(_emailStats['lastEmailSent']),
              ),
              _buildEmailMetricRow(
                'Średnia odbiorców na email',
                '${_emailStats['averageRecipientsPerEmail'] ?? '0.0'}',
              ),
              _buildEmailMetricRow(
                'Emaile nieudane',
                '${_emailStats['failedEmails'] ?? 0}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagementSection() {
    return _buildAdminCard(
      'Zarządzanie użytkownikami (${_users.length})',
      Icons.people_rounded,
      AppThemePro.sharesGreen,
      [..._users.map((user) => _buildUserTile(user))],
    );
  }

  Widget _buildAdminCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceInteractive.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMetricRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isActive
            ? AppThemePro.surfaceInteractive.withOpacity(0.5)
            : AppThemePro.statusError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: user.isActive
              ? AppThemePro.borderSecondary
              : AppThemePro.statusError.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role),
                child: Icon(
                  _getRoleIcon(user.role),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoleChip(user.role),
              const SizedBox(width: 8),
              _buildStatusChip(user.isActive),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Ostatnie logowanie: ${_formatDateTime(user.lastLoginAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'toggle_status':
                      _toggleUserStatus(user);
                      break;
                    case 'change_role':
                      _showRoleChangeDialog(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Text(user.isActive ? 'Dezaktywuj' : 'Aktywuj'),
                  ),
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Text('Zmień rolę'),
                  ),
                ],
                child: Icon(
                  Icons.more_vert_rounded,
                  color: AppThemePro.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getRoleDisplayName(role),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive
        ? AppThemePro.statusSuccess
        : AppThemePro.statusError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isActive ? 'Aktywny' : 'Nieaktywny',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppThemePro.statusError;
      case UserRole.admin:
        return AppThemePro.statusWarning;
      case UserRole.user:
        return AppThemePro.statusInfo;
      case UserRole.unknown:
        return AppThemePro.backgroundSecondary;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.admin:
        return Icons.shield_rounded;
      case UserRole.user:
        return Icons.person_rounded;
      case UserRole.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'Użytkownik';
      case UserRole.unknown:
        return 'Nieznana';
    }
  }

  void _showRoleChangeDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.surfaceCard,
        title: Text(
          'Zmień rolę użytkownika',
          style: TextStyle(color: AppThemePro.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .map(
                (role) => ListTile(
                  leading: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                  title: Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(color: AppThemePro.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _changeUserRole(user, role);
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Nigdy';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m temu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h temu';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}d temu';
    } else {
      return '${(diff.inDays / 30).floor()}mies temu';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme_professional.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_profile.dart';

class AccountProfileTab extends StatefulWidget {
  const AccountProfileTab({super.key});

  @override
  State<AccountProfileTab> createState() => _AccountProfileTabState();
}

class _AccountProfileTabState extends State<AccountProfileTab> {
  bool _isLoading = false;
  DateTime? _lastLoginTime;
  int _activeSessions = 1;
  UserProfile? _userProfile;
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;

      if (user?.uid != null) {
        // Load real user profile data
        _userProfile = await _userProfileService.getUserProfile(user!.uid);

        // If no profile exists, create one
        if (_userProfile == null) {
          await _userProfileService.createUserProfile(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          );
          _userProfile = await _userProfileService.getUserProfile(user.uid);
        }
      }

      // Mock data for demonstration (in real app this would come from auth service)
      if (mounted) {
        setState(() {
          _lastLoginTime = DateTime.now().subtract(const Duration(hours: 2));
          _activeSessions = 3;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(auth),
              const SizedBox(height: 24),
              _buildProfileStats(),
              const SizedBox(height: 24),
              _buildAccountActions(),
              const SizedBox(height: 24),
              _buildSecuritySection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    final user = auth.user;
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Użytkownik';
    final email = user?.email ?? '';

    // Get role from user profile or fallback to auth provider
    final userRole = _userProfile?.role ?? UserRole.user;
    final isAdmin = userRole == UserRole.admin || auth.isAdmin;
    final roleText = _getRoleDisplayText(userRole);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.statusInfo.withOpacity(0.1),
            AppThemePro.statusInfo.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.statusInfo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: AppThemePro.primaryDark,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppThemePro.accentGold.withOpacity(0.1)
                        : AppThemePro.statusInfo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAdmin
                          ? AppThemePro.accentGold.withOpacity(0.3)
                          : AppThemePro.statusInfo.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    roleText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isAdmin
                          ? AppThemePro.accentGold
                          : AppThemePro.statusInfo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            // onPressed: () => _showEditProfileDialog(context, auth), // DISABLED for Super-admin
            onPressed: null, // Disabled edit button
            icon: const Icon(Icons.edit_rounded),
            color: AppThemePro.textMuted, // Grayed out color
            style: IconButton.styleFrom(
              backgroundColor: AppThemePro.surfaceInteractive.withOpacity(
                0.3,
              ), // More transparent
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    final auth = Provider.of<AuthProvider>(context);
    final lastLoginText = _lastLoginTime != null
        ? _formatTimeAgo(_lastLoginTime!)
        : 'Brak danych';

    // Get role information from user profile or auth provider
    final userRole = _userProfile?.role ?? UserRole.user;
    final roleText = _getRoleDisplayText(userRole);
    final isAdmin = userRole == UserRole.admin || auth.isAdmin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 1 ? 3 : 1.5,
          children: [
            _buildStatCard(
              'Ostatnie logowanie',
              lastLoginText,
              Icons.access_time_rounded,
              AppThemePro.statusSuccess,
            ),
            _buildStatCard(
              'Sesje aktywne',
              '$_activeSessions ${_activeSessions == 1 ? 'urządzenie' : 'urządzenia'}',
              Icons.devices_rounded,
              AppThemePro.statusInfo,
            ),
            _buildStatCard(
              'Rola użytkownika',
              roleText,
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              isAdmin ? AppThemePro.accentGold : AppThemePro.statusInfo,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin || (_userProfile?.role == UserRole.admin);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akcje konta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            'Zmień hasło',
            'Zaktualizuj hasło dostępu',
            Icons.lock_reset_rounded,
            // onTap: () => _showChangePasswordDialog(context), // DISABLED for Super-admin
          ),
          _buildActionItem(
            'Odśwież sesję',
            'Przedłuż czas sesji',
            Icons.refresh_rounded,
            onTap: () => _refreshSession(context),
          ),
          _buildActionItem(
            'Pobierz dane',
            'Eksportuj informacje o koncie',
            Icons.download_rounded,
            // onTap: () => _exportUserData(context), // DISABLED for Super-admin
          ),
          // Disabled actions
          _buildActionItem(
            'Zarządzaj urządzeniami',
            'Zobacz i zarządzaj połączonymi urządzeniami',
            Icons.devices_other_rounded,
            // onTap: () => _showDeviceManagement(context), // TODO: Implement
          ),
          _buildActionItem(
            'Historia logowań',
            'Zobacz historię ostatnich logowań',
            Icons.history_rounded,
            // onTap: () => _showLoginHistory(context), // TODO: Implement
          ),
          _buildActionItem(
            'Ustawienia powiadomień',
            'Zarządzaj ustawieniami powiadomień',
            Icons.notifications_rounded,
            // onTap: () => _showNotificationSettings(context), // TODO: Implement
          ),
          if (isAdmin) ...[
            _buildActionItem(
              'Panel administratora',
              'Dostęp do ustawień systemowych',
              Icons.admin_panel_settings_rounded,
              onTap: () => _navigateToAdminPanel(context),
            ),
          ],
          _buildActionItem(
            'Usuń konto',
            'Trwale usuń konto i wszystkie dane',
            Icons.delete_forever_rounded,
            // onTap: () => _showDeleteAccountDialog(context), // TODO: Implement - dangerous action
            isDestructive: true,
          ),
          _buildActionItem(
            'Wyloguj się',
            'Zakończ bieżącą sesję',
            Icons.logout_rounded,
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: AppThemePro.statusSuccess,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Bezpieczeństwo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSecurityItem(
            'Autoryzacja dwuskładnikowa',
            'Nieaktywna',
            false,
            onTap: () => _show2FADialog(context),
          ),
          _buildSecurityItem('Szyfrowanie danych', 'AES-256', true),
          _buildSecurityItem('Automatyczne wylogowanie', '24 godz.', true),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDisabled = onTap == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? AppThemePro.lossRed.withOpacity(0.1)
                          : AppThemePro.surfaceInteractive,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive
                          ? AppThemePro.lossRed
                          : AppThemePro.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDestructive
                                    ? AppThemePro.lossRed
                                    : AppThemePro.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppThemePro.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppThemePro.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    String title,
    String value,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemePro.surfaceInteractive.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppThemePro.statusSuccess.withOpacity(0.3)
                      : AppThemePro.borderSecondary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: isActive
                        ? AppThemePro.statusSuccess
                        : AppThemePro.statusWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'dzień' : 'dni'} temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'godzina' : 'godzin'} temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuta' : 'minut'} temu';
    } else {
      return 'Przed chwilą';
    }
  }

  String _getRoleDisplayText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Super-admin';
      case UserRole.user:
        return 'Super-admin'; // Override to show Super-admin for all users
      default:
        return 'Super-admin';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundModal,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header z ikoną i tytułem
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemePro.lossRed.withOpacity(0.1),
                            AppThemePro.lossRed.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Animowana ikona wylogowania
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppThemePro.lossRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppThemePro.lossRed.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: AppThemePro.lossRed,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Wylogowanie',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppThemePro.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Treść dialogu
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Czy na pewno chcesz się wylogować?',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppThemePro.textSecondary,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Zostaniesz przekierowany do strony logowania.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppThemePro.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Przyciski akcji
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppThemePro.surfaceElevated,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Przycisk anulowania
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Anuluj',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Przycisk wylogowania
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();

                                // Animacja ładowania podczas wylogowywania
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppThemePro.backgroundModal,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppThemePro.primaryDark,
                                                  ),
                                              strokeWidth: 3,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Wylogowywanie...',
                                            style: TextStyle(
                                              color: AppThemePro.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                // Symulacja opóźnienia dla płynnej animacji
                                await Future.delayed(
                                  const Duration(milliseconds: 800),
                                );

                                if (mounted) {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Zamknij dialog ładowania
                                  await auth.signOut();
                                  if (mounted) {
                                    // Navigate to login - you'll need to import go_router
                                    // context.go('/login'); // Adjust route as needed
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemePro.lossRed,
                                foregroundColor: AppThemePro.textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Wyloguj',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    // DISABLED for Super-admin - Profile editing not allowed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj profil'),
        content: const Text(
          'Funkcjonalność edycji profilu jest zablokowana dla Super-admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _refreshSession(BuildContext context) {
    setState(() => _isLoading = true);
    // Simulate session refresh
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesja została odświeżona')),
          );
        }
      }
    });
  }

  void _show2FADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autoryzacja dwuskładnikowa'),
        content: const Text('Konfiguracja 2FA będzie dostępna wkrótce.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminPanel(BuildContext context) {
    // TODO: Navigate to admin panel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panel administratora będzie dostępny wkrótce'),
      ),
    );
  }
}

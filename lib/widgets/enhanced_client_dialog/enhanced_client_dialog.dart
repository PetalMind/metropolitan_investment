import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'client_overview_tab.dart';
import 'client_contact_tab.dart';
import 'client_investments_tab.dart';
import 'client_actions_tab.dart';

/// 🎨 SPEKTAKULARNY ENHANCED CLIENT DIALOG
///
/// Funkcje:
/// - 5 sekcji w TAB navigation z animacjami
/// - Responsywny design z adaptive sizing
/// - Keyboard shortcuts i advanced UX
/// - Premium styling z particle effects
/// - Auto-save i validation per section
/// - Hero animations między sekcjami
class EnhancedClientDialog extends StatefulWidget {
  final Client? client;
  final Function(Client) onSave;
  final VoidCallback? onCancel;
  final Map<String, dynamic>?
  additionalData; // Dane inwestycji, statystyki itp.
  final Future<Map<String, dynamic>?> Function()?
  onDataRefresh; // 🚀 NOWY: Callback do odświeżania danych

  const EnhancedClientDialog({
    super.key,
    this.client,
    required this.onSave,
    this.onCancel,
    this.additionalData,
    this.onDataRefresh,
  });

  static Future<void> show({
    required BuildContext context,
    Client? client,
    required Function(Client) onSave,
    VoidCallback? onCancel,
    Map<String, dynamic>? additionalData,
    Future<Map<String, dynamic>?> Function()?
    onDataRefresh, // 🚀 NOWY: Callback do odświeżania danych
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) => EnhancedClientDialog(
        client: client,
        onSave: onSave,
        onCancel: onCancel,
        additionalData: additionalData,
        onDataRefresh: onDataRefresh,
      ),
    );
  }

  @override
  State<EnhancedClientDialog> createState() => _EnhancedClientDialogState();
}

class _EnhancedClientDialogState extends State<EnhancedClientDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  late AnimationController _contentController;

  // Form state - shared across tabs
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ClientFormData _formData;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  Map<String, dynamic>?
  _currentAdditionalData; // 🚀 NOWY: Aktualny stan additionalData

  // Tab definitions
  static const List<TabDefinition> _tabs = [
    TabDefinition(
      label: 'Przegląd',
      icon: Icons.person_rounded,
      tooltip: 'Podstawowe informacje o kliencie',
    ),
    TabDefinition(
      label: 'Kontakt',
      icon: Icons.contact_phone_rounded,
      tooltip: 'Dane kontaktowe i adresowe',
    ),
    TabDefinition(
      label: 'Inwestycje',
      icon: Icons.trending_up_rounded,
      tooltip: 'Portfel inwestycyjny klienta',
    ),
    // Analytics tab removed - analytics moved to Investments/Overview
    TabDefinition(
      label: 'Akcje',
      icon: Icons.settings_rounded,
      tooltip: 'Email, notatki, historia',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormData();
    _setupKeyboardShortcuts();
    _currentAdditionalData =
        widget.additionalData; // 🚀 NOWY: Zainicjalizuj dane
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      animationDuration: const Duration(milliseconds: 300),
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Start animations
    _headerController.forward();
    _contentController.forward();

    // Listen to tab changes for analytics
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  void _initializeFormData() {
    _formData = ClientFormData.fromClient(widget.client);
  }

  void _setupKeyboardShortcuts() {
    // TAB switching shortcuts will be implemented in build()
  }

  void _onTabChanged(int newIndex) {
    HapticFeedback.lightImpact();

    // Validate current form state before switching
    if (_formKey.currentState?.validate() == false) {
      // Show warning about validation errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Popraw błędy walidacji w bieżącej sekcji'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onFormDataChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Popraw błędy walidacji przed zapisaniem'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState!.save();
      final client = _formData.toClient();

      // Show saving snackbar before closing dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💾 Zapisywanie klienta...'),
          backgroundColor: AppThemePro.statusInfo,
          duration: Duration(seconds: 1),
        ),
      );

      // Zapisz klienta - callback sam zamknie dialog
      await widget.onSave(client);

      // Reset states po udanym zapisie (jeśli dialog jeszcze istnieje)
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd podczas zapisywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCancel() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Niezapisane zmiany'),
          content: Text('Czy na pewno chcesz zamknąć bez zapisywania zmian?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close alert
                Navigator.of(context).pop(); // Close dialog
                widget.onCancel?.call();
              },
              child: Text('Zamknij bez zapisywania'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;
    final dialogWidth = isTablet
        ? 900.0
        : MediaQuery.of(context).size.width * 0.95;
    final dialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): VoidCallbackIntent(_onCancel),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyS):
            VoidCallbackIntent(_saveClient),
        // TAB navigation shortcuts
        LogicalKeySet(
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.digit1,
        ): VoidCallbackIntent(
          () => _tabController.animateTo(0),
        ),
        LogicalKeySet(
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.digit2,
        ): VoidCallbackIntent(
          () => _tabController.animateTo(1),
        ),
        LogicalKeySet(
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.digit3,
        ): VoidCallbackIntent(
          () => _tabController.animateTo(2),
        ),
        LogicalKeySet(
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.digit4,
        ): VoidCallbackIntent(
          () => _tabController.animateTo(3),
        ),
        // Ctrl+5 removed - fewer tabs now
      },
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 50 : 20,
            vertical: isTablet ? 40 : 30,
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: AppThemePro.premiumCardDecoration.copyWith(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.overlayDark.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(child: _buildTabContent()),
                  _buildActionBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _headerController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppThemePro.primaryDark,
              AppThemePro.primaryDark.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(
            bottom: BorderSide(
              color: AppThemePro.accentGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar/Icon with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemePro.accentGold,
                          AppThemePro.accentGold.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemePro.accentGold.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.client == null
                          ? Icons.person_add_rounded
                          : Icons.edit_rounded,
                      color: AppThemePro.backgroundPrimary,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),

            // Title section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.client == null
                            ? 'Nowy Klient'
                            : 'Edytuj Klienta',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppThemePro.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      if (_hasUnsavedChanges) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'NIEZAPISANE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.client == null
                        ? 'Dodaj nowego klienta z kompletnym profilem'
                        : 'Zarządzaj profilem klienta ${widget.client!.name}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Close button
            Container(
              decoration: BoxDecoration(
                color: AppThemePro.surfaceInteractive.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppThemePro.borderSecondary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: _onCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppThemePro.textSecondary,
                  size: 24,
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: _tabController,
        isScrollable: false,
        indicatorColor: AppThemePro.accentGold,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: AppThemePro.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;

          return Tab(
            height: 56,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 18),
                      const SizedBox(width: 6),
                      Text(tab.label),
                      if (index < 2) // Show numbers for first two tabs
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemePro.textTertiary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return FadeTransition(
      opacity: _contentController,
      child: TabBarView(
        controller: _tabController,
        children: [
          ClientOverviewTab(
            formData: _formData,
            onDataChanged: _onFormDataChanged,
            additionalData: _currentAdditionalData,
          ),
          ClientContactTab(
            formData: _formData,
            onDataChanged: _onFormDataChanged,
          ),
          ClientInvestmentsTab(
            client: widget.client,
            formData: _formData,
            additionalData: _currentAdditionalData,
          ),
          ClientActionsTab(
            client: widget.client,
            formData: _formData,
            onDataChanged: _onFormDataChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Row(
        children: [
        
          // Action buttons
          Row(
            children: [
              // Cancel button
              TextButton(
                onPressed: _isLoading ? null : _onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: AppThemePro.surfaceInteractive,
                  foregroundColor: AppThemePro.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppThemePro.borderSecondary,
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Anuluj',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),

              // Save button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveClient,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppThemePro.backgroundPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.backgroundPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper classes
class TabDefinition {
  final String label;
  final IconData icon;
  final String tooltip;

  const TabDefinition({
    required this.label,
    required this.icon,
    required this.tooltip,
  });
}

class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}

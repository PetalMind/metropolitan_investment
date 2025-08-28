import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// 🚀 Nowoczesny, responsywny i animowany header dla Enhanced Clients Screen
///
/// Funkcje:
/// - Responsywny design (tablet/mobile)
/// - Płynne animacje i przejścia
/// - Tryb selekcji z licznikiem
/// - Przyciski: Refresh, Add Client, Email, Clear Cache
/// - Gradient background z efektami świetlnymi
/// - RBAC support z tooltipami
/// - Accessibility support
/// - Mikrointerakcje i hover effects
///
/// Przykład użycia:
/// ```dart
/// EnhancedClientsHeader(
///   isTablet: MediaQuery.of(context).size.width > 768,
///   canEdit: Provider.of<AuthProvider>(context).isAdmin,
///   totalCount: clients.length,
///   isLoading: isLoadingData,
///   isRefreshing: isRefreshingData,
///   isSelectionMode: currentSelectionMode,
///   selectedClientIds: selectedIds,
///   displayedClients: filteredClients,
///   onRefresh: () => refreshData(),
///   onAddClient: () => showClientForm(),
///   onToggleEmail: () => toggleEmailMode(),
///   onClearCache: () => clearCache(),
///   onSelectAll: () => selectAllClients(),
///   onClearSelection: () => clearSelection(),
/// )
/// ```
class EnhancedClientsHeader extends StatefulWidget {
  // === REQUIRED PROPS ===
  final bool isTablet;
  final bool canEdit;
  final int totalCount;
  final bool isLoading;
  final bool isRefreshing;

  // === STATE PROPS ===
  final bool isSelectionMode;
  final bool isEmailMode;
  final bool isExportMode; // 🚀 NOWY: Tryb eksportu
  final bool isEditMode; // 🚀 NOWY: Tryb edycji
  final Set<String> selectedClientIds;
  final List<Client> displayedClients;

  // === CALLBACKS ===
  final VoidCallback onRefresh;
  final VoidCallback onAddClient;
  final VoidCallback onToggleEmail;
  final VoidCallback? onToggleExport; // 🚀 NOWY: Toggle eksportu
  final VoidCallback? onToggleEdit; // 🚀 NOWY: Toggle edycji
  final VoidCallback onEmailClients; // 🚀 NOWY: Wysyłanie email do wybranych klientów
  final VoidCallback? onExportClients; // 🚀 NOWY: Eksport klientów
  final VoidCallback? onEditClients; // 🚀 NOWY: Edycja klientów
  final VoidCallback onClearCache;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const EnhancedClientsHeader({
    super.key,
    required this.isTablet,
    required this.canEdit,
    required this.totalCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSelectionMode,
    required this.isEmailMode,
    required this.isExportMode,
    required this.isEditMode,
    required this.selectedClientIds,
    required this.displayedClients,
    required this.onRefresh,
    required this.onAddClient,
    required this.onToggleEmail,
    this.onToggleExport,
    this.onToggleEdit,
    required this.onEmailClients,
    this.onExportClients,
    this.onEditClients,
    required this.onClearCache,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  State<EnhancedClientsHeader> createState() => _EnhancedClientsHeaderState();
}

class _EnhancedClientsHeaderState extends State<EnhancedClientsHeader>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _buttonsAnimationController;
  late AnimationController _glowAnimationController;

  late Animation<double> _titleSlideAnimation;
  late Animation<double> _buttonsScaleAnimation;
  late Animation<double> _glowPulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _buttonsAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _titleSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _buttonsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _glowPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _titleAnimationController.forward();
    _buttonsAnimationController.forward();
    _glowAnimationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EnhancedClientsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart button animation when selection mode changes
    if (oldWidget.isSelectionMode != widget.isSelectionMode ||
        oldWidget.isEmailMode != widget.isEmailMode ||
        oldWidget.isExportMode != widget.isExportMode ||
        oldWidget.isEditMode != widget.isEditMode) {
      _buttonsAnimationController.reset();
      _buttonsAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _titleAnimationController,
        _buttonsAnimationController,
        _glowAnimationController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: _buildHeaderDecoration(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 24 : 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  _buildAnimatedIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTitleSection()),
                  const SizedBox(width: 16),
                  if (widget.isSelectionMode) ...[
                    _buildSelectionControls(),
                  ] else ...[
                    _buildActionButtons(),
                  ],
                  if (!widget.isTablet) ...[
                    const SizedBox(width: 8),
                    _buildFilterButton(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppThemePro.backgroundSecondary.withOpacity(0.95),
          AppThemePro.backgroundPrimary.withOpacity(0.98),
          AppThemePro.backgroundPrimary,
        ],
      ),
      border: Border(
        bottom: BorderSide(
          color: AppThemePro.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppThemePro.accentGold.withOpacity(
            0.1 * _glowPulseAnimation.value,
          ),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return Transform.scale(
      scale: _buttonsScaleAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppThemePro.accentGold.withOpacity(0.3),
              AppThemePro.accentGold.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.accentGold.withOpacity(
                0.3 * _glowPulseAnimation.value,
              ),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          widget.isSelectionMode ? Icons.group_rounded : Icons.people_rounded,
          color: AppThemePro.accentGold,
          size: widget.isTablet ? 32 : 28,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(_titleSlideAnimation),
      child: FadeTransition(
        opacity: _titleSlideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedTitle(),
            const SizedBox(height: 4),
            _buildSubtitle(),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    final title = widget.isSelectionMode
        ? 'Wybór Klientów'
        : 'Zarządzanie Klientami';

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppThemePro.accentGold,
          AppThemePro.accentGold.withOpacity(0.8),
          AppThemePro.textPrimary,
        ],
      ).createShader(bounds),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          title,
          key: ValueKey(title),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.isTablet ? 24 : 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    final subtitle =
        widget.isSelectionMode && widget.selectedClientIds.isNotEmpty
        ? 'Wybrano ${widget.selectedClientIds.length} z ${widget.displayedClients.length} klientów'
        : '${widget.totalCount} klientów';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        subtitle,
        key: ValueKey(subtitle),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isLoading
            ? AppThemePro.statusWarning.withOpacity(0.1)
            : AppThemePro.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isLoading
              ? AppThemePro.statusWarning.withOpacity(0.3)
              : AppThemePro.statusSuccess.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppThemePro.statusWarning),
              ),
            )
          else
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: AppThemePro.statusSuccess,
            ),
          const SizedBox(width: 4),
          Text(
            widget.isLoading ? 'Ładowanie...' : 'Gotowe',
            style: TextStyle(
              fontSize: 10,
              color: widget.isLoading
                  ? AppThemePro.statusWarning
                  : AppThemePro.statusSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return ScaleTransition(
      scale: _buttonsScaleAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectionButton(),
          if (widget.selectedClientIds.isNotEmpty) ...[
            const SizedBox(width: 8),
            if (widget.isEmailMode) _buildEmailButton(),
            if (widget.isExportMode) _buildExportButton(),
            if (widget.isEditMode) _buildEditButton(),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSelectionButton() {
    final isAllSelected =
        widget.selectedClientIds.length == widget.displayedClients.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextButton.icon(
        onPressed: isAllSelected ? widget.onClearSelection : widget.onSelectAll,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isAllSelected ? Icons.clear_all_rounded : Icons.select_all_rounded,
            key: ValueKey(isAllSelected),
            size: 16,
          ),
        ),
        label: Text(
          isAllSelected ? 'Odznacz' : 'Zaznacz wszystkich',
          style: TextStyle(fontSize: widget.isTablet ? 14 : 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppThemePro.accentGold,
          backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 16 : 12,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppThemePro.accentGold.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ScaleTransition(
      scale: _buttonsScaleAnimation,
      child: widget.isTablet
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 8),
                if (widget.canEdit) ...[
                  _buildAddClientButton(),
                  const SizedBox(width: 8),
                ],
                _buildEmailToggleButton(),
                const SizedBox(width: 8),
                if (widget.onToggleExport != null) ...[
                  _buildExportToggleButton(),
                  const SizedBox(width: 8),
                ],
                if (widget.onToggleEdit != null) ...[
                  _buildEditToggleButton(),
                  const SizedBox(width: 8),
                ],
                _buildMoreOptionsButton(),
              ],
            )
          : PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppThemePro.textSecondary,
              ),
              tooltip: 'Więcej opcji',
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    if (!widget.isLoading) widget.onRefresh();
                    break;
                  case 'add_client':
                    if (widget.canEdit) widget.onAddClient();
                    break;
                  case 'email':
                    if (widget.canEdit) widget.onToggleEmail();
                    break;
                  case 'export':
                    if (widget.canEdit && widget.onToggleExport != null) widget.onToggleExport!();
                    break;
                  case 'edit':
                    if (widget.canEdit && widget.onToggleEdit != null) widget.onToggleEdit!();
                    break;
                  case 'clear_cache':
                    widget.onClearCache();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  enabled: !widget.isLoading,
                  child: Row(
                    children: [
                      widget.isRefreshing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppThemePro.accentGold,
                                ),
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text('Odśwież'),
                    ],
                  ),
                ),
                if (widget.canEdit) ...[
                  PopupMenuItem(
                    value: 'add_client',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text('Dodaj Klienta'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(
                          widget.isEmailMode
                              ? Icons.close_rounded
                              : Icons.email_rounded,
                          size: 16,
                          color: widget.isEmailMode
                              ? AppThemePro.statusError
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEmailMode ? 'Zakończ email' : 'Wyślij email',
                        ),
                      ],
                    ),
                  ),
                  if (widget.onToggleExport != null)
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(
                            widget.isExportMode
                                ? Icons.close_rounded
                                : Icons.download_rounded,
                            size: 16,
                            color: widget.isExportMode
                                ? AppThemePro.statusError
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj dane',
                          ),
                        ],
                      ),
                    ),
                  if (widget.onToggleEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            widget.isEditMode
                                ? Icons.close_rounded
                                : Icons.edit_rounded,
                            size: 16,
                            color: widget.isEditMode
                                ? AppThemePro.statusError
                                : AppThemePro.statusWarning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isEditMode ? 'Zakończ edycję' : 'Tryb edycji',
                          ),
                        ],
                      ),
                    ),
                ],
                PopupMenuItem(
                  value: 'clear_cache',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text('Wyczyść cache'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Odśwież dane',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.isRefreshing
              ? AppThemePro.accentGold.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: IconButton(
          onPressed: widget.isLoading ? null : widget.onRefresh,
          icon: widget.isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppThemePro.accentGold),
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  color: widget.isLoading
                      ? AppThemePro.textTertiary
                      : AppThemePro.textSecondary,
                ),
          tooltip: 'Odśwież dane',
          style: IconButton.styleFrom(
            backgroundColor: widget.isRefreshing
                ? AppThemePro.accentGold.withOpacity(0.1)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddClientButton() {
    return Tooltip(
      message: 'Dodaj nowego klienta',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.onAddClient,
          icon: Icon(Icons.person_add_rounded, color: AppThemePro.accentGold),
          style: IconButton.styleFrom(
            backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppThemePro.accentGold.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEmailMode ? 'Zakończ wysyłanie' : 'Wyślij emaile')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit ? widget.onEmailClients : null,
          icon: Icon(
            Icons.email_rounded,
            color: widget.canEdit
                ? AppThemePro.accentGold
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppThemePro.accentGold.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptionsButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: AppThemePro.textSecondary),
      tooltip: 'Więcej opcji',
      onSelected: (value) {
        switch (value) {
          case 'email':
            if (widget.canEdit) widget.onToggleEmail();
            break;
          case 'export':
            if (widget.canEdit && widget.onToggleExport != null) widget.onToggleExport!();
            break;
          case 'edit':
            if (widget.canEdit && widget.onToggleEdit != null) widget.onToggleEdit!();
            break;
          case 'clear_cache':
            widget.onClearCache();
            break;
        }
      },
      itemBuilder: (context) => [
        if (widget.canEdit) ...[
          PopupMenuItem(
            value: 'email',
            child: Row(
              children: [
                Icon(
                  widget.isEmailMode
                      ? Icons.close_rounded
                      : Icons.email_rounded,
                  size: 16,
                  color: widget.isEmailMode ? AppThemePro.statusError : null,
                ),
                const SizedBox(width: 8),
                Text(widget.isEmailMode ? 'Zakończ email' : 'Wyślij email'),
              ],
            ),
          ),
          if (widget.onToggleExport != null)
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(
                    widget.isExportMode
                        ? Icons.close_rounded
                        : Icons.download_rounded,
                    size: 16,
                    color: widget.isExportMode ? AppThemePro.statusError : null,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj dane'),
                ],
              ),
            ),
          if (widget.onToggleEdit != null)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    widget.isEditMode
                        ? Icons.close_rounded
                        : Icons.edit_rounded,
                    size: 16,
                    color: widget.isEditMode ? AppThemePro.statusError : AppThemePro.statusWarning,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.isEditMode ? 'Zakończ edycję' : 'Tryb edycji'),
                ],
              ),
            ),
        ],
        PopupMenuItem(
          value: 'clear_cache',
          child: Row(
            children: [
              Icon(Icons.clear_all_rounded, size: 16),
              const SizedBox(width: 8),
              Text('Wyczyść cache'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailToggleButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEmailMode ? 'Zakończ wysyłanie' : 'Tryb email')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit ? widget.onToggleEmail : null,
          icon: Icon(
            widget.isEmailMode ? Icons.close_rounded : Icons.email_rounded,
            color: widget.canEdit
                ? (widget.isEmailMode ? AppThemePro.statusError : AppThemePro.accentGold)
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.isEmailMode 
                ? AppThemePro.statusError.withOpacity(0.1)
                : AppThemePro.accentGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.isEmailMode 
                    ? AppThemePro.statusError.withOpacity(0.3)
                    : AppThemePro.accentGold.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportToggleButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isExportMode ? 'Zakończ eksport' : 'Tryb eksportu')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit && widget.onToggleExport != null 
              ? widget.onToggleExport! : null,
          icon: Icon(
            widget.isExportMode ? Icons.close_rounded : Icons.download_rounded,
            color: widget.canEdit
                ? (widget.isExportMode ? AppThemePro.statusError : AppThemePro.statusInfo)
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.isExportMode 
                ? AppThemePro.statusError.withOpacity(0.1)
                : AppThemePro.statusInfo.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.isExportMode 
                    ? AppThemePro.statusError.withOpacity(0.3)
                    : AppThemePro.statusInfo.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditToggleButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEditMode ? 'Zakończ edycję' : 'Tryb edycji')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit && widget.onToggleEdit != null 
              ? widget.onToggleEdit! : null,
          icon: Icon(
            widget.isEditMode ? Icons.close_rounded : Icons.edit_rounded,
            color: widget.canEdit
                ? (widget.isEditMode ? AppThemePro.statusError : AppThemePro.statusWarning)
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.isEditMode 
                ? AppThemePro.statusError.withOpacity(0.1)
                : AppThemePro.statusWarning.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.isEditMode 
                    ? AppThemePro.statusError.withOpacity(0.3)
                    : AppThemePro.statusWarning.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? 'Eksportuj wybranych klientów'
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit && widget.onExportClients != null 
              ? widget.onExportClients! : null,
          icon: Icon(
            Icons.download_rounded,
            color: widget.canEdit
                ? AppThemePro.statusInfo
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppThemePro.statusInfo.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppThemePro.statusInfo.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEditMode ? 'Zakończ edycję' : 'Edytuj wybranych')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          onPressed: widget.canEdit && widget.onEditClients != null 
              ? widget.onEditClients! : null,
          icon: Icon(
            Icons.edit_rounded,
            color: widget.canEdit
                ? AppThemePro.statusWarning
                : AppThemePro.textTertiary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: widget.canEdit
                ? AppThemePro.statusWarning.withOpacity(0.1)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.canEdit
                    ? AppThemePro.statusWarning.withOpacity(0.3)
                    : AppThemePro.textTertiary.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: IconButton(
        onPressed: () {
          // Placeholder for filter functionality
        },
        icon: Icon(Icons.filter_list_rounded, color: AppThemePro.textSecondary),
        tooltip: 'Filtry',
      ),
    );
  }
}

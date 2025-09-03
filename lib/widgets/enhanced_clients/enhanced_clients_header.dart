import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// 🚀 Nowoczesny, responsywny i animowany header dla Enhanced Clients Screen
///
/// Funkcje:
/// - Responsywny design (tablet/mobile)
/// - Płynne animacje i przejścia
/// - Tryb selekcji z licznikiem
/// - Przyciski: Add Client, Export, Email
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
///   isSelectionMode: currentSelectionMode,
///   selectedClientIds: selectedIds,
///   displayedClients: filteredClients,
///   onAddClient: () => showClientForm(),
///   onToggleEmail: () => toggleEmailMode(),
///   onToggleExport: () => toggleExportMode(),
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

  // === STATE PROPS ===
  final bool isSelectionMode;
  final bool isEmailMode;
  final bool isExportMode;
  final Set<String> selectedClientIds;
  final List<Client> displayedClients;

  // === CALLBACKS ===
  final VoidCallback onAddClient;
  final VoidCallback onToggleEmail;
  final VoidCallback onToggleExport;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  
  // 🎯 NOWE: Callback dla legendy
  final VoidCallback? onToggleLegend;

  const EnhancedClientsHeader({
    super.key,
    required this.isTablet,
    required this.canEdit,
    required this.totalCount,
    required this.isLoading,
    required this.isSelectionMode,
    required this.isEmailMode,
    required this.isExportMode,
    required this.selectedClientIds,
    required this.displayedClients,
    required this.onAddClient,
    required this.onToggleEmail,
    required this.onToggleExport,
    required this.onSelectAll,
    required this.onClearSelection,
    this.onToggleLegend, // 🎯 OPCJONALNE
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
        oldWidget.isExportMode != widget.isExportMode) {
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
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 24 : 16,
            vertical: 16,
          ),
          decoration: _buildHeaderDecoration(),
          child: SafeArea(
            child: Row(
              children: [
                _buildAnimatedIcon(),
                const SizedBox(width: 12),
                Expanded(child: _buildTitleSection()),
                if (widget.isSelectionMode) ...[
                  _buildSelectionControls(),
                ] else ...[
                  _buildActionButtons(),
                ],
              ],
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
          AppThemePro.primaryDark,
          AppThemePro.primaryMedium.withValues(alpha: 0.9),
          AppThemePro.backgroundPrimary,
        ],
      ),
      border: Border(
        bottom: BorderSide(
          color: AppThemePro.accentGold.withValues(
            alpha: 0.3 * _glowPulseAnimation.value,
          ),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppThemePro.accentGold.withValues(
            alpha: 0.1 * _glowPulseAnimation.value,
          ),
          blurRadius: 12,
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
          borderRadius: BorderRadius.circular(12),
          gradient: RadialGradient(
            colors: [
              AppThemePro.accentGold.withValues(
                alpha: 0.3 * _glowPulseAnimation.value,
              ),
              AppThemePro.accentGold.withValues(
                alpha: 0.1 * _glowPulseAnimation.value,
              ),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.accentGold.withValues(
                alpha: 0.4 * _glowPulseAnimation.value,
              ),
              blurRadius: 12,
              spreadRadius: 1,
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
            if (widget.totalCount > 0) ...[
              const SizedBox(height: 4),
              _buildSubtitle(),
              const SizedBox(height: 4),
              _buildStatusBadge(),
            ],
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
          AppThemePro.accentGoldMuted,
          AppThemePro.textPrimary,
        ],
      ).createShader(bounds),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          title,
          key: ValueKey(title),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
          if (widget.isLoading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppThemePro.statusWarning),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Ładowanie...',
              style: TextStyle(
                color: AppThemePro.statusWarning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: AppThemePro.statusSuccess,
            ),
            const SizedBox(width: 4),
            Text(
              'Aktualny',
              style: TextStyle(
                color: AppThemePro.statusSuccess,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          if (widget.displayedClients.isNotEmpty) ...[
            _buildSelectionButton(),
            const SizedBox(width: 8),
          ],
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
            isAllSelected ? Icons.deselect : Icons.select_all,
            key: ValueKey(isAllSelected),
            size: 20,
            color: AppThemePro.accentGold,
          ),
        ),
        label: Text(
          isAllSelected ? 'Usuń zaznaczenie' : 'Zaznacz wszystko',
          style: TextStyle(
            fontSize: widget.isTablet ? 12 : 10,
            color: AppThemePro.accentGold,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppThemePro.accentGold,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 12 : 8,
            vertical: 4,
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
                if (widget.canEdit) ...[
                  _buildAddClientButton(),
                  const SizedBox(width: 8),
                ],
                _buildExportButton(),
                const SizedBox(width: 8),
                _buildEmailButton(),
        
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
                  case 'add_client':
                    if (widget.canEdit) widget.onAddClient();
                    break;
                  case 'export':
                    if (widget.canEdit) widget.onToggleExport();
                    break;
                  case 'email':
                    if (widget.canEdit) widget.onToggleEmail();
                    break;
                  case 'legend': // 🎯 NOWA OPCJA
                    widget.onToggleLegend?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (widget.canEdit)
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
                  value: 'export',
                  enabled: widget.canEdit,
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
                        widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'email',
                  enabled: widget.canEdit,
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
              ],
            ),
    );
  }

  Widget _buildAddClientButton() {
    return Tooltip(
      message: 'Dodaj nowego klienta',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppThemePro.accentGold.withOpacity(0.1),
              AppThemePro.accentGold.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: AppThemePro.accentGold.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.accentGold.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: widget.onAddClient,
          icon: Icon(
            Icons.person_add_rounded,
            color: AppThemePro.accentGold,
            size: 20,
          ),
          label: Text(
            'Dodaj klienta',
            style: TextStyle(
              color: AppThemePro.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({String? text, bool showText = false}) {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isExportMode ? 'Zakończ eksport' : 'Eksportuj wybrane dane')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: widget.isExportMode
              ? LinearGradient(
                  colors: [
                    AppThemePro.statusError.withOpacity(0.15),
                    AppThemePro.statusError.withOpacity(0.05),
                  ],
                )
              : (widget.canEdit
                    ? LinearGradient(
                        colors: [
                          AppThemePro.accentGold.withOpacity(0.1),
                          AppThemePro.accentGold.withOpacity(0.05),
                        ],
                      )
                    : null),
          border: widget.isExportMode
              ? Border.all(
                  color: AppThemePro.statusError.withOpacity(0.4),
                  width: 1.5,
                )
              : (widget.canEdit
                    ? Border.all(
                        color: AppThemePro.accentGold.withOpacity(0.3),
                        width: 1,
                      )
                    : Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      )),
          boxShadow: widget.isExportMode
              ? [
                  BoxShadow(
                    color: AppThemePro.statusError.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : (widget.canEdit
                    ? [
                        BoxShadow(
                          color: AppThemePro.accentGold.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null),
        ),
        child: Stack(
          children: [
            TextButton.icon(
              onPressed: !widget.canEdit ? null : widget.onToggleExport,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.isExportMode
                      ? Icons.close_rounded
                      : Icons.download_rounded,
                  key: ValueKey(widget.isExportMode),
                  color: widget.isExportMode
                      ? AppThemePro.statusError
                      : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                  size: 20,
                ),
              ),
              label: showText && text != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isExportMode ? 'Zakończ' : 'Eksportuj wybrane dane',
                          style: TextStyle(
                            color: widget.isExportMode
                                ? AppThemePro.statusError
                                : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: TextStyle(
                            color: widget.isExportMode
                                ? AppThemePro.statusError
                                : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      widget.isExportMode ? 'Zakończ' : 'Eksportuj wybrane dane',
                      style: TextStyle(
                        color: widget.isExportMode
                            ? AppThemePro.statusError
                            : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (widget.isExportMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppThemePro.statusError,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.statusError.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    const kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

    return Tooltip(
      message: widget.canEdit
          ? (widget.isEmailMode
                ? 'Zakończ wysyłanie email'
                : 'Wyślij email do wybranych')
          : kRbacNoPermissionTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: widget.isEmailMode
              ? LinearGradient(
                  colors: [
                    AppThemePro.statusError.withOpacity(0.15),
                    AppThemePro.statusError.withOpacity(0.05),
                  ],
                )
              : (widget.canEdit
                    ? LinearGradient(
                        colors: [
                          AppThemePro.accentGold.withOpacity(0.1),
                          AppThemePro.accentGold.withOpacity(0.05),
                        ],
                      )
                    : null),
          border: widget.isEmailMode
              ? Border.all(
                  color: AppThemePro.statusError.withOpacity(0.4),
                  width: 1.5,
                )
              : (widget.canEdit
                    ? Border.all(
                        color: AppThemePro.accentGold.withOpacity(0.3),
                        width: 1,
                      )
                    : Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      )),
          boxShadow: widget.isEmailMode
              ? [
                  BoxShadow(
                    color: AppThemePro.statusError.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : (widget.canEdit
                    ? [
                        BoxShadow(
                          color: AppThemePro.accentGold.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null),
        ),
        child: Stack(
          children: [
            TextButton.icon(
              onPressed: !widget.canEdit ? null : widget.onToggleEmail,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.isEmailMode
                      ? Icons.close_rounded
                      : Icons.email_rounded,
                  key: ValueKey(widget.isEmailMode),
                  color: widget.isEmailMode
                      ? AppThemePro.statusError
                      : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                  size: 20,
                ),
              ),
              label: Text(
                widget.isEmailMode ? 'Zakończ' : 'Wyślij maila',
                style: TextStyle(
                  color: widget.isEmailMode
                      ? AppThemePro.statusError
                      : (widget.canEdit ? AppThemePro.accentGold : Colors.grey),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (widget.isEmailMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppThemePro.statusError,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.statusError.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 🎯 NOWY: Przycisk legendy z objaśnieniami
  Widget _buildLegendButton() {
    return Tooltip(
      message: 'Wyświetl objaśnienia oznaczeń i kolorów',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppThemePro.statusInfo.withOpacity(0.1),
              AppThemePro.statusInfo.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: AppThemePro.statusInfo.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.statusInfo.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: widget.onToggleLegend,
          icon: Icon(
            Icons.help_outline,
            color: AppThemePro.statusInfo,
            size: 20,
          ),
          label: Text(
            'Legenda',
            style: TextStyle(
              color: AppThemePro.statusInfo,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

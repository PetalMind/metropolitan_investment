import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../services/investor_analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'custom_text_field.dart';
import 'animated_button.dart';

class InvestorDetailsModal extends StatefulWidget {
  final InvestorSummary investor;
  final Function()? onEditInvestor;
  final Function()? onViewInvestments;
  final Function(InvestorSummary)? onUpdateInvestor;
  final InvestorAnalyticsService? analyticsService;

  const InvestorDetailsModal({
    super.key,
    required this.investor,
    this.onEditInvestor,
    this.onViewInvestments,
    this.onUpdateInvestor,
    this.analyticsService,
  });

  @override
  State<InvestorDetailsModal> createState() => _InvestorDetailsModalState();
}

class _InvestorDetailsModalState extends State<InvestorDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Controllers for editing
  late TextEditingController _notesController;
  late VotingStatus _selectedVotingStatus;
  late ClientType _selectedClientType;
  late bool _isActive;
  late String _selectedColorCode;

  bool _isEditMode = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize editing data
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedClientType = widget.investor.client.type;
    _isActive = widget.investor.client.isActive;
    _selectedColorCode = widget.investor.client.colorCode;

    _tabController = TabController(length: 3, vsync: this);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Listen for changes
    _notesController.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    final hasChanges =
        _notesController.text != widget.investor.client.notes ||
        _selectedVotingStatus != widget.investor.client.votingStatus ||
        _selectedClientType != widget.investor.client.type ||
        _isActive != widget.investor.client.isActive ||
        _selectedColorCode != widget.investor.client.colorCode;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _closeModal() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 768;
    final isLargeTablet = screenWidth > 1024;
    final isSmallMobile = screenWidth < 400;

    // Responsywne marginesy i constraints
    final horizontalMargin = isLargeTablet
        ? 60.0
        : isTablet
            ? 40.0
            : isSmallMobile
                ? 8.0
                : 16.0;

    final verticalMargin = isTablet
        ? 40.0
        : isSmallMobile
            ? 8.0
            : 16.0;

    final maxWidth = isLargeTablet
        ? 1200.0
        : isTablet
            ? 900.0
            : screenWidth - 32;

    final maxHeight = isTablet ? screenHeight * 0.9 : screenHeight * 0.95;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeController]),
      builder: (context, child) {
        return Material(
          color: AppTheme.scrimColor.withOpacity(0.8 * _fadeAnimation.value),
          child: GestureDetector(
            onTap: _closeModal,
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping inside
                  // Dodanie obsługi swipe down do zamknięcia na mobilnych
                  onPanUpdate: (details) {
                    if (!isTablet && details.delta.dy > 5) {
                      // Swipe down detected on mobile
                      _closeModal();
                    }
                  },
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                        vertical: verticalMargin,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundModal,
                        borderRadius: BorderRadius.circular(
                          isSmallMobile ? 12 : 16,
                        ),
                        border: Border.all(
                          color: AppTheme.borderPrimary,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: isTablet ? 20 : 15,
                            offset: Offset(0, isTablet ? 10 : 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: isTablet ? 40 : 30,
                            offset: Offset(0, isTablet ? 20 : 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isSmallMobile ? 12 : 16,
                        ),
                        child: _buildResponsiveLayout(
                          isTablet: isTablet,
                          isLargeTablet: isLargeTablet,
                          isSmallMobile: isSmallMobile,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout({
    required bool isTablet,
    required bool isLargeTablet,
    required bool isSmallMobile,
  }) {
    // Na dużych tabletach używamy 3-kolumnowego layoutu
    if (isLargeTablet) {
      return _buildLargeTabletLayout();
    }
    // Na normalnych tabletach używamy 2-kolumnowego layoutu
    else if (isTablet) {
      return _buildTabletLayout();
    }
    // Na mobilnych urządzeniach używamy tabów lub uproszczonego widoku
    else {
      return isSmallMobile ? _buildCompactMobileLayout() : _buildMobileLayout();
    }
  }

  Widget _buildLargeTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lewa kolumna - informacje podstawowe (35%)
                  Expanded(
                    flex: 35,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: _buildBasicInfo(),
                    ),
                  ),
                  // Środkowa kolumna - statystyki (40%)
                  Expanded(
                    flex: 40,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: _buildScrollableInvestmentStats(),
                    ),
                  ),
                  // Prawa kolumna - akcje (25%)
                  Expanded(
                    flex: 25,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: _buildActionCenter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildBasicInfo(),
                ),
              ),

              // Divider
              Container(width: 1, color: AppTheme.borderSecondary),

              // Środkowa kolumna - statystyki inwestycji (40%)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildInvestmentStats(),
                ),
              ),

              // Divider
              Container(width: 1, color: AppTheme.borderSecondary),

              // Prawa kolumna - akcje (30%)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildActionCenter(),
                ),
              ),
            ],
          ),
        ),
        _buildFooterActions(),
      ],
    );
  }

  Widget _buildCompactMobileLayout() {
    return Column(
      children: [
        _buildCompactHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactStats(),
                const SizedBox(height: 12),
                _buildCompactInfo(),
                const SizedBox(height: 12),
                _buildVotingStatusEditor(),
                const SizedBox(height: 12),
                _buildCompactActions(),
                const SizedBox(height: 16), // Extra space for footer
              ],
            ),
          ),
        ),
        _buildCompactFooter(),
      ],
    );
  }

  Widget _buildCompactHeader() {
    final clientColor = _getClientColor(widget.investor.client);
    final isLightColor = _isLightColor(clientColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundPrimary, AppTheme.backgroundSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: clientColor.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Compact avatar z lepszą kolorystyką
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [clientColor, clientColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: clientColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: clientColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(widget.investor.client.name),
                style: TextStyle(
                  color: isLightColor ? AppTheme.textPrimary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Compact info z lepszą prezentacją
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investor.client.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 12,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatCurrency(
                        widget.investor.totalValue,
                      ),
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button z lepszym designem
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSecondary, width: 1),
            ),
            child: IconButton(
              onPressed: _closeModal,
              icon: const Icon(
                Icons.close,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statystyki',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(height: 12),

        // Compact stats grid
        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                'Kapitał pozostały',
                CurrencyFormatter.formatCurrency(
                  widget.investor.totalRemainingCapital,
                ),
                Icons.monetization_on,
                AppTheme.loansColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactStatCard(
                'Inwestycje',
                '${widget.investor.investmentCount}',
                Icons.account_balance_wallet,
                AppTheme.infoColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kontakt',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(height: 12),

        if (widget.investor.client.email.isNotEmpty)
          _buildCompactInfoRow(Icons.email, widget.investor.client.email),
        if (widget.investor.client.phone.isNotEmpty)
          _buildCompactInfoRow(Icons.phone, widget.investor.client.phone),

        const SizedBox(height: 12),
        _buildCompactInfoRow(
          _getVotingStatusIcon(widget.investor.client.votingStatus),
          'Głosowanie: ${_getVotingStatusText(widget.investor.client.votingStatus)}',
        ),
      ],
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akcje',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryGold,
          ),
        ),
        const SizedBox(height: 12),

        // Compact action buttons
        Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                'Edytuj',
                Icons.edit,
                AppTheme.secondaryGold,
                () {
                  setState(() {
                    _isEditMode = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactActionButton(
                'Inwestycje',
                Icons.visibility,
                AppTheme.infoColor,
                widget.onViewInvestments,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(top: BorderSide(color: AppTheme.borderSecondary)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: OutlinedButton(
          onPressed: _closeModal,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Zamknij', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lewa kolumna - informacje podstawowe (40%)
                  Expanded(
                    flex: 40,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: _buildBasicInfo(),
                    ),
                  ),

                  // Divider
                  Container(width: 1, color: AppTheme.borderSecondary),

                  // Prawa kolumna - szczegóły i akcje (60%)
                  Expanded(
                    flex: 60,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildScrollableInvestmentStats(),
                          const SizedBox(height: 16),
                          _buildActionCenter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppTheme.secondaryGold,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.secondaryGold,
                  tabs: const [
                    Tab(text: 'Info', icon: Icon(Icons.person, size: 16)),
                    Tab(text: 'Stats', icon: Icon(Icons.analytics, size: 16)),
                    Tab(text: 'Akcje', icon: Icon(Icons.settings, size: 16)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildBasicInfo(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildScrollableInvestmentStats(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildActionCenter(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }
        _buildFooterActions(),
      ],
    );
  }

  Widget _buildPortraitMobileLayout() {
    return Column(
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            border: Border(bottom: BorderSide(color: AppTheme.borderSecondary)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondaryGold,
            labelColor: AppTheme.secondaryGold,
            unselectedLabelColor: AppTheme.textSecondary,
            dividerColor: AppTheme.borderSecondary,
            tabs: const [
              Tab(text: 'Podstawowe'),
              Tab(text: 'Inwestycje'),
              Tab(text: 'Akcje'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildBasicInfo(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildInvestmentStats(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildActionCenter(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeMobileLayout() {
    return Row(
      children: [
        // Lewa strona - podstawowe info i stats
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBasicInfo(),
                const SizedBox(height: 16),
                _buildInvestmentStats(),
              ],
            ),
          ),
        ),

        // Divider
        Container(width: 1, color: AppTheme.borderSecondary),

        // Prawa strona - akcje
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildActionCenter(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isSmallMobile = MediaQuery.of(context).size.width < 400;
    final avatarSize = isSmallMobile ? 50.0 : 60.0;
    final titleFontSize = isSmallMobile ? 18.0 : 22.0;
    final subtitleFontSize = isSmallMobile ? 12.0 : 14.0;
    final valueFont = isSmallMobile ? 14.0 : 16.0;

    // Użyjemy ciemnego tła z akcentem kolorystycznym klienta
    final clientColor = _getClientColor(widget.investor.client);
    final isLightColor = _isLightColor(clientColor);

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundPrimary, AppTheme.backgroundSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallMobile ? 12 : 20),
          topRight: Radius.circular(isSmallMobile ? 12 : 20),
        ),
        border: Border(
          bottom: BorderSide(color: clientColor.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Avatar inwestora z kolorystycznym akcentem
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [clientColor, clientColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: clientColor.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: clientColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(widget.investor.client.name),
                style: TextStyle(
                  color: isLightColor ? AppTheme.textPrimary : Colors.white,
                  fontSize: avatarSize * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),

          // Nazwa i podstawowe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nazwa inwestora
                Text(
                  widget.investor.client.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Nazwa firmy (jeśli istnieje)
                if (widget.investor.client.companyName?.isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.investor.client.companyName!,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Wartość inwestycji z lepszą kolorystyką
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 10 : 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successColor.withOpacity(0.15),
                        AppTheme.successColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: isSmallMobile ? 14 : 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        CurrencyFormatter.formatCurrency(
                          widget.investor.totalValue,
                        ),
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: valueFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status głosowania
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _getVotingStatusIcon(widget.investor.client.votingStatus),
                      size: isSmallMobile ? 12 : 14,
                      color: _getVotingStatusColor(
                        widget.investor.client.votingStatus,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getVotingStatusText(widget.investor.client.votingStatus),
                      style: TextStyle(
                        color: _getVotingStatusColor(
                          widget.investor.client.votingStatus,
                        ),
                        fontSize: isSmallMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Przycisk zamknięcia z lepszym designem
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSecondary, width: 1),
            ),
            child: IconButton(
              onPressed: _closeModal,
              icon: Icon(
                Icons.close,
                color: AppTheme.textSecondary,
                size: isSmallMobile ? 18 : 22,
              ),
              style: IconButton.styleFrom(
                minimumSize: Size(
                  isSmallMobile ? 36 : 44,
                  isSmallMobile ? 36 : 44,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection('Informacje kontaktowe', Icons.contact_page, [
          _buildInfoRow('Email', widget.investor.client.email, Icons.email),
          _buildInfoRow('Telefon', widget.investor.client.phone, Icons.phone),
          if (widget.investor.client.address.isNotEmpty)
            _buildInfoRow(
              'Adres',
              widget.investor.client.address,
              Icons.location_on,
            ),
          const SizedBox(height: 16),
          _buildVotingStatusEditor(),
        ]),
        const SizedBox(height: 24),

        _buildInfoSection('Status i preferencje', Icons.settings, [
          _buildInfoRow(
            'Status głosowania',
            _getVotingStatusText(widget.investor.client.votingStatus),
            _getVotingStatusIcon(widget.investor.client.votingStatus),
          ),
          _buildInfoRow(
            'Typ klienta',
            _getClientTypeText(widget.investor.client.type),
            Icons.person,
          ),
          if (widget.investor.client.notes.isNotEmpty)
            _buildInfoRow('Notatki', widget.investor.client.notes, Icons.note),
        ]),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    return Column(
      children: [
        Expanded(child: _buildInvestmentStats()),
        const SizedBox(height: 16),
        _buildActionCenter(),
      ],
    );
  }

  Widget _buildScrollableInvestmentStats() {
    return SingleChildScrollView(
      child: _buildInvestmentStats(),
    );
  }

  Widget _buildInvestmentStats() {
    final clientColor = _getClientColor(widget.investor.client);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ulepszona sekcja podsumowania z ładniejszym designem
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.backgroundSecondary,
                AppTheme.backgroundPrimary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: clientColor.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundTertiary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek sekcji z ikoną
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          clientColor.withOpacity(0.2),
                          clientColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: clientColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: clientColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Podsumowanie Inwestycji',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Szczegółowe zestawienie portfela inwestycyjnego',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Grid z statystykami
              _buildEnhancedStatsGrid(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ostrzeżenie o inwestycjach niewykonalnych z lepszym designem
        if (widget.investor.hasUnviableInvestments) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warningColor.withOpacity(0.1),
                  AppTheme.warningColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.warningColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inwestycje Niewykonalne',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inwestor posiada inwestycje oznaczone jako niewykonalne, które nie będą uwzględniane w obliczeniach głosowań.',
                        style: TextStyle(
                          color: AppTheme.warningColor.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildEnhancedStatsGrid() {
    final stats = [
      {
        'title': 'Łączna Wartość',
        'value': CurrencyFormatter.formatCurrency(widget.investor.totalValue),
        'icon': Icons.trending_up,
        'color': AppTheme.successColor,
        'description': 'Całkowita wartość portfela',
      },
      if (widget.investor.totalRemainingCapital > 0)
        {
          'title': 'Pozostały Kapitał',
          'value': CurrencyFormatter.formatCurrency(
            widget.investor.totalRemainingCapital,
          ),
          'icon': Icons.monetization_on,
          'color': AppTheme.primaryColor,
          'description': 'Dostępny kapitał',
        },
      if (widget.investor.totalSharesValue > 0)
        {
          'title': 'Wartość Udziałów',
          'value': CurrencyFormatter.formatCurrency(
            widget.investor.totalSharesValue,
          ),
          'icon': Icons.business,
          'color': AppTheme.cryptoColor,
          'description': 'Udziały w spółkach',
        },
      {
        'title': 'Liczba Inwestycji',
        'value': '${widget.investor.investmentCount}',
        'icon': Icons.account_balance_wallet,
        'color': AppTheme.bondsBackground,
        'description': 'Aktywne pozycje',
      },
      {
        'title': 'Kapitał Głosujący',
        'value': CurrencyFormatter.formatCurrency(
          widget.investor.viableRemainingCapital,
        ),
        'icon': Icons.how_to_vote,
        'color': AppTheme.loansColor,
        'description': 'Uprawnienia głosowe',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 2,
        childAspectRatio: MediaQuery.of(context).size.width > 768 ? 2.2 : 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (stat['color'] as Color).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.borderSecondary.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: stat['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                stat['title'] as String,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  color: stat['color'] as Color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                stat['description'] as String,
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCenter() {
    final clientColor = _getClientColor(widget.investor.client);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ulepszona sekcja akcji z lepszym designem
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.backgroundPrimary,
                AppTheme.backgroundSecondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: clientColor.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.borderSecondary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek z lepszym designem
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          clientColor.withOpacity(0.2),
                          clientColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: clientColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.tune, color: clientColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Edytuj Dane' : 'Centrum Akcji',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isEditMode
                              ? 'Modyfikuj informacje o inwestorze'
                              : 'Dostępne operacje i funkcje',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status zmian
                  if (_isEditMode && _hasChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warningColor.withOpacity(0.2),
                            AppTheme.warningColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.warningColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Niezapisane',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Zawartość w zależności od trybu
              if (_isEditMode) ...[
                _buildEnhancedEditingForm(),
              ] else ...[
                _buildEnhancedViewModeActions(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEditingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notatki z lepszym designem
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Notatki',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                onChanged: (_) => _onDataChanged(),
                decoration: InputDecoration(
                  hintText: 'Dodaj notatki o inwestorze...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderSecondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundPrimary,
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status głosowania z lepszym designem
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.how_to_vote,
                    color: _getVotingStatusColor(_selectedVotingStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Status Głosowania',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VotingStatus>(
                value: _selectedVotingStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderSecondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.borderSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundPrimary,
                ),
                dropdownColor: AppTheme.backgroundPrimary,
                items: VotingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _getVotingStatusIcon(status),
                          color: _getVotingStatusColor(status),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getVotingStatusText(status),
                          style: TextStyle(
                            color: _getVotingStatusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (VotingStatus? value) {
                  if (value != null) {
                    setState(() {
                      _selectedVotingStatus = value;
                    });
                    _onDataChanged();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Przyciski akcji z lepszym designem
        _buildEnhancedActionButtons(),
      ],
    );
  }

  Widget _buildEnhancedViewModeActions() {
    return Column(
      children: [
        // Grid z akcjami - poprawiony dla responsywności
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            final aspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.2;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildActionCard(
                  'Edytuj',
                  Icons.edit,
                  AppTheme.primaryColor,
                  () => _toggleEditMode(),
                ),
                _buildActionCard(
                  'Inwestycje',
                  Icons.account_balance_wallet,
                  AppTheme.successColor,
                  () => _showAllInvestments(),
                ),
                _buildActionCard(
                  'Analiza',
                  Icons.analytics,
                  AppTheme.cryptoColor,
                  () => _showVotingAnalytics(),
                ),
                _buildActionCard(
                  'Historia',
                  Icons.history,
                  AppTheme.loansColor,
                  () => _showHistory(),
                ),
                _buildActionCard(
                  'Raport',
                  Icons.assessment,
                  AppTheme.bondsBackground,
                  () => _generateReport(),
                ),
                _buildActionCard(
                  'Kontakt',
                  Icons.phone,
                  AppTheme.warningColor,
                  () => _contactInvestor(),
                ),
              ],
            );
          },
        ),

        // Dodatkowy przycisk "Zobacz wszystkie inwestycje" jako główny CTA
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAllInvestments,
            icon: const Icon(Icons.visibility, size: 20),
            label: const Text(
              'Zobacz wszystkie inwestycje',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppTheme.successColor.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cancelEditing,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Anuluj'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.backgroundSecondary,
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderSecondary),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _hasChanges ? _saveChanges : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Zapisz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges
                  ? AppTheme.successColor
                  : AppTheme.backgroundSecondary,
              foregroundColor: _hasChanges
                  ? Colors.white
                  : AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _hasChanges ? 2 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edytuj dane inwestora',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGold,
                ),
              ),
              const SizedBox(height: 16),

              // Notatki
              CustomTextField(
                controller: _notesController,
                label: 'Notatki',
                hint: 'Dodaj notatki o inwestorze...',
                prefixIcon: Icons.note,
                maxLines: 3,
                onChanged: (_) => _onDataChanged(),
              ),
              const SizedBox(height: 16),

              // Status głosowania
              DropdownButtonFormField<VotingStatus>(
                value: _selectedVotingStatus,
                decoration: const InputDecoration(
                  labelText: 'Status głosowania',
                  prefixIcon: Icon(Icons.how_to_vote),
                ),
                items: VotingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _getVotingStatusIcon(status),
                          color: _getVotingStatusColor(status),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_getVotingStatusText(status)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVotingStatus = value!;
                  });
                  _onDataChanged();
                },
              ),
              const SizedBox(height: 16),

              // Typ klienta
              DropdownButtonFormField<ClientType>(
                value: _selectedClientType,
                decoration: const InputDecoration(
                  labelText: 'Typ klienta',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: ClientType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getClientTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClientType = value!;
                  });
                  _onDataChanged();
                },
              ),
              const SizedBox(height: 16),

              // Kolor oznaczenia
              Text(
                'Kolor oznaczenia',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    [
                      '#FF5252',
                      '#4CAF50',
                      '#2196F3',
                      '#FF9800',
                      '#9C27B0',
                      '#607D8B',
                    ].map((color) {
                      final isSelected = _selectedColorCode == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorCode = color;
                          });
                          _onDataChanged();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse('0xFF${color.replaceAll('#', '')}'),
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.secondaryGold
                                  : AppTheme.borderPrimary,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Status aktywności
              SwitchListTile(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                  _onDataChanged();
                },
                title: const Text('Aktywny inwestor'),
                subtitle: const Text('Czy inwestor jest aktywny w systemie'),
                activeColor: AppTheme.successColor,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Przyciski akcji w trybie edycji
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditMode = false;
                    // Reset changes
                    _notesController.text = widget.investor.client.notes;
                    _selectedVotingStatus = widget.investor.client.votingStatus;
                    _selectedClientType = widget.investor.client.type;
                    _isActive = widget.investor.client.isActive;
                    _selectedColorCode = widget.investor.client.colorCode;
                    _hasChanges = false;
                  });
                },
                child: const Text('Anuluj'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedButton(
                onPressed: _hasChanges ? _saveChanges : null,
                backgroundColor: _hasChanges
                    ? AppTheme.successColor
                    : AppTheme.textSecondary,
                child: const Text('Zapisz zmiany'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewModeActions() {
    return Column(
      children: [
        // Przycisk edycji
        SizedBox(
          width: double.infinity,
          child: AnimatedButton(
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
            backgroundColor: AppTheme.secondaryGold,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edytuj dane inwestora'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Przycisk do przeglądania inwestycji
        SizedBox(
          width: double.infinity,
          child: AnimatedButton(
            onPressed: widget.onViewInvestments,
            backgroundColor: AppTheme.infoColor,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 8),
                Text('Zobacz wszystkie inwestycje'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Przycisk kopiowania danych kontaktowych
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _copyContactData,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Kopiuj dane kontaktowe'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    final isSmallMobile = MediaQuery.of(context).size.width < 400;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(top: BorderSide(color: AppTheme.borderSecondary)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isSmallMobile ? 12 : 16),
          bottomRight: Radius.circular(isSmallMobile ? 12 : 16),
        ),
      ),
      child: isLandscape && !isSmallMobile
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _closeModal,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Zamknij'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AnimatedButton(
                    onPressed: () {
                      _closeModal();
                      widget.onViewInvestments?.call();
                    },
                    child: const Text('Zobacz wszystkie inwestycje'),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AnimatedButton(
                    onPressed: () {
                      _closeModal();
                      widget.onViewInvestments?.call();
                    },
                    child: Text(
                      isSmallMobile
                          ? 'Zobacz inwestycje'
                          : 'Zobacz wszystkie inwestycje',
                    ),
                  ),
                ),
                if (!isSmallMobile) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _closeModal,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Zamknij'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildVotingStatusEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote, color: AppTheme.secondaryGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Status głosowania',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSecondary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VotingStatus>(
                value: _selectedVotingStatus,
                dropdownColor: AppTheme.backgroundPrimary,
                isExpanded: true,
                items: VotingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _getVotingStatusIcon(status),
                          color: _getVotingStatusColor(status),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getVotingStatusText(status),
                          style: TextStyle(
                            color: _getVotingStatusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (VotingStatus? value) {
                  if (value != null) {
                    setState(() {
                      _selectedVotingStatus = value;
                    });
                    _onDataChanged();
                  }
                },
              ),
            ),
          ),
          if (_hasChanges) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedVotingStatus =
                            widget.investor.client.votingStatus;
                        _hasChanges = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Anuluj'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Zapisz'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // === HELPER WIDGETS ===

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.secondaryGold),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === HELPER METHODS ===

  Color _getClientColor(Client client) {
    try {
      return Color(int.parse('0xFF${client.colorCode.replaceAll('#', '')}'));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }

  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return 'Za';
      case VotingStatus.no:
        return 'Przeciw';
      case VotingStatus.abstain:
        return 'Wstrzymuję się';
      case VotingStatus.undecided:
        return 'Niezdecydowany';
    }
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  String _getClientTypeText(ClientType type) {
    return type.displayName;
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.undecided:
        return AppTheme.warningColor;
      case VotingStatus.abstain:
        return AppTheme.textSecondary;
    }
  }

  // Sprawdza czy kolor jest jasny (pomocna przy wyborze koloru tekstu)
  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  // === HELPER METHODS ===

  Future<void> _saveChanges() async {
    try {
      if (widget.analyticsService == null) {
        throw Exception('Analytics service nie jest dostępny');
      }

      // Zapisz zmiany przez serwis analityki
      await widget.analyticsService!.updateInvestorDetails(
        widget.investor.client.id,
        votingStatus: _selectedVotingStatus,
        notes: _notesController.text.trim(),
        colorCode: _selectedColorCode,
        type: _selectedClientType,
        isActive: _isActive,
      );

      // Aktualizuj lokalny obiekt klienta
      final updatedClient = widget.investor.client.copyWith(
        votingStatus: _selectedVotingStatus,
        notes: _notesController.text.trim(),
        colorCode: _selectedColorCode,
        type: _selectedClientType,
        isActive: _isActive,
      );

      // Utwórz zaktualizowany obiekt inwestora
      final updatedInvestor = InvestorSummary(
        client: updatedClient,
        investments: widget.investor.investments,
        totalRemainingCapital: widget.investor.totalRemainingCapital,
        totalSharesValue: widget.investor.totalSharesValue,
        totalValue: widget.investor.totalValue,
        totalInvestmentAmount: widget.investor.totalInvestmentAmount,
        totalRealizedCapital: widget.investor.totalRealizedCapital,
        investmentCount: widget.investor.investmentCount,
      );

      // Wywołaj callback z zaktualizowanymi danymi
      widget.onUpdateInvestor?.call(updatedInvestor);

      setState(() {
        _isEditMode = false;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zmiany zostały zapisane'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisywania: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _copyContactData() {
    final contactData =
        '''
${widget.investor.client.name}
${widget.investor.client.companyName?.isNotEmpty == true ? widget.investor.client.companyName! : ''}
Email: ${widget.investor.client.email}
Telefon: ${widget.investor.client.phone}
${widget.investor.client.address.isNotEmpty ? 'Adres: ${widget.investor.client.address}' : ''}
    '''
            .trim();

    Clipboard.setData(ClipboardData(text: contactData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dane kontaktowe skopiowane do schowka'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  // === DODATKOWE METODY AKCJI ===

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        // Resetuj kontrolery przy wejściu w tryb edycji
        _notesController.text = widget.investor.client.notes;
        _selectedVotingStatus = widget.investor.client.votingStatus;
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditMode = false;
      _hasChanges = false;
      // Reset changes
      _notesController.text = widget.investor.client.notes;
      _selectedVotingStatus = widget.investor.client.votingStatus;
    });
  }

  Future<void> _exportData() async {
    try {
      // Tu byłaby logika eksportu danych inwestora
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funkcja eksportu będzie dostępna wkrótce'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd eksportu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _shareData() async {
    try {
      // Tu byłaby logika udostępniania danych
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funkcja udostępniania będzie dostępna wkrótce'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd udostępniania: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showHistory() async {
    try {
      // Tu byłaby logika wyświetlania historii
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historia inwestora będzie dostępna wkrótce'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd wyświetlania historii: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showVotingAnalytics() async {
    try {
      // Otwórz ekran analityki inwestorów z fokusem na analizę głosowania
      Navigator.of(context).pushNamed(
        '/investor-analytics',
        arguments: {
          'focusInvestor': widget.investor,
          'initialView': 'voting-analysis',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd otwierania analizy głosowania: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _generateReport() async {
    try {
      // Generuj raport dla tego inwestora
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => _buildReportGeneratorModal(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd generowania raportu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildReportGeneratorModal() {
    final clientColor = _getClientColor(widget.investor.client);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.backgroundModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: clientColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: clientColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assessment, color: clientColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generator Raportów',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Wybierz typ raportu dla ${widget.investor.client.name}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Opcje raportów
              _buildReportOption(
                'Szczegółowy Raport Inwestora',
                'Kompletne zestawienie wszystkich inwestycji i statystyk',
                Icons.person_outline,
                clientColor,
                () => _generateDetailedReport(),
              ),
              const SizedBox(height: 12),
              _buildReportOption(
                'Raport Głosowania',
                'Analiza uprawnień głosowych i dystrybuacji kapitału',
                Icons.how_to_vote,
                AppTheme.bondsBackground,
                () => _generateVotingReport(),
              ),
              const SizedBox(height: 12),
              _buildReportOption(
                'Raport Finansowy',
                'Zestawienie finansowe z podsumowaniem zysków i strat',
                Icons.account_balance,
                AppTheme.successColor,
                () => _generateFinancialReport(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateDetailedReport() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie szczegółowego raportu...'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _generateVotingReport() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie raportu głosowania...'),
        backgroundColor: AppTheme.bondsBackground,
      ),
    );
  }

  void _generateFinancialReport() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generowanie raportu finansowego...'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _showAllInvestments() async {
    try {
      // Wywołaj callback przekazany z rodzica lub pokaż modal z inwestycjami
      if (widget.onViewInvestments != null) {
        widget.onViewInvestments!();
      } else {
        // Pokaż własny modal z listą inwestycji
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => _buildInvestmentsListModal(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd wyświetlania inwestycji: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildInvestmentsListModal() {
    final clientColor = _getClientColor(widget.investor.client);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.backgroundModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderPrimary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.backgroundPrimary,
                    AppTheme.backgroundSecondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: clientColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          clientColor.withOpacity(0.2),
                          clientColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: clientColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: clientColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inwestycje - ${widget.investor.client.name}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.investor.investments.length} inwestycji • ${CurrencyFormatter.formatCurrency(widget.investor.totalValue)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.backgroundSecondary.withOpacity(
                        0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista inwestycji
            Expanded(
              child: widget.investor.investments.isEmpty
                  ? _buildEmptyInvestmentsList()
                  : _buildInvestmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInvestmentsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Brak inwestycji',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ten inwestor nie posiada jeszcze żadnych inwestycji.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.investor.investments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final investment = widget.investor.investments[index];
        return _buildInvestmentItem(investment, index);
      },
    );
  }

  Widget _buildInvestmentItem(dynamic investment, int index) {
    // Zakładamy że investment ma pola type, value, date, status
    final investmentType = investment.type?.toString() ?? 'Nieznany typ';
    final investmentValue = investment.value ?? 0.0;
    final isViable = investment.isViable ?? true;

    Color typeColor;
    IconData typeIcon;

    // Określ kolor i ikonę na podstawie typu inwestycji
    switch (investmentType.toLowerCase()) {
      case 'shares':
      case 'udziały':
        typeColor = AppTheme.cryptoColor;
        typeIcon = Icons.business;
        break;
      case 'bonds':
      case 'obligacje':
        typeColor = AppTheme.bondsBackground;
        typeIcon = Icons.account_balance;
        break;
      case 'loans':
      case 'pożyczki':
        typeColor = AppTheme.loansColor;
        typeIcon = Icons.monetization_on;
        break;
      default:
        typeColor = AppTheme.primaryColor;
        typeIcon = Icons.account_balance_wallet;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.backgroundPrimary,
            AppTheme.backgroundSecondary.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikona typu inwestycji
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withOpacity(0.2),
                  typeColor.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: typeColor.withOpacity(0.3), width: 1),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Szczegóły inwestycji
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Inwestycja #${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isViable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Niewykonalna',
                          style: TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Typ: $investmentType',
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wartość: ${CurrencyFormatter.formatCurrency(investmentValue)}',
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isViable ? typeColor : AppTheme.warningColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactInvestor() async {
    try {
      // Tu byłaby logika kontaktu z inwestorem
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funkcja kontaktu będzie dostępna wkrótce'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd inicjowania kontaktu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

// Static method to show the modal
class InvestorDetailsModalHelper {
  static Future<void> show({
    required BuildContext context,
    required InvestorSummary investor,
    Function()? onEditInvestor,
    Function()? onViewInvestments,
    Function(InvestorSummary)? onUpdateInvestor,
    InvestorAnalyticsService? analyticsService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => InvestorDetailsModal(
        investor: investor,
        onEditInvestor: onEditInvestor,
        onViewInvestments: onViewInvestments,
        onUpdateInvestor: onUpdateInvestor,
        analyticsService: analyticsService,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/client_notes_widget.dart';
import '../widgets/client_form.dart';
import '../widgets/optimized_voting_status_widget.dart';
import '../widgets/investor_analytics/tabs/voting_changes_tab.dart';

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

  // Services
  final UnifiedVotingStatusService _votingService =
      UnifiedVotingStatusService();

  bool _hasChanges = false;
  bool _isSaving = false; // 🔄 Stan ładowania podczas zapisywania
  bool _showDeduplicatedProducts =
      true; // 📦 Toggle deduplikacji produktów - DOMYŚLNIE TRUE

  // 🎯 NOWE: Kontrolery do edycji inwestycji
  final Map<String, TextEditingController> _investmentControllers = {};
  final Map<String, FocusNode> _investmentFocusNodes = {};
  bool _isEditingInvestments = false;
  Map<String, Investment> _modifiedInvestments = {};

  // 🚀 NOWE: Serwisy do obsługi edycji inwestycji
  final DataCacheService _cacheService = DataCacheService();
  final InvestmentService _investmentService = InvestmentService();

  // RBAC: sprawdzenie uprawnień
  bool get canEdit => context.read<AuthProvider>().isAdmin;

  @override
  void initState() {
    super.initState();

    // 🔍 DEBUG: Sprawdź dane otrzymane przez modal
    print('🔍 [InvestorModal] DEBUG - Dane klienta:');
    print('  - ID: ${widget.investor.client.id}');
    print('  - ExcelID: ${widget.investor.client.excelId}');
    print('  - Nazwa: "${widget.investor.client.name}"');
    print('  - Email: "${widget.investor.client.email}"');
    print('  - Telefon: "${widget.investor.client.phone}"');
    print('  - Firma: "${widget.investor.client.companyName ?? 'brak'}"');
    print('  - Liczba inwestycji: ${widget.investor.investments.length}');
    print('  - Całkowita wartość: ${widget.investor.totalValue}');

    // Initialize controllers
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedClientType = widget.investor.client.type;
    _isActive = widget.investor.client.isActive;
    _selectedColorCode = widget.investor.client.colorCode;

    // Initialize animations
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

    _tabController = TabController(length: 6, vsync: this);

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _tabController.dispose();
    _notesController.dispose();

    // 🚀 NOWE: Dispose kontrolerów inwestycji
    _investmentControllers.values.forEach((controller) => controller.dispose());
    _investmentFocusNodes.values.forEach((node) => node.dispose());

    super.dispose();
  }

  void _onDataChanged() {
    setState(() {
      _hasChanges =
          _notesController.text.trim() != widget.investor.client.notes ||
          _selectedVotingStatus != widget.investor.client.votingStatus ||
          _selectedClientType != widget.investor.client.type ||
          _isActive != widget.investor.client.isActive ||
          _selectedColorCode != widget.investor.client.colorCode;
    });
  }

  void _closeModal() async {
    if (_isSaving) {
      // Nie pozwalaj zamknąć modalu podczas zapisywania
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Poczekaj na zakończenie zapisywania...'),
          backgroundColor: AppTheme.warningColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
    final isSmallMobile = screenWidth < 400;

    // Responsywne wymiary
    final horizontalMargin = isTablet
        ? 40.0
        : isSmallMobile
        ? 8.0
        : 16.0;
    final verticalMargin = isTablet
        ? 40.0
        : isSmallMobile
        ? 8.0
        : 16.0;
    final maxWidth = isTablet ? 900.0 : screenWidth - 32;
    final maxHeight = screenHeight * 0.9;

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
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isSmallMobile ? 12 : 16,
                        ),
                        child: Stack(
                          children: [
                            _buildResponsiveLayout(
                              isTablet: isTablet,
                              isSmallMobile: isSmallMobile,
                            ),
                            // 🔄 Loading overlay podczas zapisywania
                            if (_isSaving) _buildLoadingOverlay(),
                          ],
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
    required bool isSmallMobile,
  }) {
    if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        // TabBar dla tabletu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.3),
            border: Border(bottom: BorderSide(color: AppTheme.borderSecondary)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.secondaryGold,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.secondaryGold,
            tabs: const [
              Tab(text: 'Informacje', icon: Icon(Icons.person, size: 18)),
              Tab(text: 'Kapitał', icon: Icon(Icons.analytics, size: 18)),
              Tab(text: 'Notatki', icon: Icon(Icons.note, size: 18)),
              Tab(
                text: 'Inwestycje',
                icon: Icon(Icons.account_balance_wallet, size: 18),
              ),
              Tab(text: 'Zmiany', icon: Icon(Icons.history, size: 18)),
              Tab(text: 'Kontakt', icon: Icon(Icons.contact_page, size: 18)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildBasicInfo(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildInvestmentStats(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildNotesTab(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildInvestmentsTab(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildChangesTab(),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContactTab(),
              ),
            ],
          ),
        ),
        _buildFooterActions(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.secondaryGold,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.secondaryGold,
                tabs: const [
                  Tab(text: 'Info', icon: Icon(Icons.person, size: 16)),
                  Tab(text: 'Stats', icon: Icon(Icons.analytics, size: 16)),
                  Tab(text: 'Notatki', icon: Icon(Icons.note, size: 16)),
                  Tab(
                    text: 'Inwestycje',
                    icon: Icon(Icons.account_balance_wallet, size: 16),
                  ),
                  Tab(text: 'Zmiany', icon: Icon(Icons.history, size: 16)),
                  Tab(
                    text: 'Kontakt',
                    icon: Icon(Icons.contact_page, size: 16),
                  ),
                ],
              ),
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildNotesTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildInvestmentsTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildChangesTab(),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildContactTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildFooterActions(),
      ],
    );
  }

  Widget _buildHeader() {
    final clientColor = _getClientColor(widget.investor.client);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundPrimary, AppTheme.backgroundSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: clientColor.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [clientColor, clientColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: clientColor.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.investor.client.name),
                style: TextStyle(
                  color: _isLightColor(clientColor)
                      ? Colors.black87
                      : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Informacje
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investor.client.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.investor.investments.length} inwestycji • ${CurrencyFormatter.formatCurrency(widget.investor.totalValue)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: _closeModal,
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundSecondary.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
            'Typ klienta',
            _getClientTypeText(widget.investor.client.type),
            Icons.person,
          ),
          if (widget.investor.client.notes.isNotEmpty)
            _buildInfoRow('Notatki', widget.investor.client.notes, Icons.note),
        ]),
        const SizedBox(height: 24),
        _buildActionCenter(),
      ],
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

          // Użyj OptimizedVotingStatusSelector zamiast DropdownButton
          OptimizedVotingStatusSelector(
            currentStatus: _selectedVotingStatus,
            onStatusChanged: (VotingStatus newStatus) {
              setState(() {
                _selectedVotingStatus = newStatus;
              });
              _onDataChanged();
            },
            isCompact: false,
            showLabels: true,
            enabled: canEdit, // RBAC: tylko administratorzy mogą edytować
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statystyki inwestycji',
          style: TextStyle(
            color: AppTheme.secondaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'kwota_inwestycji',
          CurrencyFormatter.formatCurrency(
            widget.investor.totalInvestmentAmount,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'kapital_pozostaly',
          CurrencyFormatter.formatCurrency(
            widget.investor.totalRemainingCapital,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'kapital_zabezpieczony_nieruchomoscia',
          CurrencyFormatter.formatCurrency(
            widget.investor.capitalSecuredByRealEstate,
          ),
        ),

        const SizedBox(height: 12),
        _buildStatCard(
          'kapital_do_restrukturyzacji',
          CurrencyFormatter.formatCurrency(
            widget.investor.capitalForRestructuring,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSecondary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getStatTitle(title),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatTitle(String key) {
    switch (key) {
      case 'kapital_pozostaly':
        return 'Kapitał pozostały';
      case 'kapital_zabezpieczony_nieruchomoscia':
        return 'Kapitał zabezpieczony nieruchomością';
      case 'kwota_inwestycji':
        return 'Kwota inwestycji';
      case 'kapital_do_restrukturyzacji':
        return 'Kapitał do restrukturyzacji';
      default:
        return key;
    }
  }

  Widget _buildActionCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akcje',
          style: TextStyle(
            color: AppTheme.secondaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Edytuj',
          Icons.edit,
          AppTheme.cryptoColor,
          canEdit ? () => _showEditClientForm() : null,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Wyślij wiadomość',
          Icons.email,
          AppTheme.infoColor,
          _contactInvestor,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback? onTap,
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
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.8),
        border: Border(top: BorderSide(color: AppTheme.borderSecondary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : _closeModal, // Wyłącz podczas zapisywania
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Zapisywanie...'),
                      ],
                    )
                  : const Text('Zamknij'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: (_hasChanges && !_isSaving && canEdit)
                  ? _saveChanges
                  : null, // Wyłącz podczas loading lub gdy brak uprawnień
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Zapisywanie zmian...'),
                      ],
                    )
                  : const Text('Zapisz zmiany'),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Buduje overlay loading podczas zapisywania
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundModal.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zapisywanie zmian...',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dane zostaną automatycznie odświeżone',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Nowe zakładki
  Widget _buildNotesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSecondary),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ClientNotesWidget(
                clientId: widget.investor.client.id,
                clientName: widget.investor.client.name,
                isReadOnly:
                    !canEdit, // RBAC: tylko administratorzy mogą edytować notatki
                currentUserId: 'current_user', // TODO: Pobierz z auth service
                currentUserName: 'Użytkownik',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle deduplikacji
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderSecondary),
          ),
          child: Row(
            children: [
              Icon(
                _showDeduplicatedProducts
                    ? Icons.layers_clear_rounded
                    : Icons.layers_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showDeduplicatedProducts
                          ? 'Widok zdeduplikowany'
                          : 'Widok wszystkich inwestycji',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _showDeduplicatedProducts
                          ? 'Produkty grupowane według nazwy, typu i firmy'
                          : 'Każda inwestycja wyświetlana osobno',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showDeduplicatedProducts,
                onChanged: (value) {
                  setState(() {
                    _showDeduplicatedProducts = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),

        // 🎯 NOWY: Przycisk edycji inwestycji
        if (!_isEditingInvestments)
          Tooltip(
            message: canEdit
                ? 'Edytuj inwestycje klienta'
                : kRbacNoPermissionTooltip,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: canEdit ? _startEditingInvestments : null,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edytuj inwestycje'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canEdit
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  foregroundColor: canEdit
                      ? Colors.white
                      : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

        // 🎯 NOWY: Przyciski akcji podczas edycji
        if (_isEditingInvestments && canEdit)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInvestmentChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _cancelEditingInvestments,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Anuluj'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: _showDeduplicatedProducts
              ? _buildDeduplicatedProductsList()
              : _buildInvestmentsList(),
        ),
      ],
    );
  }

  Widget _buildChangesTab() {
    return VotingChangesTab(investor: widget.investor);
  }

  Widget _buildInvestmentsList() {
    if (widget.investor.investments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestycji',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.investor.investments.length,
      itemBuilder: (context, index) {
        final investment = widget.investor.investments[index];
        return _buildInvestmentCard(investment, index);
      },
    );
  }

  Widget _buildInvestmentCard(Investment investment, int index) {
    // Pobierz ikonę według typu produktu
    IconData getProductIcon(Investment investment) {
      switch (investment.productType.name) {
        case 'bonds':
          return Icons.description;
        case 'shares':
          return Icons.trending_up;
        case 'loans':
          return Icons.account_balance;
        case 'apartments':
          return Icons.home;
        default:
          return Icons.account_balance_wallet;
      }
    }

    return GestureDetector(
      onTap: () => _navigateToProductDetails(investment),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: AppTheme.backgroundSecondary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      getProductIcon(investment),
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.productName.isNotEmpty
                              ? investment.productName
                              : investment.productType.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (investment.creditorCompany.isNotEmpty)
                          Text(
                            investment.creditorCompany,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          'ID: ${investment.id.substring(0, 8)}...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatCurrency(
                          investment.investmentAmount,
                        ),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        investment.currency,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 🎯 NOWY: Sekcja edycji w trybie edycji lub wyświetlania standardowego
              if (_isEditingInvestments)
                _buildInvestmentEditFields(investment, index)
              else
                _buildInvestmentDisplayFields(investment),

              // Dodatkowe informacje
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Podpisano: ${investment.signedDate.day.toString().padLeft(2, '0')}.${investment.signedDate.month.toString().padLeft(2, '0')}.${investment.signedDate.year}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wyświetla standardowe pola finansowe inwestycji
  Widget _buildInvestmentDisplayFields(Investment investment) {
    // Pobierz kolor statusu
    Color getStatusColor(InvestmentStatus status) {
      switch (status) {
        case InvestmentStatus.active:
          return AppTheme.successColor;
        case InvestmentStatus.inactive:
          return AppTheme.textSecondary;
        case InvestmentStatus.earlyRedemption:
          return AppTheme.warningColor;
        case InvestmentStatus.completed:
          return AppTheme.infoColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kapitał pozostały',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  CurrencyFormatter.formatCurrency(investment.remainingCapital),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(investment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    investment.status.displayName,
                    style: TextStyle(
                      color: getStatusColor(investment.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Wyświetla edytowalne pola finansowe inwestycji
  Widget _buildInvestmentEditFields(Investment investment, int index) {
    final prefix = 'inv_${index}_';

    // Inicjalizuj kontrolery dla tej inwestycji jeśli nie istnieją
    _investmentControllers.putIfAbsent(
      '${prefix}investmentAmount',
      () => TextEditingController(
        text: investment.investmentAmount.toStringAsFixed(2),
      ),
    );
    _investmentControllers.putIfAbsent(
      '${prefix}remainingCapital',
      () => TextEditingController(
        text: investment.remainingCapital.toStringAsFixed(2),
      ),
    );
    _investmentControllers.putIfAbsent(
      '${prefix}realizedCapital',
      () => TextEditingController(
        text: investment.realizedCapital.toStringAsFixed(2),
      ),
    );

    _investmentFocusNodes.putIfAbsent(
      '${prefix}investmentAmount',
      () => FocusNode(),
    );
    _investmentFocusNodes.putIfAbsent(
      '${prefix}remainingCapital',
      () => FocusNode(),
    );
    _investmentFocusNodes.putIfAbsent(
      '${prefix}realizedCapital',
      () => FocusNode(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCurrencyEditField(
                  label: 'Kwota inwestycji',
                  controller:
                      _investmentControllers['${prefix}investmentAmount']!,
                  focusNode:
                      _investmentFocusNodes['${prefix}investmentAmount']!,
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyEditField(
                  label: 'Kapitał pozostały',
                  controller:
                      _investmentControllers['${prefix}remainingCapital']!,
                  focusNode:
                      _investmentFocusNodes['${prefix}remainingCapital']!,
                  icon: Icons.savings,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCurrencyEditField(
            label: 'Kapitał zrealizowany',
            controller: _investmentControllers['${prefix}realizedCapital']!,
            focusNode: _investmentFocusNodes['${prefix}realizedCapital']!,
            icon: Icons.monetization_on,
            color: AppTheme.infoColor,
          ),
        ],
      ),
    );
  }

  /// Helper widget do edycji pól kwotowych
  Widget _buildCurrencyEditField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            color: canEdit ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: canEdit
                ? AppTheme.backgroundSecondary.withOpacity(0.7)
                : AppTheme.backgroundSecondary.withOpacity(0.3),
            helperText: canEdit ? null : kRbacNoPermissionTooltip,
            helperStyle: TextStyle(color: Colors.orange.shade700, fontSize: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            suffixText: 'PLN',
            suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          enabled: canEdit,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pole wymagane';
            }
            final parsedValue = double.tryParse(value);
            if (parsedValue == null || parsedValue < 0) {
              return 'Nieprawidłowa wartość';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    final client = widget.investor.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_page, color: AppTheme.secondaryGold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Kontakt z klientem',
              style: TextStyle(
                color: AppTheme.secondaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Email
        if (client.email.isNotEmpty) ...[
          _buildContactCard(
            title: 'Adres e-mail',
            value: client.email,
            icon: Icons.email,
            color: AppTheme.primaryColor,
            onTap: () => _sendEmail(client.email),
            actionText: 'Wyślij e-mail',
          ),
          const SizedBox(height: 16),
        ],

        // Telefon
        if (client.phone.isNotEmpty) ...[
          _buildContactCard(
            title: 'Numer telefonu',
            value: client.phone,
            icon: Icons.phone,
            color: AppTheme.successColor,
            onTap: () => _makePhoneCall(client.phone),
            actionText: 'Zadzwoń',
          ),
          const SizedBox(height: 16),
        ],

        // Adres
        if (client.address.isNotEmpty) ...[
          _buildContactCard(
            title: 'Adres',
            value: client.address,
            icon: Icons.location_on,
            color: AppTheme.infoColor,
            onTap: () => _openMap(client.address),
            actionText: 'Pokaż na mapie',
          ),
          const SizedBox(height: 16),
        ],

        // Informacje dodatkowe
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSecondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: AppTheme.secondaryGold, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Informacje dodatkowe',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (client.pesel?.isNotEmpty == true)
                _buildInfoDetail('PESEL', client.pesel!),
              if (client.companyName?.isNotEmpty == true)
                _buildInfoDetail('Nazwa firmy', client.companyName!),
              _buildInfoDetail('Typ klienta', _getClientTypeText(client.type)),
              _buildInfoDetail(
                'Status głosowania',
                widget.investor.client.votingStatus.displayName,
              ),
              _buildInfoDetail(
                'Status konta',
                client.isActive ? 'Aktywny' : 'Nieaktywny',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String actionText,
  }) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                actionText,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Akcje kontaktu
  Future<void> _sendEmail(String email) async {
    try {
      // Skopiuj email do schowka
      await Clipboard.setData(ClipboardData(text: email));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adres e-mail skopiowany: $email'),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    try {
      // Skopiuj numer telefonu do schowka
      await Clipboard.setData(ClipboardData(text: phone));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numer telefonu skopiowany: $phone'),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _openMap(String address) async {
    try {
      // Skopiuj adres do schowka
      await Clipboard.setData(ClipboardData(text: address));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adres skopiowany: $address'),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showEditClientForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.secondaryGold, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Edytuj klienta',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: ClientForm(
                    client: widget.investor.client,
                    onSave: (updatedClient) {
                      Navigator.of(context).pop();
                      // TODO: Zaktualizuj klienta przez serwis
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dane klienta zostały zaktualizowane'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
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
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return; // Zapobiegaj wielokrotnym kliknięciom

    setState(() {
      _isSaving = true; // 🔄 Rozpocznij loading
    });

    try {
      print(
        '🔄 [Modal] Rozpoczynam zapisywanie zmian dla klienta: ${widget.investor.client.id}',
      );
      print('🔄 [Modal] Nazwa klienta: ${widget.investor.client.name}');
      print('🔄 [Modal] Nowy status głosowania: $_selectedVotingStatus');

      if (widget.analyticsService == null) {
        throw Exception('Analytics service nie jest dostępny');
      }

      // Sprawdź czy ID nie jest puste lub nieprawidłowe
      if (widget.investor.client.id.isEmpty) {
        throw Exception('ID klienta jest puste');
      }

      // Debugowanie - sprawdź format ID
      print(
        '🔍 [Modal] Format ID: ${widget.investor.client.id} (długość: ${widget.investor.client.id.length})',
      );

      // Pobierz informacje o obecnie zalogowanym użytkowniku (potrzebne dla obu przypadków)
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      final userEmail = currentUser?.email ?? 'unknown@system.local';
      final userName =
          currentUser?.displayName ??
          authProvider.userProfile?.fullName ??
          userEmail.split('@').first;

      print('🔍 [InvestorModal] DEBUG - Dane użytkownika:');
      print('  - Email: $userEmail');
      print('  - Nazwa: $userName');
      print('  - UID: ${currentUser?.uid}');

      // Jeśli status głosowania się zmienił, zapisz także historię
      if (widget.investor.client.votingStatus != _selectedVotingStatus) {
        print(
          '🗳️ [InvestorModal] Status głosowania zmieniony: ${widget.investor.client.votingStatus.name} -> ${_selectedVotingStatus.name}',
        );

        // Pobierz informacje o obecnie zalogowanym użytkowniku
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.user;
        final userEmail = currentUser?.email ?? 'unknown@system.local';
        final userName =
            currentUser?.displayName ??
            authProvider.userProfile?.fullName ??
            userEmail.split('@').first;

        print('🔍 [InvestorModal] DEBUG - Dane użytkownika:');
        print('  - Email: $userEmail');
        print('  - Nazwa: $userName');
        print('  - UID: ${currentUser?.uid}');

        // Użyj nowego jednolitego serwisu
        final result = await _votingService.updateVotingStatus(
          widget.investor.client.id,
          _selectedVotingStatus,
          reason: 'Aktualizacja danych inwestora przez interfejs użytkownika',
          editedBy: userName,
          editedByEmail: userEmail,
          editedByName: userName,
          userId: currentUser?.uid,
          updatedVia: 'investor_details_modal',
          additionalChanges: {
            'notes': _notesController.text.trim(),
            'colorCode': _selectedColorCode,
            'type': _selectedClientType.name,
            'isActive': _isActive,
          },
        );

        if (!result.isSuccess) {
          throw Exception(
            'Błąd zapisywania statusu głosowania: ${result.error}',
          );
        }

        print(
          '✅ [InvestorModal] Historia głosowania zapisana przez UnifiedVotingStatusService',
        );
      } else {
        // Jeśli status się nie zmienił, zaktualizuj tylko inne pola
        // Pobierz dane użytkownika także dla tej ścieżki
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.user;
        final userEmail = currentUser?.email ?? 'unknown@system.local';
        final userName =
            currentUser?.displayName ??
            authProvider.userProfile?.fullName ??
            userEmail.split('@').first;

        await widget.analyticsService!.updateInvestorDetails(
          widget.investor.client.id,
          votingStatus: _selectedVotingStatus,
          notes: _notesController.text.trim(),
          colorCode: _selectedColorCode,
          type: _selectedClientType,
          isActive: _isActive,
          editedBy: userName,
          editedByEmail: userEmail,
          editedByName: userName,
          userId: currentUser?.uid,
          updatedVia: 'investor_details_modal',
        );

        print(
          '✅ [InvestorModal] Dane zaktualizowane przez InvestorAnalyticsService z danymi użytkownika: $userEmail',
        );
      }

      // Dodatkowo wyczyść cache dla pewności
      widget.analyticsService!.clearAnalyticsCache();
      print('🗑️ [Modal] Cache analityk wyczyszczony po zapisaniu zmian');

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
        capitalSecuredByRealEstate: widget.investor.capitalSecuredByRealEstate,
        capitalForRestructuring: widget.investor.capitalForRestructuring,
        investmentCount: widget.investor.investmentCount,
      );

      // Wywołaj callback z zaktualizowanymi danymi
      widget.onUpdateInvestor?.call(updatedInvestor);

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Zmiany zostały zapisane i dane zostaną automatycznie odświeżone',
          ),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      final errorMessage = e.toString().contains('does not exist')
          ? 'Klient nie istnieje w bazie danych. Być może został usunięty.'
          : 'Błąd zapisywania: $e';

      print('❌ Błąd zapisu: $errorMessage');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      // 🔄 Zakończ loading niezależnie od wyniku
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _contactInvestor() async {
    try {
      // Kopiuj email do schowka
      if (widget.investor.client.email.isNotEmpty) {
        await Clipboard.setData(
          ClipboardData(text: widget.investor.client.email),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email skopiowany do schowka'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Brak adresu email dla tego klienta'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd kopiowania email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Helper functions
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }

  Color _getClientColor(Client client) {
    try {
      return Color(int.parse('0xFF${client.colorCode.replaceAll('#', '')}'));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  String _getClientTypeText(ClientType type) {
    return type.displayName;
  }

  void _navigateToProductDetails(Investment investment) {
    Navigator.of(context).pop(); // Zamknij dialog

    print('🎯 [InvestorModal] Nawigacja do konkretnego produktu:');
    print('🎯 [InvestorModal] - Investment ID (logiczne): ${investment.id}');
    print('🎯 [InvestorModal] - Investment proposalId (hash): ${investment.proposalId}');
    print('🎯 [InvestorModal] - Product Name: ${investment.productName}');
    print('🎯 [InvestorModal] - Product Type: ${investment.productType.name}');

    // 🚀 NAPRAWIONE: Użyj TYLKO logicznego ID z Firebase (np. apartment_0089, bond_0001)
    final logicalInvestmentId = investment.id;

    // Użyj logicznego ID z Firebase dla nawigacji
    final uri = Uri(
      path: '/products',
      queryParameters: {
        'investmentId': logicalInvestmentId,
        // Dodatkowe parametry jako fallback dla debugowania
        'productName': investment.productName,
        'productType': investment.productType.name,
      },
    );

    print('🎯 [InvestorModal] Nawiguj do: ${uri.toString()}');
    context.go(uri.toString());
  }

  // Helper do konwersji ProductType do UnifiedProductType
  UnifiedProductType _convertToUnifiedProductType(ProductType productType) {
    switch (productType) {
      case ProductType.bonds:
        return UnifiedProductType.bonds;
      case ProductType.shares:
        return UnifiedProductType.shares;
      case ProductType.loans:
        return UnifiedProductType.loans;
      case ProductType.apartments:
        return UnifiedProductType.apartments;
    }
  }

  Widget _buildDeduplicatedProductsList() {
    final productGroups = <String, List<Investment>>{};

    // Grupuj inwestycje według produktu
    for (final investment in widget.investor.investments) {
      final productKey =
          '${investment.productName}_${investment.productType.name}_${investment.creditorCompany}';
      productGroups.putIfAbsent(productKey, () => []);
      productGroups[productKey]!.add(investment);
    }

    if (productGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brak produktów',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: productGroups.length,
      itemBuilder: (context, index) {
        final productKey = productGroups.keys.elementAt(index);
        final productInvestments = productGroups[productKey]!;
        final firstInvestment = productInvestments.first;

        // Oblicz zagregowane wartości
        final totalCapital = productInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.remainingCapital,
        );
        final totalOriginalAmount = productInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + inv.investmentAmount,
        );

        final hasUnviable = productInvestments.any(
          (inv) => widget.investor.client.unviableInvestments.contains(inv.id),
        );

        return _buildDeduplicatedProductCard(
          firstInvestment,
          productInvestments.length,
          totalCapital,
          totalOriginalAmount,
          hasUnviable,
        );
      },
    );
  }

  Widget _buildDeduplicatedProductCard(
    Investment sampleInvestment,
    int count,
    double totalRemaining,
    double totalOriginal,
    bool hasUnviable,
  ) {
    // Pobierz ikonę według typu produktu
    IconData getProductIcon(Investment investment) {
      switch (investment.productType.name) {
        case 'bonds':
          return Icons.description;
        case 'shares':
          return Icons.trending_up;
        case 'loans':
          return Icons.account_balance;
        case 'apartments':
          return Icons.home;
        default:
          return Icons.account_balance_wallet;
      }
    }

    return GestureDetector(
      onTap: () => _navigateToProductDetails(sampleInvestment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hasUnviable
              ? AppTheme.warningColor.withOpacity(0.1)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnviable
                ? AppTheme.warningColor.withOpacity(0.3)
                : AppTheme.borderSecondary,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _convertToUnifiedProductType(
                        sampleInvestment.productType,
                      ).color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      getProductIcon(sampleInvestment),
                      color: _convertToUnifiedProductType(
                        sampleInvestment.productType,
                      ).color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sampleInvestment.productName,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${count}x',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              sampleInvestment.creditorCompany,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _convertToUnifiedProductType(
                                  sampleInvestment.productType,
                                ).color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sampleInvestment.productType.displayName,
                                style: TextStyle(
                                  color: _convertToUnifiedProductType(
                                    sampleInvestment.productType,
                                  ).color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kapitał pozostały:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrency(totalRemaining),
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kapitał początkowy:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrency(totalOriginal),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (hasUnviable) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: AppTheme.warningColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CZĘŚĆ NIEWYKONALNA',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 NOWE METODY EDYCJI INWESTYCJI

  /// Rozpoczyna tryb edycji inwestycji
  void _startEditingInvestments() {
    setState(() {
      _isEditingInvestments = true;
    });
    _initializeInvestmentControllers();
  }

  /// Anuluje edycję inwestycji
  void _cancelEditingInvestments() {
    setState(() {
      _isEditingInvestments = false;
      _modifiedInvestments.clear();
    });
    _disposeInvestmentControllers();
  }

  /// Inicjalizuje kontrolery do edycji inwestycji
  void _initializeInvestmentControllers() {
    _investmentControllers.clear();
    _investmentFocusNodes.clear();

    for (int i = 0; i < widget.investor.investments.length; i++) {
      final investment = widget.investor.investments[i];
      final prefix = 'inv_${i}_';

      // Kontrolery dla różnych kwot
      _investmentControllers['${prefix}investmentAmount'] =
          TextEditingController(
            text: investment.investmentAmount.toStringAsFixed(2),
          );
      _investmentControllers['${prefix}remainingCapital'] =
          TextEditingController(
            text: investment.remainingCapital.toStringAsFixed(2),
          );
      _investmentControllers['${prefix}realizedCapital'] =
          TextEditingController(
            text: investment.realizedCapital.toStringAsFixed(2),
          );

      // Focus nodes
      _investmentFocusNodes['${prefix}investmentAmount'] = FocusNode();
      _investmentFocusNodes['${prefix}remainingCapital'] = FocusNode();
      _investmentFocusNodes['${prefix}realizedCapital'] = FocusNode();
    }
  }

  /// Usuwa kontrolery edycji inwestycji
  void _disposeInvestmentControllers() {
    _investmentControllers.values.forEach((controller) => controller.dispose());
    _investmentFocusNodes.values.forEach((node) => node.dispose());
    _investmentControllers.clear();
    _investmentFocusNodes.clear();
  }

  /// Zapisuje zmiany w inwestycjach
  Future<void> _saveInvestmentChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      _collectModifiedInvestments();

      if (_modifiedInvestments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak zmian do zapisania'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      // Zapisz zmiany poprzez InvestmentService
      for (final modifiedInvestment in _modifiedInvestments.values) {
        await _investmentService.updateInvestment(
          modifiedInvestment.id,
          modifiedInvestment,
        );
      }

      // Wyczyść cache lokalny
      _cacheService.clearCache('investor_data');

      // Odśwież dane w parent widget
      if (widget.onUpdateInvestor != null) {
        // Pobierz zaktualizowane dane inwestora
        final updatedInvestor = await _refreshInvestorData();
        widget.onUpdateInvestor!(updatedInvestor);
      }

      setState(() {
        _isEditingInvestments = false;
        _modifiedInvestments.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Zmiany w inwestycjach zostały zapisane'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      _disposeInvestmentControllers();
    } catch (e) {
      print('❌ [InvestorModal] Błąd podczas zapisywania inwestycji: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas zapisywania: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Zbiera zmodyfikowane inwestycje
  void _collectModifiedInvestments() {
    _modifiedInvestments.clear();

    for (int i = 0; i < widget.investor.investments.length; i++) {
      final investment = widget.investor.investments[i];
      final prefix = 'inv_${i}_';

      final newInvestmentAmount =
          double.tryParse(
            _investmentControllers['${prefix}investmentAmount']?.text ?? '0',
          ) ??
          investment.investmentAmount;

      final newRemainingCapital =
          double.tryParse(
            _investmentControllers['${prefix}remainingCapital']?.text ?? '0',
          ) ??
          investment.remainingCapital;

      final newRealizedCapital =
          double.tryParse(
            _investmentControllers['${prefix}realizedCapital']?.text ?? '0',
          ) ??
          investment.realizedCapital;

      // Sprawdź czy są zmiany
      if (newInvestmentAmount != investment.investmentAmount ||
          newRemainingCapital != investment.remainingCapital ||
          newRealizedCapital != investment.realizedCapital) {
        final modifiedInvestment = investment.copyWith(
          investmentAmount: newInvestmentAmount,
          remainingCapital: newRemainingCapital,
          realizedCapital: newRealizedCapital,
        );

        _modifiedInvestments[investment.id] = modifiedInvestment;
      }
    }
  }

  /// Odświeża dane inwestora po zapisaniu zmian
  Future<InvestorSummary> _refreshInvestorData() async {
    // TODO: Implementuj odświeżenie danych z serwera
    // Na razie zwracamy obecny obiekt - w pełnej implementacji
    // należy pobrać dane z serwera
    return widget.investor;
  }
}

// Static helper class
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

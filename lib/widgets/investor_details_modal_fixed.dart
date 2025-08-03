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

    _tabController = TabController(length: 3, vsync: this);

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
                        child: _buildResponsiveLayout(
                          isTablet: isTablet,
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
        Expanded(
          child: SingleChildScrollView(
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
                        _buildInvestmentStats(),
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
        _buildFooterActions(),
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
            ),
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
          'Łączna wartość',
          CurrencyFormatter.formatCurrency(widget.investor.totalValue),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Liczba inwestycji',
          '${widget.investor.investmentCount}',
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Pozostały kapitał',
          CurrencyFormatter.formatCurrency(
            widget.investor.totalRemainingCapital,
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
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
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
          AppTheme.primaryColor,
          () => widget.onEditInvestor?.call(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Inwestycje',
          Icons.account_balance_wallet,
          AppTheme.successColor,
          () => widget.onViewInvestments?.call(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Kontakt',
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
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _closeModal();
                widget.onViewInvestments?.call();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Zobacz inwestycje'),
            ),
          ),
        ],
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
    try {
      if (widget.analyticsService == null) {
        throw Exception('Analytics service nie jest dostępny');
      }

      // Sprawdź czy klient istnieje przed aktualizacją
      print('🔄 Próba aktualizacji klienta ID: ${widget.investor.client.id}');
      print('🔄 Dane klienta: ${widget.investor.client.name}');
      print('🔄 Email klienta: ${widget.investor.client.email}');

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
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zmiany zostały zapisane'),
          backgroundColor: AppTheme.successColor,
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
    }
  }

  Future<void> _contactInvestor() async {
    try {
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

  String _getClientTypeText(ClientType type) {
    return type.displayName;
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

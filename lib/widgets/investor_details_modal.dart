import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../models/investor_summary.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'custom_text_field.dart';
import 'animated_button.dart';

class InvestorDetailsModal extends StatefulWidget {
  final InvestorSummary investor;
  final Function()? onEditInvestor;
  final Function()? onViewInvestments;
  final Function(InvestorSummary)? onUpdateInvestor;

  const InvestorDetailsModal({
    super.key,
    required this.investor,
    this.onEditInvestor,
    this.onViewInvestments,
    this.onUpdateInvestor,
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
    final isTablet = MediaQuery.of(context).size.width > 768;
    final screenHeight = MediaQuery.of(context).size.height;

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
                        horizontal: isTablet ? 40 : 16,
                        vertical: isTablet ? 40 : 20,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                        maxHeight: screenHeight * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundModal,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderPrimary,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: isTablet
                          ? _buildTabletLayout()
                          : _buildMobileLayout(),
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

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            children: [
              // Lewa kolumna - informacje podstawowe
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildBasicInfo(),
                ),
              ),

              // Divider
              Container(width: 1, color: AppTheme.borderSecondary),

              // Prawa kolumna - szczegóły i akcje
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildDetailedInfo(),
                ),
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
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderSecondary),
                  ),
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
          ),
        ),
        _buildFooterActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getClientColor(widget.investor.client),
            _getClientColor(widget.investor.client).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Avatar inwestora
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.textOnPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.textOnPrimary, width: 2),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.investor.client.name),
                style: const TextStyle(
                  color: AppTheme.textOnPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Nazwa i podstawowe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investor.client.name,
                  style: const TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.investor.client.companyName?.isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.investor.client.companyName!,
                    style: TextStyle(
                      color: AppTheme.textOnPrimary.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    CurrencyFormatter.formatCurrency(
                      widget.investor.totalValue,
                    ),
                    style: const TextStyle(
                      color: AppTheme.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Przycisk zamknięcia
          IconButton(
            onPressed: _closeModal,
            icon: const Icon(Icons.close, color: AppTheme.textOnPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.textOnPrimary.withOpacity(0.2),
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

  Widget _buildInvestmentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(
          'Podsumowanie inwestycji',
          Icons.account_balance_wallet,
          [
            _buildStatCard(
              'Łączna wartość',
              CurrencyFormatter.formatCurrency(widget.investor.totalValue),
              Icons.trending_up,
              AppTheme.successColor,
            ),
            if (widget.investor.totalRemainingCapital > 0)
              _buildStatCard(
                'Pozostały kapitał',
                CurrencyFormatter.formatCurrency(
                  widget.investor.totalRemainingCapital,
                ),
                Icons.monetization_on,
                AppTheme.primaryColor,
              ),
            if (widget.investor.totalSharesValue > 0)
              _buildStatCard(
                'Wartość udziałów',
                CurrencyFormatter.formatCurrency(
                  widget.investor.totalSharesValue,
                ),
                Icons.business,
                AppTheme.infoColor,
              ),
            _buildStatCard(
              'Liczba inwestycji',
              '${widget.investor.investmentCount}',
              Icons.account_balance_wallet,
              AppTheme.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (widget.investor.hasUnviableInvestments) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inwestycje niewykonalne',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Inwestor posiada inwestycje oznaczone jako niewykonalne',
                        style: TextStyle(
                          color: AppTheme.warningColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildActionCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Akcje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (_isEditMode && _hasChanges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Niezapisane zmiany',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isEditMode) ...[
          // Editing mode
          _buildEditingForm(),
        ] else ...[
          // View mode actions
          _buildViewModeActions(),
        ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(top: BorderSide(color: AppTheme.borderSecondary)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
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
            child: AnimatedButton(
              onPressed: () {
                _closeModal();
                widget.onViewInvestments?.call();
              },
              child: const Text('Zobacz wszystkie inwestycje'),
            ),
          ),
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

  // === HELPER METHODS ===

  Future<void> _saveChanges() async {
    try {
      // Tutaj można dodać rzeczywiste zapisywanie do bazy danych
      // Na razie symulujemy zapisywanie
      await Future.delayed(const Duration(milliseconds: 500));

      // Wywołaj callback z zaktualizowanymi danymi
      widget.onUpdateInvestor?.call(widget.investor);

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
}

// Static method to show the modal
class InvestorDetailsModalHelper {
  static Future<void> show({
    required BuildContext context,
    required InvestorSummary investor,
    Function()? onEditInvestor,
    Function()? onViewInvestments,
    Function(InvestorSummary)? onUpdateInvestor,
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
      ),
    );
  }
}

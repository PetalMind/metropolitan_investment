import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../optimized_voting_status_widget.dart';

/// 🎨 SEKCJA PRZEGLĄD - Tab 1
///
/// Zawiera:
/// - Avatar/zdjęcie klienta z upload
/// - Imię i typ klienta
/// - Status aktywności i głosowania
/// - Kolor oznaczenia
/// - Quick stats preview
/// - PESEL/NIP validation
class ClientOverviewTab extends StatefulWidget {
  final ClientFormData formData;
  final VoidCallback onDataChanged;
  final Map<String, dynamic>? additionalData;

  const ClientOverviewTab({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.additionalData,
  });

  @override
  State<ClientOverviewTab> createState() => _ClientOverviewTabState();
}

class _ClientOverviewTabState extends State<ClientOverviewTab>
    with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _peselController = TextEditingController();

  // Animation controllers
  // late AnimationController _cardController; // Removed - not used

  // Color selection
  final List<Color> _availableColors = [
    const Color(0xFFFFFFFF), // White (default)
    const Color(0xFFFFE066), // Light Yellow
    const Color(0xFFFF9999), // Light Red
    const Color(0xFF99FF99), // Light Green
    const Color(0xFF9999FF), // Light Blue
    const Color(0xFFFFCC99), // Light Orange
    const Color(0xFFFF99FF), // Light Pink
    const Color(0xFF99FFFF), // Light Cyan
    const Color(0xFFCCCCCC), // Light Gray
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.formData.name;
    _companyNameController.text = widget.formData.companyName ?? '';
    _peselController.text = widget.formData.pesel ?? '';

    // Listen to changes
    _nameController.addListener(_onNameChanged);
    _companyNameController.addListener(_onCompanyNameChanged);
    _peselController.addListener(_onPeselChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _peselController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    widget.formData.name = _nameController.text;
    widget.onDataChanged();
  }

  void _onCompanyNameChanged() {
    widget.formData.companyName = _companyNameController.text.isNotEmpty
        ? _companyNameController.text
        : null;
    widget.onDataChanged();
  }

  void _onPeselChanged() {
    widget.formData.pesel = _peselController.text.isNotEmpty
        ? _peselController.text
        : null;
    widget.onDataChanged();
  }

  void _onTypeChanged(ClientType newType) {
    setState(() {
      widget.formData.type = newType;
    });
    widget.onDataChanged();
    HapticFeedback.lightImpact();
  }

  void _onActiveChanged(bool isActive) {
    setState(() {
      widget.formData.isActive = isActive;
    });
    widget.onDataChanged();
    HapticFeedback.lightImpact();
  }

  void _onVotingStatusChanged(VotingStatus status) {
    setState(() {
      widget.formData.votingStatus = status;
    });
    widget.onDataChanged();
  }

  void _onColorChanged(Color color) {
    setState(() {
      widget.formData.colorCode =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    });
    widget.onDataChanged();
    HapticFeedback.lightImpact();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Imię i nazwisko jest wymagane';
    }
    if (value.trim().length < 2) {
      return 'Imię musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  String? _validatePesel(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length != 11) {
      return 'PESEL musi mieć 11 cyfr';
    }

    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return 'PESEL może zawierać tylko cyfry';
    }

    // Basic PESEL validation
    final digits = value.split('').map(int.parse).toList();
    final weights = [1, 3, 7, 9, 1, 3, 7, 9, 1, 3];
    int sum = 0;

    for (int i = 0; i < 10; i++) {
      sum += digits[i] * weights[i];
    }

    final checksum = (10 - (sum % 10)) % 10;
    if (checksum != digits[10]) {
      return 'Nieprawidłowy PESEL';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header z avatarem
          _buildAvatarSection(),
          const SizedBox(height: 32),

          // Podstawowe informacje
          _buildBasicInfoSection(),
          const SizedBox(height: 24),

          // Typ klienta i status
          _buildTypeAndStatusSection(),
          const SizedBox(height: 24),

          // Status głosowania
          _buildVotingSection(),
          const SizedBox(height: 24),

          // Kolor oznaczenia
          _buildColorSection(),
          const SizedBox(height: 24),

          // Quick stats (jeśli dostępne)
          if (widget.additionalData != null) _buildQuickStatsSection(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppThemePro.surfaceCard,
                    AppThemePro.surfaceCard.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppThemePro.accentGold,
                              AppThemePro.accentGold.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppThemePro.accentGold.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getClientTypeIcon(),
                          color: AppThemePro.backgroundPrimary,
                          size: 36,
                        ),
                      ),

                      // Color indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                '0xFF${widget.formData.colorCode.substring(1)}',
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppThemePro.backgroundPrimary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Info summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formData.name.isNotEmpty
                              ? widget.formData.name
                              : 'Nowy klient',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppThemePro.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.formData.type.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppThemePro.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Status badges
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildStatusBadge(
                              widget.formData.isActive
                                  ? 'Aktywny'
                                  : 'Nieaktywny',
                              widget.formData.isActive
                                  ? AppThemePro.statusSuccess
                                  : AppThemePro.statusError,
                              widget.formData.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                            ),
                            _buildStatusBadge(
                              widget.formData.votingStatus.displayName,
                              _getVotingStatusColor(
                                widget.formData.votingStatus,
                              ),
                              _getVotingStatusIcon(
                                widget.formData.votingStatus,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Podstawowe informacje',
            Icons.person_rounded,
            'Główne dane identyfikacyjne klienta',
          ),
          const SizedBox(height: 20),

          // Imię i nazwisko
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Imię i nazwisko / Nazwa*',
              hintText: 'Wprowadź pełne imię i nazwisko',
              prefixIcon: const Icon(Icons.badge_rounded),
              helperText: 'Zapisywane jako "fullName" w Firebase',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppThemePro.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppThemePro.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
              ),
            ),
            validator: _validateName,
          ),

          const SizedBox(height: 16),

          // Nazwa firmy (dla spółek)
          if (widget.formData.type == ClientType.company) ...[
            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Nazwa firmy*',
                hintText: 'Pełna nazwa firmy',
                prefixIcon: const Icon(Icons.business_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemePro.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemePro.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppThemePro.accentGold,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (widget.formData.type == ClientType.company &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Nazwa firmy jest wymagana dla spółek';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // PESEL (dla osób fizycznych)
          if (widget.formData.type == ClientType.individual ||
              widget.formData.type == ClientType.marriage) ...[
            TextFormField(
              controller: _peselController,
              decoration: InputDecoration(
                labelText: 'PESEL',
                hintText: '11-cyfrowy numer PESEL',
                prefixIcon: const Icon(Icons.credit_card_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemePro.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppThemePro.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppThemePro.accentGold,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 11,
              validator: _validatePesel,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeAndStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Typ i status',
            Icons.category_rounded,
            'Klasyfikacja i status aktywności klienta',
          ),
          const SizedBox(height: 20),

          // Typ klienta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Typ klienta*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: ClientType.values.map((type) {
                  final isSelected = widget.formData.type == type;
                  return GestureDetector(
                    onTap: () => _onTypeChanged(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppThemePro.accentGold.withOpacity(0.1)
                            : AppThemePro.surfaceInteractive,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppThemePro.accentGold
                              : AppThemePro.borderSecondary,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getClientTypeIcon(type),
                            size: 18,
                            color: isSelected
                                ? AppThemePro.accentGold
                                : AppThemePro.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppThemePro.accentGold
                                  : AppThemePro.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status aktywności
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status aktywności',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.formData.isActive
                          ? 'Klient jest aktywny i może dokonywać nowych inwestycji'
                          : 'Klient nieaktywny - ograniczony dostęp do nowych produktów',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: widget.formData.isActive,
                onChanged: _onActiveChanged,
                activeColor: AppThemePro.statusSuccess,
                inactiveThumbColor: AppThemePro.statusError,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Status głosowania',
            Icons.how_to_vote_rounded,
            'Preferencje uczestnictwa w głosowaniach korporacyjnych',
          ),
          const SizedBox(height: 20),

          OptimizedVotingStatusSelector(
            currentStatus: widget.formData.votingStatus,
            onStatusChanged: _onVotingStatusChanged,
            isCompact: false,
            showLabels: true,
            clientName: widget.formData.name.isNotEmpty
                ? widget.formData.name
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Kolor oznaczenia',
            Icons.palette_rounded,
            'Wybierz kolor do wizualnego oznaczenia klienta',
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((color) {
              final isSelected =
                  widget.formData.colorCode ==
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

              return GestureDetector(
                onTap: () => _onColorChanged(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppThemePro.accentGold
                          : AppThemePro.borderSecondary,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppThemePro.accentGold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    // TODO: Implement quick stats from additional data
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Szybki podgląd',
            Icons.dashboard_rounded,
            'Podstawowe statystyki klienta',
          ),
          const SizedBox(height: 20),

          const Center(
            child: Text(
              '📊 Statystyki będą wyświetlane po zapisaniu klienta',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppThemePro.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppThemePro.accentGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppThemePro.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getClientTypeIcon([ClientType? type]) {
    switch (type ?? widget.formData.type) {
      case ClientType.individual:
        return Icons.person_rounded;
      case ClientType.company:
        return Icons.business_rounded;
      case ClientType.marriage:
        return Icons.people_rounded;
      case ClientType.other:
        return Icons.account_circle_rounded;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppThemePro.statusSuccess;
      case VotingStatus.no:
        return AppThemePro.statusError;
      case VotingStatus.abstain:
        return AppThemePro.statusWarning;
      case VotingStatus.undecided:
        return AppThemePro.statusWarning;
    }
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle_rounded;
      case VotingStatus.no:
        return Icons.cancel_rounded;
      case VotingStatus.abstain:
        return Icons.pause_circle_rounded;
      case VotingStatus.undecided:
        return Icons.help_rounded;
    }
  }
}

// Import this in enhanced_client_dialog.dart
class ClientFormData {
  // Basic info
  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String? pesel;
  String? companyName;
  ClientType type = ClientType.individual;
  bool isActive = true;
  String notes = '';
  VotingStatus votingStatus = VotingStatus.undecided;
  String colorCode = '#FFFFFF';

  // Additional data
  Map<String, dynamic> additionalInfo = {};

  // 🎯 CONTACT PREFERENCES
  ContactPreferences contactPreferences = const ContactPreferences();

  ClientFormData();

  ClientFormData.fromClient(Client? client) {
    if (client != null) {
      name = client.name;
      email = client.email;
      phone = client.phone;
      address = client.address;
      pesel = client.pesel;
      companyName = client.companyName;
      type = client.type;
      isActive = client.isActive;
      notes = client.notes;
      votingStatus = client.votingStatus;
      colorCode = client.colorCode;
      additionalInfo = Map.from(client.additionalInfo);
      contactPreferences = client.contactPreferences;
    }
  }

  Client toClient() {
    return Client(
      id: '', // Will be set by service
      name: name,
      email: email,
      phone: phone,
      address: address,
      pesel: pesel,
      companyName: companyName,
      type: type,
      isActive: isActive,
      notes: notes,
      votingStatus: votingStatus,
      colorCode: colorCode,
      additionalInfo: additionalInfo,
      contactPreferences: contactPreferences,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

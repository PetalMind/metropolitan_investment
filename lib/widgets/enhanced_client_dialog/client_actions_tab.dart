import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../client_notes_widget.dart'; // Import ClientNotesWidget
import 'client_overview_tab.dart'; // For ClientFormData
import '../email_history_widget.dart';
import '../investment_history_widget.dart';

/// Client Actions Tab
/// - Opens the existing EnhancedEmailEditorDialog for email flows
/// - Uses EmailAndExportService for exports
/// - Shows client notes (via ClientNotesService)
/// - Documents area is a lightweight placeholder until a DocumentsService is provided
class ClientActionsTab extends StatefulWidget {
  final Client? client;
  final ClientFormData formData;
  final VoidCallback onDataChanged;

  const ClientActionsTab({
    super.key,
    this.client,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<ClientActionsTab> createState() => _ClientActionsTabState();
}

class _ClientActionsTabState extends State<ClientActionsTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ClientNotesService _clientNotesService = ClientNotesService();
  final UniversalInvestmentService _investmentService = UniversalInvestmentService.instance;

  final _notesController = TextEditingController();
  late final AnimationController _cardController;

  List<Investment> _clientInvestments = [];
  bool _investmentsLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _notesController.text = widget.formData.notes;
    _notesController.addListener(_onNotesChanged);
    _loadClientData();
    _cardController.forward();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    widget.formData.notes = _notesController.text;
    widget.onDataChanged();
  }

  Future<void> _loadClientData() async {
    _clientInvestments = [];

    if (widget.client == null) return;

    try {
      if (mounted) {
        setState(() {
          _investmentsLoading = true;
        });
      }

      // Load client investments
      final investments = await _investmentService.getInvestmentsForClient(widget.client!.id);
      
      if (mounted) {
        setState(() {
          _clientInvestments = investments;
          _investmentsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Błąd ładowania danych klienta: $e');
      if (mounted) {
        setState(() {
          _investmentsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          _buildNotesSection(),
          const SizedBox(height: 24),
          _buildDocumentsSection(),
          const SizedBox(height: 24),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Szybkie akcje',
                    Icons.flash_on_rounded,
                    'Najczęściej używane operacje',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Email',
                          Icons.email_rounded,
                          AppThemePro.accentGold,
                          () => _sendEmail(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Spotkanie',
                          Icons.event_rounded,
                          AppThemePro.statusInfo,
                          () => _scheduleMeeting(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (widget.client != null) ...[
                    SizedBox(
                      height: 600, // Fixed height for the notes widget
                      child: ClientNotesWidget(
                        clientId: widget.client!.id,
                        clientName: widget.client!.name,
                        currentUserId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
                        currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? 
                                       FirebaseAuth.instance.currentUser?.email ?? 'Nieznany użytkownik',
                        isReadOnly: false,
                      ),
                    ),
                  ] else ...[
                    // Fallback for new clients
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notatki (zapisane po utworzeniu klienta)',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                        alignLabelWithHint: true,
                        enabled: false,
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Zaawansowane notatki będą dostępne po zapisaniu klienta',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildDocumentsSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSectionHeader(
                          'Dokumenty',
                          Icons.folder_rounded,
                          'Pliki i dokumenty klienta',
                        ),
                      ),
                      IconButton(
                        onPressed: null, // Disabled until document service is implemented
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppThemePro.textMuted.withOpacity(0.1),
                          foregroundColor: AppThemePro.textMuted,
                        ),
                        tooltip: 'Funkcja niedostępna - brak serwisu dokumentów',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 48,
                          color: AppThemePro.textTertiary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Funkcja dokumentów niedostępna',
                          style: TextStyle(color: AppThemePro.textTertiary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Wymaga implementacji serwisu dokumentów',
                          style: TextStyle(
                            color: AppThemePro.textMuted,
                            fontSize: 12,
                          ),
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

  Widget _buildDocumentCard(dynamic document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemePro.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDocumentTypeColor(document.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getDocumentTypeIcon(document.type),
              color: _getDocumentTypeColor(document.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                Text(
                  '${document.size} • ${_formatDate(document.uploadedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadDocument(document),
            icon: const Icon(Icons.download_rounded),
            iconSize: 18,
            style: IconButton.styleFrom(
              foregroundColor: AppThemePro.textSecondary,
            ),
          ),
          IconButton(
            onPressed: () => _deleteDocument(document),
            icon: const Icon(Icons.delete_outline_rounded),
            iconSize: 18,
            style: IconButton.styleFrom(
              foregroundColor: AppThemePro.statusError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Historia aktywności',
                    Icons.history_rounded,
                    'Ostatnie zmiany i operacje',
                  ),
                  const SizedBox(height: 20),
                  
                  // Tab controls for different history types
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: AppThemePro.accentGold,
                          unselectedLabelColor: AppThemePro.textSecondary,
                          indicatorColor: AppThemePro.accentGold,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.trending_up_rounded),
                              text: 'Zmiany inwestycji',
                            ),
                            Tab(
                              icon: Icon(Icons.email_rounded),
                              text: 'Historia emaili',
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 400, // Fixed height for tab content
                          child: TabBarView(
                            children: [
                              _buildInvestmentHistoryTab(),
                              _buildEmailHistoryTab(),
                            ],
                          ),
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

  Widget _buildInvestmentHistoryTab() {
    if (widget.client == null) {
      return _buildEmptyHistoryState(
        'Brak danych klienta',
        Icons.trending_up_rounded,
        'Wybierz klienta aby zobaczyć historię zmian inwestycji.',
      );
    }

    if (_investmentsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie inwestycji klienta...'),
          ],
        ),
      );
    }

    if (_clientInvestments.isEmpty) {
      return _buildEmptyHistoryState(
        'Brak inwestycji',
        Icons.trending_up_rounded,
        'Ten klient nie ma jeszcze żadnych inwestycji.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppThemePro.accentGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historia zmian inwestycji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppThemePro.textPrimary,
                        ),
                      ),
                      Text(
                        '${_clientInvestments.length} ${_getInvestmentText(_clientInvestments.length)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppThemePro.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Investment history for each investment
          ..._clientInvestments.map((investment) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppThemePro.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemePro.borderPrimary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Investment header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemePro.backgroundSecondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppThemePro.accentGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: AppThemePro.accentGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investment.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppThemePro.textPrimary,
                                ),
                              ),
                              Text(
                                'ID: ${investment.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppThemePro.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Investment history widget
                  InvestmentHistoryWidget(
                    investmentId: investment.id,
                    isCompact: true,
                    maxEntries: 5,
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmailHistoryTab() {
    if (widget.client == null) {
      return _buildEmptyHistoryState(
        'Brak danych klienta',
        Icons.email_rounded,
        'Wybierz klienta aby zobaczyć historię emaili.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: EmailHistoryWidget(
        clientId: widget.client!.id,
        title: null, // No title since we have tab title
        isCompact: false,
        maxEntries: 20, // Limit to 20 most recent emails
      ),
    );
  }

  Widget _buildEmptyHistoryState(String title, IconData icon, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppThemePro.accentGold.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppThemePro.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentChangeCard(InvestmentChangeHistory change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChangeTypeColor(change.changeType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  InvestmentChangeType.fromValue(change.changeType).displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getChangeTypeColor(change.changeType),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(change.changedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            change.changeDescription,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemePro.textPrimary,
            ),
          ),
          if (change.fieldChanges.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...change.fieldChanges.map((fieldChange) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                fieldChange.changeDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemePro.textSecondary,
                ),
              ),
            )),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 12,
                color: AppThemePro.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                change.userName,
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailHistoryCard(EmailHistory email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEmailStatusColor(email.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEmailStatusIcon(email.status),
                      size: 12,
                      color: _getEmailStatusColor(email.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getEmailStatusText(email.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getEmailStatusColor(email.status),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(email.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            email.subject,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.email_rounded,
                size: 12,
                color: AppThemePro.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${email.recipients.length} odbiorca(ów)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.person_rounded,
                size: 12,
                color: AppThemePro.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                email.senderName.isNotEmpty ? email.senderName : email.senderEmail,
                style: TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppThemePro.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getInvestmentText(int count) {
    if (count == 1) return 'inwestycja';
    if (count >= 2 && count <= 4) return 'inwestycje';
    return 'inwestycji';
  }

  DateTime _getNextBusinessDay(DateTime from) {
    DateTime candidate = from.add(const Duration(days: 1));
    // Skip weekend (Saturday = 6, Sunday = 7)
    while (candidate.weekday == DateTime.saturday || candidate.weekday == DateTime.sunday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    // Set to 10:00 AM
    return DateTime(candidate.year, candidate.month, candidate.day, 10, 0);
  }

  String _generateMeetingDescription() {
    final client = widget.client!;
    final investmentCount = _clientInvestments.length;
    
    String description = 'Spotkanie biznesowe z klientem ${client.name}';
    
    if (investmentCount > 0) {
      description += '\n\nKlient posiada $investmentCount ${_getInvestmentText(investmentCount)}.';
    }
    
    if (client.email.isNotEmpty) {
      description += '\nKontakt email: ${client.email}';
    }
    
    if (client.phone.isNotEmpty) {
      description += '\nKontakt telefoniczny: ${client.phone}';
    }

    return description;
  }

  String _getSuggestedMeetingLocation() {
    // Could be enhanced with user preferences or company settings
    return 'Biuro Metropolitan Investment';
  }

  List<String> _buildParticipantsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final participants = <String>[];
    
    if (currentUser?.email != null) {
      participants.add(currentUser!.email!);
    }
    
    if (widget.client!.email.isNotEmpty) {
      participants.add(widget.client!.email);
    }
    
    return participants;
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'field_update':
        return AppThemePro.statusInfo;
      case 'bulk_update':
        return AppThemePro.statusWarning;
      case 'import':
        return AppThemePro.statusInfo; // Using statusInfo instead of accentBlue
      case 'manual_entry':
        return AppThemePro.statusSuccess;
      case 'system_update':
        return AppThemePro.accentGoldMuted; // Using accentGoldMuted instead of accentPurple
      case 'correction':
        return AppThemePro.statusError;
      default:
        return AppThemePro.textSecondary;
    }
  }

  Color _getEmailStatusColor(EmailStatus status) {
    switch (status) {
      case EmailStatus.pending:
        return AppThemePro.statusWarning;
      case EmailStatus.sending:
        return AppThemePro.statusInfo;
      case EmailStatus.sent:
        return AppThemePro.statusSuccess;
      case EmailStatus.failed:
        return AppThemePro.statusError;
      case EmailStatus.partiallyFailed:
        return AppThemePro.statusWarning;
    }
  }

  IconData _getEmailStatusIcon(EmailStatus status) {
    switch (status) {
      case EmailStatus.pending:
        return Icons.schedule_rounded;
      case EmailStatus.sending:
        return Icons.sync_rounded;
      case EmailStatus.sent:
        return Icons.check_circle_rounded;
      case EmailStatus.failed:
        return Icons.error_rounded;
      case EmailStatus.partiallyFailed:
        return Icons.warning_rounded;
    }
  }

  String _getEmailStatusText(EmailStatus status) {
    switch (status) {
      case EmailStatus.pending:
        return 'Oczekuje';
      case EmailStatus.sending:
        return 'Wysyłanie';
      case EmailStatus.sent:
        return 'Wysłany';
      case EmailStatus.failed:
        return 'Błąd';
      case EmailStatus.partiallyFailed:
        return 'Częściowo nieudany';
    }
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'JPG':
      case 'PNG':
        return Colors.blue;
      case 'DOC':
      case 'DOCX':
        return Colors.indigo;
      case 'XLS':
      case 'XLSX':
        return Colors.green;
      default:
        return AppThemePro.textSecondary;
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'JPG':
      case 'PNG':
        return Icons.image_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.description_rounded;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // Action methods
  void _sendEmail() {
    HapticFeedback.lightImpact();
    if (widget.client != null) {
      // Create InvestorSummary from client data with real investments
      final investorSummary = InvestorSummary.withoutCalculations(
        widget.client!,
        _clientInvestments,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WowEmailEditorScreen(
            selectedInvestors: [investorSummary],
            initialSubject: 'Wiadomość dla ${widget.client!.name}',
            initialMessage: 'Szanowny(a) ${widget.client!.name},\n\n',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak danych klienta do wysłania emaila'),
          backgroundColor: AppThemePro.statusWarning,
        ),
      );
    }
  }

  void _scheduleMeeting() {
    HapticFeedback.lightImpact();
    if (widget.client != null) {
      final now = DateTime.now();
      // Schedule for next business day (Monday-Friday)
      final suggestedDate = _getNextBusinessDay(now);
      final currentUser = FirebaseAuth.instance.currentUser;
      
      final initialEvent = CalendarEvent(
        id: '',
        title: 'Spotkanie z ${widget.client!.name}',
        description: _generateMeetingDescription(),
        startDate: suggestedDate,
        endDate: suggestedDate.add(const Duration(hours: 1)),
        location: _getSuggestedMeetingLocation(),
        category: CalendarEventCategory.client,
        status: CalendarEventStatus.tentative,
        participants: _buildParticipantsList(),
        createdBy: currentUser?.uid ?? '',
        createdAt: now,
        updatedAt: now,
      );

      PremiumCalendarEventDialog.show(
        context,
        event: initialEvent,
        initialDate: suggestedDate,
        onEventChanged: (event) {
          // Event was created/updated successfully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📅 Utworzono wydarzenie: ${event.title}'),
              backgroundColor: AppThemePro.statusSuccess,
            ),
          );
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brak danych klienta do zaplanowania spotkania'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }

  void _uploadDocument() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📎 Otwieranie eksploratora plików...'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }

  void _downloadDocument(dynamic document) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⬇️ Pobieranie ${document?.name ?? ''}...'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _deleteDocument(dynamic document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń dokument'),
        content: Text('Czy na pewno chcesz usunąć ${document?.name ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Document removal would be handled by document service when available
              HapticFeedback.mediumImpact();
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

}

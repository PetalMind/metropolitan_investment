import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'client_overview_tab.dart'; // For ClientFormData

/// 🎨 SEKCJA AKCJE - Tab 5
///
/// Zawiera:
/// - Email management z szablonami
/// - Notatki i historia kontaktów
/// - Dokumenty i pliki klienta
/// - Historia operacji
/// - Quick actions (telefon, email, spotkanie)
/// - Eksport danych klienta
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
  // 🚀 UŻYWAJ ISTNIEJĄCYCH SERWISÓW Z models_and_services.dart (w przyszłości)
  // final ClientNotesService _clientNotesService = ClientNotesService();
  // final EmailService _emailService = EmailService();
  // final EmailHistoryService _emailHistoryService = EmailHistoryService();
  // final CalendarService _calendarService = CalendarService();

  // Controllers for forms
  final _notesController = TextEditingController();
  final _emailSubjectController = TextEditingController();
  final _emailBodyController = TextEditingController();

  // Animation controllers
  late AnimationController _cardController;
  late AnimationController _emailController;

  // State
  bool _isEmailExpanded = false;
  String _selectedEmailTemplate = 'Wybierz szablon';
  List<ClientNote> _clientNotes = [];
  List<ClientDocument> _clientDocuments = [];

  // 🚀 UŻYJ DOSTĘPNYCH MODELI EMAILI
  final Map<String, String> _emailTemplates = {
    'Powitanie':
        'Szanowny/a {name},\n\nDziękujemy za zaufanie i wybór naszej firmy...',
    'Raport miesięczny':
        'Szanowny/a {name},\n\nPrzesyłamy raport z Pana/Pani inwestycji za {month}...',
    'Przypomnienie':
        'Szanowny/a {name},\n\nUprzejmie przypominamy o zbliżającym się terminie...',
    'Zaproszenie na spotkanie':
        'Szanowny/a {name},\n\nChcielibyśmy zaprosić Pana/Panię na spotkanie...',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClientData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _emailController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _notesController.text = widget.formData.notes;
    _notesController.addListener(_onNotesChanged);

    _cardController.forward();
  }

  void _loadClientData() {
    // Load client notes and documents - mock implementation
    _clientNotes = [
      ClientNote(
        id: '1',
        content: 'Klient zainteresowany dodatkową inwestycją w Q2',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        author: 'Jan Kowalski',
      ),
      ClientNote(
        id: '2',
        content: 'Wysłano raport miesięczny na email',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        author: 'Anna Nowak',
      ),
    ];

    _clientDocuments = [
      ClientDocument(
        id: '1',
        name: 'Umowa inwestycyjna.pdf',
        type: 'PDF',
        size: '2.1 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ClientDocument(
        id: '2',
        name: 'Dokument tożsamości.jpg',
        type: 'JPG',
        size: '1.5 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];
  }

  void _onNotesChanged() {
    widget.formData.notes = _notesController.text;
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions row
          _buildQuickActionsSection(),
          const SizedBox(height: 24),

          // Email section
          _buildEmailSection(),
          const SizedBox(height: 24),

          // Notes section
          _buildNotesSection(),
          const SizedBox(height: 24),

          // Documents section
          _buildDocumentsSection(),
          const SizedBox(height: 24),

          // History section
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
                          'Telefon',
                          Icons.phone_rounded,
                          AppThemePro.statusSuccess,
                          () => _makePhoneCall(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Email',
                          Icons.email_rounded,
                          AppThemePro.accentGold,
                          () => _toggleEmailSection(),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Eksport',
                          Icons.download_rounded,
                          AppThemePro.statusWarning,
                          () => _showExportOptions(),
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

  Widget _buildEmailSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
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
                          'Komunikacja email',
                          Icons.email_rounded,
                          'Szablony i wysyłanie wiadomości',
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleEmailSection,
                        icon: AnimatedRotation(
                          turns: _isEmailExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(Icons.expand_more_rounded),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppThemePro.accentGold.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppThemePro.accentGold,
                        ),
                      ),
                    ],
                  ),

                  if (_isEmailExpanded) ...[
                    const SizedBox(height: 20),
                    _buildEmailForm(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailForm() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _emailController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template selector
          DropdownButtonFormField<String>(
            value: _selectedEmailTemplate,
            decoration: const InputDecoration(
              labelText: 'Szablon wiadomości',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            items: ['Wybierz szablon', ..._emailTemplates.keys]
                .map(
                  (template) =>
                      DropdownMenuItem(value: template, child: Text(template)),
                )
                .toList(),
            onChanged: _onEmailTemplateChanged,
          ),
          const SizedBox(height: 16),

          // Subject field
          TextFormField(
            controller: _emailSubjectController,
            decoration: const InputDecoration(
              labelText: 'Temat wiadomości',
              prefixIcon: Icon(Icons.subject_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Body field
          TextFormField(
            controller: _emailBodyController,
            decoration: const InputDecoration(
              labelText: 'Treść wiadomości',
              prefixIcon: Icon(Icons.message_rounded),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            minLines: 4,
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previewEmail,
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Podgląd'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Wyślij'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold,
                    foregroundColor: AppThemePro.backgroundPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  _buildSectionHeader(
                    'Notatki',
                    Icons.notes_rounded,
                    'Zapisz ważne informacje o kliencie',
                  ),
                  const SizedBox(height: 20),

                  // Current notes input
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Dodaj notatkę...',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    minLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Notes history
                  if (_clientNotes.isNotEmpty) ...[
                    Text(
                      'Historia notatek',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._clientNotes
                        .map((note) => _buildNoteCard(note))
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(ClientNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemePro.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppThemePro.textPrimary,
            ),
          ),
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
                note.author,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(note.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppThemePro.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
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
                        onPressed: _uploadDocument,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppThemePro.accentGold.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppThemePro.accentGold,
                        ),
                        tooltip: 'Dodaj dokument',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_clientDocuments.isEmpty)
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
                            'Brak dokumentów',
                            style: TextStyle(color: AppThemePro.textTertiary),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._clientDocuments
                        .map((doc) => _buildDocumentCard(doc))
                        .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(ClientDocument document) {
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
                    'Ostatnie operacje i zmiany',
                  ),
                  const SizedBox(height: 20),

                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 48,
                          color: AppThemePro.textTertiary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Historia będzie dostępna wkrótce',
                          style: TextStyle(color: AppThemePro.textTertiary),
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

  // Helper methods
  void _toggleEmailSection() {
    setState(() {
      _isEmailExpanded = !_isEmailExpanded;
    });

    if (_isEmailExpanded) {
      _emailController.forward();
    } else {
      _emailController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  void _onEmailTemplateChanged(String? template) {
    if (template == null || template == 'Wybierz szablon') return;

    setState(() {
      _selectedEmailTemplate = template;
    });

    final emailTemplate = _emailTemplates[template];
    if (emailTemplate != null) {
      // Ustaw temat na podstawie szablonu
      String subject;
      switch (template) {
        case 'Powitanie':
          subject = 'Witamy w Metropolitan Investment';
          break;
        case 'Raport miesięczny':
          subject =
              'Raport miesięczny - ${_getCurrentMonth()} ${DateTime.now().year}';
          break;
        case 'Przypomnienie':
          subject = 'Przypomnienie o terminie';
          break;
        case 'Zaproszenie na spotkanie':
          subject = 'Zaproszenie na spotkanie';
          break;
        default:
          subject = '';
      }

      _emailSubjectController.text = _replaceVariables(subject);
      _emailBodyController.text = _replaceVariables(emailTemplate);
    }
  }

  String _replaceVariables(String text) {
    return text
        .replaceAll('{name}', widget.formData.name)
        .replaceAll('{month}', _getCurrentMonth())
        .replaceAll('{year}', DateTime.now().year.toString());
  }

  String _getCurrentMonth() {
    const months = [
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień',
    ];
    return months[DateTime.now().month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
  void _makePhoneCall() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Dzwonię na numer ${widget.formData.phone}'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _scheduleMeeting() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📅 Otwieranie kalendarza...'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppThemePro.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Eksportuj dane klienta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildExportOption('PDF', Icons.picture_as_pdf, Colors.red),
                  _buildExportOption('Excel', Icons.table_chart, Colors.green),
                  _buildExportOption(
                    'JSON',
                    Icons.code,
                    AppThemePro.accentGold,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(String type, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text('Eksportuj jako $type'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          _exportData(type);
        },
      ),
    );
  }

  void _previewEmail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Podgląd wiadomości'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do: ${widget.formData.email}'),
            const SizedBox(height: 8),
            Text('Temat: ${_emailSubjectController.text}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_emailBodyController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _sendEmail() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Wysyłanie wiadomości...'),
        backgroundColor: AppThemePro.accentGold,
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

  void _downloadDocument(ClientDocument document) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⬇️ Pobieranie ${document.name}...'),
        backgroundColor: AppThemePro.statusSuccess,
      ),
    );
  }

  void _deleteDocument(ClientDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń dokument'),
        content: Text('Czy na pewno chcesz usunąć ${document.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _clientDocuments.remove(document);
              });
              HapticFeedback.mediumImpact();
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _exportData(String type) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 Eksportowanie jako $type...'),
        backgroundColor: AppThemePro.statusInfo,
      ),
    );
  }
}

// Helper data classes
class EmailTemplate {
  final String subject;
  final String body;

  EmailTemplate({required this.subject, required this.body});
}

class ClientNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final String author;

  ClientNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
  });
}

class ClientDocument {
  final String id;
  final String name;
  final String type;
  final String size;
  final DateTime uploadedAt;

  ClientDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'client_overview_tab.dart'; // For ClientFormData

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
  final CalendarService _calendarService = CalendarService();

  final _notesController = TextEditingController();
  late final AnimationController _cardController;

  List<ClientNote> _clientNotes = [];
  List<dynamic> _clientDocuments = [];

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
    _clientNotes = [];
    _clientDocuments = [];

    if (widget.client == null) return;

    final clientId = widget.client!.id;

    try {
      final notes = await _clientNotesService.getClientNotes(clientId);
      setState(() => _clientNotes = notes);
    } catch (e) {
      debugPrint('Błąd ładowania notatek: $e');
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
                          'Telefon',
                          Icons.phone_rounded,
                          AppThemePro.statusSuccess,
                          () => _makePhoneCall(),
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
                  _buildSectionHeader(
                    'Notatki',
                    Icons.notes_rounded,
                    'Zapisz ważne informacje o kliencie',
                  ),
                  const SizedBox(height: 20),
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
                note.authorName,
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
                    // When a documents service is available, map documents here
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
    if (widget.client != null) {
      final now = DateTime.now().add(const Duration(days: 7));
      final event = CalendarEvent(
        id: '',
        title: 'Spotkanie z ${widget.client!.name}',
        description: 'Automatycznie utworzone wydarzenie',
        startDate: now,
        endDate: now.add(const Duration(hours: 1)),
        location: '',
        category: CalendarEventCategory.client,
        status: CalendarEventStatus.tentative,
        participants: [],
        createdBy: '',
        createdAt: now,
        updatedAt: now,
      );

      _calendarService
          .createEvent(event)
          .then((created) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📅 Utworzono wydarzenie: ${created.title}'),
                backgroundColor: AppThemePro.statusInfo,
              ),
            );
          })
          .catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Błąd tworzenia wydarzenia'),
                backgroundColor: Colors.red,
              ),
            );
          });
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

}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';

class ClientNotesWidget extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String? currentUserId;
  final String? currentUserName;
  final bool isReadOnly;

  const ClientNotesWidget({
    super.key,
    required this.clientId,
    required this.clientName,
    this.currentUserId,
    this.currentUserName,
    this.isReadOnly = false,
  });

  @override
  State<ClientNotesWidget> createState() => _ClientNotesWidgetState();
}

class _ClientNotesWidgetState extends State<ClientNotesWidget> {
  final ClientNotesService _notesService = ClientNotesService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ClientNote> _notes = [];
  List<ClientNote> _filteredNotes = [];
  bool _isLoading = false;
  bool _isSearchBarVisible = true;
  double _scrollOffset = 0.0;
  
  NoteCategory? _selectedCategory;
  NotePriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotes();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    // Żeby upewnić się, że żadne pending operacje nie wywołają setState() po dispose
    print(
      '🔧 [ClientNotesWidget] Widget disposed for client: ${widget.clientId}',
    );
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final shouldHideSearchBar = currentOffset > 50; // Zwiń po przesunięciu 50px
    
    if (shouldHideSearchBar != !_isSearchBarVisible) {
      setState(() {
        _isSearchBarVisible = !shouldHideSearchBar;
        _scrollOffset = currentOffset;
      });
    }
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notes = await _notesService.getClientNotes(widget.clientId);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();

    if (!mounted) return;
    setState(() {
      _filteredNotes = _notes.where((note) {
        // Filtruj po tekście
        final matchesQuery =
            query.isEmpty ||
            note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));

        // Filtruj po kategorii
        final matchesCategory =
            _selectedCategory == null || note.category == _selectedCategory;

        // Filtruj po priorytecie
        final matchesPriority =
            _selectedPriority == null || note.priority == _selectedPriority;

        return matchesQuery && matchesCategory && matchesPriority;
      }).toList();
    });
  }

  Future<void> _showNoteDialog([ClientNote? noteToEdit]) async {
    final result = await showDialog<ClientNote>(
      context: context,
      builder: (context) => ProfessionalNoteEditDialog(
        note: noteToEdit,
        clientId: widget.clientId,
        currentUserId: widget.currentUserId ?? 'unknown',
        currentUserName: widget.currentUserName ?? 'Nieznany użytkownik',
      ),
    );

    if (result != null) {
      if (noteToEdit == null) {
        // Dodaj nową notatkę
        await _notesService.addNote(result);
      } else {
        // Aktualizuj istniejącą notatkę
        await _notesService.updateNote(result);
      }
      if (mounted) {
        _loadNotes();
      }
    }
  }

  Future<void> _deleteNote(ClientNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.backgroundModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
        title: Text(
          'Usuwanie notatki',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć notatkę "${note.title}"?',
          style: TextStyle(color: AppThemePro.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppThemePro.textSecondary,
            ),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusError,
              foregroundColor: AppThemePro.textPrimary,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notesService.deleteNote(note.id, widget.clientId);
      if (mounted) {
        _loadNotes();
      }
    }
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return AppThemePro.statusSuccess;
      case NotePriority.normal:
        return AppThemePro.statusInfo;
      case NotePriority.high:
        return AppThemePro.statusWarning;
      case NotePriority.urgent:
        return AppThemePro.statusError;
    }
  }

  Widget _getCategoryIcon(NoteCategory category, {double size = 20}) {
    IconData iconData;
    Color iconColor;

    switch (category) {
      case NoteCategory.general:
        iconData = Icons.description_outlined;
        iconColor = AppThemePro.textSecondary;
        break;
      case NoteCategory.contact:
        iconData = Icons.contact_phone_outlined;
        iconColor = AppThemePro.statusInfo;
        break;
      case NoteCategory.investment:
        iconData = Icons.trending_up_rounded;
        iconColor = AppThemePro.profitGreen;
        break;
      case NoteCategory.meeting:
        iconData = Icons.meeting_room_outlined;
        iconColor = AppThemePro.statusWarning;
        break;
      case NoteCategory.important:
        iconData = Icons.priority_high_rounded;
        iconColor = AppThemePro.statusError;
        break;
      case NoteCategory.reminder:
        iconData = Icons.notification_important_outlined;
        iconColor = AppThemePro.accentGold;
        break;
    }

    return Icon(iconData, color: iconColor, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemePro.premiumCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profesjonalny nagłówek
            _buildProfessionalHeader(),
            const SizedBox(height: 24),

            // Zwijane filtry i wyszukiwanie z animacją
            _buildCollapsibleFilters(),

            // Lista notatek lub stan pusty
            Expanded(child: _buildNotesContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleFilters() {
    return Column(
      children: [
        // Zawsze widoczny pasek z miniaturką wyszukiwania i przyciskiem rozwijania
        _buildCompactSearchBar(),
        
        // Rozwijalne filtry
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isSearchBarVisible ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isSearchBarVisible ? 1.0 : 0.0,
            child: _isSearchBarVisible 
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildAdvancedFilters(),
                  ],
                )
              : const SizedBox.shrink(),
          ),
        ),
        
        SizedBox(height: _isSearchBarVisible ? 20 : 12),
      ],
    );
  }

  Widget _buildCompactSearchBar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: !_isSearchBarVisible ? () {
          setState(() {
            _isSearchBarVisible = true;
          });
        } : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemePro.accentGold.withOpacity(0.1),
                AppThemePro.accentGold.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: _isSearchBarVisible 
                  ? Text(
                      'Wyszukaj notatki...',
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Text(
                      _searchController.text.isEmpty 
                        ? 'Stuknij aby wyszukać...'
                        : 'Szukasz: "${_searchController.text}"',
                      style: TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
              
              // Informacja o filtrach aktywnych
              if (!_isSearchBarVisible && (_selectedCategory != null || _selectedPriority != null))
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_selectedCategory != null ? 1 : 0) + (_selectedPriority != null ? 1 : 0)}',
                    style: TextStyle(
                      color: AppThemePro.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Przycisk rozwijania/zwijania
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _isSearchBarVisible = !_isSearchBarVisible;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isSearchBarVisible ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemePro.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.sticky_note_2_outlined,
            color: AppThemePro.accentGold,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notatki klienta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredNotes.length} z ${_notes.length} notatek',
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemePro.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isReadOnly)
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showNoteDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppThemePro.primaryDark,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Nowa notatka',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        children: [
          // Wyszukiwanie
          Container(
            decoration: BoxDecoration(
              color: AppThemePro.surfaceInteractive,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Wyszukaj w tytule, treści lub tagach...',
                hintStyle: TextStyle(
                  color: AppThemePro.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppThemePro.accentGold,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppThemePro.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          if (mounted) {
                            _filterNotes();
                          }
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (_) {
                if (mounted) {
                  _filterNotes();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Filtry kategorii i priorytetu
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<NoteCategory?>(
                  value: _selectedCategory,
                  hint: 'Wszystkie kategorie',
                  icon: Icons.category_outlined,
                  items: [
                    DropdownMenuItem<NoteCategory?>(
                      value: null,
                      child: Text(
                        'Wszystkie kategorie',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...NoteCategory.values.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            _getCategoryIcon(category, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              category.displayName,
                              style: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedCategory = value);
                      _filterNotes();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown<NotePriority?>(
                  value: _selectedPriority,
                  hint: 'Wszystkie priorytety',
                  icon: Icons.flag_outlined,
                  items: [
                    DropdownMenuItem<NotePriority?>(
                      value: null,
                      child: Text(
                        'Wszystkie priorytety',
                        style: TextStyle(
                          color: AppThemePro.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...NotePriority.values.map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priority.displayName,
                              style: TextStyle(
                                color: AppThemePro.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedPriority = value);
                      _filterNotes();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceInteractive,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Row(
          children: [
            Icon(icon, color: AppThemePro.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              hint,
              style: TextStyle(color: AppThemePro.textMuted, fontSize: 14),
            ),
          ],
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppThemePro.textMuted,
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppThemePro.surfaceElevated,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNotesContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredNotes.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: ListView.separated(
        controller: _scrollController, // Dodano ScrollController
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNotes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return ProfessionalNoteListItem(
            note: note,
            onEdit: widget.isReadOnly ? null : () => _showNoteDialog(note),
            onDelete: widget.isReadOnly ? null : () => _deleteNote(note),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppThemePro.accentGold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ładowanie notatek...',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppThemePro.accentGold.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 48,
                color: AppThemePro.accentGold.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _notes.isEmpty
                  ? 'Brak notatek dla tego klienta'
                  : 'Brak notatek spełniających kryteria wyszukiwania',
              style: TextStyle(
                color: AppThemePro.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _notes.isEmpty
                  ? 'Rozpocznij dodawanie notatek aby śledzić\nważne informacje o kliencie'
                  : 'Spróbuj zmienić kryteria wyszukiwania\nlub filtry kategorii',
              style: TextStyle(
                color: AppThemePro.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_notes.isEmpty && !widget.isReadOnly) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Dodaj pierwszą notatkę',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfessionalNoteListItem extends StatelessWidget {
  final ClientNote note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfessionalNoteListItem({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
  });

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return AppThemePro.statusSuccess;
      case NotePriority.normal:
        return AppThemePro.statusInfo;
      case NotePriority.high:
        return AppThemePro.statusWarning;
      case NotePriority.urgent:
        return AppThemePro.statusError;
    }
  }

  Widget _getCategoryIcon(NoteCategory category) {
    IconData iconData;
    Color iconColor;

    switch (category) {
      case NoteCategory.general:
        iconData = Icons.description_outlined;
        iconColor = AppThemePro.textSecondary;
        break;
      case NoteCategory.contact:
        iconData = Icons.contact_phone_outlined;
        iconColor = AppThemePro.statusInfo;
        break;
      case NoteCategory.investment:
        iconData = Icons.trending_up_rounded;
        iconColor = AppThemePro.profitGreen;
        break;
      case NoteCategory.meeting:
        iconData = Icons.meeting_room_outlined;
        iconColor = AppThemePro.statusWarning;
        break;
      case NoteCategory.important:
        iconData = Icons.priority_high_rounded;
        iconColor = AppThemePro.statusError;
        break;
      case NoteCategory.reminder:
        iconData = Icons.notification_important_outlined;
        iconColor = AppThemePro.accentGold;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek notatki z priorytetem
            Row(
              children: [
                _getCategoryIcon(note.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppThemePro.textPrimary,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                note.priority,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getPriorityColor(
                                  note.priority,
                                ).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              note.priority.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(note.priority),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemePro.surfaceInteractive,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppThemePro.borderSecondary,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              note.category.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppThemePro.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu akcji
                if (onEdit != null || onDelete != null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppThemePro.surfaceInteractive,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppThemePro.borderSecondary,
                        width: 1,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppThemePro.textSecondary,
                        size: 18,
                      ),
                      color: AppThemePro.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppThemePro.borderPrimary,
                          width: 1,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) onEdit!();
                        if (value == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: AppThemePro.accentGold,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edytuj',
                                  style: TextStyle(
                                    color: AppThemePro.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppThemePro.statusError,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Usuń',
                                  style: TextStyle(
                                    color: AppThemePro.statusError,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Treść notatki
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppThemePro.borderPrimary, width: 1),
              ),
              child: Text(
                note.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemePro.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tagi
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: note.tags
                    .take(5) // Limit do 5 tagów
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppThemePro.accentGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppThemePro.accentGold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Metadata - autor i data
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppThemePro.borderPrimary, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: AppThemePro.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    note.authorName,
                    style: TextStyle(
                      color: AppThemePro.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    color: AppThemePro.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                    style: TextStyle(
                      color: AppThemePro.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (note.updatedAt != note.createdAt) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.edit_outlined,
                      color: AppThemePro.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(note.updatedAt),
                      style: TextStyle(
                        color: AppThemePro.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalNoteEditDialog extends StatefulWidget {
  final ClientNote? note;
  final String clientId;
  final String currentUserId;
  final String currentUserName;

  const ProfessionalNoteEditDialog({
    super.key,
    this.note,
    required this.clientId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ProfessionalNoteEditDialog> createState() =>
      _ProfessionalNoteEditDialogState();
}

class _ProfessionalNoteEditDialogState
    extends State<ProfessionalNoteEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  late NoteCategory _selectedCategory;
  late NotePriority _selectedPriority;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagsController = TextEditingController(text: note?.tags.join(', ') ?? '');
    _selectedCategory = note?.category ?? NoteCategory.general;
    _selectedPriority = note?.priority ?? NotePriority.normal;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String tagsText) {
    return tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Widget _getCategoryIcon(NoteCategory category) {
    IconData iconData;
    Color iconColor;

    switch (category) {
      case NoteCategory.general:
        iconData = Icons.description_outlined;
        iconColor = AppThemePro.textSecondary;
        break;
      case NoteCategory.contact:
        iconData = Icons.contact_phone_outlined;
        iconColor = AppThemePro.statusInfo;
        break;
      case NoteCategory.investment:
        iconData = Icons.trending_up_rounded;
        iconColor = AppThemePro.profitGreen;
        break;
      case NoteCategory.meeting:
        iconData = Icons.meeting_room_outlined;
        iconColor = AppThemePro.statusWarning;
        break;
      case NoteCategory.important:
        iconData = Icons.priority_high_rounded;
        iconColor = AppThemePro.statusError;
        break;
      case NoteCategory.reminder:
        iconData = Icons.notification_important_outlined;
        iconColor = AppThemePro.accentGold;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return AppThemePro.statusSuccess;
      case NotePriority.normal:
        return AppThemePro.statusInfo;
      case NotePriority.high:
        return AppThemePro.statusWarning;
      case NotePriority.urgent:
        return AppThemePro.statusError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppThemePro.backgroundModal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppThemePro.borderPrimary, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profesjonalny nagłówek
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppThemePro.primaryDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppThemePro.accentGold.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppThemePro.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppThemePro.accentGold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.note == null
                            ? Icons.note_add_outlined
                            : Icons.edit_note_outlined,
                        color: AppThemePro.accentGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.note == null
                                ? 'Nowa notatka'
                                : 'Edytuj notatkę',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppThemePro.textPrimary,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.note == null
                                ? 'Dodaj nową notatkę dla klienta'
                                : 'Modyfikuj istniejącą notatkę',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppThemePro.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppThemePro.surfaceInteractive,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppThemePro.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Formularz
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tytuł notatki
                      _buildFormField(
                        label: 'Tytuł notatki',
                        isRequired: true,
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Wprowadź tytuł notatki...',
                            prefixIcon: Icons.title_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tytuł jest wymagany';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Kategoria i priorytet
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: 'Kategoria',
                              child: DropdownButtonFormField<NoteCategory>(
                                value: _selectedCategory,
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'Wybierz kategorię',
                                  prefixIcon: Icons.category_outlined,
                                ),
                                dropdownColor: AppThemePro.surfaceElevated,
                                items: NoteCategory.values.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      children: [
                                        _getCategoryIcon(category),
                                        const SizedBox(width: 12),
                                        Text(
                                          category.displayName,
                                          style: TextStyle(
                                            color: AppThemePro.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedCategory = value);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              label: 'Priorytet',
                              child: DropdownButtonFormField<NotePriority>(
                                value: _selectedPriority,
                                style: TextStyle(
                                  color: AppThemePro.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'Wybierz priorytet',
                                  prefixIcon: Icons.flag_outlined,
                                ),
                                dropdownColor: AppThemePro.surfaceElevated,
                                items: NotePriority.values.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(priority),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          priority.displayName,
                                          style: TextStyle(
                                            color: AppThemePro.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedPriority = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Treść notatki
                      _buildFormField(
                        label: 'Treść notatki',
                        isRequired: true,
                        child: TextFormField(
                          controller: _contentController,
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Wprowadź szczegółową treść notatki...',
                            prefixIcon: Icons.description_outlined,
                            alignLabelWithHint: true,
                          ),
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Treść jest wymagana';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tagi
                      _buildFormField(
                        label: 'Tagi',
                        child: TextFormField(
                          controller: _tagsController,
                          style: TextStyle(
                            color: AppThemePro.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _buildInputDecoration(
                            hintText:
                                'np. ważne, kontakt, spotkanie (oddzielone przecinkami)',
                            prefixIcon: Icons.local_offer_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Przyciski akcji
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundSecondary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: AppThemePro.borderPrimary, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppThemePro.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemePro.accentGold,
                            AppThemePro.accentGoldMuted,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemePro.accentGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final now = DateTime.now();
                            final note = ClientNote(
                              id: widget.note?.id ?? '',
                              clientId: widget.clientId,
                              title: _titleController.text.trim(),
                              content: _contentController.text.trim(),
                              category: _selectedCategory,
                              priority: _selectedPriority,
                              authorId: widget.currentUserId,
                              authorName: widget.currentUserName,
                              createdAt: widget.note?.createdAt ?? now,
                              updatedAt: now,
                              tags: _parseTags(_tagsController.text),
                            );
                            Navigator.of(context).pop(note);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppThemePro.primaryDark,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          widget.note == null ? Icons.add : Icons.save,
                          size: 18,
                        ),
                        label: Text(
                          widget.note == null
                              ? 'Dodaj notatkę'
                              : 'Zapisz zmiany',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textSecondary,
              letterSpacing: 0.1,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppThemePro.statusError),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppThemePro.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppThemePro.accentGold.withOpacity(0.7),
        size: 20,
      ),
      filled: true,
      fillColor: AppThemePro.surfaceInteractive,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemePro.borderPrimary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemePro.borderPrimary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemePro.accentGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemePro.statusError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemePro.statusError, width: 2),
      ),
      errorStyle: TextStyle(
        color: AppThemePro.statusError,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

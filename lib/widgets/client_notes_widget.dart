import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models_and_services.dart';

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
  List<ClientNote> _notes = [];
  List<ClientNote> _filteredNotes = [];
  bool _isLoading = false;
  NoteCategory? _selectedCategory;
  NotePriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await _notesService.getClientNotes(widget.clientId);
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();

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
      builder: (context) => NoteEditDialog(
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
      _loadNotes();
    }
  }

  Future<void> _deleteNote(ClientNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuwanie notatki'),
        content: Text('Czy na pewno chcesz usunąć notatkę "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notesService.deleteNote(note.id, widget.clientId);
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek
            Row(
              children: [
                const Icon(Icons.note),
                const SizedBox(width: 8),
                Text(
                  'Notatki o kliencie',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    onPressed: () => _showNoteDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj notatkę'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtry i wyszukiwanie
            Row(
              children: [
                // Wyszukiwanie
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Szukaj w notatkach...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _filterNotes(),
                  ),
                ),
                const SizedBox(width: 8),

                // Filtr kategorii
                DropdownButton<NoteCategory?>(
                  value: _selectedCategory,
                  hint: const Text('Kategoria'),
                  items: [
                    const DropdownMenuItem<NoteCategory?>(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    ...NoteCategory.values.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _filterNotes();
                  },
                ),
                const SizedBox(width: 8),

                // Filtr priorytetu
                DropdownButton<NotePriority?>(
                  value: _selectedPriority,
                  hint: const Text('Priorytet'),
                  items: [
                    const DropdownMenuItem<NotePriority?>(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    ...NotePriority.values.map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPriority = value);
                    _filterNotes();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista notatek
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredNotes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _notes.isEmpty
                          ? 'Brak notatek dla tego klienta'
                          : 'Brak notatek spełniających kryteria wyszukiwania',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    return NoteListItem(
                      note: note,
                      onEdit: widget.isReadOnly
                          ? null
                          : () => _showNoteDialog(note),
                      onDelete: widget.isReadOnly
                          ? null
                          : () => _deleteNote(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NoteListItem extends StatelessWidget {
  final ClientNote note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoteListItem({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
  });

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return Colors.green;
      case NotePriority.normal:
        return Colors.blue;
      case NotePriority.high:
        return Colors.orange;
      case NotePriority.urgent:
        return Colors.red;
    }
  }

  Icon _getCategoryIcon(NoteCategory category) {
    switch (category) {
      case NoteCategory.general:
        return const Icon(Icons.note);
      case NoteCategory.contact:
        return const Icon(Icons.contact_phone);
      case NoteCategory.investment:
        return const Icon(Icons.trending_up);
      case NoteCategory.meeting:
        return const Icon(Icons.meeting_room);
      case NoteCategory.important:
        return const Icon(Icons.priority_high);
      case NoteCategory.reminder:
        return const Icon(Icons.notification_important);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek notatki
            Row(
              children: [
                _getCategoryIcon(note.category),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Priorytet
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      note.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(note.priority),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    note.priority.displayName,
                    style: TextStyle(
                      color: _getPriorityColor(note.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Akcje
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) onEdit!();
                      if (value == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edytuj'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Usuń', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Treść notatki
            Text(note.content, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),

            // Tagi
            if (note.tags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                children: note.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Metadata
            Row(
              children: [
                Text(
                  note.category.displayName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Text(' • '),
                Text(
                  'Autor: ${note.authorName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Text(' • '),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (note.updatedAt != note.createdAt) ...[
                  const Text(' • '),
                  Text(
                    'Edytowano: ${DateFormat('dd.MM.yyyy HH:mm').format(note.updatedAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoteEditDialog extends StatefulWidget {
  final ClientNote? note;
  final String clientId;
  final String currentUserId;
  final String currentUserName;

  const NoteEditDialog({
    super.key,
    this.note,
    required this.clientId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<NoteEditDialog> {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek
              Text(
                widget.note == null ? 'Nowa notatka' : 'Edytuj notatkę',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Tytuł
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł notatki *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tytuł jest wymagany';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategoria i priorytet
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<NoteCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategoria',
                        border: OutlineInputBorder(),
                      ),
                      items: NoteCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<NotePriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priorytet',
                        border: OutlineInputBorder(),
                      ),
                      items: NotePriority.values
                          .map(
                            (priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Treść
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Treść notatki *',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),

              // Tagi
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tagi (oddzielone przecinkami)',
                  border: OutlineInputBorder(),
                  hintText: 'np. ważne, kontakt, spotkanie',
                ),
              ),
              const SizedBox(height: 24),

              // Przyciski
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
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
                    child: Text(widget.note == null ? 'Dodaj' : 'Zapisz'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

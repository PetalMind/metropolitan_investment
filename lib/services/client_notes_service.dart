import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_note.dart';
import 'base_service.dart';

class ClientNotesService extends BaseService {
  static final ClientNotesService _instance = ClientNotesService._internal();
  factory ClientNotesService() => _instance;
  ClientNotesService._internal();

  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'client_notes',
  );

  // Cache notatek klienta
  final Map<String, List<ClientNote>> _clientNotesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Pobiera wszystkie notatki dla danego klienta
  Future<List<ClientNote>> getClientNotes(String clientId) async {
    // Sprawdź cache
    if (_clientNotesCache.containsKey(clientId) &&
        _cacheTimestamps.containsKey(clientId) &&
        DateTime.now().difference(_cacheTimestamps[clientId]!) < _cacheExpiry) {
      return _clientNotesCache[clientId]!;
    }

    try {
      final querySnapshot = await _collection
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final notes = querySnapshot.docs
          .map((doc) => ClientNote.fromFirestore(doc))
          .toList();

      // Zaktualizuj cache
      _clientNotesCache[clientId] = notes;
      _cacheTimestamps[clientId] = DateTime.now();

      return notes;
    } catch (e) {
      logError('Błąd podczas pobierania notatek klienta $clientId', e);
      return [];
    }
  }

  /// Dodaje nową notatkę
  Future<String?> addNote(ClientNote note) async {
    try {
      final docRef = await _collection.add(note.toFirestore());

      // Wyczyść cache dla tego klienta
      _clientNotesCache.remove(note.clientId);
      _cacheTimestamps.remove(note.clientId);

      return docRef.id;
    } catch (e) {
      logError('Błąd podczas dodawania notatki', e);
      return null;
    }
  }

  /// Aktualizuje notatkę
  Future<bool> updateNote(ClientNote note) async {
    try {
      await _collection.doc(note.id).update(note.toFirestore());

      // Wyczyść cache dla tego klienta
      _clientNotesCache.remove(note.clientId);
      _cacheTimestamps.remove(note.clientId);

      return true;
    } catch (e) {
      logError('Błąd podczas aktualizacji notatki ${note.id}', e);
      return false;
    }
  }

  /// Usuwa notatkę (soft delete)
  Future<bool> deleteNote(String noteId, String clientId) async {
    try {
      await _collection.doc(noteId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Wyczyść cache dla tego klienta
      _clientNotesCache.remove(clientId);
      _cacheTimestamps.remove(clientId);

      return true;
    } catch (e) {
      logError('Błąd podczas usuwania notatki $noteId', e);
      return false;
    }
  }

  /// Pobiera notatkę po ID
  Future<ClientNote?> getNoteById(String noteId) async {
    try {
      final doc = await _collection.doc(noteId).get();
      if (!doc.exists) return null;

      return ClientNote.fromFirestore(doc);
    } catch (e) {
      logError('Błąd podczas pobierania notatki $noteId', e);
      return null;
    }
  }

  /// Wyszukuje notatki po treści
  Future<List<ClientNote>> searchNotes(String clientId, String query) async {
    try {
      final allNotes = await getClientNotes(clientId);

      final lowerQuery = query.toLowerCase();
      return allNotes
          .where(
            (note) =>
                note.title.toLowerCase().contains(lowerQuery) ||
                note.content.toLowerCase().contains(lowerQuery) ||
                note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)),
          )
          .toList();
    } catch (e) {
      logError('Błąd podczas wyszukiwania notatek', e);
      return [];
    }
  }

  /// Pobiera notatki według kategorii
  Future<List<ClientNote>> getNotesByCategory(
    String clientId,
    NoteCategory category,
  ) async {
    try {
      final allNotes = await getClientNotes(clientId);
      return allNotes.where((note) => note.category == category).toList();
    } catch (e) {
      logError('Błąd podczas pobierania notatek według kategorii', e);
      return [];
    }
  }

  /// Pobiera notatki według priorytetu
  Future<List<ClientNote>> getNotesByPriority(
    String clientId,
    NotePriority priority,
  ) async {
    try {
      final allNotes = await getClientNotes(clientId);
      return allNotes.where((note) => note.priority == priority).toList();
    } catch (e) {
      logError('Błąd podczas pobierania notatek według priorytetu', e);
      return [];
    }
  }

  /// Czyści cache dla konkretnego klienta
  @override
  void clearCache(String clientId) {
    _clientNotesCache.remove(clientId);
    _cacheTimestamps.remove(clientId);
  }

  /// Czyści cały cache
  @override
  void clearAllCache() {
    _clientNotesCache.clear();
    _cacheTimestamps.clear();
  }
}

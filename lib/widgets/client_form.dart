import 'package:flutter/material.dart';
import '../models_and_services.dart';
import 'client_notes_widget.dart';
import 'optimized_voting_status_widget.dart';

class ClientForm extends StatefulWidget {
  final Client? client;
  final void Function(Client client) onSave;
  final VoidCallback? onCancel;

  const ClientForm({
    super.key,
    this.client,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final UnifiedVotingStatusService _votingService =
      UnifiedVotingStatusService();
  late String _name;
  late String _email;
  late String _phone;
  late String _address;
  String? _pesel;
  String? _companyName;
  ClientType _type = ClientType.individual;
  String _notes = '';
  VotingStatus _votingStatus = VotingStatus.undecided;
  String _colorCode = '#FFFFFF';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _name = c?.name ?? '';
    _email = c?.email ?? '';
    _phone = c?.phone ?? '';
    _address = c?.address ?? '';
    _pesel = c?.pesel;
    _companyName = c?.companyName;
    _type = c?.type ?? ClientType.individual;
    _notes = c?.notes ?? '';
    _votingStatus = c?.votingStatus ?? VotingStatus.undecided;
    _colorCode = c?.colorCode ?? '#FFFFFF';
    _isActive = c?.isActive ?? true;
  }

  /// Obsługuje zapisywanie zmian z historią głosowania
  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      _formKey.currentState?.save();

      final newClient = Client(
        id: widget.client?.id ?? '',
        name: _name,
        email: _email,
        phone: _phone,
        address: _address,
        pesel: _pesel,
        companyName: _companyName,
        type: _type,
        notes: _notes,
        votingStatus: _votingStatus,
        colorCode: _colorCode,
        unviableInvestments: widget.client?.unviableInvestments ?? [],
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
      );

      // Jeśli to edycja istniejącego klienta i status głosowania się zmienił
      if (widget.client != null &&
          widget.client!.votingStatus != _votingStatus) {
        print(
          '🗳️ [ClientForm] Status głosowania zmieniony: ${widget.client!.votingStatus.name} -> ${_votingStatus.name}',
        );

        // Zapisz zmianę statusu przez UnifiedVotingStatusService
        await _votingService.updateVotingStatus(
          widget.client!.id,
          _votingStatus,
          reason: 'Updated via client form',
          editedBy: 'Client Form',
          editedByEmail: 'system@client-form.local',
          updatedVia: 'client_form',
        );

        print('✅ [ClientForm] Historia głosowania zapisana');
      }

      widget.onSave(newClient);
    } catch (e) {
      print('❌ [ClientForm] Błąd podczas zapisywania: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nazwa/Imię i nazwisko (zapisywane jako fullName w Firebase)
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Imię i nazwisko / Nazwa',
                helperText: 'Zapisywane jako "fullName" w Firebase',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 12),

            // Typ klienta
            DropdownButtonFormField<ClientType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Typ klienta'),
              items: ClientType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Nieprawidłowy format email';
                }
                return null;
              },
              onSaved: (v) => _email = v ?? '',
            ),
            const SizedBox(height: 12),

            // Telefon
            TextFormField(
              initialValue: _phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
              onSaved: (v) => _phone = v ?? '',
            ),
            const SizedBox(height: 12),

            // Adres
            TextFormField(
              initialValue: _address,
              decoration: const InputDecoration(labelText: 'Adres'),
              maxLines: 2,
              onSaved: (v) => _address = v ?? '',
            ),
            const SizedBox(height: 12),

            // PESEL (dla osób fizycznych)
            if (_type == ClientType.individual ||
                _type == ClientType.marriage) ...[
              TextFormField(
                initialValue: _pesel,
                decoration: const InputDecoration(labelText: 'PESEL'),
                keyboardType: TextInputType.number,
                maxLength: 11,
                onSaved: (v) => _pesel = v?.isNotEmpty == true ? v : null,
              ),
              const SizedBox(height: 12),
            ],

            // Nazwa firmy (dla spółek)
            if (_type == ClientType.company) ...[
              TextFormField(
                initialValue: _companyName,
                decoration: const InputDecoration(labelText: 'Nazwa firmy'),
                onSaved: (v) => _companyName = v?.isNotEmpty == true ? v : null,
              ),
              const SizedBox(height: 12),
            ],

            // Status głosowania - ZOPTYMALIZOWANY
            const SizedBox(height: 12),
            Text(
              'Status głosowania',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            OptimizedVotingStatusSelector(
              currentStatus: _votingStatus,
              onStatusChanged: (status) {
                setState(() {
                  _votingStatus = status;
                });
              },
              isCompact: false,
              showLabels: true,
              clientName: _name.isNotEmpty ? _name : null,
            ),
            const SizedBox(height: 12),

            // Notatki - Stary system (zachowujemy dla kompatybilności)
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notatki podstawowe',
                hintText: 'Podstawowe informacje o kliencie...',
                helperText:
                    'Krótka notatka zapisana bezpośrednio w profilu klienta',
              ),
              maxLines: 2,
              onSaved: (v) => _notes = v ?? '',
            ),
            const SizedBox(height: 24),

            // Notatki zaawansowane - nowy system
            if (widget.client != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Notatki szczegółowe',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaawansowany system notatek z kategoriami, priorytetami i historią zmian.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 400,
                child: ClientNotesWidget(
                  clientId: widget.client!.id,
                  clientName: widget.client!.name,
                  currentUserId: 'current_user', // TODO: Pobierz z AuthProvider
                  currentUserName:
                      'Bieżący użytkownik', // TODO: Pobierz z AuthProvider
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Kolor (opcjonalnie możemy dodać selektor kolorów)
            Row(
              children: [
                Text(
                  'Kolor oznaczenia:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                ...['#FFFFFF', '#E8F5E8', '#FFE8E8', '#E8E8FF', '#FFF8E8'].map(
                  (color) => GestureDetector(
                    onTap: () => setState(() => _colorCode = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('0xFF${color.replaceAll('#', '')}'),
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _colorCode == color
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: _colorCode == color ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status aktywności
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Aktywny'),
              subtitle: const Text('Czy klient jest aktywny w systemie'),
            ),

            const SizedBox(height: 24),

            // Przyciski akcji
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    child: const Text('Anuluj'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.client == null ? 'Dodaj' : 'Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

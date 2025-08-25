import 'package:flutter/material.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';
import 'client_notes_widget.dart';
import 'email_history_widget.dart';
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
              const SizedBox(height: 8),
              Container(
                decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemePro.accentGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppThemePro.accentGold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.sticky_note_2_rounded,
                            color: AppThemePro.accentGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notatki szczegółowe',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppThemePro.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Zaawansowany system notatek z kategoriami, priorytetami i historią zmian',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppThemePro.borderPrimary,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ClientNotesWidget(
                          clientId: widget.client!.id,
                          clientName: widget.client!.name,
                          currentUserId:
                              'current_user', // TODO: Pobierz z AuthProvider
                          currentUserName:
                              'Bieżący użytkownik', // TODO: Pobierz z AuthProvider
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Historia emaili - nowa sekcja
            if (widget.client != null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemePro.accentGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppThemePro.accentGold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.email_rounded,
                            color: AppThemePro.accentGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Historia emaili',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppThemePro.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Kompletna historia wysłanych emaili do tego klienta',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppThemePro.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppThemePro.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppThemePro.borderPrimary,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: EmailHistoryWidget(
                          clientId: widget.client!.id,
                          isCompact: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Kolor oznaczenia - profesjonalny selektor
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.palette_rounded,
                          color: AppThemePro.accentGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Kolor oznaczenia klienta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppThemePro.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children:
                        [
                              '#FFFFFF',
                              '#E8F5E8',
                              '#FFE8E8',
                              '#E8E8FF',
                              '#FFF8E8',
                              '#F0E8FF',
                              '#E8FFFF',
                            ]
                            .map(
                              (color) => GestureDetector(
                                onTap: () => setState(() => _colorCode = color),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        '0xFF${color.replaceAll('#', '')}',
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _colorCode == color
                                          ? AppThemePro.accentGold
                                          : AppThemePro.borderSecondary,
                                      width: _colorCode == color ? 3 : 1,
                                    ),
                                    boxShadow: _colorCode == color
                                        ? [
                                            BoxShadow(
                                              color: AppThemePro.accentGold
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: _colorCode == color
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: AppThemePro.primaryDark,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status aktywności - profesjonalny przełącznik
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? AppThemePro.statusSuccess.withOpacity(0.1)
                          : AppThemePro.statusError.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isActive
                          ? AppThemePro.statusSuccess
                          : AppThemePro.statusError,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status aktywności',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppThemePro.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isActive
                              ? 'Klient jest aktywny w systemie'
                              : 'Klient jest nieaktywny w systemie',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppThemePro.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: AppThemePro.statusSuccess,
                    activeTrackColor: AppThemePro.statusSuccess.withOpacity(
                      0.3,
                    ),
                    inactiveThumbColor: AppThemePro.statusError,
                    inactiveTrackColor: AppThemePro.statusError.withOpacity(
                      0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profesjonalne przyciski akcji
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemePro.borderPrimary, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onCancel != null) ...[
                    // Przycisk anuluj
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemePro.surfaceInteractive,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppThemePro.borderSecondary,
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _isLoading ? null : widget.onCancel,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Anuluj',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Przycisk zapisz/dodaj
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [
                                AppThemePro.surfaceInteractive,
                                AppThemePro.surfaceInteractive,
                              ]
                            : [
                                AppThemePro.accentGold,
                                AppThemePro.accentGoldDark,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_isLoading
                          ? [
                              BoxShadow(
                                color: AppThemePro.accentGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: _isLoading
                            ? AppThemePro.textMuted
                            : AppThemePro.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppThemePro.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Zapisywanie...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              widget.client == null
                                  ? Icons.person_add_rounded
                                  : Icons.save_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.client == null
                                  ? 'Dodaj Klienta'
                                  : 'Zapisz Zmiany',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

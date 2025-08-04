import 'package:flutter/material.dart';
import '../widgets/client_form.dart';
import '../models_and_services.dart';

class ClientNotesDemo extends StatefulWidget {
  const ClientNotesDemo({super.key});

  @override
  State<ClientNotesDemo> createState() => _ClientNotesDemoState();
}

class _ClientNotesDemoState extends State<ClientNotesDemo> {
  Client? _selectedClient;

  // Przykładowy klient do demonstracji
  final Client _demoClient = Client(
    id: 'demo-client-123',
    name: 'Jan Kowalski',
    email: 'jan.kowalski@example.com',
    phone: '+48 123 456 789',
    address: 'ul. Przykładowa 1, 00-001 Warszawa',
    pesel: '80010112345',
    type: ClientType.individual,
    notes: 'Stary system notatek - przykładowa notatka',
    votingStatus: VotingStatus.undecided,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _selectedClient = _demoClient;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Nowy system notatek'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informacje o nowej funkcjonalności
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Nowy system notatek o klientach',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ulepszona funkcjonalność notatek zawiera:',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 8),
                    ...const [
                      '• Kategorie notatek (Ogólne, Kontakt, Inwestycje, Spotkanie, Ważne, Przypomnienie)',
                      '• Priorytety (Niska, Normalna, Wysoka, Pilna)',
                      '• System tagów dla lepszej organizacji',
                      '• Historia utworzenia i modyfikacji',
                      '• Wyszukiwanie w treści notatek',
                      '• Filtrowanie według kategorii i priorytetu',
                      '• Informacje o autorze notatki',
                    ].map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text(
                          text,
                          style: TextStyle(color: Colors.blue.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formularz klienta z nowym systemem notatek
            Expanded(
              child: ClientForm(
                client: _selectedClient,
                onSave: (Client updatedClient) {
                  setState(() {
                    _selectedClient = updatedClient;
                  });

                  // Pokaż potwierdzenie
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dane klienta "${updatedClient.name}" zostały zaktualizowane',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onCancel: () {
                  // Opcjonalnie - cofnij zmiany
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

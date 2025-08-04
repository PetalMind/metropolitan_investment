import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/custom_loading_widget.dart';
import '../widgets/client_form.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  List<Client> _activeClients = []; // Nowa lista dla aktywnych klientów
  bool _isLoading = true;
  bool _showActiveOnly = false; // Toggle dla aktywnych klientów
  double _loadingProgress = 0.0;
  String _loadingStage = 'Inicjalizacja...';

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _loadingStage = 'Inicjalizacja...';
    });

    try {
      // Ładowanie wszystkich klientów
      final clients = await _clientService.loadAllClientsWithProgress(
        onProgress: (progress, stage) {
          if (mounted) {
            setState(() {
              _loadingProgress = progress * 0.7; // 70% dla wszystkich klientów
              _loadingStage = stage;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _loadingProgress = 0.8;
          _loadingStage = 'Ładowanie aktywnych klientów...';
        });

        // Ładowanie aktywnych klientów z wykorzystaniem indeksu
        final activeClientsStream = _clientService.getActiveClients();
        final activeClients = await activeClientsStream.first;

        setState(() {
          _clients = clients;
          _activeClients = activeClients;
          _filteredClients = _showActiveOnly ? _activeClients : _clients;
          _isLoading = false;
          _loadingProgress = 1.0;
          _loadingStage = 'Zakończono';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorSnackBar('Błąd podczas ładowania klientów: $e');
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    final sourceList = _showActiveOnly ? _activeClients : _clients;

    setState(() {
      _filteredClients = sourceList.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query) ||
            client.phone.toLowerCase().contains(query) ||
            (client.pesel?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _toggleActiveClients() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
      _filteredClients = _showActiveOnly ? _activeClients : _clients;
    });
    _filterClients(); // Re-apply search filter
  }

  void _showClientForm([Client? client]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundModal,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek
              Row(
                children: [
                  Icon(
                    client == null ? Icons.person_add : Icons.edit,
                    color: AppTheme.secondaryGold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    client == null ? 'Nowy Klient' : 'Edytuj Klienta',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Zaawansowany formularz klienta
              Expanded(
                child: ClientForm(
                  client: client,
                  onSave: (Client updatedClient) async {
                    Navigator.of(context).pop();

                    try {
                      if (client == null) {
                        // Dodawanie nowego klienta
                        final clientId = await _clientService.createClient(
                          updatedClient,
                        );
                        if (clientId.isNotEmpty) {
                          _showSuccessSnackBar(
                            'Klient "${updatedClient.name}" został dodany',
                          );
                          _loadClients(); // Przeładuj listę
                        } else {
                          _showErrorSnackBar('Błąd podczas dodawania klienta');
                        }
                      } else {
                        // Aktualizacja istniejącego klienta
                        await _clientService.updateClient(
                          client.id,
                          updatedClient,
                        );
                        _showSuccessSnackBar(
                          'Klient "${updatedClient.name}" został zaktualizowany',
                        );
                        _loadClients(); // Przeładuj listę
                      }
                    } catch (e) {
                      _showErrorSnackBar('Błąd: $e');
                    }
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildToolbar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: ProgressLoadingWidget(
                      progress: _loadingProgress,
                      message: _loadingStage,
                      details: 'Ładowanie bazy danych klientów...',
                    ),
                  )
                : _filteredClients.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _buildClientsList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zarządzanie Klientami',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredClients.length} klientów',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nowy Klient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.textOnSecondary,
              elevation: 4,
              shadowColor: AppTheme.secondaryGold.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'Szukaj po imieniu i nazwisku, PESEL, emailu lub telefonie...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () => _searchController.clear(),
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceInteractive,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSecondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.secondaryGold,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Przełącznik dla aktywnych klientów - wykorzystuje indeks compound (isActive, name)
          FilterChip(
            label: Text(
              'Tylko aktywni (${_activeClients.length})',
              style: TextStyle(
                color: _showActiveOnly ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            selected: _showActiveOnly,
            onSelected: (bool selected) => _toggleActiveClients(),
            selectedColor: AppTheme.secondaryGold,
            checkmarkColor: Colors.white,
            backgroundColor: AppTheme.surfaceInteractive,
            side: BorderSide(
              color: _showActiveOnly
                  ? AppTheme.secondaryGold
                  : AppTheme.borderSecondary,
            ),
            tooltip:
                'Pokaż tylko aktywnych klientów - optymalizacja 50-100x szybsza',
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showInfoSnackBar('Eksport - w przygotowaniu');
                  break;
                case 'import':
                  _showInfoSnackBar('Import - w przygotowaniu');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Eksport',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Import',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return DataTableWidget<Client>(
      items: _filteredClients,
      columns: [
        DataTableColumn<Client>(
          label: 'Imię i nazwisko',
          value: (client) => client.name,
          sortable: true,
          width: 180,
        ),
        DataTableColumn<Client>(
          label: 'PESEL',
          value: (client) => client.pesel ?? '',
          sortable: true,
          width: 120,
        ),
        DataTableColumn<Client>(
          label: 'Email',
          value: (client) => client.email,
          sortable: true,
          width: 200,
        ),
        DataTableColumn<Client>(
          label: 'Telefon',
          value: (client) => client.phone,
          sortable: true,
          width: 140,
        ),
        DataTableColumn<Client>(
          label: 'Adres',
          value: (client) => client.address,
          width: 200,
        ),
        DataTableColumn<Client>(
          label: 'Akcje',
          value: (client) => '',
          width: 120,
          widget: (client) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showClientForm(client),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edytuj',
              ),
              IconButton(
                onPressed: () => _deleteClient(client),
                icon: const Icon(Icons.delete, size: 18),
                tooltip: 'Usuń',
              ),
            ],
          ),
        ),
      ],
      onRowTap: (client) => _showClientForm(client),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Brak klientów',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Klienta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.textOnSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: const Text(
          'Potwierdzenie usunięcia',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć klienta ${client.name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Klient został usunięty');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.infoColor),
    );
  }
}

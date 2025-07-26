import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../widgets/data_table_widget.dart';

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
  bool _isLoading = true;

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
    setState(() => _isLoading = true);

    try {
      _clientService.getClients().listen((clients) {
        setState(() {
          _clients = clients;
          _filteredClients = clients;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Błąd podczas ładowania klientów: $e');
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredClients = _clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query) ||
            client.phone.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showClientForm([Client? client]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Nowy Klient' : 'Edytuj Klienta'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nazwa/Imię i nazwisko',
                ),
                initialValue: client?.name ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                initialValue: client?.email ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Telefon'),
                initialValue: client?.phone ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Adres'),
                initialValue: client?.address ?? '',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar(
                client == null
                    ? 'Klient został dodany'
                    : 'Klient został zaktualizowany',
              );
            },
            child: const Text('Zapisz'),
          ),
        ],
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
                ? const Center(child: CircularProgressIndicator())
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
                    color: AppTheme.textOnPrimary.withOpacity(0.8),
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
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj po nazwie, emailu lub telefonie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () => _searchController.clear(),
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
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
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Eksport'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
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
          label: 'Nazwa',
          value: (client) => client.name,
          sortable: true,
        ),
        DataTableColumn<Client>(
          label: 'Email',
          value: (client) => client.email,
          sortable: true,
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
          label: 'Data utworzenia',
          value: (client) => _formatDate(client.createdAt),
          sortable: true,
          width: 120,
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
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Brak klientów',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodaj pierwszego klienta, aby rozpocząć',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj Klienta'),
          ),
        ],
      ),
    );
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: Text('Czy na pewno chcesz usunąć klienta ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Klient został usunięty');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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

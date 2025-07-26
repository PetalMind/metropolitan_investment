import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/company_form.dart';
import '../widgets/animated_button.dart';
import '../theme/app_theme.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final CompanyService _companyService = CompanyService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }

  void _showCompanyForm({Company? company}) {
    showDialog(
      context: context,
      builder: (context) => CompanyForm(company: company),
    );
  }

  void _deleteCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń firmę'),
        content: Text('Czy na pewno chcesz usunąć firmę "${company.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _companyService.deleteCompany(company.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Firma została usunięta'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Błąd podczas usuwania: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  List<Company> _filterAndSortCompanies(List<Company> companies) {
    // Filter
    List<Company> filtered = companies;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = companies.where((company) {
        return company.name.toLowerCase().contains(query) ||
            company.fullName.toLowerCase().contains(query) ||
            company.taxId.toLowerCase().contains(query) ||
            company.email.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'fullName':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'taxId':
          comparison = a.taxId.compareTo(b.taxId);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Zarządzanie spółkami'),
        backgroundColor: AppTheme.backgroundSecondary,
        actions: [
          AnimatedButton(
            onPressed: () => _showCompanyForm(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Dodaj firmę', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundSecondary,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      labelText: 'Szukaj firm',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      hintText: 'Wpisz nazwę, NIP, email...',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortColumn,
                  onChanged: (value) {
                    if (value != null) {
                      _onSort(value, _sortAscending);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Nazwa')),
                    DropdownMenuItem(
                      value: 'fullName',
                      child: Text('Pełna nazwa'),
                    ),
                    DropdownMenuItem(value: 'taxId', child: Text('NIP')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Data utworzenia'),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _onSort(_sortColumn, !_sortAscending),
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),

          // Companies table
          Expanded(
            child: StreamBuilder<List<Company>>(
              stream: _searchQuery.isEmpty
                  ? _companyService.getCompanies()
                  : _companyService.searchCompanies(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryGold,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Błąd podczas wczytywania danych',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Błąd: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  );
                }

                final companies = snapshot.data ?? [];
                final filteredCompanies = _filterAndSortCompanies(companies);

                if (filteredCompanies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Brak firm w systemie'
                              : 'Nie znaleziono firm',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Dodaj pierwszą firmę, aby rozpocząć'
                              : 'Spróbuj zmienić kryteria wyszukiwania',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          AnimatedButton(
                            onPressed: () => _showCompanyForm(),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Dodaj pierwszą firmę',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return DataTableWidget<Company>(
                  items: filteredCompanies,
                  columns: [
                    DataTableColumn<Company>(
                      label: 'Nazwa',
                      value: (company) => company.name,
                      sortable: true,
                      width: 150,
                      widget: (company) => Text(
                        company.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Pełna nazwa',
                      value: (company) => company.fullName,
                      sortable: true,
                      width: 200,
                      widget: (company) => Text(
                        company.fullName.isNotEmpty ? company.fullName : '-',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'NIP',
                      value: (company) => company.taxId,
                      sortable: true,
                      width: 120,
                      widget: (company) => Text(
                        company.taxId.isNotEmpty ? company.taxId : '-',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Email',
                      value: (company) => company.email,
                      sortable: true,
                      width: 180,
                      widget: (company) => Text(
                        company.email.isNotEmpty ? company.email : '-',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Telefon',
                      value: (company) => company.phone,
                      width: 130,
                      widget: (company) => Text(
                        company.phone.isNotEmpty ? company.phone : '-',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Status',
                      value: (company) =>
                          company.isActive ? 'Aktywna' : 'Nieaktywna',
                      width: 100,
                      widget: (company) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: company.isActive
                              ? AppTheme.successPrimary.withValues(alpha: 0.1)
                              : AppTheme.errorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: company.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          company.isActive ? 'Aktywna' : 'Nieaktywna',
                          style: TextStyle(
                            color: company.isActive
                                ? AppTheme.successPrimary
                                : AppTheme.errorPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Data utworzenia',
                      value: (company) =>
                          '${company.createdAt.day.toString().padLeft(2, '0')}.${company.createdAt.month.toString().padLeft(2, '0')}.${company.createdAt.year}',
                      sortable: true,
                      width: 120,
                      widget: (company) => Text(
                        '${company.createdAt.day.toString().padLeft(2, '0')}.${company.createdAt.month.toString().padLeft(2, '0')}.${company.createdAt.year}',
                        style: const TextStyle(color: AppTheme.textTertiary),
                      ),
                    ),
                    DataTableColumn<Company>(
                      label: 'Akcje',
                      value: (company) => '',
                      width: 120,
                      widget: (company) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showCompanyForm(company: company),
                            icon: const Icon(
                              Icons.edit,
                              color: AppTheme.secondaryGold,
                            ),
                            tooltip: 'Edytuj',
                          ),
                          IconButton(
                            onPressed: () => _deleteCompany(company),
                            icon: const Icon(
                              Icons.delete,
                              color: AppTheme.errorPrimary,
                            ),
                            tooltip: 'Usuń',
                          ),
                        ],
                      ),
                    ),
                  ],
                  onRowTap: (company) => _showCompanyForm(company: company),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

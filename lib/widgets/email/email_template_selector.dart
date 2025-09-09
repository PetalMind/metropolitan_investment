import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../models/email_template.dart';
import '../../services/email_template_service.dart';
import '../../theme/app_theme.dart';

/// 📧 WIDGET WYBORU SZABLONU EMAIL
/// 
/// Umożliwia wybór szablonu z kategorii, podgląd treści,
/// i automatyczne wypełnienie edytora wybranym szablonem.
class EmailTemplateSelector extends StatefulWidget {
  final Function(EmailTemplateModel) onTemplateSelected;
  final EmailTemplateCategory? initialCategory;
  final bool showCategoryFilter;
  final String? selectedTemplateId;

  const EmailTemplateSelector({
    super.key,
    required this.onTemplateSelected,
    this.initialCategory,
    this.showCategoryFilter = true,
    this.selectedTemplateId,
  });

  @override
  State<EmailTemplateSelector> createState() => _EmailTemplateSelectorState();
}

class _EmailTemplateSelectorState extends State<EmailTemplateSelector>
    with TickerProviderStateMixin {
  final EmailTemplateService _templateService = EmailTemplateService();
  
  List<EmailTemplateModel> _templates = [];
  List<EmailTemplateModel> _filteredTemplates = [];
  EmailTemplateCategory? _selectedCategory;
  EmailTemplateModel? _selectedTemplate;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    _loadTemplates();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final templates = await _templateService.getAllTemplates();
      if (templates != null) {
        setState(() {
          _templates = templates;
          _filteredTemplates = templates;
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _error = 'Nie udało się załadować szablonów';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Błąd ładowania szablonów: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        // Filter by category
        bool matchesCategory = _selectedCategory == null || 
                             template.category == _selectedCategory;
        
        // Filter by search query
        bool matchesSearch = _searchQuery.isEmpty ||
                           template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           template.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           template.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesCategory && matchesSearch;
      }).toList();
      
      // Sort by category, then by name
      _filteredTemplates.sort((a, b) {
        final categoryCompare = a.category.displayName.compareTo(b.category.displayName);
        if (categoryCompare != 0) return categoryCompare;
        return a.name.compareTo(b.name);
      });
    });
  }

  void _onCategoryChanged(EmailTemplateCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
    HapticFeedback.selectionClick();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onTemplateSelected(EmailTemplateModel template) {
    setState(() {
      _selectedTemplate = template;
    });
    
    HapticFeedback.mediumImpact();
    widget.onTemplateSelected(template);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundSecondary.withOpacity(0.9),
              AppTheme.backgroundPrimary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderPrimary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            // Filters
            if (widget.showCategoryFilter) _buildFilters(),
            
            // Templates List
            Expanded(
              child: _buildTemplatesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryGold.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderPrimary.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: AppTheme.secondaryGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Szablony Email',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wybierz szablon do szybkiej personalizacji',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Szukaj szablonów...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundSecondary.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.borderPrimary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
              ),
            ),
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          
          const SizedBox(height: 16),
          
          // Category Filter
          Text(
            'Kategoria:',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All categories chip
              FilterChip(
                label: const Text('Wszystkie'),
                selected: _selectedCategory == null,
                onSelected: (_) => _onCategoryChanged(null),
                selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
                checkmarkColor: AppTheme.secondaryGold,
                backgroundColor: AppTheme.backgroundSecondary,
              ),
              // Category chips
              ...EmailTemplateCategory.values.map((category) {
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(category.displayName),
                    ],
                  ),
                  selected: _selectedCategory == category,
                  onSelected: (_) => _onCategoryChanged(category),
                  selectedColor: AppTheme.secondaryGold.withOpacity(0.2),
                  checkmarkColor: AppTheme.secondaryGold,
                  backgroundColor: AppTheme.backgroundSecondary,
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ładowanie szablonów...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: AppTheme.errorPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTemplates,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Brak szablonów pasujących do wyszukiwania'
                  : 'Brak dostępnych szablonów',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(EmailTemplateModel template) {
    final isSelected = _selectedTemplate?.id == template.id ||
                       widget.selectedTemplateId == template.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTemplateSelected(template),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        AppTheme.secondaryGold.withOpacity(0.2),
                        AppTheme.primaryColor.withOpacity(0.1),
                      ]
                    : [
                        AppTheme.backgroundSecondary.withOpacity(0.5),
                        AppTheme.backgroundPrimary.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.secondaryGold
                    : AppTheme.borderPrimary.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${template.category.icon} ${template.category.displayName}',
                        style: TextStyle(
                          color: AppTheme.secondaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.secondaryGold,
                        size: 20,
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Name
                Text(
                  template.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Description
                if (template.description.isNotEmpty)
                  Text(
                    template.description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 8),
                
                // Subject preview
                Text(
                  'Temat: ${template.subject}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Features
                Row(
                  children: [
                    if (template.includeInvestmentDetails)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '💰 Inwestycje',
                          style: TextStyle(
                            color: AppTheme.successPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    if (template.placeholders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.infoPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🏷️ ${template.placeholders.length} zmiennych',
                          style: TextStyle(
                            color: AppTheme.infoPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
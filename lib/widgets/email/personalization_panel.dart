import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../models/email_template.dart';
import '../../services/email_template_service.dart';
import '../../theme/app_theme.dart';

/// 🎨 PANEL PERSONALIZACJI EMAIL
/// 
/// Zaawansowane narzędzie do personalizacji treści email z:
/// - Podglądem dostępnych placeholders
/// - Edycją custom values
/// - Podglądem wyników personalizacji
/// - Zarządzaniem wariantami dla różnych odbiorców
class PersonalizationPanel extends StatefulWidget {
  final EmailTemplateModel? template;
  final List<InvestorSummary> investors;
  final Map<String, String> customValues;
  final Function(Map<String, String>) onCustomValuesChanged;
  final Function(String)? onContentChanged;
  final String currentContent;

  const PersonalizationPanel({
    super.key,
    this.template,
    required this.investors,
    required this.customValues,
    required this.onCustomValuesChanged,
    this.onContentChanged,
    required this.currentContent,
  });

  @override
  State<PersonalizationPanel> createState() => _PersonalizationPanelState();
}

class _PersonalizationPanelState extends State<PersonalizationPanel>
    with TickerProviderStateMixin {
  final EmailTemplateService _templateService = EmailTemplateService();
  final ScrollController _scrollController = ScrollController();
  
  late Map<String, TextEditingController> _customValueControllers;
  List<String> _availablePlaceholders = [];
  List<String> _usedPlaceholders = [];
  InvestorSummary? _previewInvestor;
  String _previewContent = '';
  bool _showPreview = false;
  
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    
    _initializeControllers();
    _updatePlaceholders();
    
    if (widget.investors.isNotEmpty) {
      _previewInvestor = widget.investors.first;
      _updatePreview();
    }
  }

  @override
  void didUpdateWidget(PersonalizationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.template != widget.template ||
        oldWidget.currentContent != widget.currentContent) {
      _updatePlaceholders();
      _updatePreview();
    }
    
    if (oldWidget.investors != widget.investors && widget.investors.isNotEmpty) {
      _previewInvestor = widget.investors.first;
      _updatePreview();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expandController.dispose();
    for (final controller in _customValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _customValueControllers = {};
    for (final entry in widget.customValues.entries) {
      _customValueControllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  void _updatePlaceholders() {
    setState(() {
      _availablePlaceholders = EmailTemplateService.getAvailablePlaceholders();
      
      // Find used placeholders in current content
      final regex = RegExp(r'\{\{([^}]+)\}\}');
      final matches = regex.allMatches(widget.currentContent);
      _usedPlaceholders = matches
          .map((match) => '{{${match.group(1)}}}')
          .toSet()
          .toList()
          ..sort();
      
      // Add controllers for new custom values
      for (final placeholder in _usedPlaceholders) {
        if (!_availablePlaceholders.contains(placeholder) &&
            !_customValueControllers.containsKey(placeholder)) {
          _customValueControllers[placeholder] = TextEditingController();
        }
      }
    });
  }

  void _updatePreview() {
    if (_previewInvestor == null || widget.template == null) {
      setState(() {
        _previewContent = widget.currentContent;
      });
      return;
    }

    // Get custom values from controllers
    final customValues = <String, String>{};
    for (final entry in _customValueControllers.entries) {
      if (entry.value.text.isNotEmpty) {
        customValues[entry.key] = entry.value.text;
      }
    }

    // Create template with current content
    final tempTemplate = widget.template!.copyWith(content: widget.currentContent);
    
    // Render for preview investor
    final rendered = _templateService.renderTemplateForInvestor(
      tempTemplate,
      _previewInvestor!,
      customValues: customValues,
    );

    setState(() {
      _previewContent = rendered.content;
    });
  }

  void _onCustomValueChanged(String placeholder, String value) {
    final newCustomValues = Map<String, String>.from(widget.customValues);
    if (value.isEmpty) {
      newCustomValues.remove(placeholder);
    } else {
      newCustomValues[placeholder] = value;
    }
    
    widget.onCustomValuesChanged(newCustomValues);
    _updatePreview();
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
      if (_showPreview) {
        _expandController.forward();
        _updatePreview();
      } else {
        _expandController.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _insertPlaceholder(String placeholder) {
    if (widget.onContentChanged != null) {
      final newContent = widget.currentContent + ' $placeholder';
      widget.onContentChanged!(newContent);
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
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
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Placeholders
                  _buildAvailablePlaceholders(),
                  
                  const SizedBox(height: 24),
                  
                  // Used Placeholders (Custom Values)
                  if (_usedPlaceholders.isNotEmpty) ...[
                    _buildUsedPlaceholders(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Preview Controls
                  _buildPreviewControls(),
                  
                  // Preview Content
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildPreviewContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            AppTheme.infoPrimary.withOpacity(0.1),
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
            Icons.tune,
            color: AppTheme.infoPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalizacja',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dostosuj treść do konkretnych odbiorców',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_usedPlaceholders.length}/${_availablePlaceholders.length}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlaceholders() {
    final descriptions = EmailTemplateService.getPlaceholderDescriptions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label_outline,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Dostępne zmienne',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availablePlaceholders.map((placeholder) {
            final isUsed = _usedPlaceholders.contains(placeholder);
            final description = descriptions[placeholder] ?? 'Brak opisu';
            
            return Tooltip(
              message: description,
              child: InkWell(
                onTap: () => _insertPlaceholder(placeholder),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? AppTheme.successPrimary.withOpacity(0.1)
                        : AppTheme.backgroundSecondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUsed
                          ? AppTheme.successPrimary
                          : AppTheme.borderPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUsed)
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppTheme.successPrimary,
                        )
                      else
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        placeholder.replaceAll(RegExp(r'[{}]'), ''),
                        style: TextStyle(
                          color: isUsed
                              ? AppTheme.successPrimary
                              : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsedPlaceholders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_attributes,
              color: AppTheme.warningPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Wartości niestandardowe',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        ..._usedPlaceholders.map((placeholder) {
          // Skip standard placeholders that are auto-filled
          if (_availablePlaceholders.contains(placeholder)) {
            return const SizedBox.shrink();
          }
          
          final controller = _customValueControllers[placeholder];
          if (controller == null) return const SizedBox.shrink();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeholder,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  onChanged: (value) => _onCustomValueChanged(placeholder, value),
                  decoration: InputDecoration(
                    hintText: 'Wprowadź wartość dla $placeholder',
                    filled: true,
                    fillColor: AppTheme.backgroundSecondary.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.borderPrimary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.warningPrimary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview,
              color: AppTheme.infoPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Podgląd personalizacji',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: _showPreview,
              onChanged: (_) => _togglePreview(),
              activeColor: AppTheme.infoPrimary,
            ),
          ],
        ),
        
        if (_showPreview && widget.investors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Podgląd dla:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<InvestorSummary>(
                  value: _previewInvestor,
                  isExpanded: true,
                  underline: Container(
                    height: 1,
                    color: AppTheme.borderPrimary.withOpacity(0.3),
                  ),
                  items: widget.investors.map((investor) {
                    return DropdownMenuItem<InvestorSummary>(
                      value: investor,
                      child: Text(
                        investor.client.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (investor) {
                    setState(() {
                      _previewInvestor = investor;
                    });
                    _updatePreview();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewContent() {
    if (!_showPreview || _previewContent.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(
                color: AppTheme.borderPrimary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Podgląd spersonalizowanej treści',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(
                color: AppTheme.borderPrimary.withOpacity(0.3),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _previewContent.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../services/unified_product_management_service.dart';
import '../premium_loading_widget.dart';
import '../premium_error_widget.dart';

/// Nowoczesny dialog do edycji produktów zunifikowanych
class ProductEditDialog extends StatefulWidget {
  final UnifiedProduct product;
  final VoidCallback? onProductUpdated;

  const ProductEditDialog({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UnifiedProductManagementService _managementService =
      UnifiedProductManagementService();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Kontrolery pól tekstowych
  late TextEditingController _nameController;
  late TextEditingController _investmentAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _descriptionController;
  late TextEditingController _currencyController;

  // Stan formularza
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initControllers();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Rozpocznij animacje
    _slideController.forward();
    _fadeController.forward();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _investmentAmountController = TextEditingController(
      text: widget.product.investmentAmount.toStringAsFixed(2),
    );
    _interestRateController = TextEditingController(
      text: (widget.product.interestRate ?? 0.0).toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _currencyController = TextEditingController(
      text: widget.product.currency ?? 'PLN',
    );

    // Dodaj listenery do kontrolerów, żeby śledzić zmiany
    _nameController.addListener(_onFieldChanged);
    _investmentAmountController.addListener(_onFieldChanged);
    _interestRateController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _currencyController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _investmentAmountController.dispose();
    _interestRateController.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Przygotuj dane do aktualizacji
      final updates = <String, dynamic>{};

      // Sprawdź które pola zostały zmienione
      if (_nameController.text != widget.product.name) {
        updates['nazwa_produktu'] = _nameController.text;
        updates['name'] = _nameController.text;
      }

      final newInvestmentAmount =
          double.tryParse(_investmentAmountController.text) ?? 0.0;
      if (newInvestmentAmount != widget.product.investmentAmount) {
        updates['kwota_inwestycji'] = newInvestmentAmount;
        updates['investmentAmount'] = newInvestmentAmount;
      }

      final newInterestRate = double.tryParse(_interestRateController.text);
      if (newInterestRate != widget.product.interestRate) {
        updates['oprocentowanie'] = newInterestRate;
        updates['interestRate'] = newInterestRate;
      }

      if (_descriptionController.text != widget.product.description) {
        updates['description'] = _descriptionController.text;
        updates['opis'] = _descriptionController.text;
      }

      if (_currencyController.text != (widget.product.currency ?? 'PLN')) {
        updates['waluta'] = _currencyController.text;
        updates['currency'] = _currencyController.text;
      }

      // Jeśli nie ma zmian, zakończ
      if (updates.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Wykonaj aktualizację
      final success = await _managementService.updateProduct(
        widget.product,
        updates,
      );

      if (mounted) {
        if (success) {
          // Wywołaj callback
          if (widget.onProductUpdated != null) {
            widget.onProductUpdated!();
          }

          // Pokaż sukces i zamknij dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Produkt "${widget.product.name}" został zaktualizowany pomyślnie',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successPrimary,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop();
        } else {
          setState(() {
            _errorMessage =
                'Nie udało się zaktualizować produktu. Spróbuj ponownie.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Wystąpił błąd: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    // Pokaż dialog potwierdzenia
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Niezapisane zmiany',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Masz niezapisane zmiany. Czy chcesz je odrzucić?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorPrimary,
            ),
            child: const Text(
              'Odrzuć zmiany',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: screenWidth > 700 ? 600 : screenWidth * 0.95,
              height: screenHeight * 0.8,
              constraints: const BoxConstraints(
                maxWidth: 600,
                maxHeight: 700,
                minHeight: 500,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundModal,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderPrimary, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: PremiumLoadingWidget(
                              message: 'Zapisywanie zmian...',
                            ),
                          )
                        : _buildForm(),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.secondaryGold, AppTheme.primaryAccent],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edycja produktu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.productType.displayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (_hasChanges) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Niezapisane zmiany',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              PremiumErrorWidget(
                error: _errorMessage!,
                onRetry: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            // Nazwa produktu
            _buildAnimatedField(
              label: 'Nazwa produktu',
              icon: Icons.business_center,
              child: TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: _getInputDecoration('Wprowadź nazwę produktu'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa produktu jest wymagana';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Kwota inwestycji
            _buildAnimatedField(
              label: 'Kwota inwestycji',
              icon: Icons.monetization_on,
              child: TextFormField(
                controller: _investmentAmountController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: _getInputDecoration(
                  '0.00',
                ).copyWith(suffixText: 'zł'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kwota jest wymagana';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Wprowadź poprawną kwotę';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Oprocentowanie (jeśli dotyczy)
            if (widget.product.interestRate != null) ...[
              _buildAnimatedField(
                label: 'Oprocentowanie',
                icon: Icons.percent,
                child: TextFormField(
                  controller: _interestRateController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: _getInputDecoration(
                    '0.00',
                  ).copyWith(suffixText: '%'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Wprowadź poprawne oprocentowanie (0-100%)';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Waluta
            _buildAnimatedField(
              label: 'Waluta',
              icon: Icons.currency_exchange,
              child: TextFormField(
                controller: _currencyController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: _getInputDecoration('PLN'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Waluta jest wymagana';
                  }
                  if (value.length != 3) {
                    return 'Kod waluty powinien mieć 3 znaki (np. PLN, USD)';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Opis
            _buildAnimatedField(
              label: 'Opis produktu',
              icon: Icons.description,
              child: TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: _getInputDecoration('Opcjonalny opis produktu'),
                maxLines: 3,
                maxLength: 500,
              ),
            ),

            const SizedBox(height: 20),

            // Informacje tylko do odczytu
            _buildReadOnlyInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.borderPrimary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppTheme.secondaryGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.infoPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informacje systemowe',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('ID produktu:', widget.product.id),
          _buildInfoRow(
            'Typ produktu:',
            widget.product.productType.displayName,
          ),
          _buildInfoRow(
            'Data utworzenia:',
            _formatDate(widget.product.createdAt),
          ),
          _buildInfoRow(
            'Ostatnia aktualizacja:',
            _formatDate(widget.product.uploadedAt),
          ),
          _buildInfoRow('Źródło danych:', widget.product.sourceFile),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppTheme.borderPrimary, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.borderPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Anuluj',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGold,
                disabledBackgroundColor: AppTheme.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: _hasChanges ? 4 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _isLoading ? 'Zapisywanie...' : 'Zapisz zmiany',
                    style: TextStyle(
                      color: _hasChanges ? Colors.white : AppTheme.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorPrimary, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.backgroundPrimary.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

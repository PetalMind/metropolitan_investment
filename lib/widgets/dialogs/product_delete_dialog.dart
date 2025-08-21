import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import '../../services/unified_product_management_service.dart';
import '../../models_and_services.dart';
import '../premium_error_widget.dart';

/// Dialog do potwierdzenia usunięcia produktu z dodatkowymi funkcjonalnościami
class ProductDeleteDialog extends StatefulWidget {
  final UnifiedProduct product;
  final VoidCallback? onProductDeleted;

  const ProductDeleteDialog({
    super.key,
    required this.product,
    this.onProductDeleted,
  });

  @override
  State<ProductDeleteDialog> createState() => _ProductDeleteDialogState();
}

class _ProductDeleteDialogState extends State<ProductDeleteDialog>
    with TickerProviderStateMixin {
  final UnifiedProductManagementService _managementService =
      UnifiedProductManagementService();

  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  ProductDeletionCheck? _deletionCheck;
  bool _isLoadingCheck = true;
  bool _isDeleting = false;
  bool _useSoftDelete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkDeletionPossibility();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    _scaleController.forward();
  }

  Future<void> _checkDeletionPossibility() async {
    try {
      final check = await _managementService.checkProductDeletion(
        widget.product,
      );

      if (mounted) {
        setState(() {
          _deletionCheck = check;
          _isLoadingCheck = false;
          _useSoftDelete =
              !check.canDelete; // Domyślnie soft delete jeśli są powiązania
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Błąd podczas sprawdzania produktu: $e';
          _isLoadingCheck = false;
        });
      }
    }
  }

  Future<void> _performDeletion() async {
    if (_deletionCheck == null) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      bool success;

      if (_useSoftDelete) {
        success = await _managementService.softDeleteProduct(widget.product);
      } else {
        success = await _managementService.deleteProduct(widget.product);
      }

      if (mounted) {
        if (success) {
          // Wywołaj callback
          if (widget.onProductDeleted != null) {
            widget.onProductDeleted!();
          }

          // Pokaż komunikat sukcesu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _useSoftDelete
                          ? 'Produkt "${widget.product.name}" został dezaktywowany'
                          : 'Produkt "${widget.product.name}" został usunięty',
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
            _errorMessage = 'Nie udało się usunąć produktu. Spróbuj ponownie.';
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
          _isDeleting = false;
        });
      }
    }
  }

  void _showDangerConfirmation() {
    _shakeController.reset();
    _shakeController.forward();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorPrimary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Potwierdzenie usunięcia',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Czy na pewno chcesz ${_useSoftDelete ? "dezaktywować" : "trwale usunąć"} ten produkt?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorPrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produkt: ${widget.product.name}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Typ: ${widget.product.productType.displayName}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'ID: ${widget.product.id}',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (!_useSoftDelete) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ta operacja jest nieodwracalna!',
                        style: TextStyle(
                          color: AppTheme.warningPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorPrimary,
            ),
            child: Text(
              _useSoftDelete ? 'Dezaktywuj' : 'Usuń',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 500,
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundModal,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.errorPrimary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorPrimary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isLoadingCheck
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: PremiumShimmerLoadingWidget.analyticsCard(),
                        ),
                      )
                    : _buildContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        if (_errorMessage != null) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumErrorWidget(
              error: _errorMessage!,
              onRetry: () {
                setState(() {
                  _errorMessage = null;
                });
                _checkDeletionPossibility();
              },
            ),
          ),
        ] else if (_deletionCheck != null) ...[
          _buildDeletionInfo(),
          _buildOptions(),
        ],
        _buildActions(),
      ],
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
          colors: [
            AppTheme.errorPrimary,
            AppTheme.errorPrimary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuwanie produktu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionInfo() {
    final check = _deletionCheck!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status usunięcia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: check.canDelete
                  ? AppTheme.successPrimary.withOpacity(0.1)
                  : AppTheme.warningPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: check.canDelete
                    ? AppTheme.successPrimary.withOpacity(0.3)
                    : AppTheme.warningPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  check.canDelete ? Icons.check_circle : Icons.warning,
                  color: check.canDelete
                      ? AppTheme.successPrimary
                      : AppTheme.warningPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        check.canDelete
                            ? 'Produkt może być bezpiecznie usunięty'
                            : 'Produkt ma powiązania w systemie',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (check.hasWarnings) ...[
                        const SizedBox(height: 4),
                        Text(
                          check.warningsText,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Szczegóły powiązań
          if (!check.canDelete) ...[
            const SizedBox(height: 16),
            _buildRelationshipInfo(
              'Powiązane inwestycje',
              check.relatedInvestments,
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 8),
            _buildRelationshipInfo(
              'Inne powiązania',
              check.relatedData,
              Icons.link,
            ),
          ],

          const SizedBox(height: 20),

          // Informacje o produkcie
          _buildProductInfo(),
        ],
      ),
    );
  }

  Widget _buildRelationshipInfo(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.warningPrimary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppTheme.warningPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacje o produkcie',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Typ:', widget.product.productType.displayName),
          _buildInfoRow(
            'Kwota inwestycji:',
            '${widget.product.investmentAmount.toStringAsFixed(2)} zł',
          ),
          _buildInfoRow(
            'Data utworzenia:',
            _formatDate(widget.product.createdAt),
          ),
          _buildInfoRow('ID:', widget.product.id),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final check = _deletionCheck!;

    if (check.canDelete) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opcje usuwania',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<bool>(
              value: false,
              groupValue: _useSoftDelete,
              onChanged: (value) => setState(() => _useSoftDelete = value!),
              title: Text(
                'Usuń trwale',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                'Produkt zostanie całkowicie usunięty z bazy danych',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              activeColor: AppTheme.errorPrimary,
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _useSoftDelete,
              onChanged: (value) => setState(() => _useSoftDelete = value!),
              title: Text(
                'Dezaktywuj',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                'Produkt zostanie oznaczony jako nieaktywny',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              activeColor: AppTheme.warningPrimary,
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.warningPrimary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tylko dezaktywacja',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ze względu na powiązania w systemie, produkt może być tylko dezaktywowany. Trwałe usunięcie nie jest możliwe.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.borderPrimary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
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
              onPressed: _isDeleting || _deletionCheck == null
                  ? null
                  : _showDangerConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _useSoftDelete
                    ? AppTheme.warningPrimary
                    : AppTheme.errorPrimary,
                disabledBackgroundColor: AppTheme.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isDeleting) ...[
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
                    _isDeleting
                        ? 'Przetwarzanie...'
                        : _useSoftDelete
                        ? 'Dezaktywuj produkt'
                        : 'Usuń produkt',
                    style: const TextStyle(
                      color: Colors.white,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

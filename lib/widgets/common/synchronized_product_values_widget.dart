import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// Widget wyświetlający zsynchronizowane wartości produktu
/// Używa tego samego UnifiedProductModalService co ProductDetailsModal
/// aby zapewnić spójność danych między listą a dialogiem
class SynchronizedProductValuesWidget extends StatefulWidget {
  final UnifiedProduct product;
  final TextStyle? textStyle;
  final Color? valueColor;
  final String
  valueType; // 'totalInvestmentAmount', 'totalRemainingCapital', 'totalInvestors'

  const SynchronizedProductValuesWidget({
    super.key,
    required this.product,
    required this.valueType,
    this.textStyle,
    this.valueColor,
  });

  @override
  State<SynchronizedProductValuesWidget> createState() =>
      _SynchronizedProductValuesWidgetState();
}

class _SynchronizedProductValuesWidgetState
    extends State<SynchronizedProductValuesWidget> {
  final UnifiedProductModalService _modalService = UnifiedProductModalService();

  ProductModalData? _modalData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModalData();
  }

  @override
  void didUpdateWidget(SynchronizedProductValuesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Przeładuj dane jeśli zmienił się produkt
    if (oldWidget.product.id != widget.product.id) {
      _loadModalData();
    }
  }

  Future<void> _loadModalData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final modalData = await _modalService.getProductModalData(
        product: widget.product,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          _modalData = modalData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return _buildValueWidget();
  }

  Widget _buildLoadingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.valueColor ?? AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    // Fallback na oryginalne wartości z produktu
    return Text(
      _getFallbackValue(),
      style:
          widget.textStyle?.copyWith(
            color: widget.valueColor ?? AppTheme.errorColor,
          ) ??
          TextStyle(color: widget.valueColor ?? AppTheme.errorColor),
    );
  }

  Widget _buildValueWidget() {
    final value = _getValueFromModal();

    return Text(
      value,
      style:
          widget.textStyle?.copyWith(
            color: widget.valueColor ?? AppTheme.primaryAccent,
          ) ??
          TextStyle(
            color: widget.valueColor ?? AppTheme.primaryAccent,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _getValueFromModal() {
    if (_modalData == null) return _getFallbackValue();

    switch (widget.valueType) {
      case 'totalInvestmentAmount':
        return CurrencyFormatter.formatCurrency(
          _modalData!.statistics.totalInvestmentAmount,
          showDecimals: false,
        );
      case 'totalRemainingCapital':
        return CurrencyFormatter.formatCurrency(
          _modalData!.statistics.totalRemainingCapital,
          showDecimals: false,
        );
      case 'totalInvestors':
        return CurrencyFormatter.formatNumber(
          _modalData!.statistics.totalInvestors.toDouble(),
        );
      default:
        return _getFallbackValue();
    }
  }

  String _getFallbackValue() {
    switch (widget.valueType) {
      case 'totalInvestmentAmount':
        return CurrencyFormatter.formatCurrency(
          widget.product.investmentAmount,
          showDecimals: false,
        );
      case 'totalRemainingCapital':
        // Używaj remainingCapital jeśli dostępne, w przeciwnym razie investmentAmount
        final remainingCapital =
            widget.product.remainingCapital ?? widget.product.investmentAmount;
        return CurrencyFormatter.formatCurrency(
          remainingCapital,
          showDecimals: false,
        );
      case 'totalInvestors':
        return '-'; // Będzie używał InvestorCountWidget jako fallback
      default:
        return '-';
    }
  }

  /// Publiczna metoda do odświeżenia danych
  void refresh() {
    _loadModalData();
  }
}

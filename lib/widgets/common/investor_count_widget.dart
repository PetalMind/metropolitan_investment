import 'package:flutter/material.dart';
import '../../models_and_services.dart';

/// Widget wyświetlający liczbę inwestorów dla produktu
/// Automatycznie ładuje dane w tle i wyświetla je w sposób responsywny
class InvestorCountWidget extends StatefulWidget {
  final UnifiedProduct product;
  final TextStyle? textStyle;
  final Color? color;
  final String? prefix;
  final bool showIcon;

  const InvestorCountWidget({
    super.key,
    required this.product,
    this.textStyle,
    this.color,
    this.prefix,
    this.showIcon = false,
  });

  @override
  State<InvestorCountWidget> createState() => _InvestorCountWidgetState();
}

class _InvestorCountWidgetState extends State<InvestorCountWidget> {
  final UnifiedInvestorCountService _investorCountService = UnifiedInvestorCountService();
  
  int? _investorCount;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvestorCount();
  }

  @override
  void didUpdateWidget(InvestorCountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Przeładuj dane jeśli zmienił się produkt
    if (oldWidget.product.id != widget.product.id) {
      _loadInvestorCount();
    }
  }

  Future<void> _loadInvestorCount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final count = await _investorCountService.getProductInvestorCount(widget.product);
      
      if (mounted) {
        setState(() {
          _investorCount = count;
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
    
    return _buildCountWidget();
  }

  Widget _buildLoadingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            Icons.people,
            size: 16,
            color: widget.color ?? AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
        ],
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            Icons.people_outline,
            size: 16,
            color: widget.color ?? AppTheme.errorColor,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '-',
          style: widget.textStyle?.copyWith(
            color: widget.color ?? AppTheme.errorColor,
          ) ?? TextStyle(
            color: widget.color ?? AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCountWidget() {
    final count = _investorCount ?? 0;
    final prefix = widget.prefix != null ? '${widget.prefix} ' : '';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            Icons.people,
            size: 16,
            color: widget.color ?? AppTheme.primaryAccent,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '$prefix$count',
          style: widget.textStyle?.copyWith(
            color: widget.color ?? AppTheme.primaryAccent,
          ) ?? TextStyle(
            color: widget.color ?? AppTheme.primaryAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Publiczna metoda do odświeżenia danych
  void refresh() {
    _loadInvestorCount();
  }
}
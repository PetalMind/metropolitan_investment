import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/investor_summary.dart';
import '../../services/standard_product_investors_service.dart';

/// Zakładka z inwestorami dla standardowego produktu
class StandardProductInvestorsTab extends StatefulWidget {
  final Product product;
  final StandardProductInvestorsService investorsService;
  final Function(bool) onLoading;
  final Function(String?) onError;

  const StandardProductInvestorsTab({
    super.key,
    required this.product,
    required this.investorsService,
    required this.onLoading,
    required this.onError,
  });

  @override
  State<StandardProductInvestorsTab> createState() =>
      _StandardProductInvestorsTabState();
}

class _StandardProductInvestorsTabState
    extends State<StandardProductInvestorsTab> {
  List<InvestorSummary>? _investors;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvestors();
  }

  Future<void> _loadInvestors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    widget.onLoading(true);
    widget.onError(null);

    try {
      final investors = await widget.investorsService.getInvestorsForProduct(
        widget.product,
      );

      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = 'Błąd podczas ładowania inwestorów: $e';

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }

      widget.onError(errorMessage);
    } finally {
      widget.onLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _investors == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd podczas ładowania',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvestors,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    final investors = _investors ?? [];
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    if (investors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Brak inwestorów',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ten produkt nie ma jeszcze żadnych inwestorów',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: investors.length,
      itemBuilder: (context, index) {
        final investor = investors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              investor.client.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(investor.client.email),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(investor.totalValue),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${investor.investments.length} inwestycji',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

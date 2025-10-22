import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 🚀 PRZYKŁAD IMPLEMENTACJI ZUNIFIKOWANEJ ARCHITEKTURY
///
/// Ten plik pokazuje jak migrować ProductDetailsModal do zunifikowanej architektury
/// bez zmiany istniejącego UI

class ProductDetailsModalUnified extends StatefulWidget {
  final UnifiedProduct product;

  const ProductDetailsModalUnified({super.key, required this.product});

  @override
  State<ProductDetailsModalUnified> createState() =>
      _ProductDetailsModalUnifiedState();
}

class _ProductDetailsModalUnifiedState
    extends State<ProductDetailsModalUnified> {
  // 🚀 ZUNIFIKOWANA ARCHITEKTURA - jeden adapter zamiast wielu serwisów
  final _adapter = ProductDetailsAdapter.instance;

  List<InvestorSummary> _investors = [];
  bool _isLoadingInvestors = false;
  String? _investorsError;

  UnifiedProduct? _freshProduct;
  bool _isLoadingProduct = false;
  String? _productError;

  // ⭐ AUTOMATYCZNE SUMY - nie trzeba ręcznie liczyć
  ProductDetailsSums? _calculatedSums;

  @override
  void initState() {
    super.initState();
    _loadInvestors(); // Automatyczne resolve ProductId
    _loadProduct(); // Zunifikowane pobieranie danych
  }

  /// 🔍 POBIERZ INWESTORÓW Z AUTOMATYCZNYM RESOLVE PRODUCT ID
  Future<void> _loadInvestors({bool forceRefresh = false}) async {
    if (_isLoadingInvestors) return;

    setState(() {
      _isLoadingInvestors = true;
      _investorsError = null;
    });

    try {
      // 🚀 JEDNA LINIJKA zamiast complex logic z _findRealProductId
      final result = await _adapter.getProductInvestorsWithResolve(
        product: widget.product,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _investors = result.investors;
          _isLoadingInvestors = false;

          // ⭐ AUTOMATYCZNE OBLICZENIA
          _calculatedSums = _adapter.calculateSumsFromInvestors(
            result.investors,
          );
        });

        // 📊 DEBUG INFO - pokaż czy Product ID został zresolve'owany
        // Debug prints removed for production
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _investorsError = e.toString();
          _isLoadingInvestors = false;
        });
      }
    }
  }

  /// 🏢 POBIERZ ŚWIEŻE DANE PRODUKTU
  Future<void> _loadProduct() async {
    if (_isLoadingProduct) return;

    setState(() {
      _isLoadingProduct = true;
      _productError = null;
    });

    try {
      // 🚀 ZUNIFIKOWANE POBIERANIE - automatyczny wybór najlepszego serwisu
      final loaded = await _adapter.getFreshProductData(widget.product);

      if (mounted) {
        setState(() {
          _freshProduct = loaded;
          _isLoadingProduct = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productError = e.toString();
          _isLoadingProduct = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(_getProductIcon(), color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 SEKCJA Z AUTOMATYCZNYMI SUMAMI
          _buildAutomaticSumsSection(),

          const SizedBox(height: 20),

          // 👥 SEKCJA INWESTORÓW
          _buildInvestorsSection(),

          const SizedBox(height: 20),

          // 📋 SZCZEGÓŁY PRODUKTU
          _buildProductDetailsSection(),
        ],
      ),
    );
  }

  /// 📊 SEKCJA Z AUTOMATYCZNYMI SUMAMI
  Widget _buildAutomaticSumsSection() {
    if (_calculatedSums == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ładowanie sum...'),
        ),
      );
    }

    final sums = _calculatedSums!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 AUTOMATYCZNE SUMY Z INWESTORÓW',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildSumRow(
              '💰 Łączna kwota inwestycji',
              '${sums.totalInvestmentAmount.toStringAsFixed(2)} PLN',
              Colors.blue,
            ),

            _buildSumRow(
              '📈 Pozostały kapitał',
              '${sums.totalRemainingCapital.toStringAsFixed(2)} PLN',
              Colors.green,
            ),

            _buildSumRow(
              '🏠 Kapitał zabezpieczony',
              '${sums.totalCapitalSecuredByRealEstate.toStringAsFixed(2)} PLN',
              Colors.orange,
            ),

            _buildSumRow(
              '👥 Liczba inwestorów',
              '${sums.investorsCount}',
              Colors.purple,
            ),

            _buildSumRow(
              '📊 Średnia inwestycja',
              '${sums.averageInvestmentAmount.toStringAsFixed(2)} PLN',
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSumRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 SEKCJA INWESTORÓW
  Widget _buildInvestorsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '👥 INWESTORZY',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _loadInvestors(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingInvestors)
              const Center(child: CircularProgressIndicator())
            else if (_investorsError != null)
              Text(
                'Błąd: $_investorsError',
                style: const TextStyle(color: Colors.red),
              )
            else if (_investors.isEmpty)
              const Text('Brak inwestorów')
            else
              Column(
                children: _investors.take(5).map((investor) {
                  return ListTile(
                    leading: CircleAvatar(child: Text(investor.client.name[0])),
                    title: Text(investor.client.name),
                    subtitle: Text(
                      'Kapitał: ${investor.totalRemainingCapital.toStringAsFixed(2)} PLN',
                    ),
                    trailing: Text(
                      '${investor.totalInvestmentAmount.toStringAsFixed(2)} PLN',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// 📋 SZCZEGÓŁY PRODUKTU
  Widget _buildProductDetailsSection() {
    final product = _freshProduct ?? widget.product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 SZCZEGÓŁY PRODUKTU',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildDetailRow('ID Produktu', product.id),
            _buildDetailRow('Typ', product.productType.displayName),
            _buildDetailRow('Firma', product.companyName ?? 'Brak danych'),
            _buildDetailRow('Status', product.status.displayName),
            _buildDetailRow(
              'Utworzono',
              product.createdAt.toString().split(' ')[0],
            ),

            if (product.interestRate != null)
              _buildDetailRow('Oprocentowanie', '${product.interestRate}%'),

            if (product.maturityDate != null)
              _buildDetailRow(
                'Data zapadalności',
                product.maturityDate.toString().split(' ')[0],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 🎯 INFO O ZUNIFIKOWANEJ ARCHITEKTURZE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🚀 Zunifikowana Architektura',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Automatyczny resolve Product ID • Cache management • Unified services',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return Icons.account_balance;
      case UnifiedProductType.shares:
        return Icons.trending_up;
      case UnifiedProductType.loans:
        return Icons.handshake;
      case UnifiedProductType.apartments:
        return Icons.home;
      case UnifiedProductType.other:
        return Icons.business;
    }
  }
}

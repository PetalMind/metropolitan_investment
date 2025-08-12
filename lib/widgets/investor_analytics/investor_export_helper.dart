import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';

/// 📤 Investor Data Export Helper
///
/// Provides functionality to export investor data in various formats
class InvestorExportHelper {
  static void exportToClipboard(
    BuildContext context,
    InvestorSummary investor,
  ) {
    // Prepare comprehensive data for export
    final data = StringBuffer();

    // Header
    data.writeln('=== ${investor.client.name.toUpperCase()} ===');
    data.writeln('Data eksportu: ${DateTime.now().toString().split('.')[0]}');
    data.writeln('');

    // Basic info
    data.writeln('INFORMACJE PODSTAWOWE:');
    data.writeln(
      '• Email: ${investor.client.email.isNotEmpty ? investor.client.email : 'Brak'}',
    );
    data.writeln(
      '• Telefon: ${investor.client.phone.isNotEmpty ? investor.client.phone : 'Brak'}',
    );
    data.writeln('• Typ klienta: ${investor.client.type.displayName}');
    data.writeln(
      '• Status głosowania: ${investor.client.votingStatus.displayName}',
    );
    data.writeln('');

    // ✅ WSZYSTKIE 4 KLUCZOWE METRYKI FINANSOWE
    data.writeln('SZCZEGÓŁY FINANSOWE:');
    data.writeln(
      '• Kapitał pozostały: ${CurrencyFormatter.formatCurrency(investor.viableRemainingCapital)}',
    );
    data.writeln(
      '• Kwota inwestycji (całkowita): ${CurrencyFormatter.formatCurrency(investor.totalInvestmentAmount)}',
    );
    data.writeln(
      '• Kapitał do restrukturyzacji: ${CurrencyFormatter.formatCurrency(investor.capitalForRestructuring)}',
    );
    data.writeln(
      '• Kapitał zabezpieczony nieruchomościami: ${CurrencyFormatter.formatCurrency(investor.capitalSecuredByRealEstate)}',
    );
    data.writeln('• Liczba inwestycji: ${investor.investmentCount}');
    data.writeln('');

    // Additional calculations
    final effectiveCapital =
        investor.viableRemainingCapital - investor.capitalForRestructuring;
    final securityRatio = investor.viableRemainingCapital > 0
        ? (investor.capitalSecuredByRealEstate /
                  investor.viableRemainingCapital) *
              100
        : 0.0;

    data.writeln('ANALIZA DODATKOWA:');
    data.writeln(
      '• Kapitał efektywny (po restrukturyzacji): ${CurrencyFormatter.formatCurrency(effectiveCapital > 0 ? effectiveCapital : 0)}',
    );
    data.writeln(
      '• Stopień zabezpieczenia nieruchomościami: ${securityRatio.toStringAsFixed(1)}%',
    );
    data.writeln(
      '• Średnia na inwestycję: ${CurrencyFormatter.formatCurrency(investor.investmentCount > 0 ? investor.viableRemainingCapital / investor.investmentCount : 0)}',
    );
    data.writeln('');

    // Investment breakdown
    if (investor.investments.isNotEmpty) {
      data.writeln('LISTA INWESTYCJI (${investor.investments.length}):');
      for (var i = 0; i < investor.investments.length; i++) {
        final investment = investor.investments[i];
        final isUnviable = investor.client.unviableInvestments.contains(
          investment.id,
        );
        data.writeln('${i + 1}. ${investment.productName}');
        data.writeln('   - Firma: ${investment.creditorCompany}');
        data.writeln('   - Typ: ${investment.productType.displayName}');
        data.writeln(
          '   - Kapitał pozostały: ${CurrencyFormatter.formatCurrency(investment.remainingCapital)}',
        );
        data.writeln(
          '   - Status: ${isUnviable ? 'NIEWYKONALNA' : 'Wykonalna'}',
        );
        if (i < investor.investments.length - 1) data.writeln('');
      }
      data.writeln('');
    }

    // Footer
    data.writeln('---');
    data.writeln(
      'Eksport wygenerowany przez Metropolitan Investment Analytics',
    );
    data.writeln('© ${DateTime.now().year} Wszystkie prawa zastrzeżone');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: data.toString()));

    // Show confirmation with enhanced feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dane inwestora skopiowane!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Zawiera wszystkie 4 metryki finansowe i szczegóły inwestycji',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Export multiple investors as CSV format
  static void exportInvestorsToClipboard(
    BuildContext context,
    List<InvestorSummary> investors, {
    String? title,
  }) {
    if (investors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brak inwestorów do eksportu'),
          backgroundColor: AppTheme.warningPrimary,
        ),
      );
      return;
    }

    final data = StringBuffer();

    // Header
    data.writeln(title != null ? '=== $title ===' : '=== LISTA INWESTORÓW ===');
    data.writeln('Data eksportu: ${DateTime.now().toString().split('.')[0]}');
    data.writeln('Liczba inwestorów: ${investors.length}');
    data.writeln('');

    // CSV Headers
    data.writeln(
      'Lp;Nazwa;Email;Typ klienta;Status głosowania;Kapitał pozostały;Kwota inwestycji;Kapitał do restrukturyzacji;Zabezpieczony nieruchomościami;Liczba inwestycji',
    );

    // Data rows
    for (var i = 0; i < investors.length; i++) {
      final investor = investors[i];
      data.writeln(
        '${i + 1};'
        '${investor.client.name};'
        '${investor.client.email};'
        '${investor.client.type.displayName};'
        '${investor.client.votingStatus.displayName};'
        '${investor.viableRemainingCapital.toStringAsFixed(2)};'
        '${investor.totalInvestmentAmount.toStringAsFixed(2)};'
        '${investor.capitalForRestructuring.toStringAsFixed(2)};'
        '${investor.capitalSecuredByRealEstate.toStringAsFixed(2)};'
        '${investor.investmentCount}',
      );
    }

    data.writeln('');
    data.writeln('---');
    data.writeln(
      'Eksport CSV wygenerowany przez Metropolitan Investment Analytics',
    );

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: data.toString()));

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.table_chart, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lista inwestorów skopiowana!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Format CSV z wszystkimi metrykami (${investors.length} inwestorów)',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Export summary statistics
  static void exportSummaryStats(
    BuildContext context,
    List<InvestorSummary> investors,
    double totalViableCapital,
  ) {
    final data = StringBuffer();

    // Calculate statistics
    final totalInvestmentAmount = investors.fold<double>(
      0,
      (sum, inv) => sum + inv.totalInvestmentAmount,
    );
    final totalForRestructuring = investors.fold<double>(
      0,
      (sum, inv) => sum + inv.capitalForRestructuring,
    );
    final totalSecuredByRealEstate = investors.fold<double>(
      0,
      (sum, inv) => sum + inv.capitalSecuredByRealEstate,
    );
    final totalInvestments = investors.fold<int>(
      0,
      (sum, inv) => sum + inv.investmentCount,
    );

    final avgCapitalPerInvestor = investors.isNotEmpty
        ? (totalViableCapital / investors.length).toDouble()
        : 0.0;
    final avgInvestmentsPerInvestor = investors.isNotEmpty
        ? (totalInvestments / investors.length).toDouble()
        : 0.0;

    // Header
    data.writeln('=== PODSUMOWANIE STATYSTYK INWESTORÓW ===');
    data.writeln(
      'Data wygenerowania: ${DateTime.now().toString().split('.')[0]}',
    );
    data.writeln('');

    // Basic stats
    data.writeln('PODSTAWOWE STATYSTYKI:');
    data.writeln('• Liczba inwestorów: ${investors.length}');
    data.writeln('• Łączna liczba inwestycji: $totalInvestments');
    data.writeln(
      '• Średnia inwestycji na inwestora: ${avgInvestmentsPerInvestor.toStringAsFixed(1)}',
    );
    data.writeln('');

    // Financial breakdown
    data.writeln('ROZKŁAD FINANSOWY:');
    data.writeln(
      '• Kapitał pozostały (łączny): ${CurrencyFormatter.formatCurrency(totalViableCapital)}',
    );
    data.writeln(
      '• Kwota inwestycji (łączna): ${CurrencyFormatter.formatCurrency(totalInvestmentAmount)}',
    );
    data.writeln(
      '• Do restrukturyzacji (łączny): ${CurrencyFormatter.formatCurrency(totalForRestructuring)}',
    );
    data.writeln(
      '• Zabezpieczony nieruchomościami (łączny): ${CurrencyFormatter.formatCurrency(totalSecuredByRealEstate)}',
    );
    data.writeln('');

    // Averages
    data.writeln('ŚREDNIE WARTOŚCI:');
    data.writeln(
      '• Średni kapitał na inwestora: ${CurrencyFormatter.formatCurrency(avgCapitalPerInvestor)}',
    );
    data.writeln(
      '• Średnia kwota inwestycji: ${CurrencyFormatter.formatCurrency((totalInvestmentAmount / investors.length).toDouble())}',
    );
    data.writeln(
      '• Średni kapitał do restrukturyzacji: ${CurrencyFormatter.formatCurrency((totalForRestructuring / investors.length).toDouble())}',
    );
    data.writeln(
      '• Średni kapitał zabezpieczony: ${CurrencyFormatter.formatCurrency((totalSecuredByRealEstate / investors.length).toDouble())}',
    );
    data.writeln('');

    // Ratios
    final restructuringRatio = totalViableCapital > 0
        ? ((totalForRestructuring / totalViableCapital) * 100).toDouble()
        : 0.0;
    final securityRatio = totalViableCapital > 0
        ? ((totalSecuredByRealEstate / totalViableCapital) * 100).toDouble()
        : 0.0;

    data.writeln('WSKAŹNIKI PROCENTOWE:');
    data.writeln(
      '• Udział kapitału do restrukturyzacji: ${restructuringRatio.toStringAsFixed(1)}%',
    );
    data.writeln(
      '• Udział kapitału zabezpieczonego: ${securityRatio.toStringAsFixed(1)}%',
    );
    data.writeln(
      '• Skuteczność inwestycji: ${((totalViableCapital / totalInvestmentAmount) * 100).toStringAsFixed(1)}%',
    );

    data.writeln('');
    data.writeln('---');
    data.writeln(
      'Statystyki wygenerowane przez Metropolitan Investment Analytics',
    );

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: data.toString()));

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.analytics, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Statystyki skopiowane!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Kompletne podsumowanie wszystkich metryk finansowych',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

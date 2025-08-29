import '../models_and_services.dart';

/// Lightweight compatibility wrapper used by the "new" email editor dialog.
/// This file provides a small surface that the dialog expects (template
/// generation, simple HTML table helpers and a font-family map). The heavy
/// lifting is delegated to existing services where appropriate.
class EnhancedEmailEditorService {
  // Exposed to match previous API used by dialog code
  static const Map<String, String> customFontFamilies = {
    'Arial': 'Arial, sans-serif',
    'Roboto': 'Roboto, sans-serif',
    'Montserrat': 'Montserrat, sans-serif',
  };

  /// Returns a simple default template for the editor.
  String getDefaultTemplate() {
    return '<p>Wiadomość dotycząca portfela inwestycyjnego.</p>';
  }

  /// Generate a voting template for email content
  String generateVotingTemplate() {
    return '''
<div style="border: 1px solid #ddd; padding: 16px; margin: 16px 0; border-radius: 8px; background-color: #f9f9f9;">
  <h3 style="color: #333; margin-top: 0;">📊 Głosowanie - Ważne decyzje</h3>
  <p style="color: #666; margin: 8px 0;">Prosimy o wyrażenie opinii w następujących kwestiach:</p>
  
  <div style="margin: 12px 0;">
    <strong style="color: #333;">1. Czy zgadza się Pan/Pani na proponowane zmiany?</strong>
    <div style="margin: 8px 0 16px 20px;">
      ☐ TAK - zgadzam się<br>
      ☐ NIE - nie zgadzam się<br>
      ☐ WSTRZYMUJĘ SIĘ od głosu
    </div>
  </div>
  
  <div style="margin: 12px 0;">
    <strong style="color: #333;">2. Dodatkowe uwagi:</strong>
    <div style="margin: 8px 0 0 20px; min-height: 40px; border: 1px solid #ccc; padding: 8px; background: white;">
      [Miejsce na uwagi]
    </div>
  </div>
  
  <p style="color: #888; font-size: 12px; margin-bottom: 0;">
    Prosimy o odpowiedź do dnia: <strong>[TERMIN]</strong><br>
    Odpowiedź można przesłać na adres: <strong>biuro@metropolitan-investment.com</strong>
  </p>
</div>
''';
  }

  /// Generate a small HTML table for a single investor. This is intentionally
  /// lightweight — the server/export logic will handle richer tables if needed.
  String generateInvestorTableHtml(InvestorSummary investor) {
    final investments = investor.investments;
    final rows = investments.map((inv) {
      final amount = (inv.remainingCapital != 0 ? inv.remainingCapital : inv.investmentAmount).toString();
      // Use productType property which exists on Investment model
      final type = inv.productType.displayName;
      return '<tr><td>${inv.id}</td><td>$type</td><td>$amount</td></tr>';
    }).join();

    return '''
<table style="width:100%; border-collapse:collapse;">
  <thead><tr><th>ID</th><th>Typ</th><th>Kwota</th></tr></thead>
  <tbody>$rows</tbody>
</table>
''';
  }

  /// Generate an aggregated table for multiple investors (simple summary).
  String generateAggregatedTableHtml(List<InvestorSummary> investors) {
    final buffer = StringBuffer();
    buffer.writeln('<table style="width:100%; border-collapse:collapse;">');
    buffer.writeln('<thead><tr><th>Klient</th><th>Inwestycje</th></tr></thead>');
    buffer.writeln('<tbody>');

    for (final inv in investors) {
      final name = inv.client.name;
      final count = inv.investments.length;
      buffer.writeln('<tr><td>$name</td><td>$count</td></tr>');
    }

    buffer.writeln('</tbody></table>');
    return buffer.toString();
  }
}
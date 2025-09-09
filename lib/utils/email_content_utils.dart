import 'currency_formatter.dart';

/// Utility class for shared email content generation and formatting
class EmailContentUtils {
  /// Generate default email content for HTML editor widget
  static String getDefaultEmailContentForWidget() {
    return '''
<div style="font-family: Inter, Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #333;">
  <h2 style="color: #2c2c2c; margin-bottom: 20px;">Szanowni Państwo,</h2>

  <p style="margin-bottom: 15px;">
    Dziękujemy za zaufanie i inwestycje w nasze produkty. W załączeniu przesyłamy aktualne informacje dotyczące Państwa portfela inwestycyjnego.
  </p>

  <h3 style="color: #2c2c2c; margin-top: 25px; margin-bottom: 15px;">Najważniejsze informacje:</h3>

  <ul style="margin-left: 20px; margin-bottom: 20px;">
    <li style="margin-bottom: 8px;">Aktualna wartość portfela</li>
    <li style="margin-bottom: 8px;">Status wszystkich inwestycji</li>
    <li style="margin-bottom: 8px;">Planowane wypłaty</li>
  </ul>

  <p style="margin-bottom: 15px;">
    W przypadku pytań lub potrzeby dodatkowych informacji, prosimy o kontakt pod numerem telefonu lub poprzez e-mail.
  </p>

  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
    <p style="margin-bottom: 10px;"><strong>Z poważaniem,</strong></p>
    <p style="margin-bottom: 5px;">Zespół Metropolitan Investment</p>
    <p style="font-size: 14px; color: #666;">
      Tel: <a href="tel:+48123456789" style="color: #d4af37; text-decoration: none;">+48 123 456 789</a><br>
      Email: <a href="mailto:biuro@metropolitan-investment.pl" style="color: #d4af37; text-decoration: none;">biuro@metropolitan-investment.pl</a>
    </p>
  </div>
</div>
    '''
        .trim();
  }

  /// Generate default email content for main email editor screen
  static String getDefaultEmailContentForEditor() {
    return '''
<div style="font-family: Inter, Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #333;">
  <h2 style="color: #2c2c2c; margin-bottom: 20px;">Szanowni Państwo,</h2>

  <p style="margin-bottom: 15px;">
    Przesyłamy aktualne informacje dotyczące Państwa inwestycji w Metropolitan Investment.
  </p>

  <h3 style="color: #2c2c2c; margin-top: 25px; margin-bottom: 15px;">Poniżej znajdą Państwo szczegółowe podsumowanie swojego portfela inwestycyjnego. </h3>
  <p>W razie pytań prosimy o kontakt z naszym działem obsługi klienta.</p>


  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
    <p style="margin-bottom: 10px;"><strong>Z poważaniem,</strong></p>
    <p style="margin-bottom: 5px;">Zespół Metropolitan Investment</p>
    <p style="font-size: 14px; color: #666;">
      Tel: <a href="tel:+48123456789" style="color: #d4af37; text-decoration: none;">+48 123 456 789</a><br>
      Email: <a href="mailto:biuro@metropolitan-investment.pl" style="color: #d4af37; text-decoration: none;">biuro@metropolitan-investment.pl</a>
    </p>
  </div>
</div>
    '''
        .trim();
  }

  /// Format currency using the shared CurrencyFormatter
  static String formatCurrency(double amount, {bool showDecimals = true}) {
    return CurrencyFormatter.formatCurrency(amount, showDecimals: showDecimals);
  }

  /// Format currency with short notation (K, M, B)
  static String formatCurrencyShort(double amount) {
    return CurrencyFormatter.formatCurrencyShort(amount);
  }

  /// Get standard email signature
  static String getStandardSignature() {
    return '''
<div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
  <p style="margin-bottom: 10px;"><strong>Z poważaniem,</strong></p>
  <p style="margin-bottom: 5px;">Zespół Metropolitan Investment</p>
  <p style="font-size: 14px; color: #666;">
    Tel: <a href="tel:+48123456789" style="color: #d4af37; text-decoration: none;">+48 123 456 789</a><br>
    Email: <a href="mailto:biuro@metropolitan-investment.pl" style="color: #d4af37; text-decoration: none;">biuro@metropolitan-investment.pl</a>
  </p>
</div>
    '''
        .trim();
  }

  /// Get standard greeting
  static String getStandardGreeting() {
    return '''
<div style="font-family: Inter, Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #333;">
  <h2 style="color: #2c2c2c; margin-bottom: 20px;">Szanowni Państwo,</h2>
</div>
    '''
        .trim();
  }

  /// Get investment update introduction text
  static String getInvestmentUpdateText() {
    return '''
<p style="margin-bottom: 15px;">
  Przesyłamy aktualne informacje dotyczące Państwa inwestycji w Metropolitan Investment.
</p>
    '''
        .trim();
  }

  /// Get portfolio summary header
  static String getPortfolioSummaryHeader() {
    return '''
<h3 style="color: #2c2c2c; margin-top: 25px; margin-bottom: 15px;">Poniżej znajdą Państwo szczegółowe podsumowanie swojego portfela inwestycyjnego.</h3>
<p>W razie pytań prosimy o kontakt z naszym działem obsługi klienta.</p>
    '''
        .trim();
  }

  /// Get trust and investment acknowledgment text
  static String getTrustAcknowledgmentText() {
    return '''
<p style="margin-bottom: 15px;">
  Dziękujemy za zaufanie i inwestycje w nasze produkty. W załączeniu przesyłamy aktualne informacje dotyczące Państwa portfela inwestycyjnego.
</p>
    '''
        .trim();
  }

  /// Get key information header
  static String getKeyInformationHeader() {
    return '''
<h3 style="color: #2c2c2c; margin-top: 25px; margin-bottom: 15px;">Najważniejsze informacje:</h3>
    '''
        .trim();
  }

  /// Get standard information points list
  static String getStandardInformationPoints() {
    return '''
<ul style="margin-left: 20px; margin-bottom: 20px;">
  <li style="margin-bottom: 8px;">Aktualna wartość portfela</li>
  <li style="margin-bottom: 8px;">Status wszystkich inwestycji</li>
  <li style="margin-bottom: 8px;">Planowane wypłaty</li>
</ul>
    '''
        .trim();
  }

  /// Get contact information text
  static String getContactInformationText() {
    return '''
<p style="margin-bottom: 15px;">
  W przypadku pytań lub potrzeby dodatkowych informacji, prosimy o kontakt pod numerem telefonu lub poprzez e-mail.
</p>
    '''
        .trim();
  }
}

import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/investment.dart';
import '../models/product.dart';
import '../services/investor_analytics_service.dart';

class EmailService {
  static const String _companyName = 'Metropolitan Investment';
  static const String _companyEmail = 'biuro@metropolitan-investment.pl';

  // Generuj szablon maila dla inwestora
  static String generateInvestorEmailTemplate({
    required Client client,
    required List<Investment> investments,
    String? customMessage,
    bool includeInvestmentDetails = true,
  }) {
    final StringBuffer emailBody = StringBuffer();

    // Nagłówek
    emailBody.writeln('Szanowny/a ${client.name},');
    emailBody.writeln('');

    // Wiadomość niestandardowa
    if (customMessage?.isNotEmpty == true) {
      emailBody.writeln(customMessage);
      emailBody.writeln('');
    }

    // Szczegóły inwestycji
    if (includeInvestmentDetails && investments.isNotEmpty) {
      emailBody.writeln(
        'Poniżej przedstawiamy aktualny stan Państwa inwestycji:',
      );
      emailBody.writeln('');

      double totalRemainingCapital = 0;
      double totalSharesValue = 0;
      double totalInvestmentAmount = 0;

      for (final investment in investments) {
        emailBody.writeln('• ${investment.productName}');
        emailBody.writeln(
          '  - Kwota inwestycji: ${investment.investmentAmount.toStringAsFixed(2)} PLN',
        );

        if (investment.productType == ProductType.shares) {
          emailBody.writeln('  - Typ: Udziały');
          totalSharesValue += investment.investmentAmount;
        } else {
          emailBody.writeln(
            '  - Kapitał pozostały: ${investment.remainingCapital.toStringAsFixed(2)} PLN',
          );
          emailBody.writeln(
            '  - Odsetki pozostałe: ${investment.remainingInterest.toStringAsFixed(2)} PLN',
          );
          totalRemainingCapital += investment.remainingCapital;
        }

        emailBody.writeln(
          '  - Spółka: ${investment.creditorCompany.isNotEmpty ? investment.creditorCompany : investment.companyId}',
        );
        emailBody.writeln('');

        totalInvestmentAmount += investment.investmentAmount;
      }

      // Podsumowanie
      emailBody.writeln('PODSUMOWANIE:');
      emailBody.writeln(
        '• Łączna kwota inwestycji: ${totalInvestmentAmount.toStringAsFixed(2)} PLN',
      );
      if (totalRemainingCapital > 0) {
        emailBody.writeln(
          '• Łączny kapitał pozostały: ${totalRemainingCapital.toStringAsFixed(2)} PLN',
        );
      }
      if (totalSharesValue > 0) {
        emailBody.writeln(
          '• Łączna wartość udziałów: ${totalSharesValue.toStringAsFixed(2)} PLN',
        );
      }
      emailBody.writeln(
        '• Łączna wartość portfela: ${(totalRemainingCapital + totalSharesValue).toStringAsFixed(2)} PLN',
      );
      emailBody.writeln('');
    }

    // Stopka
    emailBody.writeln('W razie pytań prosimy o kontakt.');
    emailBody.writeln('');
    emailBody.writeln('Z poważaniem,');
    emailBody.writeln('Zespół $_companyName');
    emailBody.writeln('Email: $_companyEmail');

    return emailBody.toString();
  }

  // Generuj temat maila
  static String generateEmailSubject({
    required String purpose,
    String? customSubject,
  }) {
    if (customSubject?.isNotEmpty == true) {
      return customSubject!;
    }

    switch (purpose) {
      case 'portfolio_update':
        return 'Aktualizacja portfela inwestycyjnego - $_companyName';
      case 'voting_notification':
        return 'Powiadomienie o głosowaniu - $_companyName';
      case 'meeting_invitation':
        return 'Zaproszenie na spotkanie - $_companyName';
      case 'document_request':
        return 'Prośba o dokumenty - $_companyName';
      default:
        return 'Informacja od $_companyName';
    }
  }

  // Otwórz klienta email z przygotowanym mailem
  static Future<bool> openEmailClient({
    required List<String> recipients,
    required String subject,
    required String body,
    List<String> cc = const [],
    List<String> bcc = const [],
  }) async {
    try {
      final StringBuffer emailUri = StringBuffer('mailto:');

      // Odbiorcy
      if (recipients.isNotEmpty) {
        emailUri.write(recipients.join(','));
      }

      // Parametry
      final List<String> params = [];

      if (subject.isNotEmpty) {
        params.add('subject=${Uri.encodeComponent(subject)}');
      }

      if (body.isNotEmpty) {
        params.add('body=${Uri.encodeComponent(body)}');
      }

      if (cc.isNotEmpty) {
        params.add('cc=${Uri.encodeComponent(cc.join(','))}');
      }

      if (bcc.isNotEmpty) {
        params.add('bcc=${Uri.encodeComponent(bcc.join(','))}');
      }

      if (params.isNotEmpty) {
        emailUri.write('?${params.join('&')}');
      }

      final uri = Uri.parse(emailUri.toString());

      // Próba otwarcia URI
      debugPrint('Otwieranie URI: ${uri.toString()}');
      // W rzeczywistej implementacji można użyć url_launcher
      return false; // Tymczasowo zwracamy false
    } catch (e) {
      debugPrint('Błąd podczas otwierania klienta email: $e');
      return false;
    }
  }

  // Generuj maile grupowe dla inwestorów
  static Future<List<EmailData>> generateBulkEmails({
    required List<String> clientIds,
    required InvestorAnalyticsService analyticsService,
    required String purpose,
    String? customMessage,
    String? customSubject,
    bool includeInvestmentDetails = true,
  }) async {
    try {
      final List<EmailData> emails = [];
      final investorData = await analyticsService.getInvestorsByClientIds(clientIds);

      for (final data in investorData) {
        if (data.client.email.isNotEmpty) {
          final subject = generateEmailSubject(
            purpose: purpose,
            customSubject: customSubject,
          );

          final body = generateInvestorEmailTemplate(
            client: data.client,
            investments: data.investments,
            customMessage: customMessage,
            includeInvestmentDetails: includeInvestmentDetails,
          );

          emails.add(
            EmailData(
              recipient: data.client.email,
              recipientName: data.client.name,
              subject: subject,
              body: body,
              client: data.client,
              investments: data.investments,
            ),
          );
        }
      }

      return emails;
    } catch (e) {
      debugPrint('Błąd podczas generowania maili grupowych: $e');
      return [];
    }
  }

  // Eksportuj listę maili do CSV
  static String generateEmailListCSV(List<EmailData> emails) {
    final StringBuffer csv = StringBuffer();

    // Nagłówki
    csv.writeln('Nazwa,Email,Liczba inwestycji,Wartość portfela');

    // Dane
    for (final email in emails) {
      final totalValue = email.investments.fold<double>(
        0.0,
        (sum, inv) =>
            sum +
            inv.remainingCapital +
            (inv.productType == ProductType.shares ? inv.investmentAmount : 0),
      );

      csv.writeln(
        '"${email.recipientName}","${email.recipient}",${email.investments.length},"${totalValue.toStringAsFixed(2)} PLN"',
      );
    }

    return csv.toString();
  }

  // Generuj szablon newsletter dla wszystkich inwestorów
  static String generateNewsletterTemplate({
    required String title,
    required String content,
    String? additionalInfo,
  }) {
    final StringBuffer newsletter = StringBuffer();

    newsletter.writeln('Szanowni Państwo,');
    newsletter.writeln('');
    newsletter.writeln(title);
    newsletter.writeln('');
    newsletter.writeln(content);
    newsletter.writeln('');

    if (additionalInfo?.isNotEmpty == true) {
      newsletter.writeln(additionalInfo);
      newsletter.writeln('');
    }

    newsletter.writeln('Dziękujemy za zaufanie i współpracę.');
    newsletter.writeln('');
    newsletter.writeln('Z poważaniem,');
    newsletter.writeln('Zespół $_companyName');
    newsletter.writeln('Email: $_companyEmail');

    return newsletter.toString();
  }

  // Sprawdź poprawność adresu email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Wyczyść listę maili (usuń duplikaty, nieprawidłowe adresy)
  static List<String> cleanEmailList(List<String> emails) {
    return emails
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty && isValidEmail(email))
        .toSet() // Usuń duplikaty
        .toList();
  }
}

// Klasa reprezentująca dane email
class EmailData {
  final String recipient;
  final String recipientName;
  final String subject;
  final String body;
  final Client client;
  final List<Investment> investments;

  EmailData({
    required this.recipient,
    required this.recipientName,
    required this.subject,
    required this.body,
    required this.client,
    required this.investments,
  });

  // Oblicz całkowitą wartość portfela
  double get totalPortfolioValue {
    return investments.fold<double>(
      0.0,
      (sum, inv) =>
          sum +
          inv.remainingCapital +
          (inv.productType == ProductType.shares ? inv.investmentAmount : 0),
    );
  }

  // Sprawdź czy inwestor ma niewykonalne inwestycje
  bool get hasUnviableInvestments {
    return client.unviableInvestments.isNotEmpty;
  }

  // Lista niewykonalnych inwestycji
  List<Investment> get unviableInvestments {
    return investments
        .where((inv) => client.unviableInvestments.contains(inv.id))
        .toList();
  }
}

// Szablony maili dla różnych celów
class EmailTemplates {
  // Szablon powiadomienia o głosowaniu
  static String votingNotificationTemplate({
    required String votingTopic,
    required DateTime meetingDate,
    required String meetingLocation,
    String? additionalInfo,
  }) {
    return '''
Uprzejmie informujemy o zbliżającym się głosowaniu dotyczącym: $votingTopic

Szczegóły spotkania:
• Data: ${meetingDate.day}/${meetingDate.month}/${meetingDate.year}
• Godzina: ${meetingDate.hour}:${meetingDate.minute.toString().padLeft(2, '0')}
• Miejsce: $meetingLocation

${additionalInfo ?? ''}

Prosimy o potwierdzenie uczestnictwa oraz poinformowanie nas o swojej decyzji dotyczącej głosowania.

Państwa udział w procesie decyzyjnym jest dla nas bardzo ważny.
''';
  }

  // Szablon aktualizacji portfela
  static String portfolioUpdateTemplate({
    required String updatePeriod,
    String? marketSummary,
    String? importantChanges,
  }) {
    return '''
Przekazujemy Państwu aktualizację portfela inwestycyjnego za okres: $updatePeriod

${marketSummary ?? ''}

${importantChanges ?? ''}

W załączeniu znajdą Państwo szczegółowe zestawienie swoich inwestycji.

Zachęcamy do kontaktu w przypadku jakichkolwiek pytań.
''';
  }

  // Szablon zaproszenia na spotkanie
  static String meetingInvitationTemplate({
    required String meetingPurpose,
    required DateTime meetingDate,
    required String meetingLocation,
    String? agenda,
  }) {
    return '''
Zapraszamy Państwa na spotkanie w sprawie: $meetingPurpose

Szczegóły:
• Data: ${meetingDate.day}/${meetingDate.month}/${meetingDate.year}
• Godzina: ${meetingDate.hour}:${meetingDate.minute.toString().padLeft(2, '0')}
• Miejsce: $meetingLocation

${agenda != null ? 'Agenda spotkania:\n$agenda\n' : ''}

Prosimy o potwierdzenie uczestnictwa do ${DateTime.now().add(const Duration(days: 3)).day}/${DateTime.now().add(const Duration(days: 3)).month}/${DateTime.now().add(const Duration(days: 3)).year}.
''';
  }
}

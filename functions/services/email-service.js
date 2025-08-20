/**
 * Email Service - Wysyłanie maili do inwestorów
 * 
 * Serwis obsługujący wysyłanie maili z listą inwestycji klientów,
 * raportami i podsumowaniami finansowymi.
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Wysyłanie listy inwestycji do klienta
 * • Generowanie raportów PDF
 * • Personalizowane szablony email
 * • Bezpieczne dane osobowe
 * • Historia wysłanych maili
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString, formatCurrency } = require("../utils/data-mapping");

// Import nodemailer for email sending
const nodemailer = require('nodemailer');

/**
 * Wysyła email z listą inwestycji do klienta
 * 
 * @param {Object} data - Dane wejściowe
 * @param {string} data.clientId - ID klienta
 * @param {string} data.clientEmail - Email klienta  
 * @param {string} data.clientName - Nazwa klienta
 * @param {string[]} data.investmentIds - Lista ID inwestycji (opcjonalnie)
 * @param {string} data.emailTemplate - Typ szablonu ('summary'|'detailed'|'custom')
 * @param {string} data.subject - Temat maila (opcjonalnie)
 * @param {string} data.customMessage - Dodatkowa wiadomość (opcjonalnie)
 * @param {string} data.senderEmail - Email wysyłającego
 * @param {string} data.senderName - Nazwa wysyłającego
 * 
 * @returns {Object} Wynik wysyłania maila
 */
const sendInvestmentEmailToClient = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`📧 [EmailService] Rozpoczynam wysyłanie maila do klienta`);
  console.log(`📊 [EmailService] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

  try {
    const {
      clientId,
      clientEmail,
      clientName,
      investmentIds = null,
      emailTemplate = 'summary',
      subject = null,
      customMessage = '',
      senderEmail,
      senderName = 'Metropolitan Investment'
    } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!clientId || !clientEmail || !clientName) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagane są: clientId, clientEmail, clientName'
      );
    }

    if (!senderEmail) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagany jest senderEmail (email wysyłającego)'
      );
    }

    // Walidacja formatu email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(clientEmail)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email klienta');
    }
    if (!emailRegex.test(senderEmail)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email wysyłającego');
    }

    // 🔍 POBIERZ INWESTYCJE KLIENTA
    console.log(`🔍 [EmailService] Wyszukuję inwestycje dla klienta: ${clientId}`);

    let query = db.collection('investments').where('clientId', '==', clientId);

    // Jeśli podano konkretne ID inwestycji, filtruj po nich
    if (investmentIds && investmentIds.length > 0) {
      query = query.where('id', 'in', investmentIds.slice(0, 10)); // Firestore limit: max 10 items in 'in' query
    }

    const investmentsSnapshot = await query.get();

    if (investmentsSnapshot.empty) {
      throw new HttpsError(
        'not-found',
        `Nie znaleziono inwestycji dla klienta ${clientName} (${clientId})`
      );
    }

    const investments = investmentsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`✅ [EmailService] Znaleziono ${investments.length} inwestycji dla klienta`);

    // 📊 OBLICZ PODSUMOWANIA FINANSOWE
    let totalInvestmentAmount = 0;
    let totalRemainingCapital = 0;
    let totalRealizedCapital = 0;
    let totalCapitalSecured = 0;
    let totalCapitalForRestructuring = 0;

    const investmentSummaries = investments.map(investment => {
      const investmentAmount = safeToDouble(investment.investmentAmount || investment.kwota_inwestycji || 0);
      const remainingCapital = safeToDouble(investment.remainingCapital || investment.kapital_pozostaly || 0);
      const realizedCapital = safeToDouble(investment.realizedCapital || investment.kapital_zrealizowany || 0);
      const capitalSecured = safeToDouble(investment.capitalSecuredByRealEstate || investment.kapital_zabezpieczony_nieruchomoscami || 0);
      const capitalForRestructuring = safeToDouble(investment.capitalForRestructuring || investment.kapital_do_restrukturyzacji || 0);

      totalInvestmentAmount += investmentAmount;
      totalRemainingCapital += remainingCapital;
      totalRealizedCapital += realizedCapital;
      totalCapitalSecured += capitalSecured;
      totalCapitalForRestructuring += capitalForRestructuring;

      return {
        id: investment.id,
        productName: safeToString(investment.productName || investment.nazwa_produktu || 'Nieokreślony produkt'),
        productType: safeToString(investment.productType || investment.typ_produktu || 'Nieokreślony typ'),
        investmentAmount,
        remainingCapital,
        realizedCapital,
        capitalSecured,
        capitalForRestructuring,
        signedDate: investment.signedDate || investment.data_podpisania || null,
        status: investment.status || 'active'
      };
    });

    // 📧 GENERUJ TREŚĆ EMAIL
    const emailContent = generateEmailContent({
      clientName,
      investments: investmentSummaries,
      totals: {
        totalInvestmentAmount,
        totalRemainingCapital,
        totalRealizedCapital,
        totalCapitalSecured,
        totalCapitalForRestructuring
      },
      template: emailTemplate,
      customMessage,
      senderName
    });

    // 📬 WYŚLIJ EMAIL
    console.log(`📧 [EmailService] Wysyłam email do: ${clientEmail}`);

    const mailOptions = {
      from: `${senderName} <${senderEmail}>`,
      to: clientEmail,
      subject: subject || `Twoje inwestycje w ${senderName} - podsumowanie`,
      html: emailContent.html,
      text: emailContent.text,
      // Opcjonalnie: załączniki PDF
      attachments: emailContent.attachments || []
    };

    // Konfiguracja SMTP (należy skonfigurować w Firebase Config)
    const transporter = createEmailTransporter();
    const emailResult = await transporter.sendMail(mailOptions);

    console.log(`✅ [EmailService] Email wysłany pomyślnie. MessageId: ${emailResult.messageId}`);

    // 📝 ZAPISZ HISTORIĘ WYSŁANIA MAILA
    const historyRecord = {
      clientId,
      clientEmail,
      clientName,
      senderEmail,
      senderName,
      subject: mailOptions.subject,
      investmentCount: investments.length,
      totalAmount: totalInvestmentAmount,
      template: emailTemplate,
      sentAt: new Date(),
      messageId: emailResult.messageId,
      status: 'sent',
      executionTimeMs: Date.now() - startTime
    };

    try {
      await db.collection('email_history').add(historyRecord);
      console.log(`📝 [EmailService] Historia maila zapisana`);
    } catch (historyError) {
      console.warn(`⚠️ [EmailService] Nie udało się zapisać historii:`, historyError);
    }

    // 🎯 ZWRÓĆ WYNIK
    const result = {
      success: true,
      messageId: emailResult.messageId,
      clientEmail,
      clientName,
      investmentCount: investments.length,
      totalAmount: totalInvestmentAmount,
      executionTimeMs: Date.now() - startTime,
      template: emailTemplate
    };

    console.log(`🎉 [EmailService] Email wysłany pomyślnie w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error(`❌ [EmailService] Błąd podczas wysyłania maila:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else if (error.code === 'EAUTH' || error.code === 'ENOTFOUND') {
      throw new HttpsError(
        'internal',
        'Błąd konfiguracji serwera email. Skontaktuj się z administratorem.',
        error.message
      );
    } else {
      throw new HttpsError(
        'internal',
        'Błąd podczas wysyłania maila',
        error.message
      );
    }
  }
});

/**
 * Tworzy transporter email (SMTP)
 */
async function createEmailTransporter() {
  console.log("🔄 [EmailService] Pobieranie konfiguracji SMTP z Firestore...");
  try {
    const smtpConfigDoc = await db.collection('app_settings').doc('smtp_configuration').get();

    if (!smtpConfigDoc.exists) {
      console.error("❌ [EmailService] Brak konfiguracji SMTP w Firestore! Używam fallback.");
      // Fallback do zmiennych środowiskowych jeśli dokument nie istnieje
      return createTransporterFromEnv();
    }

    const settings = smtpConfigDoc.data();
    const config = {
      host: settings.host,
      port: settings.port,
      secure: settings.security === 'ssl' || settings.port === 465, // SSL dla portu 465
      auth: {
        user: settings.username,
        pass: settings.password, // Hasło powinno być odczytywane z bezpiecznego miejsca
      },
      // Opcjonalne: Wymuś TLS jeśli jest wybrane
      requireTLS: settings.security === 'tls',
    };

    console.log(`✅ [EmailService] Konfiguracja SMTP załadowana z Firestore: ${config.host}:${config.port}`);
    return nodemailer.createTransport(config);
  } catch (error) {
    console.error("❌ [EmailService] Błąd podczas pobierania konfiguracji SMTP z Firestore. Używam fallback.", error);
    return createTransporterFromEnv();
  }
}

/**
 * Tworzy transporter ze zmiennych środowiskowych (fallback)
 */
function createTransporterFromEnv() {
  // W produkcji należy skonfigurować przez Firebase Config
  // firebase functions:config:set email.smtp_host="smtp.gmail.com" email.smtp_user="your@gmail.com" email.smtp_password="password"

  // Odczytaj konfigurację z Firebase Config lub zmiennych środowiskowych
  const functions = require('firebase-functions');
  
  // Próba odczytu z Firebase Config
  const emailConfig = functions.config().email || {};
  
  const config = {
    host: process.env.SMTP_HOST || emailConfig.smtp_host || 'smtp.office365.com',
    port: parseInt(process.env.SMTP_PORT || emailConfig.smtp_port) || 587,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER || emailConfig.smtp_user,
      pass: process.env.SMTP_PASSWORD || emailConfig.smtp_password
    }
  };

  // Sprawdź czy mamy wymagane dane uwierzytelniania
  if (!config.auth.user || !config.auth.pass) {
    throw new Error('Brak konfiguracji SMTP. Skonfiguruj zmienne środowiskowe lub Firebase Config.');
  }

  console.log(`📧 [EmailService] Konfiguracja SMTP (fallback z env): ${config.host}:${config.port} (user: ${config.auth.user})`);
  return nodemailer.createTransport(config);
}

/**
 * Generuje treść email na podstawie szablonu
 */
function generateEmailContent({ clientName, investments, totals, template, customMessage, senderName }) {
  const formatPLN = (amount) => `${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} PLN`;

  // HTML Template
  let html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: #1a237e; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .summary { background: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .investment { border: 1px solid #ddd; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .total { font-weight: bold; color: #1a237e; }
        .footer { background: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #666; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #1a237e; color: white; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>${senderName}</h1>
        <h2>Podsumowanie Twoich Inwestycji</h2>
      </div>
      
      <div class="content">
        <p>Szanowny/a <strong>${clientName}</strong>,</p>
        
        ${customMessage ? `<p><em>${customMessage}</em></p>` : ''}
        
        <p>Przesyłamy aktualne podsumowanie Twoich inwestycji w naszej firmie:</p>

        <div class="summary">
          <h3>📊 Podsumowanie Finansowe</h3>
          <p><strong>Liczba inwestycji:</strong> ${investments.length}</p>
          <p><strong>Całkowita kwota inwestycji:</strong> <span class="total">${formatPLN(totals.totalInvestmentAmount)}</span></p>
          <p><strong>Kapitał pozostały:</strong> <span class="total">${formatPLN(totals.totalRemainingCapital)}</span></p>
          <p><strong>Kapitał zrealizowany:</strong> ${formatPLN(totals.totalRealizedCapital)}</p>
          ${totals.totalCapitalSecured > 0 ? `<p><strong>Kapitał zabezpieczony:</strong> ${formatPLN(totals.totalCapitalSecured)}</p>` : ''}
          ${totals.totalCapitalForRestructuring > 0 ? `<p><strong>Kapitał do restrukturyzacji:</strong> ${formatPLN(totals.totalCapitalForRestructuring)}</p>` : ''}
        </div>
  `;

  // Szczegółowa tabela inwestycji (jeśli template == 'detailed')
  if (template === 'detailed' || template === 'custom') {
    html += `
        <h3>📋 Szczegółowa Lista Inwestycji</h3>
        <table>
          <thead>
            <tr>
              <th>Produkt</th>
              <th>Typ</th>
              <th>Kwota Inwestycji</th>
              <th>Kapitał Pozostały</th>
              <th>Kapitał Zrealizowany</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
    `;

    investments.forEach(investment => {
      html += `
            <tr>
              <td>${investment.productName}</td>
              <td>${investment.productType}</td>
              <td>${formatPLN(investment.investmentAmount)}</td>
              <td>${formatPLN(investment.remainingCapital)}</td>
              <td>${formatPLN(investment.realizedCapital)}</td>
              <td>${investment.status}</td>
            </tr>
      `;
    });

    html += `
          </tbody>
        </table>
    `;
  }

  html += `
        <p>W razie pytań, prosimy o kontakt z naszym działem obsługi klienta.</p>
        
        <p>Z poważaniem,<br>
        <strong>${senderName}</strong></p>
      </div>
      
      <div class="footer">
        <p>Ten email został wygenerowany automatycznie ${new Date().toLocaleString('pl-PL')}.</p>
        <p>Metropolitan Investment - Zarządzanie Kapitałem</p>
      </div>
    </body>
    </html>
  `;

  // Text version (fallback)
  let text = `
${senderName}
Podsumowanie Twoich Inwestycji

Szanowny/a ${clientName},

${customMessage || ''}

Przesyłamy aktualne podsumowanie Twoich inwestycji:

PODSUMOWANIE FINANSOWE:
- Liczba inwestycji: ${investments.length}
- Całkowita kwota inwestycji: ${formatPLN(totals.totalInvestmentAmount)}
- Kapitał pozostały: ${formatPLN(totals.totalRemainingCapital)}
- Kapitał zrealizowany: ${formatPLN(totals.totalRealizedCapital)}
${totals.totalCapitalSecured > 0 ? `- Kapitał zabezpieczony: ${formatPLN(totals.totalCapitalSecured)}\n` : ''}
${totals.totalCapitalForRestructuring > 0 ? `- Kapitał do restrukturyzacji: ${formatPLN(totals.totalCapitalForRestructuring)}\n` : ''}

  `;

  if (template === 'detailed' || template === 'custom') {
    text += `
SZCZEGÓŁOWA LISTA INWESTYCJI:
`;
    investments.forEach((investment, index) => {
      text += `
${index + 1}. ${investment.productName}
   - Typ: ${investment.productType}
   - Kwota inwestycji: ${formatPLN(investment.investmentAmount)}
   - Kapitał pozostały: ${formatPLN(investment.remainingCapital)}
   - Kapitał zrealizowany: ${formatPLN(investment.realizedCapital)}
   - Status: ${investment.status}
`;
    });
  }

  text += `
W razie pytań, prosimy o kontakt z naszym działem obsługi klienta.

Z poważaniem,
${senderName}

---
Ten email został wygenerowany automatycznie ${new Date().toLocaleString('pl-PL')}.
Metropolitan Investment - Zarządzanie Kapitałem
  `;

  return { html, text };
}

module.exports = {
  sendInvestmentEmailToClient,
};

/**
 * Custom Email Service - Wysyłanie niestandardowych maili HTML
 * 
 * Serwis obsługujący wysyłanie spersonalizowanych maili HTML
 * z treścią wygenerowaną przez edytor Quill z aplikacji Flutter.
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Wysyłanie maili HTML z niestandardową treścią
 * • Personalizacja dla każdego odbiorcy
 * • Opcjonalne dołączanie szczegółów inwestycji
 * • Bezpieczne dane osobowe
 * • Historia wysłanych maili
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Inicjalizacja bazy danych
const db = admin.firestore();

/**
 * ✉️ Wysyła niestandardowe maile do mieszanej listy odbiorców (inwestorzy + dodatkowe emaile)
 * 
 * @param {Object} request.data - Dane żądania
 * @param {Array} request.data.recipients - Lista odbiorców (inwestorzy)
 * @param {Array} request.data.additionalEmails - Lista dodatkowych adresów email
 * @param {string} request.data.htmlContent - Treść HTML maila
 * @param {string} request.data.subject - Temat maila
 * @param {boolean} request.data.includeInvestmentDetails - Czy dołączyć szczegóły inwestycji
 * @param {string} request.data.senderEmail - Email wysyłającego
 * @param {string} request.data.senderName - Nazwa wysyłającego
 * @returns {Promise<Object>} Wyniki wysyłania
 */
const sendEmailsToMixedRecipients = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`📧 [MixedEmailService] Rozpoczynam wysyłanie do mieszanej listy odbiorców`);
  console.log(`📊 [MixedEmailService] Dane wejściowe:`, JSON.stringify({
    recipientCount: request.data.recipients?.length || 0,
    additionalEmailsCount: request.data.additionalEmails?.length || 0,
    subject: request.data.subject,
    includeInvestmentDetails: request.data.includeInvestmentDetails,
    senderEmail: request.data.senderEmail,
    htmlContentLength: request.data.htmlContent?.length || 0,
  }, null, 2));

  try {
    const {
      recipients = [],
      additionalEmails = [],
      htmlContent,
      subject,
      includeInvestmentDetails = false,
      senderEmail,
      senderName = 'Metropolitan Investment'
    } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    const totalRecipients = recipients.length + additionalEmails.length;
    if (totalRecipients === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Lista odbiorców (inwestorzy + dodatkowe emaile) nie może być pusta'
      );
    }

    if (!htmlContent || htmlContent.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Treść HTML nie może być pusta'
      );
    }

    if (!senderEmail) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagany jest email wysyłającego'
      );
    }

    if (!subject || subject.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Temat maila jest wymagany'
      );
    }

    // Walidacja formatu email wysyłającego
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(senderEmail)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email wysyłającego');
    }

    // Walidacja dodatkowych emaili
    for (const email of additionalEmails) {
      if (!emailRegex.test(email)) {
        throw new HttpsError('invalid-argument', `Nieprawidłowy format dodatkowego email: ${email}`);
      }
    }

    // Ograniczenie liczby odbiorców
    if (totalRecipients > 100) {
      throw new HttpsError('invalid-argument', 'Maksymalna liczba odbiorców w jednej operacji: 100');
    }

    console.log(`📧 [MixedEmailService] Przetwarzam ${recipients.length} inwestorów + ${additionalEmails.length} dodatkowych emaili`);

    // 📬 PRZETWÓRZ I WYŚLIJ MAILE
    const results = [];
    const transporter = await createEmailTransporter();

    // 📧 WYŚLIJ DO INWESTORÓW
    for (const recipient of recipients) {
      const recipientStartTime = Date.now();

      try {
        // Walidacja danych odbiorcy
        if (!recipient.clientEmail || !emailRegex.test(recipient.clientEmail)) {
          console.warn(`⚠️ [MixedEmailService] Nieprawidłowy email inwestora: ${recipient.clientEmail}`);
          results.push({
            success: false,
            messageId: '',
            recipientEmail: recipient.clientEmail || '',
            recipientName: recipient.clientName || 'Nieznany',
            recipientType: 'investor',
            investmentCount: recipient.investmentCount || 0,
            totalAmount: recipient.totalAmount || 0,
            executionTimeMs: Date.now() - recipientStartTime,
            template: 'mixed_custom_html',
            error: 'Nieprawidłowy adres email inwestora'
          });
          continue;
        }

        // 📊 POBIERZ INWESTYCJE ODBIORCY (jeśli wymagane)
        let investmentDetailsHtml = '';
        if (includeInvestmentDetails && recipient.clientId) {
          investmentDetailsHtml = await getInvestmentDetailsForClient(recipient.clientId);
        }

        // 📧 GENERUJ SPERSONALIZOWANĄ TREŚĆ EMAIL DLA INWESTORA
        const personalizedHtml = generatePersonalizedEmailContent({
          clientName: recipient.clientName,
          htmlContent: htmlContent,
          investmentDetailsHtml: investmentDetailsHtml,
          senderName: senderName,
          totalAmount: recipient.totalAmount || 0,
          investmentCount: recipient.investmentCount || 0
        });

        // 📬 WYŚLIJ EMAIL DO INWESTORA
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: recipient.clientEmail,
          subject: subject,
          html: personalizedHtml,
          text: stripHtmlTags(personalizedHtml),
        };

        const emailResult = await transporter.sendMail(mailOptions);

        console.log(`✅ [MixedEmailService] Email wysłany do inwestora ${recipient.clientName} (${recipient.clientEmail}). MessageId: ${emailResult.messageId}`);

        results.push({
          success: true,
          messageId: emailResult.messageId,
          recipientEmail: recipient.clientEmail,
          recipientName: recipient.clientName,
          recipientType: 'investor',
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'mixed_custom_html'
        });

      } catch (recipientError) {
        console.error(`❌ [MixedEmailService] Błąd wysyłania do inwestora ${recipient.clientName}:`, recipientError);

        results.push({
          success: false,
          messageId: '',
          recipientEmail: recipient.clientEmail || '',
          recipientName: recipient.clientName || 'Nieznany',
          recipientType: 'investor',
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'mixed_custom_html',
          error: recipientError.message || recipientError.toString()
        });
      }
    }

    // 📧 WYŚLIJ DO DODATKOWYCH EMAILI
    for (let i = 0; i < additionalEmails.length; i++) {
      const email = additionalEmails[i];
      const recipientStartTime = Date.now();

      try {
        // 📧 GENERUJ PODSTAWOWĄ TREŚĆ EMAIL DLA DODATKOWEGO ODBIORCY
        const basicHtml = generateBasicEmailContent({
          htmlContent: htmlContent,
          senderName: senderName,
          recipientEmail: email
        });

        // 📬 WYŚLIJ EMAIL DO DODATKOWEGO ODBIORCY
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: email,
          subject: subject,
          html: basicHtml,
          text: stripHtmlTags(basicHtml),
        };

        const emailResult = await transporter.sendMail(mailOptions);

        console.log(`✅ [MixedEmailService] Email wysłany do dodatkowego odbiorcy (${email}). MessageId: ${emailResult.messageId}`);

        results.push({
          success: true,
          messageId: emailResult.messageId,
          recipientEmail: email,
          recipientName: email, // Dla dodatkowych emaili nazwa = email
          recipientType: 'additional',
          investmentCount: 0,
          totalAmount: 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'mixed_basic_html'
        });

      } catch (recipientError) {
        console.error(`❌ [MixedEmailService] Błąd wysyłania do dodatkowego email ${email}:`, recipientError);

        results.push({
          success: false,
          messageId: '',
          recipientEmail: email,
          recipientName: email,
          recipientType: 'additional',
          investmentCount: 0,
          totalAmount: 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'mixed_basic_html',
          error: recipientError.message || recipientError.toString()
        });
      }
    }

    // 📝 ZAPISZ HISTORIĘ WYSŁANIA MAILI
    const successful = results.filter(r => r.success).length;
    const failed = results.length - successful;
    const investorResults = results.filter(r => r.recipientType === 'investor');
    const additionalResults = results.filter(r => r.recipientType === 'additional');

    const historyRecord = {
      operation: 'mixed_recipients_bulk_email',
      totalRecipients: totalRecipients,
      investorCount: recipients.length,
      additionalEmailCount: additionalEmails.length,
      successful: successful,
      failed: failed,
      successfulInvestors: investorResults.filter(r => r.success).length,
      failedInvestors: investorResults.length - investorResults.filter(r => r.success).length,
      successfulAdditional: additionalResults.filter(r => r.success).length,
      failedAdditional: additionalResults.length - additionalResults.filter(r => r.success).length,
      subject: subject,
      senderEmail: senderEmail,
      senderName: senderName,
      includeInvestmentDetails: includeInvestmentDetails,
      htmlContentLength: htmlContent.length,
      sentAt: new Date(),
      executionTimeMs: Date.now() - startTime,
      results: results.map(r => ({
        recipientEmail: r.recipientEmail,
        recipientName: r.recipientName,
        recipientType: r.recipientType,
        success: r.success,
        error: r.error || null
      }))
    };

    try {
      await db.collection('email_history').add(historyRecord);
      console.log(`📝 [MixedEmailService] Historia maili zapisana`);
    } catch (historyError) {
      console.warn(`⚠️ [MixedEmailService] Nie udało się zapisać historii:`, historyError);
    }

    // 🎯 ZWRÓĆ WYNIK
    const finalResult = {
      success: true,
      results: results,
      summary: {
        total: totalRecipients,
        successful: successful,
        failed: failed,
        investors: {
          total: recipients.length,
          successful: investorResults.filter(r => r.success).length,
          failed: investorResults.length - investorResults.filter(r => r.success).length
        },
        additional: {
          total: additionalEmails.length,
          successful: additionalResults.filter(r => r.success).length,
          failed: additionalResults.length - additionalResults.filter(r => r.success).length
        },
        successRate: totalRecipients > 0 ? (successful / totalRecipients * 100).toFixed(1) : '0.0',
        executionTimeMs: Date.now() - startTime
      }
    };

    console.log(`🎉 [MixedEmailService] Wysłano ${successful}/${totalRecipients} maili pomyślnie (${investorResults.filter(r => r.success).length} inwestorów + ${additionalResults.filter(r => r.success).length} dodatkowych) w ${Date.now() - startTime}ms`);
    return finalResult;

  } catch (error) {
    console.error(`❌ [MixedEmailService] Błąd podczas wysyłania maili:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else if (error.code === 'EAUTH' || error.code === 'ENOTFOUND') {
      throw new HttpsError(
        'internal',
        'Błąd konfiguracji serwera email. Skontaktuj się z administratorem.',
        error
      );
    } else {
      throw new HttpsError(
        'internal',
        `Błąd serwera podczas wysyłania maili: ${error.message}`,
        error
      );
    }
  }
});

/**
 * Generuje podstawową treść email dla dodatkowych odbiorców (bez szczegółów inwestycji)
 */
function generateBasicEmailContent({ htmlContent, senderName, recipientEmail }) {
  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wiadomość od ${senderName}</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            max-width: 600px; 
            margin: 0 auto; 
            padding: 20px; 
            background-color: #f4f4f4;
        }
        .email-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header { 
            background: linear-gradient(135deg, #1a237e, #3949ab); 
            color: white; 
            padding: 30px 20px; 
            text-align: center; 
            border-radius: 8px 8px 0 0; 
            margin: -30px -30px 30px -30px;
        }
        .content { 
            background: white; 
            padding: 20px 0; 
        }
        .footer { 
            background: #f5f5f5; 
            padding: 20px; 
            text-align: center; 
            font-size: 14px; 
            color: #666; 
            border-radius: 0 0 8px 8px; 
            margin: 30px -30px -30px -30px;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>${senderName}</h1>
            <p>Wiadomość dla Ciebie</p>
        </div>
        
        <div class="content">
            <p><strong>Szanowni Państwo,</strong></p>
            <div class="message-content">
                ${htmlContent}
            </div>
        </div>
        
        <div class="footer">
            <p>Ten email został wygenerowany automatycznie ${new Date().toLocaleString('pl-PL')}.</p>
            <p><strong>${senderName}</strong> - Profesjonalne Zarządzanie Kapitałem</p>
        </div>
    </div>
</body>
</html>`;
}

/**
 * Wysyła niestandardowe maile HTML do wielu klientów
 * 
 * @param {Object} data - Dane wejściowe
 * @param {Array} data.recipients - Lista odbiorców [{clientId, clientEmail, clientName, investmentCount, totalAmount}]
 * @param {string} data.htmlContent - Treść HTML z edytora Quill
 * @param {string} data.subject - Temat maila
 * @param {boolean} data.includeInvestmentDetails - Czy dołączyć szczegóły inwestycji
 * @param {string} data.senderEmail - Email wysyłającego
 * @param {string} data.senderName - Nazwa wysyłającego
 * 
 * @returns {Object} Wynik wysyłania maili
 */
const sendCustomHtmlEmailsToMultipleClients = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`📧 [CustomEmailService] Rozpoczynam wysyłanie niestandardowych maili HTML`);
  console.log(`📊 [CustomEmailService] Dane wejściowe:`, JSON.stringify({
    recipientCount: request.data.recipients?.length || 0,
    subject: request.data.subject,
    includeInvestmentDetails: request.data.includeInvestmentDetails,
    senderEmail: request.data.senderEmail,
    htmlContentLength: request.data.htmlContent?.length || 0,
  }, null, 2));

  try {
    const {
      recipients,
      htmlContent,
      subject,
      includeInvestmentDetails = false,
      senderEmail,
      senderName = 'Metropolitan Investment'
    } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Lista odbiorców nie może być pusta'
      );
    }

    if (!htmlContent || htmlContent.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Treść HTML nie może być pusta'
      );
    }

    if (!senderEmail) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagany jest email wysyłającego'
      );
    }

    if (!subject || subject.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Temat maila jest wymagany'
      );
    }

    // Walidacja formatu email wysyłającego
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(senderEmail)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email wysyłającego');
    }

    // Ograniczenie liczby odbiorców
    if (recipients.length > 100) {
      throw new HttpsError('invalid-argument', 'Maksymalna liczba odbiorców w jednej operacji: 100');
    }

    console.log(`📧 [CustomEmailService] Przetwarzam ${recipients.length} odbiorców`);

    // 📬 PRZETWÓRZ I WYŚLIJ MAILE
    const results = [];
    const transporter = await createEmailTransporter();

    for (const recipient of recipients) {
      const recipientStartTime = Date.now();

      try {
        // Walidacja danych odbiorcy
        if (!recipient.clientEmail || !emailRegex.test(recipient.clientEmail)) {
          console.warn(`⚠️ [CustomEmailService] Nieprawidłowy email odbiorcy: ${recipient.clientEmail}`);
          results.push({
            success: false,
            messageId: '',
            clientEmail: recipient.clientEmail || '',
            clientName: recipient.clientName || 'Nieznany',
            investmentCount: recipient.investmentCount || 0,
            totalAmount: recipient.totalAmount || 0,
            executionTimeMs: Date.now() - recipientStartTime,
            template: 'custom_html',
            error: 'Nieprawidłowy adres email odbiorcy'
          });
          continue;
        }

        // 📊 POBIERZ INWESTYCJE ODBIORCY (jeśli wymagane)
        let investmentDetailsHtml = '';
        if (includeInvestmentDetails && recipient.clientId) {
          investmentDetailsHtml = await getInvestmentDetailsForClient(recipient.clientId);
        }

        // 📧 GENERUJ SPERSONALIZOWANĄ TREŚĆ EMAIL
        const personalizedHtml = generatePersonalizedEmailContent({
          clientName: recipient.clientName,
          htmlContent: htmlContent,
          investmentDetailsHtml: investmentDetailsHtml,
          senderName: senderName,
          totalAmount: recipient.totalAmount || 0,
          investmentCount: recipient.investmentCount || 0
        });

        // 📬 WYŚLIJ EMAIL
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: recipient.clientEmail,
          subject: subject,
          html: personalizedHtml,
          text: stripHtmlTags(personalizedHtml), // Wersja tekstowa jako fallback
        };

        const emailResult = await transporter.sendMail(mailOptions);

        console.log(`✅ [CustomEmailService] Email wysłany do ${recipient.clientName} (${recipient.clientEmail}). MessageId: ${emailResult.messageId}`);

        results.push({
          success: true,
          messageId: emailResult.messageId,
          clientEmail: recipient.clientEmail,
          clientName: recipient.clientName,
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'custom_html'
        });

      } catch (recipientError) {
        console.error(`❌ [CustomEmailService] Błąd wysyłania do ${recipient.clientName}:`, recipientError);

        results.push({
          success: false,
          messageId: '',
          clientEmail: recipient.clientEmail || '',
          clientName: recipient.clientName || 'Nieznany',
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'custom_html',
          error: recipientError.message || recipientError.toString()
        });
      }
    }

    // 📝 ZAPISZ HISTORIĘ WYSŁANIA MAILI
    const successful = results.filter(r => r.success).length;
    const failed = results.length - successful;

    const historyRecord = {
      operation: 'custom_html_bulk_email',
      recipientCount: recipients.length,
      successful: successful,
      failed: failed,
      subject: subject,
      senderEmail: senderEmail,
      senderName: senderName,
      includeInvestmentDetails: includeInvestmentDetails,
      htmlContentLength: htmlContent.length,
      sentAt: new Date(),
      executionTimeMs: Date.now() - startTime,
      results: results.map(r => ({
        clientEmail: r.clientEmail,
        clientName: r.clientName,
        success: r.success,
        error: r.error || null
      }))
    };

    try {
      await db.collection('email_history').add(historyRecord);
      console.log(`📝 [CustomEmailService] Historia maili zapisana`);
    } catch (historyError) {
      console.warn(`⚠️ [CustomEmailService] Nie udało się zapisać historii:`, historyError);
    }

    // 🎯 ZWRÓĆ WYNIK
    const finalResult = {
      success: true,
      results: results,
      summary: {
        total: recipients.length,
        successful: successful,
        failed: failed,
        successRate: recipients.length > 0 ? (successful / recipients.length * 100).toFixed(1) : '0.0',
        executionTimeMs: Date.now() - startTime
      }
    };

    console.log(`🎉 [CustomEmailService] Wysłano ${successful}/${recipients.length} maili pomyślnie w ${Date.now() - startTime}ms`);
    return finalResult;

  } catch (error) {
    console.error(`❌ [CustomEmailService] Błąd podczas wysyłania maili:`, error);

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
        'Błąd podczas wysyłania maili',
        error.message
      );
    }
  }
});

/**
 * Pobiera szczegóły inwestycji dla klienta i generuje HTML
 */
async function getInvestmentDetailsForClient(clientId) {
  try {
    console.log(`🔍 [CustomEmailService] Wyszukuję inwestycje dla klienta: ${clientId}`);

    const investmentsSnapshot = await db.collection('investments')
      .where('clientId', '==', clientId)
      .get();

    if (investmentsSnapshot.empty) {
      return '<p><em>Brak inwestycji do wyświetlenia.</em></p>';
    }

    const investments = investmentsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Oblicz podsumowania
    let totalInvestmentAmount = 0;
    let totalRemainingCapital = 0;
    let totalRealizedCapital = 0;

    const investmentRows = investments.map(investment => {
      const investmentAmount = safeToDouble(investment.investmentAmount || investment.kwota_inwestycji || 0);
      const remainingCapital = safeToDouble(investment.remainingCapital || investment.kapital_pozostaly || 0);
      const realizedCapital = safeToDouble(investment.realizedCapital || investment.kapital_zrealizowany || 0);

      totalInvestmentAmount += investmentAmount;
      totalRemainingCapital += remainingCapital;
      totalRealizedCapital += realizedCapital;

      return `
        <tr>
          <td>${safeToString(investment.productName || investment.nazwa_produktu || 'Nieokreślony produkt')}</td>
          <td>${formatCurrency(investmentAmount)}</td>
          <td>${formatCurrency(remainingCapital)}</td>
          <td>${formatCurrency(realizedCapital)}</td>
          <td>${investment.status || 'Aktywna'}</td>
        </tr>
      `;
    }).join('');

    return `
      <div class="investment-details">
        <h3>📊 Podsumowanie Twojego Portfela</h3>
        <div class="summary">
          <p><strong>Liczba inwestycji:</strong> ${investments.length}</p>
          <p><strong>Całkowita kwota inwestycji:</strong> <span class="total">${formatCurrency(totalInvestmentAmount)}</span></p>
          <p><strong>Kapitał pozostały:</strong> <span class="total">${formatCurrency(totalRemainingCapital)}</span></p>
          <p><strong>Kapitał zrealizowany:</strong> ${formatCurrency(totalRealizedCapital)}</p>
        </div>
        
        <h3>📋 Szczegóły Inwestycji</h3>
        <table class="investment-table">
          <thead>
            <tr>
              <th>Produkt</th>
              <th>Kwota Inwestycji</th>
              <th>Kapitał Pozostały</th>
              <th>Kapitał Zrealizowany</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            ${investmentRows}
          </tbody>
        </table>
      </div>
    `;

  } catch (error) {
    console.error(`❌ [CustomEmailService] Błąd pobierania inwestycji dla klienta ${clientId}:`, error);
    return '<p><em>Błąd podczas pobierania danych inwestycji.</em></p>';
  }
}

/**
 * Generuje spersonalizowaną treść email
 */
function generatePersonalizedEmailContent({
  clientName,
  htmlContent,
  investmentDetailsHtml,
  senderName,
  totalAmount,
  investmentCount
}) {
  // Podstawowe CSS dla email
  const emailStyles = `
    <style>
      body { 
        font-family: Arial, sans-serif; 
        line-height: 1.6; 
        color: #333; 
        max-width: 600px; 
        margin: 0 auto; 
        padding: 20px; 
      }
      .header { 
        background: linear-gradient(135deg, #1a237e, #3949ab); 
        color: white; 
        padding: 30px 20px; 
        text-align: center; 
        border-radius: 8px 8px 0 0; 
        margin-bottom: 0;
      }
      .content { 
        background: white; 
        padding: 30px; 
        border: 1px solid #e0e0e0; 
        border-top: none;
      }
      .summary { 
        background: #f8f9fa; 
        padding: 20px; 
        margin: 20px 0; 
        border-radius: 8px; 
        border-left: 4px solid #1a237e; 
      }
      .footer { 
        background: #f5f5f5; 
        padding: 20px; 
        text-align: center; 
        font-size: 14px; 
        color: #666; 
        border-radius: 0 0 8px 8px; 
        border: 1px solid #e0e0e0;
        border-top: none;
      }
      .investment-details {
        margin: 20px 0;
      }
      .investment-table { 
        width: 100%; 
        border-collapse: collapse; 
        margin: 20px 0; 
      }
      .investment-table th, 
      .investment-table td { 
        border: 1px solid #ddd; 
        padding: 12px; 
        text-align: left; 
      }
      .investment-table th { 
        background-color: #1a237e; 
        color: white; 
      }
      .total { 
        font-weight: bold; 
        color: #1a237e; 
        font-size: 18px; 
      }
      .user-content {
        margin: 20px 0;
        line-height: 1.8;
      }
      .user-content h1, .user-content h2, .user-content h3 {
        color: #1a237e;
        margin-top: 30px;
        margin-bottom: 15px;
      }
      .user-content p {
        margin-bottom: 15px;
      }
      .user-content ul, .user-content ol {
        margin-left: 20px;
        margin-bottom: 15px;
      }
      .user-content li {
        margin-bottom: 8px;
      }
      .user-content strong {
        color: #1a237e;
      }
      .user-content em {
        font-style: italic;
        color: #666;
      }
    </style>
  `;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      ${emailStyles}
    </head>
    <body>
      <div class="header">
        <h1>${senderName}</h1>
        <h2>Wiadomość Dla Ciebie</h2>
      </div>
      
      <div class="content">
        <p><strong>Szanowny/a ${clientName},</strong></p>
        
        <div class="user-content">
          ${htmlContent}
        </div>
        
        ${investmentDetailsHtml}
      </div>
      
      <div class="footer">
        <p>Ten email został wysłany ${new Date().toLocaleString('pl-PL')}.</p>
        <p><strong>${senderName}</strong> - Profesjonalne Zarządzanie Kapitałem</p>
        <p>W razie pytań, prosimy o kontakt z naszym działem obsługi klienta.</p>
      </div>
    </body>
    </html>
  `;
}

/**
 * Usuwa tagi HTML i zwraca czysty tekst
 */
function stripHtmlTags(html) {
  return html
    .replace(/<[^>]*>/g, '') // Usuń wszystkie tagi HTML
    .replace(/&nbsp;/g, ' ') // Zamień &nbsp; na spacje
    .replace(/&lt;/g, '<')   // Dekoduj podstawowe encje HTML
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')    // Normalizuj białe znaki
    .trim();
}

/**
 * Tworzy transporter email (SMTP) - współdzielony z email-service.js
 */
async function createEmailTransporter() {
  console.log("🔄 [CustomEmailService] Pobieranie konfiguracji SMTP z Firestore...");
  try {
    const smtpConfigDoc = await db.collection('app_settings').doc('smtp_configuration').get();

    if (!smtpConfigDoc.exists) {
      console.error("❌ [CustomEmailService] Brak konfiguracji SMTP w Firestore! Używam fallback.");
      return createTransporterFromEnv();
    }

    const settings = smtpConfigDoc.data();
    const config = {
      host: settings.host,
      port: settings.port,
      secure: settings.security === 'ssl' || settings.port === 465,
      auth: {
        user: settings.username,
        pass: settings.password,
      },
      requireTLS: settings.security === 'tls',
    };

    console.log(`✅ [CustomEmailService] Konfiguracja SMTP załadowana z Firestore: ${config.host}:${config.port}`);
    return nodemailer.createTransport(config);
  } catch (error) {
    console.error("❌ [CustomEmailService] Błąd podczas pobierania konfiguracji SMTP z Firestore. Używam fallback.", error);
    return createTransporterFromEnv();
  }
}

/**
 * Tworzy transporter ze zmiennych środowiskowych (fallback)
 */
function createTransporterFromEnv() {
  const functions = require('firebase-functions');
  const emailConfig = functions.config().email || {};

  const config = {
    host: process.env.SMTP_HOST || emailConfig.smtp_host || 'smtp.office365.com',
    port: parseInt(process.env.SMTP_PORT || emailConfig.smtp_port) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER || emailConfig.smtp_user,
      pass: process.env.SMTP_PASSWORD || emailConfig.smtp_password
    }
  };

  if (!config.auth.user || !config.auth.pass) {
    throw new Error('Brak konfiguracji SMTP. Skonfiguruj zmienne środowiskowe lub Firebase Config.');
  }

  console.log(`📧 [CustomEmailService] Konfiguracja SMTP (fallback z env): ${config.host}:${config.port} (user: ${config.auth.user})`);
  return nodemailer.createTransport(config);
}

module.exports = {
  sendCustomHtmlEmailsToMultipleClients,
  sendEmailsToMixedRecipients,
};
/**
 * Email Service - DEVELOPMENT VERSION (bez nodemailer)
 * 
 * Tymczasowa wersja do testowania bez instalacji nodemailer.
 * W produkcji należy zainstalować nodemailer i użyć pełnej wersji.
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

console.log("⚠️  [EmailService] Uruchomiono w trybie DEVELOPMENT (bez nodemailer)");

/**
 * Wysyła email z listą inwestycji do klienta (MOCK VERSION)
 */
const sendInvestmentEmailToClient = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const startTime = Date.now();
  console.log(`📧 [EmailService-DEV] MOCK - Symulacja wysyłania maila`);
  console.log(`📊 [EmailService-DEV] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

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
    console.log(`🔍 [EmailService-DEV] Wyszukuję inwestycje dla klienta: ${clientId}`);

    let query = db.collection('investments').where('clientId', '==', clientId);

    if (investmentIds && investmentIds.length > 0) {
      query = query.where('id', 'in', investmentIds.slice(0, 10));
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

    console.log(`✅ [EmailService-DEV] Znaleziono ${investments.length} inwestycji`);

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

    // 📧 GENERUJ TREŚĆ EMAIL (MOCK)
    const emailContent = generateMockEmailContent({
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

    // 🎭 SYMULUJ WYSYŁANIE EMAIL
    console.log(`📧 [EmailService-DEV] MOCK - Symulacja wysyłania do: ${clientEmail}`);
    console.log(`📋 [EmailService-DEV] Temat: ${subject || `Twoje inwestycje w ${senderName} - podsumowanie`}`);
    console.log(`📄 [EmailService-DEV] Treść (HTML, ${emailContent.html.length} znaków)`);
    console.log(`📄 [EmailService-DEV] Treść (TEXT, ${emailContent.text.length} znaków)`);

    // Symulacja opóźnienia wysyłania
    await new Promise(resolve => setTimeout(resolve, 100 + Math.random() * 300));

    const mockMessageId = `dev-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    console.log(`✅ [EmailService-DEV] MOCK - Email "wysłany" pomyślnie. MessageId: ${mockMessageId}`);

    // 📝 ZAPISZ HISTORIĘ WYSŁANIA MAILA (DEV)
    const historyRecord = {
      clientId,
      clientEmail,
      clientName,
      senderEmail,
      senderName,
      subject: subject || `Twoje inwestycje w ${senderName} - podsumowanie`,
      investmentCount: investments.length,
      totalAmount: totalInvestmentAmount,
      template: emailTemplate,
      sentAt: new Date(),
      messageId: mockMessageId,
      status: 'sent-mock-dev',
      executionTimeMs: Date.now() - startTime,
      mockMode: true
    };

    try {
      await db.collection('email_history').add(historyRecord);
      console.log(`📝 [EmailService-DEV] Historia maila zapisana (DEV mode)`);
    } catch (historyError) {
      console.warn(`⚠️ [EmailService-DEV] Nie udało się zapisać historii:`, historyError);
    }

    // 🎯 ZWRÓĆ WYNIK
    const result = {
      success: true,
      messageId: mockMessageId,
      clientEmail,
      clientName,
      investmentCount: investments.length,
      totalAmount: totalInvestmentAmount,
      executionTimeMs: Date.now() - startTime,
      template: emailTemplate,
      mockMode: true,
      warning: '⚠️ DEVELOPMENT MODE - Email nie został faktycznie wysłany. Zainstaluj nodemailer do pracy w trybie produkcyjnym.'
    };

    console.log(`🎉 [EmailService-DEV] MOCK Email zakończony w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error(`❌ [EmailService-DEV] Błąd podczas mock wysyłania:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else {
      throw new HttpsError(
        'internal',
        'Błąd podczas symulacji wysyłania maila (DEV mode)',
        error.message
      );
    }
  }
});

/**
 * Batch wysyłanie maili (MOCK VERSION)
 */
const sendEmailsToMultipleClients = onCall({
  memory: "1GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const startTime = Date.now();
  console.log(`📧 [EmailService-DEV] MOCK - Batch wysyłanie maili`);

  try {
    const {
      clientIds,
      emailTemplate = 'summary',
      subject = null,
      customMessage = '',
      senderEmail,
      senderName = 'Metropolitan Investment'
    } = request.data;

    if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
      throw new HttpsError('invalid-argument', 'Wymagana jest lista clientIds');
    }

    if (clientIds.length > 100) {
      throw new HttpsError('invalid-argument', 'Maksymalna liczba klientów w batch: 100');
    }

    const results = [];
    let successCount = 0;
    let errorCount = 0;

    for (const clientId of clientIds) {
      try {
        // Symuluj pojedyncze wysyłanie
        console.log(`📧 [EmailService-DEV] MOCK - Przetwarzam klienta: ${clientId}`);

        // Symulacja opóźnienia
        await new Promise(resolve => setTimeout(resolve, 50 + Math.random() * 100));

        // Symuluj 95% sukcesu
        if (Math.random() < 0.95) {
          const mockMessageId = `dev-batch-${Date.now()}-${clientId}`;
          results.push({
            success: true,
            clientId,
            messageId: mockMessageId,
            mockMode: true
          });
          successCount++;
        } else {
          results.push({
            success: false,
            clientId,
            error: 'Mock network error',
            mockMode: true
          });
          errorCount++;
        }

      } catch (clientError) {
        console.error(`❌ [EmailService-DEV] Mock błąd dla klienta ${clientId}:`, clientError);
        results.push({
          success: false,
          clientId,
          error: clientError.message,
          mockMode: true
        });
        errorCount++;
      }
    }

    console.log(`🎉 [EmailService-DEV] MOCK Batch zakończony: ${successCount} sukces, ${errorCount} błędów`);

    return {
      success: true,
      totalClients: clientIds.length,
      successCount,
      errorCount,
      results,
      executionTimeMs: Date.now() - startTime,
      mockMode: true,
      warning: '⚠️ DEVELOPMENT MODE - Maile nie zostały faktycznie wysłane'
    };

  } catch (error) {
    console.error(`❌ [EmailService-DEV] Błąd batch mock:`, error);
    throw new HttpsError('internal', 'Błąd batch mock wysyłania', error.message);
  }
});

/**
 * Generuje mock treść email
 */
function generateMockEmailContent({ clientName, investments, totals, template, customMessage, senderName }) {
  const formatPLN = (amount) => `${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} PLN`;

  // Skrócona wersja dla DEV
  const html = `
    <html>
    <body style="font-family: Arial, sans-serif;">
      <div style="background: #1a237e; color: white; padding: 20px; text-align: center;">
        <h1>${senderName}</h1>
        <h2>Podsumowanie Inwestycji (DEV MODE)</h2>
      </div>
      
      <div style="padding: 20px;">
        <p>Szanowny/a <strong>${clientName}</strong>,</p>
        
        ${customMessage ? `<p><em>${customMessage}</em></p>` : ''}
        
        <div style="background: #f5f5f5; padding: 15px; margin: 20px 0;">
          <h3>📊 Podsumowanie Finansowe</h3>
          <p><strong>Liczba inwestycji:</strong> ${investments.length}</p>
          <p><strong>Kapitał pozostały:</strong> ${formatPLN(totals.totalRemainingCapital)}</p>
          <p><strong>Kwota inwestycji:</strong> ${formatPLN(totals.totalInvestmentAmount)}</p>
        </div>

        ${template === 'detailed' ? `
        <h3>📋 Lista Inwestycji</h3>
        <ul>
          ${investments.slice(0, 5).map(inv =>
    `<li>${inv.productName} - ${formatPLN(inv.remainingCapital)}</li>`
  ).join('')}
          ${investments.length > 5 ? `<li>... i ${investments.length - 5} więcej</li>` : ''}
        </ul>
        ` : ''}
        
        <p>Z poważaniem,<br><strong>${senderName}</strong></p>
        
        <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; margin: 20px 0;">
          <strong>⚠️ DEVELOPMENT MODE</strong><br>
          Ten email został wygenerowany w trybie deweloperskim i nie został faktycznie wysłany.
        </div>
      </div>
    </body>
    </html>
  `;

  const text = `
${senderName} - Podsumowanie Inwestycji (DEV MODE)

Szanowny/a ${clientName},

${customMessage || ''}

PODSUMOWANIE FINANSOWE:
- Liczba inwestycji: ${investments.length}
- Kapitał pozostały: ${formatPLN(totals.totalRemainingCapital)}
- Kwota inwestycji: ${formatPLN(totals.totalInvestmentAmount)}

Z poważaniem,
${senderName}

⚠️ DEVELOPMENT MODE - Email nie został faktycznie wysłany.
  `;

  return { html, text };
}

module.exports = {
  sendInvestmentEmailToClient,
  sendEmailsToMultipleClients,
};

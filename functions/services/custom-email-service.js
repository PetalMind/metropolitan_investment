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
 * ✉️ Wysyła pre-generowane emaile (kompletny HTML przygotowany na frontendzie)
 * 
 * Ta funkcja używa kompletnego HTML przygotowanego na frontendzie (identycznego z podglądem)
 * eliminując różnice między podglądem a wysyłanymi emailami.
 * 
 * @param {Object} request.data - Dane żądania
 * @param {Array} request.data.recipients - Lista odbiorców (inwestorzy)
 * @param {Array} request.data.additionalEmails - Lista dodatkowych adresów email
 * @param {string} request.data.subject - Temat maila
 * @param {Object} request.data.completeEmailHtmlByClient - Mapa clientId -> kompletny HTML email
 * @param {string} request.data.aggregatedEmailHtmlForAdditionals - Kompletny HTML dla dodatkowych odbiorców
 * @param {string} request.data.senderEmail - Email wysyłającego
 * @param {string} request.data.senderName - Nazwa wysyłającego
 * @returns {Promise<Object>} Wyniki wysyłania
 */
const sendPreGeneratedEmails = onCall(async (request) => {
  const startTime = Date.now();
  console.log(`📧 [PreGeneratedEmailService] Rozpoczynam wysyłanie pre-generowanych emaili`);
  console.log(`📊 [PreGeneratedEmailService] Dane wejściowe:`, JSON.stringify({
    recipientCount: request.data.recipients?.length || 0,
    additionalEmailsCount: request.data.additionalEmails?.length || 0,
    subject: request.data.subject,
    hasCompleteEmailHtmlByClient: !!(request.data.completeEmailHtmlByClient && Object.keys(request.data.completeEmailHtmlByClient).length > 0),
    hasAggregatedEmailHtmlForAdditionals: !!(request.data.aggregatedEmailHtmlForAdditionals && request.data.aggregatedEmailHtmlForAdditionals.length > 0),
    senderEmail: request.data.senderEmail,
  }, null, 2));

  try {
    const {
      recipients = [],
      additionalEmails = [],
      subject,
      completeEmailHtmlByClient = null,
      aggregatedEmailHtmlForAdditionals = null,
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

    if (!senderEmail) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagany jest email wysyłającego'
      );
    }

    if (!subject || subject.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Temat maila nie może być pusty'
      );
    }

    // Walidacja email addresses
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(senderEmail)) {
      throw new HttpsError('invalid-argument', `Nieprawidłowy format email wysyłającego: ${senderEmail}`);
    }

    for (const email of additionalEmails) {
      if (!emailRegex.test(email)) {
        throw new HttpsError('invalid-argument', `Nieprawidłowy format dodatkowego email: ${email}`);
      }
    }

    // Ograniczenie liczby odbiorców
    if (totalRecipients > 100) {
      throw new HttpsError('invalid-argument', 'Maksymalna liczba odbiorców w jednej operacji: 100');
    }

    console.log(`📧 [PreGeneratedEmailService] Przetwarzam ${recipients.length} inwestorów + ${additionalEmails.length} dodatkowych emaili`);

    // 📬 PRZETWÓRZ I WYŚLIJ MAILE
    const results = [];
    const transporter = await createEmailTransporter();

    // 📧 WYŚLIJ DO INWESTORÓW
    for (const recipient of recipients) {
      const recipientStartTime = Date.now();

      try {
        // Walidacja danych odbiorcy
        if (!recipient.clientEmail || !emailRegex.test(recipient.clientEmail)) {
          console.warn(`⚠️ [PreGeneratedEmailService] Nieprawidłowy email inwestora: ${recipient.clientEmail}`);
          results.push({
            success: false,
            messageId: '',
            recipientEmail: recipient.clientEmail || '',
            recipientName: recipient.clientName || 'Nieznany',
            recipientType: 'investor',
            investmentCount: recipient.investmentCount || 0,
            totalAmount: recipient.totalAmount || 0,
            executionTimeMs: Date.now() - recipientStartTime,
            template: 'pre_generated_html',
            error: 'Nieprawidłowy adres email inwestora'
          });
          continue;
        }

        // 📧 POBIERZ KOMPLETNY HTML Z FRONTENDU
        let emailHtml = '';
        if (completeEmailHtmlByClient && completeEmailHtmlByClient[recipient.clientId]) {
          emailHtml = completeEmailHtmlByClient[recipient.clientId];
          console.log(`✅ [PreGeneratedEmailService] Używam pre-generowanego HTML dla ${recipient.clientName} (${emailHtml.length} chars)`);
        } else {
          console.warn(`⚠️ [PreGeneratedEmailService] Brak pre-generowanego HTML dla ${recipient.clientName} (ID: ${recipient.clientId})`);
          results.push({
            success: false,
            messageId: '',
            recipientEmail: recipient.clientEmail,
            recipientName: recipient.clientName || 'Nieznany',
            recipientType: 'investor',
            investmentCount: recipient.investmentCount || 0,
            totalAmount: recipient.totalAmount || 0,
            executionTimeMs: Date.now() - recipientStartTime,
            template: 'pre_generated_html',
            error: 'Brak pre-generowanego HTML dla tego klienta'
          });
          continue;
        }

        // 📬 WYŚLIJ EMAIL DO INWESTORA
        const normalizedHtml = normalizeQuillHtml(emailHtml);
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: recipient.clientEmail,
          subject: subject,
          html: normalizedHtml,
          text: stripHtmlTags(normalizedHtml),
        };

        const emailResult = await transporter.sendMail(mailOptions);
        console.log(`✅ [PreGeneratedEmailService] Email wysłany do inwestora ${recipient.clientName} (${recipient.clientEmail}). MessageId: ${emailResult.messageId}`);

        results.push({
          success: true,
          messageId: emailResult.messageId,
          recipientEmail: recipient.clientEmail,
          recipientName: recipient.clientName,
          recipientType: 'investor',
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'pre_generated_html'
        });

      } catch (recipientError) {
        console.error(`❌ [PreGeneratedEmailService] Błąd wysyłania do inwestora ${recipient.clientName}:`, recipientError);
        results.push({
          success: false,
          messageId: '',
          recipientEmail: recipient.clientEmail || '',
          recipientName: recipient.clientName || 'Nieznany',
          recipientType: 'investor',
          investmentCount: recipient.investmentCount || 0,
          totalAmount: recipient.totalAmount || 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'pre_generated_html',
          error: recipientError.message || recipientError.toString()
        });
      }
    }

    // 📧 WYŚLIJ DO DODATKOWYCH ODBIORCÓW
    for (const email of additionalEmails) {
      const recipientStartTime = Date.now();

      try {
        let emailHtml = '';
        if (aggregatedEmailHtmlForAdditionals && aggregatedEmailHtmlForAdditionals.trim().length > 0) {
          emailHtml = aggregatedEmailHtmlForAdditionals;
          console.log(`✅ [PreGeneratedEmailService] Używam pre-generowanego zbiorczego HTML dla ${email}`);
        } else {
          console.warn(`⚠️ [PreGeneratedEmailService] Brak pre-generowanego zbiorczego HTML dla ${email}`);
          results.push({
            success: false,
            messageId: '',
            recipientEmail: email,
            recipientName: email,
            recipientType: 'additional',
            investmentCount: 0,
            totalAmount: 0,
            executionTimeMs: Date.now() - recipientStartTime,
            template: 'pre_generated_html',
            error: 'Brak pre-generowanego HTML dla dodatkowych odbiorców'
          });
          continue;
        }

        // 📬 WYŚLIJ EMAIL DO DODATKOWEGO ODBIORCY
        const normalizedHtml = normalizeQuillHtml(emailHtml);
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: email,
          subject: subject,
          html: normalizedHtml,
          text: stripHtmlTags(normalizedHtml),
        };

        const emailResult = await transporter.sendMail(mailOptions);
        console.log(`✅ [PreGeneratedEmailService] Email wysłany do dodatkowego odbiorcy (${email}). MessageId: ${emailResult.messageId}`);

        results.push({
          success: true,
          messageId: emailResult.messageId,
          recipientEmail: email,
          recipientName: email,
          recipientType: 'additional',
          investmentCount: 0,
          totalAmount: 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'pre_generated_html'
        });

      } catch (recipientError) {
        console.error(`❌ [PreGeneratedEmailService] Błąd wysyłania do dodatkowego email ${email}:`, recipientError);
        results.push({
          success: false,
          messageId: '',
          recipientEmail: email,
          recipientName: email,
          recipientType: 'additional',
          investmentCount: 0,
          totalAmount: 0,
          executionTimeMs: Date.now() - recipientStartTime,
          template: 'pre_generated_html',
          error: recipientError.message || recipientError.toString()
        });
      }
    }

    // 📊 PODSUMOWANIE WYNIKÓW
    const successful = results.filter(r => r.success).length;
    const failed = results.length - successful;

    console.log(`📊 [PreGeneratedEmailService] Podsumowanie:`);
    console.log(`   ✅ Pomyślnie: ${successful}`);
    console.log(`   ❌ Błędy: ${failed}`);
    console.log(`   ⏱️ Całkowity czas: ${Date.now() - startTime}ms`);

    // 📝 ZAPISZ HISTORIĘ WYSŁANIA MAILI
    const historyRecord = {
      service: 'PreGeneratedEmailService',
      action: 'sendPreGeneratedEmails',
      successful: successful,
      failed: failed,
      totalRecipients: totalRecipients,
      subject: subject,
      senderEmail: senderEmail,
      senderName: senderName,
      hasCompleteEmailHtmlByClient: !!(completeEmailHtmlByClient && Object.keys(completeEmailHtmlByClient).length > 0),
      hasAggregatedEmailHtmlForAdditionals: !!(aggregatedEmailHtmlForAdditionals && aggregatedEmailHtmlForAdditionals.length > 0),
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
      console.log(`📝 [PreGeneratedEmailService] Historia maili zapisana`);
    } catch (historyError) {
      console.warn(`⚠️ [PreGeneratedEmailService] Nie udało się zapisać historii:`, historyError);
    }

    return {
      success: true,
      message: `Emaile pre-generowane wysłane: ${successful} pomyślnie, ${failed} błędów`,
      results: results,
      summary: {
        totalSent: results.length,
        successful: successful,
        failed: failed,
        executionTimeMs: Date.now() - startTime
      }
    };

  } catch (error) {
    console.error(`❌ [PreGeneratedEmailService] Błąd wysyłania pre-generowanych emaili:`, error);

    return {
      success: false,
      message: `Błąd wysyłania pre-generowanych emaili: ${error.message}`,
      results: [],
      summary: {
        totalSent: 0,
        successful: 0,
        failed: 0,
        executionTimeMs: Date.now() - startTime
      }
    };
  }
});

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
    hasInvestmentDetailsByClient: !!(request.data.investmentDetailsByClient && Object.keys(request.data.investmentDetailsByClient).length > 0),
    hasAggregatedInvestmentsForAdditionals: !!(request.data.aggregatedInvestmentsForAdditionals && request.data.aggregatedInvestmentsForAdditionals.length > 0),
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
      investmentDetailsByClient = null,
      aggregatedInvestmentsForAdditionals = null,
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

        // 📊 POBIERZ INWESTYCJE ODBIORCY (klient może dostarczyć gotowy HTML)
        let investmentDetailsHtml = '';
        if (includeInvestmentDetails) {
          console.log(`🔍 [MixedEmailService] Sprawdzam inwestycje dla ${recipient.clientName} (ID: ${recipient.clientId})`);
          console.log(`   - investmentDetailsByClient exists: ${!!(investmentDetailsByClient && Object.keys(investmentDetailsByClient).length > 0)}`);
          console.log(`   - Available client IDs: ${investmentDetailsByClient ? Object.keys(investmentDetailsByClient).join(', ') : 'none'}`);

          if (investmentDetailsByClient && investmentDetailsByClient[recipient.clientId]) {
            // Use deterministic client-provided HTML
            investmentDetailsHtml = investmentDetailsByClient[recipient.clientId];
            console.log(`✅ [MixedEmailService] Używam gotowej tabeli z frontendu dla ${recipient.clientName} (${investmentDetailsHtml.length} chars)`);
          } else if (recipient.clientId) {
            // Fallback: fetch from Firestore
            console.log(`🔄 [MixedEmailService] Pobieram inwestycje z Firestore dla ${recipient.clientName}`);
            investmentDetailsHtml = await getInvestmentDetailsForClient(recipient.clientId);
          } else {
            console.warn(`⚠️ [MixedEmailService] Brak clientId dla ${recipient.clientName}`);
          }
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
        const normalizedHtml = normalizeQuillHtml(personalizedHtml);
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: recipient.clientEmail,
          subject: subject,
          html: normalizedHtml,
          text: stripHtmlTags(normalizedHtml),
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
        // 📧 GENERUJ TREŚĆ EMAIL DLA DODATKOWEGO ODBIORCY
        let emailHtml;
        if (includeInvestmentDetails && recipients.length > 0) {
          // Użyj gotowego zbiorczego raportu z frontendu jeśli dostępny
          if (aggregatedInvestmentsForAdditionals && aggregatedInvestmentsForAdditionals.trim().length > 0) {
            console.log(`✅ [MixedEmailService] Używam gotowego zbiorczego raportu z frontendu dla ${email}`);
            emailHtml = generatePersonalizedEmailContent({
              clientName: 'Szanowni Państwo',
              htmlContent: htmlContent,
              investmentDetailsHtml: aggregatedInvestmentsForAdditionals,
              senderName: senderName,
              totalAmount: 0,
              investmentCount: 0
            });
          } else if (investmentDetailsByClient && Object.keys(investmentDetailsByClient).length > 0) {
            // Fallback: buduj z per-client fragmentów
            console.log(`🔄 [MixedEmailService] Buduję zbiorczy raport z fragmentów per-client dla ${email}`);
            let combined = '<h3>📈 Podsumowanie wybranych inwestycji</h3>';
            for (const r of recipients) {
              const htmlSnippet = investmentDetailsByClient[r.clientId];
              if (htmlSnippet) {
                combined += `<div style="margin-bottom:12px;"><h4>${safeToString(r.clientName)}</h4>${htmlSnippet}</div>`;
              }
            }
            emailHtml = generatePersonalizedEmailContent({
              clientName: 'Szanowni Państwo',
              htmlContent: htmlContent,
              investmentDetailsHtml: combined,
              senderName: senderName,
              totalAmount: 0,
              investmentCount: 0
            });
          } else {
            // Ostateczny fallback: wygeneruj na serwerze
            console.log(`🔄 [MixedEmailService] Generuję zbiorczy raport na serwerze dla ${email}`);
            const allInvestmentsHtml = await generateAllInvestmentsSummary(recipients);
            emailHtml = generatePersonalizedEmailContent({
              clientName: 'Szanowni Państwo',
              htmlContent: htmlContent,
              investmentDetailsHtml: allInvestmentsHtml,
              senderName: senderName,
              totalAmount: 0,
              investmentCount: 0
            });
          }
        } else {
          // Podstawowa treść bez szczegółów inwestycji
          emailHtml = generateBasicEmailContent({
            htmlContent: htmlContent,
            senderName: senderName,
            recipientEmail: email
          });
        }

        // 📬 WYŚLIJ EMAIL DO DODATKOWEGO ODBIORCY
        const normalizedHtml = normalizeQuillHtml(emailHtml);
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: email,
          subject: subject,
          html: normalizedHtml,
          text: stripHtmlTags(normalizedHtml),
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
      operation: 'mixed_recipients_bulk_email_enhanced',
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
      hasDetailedInvestmentTables: !!(investmentDetailsByClient && Object.keys(investmentDetailsByClient).length > 0),
      hasAggregatedReportForAdditionals: !!(aggregatedInvestmentsForAdditionals && aggregatedInvestmentsForAdditionals.length > 0),
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
 * Generuje zbiorczy raport wszystkich inwestycji dla dodatkowych odbiorców
 * 📊 NOWA WERSJA - pobiera rzeczywiste dane z Firebase zamiast hardkodowanych wartości
 */
async function generateAllInvestmentsSummary(recipients) {
  console.log(`📊 [MixedEmailService] Generuję zbiorczy raport dla ${recipients.length} inwestorów`);

  let totalCapital = 0;
  let totalSecuredCapital = 0;
  let totalRestructuringCapital = 0;
  let totalInvestments = 0;

  let html = '<h3 style="color: #d4af37; margin-bottom: 16px;">📈 Podsumowanie wszystkich wybranych inwestycji:</h3>';
  html += '<table style="width: 100%; border-collapse: collapse; margin-bottom: 20px; font-family: Arial, sans-serif;">';

  // Zaktualizowane nagłówki tabeli - bez wartości udziałów, dodano kapitał zabezpieczony i do restrukturyzacji
  html += '<tr style="background-color: #2c2c2c; color: #d4af37;">';
  html += '<th style="padding: 12px; border: 1px solid #ddd; text-align: left;">Klient</th>';
  html += '<th style="padding: 12px; border: 1px solid #ddd; text-align: right;">Pozostały kapitał</th>';
  html += '<th style="padding: 12px; border: 1px solid #ddd; text-align: right;">Kapitał zabezpieczony</th>';
  html += '<th style="padding: 12px; border: 1px solid #ddd; text-align: right;">Kapitał do restrukturyzacji</th>';
  html += '<th style="padding: 12px; border: 1px solid #ddd; text-align: center;">Liczba inwestycji</th>';
  html += '</tr>';

  // 🔄 Pobierz rzeczywiste dane dla każdego inwestora z Firebase
  for (let index = 0; index < recipients.length; index++) {
    const recipient = recipients[index];

    try {
      console.log(`🔍 [MixedEmailService] Pobieram dane inwestycji dla ${recipient.clientName} (${recipient.clientId})`);

      // Pobierz inwestycje klienta z Firebase
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', '==', recipient.clientId)
        .get();

      let clientRemainingCapital = 0;
      let clientSecuredCapital = 0;
      let clientRestructuringCapital = 0;
      let clientInvestmentCount = 0;

      if (!investmentsSnapshot.empty) {
        const investments = investmentsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));

        clientInvestmentCount = investments.length;

        // Oblicz rzeczywiste kwoty na podstawie danych z Firebase
        for (const investment of investments) {
          const remainingCapital = safeToDouble(investment.remainingCapital || investment.kapital_pozostaly || 0);
          const securedCapital = safeToDouble(investment.securedCapital || investment.kapital_zabezpieczony || 0);
          const restructuringCapital = safeToDouble(investment.restructuringCapital || investment.kapital_restrukturyzacja || 0);

          clientRemainingCapital += remainingCapital;
          clientSecuredCapital += securedCapital;
          clientRestructuringCapital += restructuringCapital;
        }
      }

      // Dodaj wiersz dla klienta
      const isOddRow = (index % 2) === 1;
      const bgColor = isOddRow ? '#f9f9f9' : '#ffffff';

      html += `<tr style="background-color: ${bgColor};">`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; font-weight: 500;">${recipient.clientName}</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${formatCurrency(clientRemainingCapital)}</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${formatCurrency(clientSecuredCapital)}</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right;">${formatCurrency(clientRestructuringCapital)}</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: center;">${clientInvestmentCount}</td>`;
      html += '</tr>';

      // Dodaj do sum globalnych
      totalCapital += clientRemainingCapital;
      totalSecuredCapital += clientSecuredCapital;
      totalRestructuringCapital += clientRestructuringCapital;
      totalInvestments += clientInvestmentCount;

      console.log(`✅ [MixedEmailService] ${recipient.clientName}: ${clientInvestmentCount} inwestycji, kapitał pozostały: ${formatCurrency(clientRemainingCapital)}`);

    } catch (clientError) {
      console.error(`❌ [MixedEmailService] Błąd pobierania danych dla ${recipient.clientName}:`, clientError);

      // Dodaj wiersz z błędem
      const isOddRow = (index % 2) === 1;
      const bgColor = isOddRow ? '#f9f9f9' : '#ffffff';

      html += `<tr style="background-color: ${bgColor};">`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; font-weight: 500;">${recipient.clientName}</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right; color: #dc3545;">Błąd danych</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right; color: #dc3545;">Błąd danych</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: right; color: #dc3545;">Błąd danych</td>`;
      html += `<td style="padding: 8px; border: 1px solid #ddd; text-align: center; color: #dc3545;">0</td>`;
      html += '</tr>';
    }
  }

  // Wiersz podsumowujący z rzeczywistymi kwotami
  html += '<tr style="background-color: #2c2c2c; color: #d4af37; font-weight: bold;">';
  html += '<td style="padding: 12px; border: 1px solid #ddd; font-size: 16px;">📊 RAZEM</td>';
  html += `<td style="padding: 12px; border: 1px solid #ddd; text-align: right; font-size: 16px;">${formatCurrency(totalCapital)}</td>`;
  html += `<td style="padding: 12px; border: 1px solid #ddd; text-align: right; font-size: 16px;">${formatCurrency(totalSecuredCapital)}</td>`;
  html += `<td style="padding: 12px; border: 1px solid #ddd; text-align: right; font-size: 16px;">${formatCurrency(totalRestructuringCapital)}</td>`;
  html += `<td style="padding: 12px; border: 1px solid #ddd; text-align: center; font-size: 16px;">${totalInvestments}</td>`;
  html += '</tr>';

  html += '</table>';

  // Dodaj dodatkowe informacje 
  html += '<div style="margin-top: 20px; padding: 16px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">';
  html += '<h4 style="color: #2c2c2c; margin-bottom: 12px;">💡 Informacje dodatkowe:</h4>';
  html += '<ul style="margin: 0; padding-left: 20px; color: #495057;">';
  html += `<li>Łączna liczba analizowanych klientów: <strong>${recipients.length}</strong></li>`;
  html += `<li>Łączna liczba inwestycji: <strong>${totalInvestments}</strong></li>`;
  html += `<li>Średnia kwota kapitału pozostałego na klienta: <strong>${recipients.length > 0 ? formatCurrency(totalCapital / recipients.length) : '0,00 PLN'}</strong></li>`;
  html += `<li>Raport wygenerowany: <strong>${new Date().toLocaleString('pl-PL')}</strong></li>`;
  html += '</ul>';
  html += '</div>';

  console.log(`📊 [MixedEmailService] Zbiorczy raport wygenerowany: ${totalInvestments} inwestycji, kapitał łączny: ${formatCurrency(totalCapital)}`);

  return html;
}

/**
 * Formatuje wartość jako walutę
 */
function formatCurrency(amount) {
  if (!amount || isNaN(amount)) return '0,00 PLN';
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    minimumFractionDigits: 2
  }).format(amount);
}

/**
 * Bezpiecznie konwertuje wartość na liczbę
 */
function safeToDouble(value) {
  if (value === null || value === undefined) return 0;
  if (typeof value === 'number') return isNaN(value) ? 0 : value;
  if (typeof value === 'string') {
    const parsed = parseFloat(value.replace(',', '.'));
    return isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

/**
 * Bezpiecznie konwertuje wartość na string
 */
function safeToString(value) {
  if (value === null || value === undefined) return '';
  return String(value);
}

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
        const normalizedHtml = normalizeQuillHtml(personalizedHtml);
        const mailOptions = {
          from: `${senderName} <${senderEmail}>`,
          to: recipient.clientEmail,
          subject: subject,
          html: normalizedHtml,
          text: stripHtmlTags(normalizedHtml), // Wersja tekstowa jako fallback
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
 * Normalizuje HTML z Quill dla lepszej kompatybilności z klientami email
 * Synchronizowane z logiką frontendu w enhanced_email_editor_dialog.dart
 */
function normalizeQuillHtml(html) {
  if (!html || typeof html !== 'string') return html;

  let normalizedHtml = html;

  // 1. Upewnij się, że font-family ma bezpieczne fallback fonts
  normalizedHtml = normalizedHtml.replace(
    /font-family:\s*([^;,"]+)(?![,"])/g, 
    (match, fontFamily) => {
      const cleanFont = fontFamily.trim();
      
      // Mapowanie zgodne z frontendem _customFontFamilies
      const fontFamilyMap = {
        'Arial': 'Arial, sans-serif',
        'Helvetica': 'Helvetica, Arial, sans-serif',
        'Times New Roman': 'Times New Roman, Times, serif',
        'Georgia': 'Georgia, serif',
        'Verdana': 'Verdana, sans-serif',
        'Calibri': 'Calibri, sans-serif',
        'Roboto': 'Roboto, sans-serif',
        'Open Sans': 'Open Sans, sans-serif',
        'Lato': 'Lato, sans-serif',
        'Source Sans Pro': 'Source Sans Pro, sans-serif',
        'Montserrat': 'Montserrat, sans-serif',
        'Oswald': 'Oswald, sans-serif',
        'Courier New': 'Courier New, Courier, monospace',
        'Monaco': 'Monaco, Consolas, monospace',
      };

      // Jeśli font jest w mapie, użyj pełnej definicji
      if (fontFamilyMap[cleanFont]) {
        return `font-family: ${fontFamilyMap[cleanFont]}`;
      }

      // Jeśli nie zawiera przecinka, dodaj bezpieczny fallback
      if (!cleanFont.includes(',')) {
        return `font-family: "${cleanFont}", Arial, sans-serif`;
      }

      return match;
    }
  );

  // 2. Normalizuj font-size - upewnij się, że ma jednostki
  normalizedHtml = normalizedHtml.replace(
    /font-size:\s*(\d+)(?!px|pt|em|rem|%)/g, 
    'font-size: $1px'
  );

  // 3. Normalizuj kolory hex do uppercase dla lepszej kompatybilności
  normalizedHtml = normalizedHtml.replace(
    /color:\s*(#[a-f0-9]{6})/gi, 
    (match, colorValue) => `color: ${colorValue.toUpperCase()}`
  );

  // 4. Normalizuj background-color hex
  normalizedHtml = normalizedHtml.replace(
    /background-color:\s*(#[a-f0-9]{6})/gi, 
    (match, colorValue) => `background-color: ${colorValue.toUpperCase()}`
  );

  // 5. Dodaj CSS resetowanie dla lepszej kompatybilności z klientami email
  if (normalizedHtml.includes('<style>') || normalizedHtml.includes('style=')) {
    // Dodaj podstawowe resetowanie dla email clients
    const emailResetStyles = `
      <style>
        /* Email client reset */
        body, table, td, p, a, li, blockquote {
          -webkit-text-size-adjust: 100%;
          -ms-text-size-adjust: 100%;
        }
        table, td {
          mso-table-lspace: 0pt;
          mso-table-rspace: 0pt;
        }
        /* Preserve font formatting */
        .preserve-font {
          font-family: inherit !important;
          font-size: inherit !important;
          color: inherit !important;
        }
      </style>
    `;
    
    // Wstaw style na początku jeśli HTML ma strukturę
    if (normalizedHtml.includes('<head>')) {
      normalizedHtml = normalizedHtml.replace('<head>', `<head>${emailResetStyles}`);
    } else if (normalizedHtml.includes('<html>')) {
      normalizedHtml = normalizedHtml.replace('<html>', `<html><head>${emailResetStyles}</head>`);
    }
  }

  console.log(`📧 [normalizeQuillHtml] Normalized HTML length: ${normalizedHtml.length}`);
  
  return normalizedHtml;
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
  sendPreGeneratedEmails,
};
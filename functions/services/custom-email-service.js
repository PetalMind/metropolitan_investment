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
 * Generuje SVG logo w kolorze złotym dla email headers
 */
function getGoldenLogoSvg() {
  return `
<svg version="1.1" id="metropolitan-logo" width="360" height="189" viewBox="0 0 159.77333 84.173332" 
     xmlns="http://www.w3.org/2000/svg" style="display: block; margin: 0 auto;">
  <g id="g1">
    <g id="group-R5">
      <path id="path3" d="m 162.859,267.559 -22.386,-29.84 h -2.555 l -21.891,29.941 v -49.972 h -12.961 v 68.726 h 14.922 l 21.504,-29.551 21.5,29.551 h 14.828 v -68.726 h -12.961 z m 96.012,-49.766 h -51.445 c 0,22.871 0,45.848 0,68.719 h 51.445 v -12.567 h -38.582 v -15.804 h 37.207 v -12.078 h -37.207 v -15.516 h 38.582 z m 51.434,56.937 h -21.793 v 11.782 c 19.836,0 36.625,0 56.554,0 V 274.73 H 323.27 V 217.793 H 310.305 Z M 433.52,217.793 h -15.418 l -20.028,22.969 h -12.469 v -22.969 h -12.96 v 68.816 c 10.902,0 21.8,-0.097 32.695,-0.097 16.199,-0.098 24.742,-10.895 24.742,-22.778 0,-9.425 -4.32,-18.949 -17.379,-21.597 l 20.817,-23.469 z m -47.915,56.641 v 0 -21.985 h 19.735 c 8.246,0 11.781,5.492 11.781,10.992 0,5.493 -3.633,10.993 -11.781,10.993 z m 140.387,-22.676 c -0.191,-17.77 -11.094,-35.543 -35.242,-35.543 -24.152,0 -35.348,17.379 -35.348,35.441 0,18.071 11.586,36.231 35.348,36.231 23.66,0 35.445,-18.16 35.242,-36.129 z m -57.824,-0.293 v 0 c 0.297,-11.289 6.379,-23.371 22.582,-23.371 16.199,0 22.289,12.176 22.48,23.469 0.2,11.582 -6.281,24.542 -22.48,24.542 -16.203,0 -22.879,-13.054 -22.582,-24.64 z m 119.379,-13.457 h -19.442 v -20.215 h -12.96 v 68.719 c 10.8,0 21.601,0.097 32.402,0.097 33.582,0 33.676,-48.601 0,-48.601 z m -19.442,11.879 v 0 h 19.442 c 16.594,0 16.492,24.351 0,24.351 h -19.442 z m 140.586,1.871 c -0.195,-17.77 -11.089,-35.543 -35.242,-35.543 -24.156,0 -35.347,17.379 -35.347,35.441 0,18.071 11.586,36.231 35.347,36.231 23.66,0 35.442,-18.16 35.242,-36.129 z m -57.824,-0.293 v 0 c 0.297,-11.289 6.379,-23.371 22.582,-23.371 16.199,0 22.285,12.176 22.485,23.469 0.195,11.582 -6.286,24.542 -22.485,24.542 -16.203,0 -22.879,-13.054 -22.582,-24.64 z m 99.942,35.047 v -56.746 h 35.343 v -11.973 h -48.304 v 68.719 z m 64.199,-68.719 v 68.719 h 12.863 v -68.719 z m 65.578,56.937 h -21.797 v 11.782 c 19.836,0 36.625,0 56.559,0 V 274.73 h -21.793 v -56.937 h -12.969 z m 111.031,-43.98 h -35.929 l -5.891,-12.957 h -14.039 l 30.828,68.719 h 14.137 l 30.837,-68.719 h -14.142 z m -17.965,41.328 v 0 l -12.757,-29.254 h 25.527 z m 108.588,14.531 h 12.95 v -68.816 h -8.05 v -0.105 l -36.13,46.437 v -46.332 h -12.96 v 68.719 h 10.51 l 33.68,-42.606 v 42.703" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path4" d="m 351.273,152.938 h 5.54 v -49.032 h -5.54 v 49.032" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path5" d="m 383.828,140.117 h 5.391 v -6.301 c 2.383,3.918 6.164,7.075 12.398,7.075 8.754,0 13.867,-5.883 13.867,-14.504 v -22.481 h -5.394 v 21.153 c 0,6.726 -3.641,10.925 -10.016,10.925 -6.23,0 -10.855,-4.55 -10.855,-11.343 v -20.735 h -5.391 v 36.211" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path6" d="m 434.984,140.117 h 5.954 l 12.187,-30.047 12.258,30.047 h 5.812 l -15.761,-36.488 h -4.758 l -15.692,36.488" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path7" d="m 517.109,124.148 c -0.629,6.586 -4.414,12.188 -11.558,12.188 -6.231,0 -10.996,-5.184 -11.766,-12.188 z m -10.578,-16.386 c 4.973,0 8.477,2.031 11.418,5.113 l 3.36,-3.016 c -3.637,-4.062 -8.051,-6.793 -14.918,-6.793 -9.946,0 -18.067,7.633 -18.067,18.914 0,10.5 7.356,18.911 17.367,18.911 10.715,0 16.883,-8.547 16.883,-19.196 0,-0.488 0,-1.05 -0.074,-1.89 h -28.715 c 0.77,-7.629 6.375,-12.043 12.746,-12.043" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path8" d="m 543.422,108.531 2.73,3.852 c 3.922,-2.942 8.266,-4.621 12.539,-4.621 4.34,0 7.493,2.242 7.493,5.742 v 0.141 c 0,3.64 -4.27,5.043 -9.036,6.371 -5.671,1.613 -11.976,3.574 -11.976,10.226 v 0.141 c 0,6.234 5.183,10.367 12.328,10.367 4.414,0 9.316,-1.543 13.027,-3.996 l -2.449,-4.063 c -3.367,2.172 -7.219,3.5 -10.719,3.5 -4.273,0 -7.004,-2.238 -7.004,-5.246 v -0.144 c 0,-3.43 4.485,-4.758 9.317,-6.235 5.601,-1.679 11.629,-3.851 11.629,-10.359 v -0.144 c 0,-6.864 -5.676,-10.852 -12.891,-10.852 -5.183,0 -10.926,2.031 -14.988,5.32" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path9" d="m 596.633,113.504 v 21.848 h -5.043 v 4.765 h 5.043 v 10.926 h 5.39 v -10.926 h 11.489 v -4.765 h -11.489 v -21.145 c 0,-4.414 2.45,-6.027 6.094,-6.027 1.821,0 3.363,0.351 5.254,1.261 v -4.625 c -1.891,-0.976 -3.922,-1.539 -6.516,-1.539 -5.808,0 -10.222,2.871 -10.222,10.227" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path10" d="m 638.297,140.117 h 5.391 v -6.094 c 2.382,3.571 5.605,6.868 11.699,6.868 5.879,0 9.668,-3.157 11.633,-7.219 2.585,3.996 6.433,7.219 12.742,7.219 8.332,0 13.449,-5.606 13.449,-14.571 v -22.414 h -5.391 v 21.153 c 0,7.004 -3.507,10.925 -9.386,10.925 -5.469,0 -10.016,-4.058 -10.016,-11.207 v -20.871 h -5.324 v 21.289 c 0,6.797 -3.574,10.789 -9.317,10.789 -5.742,0 -10.089,-4.761 -10.089,-11.418 v -20.66 h -5.391 v 36.211" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path11" d="m 743.297,124.148 c -0.637,6.586 -4.414,12.188 -11.563,12.188 -6.23,0 -10.996,-5.184 -11.765,-12.188 z m -10.574,-16.386 c 4.968,0 8.472,2.031 11.414,5.113 l 3.359,-3.016 c -3.644,-4.062 -8.058,-6.793 -14.922,-6.793 -9.941,0 -18.066,7.633 -18.066,18.914 0,10.5 7.351,18.911 17.375,18.911 10.711,0 16.875,-8.547 16.875,-19.196 0,-0.488 0,-1.05 -0.07,-1.89 h -28.719 c 0.769,-7.629 6.375,-12.043 12.754,-12.043" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path12" d="m 771.488,140.117 h 5.391 v -6.301 c 2.383,3.918 6.164,7.075 12.394,7.075 8.758,0 13.868,-5.883 13.868,-14.504 v -22.481 h -5.391 v 21.153 c 0,6.726 -3.645,10.925 -10.02,10.925 -6.23,0 -10.851,-4.55 -10.851,-11.343 v -20.735 h -5.391 v 36.211" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path13" d="m 830.074,113.504 v 21.848 h -5.039 v 4.765 h 5.039 v 10.926 h 5.399 v -10.926 h 11.488 v -4.765 h -11.488 v -21.145 c 0,-4.414 2.453,-6.027 6.093,-6.027 1.817,0 3.36,0.351 5.247,1.261 v -4.625 c -1.887,-0.976 -3.918,-1.539 -6.504,-1.539 -5.821,0 -10.235,2.871 -10.235,10.227" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path14" d="m 513.23,363.922 h 32.723 V 487.16 L 513.23,514.227 V 363.922" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path15" d="m 566.406,363.922 h 32.727 V 498.414 L 566.406,480.047 V 363.922" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
      <path id="path16" d="m 619.586,363.922 h 32.727 V 528.266 L 619.586,509.895 V 363.922" 
            style="fill:#d4af37;fill-opacity:1;fill-rule:nonzero;stroke:none" 
            transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
    </g>
  </g>
</svg>
  `;
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
        * {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
        }
        
        body { 
            line-height: 1.6; 
            color: #2c2c2c; 
            background-color: #2c2c2c;
            margin: 0;
            padding: 0;
        }
        
        .email-container {
            max-width: 680px;
            margin: 0 auto;
            background-color: #2c2c2c;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        
        .header { 
            background-color: #1e293b;
            color: #ffffff; 
            padding: 40px 30px; 
            text-align: center;
        }
        
        .header h1 {
            font-size: 24px;
            font-weight: 300;
            margin-bottom: 8px;
            letter-spacing: 0.5px;
        }
        
        .header .subtitle {
            font-size: 14px;
            color: #d4af37;
            font-weight: 400;
            opacity: 0.9;
        }
        
        .content { 
            background: #ffffff; 
            padding: 40px 30px;
        }
        
        .greeting {
            font-size: 18px;
            color: #1e293b;
            margin-bottom: 24px;
            font-weight: 500;
        }
        
        .user-content {
            margin: 30px 0;
            line-height: 1.7;
            color: #374151;
        }
        
        .user-content h1, .user-content h2, .user-content h3 {
            color: #1e293b;
            margin-top: 24px;
            margin-bottom: 12px;
            font-weight: 600;
        }
        
        .user-content p {
            margin-bottom: 16px;
            color: #374151;
        }
        
        .footer { 
            background: #f8fafc; 
            padding: 30px; 
            text-align: center; 
            border-top: 1px solid #e2e8f0;
        }
        
        .footer p {
            font-size: 13px; 
            color: #64748b; 
            margin-bottom: 8px;
        }
        
        .footer .company-name {
            font-weight: 600;
            color: #1e293b;
        }
        
        @media only screen and (max-width: 600px) {
            .email-container {
                margin: 0;
                box-shadow: none;
            }
            
            .header, .content, .footer {
                padding: 24px 20px;
            }
            
            .header h1 {
                font-size: 20px;
            }
            
            .greeting {
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            ${getGoldenLogoSvg()}
            <div class="subtitle" style="margin-top: 16px;">Profesjonalne Zarządzanie Kapitałem</div>
        </div>
        
        <div class="content">
        
        
            <div class="user-content">
                ${htmlContent}
            </div>
        </div>
        
        <div class="footer">
            <p>Ten email został wysłany automatycznie dnia ${new Date().toLocaleDateString('pl-PL')}.</p>
            <p><span class="company-name">${senderName}</span></p>
            <p>W razie pytań, prosimy o kontakt z naszym działem obsługi klienta.</p>
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
          <td data-label="Produkt">
            <div class="product-info">
              <div class="product-name">${safeToString(investment.productName || investment.nazwa_produktu || 'Nieokreślony produkt')}</div>
              <div class="product-id">${investment.id || ''}</div>
            </div>
          </td>
          <td data-label="Kwota Inwestycji" class="amount-cell">${formatCurrency(investmentAmount)}</td>
          <td data-label="Pozostały Kapitał" class="amount-cell">${formatCurrency(remainingCapital)}</td>
          <td data-label="Zrealizowany Kapitał" class="amount-cell">${formatCurrency(realizedCapital)}</td>
          <td data-label="Status">
            <span class="status-badge ${investment.status === 'Aktywna' || !investment.status ? 'active' : 'other'}">${investment.status || 'Aktywna'}</span>
          </td>
        </tr>
      `;
    }).join('');

    return `
      <div class="portfolio-section">
        <div class="section-header">
          <h3>📊 Podsumowanie Portfela</h3>
        </div>

        <div class="portfolio-summary">
          <div class="summary-cards">
            <div class="summary-card">
              <div class="card-label">Liczba inwestycji</div>
              <div class="card-value">${investments.length}</div>
            </div>
            <div class="summary-card primary">
              <div class="card-label">Całkowita kwota inwestycji</div>
              <div class="card-value">${formatCurrency(totalInvestmentAmount)}</div>
            </div>
            <div class="summary-card">
              <div class="card-label">Kapitał pozostały</div>
              <div class="card-value">${formatCurrency(totalRemainingCapital)}</div>
            </div>
            <div class="summary-card">
              <div class="card-label">Kapitał zrealizowany</div>
              <div class="card-value">${formatCurrency(totalRealizedCapital)}</div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="investments-section">
        <div class="section-header">
          <h3>📋 Szczegóły Inwestycji</h3>
        </div>
        
        <div class="investments-table-container">
          <table class="modern-table">
            <thead>
              <tr>
                <th>Produkt</th>
                <th>Kwota Inwestycji</th>
                <th>Pozostały Kapitał</th>
                <th>Zrealizowany Kapitał</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              ${investmentRows}
            </tbody>
          </table>
        </div>
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
  // Profesjonalne, responsywne CSS dla email
  const emailStyles = `
    <style>
      /* Reset i podstawowe style */
      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      
      body { 
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        line-height: 1.6; 
        color: #2c2c2c; 
        background-color: #f8f9fa;
        margin: 0;
        padding: 0;
        -webkit-text-size-adjust: 100%;
        -ms-text-size-adjust: 100%;
      }
      
      .email-container {
        max-width: 680px;
        margin: 0 auto;
        background-color: #ffffff;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
      }
      
      .header { 
        background: #1e293b;
        color: #ffffff; 
        padding: 40px 30px; 
        text-align: center;
      }
      
      .header h1 {
        font-size: 24px;
        font-weight: 300;
        margin-bottom: 8px;
        letter-spacing: 0.5px;
      }
      
      .header .subtitle {
        font-size: 14px;
        color: #d4af37;
        font-weight: 400;
        opacity: 0.9;
      }
      
      .content { 
        background: #ffffff; 
        padding: 40px 30px;
      }
      
      .greeting {
        font-size: 18px;
        color: #1e293b;
        margin-bottom: 24px;
        font-weight: 500;
      }
      
      .summary { 
        background: #f9fafb;
        padding: 24px; 
        margin: 30px 0; 
        border-radius: 6px;
        border: 1px solid #e5e7eb;
      }

      /* Nowe style dla profesjonalnego designu */
      .portfolio-section, .investments-section {
        margin: 32px 0;
      }

      .section-header {
        margin-bottom: 24px;
      }

      .section-header h3 {
        color: #1e293b;
        font-size: 20px;
        font-weight: 600;
        margin: 0;
        padding-bottom: 12px;
        border-bottom: 2px solid #f1f5f9;
      }

      .portfolio-summary {
        background: #ffffff;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        padding: 24px;
      }

      .summary-cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
      }

      .summary-card {
        background: #f8fafc;
        padding: 20px;
        border-radius: 6px;
        border: 1px solid #e2e8f0;
        text-align: center;
        transition: all 0.2s ease;
      }

      .summary-card.primary {
        background: #1e293b;
        color: #ffffff;
        border-color: #1e293b;
      }

      .summary-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      }

      .card-label {
        font-size: 12px;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: #64748b;
        margin-bottom: 8px;
      }

      .summary-card.primary .card-label {
        color: #d4af37;
      }

      .card-value {
        font-size: 24px;
        font-weight: 700;
        color: #1e293b;
      }

      .summary-card.primary .card-value {
        color: #ffffff;
      }

      .investments-table-container {
        background: #ffffff;
        border-radius: 8px;
        overflow: hidden;
        border: 1px solid #e2e8f0;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      }

      .modern-table {
        width: 100%;
        border-collapse: collapse;
        margin: 0;
      }

      .modern-table th {
        background: #f8fafc;
        color: #374151;
        padding: 16px 20px;
        text-align: left;
        font-weight: 600;
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 2px solid #e2e8f0;
      }

      .modern-table td {
        padding: 16px 20px;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
      }

      .modern-table tr:last-child td {
        border-bottom: none;
      }

      .modern-table tr:hover {
        background-color: #f8fafc;
      }

      .product-info {
        display: flex;
        flex-direction: column;
        gap: 4px;
      }

      .product-name {
        font-weight: 600;
        color: #1e293b;
        font-size: 14px;
      }

      .product-id {
        font-size: 12px;
        color: #64748b;
        font-family: 'Courier New', monospace;
      }

      .amount-cell {
        font-weight: 600;
        color: #1e293b;
        text-align: right;
        font-variant-numeric: tabular-nums;
      }

      .status-badge {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 12px;
        font-size: 12px;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }

      .status-badge.active {
        background: #dcfce7;
        color: #166534;
        border: 1px solid #bbf7d0;
      }

      .status-badge.other {
        background: #f3f4f6;
        color: #374151;
        border: 1px solid #d1d5db;
      }      .summary h3 {
        color: #1e293b;
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 16px;
        display: flex;
        align-items: center;
      }
      
      /* Legacy styles - keeping for backward compatibility */
      .summary-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 16px;
      }
      
      .summary-item {
        display: flex;
        flex-direction: column;
      }
      
      .summary-label {
        font-size: 13px;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        font-weight: 500;
        margin-bottom: 4px;
      }
      
      .summary-value {
        font-size: 18px;
        color: #1e293b;
        font-weight: 600;
      }
      
      .summary-value.highlight {
        color: #d4af37;
        font-size: 20px;
      }
        margin-bottom: 4px;
      }

      .summary-value {
        font-size: 18px;
        color: #1e293b;
        font-weight: 600;
      }

      .summary-value.highlight {
        color: #d4af37;
        font-size: 20px;
      }
      
      .investment-details {
        margin: 30px 0;
      }
      
      .investment-details h3 {
        color: #1e293b;
        font-size: 18px;
        font-weight: 600;
        margin-bottom: 20px;
        padding-bottom: 8px;
        border-bottom: 2px solid #f1f5f9;
      }
      
      /* Legacy investment table styles - keeping for backward compatibility */
      .investment-table { 
        width: 100%; 
        border-collapse: collapse; 
        margin: 20px 0;
        background: #ffffff;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      }
      
      .investment-table th { 
        background: #f8fafc;
        color: #374151;
        padding: 16px 12px;
        text-align: left;
        font-weight: 600;
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 2px solid #e2e8f0;
      }
      
      .investment-table td { 
        padding: 14px 12px; 
        border-bottom: 1px solid #f1f5f9;
        color: #2c2c2c;
      }
      
      .investment-table tr:hover {
        background-color: #f8fafc;
      }
      
      .investment-table tr:last-child td {
        border-bottom: none;
      }
      
      .total { 
        font-weight: 700; 
        color: #d4af37; 
        font-size: 16px; 
      }
      
      .user-content {
        margin: 30px 0;
        line-height: 1.7;
        color: #374151;
      }
      
      .user-content h1, .user-content h2, .user-content h3 {
        color: #1e293b;
        margin-top: 24px;
        margin-bottom: 12px;
        font-weight: 600;
      }
      
      .user-content h1 { font-size: 24px; }
      .user-content h2 { font-size: 20px; }
      .user-content h3 { font-size: 18px; }
      
      .user-content p {
        margin-bottom: 16px;
        color: #374151;
      }
      
      .user-content ul, .user-content ol {
        margin-left: 20px;
        margin-bottom: 16px;
      }
      
      .user-content li {
        margin-bottom: 8px;
        color: #374151;
      }
      
      .user-content strong {
        color: #1e293b;
        font-weight: 600;
      }
      
      .user-content em {
        font-style: italic;
        color: #6b7280;
      }
      
      .footer { 
        background: #f8fafc; 
        padding: 30px; 
        text-align: center; 
        border-top: 1px solid #e2e8f0;
      }
      
      .footer p {
        font-size: 13px; 
        color: #64748b; 
        margin-bottom: 8px;
      }
      
      .footer .company-name {
        font-weight: 600;
        color: #1e293b;
      }
      
      /* Responsywność mobilna */
      @media only screen and (max-width: 600px) {
        .email-container {
          margin: 0;
          box-shadow: none;
        }
        
        .header, .content, .footer {
          padding: 24px 20px;
        }
        
        .header h1 {
          font-size: 20px;
        }
        
        .greeting {
          font-size: 16px;
        }
        
        /* Nowe style mobilne */
        .portfolio-summary {
          padding: 16px;
        }

        .summary-cards {
          grid-template-columns: 1fr;
          gap: 12px;
        }

        .summary-card {
          padding: 16px;
        }

        .card-value {
          font-size: 20px;
        }

        .modern-table {
          font-size: 14px;
        }

        .modern-table th,
        .modern-table td {
          padding: 12px 16px;
        }

        .section-header h3 {
          font-size: 18px;
        }

        /* Legacy styles */
        .summary {
          padding: 20px;
          margin: 20px 0;
        }
        
        .summary-grid {
          grid-template-columns: 1fr;
          gap: 12px;
        }
        
        .investment-table {
          font-size: 14px;
        }
        
        .investment-table th,
        .investment-table td {
          padding: 10px 8px;
        }
        
        .user-content h1 { font-size: 20px; }
        .user-content h2 { font-size: 18px; }
        .user-content h3 { font-size: 16px; }
      }
      
      /* Wsparcie dla klientów email i bardzo małych ekranów */
      @media only screen and (max-width: 480px) {
        /* Nowe style dla kart */
        .summary-cards {
          display: block;
        }

        .summary-card {
          margin-bottom: 12px;
        }

        /* Nowa tabela na małych ekranach */
        .modern-table,
        .modern-table tbody,
        .modern-table th,
        .modern-table td,
        .modern-table tr {
          display: block;
        }

        .modern-table th {
          display: none;
        }

        .modern-table tr {
          border: 1px solid #e2e8f0;
          margin-bottom: 12px;
          border-radius: 8px;
          padding: 16px;
          background: #ffffff;
        }

        .modern-table td {
          border: none;
          padding: 8px 0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .modern-table td:before {
          content: attr(data-label) ": ";
          font-weight: 600;
          color: #64748b;
          font-size: 12px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .product-info {
          flex-direction: column;
          align-items: flex-start;
        }

        /* Legacy styles */
        .summary-grid {
          display: block;
        }
        
        .summary-item {
          margin-bottom: 16px;
        }
        
        .investment-table,
        .investment-table tbody,
        .investment-table th,
        .investment-table td,
        .investment-table tr {
          display: block;
        }
        
        .investment-table th {
          display: none;
        }
        
        .investment-table tr {
          border: 1px solid #e2e8f0;
          margin-bottom: 8px;
          border-radius: 4px;
          padding: 12px;
        }
        
        .investment-table td {
          border: none;
          padding: 4px 0;
          position: relative;
          padding-left: 35%;
        }
        
        .investment-table td:before {
          content: attr(data-label) ": ";
          position: absolute;
          left: 0;
          width: 30%;
          font-weight: 600;
          color: #1e293b;
        }
      }
    </style>
  `;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Wiadomość od ${senderName}</title>
      ${emailStyles}
    </head>
    <body>
      <div class="email-container">
        <div class="header">
          ${getGoldenLogoSvg()}
          <div class="subtitle" style="margin-top: 16px;">Profesjonalne Zarządzanie Kapitałem</div>
        </div>
        
        <div class="content">
         
     
          <div class="user-content">
            ${htmlContent}
          </div>
          
          ${investmentDetailsHtml ? `
            <div class="investment-details">
              ${investmentDetailsHtml}
            </div>
          ` : ''}
        </div>
        
        <div class="footer">
          <p>Ten email został wysłany automatycznie dnia ${new Date().toLocaleDateString('pl-PL')}.</p>
          <p><span class="company-name">${senderName}</span></p>
          <p>W razie pytań, prosimy o kontakt z naszym działem obsługi klienta.</p>
        </div>
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

      // Mapowanie zgodne z FontFamilyService - obsługa nazw lokalnych czcionek i ich display names
      const fontFamilyMap = {
        // System fonts (legacy)
        'Arial': 'Arial, sans-serif',
        'Helvetica': 'Helvetica, Arial, sans-serif',
        'Times New Roman': 'Times New Roman, Times, serif',
        'Georgia': 'Georgia, serif',
        'Verdana': 'Verdana, sans-serif',
        'Calibri': 'Calibri, sans-serif',

        // Local fonts - Flutter internal names
        'OpenSans': '"Open Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Roboto': 'Roboto, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif',
        'Lato': 'Lato, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Montserrat': 'Montserrat, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'SourceSans3': '"Source Sans Pro", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'NunitoSans': '"Nunito Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Inter': 'Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'WorkSans': '"Work Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'FiraSans': '"Fira Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',

        // Local fonts - Serif
        'Merriweather': 'Merriweather, Georgia, "Times New Roman", serif',
        'PlayfairDisplay': '"Playfair Display", Georgia, "Times New Roman", serif',
        'CrimsonText': '"Crimson Text", Georgia, "Times New Roman", serif',
        'LibreBaskerville': '"Libre Baskerville", Georgia, "Times New Roman", serif',

        // Local fonts - Modern
        'Poppins': 'Poppins, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Raleway': 'Raleway, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Ubuntu': 'Ubuntu, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Nunito': 'Nunito, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',

        // Local fonts - Corporate
        'RobotoCondensed': '"Roboto Condensed", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Oswald': 'Oswald, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'PTSans': '"PT Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',

        // Display names mapping - dla kompatybilności z HTML z display names
        'Open Sans': '"Open Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Source Sans Pro': '"Source Sans Pro", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Nunito Sans': '"Nunito Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Work Sans': '"Work Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Fira Sans': '"Fira Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'Playfair Display': '"Playfair Display", Georgia, "Times New Roman", serif',
        'Libre Baskerville': '"Libre Baskerville", Georgia, "Times New Roman", serif',
        'Crimson Text': '"Crimson Text", Georgia, "Times New Roman", serif',
        'Roboto Condensed': '"Roboto Condensed", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        'PT Sans': '"PT Sans", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',

        // Legacy compatibility (monospace)
        'Courier New': 'Courier New, Courier, monospace',
        'Fira Code': 'Fira Code, monospace',
        'Source Code Pro': 'Source Code Pro, monospace',
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
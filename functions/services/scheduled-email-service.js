/**
 * Scheduled Email Service - Obsługa zaplanowanych emaili przez Cloud Functions
 * 
 * Serwis wykonujący się automatycznie co minutę w celu sprawdzenia
 * i wysłania zaplanowanych emaili. Działa w kontekście Firebase Admin SDK
 * z pełnymi uprawnieniami do Firestore.
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Automatyczne sprawdzanie zaplanowanych emaili
 * • Wysyłka emaili w odpowiednim czasie
 * • Aktualizacja statusów w Firestore
 * • Obsługa błędów i ponownych prób
 * • Logowanie szczegółowe
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Inicjalizacja bazy danych
const db = admin.firestore();

/**
 * CYKLICZNA FUNKCJA - SPRAWDZANIE ZAPLANOWANYCH EMAILI
 * Uruchamia się co minutę przez Firebase Scheduler
 */
const processScheduledEmails = onSchedule({
    schedule: "every 1 minutes",
    timeZone: "Europe/Warsaw",
    memory: "1GiB",
    timeoutSeconds: 540,
}, async (event) => {
    const startTime = Date.now();
    console.log('📅 [ScheduledEmailService] Starting scheduled email processing...');

    try {
        const now = new Date();

        // Pobierz emaile gotowe do wysłania
        const querySnapshot = await db
            .collection('scheduled_emails')
            .where('status', '==', 'pending')
            .where('scheduledDateTime', '<=', admin.firestore.Timestamp.fromDate(now))
            .limit(10) // Przetwarzaj maksymalnie 10 na raz
            .get();

        if (querySnapshot.empty) {
            console.log('📅 [ScheduledEmailService] No emails to send at this time');
            return null;
        }

        console.log(`📅 [ScheduledEmailService] Found ${querySnapshot.docs.length} emails to send`);

        // Przetwórz każdy email
        const results = await Promise.allSettled(
            querySnapshot.docs.map(doc => processScheduledEmail(doc.id, doc.data()))
        );

        // Podsumowanie wyników
        const successful = results.filter(r => r.status === 'fulfilled').length;
        const failed = results.filter(r => r.status === 'rejected').length;

        console.log(`📅 [ScheduledEmailService] Processing completed: ${successful} successful, ${failed} failed`);
        console.log(`📅 [ScheduledEmailService] Total execution time: ${Date.now() - startTime}ms`);

        return {
            processed: querySnapshot.docs.length,
            successful,
            failed,
            executionTimeMs: Date.now() - startTime
        };

    } catch (error) {
        console.error('❌ [ScheduledEmailService] Error processing scheduled emails:', error);
        throw error;
    }
});

/**
 * PRZETWARZANIE POJEDYNCZEGO ZAPLANOWANEGO EMAILA
 */
async function processScheduledEmail(emailId, emailData) {
    console.log(`📧 [ScheduledEmailService] Processing email: ${emailId}`);

    try {
        // Walidacja danych
        const recipientsData = emailData.recipientsData || [];
        if (recipientsData.length === 0) {
            console.log(`❌ [ScheduledEmailService] No recipients for email: ${emailId}`);
            await updateEmailStatus(emailId, 'failed', {
                errorMessage: 'Brak odbiorców - email nie może zostać wysłany'
            });
            return;
        }

        // Oznacz jako wysyłany
        await updateEmailStatus(emailId, 'sending');

        console.log(`📧 [ScheduledEmailService] Sending email to ${recipientsData.length} recipients`);

        // Konwertuj dane odbiorców do formatu wymaganego przez customEmailService
        const investors = recipientsData.map(recipient => ({
            client: {
                id: recipient.clientId || '',
                name: recipient.clientName || '',
                email: recipient.clientEmail || '',
                phone: recipient.clientPhone || ''
            },
            totalInvestmentAmount: recipient.totalInvestmentAmount || 0,
            totalRemainingCapital: recipient.totalRemainingCapital || 0,
            totalRealized: recipient.totalRealized || 0,
            totalSharesValue: recipient.totalSharesValue || 0,
            investmentCount: recipient.investmentCount || 0,
            capitalSecuredByRealEstate: recipient.capitalSecuredByRealEstate || 0
        }));

        // Przygotuj dodatkowych odbiorców
        const additionalRecipients = {};
        if (emailData.additionalRecipients) {
            Object.assign(additionalRecipients, emailData.additionalRecipients);
        }

        // Wywołaj funkcję wysyłania emaili - używamy sendPreGeneratedEmails
        const customEmailService = require('./custom-email-service');
        const sendFunction = customEmailService.sendPreGeneratedEmails;

        // Przygotuj dane w formacie wymaganym przez sendPreGeneratedEmails
        const completeEmailHtmlByClient = {};
        investors.forEach(investor => {
            completeEmailHtmlByClient[investor.client.id] = emailData.htmlContent;
        });

        const callableRequest = {
            data: {
                recipients: investors,
                additionalEmails: Object.keys(additionalRecipients),
                subject: emailData.subject || '',
                completeEmailHtmlByClient: completeEmailHtmlByClient,
                aggregatedEmailHtmlForAdditionals: emailData.htmlContent, // Ten sam HTML dla dodatkowych
                senderEmail: emailData.senderEmail || '',
                senderName: emailData.senderName || ''
            }
        };

        const results = await sendFunction(callableRequest);

        // Sprawdź wyniki - sendPreGeneratedEmails zwraca obiekt z results array
        const emailResults = results.results || [];
        const hasErrors = emailResults.some(result => !result.success);
        const successCount = emailResults.filter(result => result.success).length;
        const totalCount = emailResults.length;

        if (hasErrors) {
            await updateEmailStatus(emailId, 'partiallyFailed', {
                sentAt: new Date(),
                successCount,
                totalCount,
                errorMessage: `Częściowy błąd: ${successCount}/${totalCount} emaili wysłanych pomyślnie`
            });
        } else {
            await updateEmailStatus(emailId, 'sent', {
                sentAt: new Date(),
                successCount,
                totalCount
            });
        }

        console.log(`✅ [ScheduledEmailService] Email ${emailId} processed: ${successCount}/${totalCount} sent`);

    } catch (error) {
        console.error(`❌ [ScheduledEmailService] Error processing email ${emailId}:`, error);

        await updateEmailStatus(emailId, 'failed', {
            errorMessage: `Błąd wysyłania: ${error.message}`
        });

        throw error;
    }
}

/**
 * AKTUALIZACJA STATUSU EMAILA
 */
async function updateEmailStatus(emailId, status, additionalData = {}) {
    const updates = {
        status: status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...additionalData
    };

    if (additionalData.sentAt) {
        updates.sentAt = admin.firestore.Timestamp.fromDate(additionalData.sentAt);
        delete updates.sentAt; // Remove from additionalData to avoid duplication
        updates.sentAt = admin.firestore.Timestamp.fromDate(additionalData.sentAt);
    }

    await db.collection('scheduled_emails').doc(emailId).update(updates);
    console.log(`📝 [ScheduledEmailService] Updated email ${emailId} status to: ${status}`);
}

/**
 * FUNKCJA TESTOWA - Ręczne uruchomienie przetwarzania
 */
const testScheduledEmailProcessing = onCall({
    memory: "1GiB",
    timeoutSeconds: 540,
}, async (request) => {
    console.log('🧪 [ScheduledEmailService] Manual test triggered');

    try {
        // Uruchom przetwarzanie ręcznie
        const result = await processScheduledEmails.run();

        return {
            success: true,
            message: 'Przetwarzanie zaplanowanych emaili zakończone',
            result: result
        };
    } catch (error) {
        console.error('❌ [ScheduledEmailService] Test failed:', error);
        throw new HttpsError('internal', `Błąd testowania: ${error.message}`);
    }
});

/**
 * FUNKCJA DEBUGOWANIA - Sprawdź emaile z pustymi recipientami
 */
const debugEmptyRecipients = onCall({
    memory: "512MiB",
    timeoutSeconds: 60,
}, async (request) => {
    console.log('🔍 [ScheduledEmailService] Debugging empty recipients...');

    try {
        const querySnapshot = await db
            .collection('scheduled_emails')
            .where('status', '==', 'pending')
            .get();

        const fixedEmails = [];

        for (const doc of querySnapshot.docs) {
            const data = doc.data();
            const recipientsData = data.recipientsData || [];

            if (recipientsData.length === 0) {
                // Email z pustymi recipientami - oznacz jako failed
                await updateEmailStatus(doc.id, 'failed', {
                    errorMessage: 'Email zaplanowany bez odbiorców - automatycznie anulowany'
                });

                fixedEmails.push(doc.id);
                console.log(`🔧 [ScheduledEmailService] Fixed empty recipients email: ${doc.id}`);
            }
        }

        return {
            success: true,
            message: `Sprawdzono ${querySnapshot.docs.length} emaili, naprawiono ${fixedEmails.length}`,
            fixedEmails
        };

    } catch (error) {
        console.error('❌ [ScheduledEmailService] Debug failed:', error);
        throw new HttpsError('internal', `Błąd debugowania: ${error.message}`);
    }
});

module.exports = {
    processScheduledEmails,
    testScheduledEmailProcessing,
    debugEmptyRecipients
};
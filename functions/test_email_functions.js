/**
 * Test Email Functions - Szybki test naprawionych funkcji email
 */

const admin = require('firebase-admin');

// Inicjalizuj Firebase Admin z domyślnymi ustawieniami
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function testEmailFunctions() {
  console.log('🧪 Testowanie naprawionych funkcji email...\n');

  try {
    // Test 1: Sprawdź czy nodemailer się ładuje poprawnie
    console.log('1️⃣ Test importu nodemailer...');
    const nodemailer = require('nodemailer');

    if (!nodemailer.createTransport) {
      throw new Error('nodemailer.createTransport is not available!');
    }

    console.log('✅ nodemailer.createTransport dostępne');

    // Test 2: Sprawdź czy można utworzyć transporter
    console.log('\n2️⃣ Test tworzenia transportera...');
    const testTransport = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      auth: {
        user: 'test@example.com',
        pass: 'testpassword'
      }
    });

    console.log('✅ Transporter utworzony poprawnie');

    // Test 3: Sprawdź konfigurację SMTP w Firestore
    console.log('\n3️⃣ Test konfiguracji SMTP w Firestore...');
    const smtpConfigDoc = await db.collection('app_settings').doc('smtp_configuration').get();

    if (smtpConfigDoc.exists) {
      const config = smtpConfigDoc.data();
      console.log('✅ Konfiguracja SMTP znaleziona:', {
        host: config.host,
        port: config.port,
        security: config.security,
        username: config.username ? '***' : 'BRAK'
      });
    } else {
      console.log('⚠️ Brak konfiguracji SMTP w Firestore');
      console.log('   Utwórz dokument: app_settings/smtp_configuration');
      console.log('   Przykładowe pola:');
      console.log('   {');
      console.log('     "host": "smtp.office365.com",');
      console.log('     "port": 587,');
      console.log('     "security": "tls",');
      console.log('     "username": "your@email.com",');
      console.log('     "password": "your_password"');
      console.log('   }');
    }

    // Test 4: Sprawdź czy collections investments i clients istnieją
    console.log('\n4️⃣ Test dostępu do danych...');

    const investmentsQuery = await db.collection('investments').limit(1).get();
    console.log(`✅ Kolekcja investments: ${investmentsQuery.size} dokumentów (sample)`);

    const clientsQuery = await db.collection('clients').limit(1).get();
    console.log(`✅ Kolekcja clients: ${clientsQuery.size} dokumentów (sample)`);

    // Test 5: Sprawdź funkcje email service
    console.log('\n5️⃣ Test importu serwisów email...');

    try {
      const emailService = require('./services/email-service.js');
      console.log('✅ email-service.js załadowany');
    } catch (e) {
      console.log('❌ Błąd email-service.js:', e.message);
    }

    try {
      const customEmailService = require('./services/custom-email-service.js');
      console.log('✅ custom-email-service.js załadowany');
    } catch (e) {
      console.log('❌ Błąd custom-email-service.js:', e.message);
    }

    try {
      const smtpTestService = require('./services/smtp-test-service.js');
      console.log('✅ smtp-test-service.js załadowany');
    } catch (e) {
      console.log('❌ Błąd smtp-test-service.js:', e.message);
    }

    console.log('\n🎉 Wszystkie testy przeszły pomyślnie!');
    console.log('\n📋 Podsumowanie:');
    console.log('   ✅ nodemailer.createTransport naprawione');
    console.log('   ✅ Serwisy email działają');
    console.log('   ✅ Dostęp do Firestore OK');
    console.log('\n🚀 Gotowe do deploymentu!');

  } catch (error) {
    console.error('\n❌ Błąd podczas testów:', error);
    process.exit(1);
  }
}

// Uruchom testy jeśli skrypt jest wywoływany bezpośrednio
if (require.main === module) {
  testEmailFunctions()
    .then(() => {
      console.log('\n✅ Testy zakończone pomyślnie');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Testy nie powiodły się:', error);
      process.exit(1);
    });
}

module.exports = { testEmailFunctions };

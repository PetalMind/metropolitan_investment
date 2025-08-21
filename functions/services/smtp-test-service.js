/**
 * SMTP Test Service - Testowanie połączenia i wysyłanie testowych maili
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Testowanie połączenia SMTP
 * • Wysyłanie testowych maili
 * • Walidacja konfiguracji SMTP
 * • Bezpieczne zarządzanie hasłami
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const nodemailer = require('nodemailer');

// CORS configuration
const corsOptions = {
  origin: [
    'https://metropolitan-investment.web.app',
    'https://metropolitan-investment.firebaseapp.com',
    'http://localhost:3000',
    'http://localhost:8080'
  ],
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};

/**
 * Testuje połączenie SMTP bez wysyłania maila
 * 
 * @param {Object} data - Dane wejściowe
 * @param {string} data.host - Host SMTP
 * @param {number} data.port - Port SMTP
 * @param {string} data.username - Nazwa użytkownika
 * @param {string} data.password - Hasło
 * @param {string} data.security - Typ zabezpieczenia ('none'|'ssl'|'tls')
 * 
 * @returns {Object} Wynik testowania połączenia
 */
const testSmtpConnection = onCall({ cors: corsOptions }, async (request) => {
  const startTime = Date.now();
  console.log(`🔧 [SmtpTestService] Rozpoczynam test połączenia SMTP`);

  try {
    const { host, port, username, password, security } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!host || !port || !username || !password) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagane są wszystkie pola: host, port, username, password'
      );
    }

    // Walidacja portu
    const portNumber = parseInt(port);
    if (isNaN(portNumber) || portNumber < 1 || portNumber > 65535) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy numer portu');
    }

    // Walidacja formatu email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(username)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email użytkownika');
    }

    console.log(`🔍 [SmtpTestService] Testuję połączenie: ${host}:${portNumber} (${security})`);

    // 🔧 KONFIGURACJA TRANSPORTERA
    const transportConfig = {
      host: host,
      port: portNumber,
      secure: security === 'ssl' || portNumber === 465, // SSL dla portu 465
      auth: {
        user: username,
        pass: password,
      },
    };

    // Dodatkowe opcje dla TLS
    if (security === 'tls') {
      transportConfig.requireTLS = true;
      transportConfig.tls = {
        ciphers: 'SSLv3',
        rejectUnauthorized: false // W środowisku produkcyjnym ustawić na true
      };
    }

    console.log(`📧 [SmtpTestService] Konfiguracja transportera:`, {
      host: transportConfig.host,
      port: transportConfig.port,
      secure: transportConfig.secure,
      requireTLS: transportConfig.requireTLS || false,
      authUser: transportConfig.auth.user
    });

    const transporter = nodemailer.createTransport(transportConfig);

    // 🧪 TEST POŁĄCZENIA
    console.log(`🔄 [SmtpTestService] Weryfikuję połączenie...`);
    await transporter.verify();

    console.log(`✅ [SmtpTestService] Połączenie SMTP pomyślne w ${Date.now() - startTime}ms`);

    return {
      success: true,
      message: 'Połączenie SMTP zostało pomyślnie nawiązane',
      details: {
        host: host,
        port: portNumber,
        security: security,
        username: username,
        responseTime: Date.now() - startTime
      }
    };

  } catch (error) {
    console.error(`❌ [SmtpTestService] Błąd podczas testowania połączenia:`, error);

    let errorMessage = 'Nieznany błąd połączenia';
    let errorCode = 'internal';

    // Interpretacja błędów SMTP
    if (error.code === 'EAUTH') {
      errorMessage = 'Błąd uwierzytelniania - sprawdź nazwę użytkownika i hasło';
      errorCode = 'unauthenticated';
    } else if (error.code === 'ENOTFOUND') {
      errorMessage = 'Nie można znaleźć serwera SMTP - sprawdź adres hosta';
      errorCode = 'not-found';
    } else if (error.code === 'ECONNREFUSED') {
      errorMessage = 'Odmowa połączenia - sprawdź port i typ zabezpieczenia';
      errorCode = 'unavailable';
    } else if (error.code === 'ETIMEDOUT') {
      errorMessage = 'Przekroczenie limitu czasu połączenia';
      errorCode = 'deadline-exceeded';
    } else if (error.message) {
      errorMessage = error.message;
    }

    if (error instanceof HttpsError) {
      throw error;
    } else {
      return {
        success: false,
        error: errorMessage,
        errorCode: error.code || 'UNKNOWN',
        details: {
          originalError: error.message,
          responseTime: Date.now() - startTime
        }
      };
    }
  }
});

/**
 * Wysyła testowy email
 * 
 * @param {Object} data - Dane wejściowe
 * @param {Object} data.smtpSettings - Ustawienia SMTP
 * @param {string} data.testEmail - Adres email do wysłania testu
 * @param {string} data.customMessage - Niestandardowa wiadomość
 * 
 * @returns {Object} Wynik wysyłania testowego maila
 */
const sendTestEmail = onCall({ cors: corsOptions }, async (request) => {
  const startTime = Date.now();
  console.log(`📧 [SmtpTestService] Rozpoczynam wysyłanie testowego maila`);

  try {
    const { smtpSettings, testEmail, customMessage } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!smtpSettings || !testEmail) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagane są: smtpSettings i testEmail'
      );
    }

    const { host, port, username, password, security } = smtpSettings;

    if (!host || !port || !username || !password) {
      throw new HttpsError(
        'invalid-argument',
        'Niepełne ustawienia SMTP'
      );
    }

    // Walidacja formatu email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(testEmail)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email testowego');
    }

    if (!emailRegex.test(username)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format email w ustawieniach SMTP');
    }

    console.log(`📧 [SmtpTestService] Wysyłam testowy mail do: ${testEmail}`);

    // 🔧 KONFIGURACJA TRANSPORTERA
    const transportConfig = {
      host: host,
      port: parseInt(port),
      secure: security === 'ssl' || parseInt(port) === 465,
      auth: {
        user: username,
        pass: password,
      },
    };

    if (security === 'tls') {
      transportConfig.requireTLS = true;
      transportConfig.tls = {
        ciphers: 'SSLv3',
        rejectUnauthorized: false
      };
    }

    const transporter = nodemailer.createTransport(transportConfig);

    // 📧 PRZYGOTOWANIE TREŚCI MAILA
    const subject = 'Test konfiguracji SMTP - Metropolitan Investment';

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .header { background: #1a237e; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .success { background: #e8f5e8; border: 1px solid #4caf50; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { background: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Metropolitan Investment</h1>
          <h2>Test Konfiguracji SMTP</h2>
        </div>
        
        <div class="content">
          <div class="success">
            <h3>✅ Sukces!</h3>
            <p>Konfiguracja serwera SMTP działa poprawnie.</p>
          </div>
          
          <p>Szanowny Użytkowniku,</p>
          
          <p>Ten email to potwierdzenie, że konfiguracja serwera SMTP w systemie Metropolitan Investment została pomyślnie skonfigurowana i działa poprawnie.</p>
          
          ${customMessage ? `<p><strong>Wiadomość niestandardowa:</strong><br><em>${customMessage}</em></p>` : ''}
          
          <h3>📋 Szczegóły konfiguracji:</h3>
          <ul>
            <li><strong>Host SMTP:</strong> ${host}</li>
            <li><strong>Port:</strong> ${port}</li>
            <li><strong>Zabezpieczenia:</strong> ${security.toUpperCase()}</li>
            <li><strong>Użytkownik:</strong> ${username}</li>
            <li><strong>Data testu:</strong> ${new Date().toLocaleString('pl-PL')}</li>
          </ul>
          
          <p>System email jest gotowy do wysyłania wiadomości do klientów.</p>
          
          <p>Z poważaniem,<br>
          <strong>Zespół Metropolitan Investment</strong></p>
        </div>
        
        <div class="footer">
          <p>Ten email został wygenerowany automatycznie przez system testowania SMTP.</p>
          <p>Metropolitan Investment - Zarządzanie Kapitałem</p>
        </div>
      </body>
      </html>
    `;

    const textContent = `
Metropolitan Investment - Test Konfiguracji SMTP

✅ SUKCES!
Konfiguracja serwera SMTP działa poprawnie.

Szanowny Użytkowniku,

Ten email to potwierdzenie, że konfiguracja serwera SMTP w systemie Metropolitan Investment została pomyślnie skonfigurowana i działa poprawnie.

${customMessage ? `Wiadomość niestandardowa: ${customMessage}\n\n` : ''}

SZCZEGÓŁY KONFIGURACJI:
- Host SMTP: ${host}
- Port: ${port}
- Zabezpieczenia: ${security.toUpperCase()}
- Użytkownik: ${username}
- Data testu: ${new Date().toLocaleString('pl-PL')}

System email jest gotowy do wysyłania wiadomości do klientów.

Z poważaniem,
Zespół Metropolitan Investment

---
Ten email został wygenerowany automatycznie przez system testowania SMTP.
Metropolitan Investment - Zarządzanie Kapitałem
    `;

    // 📬 WYSYŁANIE MAILA
    const mailOptions = {
      from: `Metropolitan Investment <${username}>`,
      to: testEmail,
      subject: subject,
      html: htmlContent,
      text: textContent,
    };

    console.log(`🔄 [SmtpTestService] Wysyłam mail testowy...`);
    const emailResult = await transporter.sendMail(mailOptions);

    console.log(`✅ [SmtpTestService] Testowy mail wysłany pomyślnie. MessageId: ${emailResult.messageId}`);

    return {
      success: true,
      message: 'Testowy email został pomyślnie wysłany',
      details: {
        messageId: emailResult.messageId,
        to: testEmail,
        from: username,
        subject: subject,
        responseTime: Date.now() - startTime,
        smtpHost: host,
        smtpPort: port,
        security: security
      }
    };

  } catch (error) {
    console.error(`❌ [SmtpTestService] Błąd podczas wysyłania testowego maila:`, error);

    let errorMessage = 'Nieznany błąd podczas wysyłania maila';
    let errorCode = 'internal';

    // Interpretacja błędów SMTP
    if (error.code === 'EAUTH') {
      errorMessage = 'Błąd uwierzytelniania - sprawdź nazwę użytkownika i hasło';
      errorCode = 'unauthenticated';
    } else if (error.code === 'ENOTFOUND') {
      errorMessage = 'Nie można znaleźć serwera SMTP - sprawdź adres hosta';
      errorCode = 'not-found';
    } else if (error.code === 'ECONNREFUSED') {
      errorMessage = 'Odmowa połączenia - sprawdź port i typ zabezpieczenia';
      errorCode = 'unavailable';
    } else if (error.code === 'EMESSAGE') {
      errorMessage = 'Błąd w treści wiadomości email';
      errorCode = 'invalid-argument';
    } else if (error.message) {
      errorMessage = error.message;
    }

    if (error instanceof HttpsError) {
      throw error;
    } else {
      return {
        success: false,
        error: errorMessage,
        errorCode: error.code || 'UNKNOWN',
        details: {
          originalError: error.message,
          responseTime: Date.now() - startTime
        }
      };
    }
  }
});

module.exports = {
  testSmtpConnection,
  sendTestEmail,
};
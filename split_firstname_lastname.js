#!/usr/bin/env node
/**
 * Skrypt do rozdzielenia pól firstName i lastName w kolekcji 'employees' w Firebase
 * Skrypt analizuje pole firstName, rozdziela imię i nazwisko, i aktualizuje dokumenty pracowników
 * 
 * Uruchomienie: node split_firstname_lastname.js
 * Opcje:
 *   --dry-run, -d     Tylko symulacja (bez zapisywania)
 *   --test, -t        Test połączenia z Firebase
 *   --help, -h        Wyświetla pomoc
 */

const admin = require('firebase-admin');
const path = require('path');

// Inicjalizacja Firebase Admin SDK
// Spróbuj załadować plik ServiceAccount.json, ale jeśli nie istnieje, użyj domyślnych uwierzytelnień
let serviceAccount;
try {
  serviceAccount = require('./ServiceAccount.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'metropolitan-investment'
  });
} catch (error) {
  // Jeśli nie można załadować pliku, używamy domyślnych uwierzytelnień
  console.log('⚠️ Nie znaleziono pliku ServiceAccount.json, używam domyślnych uwierzytelnień...');
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Rozdziela pełne imię i nazwisko na dwie części
 * @param {string} fullName - Pełne imię i nazwisko
 * @returns {Object} Obiekt zawierający firstName i lastName
 */
function splitFullName(fullName) {
  if (!fullName || typeof fullName !== 'string') {
    return { firstName: '', lastName: '' };
  }

  const nameParts = fullName.trim().split(/\s+/);

  if (nameParts.length === 0) {
    return { firstName: '', lastName: '' };
  } else if (nameParts.length === 1) {
    // Jeśli jest tylko jedno słowo, traktujemy je jako imię
    return { firstName: nameParts[0], lastName: '' };
  } else {
    // Pierwsze słowo to imię, reszta to nazwisko
    const firstName = nameParts[0];
    const lastName = nameParts.slice(1).join(' ');
    return { firstName, lastName };
  }
}

/**
 * Testuje rozdzielenie imienia i nazwiska dla przykładowych danych
 */
function testNameSplitting() {
  const testCases = [
    "Jarosław Maliniak",
    "Anna Maria Kowalska",
    "Jan",
    "   Adam   Nowak   ",
    "Krzysztof de Vito",
    ""
  ];

  console.log('🧪 Test rozdzielania imion i nazwisk:');
  testCases.forEach(name => {
    const { firstName, lastName } = splitFullName(name);
    console.log(`"${name}" → firstName: "${firstName}", lastName: "${lastName}"`);
  });
  console.log('');
}

/**
 * Aktualizuje pojedynczy dokument, rozdzielając firstName i lastName
 * @param {string} docId - ID dokumentu pracownika
 * @param {boolean} dryRun - Czy tylko symulować (bez zapisywania)
 * @returns {Promise<Object>} Wynik operacji
 */
async function updateEmployeeNameFields(docId, dryRun = false) {
  try {
    // Pobierz dokument pracownika
    const docRef = db.collection('employees').doc(docId);
    const docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      return {
        success: false,
        docId,
        reason: 'not_found',
        message: 'Dokument nie istnieje'
      };
    }

    const clientData = docSnapshot.data();
    const currentFirstName = clientData.firstName || '';
    const currentLastName = clientData.lastName || '';

    // Jeśli firstName i lastName mają te same wartości lub firstName zawiera spację (pełne imię i nazwisko)
    if ((currentFirstName === currentLastName && currentFirstName.includes(' ')) ||
      (currentFirstName.includes(' ') && !currentLastName)) {

      // Rozdziel firstName na dwie części
      const { firstName, lastName } = splitFullName(currentFirstName);

      console.log(`📝 ${docId}: "${currentFirstName}" → firstName: "${firstName}", lastName: "${lastName}"`);

      // Aktualizuj dokument (chyba że to dry run)
      if (!dryRun) {
        await docRef.update({
          firstName: firstName,
          lastName: lastName,
          updatedAt: admin.firestore.Timestamp.now()
        });

        return {
          success: true,
          docId,
          action: 'updated',
          oldFirstName: currentFirstName,
          oldLastName: currentLastName,
          newFirstName: firstName,
          newLastName: lastName
        };
      } else {
        return {
          success: true,
          docId,
          action: 'would_update',
          oldFirstName: currentFirstName,
          oldLastName: currentLastName,
          newFirstName: firstName,
          newLastName: lastName
        };
      }
    } else {
      // Żadne zmiany nie są wymagane
      return {
        success: true,
        docId,
        action: 'skipped',
        reason: 'no_changes_needed',
        firstName: currentFirstName,
        lastName: currentLastName
      };
    }

  } catch (error) {
    console.error(`❌ Błąd przy aktualizacji klienta ${docId}:`, error);
    return {
      success: false,
      docId,
      reason: 'error',
      error: error.message
    };
  }
}

/**
 * Przetwarzanie konkretnej listy ID pracowników
 * @param {string[]} employeeIds - Lista ID pracowników do aktualizacji
 * @param {boolean} dryRun - Czy tylko symulować (bez zapisywania)
 * @returns {Promise<Object>} Statystyki operacji
 */
async function processEmployeeIds(employeeIds, dryRun = false) {
  const stats = {
    total: employeeIds.length,
    processed: 0,
    updated: 0,
    skipped: 0,
    notFound: 0,
    errors: 0,
    results: []
  };

  console.log(`\n📊 Rozpoczynanie przetwarzania ${stats.total} pracowników...${dryRun ? ' (TRYB SYMULACJI)' : ''}`);

  // Przetwarzanie każdego ID pracownika
  for (let i = 0; i < employeeIds.length; i++) {
    const employeeId = employeeIds[i];
    const result = await updateEmployeeNameFields(employeeId, dryRun);

    stats.processed++;
    stats.results.push(result);

    // Aktualizacja statystyk
    if (result.success) {
      if (result.action === 'updated' || result.action === 'would_update') {
        stats.updated++;
      } else if (result.action === 'skipped') {
        stats.skipped++;
      }
    } else {
      if (result.reason === 'not_found') {
        stats.notFound++;
      } else {
        stats.errors++;
      }
    }
  }

  return stats;
}

/**
 * Funkcja testowa - sprawdza połączenie z Firebase
 */
async function testFirebaseConnection() {
  try {
    console.log('🔍 Testowanie połączenia z Firebase...');

    // Test zapisu
    const testDoc = db.collection('test').doc('connection_test');
    await testDoc.set({
      timestamp: admin.firestore.Timestamp.now(),
      message: 'Test connection'
    });

    // Test odczytu
    const doc = await testDoc.get();
    if (doc.exists) {
      console.log('✅ Połączenie z Firebase działa poprawnie');

      // Usunięcie dokumentu testowego
      await testDoc.delete();
      return true;
    }

    return false;
  } catch (error) {
    console.error('❌ Błąd połączenia z Firebase:', error);
    return false;
  }
}

/**
 * Główna funkcja skryptu
 */
async function main() {
  // Lista pracowników do przetworzenia
  const employeeIds = [
    'VzHB24fNWK4U0wuN',
    '4BhIJ2HGvIStZ3ZW59og',
    '5t9TAogibCbzjB5aMasc',
    '7m6zXPtciO50Mi9B8R5b',
    '99bwm3E504n3sDJ4tutV',
    'B18gtQWnBQHJnEIIY0us',
    'Gn3d4uY6laXdcUQYKLtC',
    'JMdkJBqOVOIsludmHkiK',
    'JW42zAEx53GLb4nvPzqG',
    'LrHgYGKuG578AOQNnjTV',
    'MSX9JvuUy2QAodp5X5ll',
    'OnJmD9MT7DCUYXc1RItE',
    'RRiw9fwybu3jwryvmKn2',
    'SGyTodmjxVjmPwovcOCn',
    'VtINkY4ezU807fXvjQ7a',
    'XAd27eZnBwCxxvaMYIk5',
    'YpFpYGKsxjJXvreXOu5V',
    'Z4O4ylIRmxepqZsrAsla',
    'djLZfMVVm1ynya49gbzH',
    'dpA5lSR7zMlCerlPKMkU',
    'eTM55pwVCrjQuhvP57Ro',
    'f3WPgYpXlw4Wh1l1XPvi',
    'i6A9wkv9xNB82xYxdQ0b',
    'iyYNakYsX8bNTTdxPAZ2',
    'jWHqNoWxRQfOsyXv6igc',
    'kRjLp2NeUdP3uRkOPbyE',
    'kaznMBM2HC1prf5O7jFr',
    'kfSYdAet6nJ4RZjkK7Sk',
    'm4NZ6mbDuGDS9UFPzNZ2',
    'mk16QqHwaUo077FLOUWv',
    'nRKFdsPizPP2VQLx2LlH',
    'ssCWLo8ThPCwpmvUKqCV',
    '3ym9VzHB24fNWK4U0wuN'
  ];

  // Parsowanie argumentów
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  const testOnly = args.includes('--test') || args.includes('-t');
  const helpRequested = args.includes('--help') || args.includes('-h');

  // Wyświetlenie pomocy
  if (helpRequested) {
    console.log(`
📚 Skrypt do rozdzielania pól firstName i lastName pracowników w Firebase

Użycie:
  node split_firstname_lastname.js [opcje]

Opcje:
  --dry-run, -d     Tylko symulacja (bez zapisywania)
  --test, -t        Test połączenia z Firebase
  --help, -h        Pokaż tę pomoc

Przykłady:
  node split_firstname_lastname.js            # Normalna aktualizacja pracowników
  node split_firstname_lastname.js --dry-run  # Symulacja (bez zapisywania)
  node split_firstname_lastname.js --test     # Test połączenia
    `);
    process.exit(0);
  }

  try {
    // Test funkcji rozdzielania imienia i nazwiska
    testNameSplitting();

    // Test połączenia jeśli wymagany
    if (testOnly) {
      const connected = await testFirebaseConnection();
      process.exit(connected ? 0 : 1);
    }

    // Test połączenia przed głównym updatem
    console.log('🔍 Sprawdzanie połączenia z Firebase...');
    const connected = await testFirebaseConnection();
    if (!connected) {
      console.error('❌ Nie można nawiązać połączenia z Firebase. Sprawdź konfigurację.');
      process.exit(1);
    }

    // Główne przetwarzanie
    const stats = await processEmployeeIds(employeeIds, dryRun);

    // Podsumowanie
    console.log('\n' + '='.repeat(50));
    console.log(`📊 PODSUMOWANIE ${dryRun ? '(SYMULACJA)' : ''}`);
    console.log('='.repeat(50));
    console.log(`📋 Łącznie przetworzonych: ${stats.processed}/${stats.total}`);
    console.log(`✅ Zaktualizowanych: ${stats.updated}`);
    console.log(`⏭️ Pominiętych: ${stats.skipped}`);
    console.log(`🔍 Nie znaleziono: ${stats.notFound}`);
    console.log(`❌ Błędów: ${stats.errors}`);
    console.log('='.repeat(50));

    if (stats.errors === 0) {
      console.log('🎉 Aktualizacja zakończona pomyślnie!');
    } else {
      console.log('⚠️ Aktualizacja zakończona z błędami. Sprawdź logi powyżej.');
    }

  } catch (error) {
    console.error('💥 Nieoczekiwany błąd:', error);
    process.exit(1);
  } finally {
    // Zakończenie połączenia
    console.log('👋 Zamykanie połączenia...');
    process.exit(0);
  }
}

// Uruchomienie skryptu
if (require.main === module) {
  main();
}

// Eksportowanie funkcji dla użycia jako moduł
module.exports = {
  splitFullName,
  updateEmployeeNameFields,
  testFirebaseConnection
};

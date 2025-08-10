const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Inicjalizacja Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://metropolitan-investment-default-rtdb.europe-west1.firebasedatabase.app"
});

const db = admin.firestore();

// Konfiguracja
const CONFIG = {
  batchSize: 500, // Maksymalna liczba dokumentów w batch
  dryRun: false,  // Ustaw true aby tylko sprawdzić bez wysyłania
  sourceDir: './split_investment_data_normalized', // Folder z znormalizowanymi danymi
  collections: {
    'clients_normalized.json': 'clients',
    'apartments_normalized.json': 'investments',
    'loans_normalized.json': 'investments',
    'shares_normalized.json': 'investments'
  },
  timestampFields: ['createdAt', 'updatedAt', 'signingDate', 'entryDate', 'disbursementDate', 'repaymentDate', 'deliveryDate'],
  logLevel: 'INFO' // DEBUG, INFO, WARN, ERROR
};

// Utility functions
function log(level, message, data = null) {
  const levels = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3 };
  const currentLevel = levels[CONFIG.logLevel] || 1;

  if (levels[level] >= currentLevel) {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${level}: ${message}`);
    if (data && level === 'DEBUG') {
      console.log(JSON.stringify(data, null, 2));
    }
  }
}

function convertToFirebaseTimestamp(dateString) {
  if (!dateString || dateString === '') return null;

  // Obsługa różnych formatów daty
  let date;
  if (dateString.includes('/')) {
    // Format DD/MM/YYYY lub MM/DD/YYYY
    const parts = dateString.split('/');
    if (parts.length === 3) {
      // Zakładamy DD/MM/YYYY (polski format)
      date = new Date(`${parts[2]}-${parts[1]}-${parts[0]}`);
    }
  } else if (dateString.includes('-')) {
    // Format YYYY-MM-DD
    date = new Date(dateString);
  } else {
    return null;
  }

  return date.getTime() > 0 ? admin.firestore.Timestamp.fromDate(date) : null;
}

function processDocument(doc, productType = null) {
  const processedDoc = { ...doc };

  // Konwersja dat na Firebase Timestamps
  CONFIG.timestampFields.forEach(field => {
    if (processedDoc[field]) {
      processedDoc[field] = convertToFirebaseTimestamp(processedDoc[field]);
    }
  });

  // Dodanie metadanych
  processedDoc.uploadedAt = admin.firestore.Timestamp.now();
  processedDoc.dataVersion = '2.0'; // Oznaczenie znormalizowanych danych
  processedDoc.migrationSource = 'normalized_json_import';

  if (productType) {
    processedDoc.productType = productType;
  }

  // Konwersja numerycznych stringów na liczby
  ['investmentAmount', 'remainingCapital', 'paidAmount', 'realizedCapital',
    'accruedInterest', 'interestRate', 'area', 'pricePerM2', 'sharesCount'].forEach(field => {
      if (processedDoc[field] && typeof processedDoc[field] === 'string') {
        const num = parseFloat(processedDoc[field].replace(/,/g, ''));
        if (!isNaN(num)) {
          processedDoc[field] = num;
        }
      }
    });

  // Konwersja boolean wartości
  ['hasBalcony', 'hasParkingSpace', 'hasStorage'].forEach(field => {
    if (processedDoc[field] === '1' || processedDoc[field] === 1) {
      processedDoc[field] = true;
    } else if (processedDoc[field] === '0' || processedDoc[field] === 0) {
      processedDoc[field] = false;
    }
  });

  return processedDoc;
}

async function uploadDocuments(collectionName, documents, productType = null) {
  log('INFO', `Rozpoczynanie uploadu do kolekcji: ${collectionName}`);
  log('INFO', `Liczba dokumentów do przesłania: ${documents.length}`);

  if (CONFIG.dryRun) {
    log('WARN', 'DRY RUN MODE - dokumenty nie zostaną przesłane');
    return { success: documents.length, errors: 0 };
  }

  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  // Przetwarzanie w batch'ach
  for (let i = 0; i < documents.length; i += CONFIG.batchSize) {
    const batch = db.batch();
    const batchDocs = documents.slice(i, i + CONFIG.batchSize);

    log('INFO', `Przetwarzanie batch ${Math.floor(i / CONFIG.batchSize) + 1}/${Math.ceil(documents.length / CONFIG.batchSize)}`);

    batchDocs.forEach(doc => {
      try {
        const processedDoc = processDocument(doc, productType);

        // Generowanie ID dokumentu
        let docId;
        if (processedDoc.id) {
          docId = processedDoc.id.toString();
        } else if (processedDoc.clientId && processedDoc.productType) {
          docId = `${processedDoc.clientId}_${processedDoc.productType}_${Date.now()}`;
        } else {
          docId = db.collection(collectionName).doc().id;
        }

        const docRef = db.collection(collectionName).doc(docId);
        batch.set(docRef, processedDoc);

        log('DEBUG', `Przygotowano dokument ${docId}`, processedDoc);

      } catch (error) {
        log('ERROR', `Błąd przetwarzania dokumentu: ${error.message}`);
        errors.push({ doc, error: error.message });
        errorCount++;
      }
    });

    try {
      await batch.commit();
      successCount += batchDocs.length - errors.length;
      log('INFO', `Batch przesłany pomyślnie (${batchDocs.length} dokumentów)`);

      // Krótka pauza między batch'ami
      await new Promise(resolve => setTimeout(resolve, 100));

    } catch (error) {
      log('ERROR', `Błąd przesyłania batch: ${error.message}`);
      errorCount += batchDocs.length;
      errors.push({ batch: i, error: error.message });
    }
  }

  return { success: successCount, errors: errorCount, details: errors };
}

async function loadJsonFile(filename) {
  try {
    const filePath = path.join(CONFIG.sourceDir, filename);
    const data = await fs.readFile(filePath, 'utf8');
    const jsonData = JSON.parse(data);

    log('INFO', `Załadowano plik ${filename}: ${jsonData.length} rekordów`);
    return jsonData;

  } catch (error) {
    log('ERROR', `Błąd ładowania pliku ${filename}: ${error.message}`);
    return [];
  }
}

async function verifyUpload(collectionName, expectedCount) {
  if (CONFIG.dryRun) return true;

  try {
    const snapshot = await db.collection(collectionName)
      .where('migrationSource', '==', 'normalized_json_import')
      .get();

    const actualCount = snapshot.size;
    log('INFO', `Weryfikacja ${collectionName}: oczekiwano ${expectedCount}, znaleziono ${actualCount}`);

    return actualCount === expectedCount;
  } catch (error) {
    log('ERROR', `Błąd weryfikacji: ${error.message}`);
    return false;
  }
}

async function main() {
  const startTime = Date.now();
  log('INFO', '🚀 Rozpoczynanie przesyłania znormalizowanych danych do Firebase');
  log('INFO', `Konfiguracja: DryRun=${CONFIG.dryRun}, BatchSize=${CONFIG.batchSize}`);

  const results = {
    totalProcessed: 0,
    totalSuccess: 0,
    totalErrors: 0,
    collections: {}
  };

  try {
    // Sprawdź czy folder istnieje
    await fs.access(CONFIG.sourceDir);

    // Przetwarzaj każdy plik
    for (const [filename, collectionName] of Object.entries(CONFIG.collections)) {
      log('INFO', `\n📁 Przetwarzanie: ${filename} -> ${collectionName}`);

      const documents = await loadJsonFile(filename);
      if (documents.length === 0) {
        log('WARN', `Pominięto pusty plik: ${filename}`);
        continue;
      }

      // Określ typ produktu na podstawie nazwy pliku
      let productType = null;
      if (filename.includes('apartments')) productType = 'apartment';
      else if (filename.includes('loans')) productType = 'loan';
      else if (filename.includes('shares')) productType = 'share';

      const result = await uploadDocuments(collectionName, documents, productType);

      results.totalProcessed += documents.length;
      results.totalSuccess += result.success;
      results.totalErrors += result.errors;
      results.collections[filename] = result;

      log('INFO', `✅ Zakończono ${filename}: ${result.success} sukces, ${result.errors} błędów`);

      // Weryfikacja
      if (!CONFIG.dryRun) {
        const verified = await verifyUpload(collectionName, result.success);
        log(verified ? 'INFO' : 'WARN', `Weryfikacja ${collectionName}: ${verified ? 'OK' : 'BŁĄD'}`);
      }
    }

    // Podsumowanie
    const duration = (Date.now() - startTime) / 1000;
    log('INFO', '\n🎉 PODSUMOWANIE:');
    log('INFO', `⏱️  Czas wykonania: ${duration.toFixed(2)}s`);
    log('INFO', `📊 Przetworzono: ${results.totalProcessed} dokumentów`);
    log('INFO', `✅ Sukces: ${results.totalSuccess} dokumentów`);
    log('INFO', `❌ Błędy: ${results.totalErrors} dokumentów`);
    log('INFO', `📈 Wskaźnik sukcesu: ${((results.totalSuccess / results.totalProcessed) * 100).toFixed(1)}%`);

    // Szczegóły dla każdego pliku
    Object.entries(results.collections).forEach(([filename, result]) => {
      log('INFO', `  ${filename}: ${result.success}/${result.success + result.errors} (${((result.success / (result.success + result.errors)) * 100).toFixed(1)}%)`);
    });

    if (CONFIG.dryRun) {
      log('WARN', '⚠️  To był DRY RUN - ustaw CONFIG.dryRun = false aby przesłać dane');
    }

  } catch (error) {
    log('ERROR', `Krytyczny błąd: ${error.message}`);
    console.error(error);
  }
}

// Dodatkowe funkcje pomocnicze

async function cleanupPreviousImports() {
  log('INFO', '🧹 Czyszczenie poprzednich importów...');

  if (CONFIG.dryRun) {
    log('WARN', 'DRY RUN - czyszczenie pomijane');
    return;
  }

  const collections = ['clients', 'investments'];

  for (const collectionName of collections) {
    try {
      const snapshot = await db.collection(collectionName)
        .where('migrationSource', '==', 'normalized_json_import')
        .get();

      if (snapshot.empty) {
        log('INFO', `Brak poprzednich danych w ${collectionName}`);
        continue;
      }

      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      log('INFO', `Usunięto ${snapshot.size} dokumentów z ${collectionName}`);

    } catch (error) {
      log('ERROR', `Błąd czyszczenia ${collectionName}: ${error.message}`);
    }
  }
}

async function generateReport() {
  if (CONFIG.dryRun) return;

  log('INFO', '📋 Generowanie raportu...');

  const report = {
    timestamp: new Date().toISOString(),
    collections: {}
  };

  const collections = ['clients', 'investments'];

  for (const collectionName of collections) {
    try {
      const totalSnapshot = await db.collection(collectionName).get();
      const importedSnapshot = await db.collection(collectionName)
        .where('migrationSource', '==', 'normalized_json_import')
        .get();

      report.collections[collectionName] = {
        total: totalSnapshot.size,
        imported: importedSnapshot.size,
        percentage: ((importedSnapshot.size / totalSnapshot.size) * 100).toFixed(1)
      };

    } catch (error) {
      log('ERROR', `Błąd generowania raportu dla ${collectionName}: ${error.message}`);
    }
  }

  await fs.writeFile('./firebase_upload_report.json', JSON.stringify(report, null, 2));
  log('INFO', '📄 Raport zapisany w firebase_upload_report.json');
}

// Obsługa argumentów wiersza poleceń
const args = process.argv.slice(2);
if (args.includes('--dry-run')) {
  CONFIG.dryRun = true;
  log('INFO', '🔍 Uruchomiono w trybie DRY RUN');
}
if (args.includes('--cleanup')) {
  log('INFO', '🧹 Wykonywanie czyszczenia przed importem');
  cleanupPreviousImports().then(() => main());
} else {
  main().then(() => {
    if (args.includes('--report')) {
      generateReport();
    }
  });
}

module.exports = {
  uploadDocuments,
  processDocument,
  convertToFirebaseTimestamp
};

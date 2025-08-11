const { NormalizedClientsUploader } = require('./upload_normalized_clients.js');

class MissingRecordsUploader extends NormalizedClientsUploader {
  constructor() {
    super();
    this.missingOnly = true;
  }

  async findMissingRecords() {
    try {
      console.log('🔍 Szukam brakujących rekordów...');

      // Załaduj oryginalne dane
      const originalClients = await this.loadNormalizedClientsData();

      // Pobierz zapisane ID z Firebase
      const snapshot = await this.db.collection('clients').get();
      const savedIds = new Set();

      snapshot.forEach(doc => {
        savedIds.add(parseInt(doc.id));
      });

      // Znajdź brakujące rekordy
      const missingRecords = originalClients.filter(client => !savedIds.has(client.id));

      console.log(`📊 Znaleziono ${missingRecords.length} brakujących rekordów z ${originalClients.length} oryginalnych`);

      if (missingRecords.length > 0) {
        console.log('📋 Pierwsze 10 brakujących rekordów:');
        missingRecords.slice(0, 10).forEach(client => {
          console.log(`   ID: ${client.id}, Nazwa: "${client.fullName}"`);
        });
      }

      return missingRecords;

    } catch (error) {
      console.error('❌ Błąd wyszukiwania brakujących rekordów:', error.message);
      throw error;
    }
  }

  async uploadMissingRecords() {
    console.log('🔄 NAPRAWA BRAKUJĄCYCH REKORDÓW');
    console.log('='.repeat(50));

    try {
      // 1. Inicjalizacja
      await this.initialize();

      // 2. Znajdź brakujące rekordy
      const missingRecords = await this.findMissingRecords();

      if (missingRecords.length === 0) {
        console.log('✅ Brak brakujących rekordów - wszystkie klienci są już w bazie!');
        return;
      }

      // 3. Potwierdź upload
      if (!this.dryRun) {
        console.log(`\n❓ Czy chcesz uploadować ${missingRecords.length} brakujących rekordów?`);
        console.log('   Naciśnij Ctrl+C aby anulować lub Enter aby kontynuować...');
        await new Promise(resolve => setTimeout(resolve, 2000));
      }

      // 4. Upload brakujących rekordów
      await this.uploadClientsInBatches(missingRecords);

      // 5. Sprawdź czy wszystko zostało naprawione
      const remainingMissing = await this.findMissingRecords();

      if (remainingMissing.length === 0) {
        console.log('\n✅ NAPRAWA ZAKOŃCZONA SUKCESEM! Wszystkie rekordy są już w bazie.');
      } else {
        console.log(`\n⚠️  Nadal brakuje ${remainingMissing.length} rekordów. Może być potrzebna dodatkowa analiza.`);
      }

    } catch (error) {
      console.error('\n💥 BŁĄD NAPRAWY:', error.message);
      throw error;
    }
  }
}

// Główna funkcja
async function main() {
  console.log('🔧 NAPRAWA BRAKUJĄCYCH KLIENTÓW v1.0');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  // Sprawdź argumenty wiersza poleceń
  const args = process.argv.slice(2);

  const uploader = new MissingRecordsUploader();
  uploader.dryRun = args.includes('--dry-run');
  uploader.showReport = args.includes('--report');

  if (uploader.dryRun) {
    console.log('🔧 Tryb DRY RUN: tylko analiza bez naprawy');
  }

  try {
    if (uploader.dryRun) {
      // W trybie dry run tylko znajdź brakujące
      await uploader.initialize();
      await uploader.findMissingRecords();
    } else {
      // Pełna naprawa
      await uploader.uploadMissingRecords();
    }

    console.log('\n🎉 Proces zakończony pomyślnie!');
    process.exit(0);

  } catch (error) {
    console.error('\n💥 KRYTYCZNY BŁĄD:', error.message);
    process.exit(1);
  }
}

// Obsługa sygnałów
process.on('SIGINT', () => {
  console.log('\n🛑 Proces anulowany przez użytkownika');
  process.exit(1);
});

// Uruchom program
if (require.main === module) {
  main();
}

module.exports = { MissingRecordsUploader };

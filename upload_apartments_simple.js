// Skrypt do wgrywania produktow apartamentowych do Firebase
// Wzorowany na upload_clients_with_uuid.js
// npm install firebase-admin

const fs = require('fs');
const admin = require('firebase-admin');

// Sciezka do pliku z danymi produktow apartamentowych
const DATA_PATH = './apartment_products.json';

// Sciezka do pliku z kluczem serwisowym Firebase
const SERVICE_ACCOUNT_PATH = './service-account.json';

// Nazwa kolekcji w Firestore
const COLLECTION_NAME = 'products';

// Inicjalizacja Firebase
admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

// Sprawdz czy produkt juz istnieje w bazie
async function checkProductExists(productId, productName, companyName) {
  try {
    // Sprawdz po ID
    const docSnapshot = await db.collection(COLLECTION_NAME).doc(productId).get();
    if (docSnapshot.exists) {
      return { exists: true, reason: `ID juz istnieje: ${productId}` };
    }

    // Sprawdz po nazwie + spolce + typie
    const querySnapshot = await db.collection(COLLECTION_NAME)
      .where('name', '==', productName)
      .where('companyName', '==', companyName)
      .where('type', '==', 'apartments')
      .get();

    if (!querySnapshot.empty) {
      const existingDoc = querySnapshot.docs[0];
      return {
        exists: true,
        reason: `Duplikat nazwy i spolki (istniejacy ID: ${existingDoc.id})`
      };
    }

    return { exists: false };
  } catch (error) {
    console.error(`Blad sprawdzania produktu ${productName}:`, error.message);
    return { exists: false };
  }
}

async function uploadApartmentProducts() {
  console.log('APARTMENT PRODUCTS UPLOADER');
  console.log('Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  // Sprawdz czy plik z produktami istnieje
  if (!fs.existsSync(DATA_PATH)) {
    console.error(`Plik ${DATA_PATH} nie istnieje. Uruchom najpierw migrator:`);
    console.error('   dart run tools/apartment_products_migrator.dart');
    process.exit(1);
  }

  // Wczytaj produkty
  const products = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
  if (!Array.isArray(products)) {
    console.error('Plik JSON powinien zawierac tablice produktow.');
    process.exit(1);
  }

  console.log(`Znaleziono ${products.length} produktow apartamentowych do uploadu`);

  // Sprawdz tryb dzialania
  const forceUpdate = process.argv.includes('--force') || process.argv.includes('-f');
  console.log(`Tryb: ${forceUpdate ? 'FORCE (nadpisywanie)' : 'BEZPIECZNY (pomijanie duplikatow)'}`);

  // Statystyki
  let uploaded = 0;
  let skipped = 0;
  let updated = 0;
  let errors = 0;

  // Przetwarz kazdy produkt
  for (let i = 0; i < products.length; i++) {
    const product = products[i];
    console.log(`\n[${i + 1}/${products.length}] Przetwarzam: "${product.name}"`);

    try {
      // Sprawdz czy juz istnieje
      const existsCheck = await checkProductExists(product.id, product.name, product.companyName);

      if (existsCheck.exists && !forceUpdate) {
        console.log(`  POMINIETO - ${existsCheck.reason}`);
        skipped++;
        continue;
      }

      // Przygotuj dane do zapisu
      const productId = product.id;
      const productData = { ...product };
      delete productData.id; // Usun ID z danych

      // Dodaj metadane upload
      productData.uploaded_at = new Date().toISOString();
      productData.source_file = 'apartment_products.json';
      productData.migration_version = '2025_08_06';

      if (existsCheck.exists && forceUpdate) {
        productData.updated_at = new Date().toISOString();
        productData.update_reason = 'Force update from migration';
      }

      // Upload do Firestore
      await db.collection(COLLECTION_NAME).doc(productId).set(productData, { merge: true });

      if (existsCheck.exists) {
        console.log(`  ZAKTUALIZOWANO - ${existsCheck.reason}`);
        updated++;
      } else {
        console.log(`  DODANO NOWY`);
        uploaded++;
      }

      // Krotka pauza miedzy uploads
      await new Promise(resolve => setTimeout(resolve, 200));

    } catch (error) {
      console.error(`  BLAD: ${error.message}`);
      errors++;
    }
  }

  // Podsumowanie
  console.log('\n' + '='.repeat(70));
  console.log('PODSUMOWANIE UPLOADU PRODUKTOW APARTAMENTOWYCH');
  console.log('='.repeat(70));
  console.log(`Produktow do sprawdzenia: ${products.length}`);
  console.log(`Nowych dodanych: ${uploaded}`);
  console.log(`Zaktualizowanych: ${updated}`);
  console.log(`Pominiętych (duplikaty): ${skipped}`);
  console.log(`Bledow: ${errors}`);

  const successRate = Math.round(((uploaded + updated) / products.length) * 100);
  console.log(`Sukces: ${successRate}%`);
  console.log('='.repeat(70));

  // Weryfikacja
  console.log('\nWeryfikacja uploadu...');
  try {
    const snapshot = await db.collection(COLLECTION_NAME).where('type', '==', 'apartments').get();
    console.log(`Produktow apartamentowych w bazie: ${snapshot.size}`);

    console.log('\nPrzyktady zapisanych produktow apartamentowych:');
    let count = 0;
    snapshot.forEach(doc => {
      if (count < 3) {
        const data = doc.data();
        const meta = data.metadata || {};
        console.log(`   - ${data.name} (${data.companyName})`);
        console.log(`     ${meta.totalAmount || 'N/A'} PLN, ${meta.totalInvestments || 'N/A'} inwestycji`);
        count++;
      }
    });
  } catch (error) {
    console.error('Blad weryfikacji:', error.message);
  }

  console.log('\nUpload zakonczony!');
  console.log('Sprawdz w Firebase Console:');
  console.log('   https://console.firebase.google.com/project/metropolitan-investment/firestore/data/~2Fproducts');
}

// Obsluga argumentow i sygnalow
if (process.argv.includes('--force') || process.argv.includes('-f')) {
  console.log('UWAGA: Tryb --force wlaczony - istniejace produkty beda nadpisane!');
}

process.on('SIGINT', () => {
  console.log('\nUpload anulowany przez uzytkownika');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Nieobsluzone odrzucenie Promise:', reason);
  process.exit(1);
});

// Uruchom upload
uploadApartmentProducts().catch(console.error);

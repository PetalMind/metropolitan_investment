// Skrypt do wgrywania produktów apartamentowych do Firebase
// Wzorowany na upload_clients_with_uuid.js
// npm install firebase-admin

const fs = require('fs');
const admin = require('firebase-admin');

// Ścieżka do pliku z danymi produktów apartamentowych
const DATA_PATH = './apartment_products.json';

// Ścieżka do pliku z kluczem serwisowym Firebase
const SERVICE_ACCOUNT_PATH = './service-account.json';

// Nazwa kolekcji w Firestore
const COLLECTION_NAME = 'products';

// Inicjalizacja Firebase
admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

// Sprawdź czy produkt już istnieje w bazie
async function checkProductExists(productId, productName, companyName) {
  try {
    // Sprawdź po ID
    const docSnapshot = await db.collection(COLLECTION_NAME).doc(productId).get();
    if (docSnapshot.exists) {
      return { exists: true, reason: `ID już istnieje: ${productId}` };
    }

    // Sprawdź po nazwie + spółce + typie
    const querySnapshot = await db.collection(COLLECTION_NAME)
      .where('name', '==', productName)
      .where('companyName', '==', companyName)
      .where('type', '==', 'apartments')
      .get();

    if (!querySnapshot.empty) {
      const existingDoc = querySnapshot.docs[0];
      return {
        exists: true,
        reason: `Duplikat nazwy i spółki (istniejący ID: ${existingDoc.id})`
      };
    }

    return { exists: false };
  } catch (error) {
    console.error(`❌ Błąd sprawdzania produktu ${productName}:`, error.message);
    return { exists: false };
  }
}

async function uploadApartmentProducts() {
  console.log('🏠 APARTMENT PRODUCTS UPLOADER 🏠');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  // Sprawdź czy plik z produktami istnieje
  if (!fs.existsSync(DATA_PATH)) {
    console.error(`❌ Plik ${DATA_PATH} nie istnieje. Uruchom najpierw migrator:`);
    console.error('   dart run tools/apartment_products_migrator.dart');
    process.exit(1);
  }

  // Wczytaj produkty
  const products = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
  if (!Array.isArray(products)) {
    console.error('❌ Plik JSON powinien zawierać tablicę produktów.');
    process.exit(1);
  }

  console.log(`📊 Znaleziono ${products.length} produktów apartamentowych do uploadu`);

  // Sprawdź tryb działania
  const forceUpdate = process.argv.includes('--force') || process.argv.includes('-f');
  console.log(`📋 Tryb: ${forceUpdate ? 'FORCE (nadpisywanie)' : 'BEZPIECZNY (pomijanie duplikatów)'}`);

  // Statystyki
  let uploaded = 0;
  let skipped = 0;
  let updated = 0;
  let errors = 0;

  // Przetwórz każdy produkt
  for (let i = 0; i < products.length; i++) {
    const product = products[i];
    console.log(`
📦 [${i + 1}/${products.length}] Przetwarzam: uire('firebase-admin');
const fs = require('fs');
const path = require('path');

// Konfiguracja Firebase Admin (wzorowana na upload_clients_to_firebase.js)
const serviceAccount = {
  type: "service_account",
  project_id: "metropolitan-investment",
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL
};

class ApartmentProductsUploader {
  constructor() {
    this.db = null;
    this.uploadStats = {
      total: 0,
      uploaded: 0,
      skipped: 0,
      updated: 0,
      errors: 0,
      startTime: null,
      endTime: null
    };
  }

  async initialize() {
    try {
      console.log('🔥 Inicjalizacja Firebase Admin...');

      // Sprawdź czy mamy wszystkie wymagane zmienne środowiskowe
      const requiredVars = ['FIREBASE_PRIVATE_KEY', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_CLIENT_ID'];
      const missingVars = requiredVars.filter(varName => !process.env[varName]);

      if (missingVars.length > 0) {
        console.log('⚠️  Brakuje zmiennych środowiskowych:', missingVars.join(', '));
        console.log('Próbuję użyć pliku service-account.json...');

        // Spróbuj użyć pliku service account
        const serviceAccountPath = path.join(__dirname, 'service-account.json');
        if (fs.existsSync(serviceAccountPath)) {
          const serviceAccountFile = require(serviceAccountPath);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccountFile),
            projectId: serviceAccountFile.project_id
          });
        } else {
          throw new Error('Brak pliku service-account.json');
        }
      } else {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      }

      this.db = admin.firestore();
      console.log('✅ Firebase zainicjalizowany pomyślnie!');

      // Test połączenia
      await this.db.collection('test').limit(1).get();
      console.log('✅ Połączenie z Firestore potwierdzone!');

    } catch (error) {
      console.error('❌ Błąd inicjalizacji Firebase:', error.message);
      throw error;
    }
  }

  async checkExistingProducts() {
    try {
      console.log('🔍 Sprawdzanie istniejących produktów w bazie...');
      const snapshot = await this.db.collection('products').get();

      const existingProducts = new Map();
      snapshot.forEach(doc => {
        const data = doc.data();
        existingProducts.set(doc.id, {
          name: data.name,
          companyName: data.companyName,
          type: data.type
        });
      });

      console.log(`📊 Znaleziono ${ existingProducts.size } istniejących produktów w bazie`);
      return existingProducts;
    } catch (error) {
      console.error('❌ Błąd sprawdzania istniejących produktów:', error.message);
      return new Map();
    }
  } async loadApartmentProducts() {
    try {
      console.log('📄 Ładowanie produktów apartamentowych...');

      if (!fs.existsSync('apartment_products.json')) {
        throw new Error('Plik apartment_products.json nie istnieje. Uruchom najpierw migrator.');
      }

      const products = JSON.parse(fs.readFileSync('apartment_products.json', 'utf8'));
      console.log(`✅ Załadowano ${ products.length } produktów apartamentowych`);
      this.uploadStats.total = products.length;

      return products;
    } catch (error) {
      console.error('❌ Błąd ładowania produktów:', error.message);
      throw error;
    }
  }

  isProductDuplicate(product, existingProducts) {
    // Sprawdź po ID
    if (existingProducts.has(product.id)) {
      return { isDuplicate: true, reason: 'ID już istnieje' };
    }

    // Sprawdź po nazwie i spółce
    for (const [existingId, existingData] of existingProducts) {
      if (existingData.name === product.name &&
        existingData.companyName === product.companyName &&
        existingData.type === 'apartments') {
        return {
          isDuplicate: true,
          reason: `Duplikat nazwy i spółki(istniejący ID: ${ existingId })`
        };
      }
    }

    return { isDuplicate: false };
  }

  async uploadProducts(products, existingProducts, forceUpdate = false) {
    this.uploadStats.startTime = new Date();
    console.log(`\n🚀 Rozpoczynam upload produktów apartamentowych...`);
    console.log(`📋 Tryb: ${ forceUpdate? 'AKTUALIZACJA (nadpisywanie)': 'BEZPIECZNY (pomijanie duplikatów)' }`);

    for (let i = 0; i < products.length; i++) {
      const product = products[i];
      console.log(`\n📦[${ i + 1}/${products.length}]Przetwarzam: "${product.name}"`);

      try {
        // Sprawdź czy już istnieje
        const duplicateCheck = this.isProductDuplicate(product, existingProducts);

        if (duplicateCheck.isDuplicate && !forceUpdate) {
          console.log(`  ⏭️  POMINIĘTO - ${ duplicateCheck.reason } `);
          this.uploadStats.skipped++;
          continue;
        }

        // Przygotuj dane do zapisu
        const productId = product.id;
        const productData = { ...product };
        delete productData.id; // Usuń ID z danych

        // Dodaj metadane upload
        productData.uploaded_at = new Date().toISOString();
        productData.source_file = 'apartment_products.json';
        productData.migration_version = '2025_08_06';

        if (duplicateCheck.isDuplicate && forceUpdate) {
          productData.updated_at = new Date().toISOString();
          productData.update_reason = 'Force update from migration';
        }

        // Upload do Firestore używając Firebase Admin
        await this.db.collection('products').doc(productId).set(productData, { merge: true });

        if (duplicateCheck.isDuplicate) {
          console.log(`  🔄 ZAKTUALIZOWANO - ${ duplicateCheck.reason } `);
          this.uploadStats.updated++;
        } else {
          console.log(`  ✅ DODANO NOWY`);
          this.uploadStats.uploaded++;
        }

        // Dodaj do mapy istniejących
        existingProducts.set(productId, {
          name: product.name,
          companyName: product.companyName,
          type: product.type
        });

        // Krótka pauza między uploads
        await new Promise(resolve => setTimeout(resolve, 200));

      } catch (error) {
        console.error(`  ❌ BŁĄD: ${ error.message } `);
        this.uploadStats.errors++;
      }
    }

    this.uploadStats.endTime = new Date();
    this.printFinalStats();
  }

  async verifyUpload() {
    try {
      console.log('\n🔍 Weryfikacja uploadu...');

      // Sprawdź wszystkie produkty apartamentowe
      const snapshot = await this.db.collection('products').where('type', '==', 'apartments').get();

      console.log(`📊 Produktów apartamentowych w bazie: ${ snapshot.size } `);

      // Pokaż przykłady
      console.log('\n📋 Przykłady zapisanych produktów apartamentowych:');
      let count = 0;
      snapshot.forEach(doc => {
        if (count < 3) {
          const data = doc.data();
          const meta = data.metadata || {};
          console.log(`   - ${ data.name } (${ data.companyName })`);
          console.log(`     💰 ${ meta.totalAmount || 'N/A' } PLN, ${ meta.totalInvestments || 'N/A' } inwestycji`);
          count++;
        }
      });

    } catch (error) {
      console.error('❌ Błąd weryfikacji:', error.message);
    }
  }

  printFinalStats() {
    const duration = Math.round((this.uploadStats.endTime - this.uploadStats.startTime) / 1000);

    console.log('\n' + '='.repeat(70));
    console.log('🎯 PODSUMOWANIE UPLOADU PRODUKTÓW APARTAMENTOWYCH');
    console.log('='.repeat(70));
    console.log(`📊 Całkowity czas: ${ duration } s`);
    console.log(`📊 Produktów do sprawdzenia: ${ this.uploadStats.total }`);
    console.log(`✅ Nowych dodanych: ${ this.uploadStats.uploaded } `);
    console.log(`🔄 Zaktualizowanych: ${ this.uploadStats.updated } `);
    console.log(`⏭️  Pominiętych(duplikaty): ${ this.uploadStats.skipped } `);
    console.log(`❌ Błędów: ${ this.uploadStats.errors } `);

    const successRate = Math.round(((this.uploadStats.uploaded + this.uploadStats.updated) / this.uploadStats.total) * 100);
    console.log(`📈 Sukces: ${ successRate }% `);
    console.log('='.repeat(70));
  }
}

async function uploadApartmentProducts() {
  console.log('🏠 APARTMENT PRODUCTS UPLOADER 🏠');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  const uploader = new ApartmentProductsUploader();

  try {
    // 1. Inicjalizacja Firebase
    await uploader.initialize();

    // 2. Sprawdź istniejące produkty
    const existingProducts = await uploader.checkExistingProducts();

    // 3. Załaduj produkty apartamentowe do uploadu
    const products = await uploader.loadApartmentProducts();

    // 4. Pokaż plan działania
    console.log('\n📋 PLAN DZIAŁANIA:');
    console.log('  1. Sprawdzenie każdego produktu pod kątem duplikatów');
    console.log('  2. Dodanie tylko nowych produktów');
    console.log('  3. Pominięcie istniejących duplikatów');
    console.log('  4. Weryfikacja końcowa');

    // 5. Opcjonalne potwierdzenie
    console.log(`\n❓ Kontynuować upload ${ products.length } produktów apartamentowych ? `);
    console.log('   Naciśnij Ctrl+C aby anulować lub czekaj 3 sekundy...');
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 6. Upload produktów (tryb zależny od argumentów)
    const forceUpdate = process.argv.includes('--force') || process.argv.includes('-f');
    await uploader.uploadProducts(products, existingProducts, forceUpdate);

    // 7. Weryfikacja
    await uploader.verifyUpload();

    console.log('\n🎉 Upload zakończony pomyślnie!');
    console.log('🌐 Sprawdź w Firebase Console:');
    console.log('   https://console.firebase.google.com/project/metropolitan-investment/firestore/data/~2Fproducts');

  } catch (error) {
    console.error('\n💥 KRYTYCZNY BŁĄD:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Obsługa argumentów linii poleceń
const forceUpdate = process.argv.includes('--force') || process.argv.includes('-f');

if (forceUpdate) {
  console.log('⚠️  UWAGA: Tryb --force włączony - istniejące produkty będą nadpisane!');
}

// Obsługa sygnałów
process.on('SIGINT', () => {
  console.log('\n🛑 Upload anulowany przez użytkownika');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Nieobsłużone odrzucenie Promise:', reason);
  process.exit(1);
});

// Uruchom program
if (require.main === module) {
  uploadApartmentProducts();
}

module.exports = { ApartmentProductsUploader };

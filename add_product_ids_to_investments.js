const admin = require('firebase-admin');
const path = require('path');

// Inicjalizacja Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://metropolitan-investment-default-rtdb.europe-west1.firebasedatabase.app'
});

const db = admin.firestore();

/**
 * Mapa grup produktów - klucz deduplikacji -> pierwsza inwestycja
 * Używana do ustalenia productId zgodnie z logiką DeduplicatedProductService
 */
const productGroups = new Map();

/**
 * Funkcja do generowania klucza deduplikacji
 * Odpowiada logice z DeduplicatedProductService
 */
function createProductKey(productName, productType, companyId) {
  const normalizedName = productName.trim().toLowerCase();
  const normalizedType = productType.trim().toLowerCase();
  const normalizedCompany = companyId.trim().toLowerCase();

  return `${normalizedName}_${normalizedType}_${normalizedCompany}`;
}

/**
 * Funkcja do określenia productId zgodnie z logiką DeduplicatedProductService
 * 1. Używa ID pierwszej inwestycji w grupie (np. bond_0093)
 * 2. Fallback: hash klucza produktu
 */
function determineProductId(productKey, investmentId) {
  if (!productGroups.has(productKey)) {
    // To jest pierwsza inwestycja dla tego produktu
    productGroups.set(productKey, investmentId);
    return investmentId; // ⭐ UŻYWAMY ID PIERWSZEJ INWESTYCJI
  }

  // Dla kolejnych inwestycji tego samego produktu używamy ID pierwszej
  return productGroups.get(productKey);
}

/**
 * Główna funkcja migracji
 */
async function addProductIdsToInvestments() {
  console.log('🚀 Rozpoczynam migrację - dodawanie productId do inwestycji...');

  try {
    // Pobranie wszystkich inwestycji
    const investmentsSnapshot = await db.collection('investments').get();
    console.log(`📊 Znaleziono ${investmentsSnapshot.size} inwestycji do przetworzenia`);

    // KROK 1: Budowanie mapy produktów (ustalenie pierwszej inwestycji dla każdego produktu)
    console.log('🔍 Krok 1: Analiza struktury produktów...');
    const allInvestments = [];

    for (const doc of investmentsSnapshot.docs) {
      const data = doc.data();

      if (!data.productName || !data.productType || !data.companyId) {
        console.log(`⚠️  Pomijam ${doc.id} - brakuje wymaganych pól`);
        continue;
      }

      allInvestments.push({
        id: doc.id,
        docRef: doc.ref,
        data: data
      });

      const productKey = createProductKey(
        data.productName,
        data.productType,
        data.companyId
      );

      // Określenie productId dla tej grupy produktów
      determineProductId(productKey, data.id);
    }

    console.log(`📦 Znaleziono ${productGroups.size} unikalnych produktów`);

    // KROK 2: Aktualizacja dokumentów
    console.log('🔄 Krok 2: Aktualizacja dokumentów...');
    const batch = db.batch();
    let processedCount = 0;
    let skippedCount = 0;
    let updatedCount = 0;

    for (const investment of allInvestments) {
      const { id, docRef, data } = investment;
      processedCount++;

      // Sprawdzenie czy już ma productId
      if (data.productId && data.productId !== null && data.productId !== '') {
        console.log(`⏭️  Pomijam ${id} - już ma productId: ${data.productId}`);
        skippedCount++;
        continue;
      }

      // Określenie productId na podstawie grupy produktów
      const productKey = createProductKey(
        data.productName,
        data.productType,
        data.companyId
      );

      const productId = productGroups.get(productKey);

      if (!productId) {
        console.log(`⚠️  Brak productId dla: ${id}`);
        skippedCount++;
        continue;
      }

      // Dodanie do batch
      batch.update(docRef, { productId });
      updatedCount++;

      const isFirstInvestment = productId === data.id;
      console.log(`${isFirstInvestment ? '🌟' : '✅'} ${id}: ${data.productName} -> productId: ${productId}${isFirstInvestment ? ' (PIERWSZA)' : ''}`);

      // Firebase batch ma limit 500 operacji
      if (updatedCount % 450 === 0) {
        console.log(`📦 Wykonuję batch ${Math.ceil(updatedCount / 450)} (${updatedCount} aktualizacji)...`);
        await batch.commit();
        // Utworzenie nowego batch
        const newBatch = db.batch();
        Object.assign(batch, newBatch);
      }
    }

    // Ostatni batch
    if (updatedCount % 450 !== 0) {
      console.log(`📦 Wykonuję ostatni batch...`);
      await batch.commit();
    }

    console.log('\n🎉 Migracja zakończona pomyślnie!');
    console.log(`📊 Statystyki:`);
    console.log(`   - Przetworzono: ${processedCount} dokumentów`);
    console.log(`   - Zaktualizowano: ${updatedCount} dokumentów`);
    console.log(`   - Pominięto: ${skippedCount} dokumentów`);
    console.log(`   - Unikalnych produktów: ${productGroups.size}`);

  } catch (error) {
    console.error('❌ Błąd podczas migracji:', error);
    throw error;
  }
}

/**
 * Funkcja walidacyjna - sprawdzenie efektów migracji
 */
async function validateMigration() {
  console.log('\n🔍 Sprawdzam efekty migracji...');

  try {
    const investmentsSnapshot = await db.collection('investments').get();

    let withProductId = 0;
    let withoutProductId = 0;
    const productIdCounts = {};

    for (const doc of investmentsSnapshot.docs) {
      const data = doc.data();

      if (data.productId && data.productId !== null && data.productId !== '') {
        withProductId++;

        // Zliczanie produktów
        if (productIdCounts[data.productId]) {
          productIdCounts[data.productId]++;
        } else {
          productIdCounts[data.productId] = 1;
        }
      } else {
        withoutProductId++;
        console.log(`❌ Brak productId w: ${doc.id} (${data.productName})`);
      }
    }

    console.log(`✅ Z productId: ${withProductId}`);
    console.log(`❌ Bez productId: ${withoutProductId}`);
    console.log(`📊 Unique produktów: ${Object.keys(productIdCounts).length}`);

    // Top 10 produktów z największą liczbą inwestycji
    const topProducts = Object.entries(productIdCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10);

    console.log('\n🏆 Top 10 produktów z największą liczbą inwestycji:');
    for (const [productId, count] of topProducts) {
      // Znajdź nazwę produktu
      const sampleDoc = await db.collection('investments')
        .where('productId', '==', productId)
        .limit(1)
        .get();

      const productName = sampleDoc.docs[0]?.data()?.productName || 'Nieznana nazwa';
      console.log(`   ${productId}: ${count} inwestycji (${productName})`);
    }

  } catch (error) {
    console.error('❌ Błąd podczas walidacji:', error);
  }
}

// Uruchomienie skryptu
async function main() {
  try {
    await addProductIdsToInvestments();
    await validateMigration();

    console.log('\n✅ Wszystko zakończone pomyślnie!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Krytyczny błąd:', error);
    process.exit(1);
  }
}

// Sprawdzenie argumentów CLI
const args = process.argv.slice(2);
if (args.includes('--validate-only')) {
  console.log('🔍 Tryb walidacji - tylko sprawdzanie danych...');
  validateMigration().then(() => process.exit(0));
} else if (args.includes('--help')) {
  console.log(`
🔧 Skrypt migracji productId dla kolekcji investments

Użycie:
  node add_product_ids_to_investments.js           # Pełna migracja
  node add_product_ids_to_investments.js --validate-only   # Tylko walidacja
  node add_product_ids_to_investments.js --help            # Ta pomoc

⚠️  UWAGA: Przed uruchomieniem upewnij się, że:
1. Masz poprawną ścieżkę do service-account-key.json
2. Masz backup bazy danych
3. Testowałeś na środowisku deweloperskim

🔥 Skrypt aktualizuje kolekcję 'investments' dodając pole 'productId'
   na podstawie kombinacji: productName + productType + companyId
  `);
  process.exit(0);
} else {
  main();
}

// 🧪 Test funkcji getAllProductsWithInvestors z statusami głosowania
// Sprawdza czy nowa funkcja zwraca statusy głosowania inwestorów

const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Inicjalizuj Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'metropolitan-investment-default'
  });
}

// Import z functions
const { getAllProductsWithInvestors } = require('./functions/services/product-batch-service');

async function testVotingInProducts() {
  console.log('🧪 === TEST STATUSÓW GŁOSOWANIA W PRODUKTACH ===');
  console.log();

  try {
    // Test wywołania funkcji z małą liczbą produktów
    console.log('1️⃣ Testowanie funkcji getAllProductsWithInvestors...');

    const request = {
      data: {
        forceRefresh: true,
        includeStatistics: false,
        maxProducts: 5
      }
    };

    const result = await getAllProductsWithInvestors(request);

    console.log('✅ Funkcja zakończona pomyślnie');
    console.log(`📊 Produkty: ${result.products.length}`);

    // Sprawdź czy produkty mają inwestorów z statusami głosowania
    let foundVotingStatus = false;

    for (const product of result.products) {
      console.log(`\n📦 Produkt: ${product.name}`);
      console.log(`👥 Inwestorów: ${product.topInvestors.length}`);

      for (const investor of product.topInvestors) {
        if (investor.votingStatus) {
          console.log(`  ✅ ${investor.clientName}: ${investor.votingStatus}`);
          foundVotingStatus = true;
        } else {
          console.log(`  ⚠️ ${investor.clientName}: brak statusu głosowania`);
        }
      }
    }

    if (foundVotingStatus) {
      console.log('\n🎉 SUCCESS: Statusy głosowania są dostępne w danych produktów!');
    } else {
      console.log('\n❌ PROBLEM: Nie znaleziono statusów głosowania w danych');
    }

  } catch (error) {
    console.error('❌ Błąd testu:', error);
  }
}

// Uruchom test
testVotingInProducts()
  .then(() => {
    console.log('\n🏁 Test zakończony');
    process.exit(0);
  })
  .catch(error => {
    console.error('💥 Test failed:', error);
    process.exit(1);
  });

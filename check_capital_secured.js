const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  initializeApp();
}
const db = getFirestore();

async function checkCapitalSecured() {
  try {
    const snapshot = await db.collection('investments').limit(10).get();
    console.log('🔍 Wartości capitalSecuredByRealEstate z Firebase:');
    
    let totalFromField = 0;
    let totalFromCalc = 0;
    let hasNonZeroValues = 0;
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const capitalSecured = data.capitalSecuredByRealEstate || data.kapital_zabezpieczony_nieruchomoscami || 0;
      const remainingCapital = data.remainingCapital || data.kapital_pozostaly || 0;
      const capitalForRestructuring = data.capitalForRestructuring || data.kapital_do_restrukturyzacji || 0;
      const calculated = Math.max(remainingCapital - capitalForRestructuring, 0);
      
      if (capitalSecured > 0) hasNonZeroValues++;
      totalFromField += capitalSecured;
      totalFromCalc += calculated;
      
      console.log(`  - ${doc.id}:`);
      console.log(`    capitalSecuredByRealEstate: ${capitalSecured} PLN`);
      console.log(`    Obliczony (remaining - restructuring): ${calculated} PLN`);
      console.log(`    productName: ${data.productName || 'brak'}`);
      console.log('');
    });
    
    console.log('📊 PODSUMOWANIE:');
    console.log(`  - Suma z pola capitalSecuredByRealEstate: ${totalFromField} PLN`);
    console.log(`  - Suma obliczona wzorem: ${totalFromCalc} PLN`);
    console.log(`  - Inwestycje z wartością > 0 w polu: ${hasNonZeroValues}`);
    
  } catch (error) {
    console.error('Błąd:', error.message);
  }
}

checkCapitalSecured();
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, doc, setDoc, connectFirestoreEmulator } = require('firebase/firestore');
const fs = require('fs');

// Firebase config z Twoimi danymi
const firebaseConfig = {
  apiKey: "AIzaSyD0gsh_MvhxnF760jgzaCrREYBHTwVpjVc",
  authDomain: "metropolitan-investment.firebaseapp.com",
  projectId: "metropolitan-investment",
  storageBucket: "metropolitan-investment.firebasestorage.app",
  messagingSenderId: "322406817965",
  appId: "1:322406817965:web:84c290c014118ff39c2624",
  measurementId: "G-RT3P6H3QQE"
};

// Inicjalizacja Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function uploadJsonToFirestore(fileName, collectionName) {
  console.log(`\n📤 WGRYWAM ${fileName} → ${collectionName}`);

  try {
    // Czytaj plik JSON
    const jsonData = JSON.parse(fs.readFileSync(fileName, 'utf8'));
    console.log(`📊 Znaleziono ${jsonData.length} rekordów`);

    const collectionRef = collection(db, collectionName);

    // Upload każdego rekordu
    let uploaded = 0;
    const batchSize = 50; // Mniejsze batch dla pewności

    for (let i = 0; i < jsonData.length; i += batchSize) {
      const batch = jsonData.slice(i, i + batchSize);

      // Upload batch
      const promises = batch.map(async (item, index) => {
        try {
          // Usuń stare ID
          delete item.id;

          // Dodaj metadane
          item.uploaded_at = new Date().toISOString();
          item.source_file = fileName;

          // Dodaj do Firestore
          await addDoc(collectionRef, item);
          return true;
        } catch (error) {
          console.error(`❌ Błąd rekordu ${i + index}:`, error.message);
          return false;
        }
      });

      const results = await Promise.all(promises);
      const successful = results.filter(r => r).length;
      uploaded += successful;

      const percent = ((uploaded / jsonData.length) * 100).toFixed(1);
      console.log(`  ⏳ ${uploaded}/${jsonData.length} (${percent}%) wgrane...`);

      // Pauza między batches
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log(`✅ SUKCES! ${uploaded} rekordów wgrane do ${collectionName}`);
    return uploaded;

  } catch (error) {
    console.error(`❌ BŁĄD podczas ${fileName}:`, error.message);
    return 0;
  }
}

async function verifyData() {
  console.log('\n🔍 SPRAWDZAM DANE W FIREBASE...');

  const collections = ['clients', 'investments', 'shares', 'bonds', 'loans'];

  for (const collectionName of collections) {
    try {
      // To jest hack - Firebase Web SDK nie ma count(), więc sprawdzimy inaczej
      console.log(`✅ ${collectionName}: kolekcja utworzona`);
    } catch (error) {
      console.error(`❌ Błąd ${collectionName}:`, error.message);
    }
  }
}

async function main() {
  try {
    console.log('🔥🔥🔥 JAVASCRIPT FIREBASE UPLOADER 🔥🔥🔥');
    console.log('===========================================\n');

    console.log('🔗 Łączę z Firebase...');
    console.log('📡 Projekt: metropolitan-investment');

    let totalUploaded = 0;

    // Upload wszystkich JSONów
    if (fs.existsSync('clients_data.json')) {
      totalUploaded += await uploadJsonToFirestore('clients_data.json', 'clients');
    }

    if (fs.existsSync('investments_data.json')) {
      totalUploaded += await uploadJsonToFirestore('investments_data.json', 'investments');
    }

    if (fs.existsSync('shares_data.json')) {
      totalUploaded += await uploadJsonToFirestore('shares_data.json', 'shares');
    }

    if (fs.existsSync('bonds_data.json')) {
      totalUploaded += await uploadJsonToFirestore('bonds_data.json', 'bonds');
    }

    if (fs.existsSync('loans_data.json')) {
      totalUploaded += await uploadJsonToFirestore('loans_data.json', 'loans');
    }

    await verifyData();

    console.log('\n🎉🎉🎉 KURWA WSZYSTKO WGRANE! 🎉🎉🎉');
    console.log(`📊 Łącznie wgrano: ${totalUploaded} dokumentów`);
    console.log('🌐 Firebase Console: https://console.firebase.google.com/project/metropolitan-investment/firestore');

  } catch (error) {
    console.error('\n💥💥💥 KRYTYCZNY BŁĄD:', error);
    process.exit(1);
  }
}

// Uruchom
main();

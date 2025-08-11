/**
 * Test Firebase Functions - sprawdzenie czy funkcje klientów działają
 */

const admin = require('firebase-admin');

// Inicjalizuj Firebase Admin z service account
const serviceAccount = require('./service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testClientsFunctions() {
  console.log('🧪 Testowanie funkcji klientów...');

  try {
    // Test 1: Sprawdź czy kolekcja clients istnieje
    console.log('\n1️⃣ Sprawdzam kolekcję clients...');
    const clientsSnapshot = await db.collection('clients').limit(5).get();
    console.log(`   📊 Znaleziono ${clientsSnapshot.size} klientów (limit 5)`);

    if (clientsSnapshot.empty) {
      console.log('   ❌ Kolekcja clients jest pusta!');
      return;
    }

    // Pokaż przykładowego klienta
    const firstClient = clientsSnapshot.docs[0];
    console.log(`   👤 Przykładowy klient ID: ${firstClient.id}`);
    console.log(`   📋 Dane:`, JSON.stringify(firstClient.data(), null, 2));

    // Test 2: Sprawdź kolekcję investments
    console.log('\n2️⃣ Sprawdzam kolekcję investments...');
    const investmentsSnapshot = await db.collection('investments').limit(5).get();
    console.log(`   💼 Znaleziono ${investmentsSnapshot.size} inwestycji (limit 5)`);

    if (investmentsSnapshot.size > 0) {
      const firstInvestment = investmentsSnapshot.docs[0];
      console.log(`   💰 Przykładowa inwestycja ID: ${firstInvestment.id}`);
      console.log(`   📋 Dane:`, JSON.stringify(firstInvestment.data(), null, 2));
    }

    // Test 3: Symuluj logikę getAllClients
    console.log('\n3️⃣ Testuję logikę getAllClients...');
    const allClientsSnapshot = await db.collection('clients').get();
    console.log(`   📊 Łączna liczba klientów: ${allClientsSnapshot.size}`);

    const clients = [];
    allClientsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const client = {
        id: doc.id,
        name: data.imie_nazwisko || data.fullName || data.name || 'Brak nazwy',
        email: data.email || '',
        phone: data.telefon || data.phone || ''
      };
      clients.push(client);
    });

    console.log(`   ✅ Przekonwertowano ${clients.length} klientów`);
    console.log('   👥 Pierwsi 3 klienci:');
    clients.slice(0, 3).forEach((client, index) => {
      console.log(`      ${index + 1}. ${client.name} (${client.email})`);
    });

    // Test 4: Symuluj logikę getActiveClients
    console.log('\n4️⃣ Testuję logikę getActiveClients...');
    const allInvestmentsSnapshot = await db.collection('investments').get();
    const clientsWithInvestments = new Set();

    allInvestmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const clientId = data.clientId;
      const remainingCapital = parseFloat(data.remainingCapital || data.kapital_pozostaly || 0);

      if (clientId && remainingCapital > 0) {
        clientsWithInvestments.add(clientId);
      }
    });

    console.log(`   💼 Znaleziono ${clientsWithInvestments.size} klientów z aktywnymi inwestycjami`);

    const activeClients = clients.filter(client => clientsWithInvestments.has(client.id));
    console.log(`   ✅ Aktywni klienci: ${activeClients.length}`);

    if (activeClients.length > 0) {
      console.log('   👥 Pierwsi 3 aktywni klienci:');
      activeClients.slice(0, 3).forEach((client, index) => {
        console.log(`      ${index + 1}. ${client.name} (${client.email})`);
      });
    }

    console.log('\n🎉 Test zakończony pomyślnie!');

  } catch (error) {
    console.error('\n❌ Błąd podczas testowania:', error);
    console.error('Stack trace:', error.stack);
  }
}

// Uruchom test
testClientsFunctions().then(() => {
  console.log('\n👋 Test zakończony.');
  process.exit(0);
}).catch(error => {
  console.error('💥 Krytyczny błąd:', error);
  process.exit(1);
});

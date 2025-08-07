// Test połączenia z Firebase - bez uploadu danych
const { FirebaseClientUploader } = require('./upload_clients_to_firebase.js');

async function testConnection() {
  console.log('🧪 TEST POŁĄCZENIA Z FIREBASE');
  console.log('='.repeat(40));

  const uploader = new FirebaseClientUploader();

  try {
    // Test inicjalizacji
    await uploader.initialize();
    console.log('✅ Inicjalizacja przeszła pomyślnie!');

    // Test sprawdzenia istniejących klientów
    const existingCount = await uploader.checkExistingClients();
    console.log(`✅ Sprawdzenie istniejących klientów przeszło pomyślnie! (${existingCount} klientów)`);

    console.log('\n🎉 Test połączenia zakończony SUKCESEM!');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ Test połączenia NIEPOWODZENIE:', error.message);
    process.exit(1);
  }
}

testConnection();

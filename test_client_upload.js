#!/usr/bin/env node
/**
 * Prosty skrypt testowy do uploadu klientów do Firebase
 */

const { uploadAllClients, testFirebaseConnection } = require('./upload_clients_to_firebase.js');

async function runTest() {
  console.log('🧪 Uruchamianie testu uploadu klientów...');

  try {
    // Test połączenia
    console.log('\n1️⃣ Test połączenia z Firebase...');
    const connected = await testFirebaseConnection();

    if (!connected) {
      console.error('❌ Błąd połączenia z Firebase');
      return;
    }

    // Dry run - symulacja uploadu
    console.log('\n2️⃣ Symulacja uploadu (dry run)...');
    await uploadAllClients({
      dryRun: true,
      batchSize: 10
    });

    console.log('\n✅ Test zakończony pomyślnie!');
    console.log('\n📝 Aby wykonać prawdziwy upload:');
    console.log('   node upload_clients_to_firebase.js');
    console.log('\n📝 Aby nadpisać istniejące dane:');
    console.log('   node upload_clients_to_firebase.js --overwrite');

  } catch (error) {
    console.error('❌ Błąd podczas testu:', error);
  }
}

runTest();

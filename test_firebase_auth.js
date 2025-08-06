// Test prostej autoryzacji Firebase
const admin = require('firebase-admin');

console.log('Test autoryzacji Firebase...');

try {
  // Inicjalizacja Firebase
  admin.initializeApp({
    credential: admin.credential.cert(require('./service-account.json')),
  });

  const db = admin.firestore();
  console.log('Firebase zainicjalizowany');

  // Test prostego zapytania
  db.collection('test').limit(1).get()
    .then(() => {
      console.log('SUKCES: Polaczenie z Firebase dziala!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('BLAD autoryzacji:', error.message);

      if (error.message.includes('UNAUTHENTICATED')) {
        console.log('\nMozliwe przyczyny:');
        console.log('1. Nieprawidlowy plik service-account.json');
        console.log('2. Brak uprawnien dla service account');
        console.log('3. Nieprawidlowy project_id');
        console.log('4. Service account nie ma dostepu do Firestore');
      }

      process.exit(1);
    });

} catch (error) {
  console.error('BLAD inicjalizacji:', error.message);
  process.exit(1);
}

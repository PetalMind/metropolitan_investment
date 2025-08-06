const admin = require('firebase-admin');
const path = require('path');

async function testFirebase() {
  try {
    console.log('Testing Firebase Admin...');

    const serviceAccountPath = path.join(__dirname, 'service-account.json');
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });

    const db = admin.firestore();
    console.log('Firebase initialized successfully!');

    // Simple test
    const testDoc = await db.collection('test').limit(1).get();
    console.log('Connection test successful!');

  } catch (error) {
    console.error('Error:', error.message);
  }
}

testFirebase();

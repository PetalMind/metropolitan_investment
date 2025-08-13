const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://metropolitan-investment-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function analyzeFirestoreState() {
  try {

    // Check clients collection
    const clientsSnapshot = await db.collection('clients').get();

    // Sample document IDs to see pattern
    const clientIds = [];
    clientsSnapshot.forEach(doc => {
      clientIds.push(doc.id);
    });

    clientIds.slice(0, 20).forEach(id => console.log(`   - ${id}`));

    clientIds.slice(-20).forEach(id => console.log(`   - ${id}`));

    // Check for specific patterns
    const numericIds = clientIds.filter(id => /^\d+$/.test(id));
    const uuidIds = clientIds.filter(id => /^[a-f0-9\-]{36}$/.test(id));
    const otherIds = clientIds.filter(id => !/^\d+$/.test(id) && !/^[a-f0-9\-]{36}$/.test(id));

    // Check ID ranges for numeric IDs
    if (numericIds.length > 0) {
      const numericValues = numericIds.map(id => parseInt(id)).sort((a, b) => a - b);

      // Check for gaps
      const gaps = [];
      for (let i = 1; i < numericValues.length; i++) {
        if (numericValues[i] - numericValues[i - 1] > 1) {
          gaps.push(`${numericValues[i - 1]}-${numericValues[i]}`);
        }
      }

      if (gaps.length > 0) {
        console.log(`   - First few gaps: ${gaps.slice(0, 10).join(', ')}`);
      }
    }

    // Check other collections
    const collections = ['investments', 'products', 'employees', 'companies'];
    for (const collectionName of collections) {
      try {
        const snapshot = await db.collection(collectionName).get();
      } catch (error) {
        console.log(`❌ ${collectionName} collection: Error (${error.message})`);
      }
    }

    // Check for any constraints or issues
    console.log(`   - Project ID: ${admin.app().options.projectId || 'default'}`);

  } catch (error) {
  }
}

analyzeFirestoreState().then(() => process.exit(0)).catch(console.error);

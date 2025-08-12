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
    console.log('🔍 Analyzing current Firestore state...\n');

    // Check clients collection
    const clientsSnapshot = await db.collection('clients').get();
    console.log(`📊 Clients collection: ${clientsSnapshot.size} documents`);

    // Sample document IDs to see pattern
    const clientIds = [];
    clientsSnapshot.forEach(doc => {
      clientIds.push(doc.id);
    });

    console.log(`📋 First 20 client IDs:`);
    clientIds.slice(0, 20).forEach(id => console.log(`   - ${id}`));

    console.log(`📋 Last 20 client IDs:`);
    clientIds.slice(-20).forEach(id => console.log(`   - ${id}`));

    // Check for specific patterns
    const numericIds = clientIds.filter(id => /^\d+$/.test(id));
    const uuidIds = clientIds.filter(id => /^[a-f0-9\-]{36}$/.test(id));
    const otherIds = clientIds.filter(id => !/^\d+$/.test(id) && !/^[a-f0-9\-]{36}$/.test(id));

    console.log(`\n📊 ID Patterns:`);
    console.log(`   - Numeric IDs: ${numericIds.length}`);
    console.log(`   - UUID IDs: ${uuidIds.length}`);
    console.log(`   - Other IDs: ${otherIds.length}`);

    // Check ID ranges for numeric IDs
    if (numericIds.length > 0) {
      const numericValues = numericIds.map(id => parseInt(id)).sort((a, b) => a - b);
      console.log(`\n📈 Numeric ID range:`);
      console.log(`   - Min: ${numericValues[0]}`);
      console.log(`   - Max: ${numericValues[numericValues.length - 1]}`);
      console.log(`   - Count: ${numericValues.length}`);

      // Check for gaps
      const gaps = [];
      for (let i = 1; i < numericValues.length; i++) {
        if (numericValues[i] - numericValues[i - 1] > 1) {
          gaps.push(`${numericValues[i - 1]}-${numericValues[i]}`);
        }
      }

      if (gaps.length > 0) {
        console.log(`   - Gaps found: ${gaps.length}`);
        console.log(`   - First few gaps: ${gaps.slice(0, 10).join(', ')}`);
      }
    }

    // Check other collections
    const collections = ['investments', 'products', 'employees', 'companies'];
    for (const collectionName of collections) {
      try {
        const snapshot = await db.collection(collectionName).get();
        console.log(`📊 ${collectionName} collection: ${snapshot.size} documents`);
      } catch (error) {
        console.log(`❌ ${collectionName} collection: Error (${error.message})`);
      }
    }

    // Check for any constraints or issues
    console.log(`\n🔍 Database info:`);
    console.log(`   - Project ID: ${admin.app().options.projectId || 'default'}`);
    console.log(`   - Total collections checked: ${collections.length + 1}`);

  } catch (error) {
    console.error('❌ Analysis error:', error);
  }
}

analyzeFirestoreState().then(() => process.exit(0)).catch(console.error);

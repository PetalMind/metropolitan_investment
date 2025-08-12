const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://metropolitan-investment-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function testSmallBatch() {
  try {
    console.log('🧪 Testing small batch upload...');

    // Load a small sample of data
    const jsonPath = path.join(__dirname, 'clients_extracted_updated.json');
    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const clientsData = JSON.parse(rawData);

    // Take only 10 clients from the end (likely to be missing)
    const testClients = clientsData.slice(900, 910);
    console.log(`📊 Testing with ${testClients.length} clients from end of file`);

    // Check current collection size
    let beforeSnapshot = await db.collection('clients').get();
    console.log(`📋 Before upload: ${beforeSnapshot.size} documents`);

    // Upload with individual document sets (not batch)
    for (let i = 0; i < testClients.length; i++) {
      const client = testClients[i];

      if (!client || !client.excelId) {
        console.log(`⚠️ Skipping invalid client at index ${i}`);
        continue;
      }

      try {
        const docRef = db.collection('clients').doc(`test_${client.excelId}`);
        const convertedData = {
          fullName: client.fullName || client.name || '',
          name: client.fullName || client.name || '',
          email: (client.email && client.email !== 'brak') ? client.email : '',
          phone: client.phone || '',
          address: client.address || '',
          type: client.type || 'individual',
          isActive: true,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
          testUpload: true,
          originalExcelId: client.excelId
        };

        await docRef.set(convertedData);
        console.log(`✅ Uploaded test client ${client.excelId}`);

        // Check if document exists immediately after
        const checkDoc = await docRef.get();
        console.log(`   - Verification: ${checkDoc.exists ? 'EXISTS' : 'MISSING'}`);

      } catch (error) {
        console.error(`❌ Error uploading client ${client.excelId}:`, error.message);
      }
    }

    // Check final collection size
    let afterSnapshot = await db.collection('clients').get();
    console.log(`📋 After upload: ${afterSnapshot.size} documents`);
    console.log(`📈 Added: ${afterSnapshot.size - beforeSnapshot.size} documents`);

    // List test documents
    console.log('\n🔍 Checking test documents...');
    const testDocs = await db.collection('clients').where('testUpload', '==', true).get();
    console.log(`📋 Found ${testDocs.size} test documents`);

    testDocs.forEach(doc => {
      const data = doc.data();
      console.log(`   - ${doc.id}: ${data.fullName} (original: ${data.originalExcelId})`);
    });

  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

async function cleanupTestDocs() {
  console.log('🧹 Cleaning up test documents...');
  const testDocs = await db.collection('clients').where('testUpload', '==', true).get();

  const batch = db.batch();
  testDocs.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`✅ Deleted ${testDocs.size} test documents`);
}

// Run test
async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--cleanup')) {
    await cleanupTestDocs();
  } else {
    await testSmallBatch();
  }

  process.exit(0);
}

main().catch(console.error);

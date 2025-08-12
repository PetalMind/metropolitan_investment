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

// Function to parse dates
function parseDate(dateString) {
  if (!dateString) return admin.firestore.Timestamp.now();

  try {
    const date = new Date(dateString);
    return admin.firestore.Timestamp.fromDate(date);
  } catch (error) {
    console.log(`⚠️ Date parsing error "${dateString}": ${error.message}`);
    return admin.firestore.Timestamp.now();
  }
}

// Function to map client type
function mapClientType(type) {
  const typeMapping = {
    'individual': 'individual',
    'marriage': 'marriage',
    'company': 'company',
    'other': 'other'
  };
  return typeMapping[type] || 'individual';
}

// Function to map voting status
function mapVotingStatus(status) {
  const statusMapping = {
    'undecided': 'undecided',
    'yes': 'yes',
    'no': 'no',
    'abstain': 'abstain'
  };
  return statusMapping[status] || 'undecided';
}

// Funkcja do konwersji danych klienta zgodnie ze strukturą Client.dart
function convertClientData(client) {
  return {
    // Structure matching Client.dart toFirestore()
    fullName: client.fullName || client.name || '',
    name: client.fullName || client.name || '',
    imie_nazwisko: client.fullName || client.name || '', // Legacy compatibility

    excelId: client.excelId?.toString() || client.id?.toString() || '',
    original_id: client.excelId?.toString() || client.id?.toString() || '', // Legacy compatibility

    email: (client.email && client.email !== 'brak') ? client.email : '',

    phone: client.phone || '',
    telefon: client.phone || '', // Legacy compatibility

    address: client.address || '',
    pesel: client.pesel || null,

    companyName: client.companyName || null,
    nazwa_firmy: client.companyName || '', // Legacy compatibility

    type: mapClientType(client.type),
    notes: client.notes || '',
    votingStatus: mapVotingStatus(client.votingStatus),
    colorCode: client.colorCode || '#FFFFFF',
    unviableInvestments: client.unviableInvestments || [],

    // Dates - conversion to Timestamp (matching Client.dart)
    createdAt: parseDate(client.createdAt),
    updatedAt: parseDate(client.updatedAt),
    created_at: client.createdAt || new Date().toISOString(), // Legacy compatibility
    uploaded_at: client.updatedAt || new Date().toISOString(), // Legacy compatibility
    uploadedAt: client.updatedAt || new Date().toISOString(), // Normalized name

    isActive: client.isActive !== false, // Default true

    additionalInfo: client.additionalInfo || {},

    // Source fields for compatibility
    sourceFile: client.additionalInfo?.sourceFile || client.additionalInfo?.source_file || 'normalized_json',
    source_file: client.additionalInfo?.sourceFile || client.additionalInfo?.source_file || 'normalized_json'
  };
}

async function uploadClientsToFirestore() {
  try {
    console.log('🚀 Starting client upload to Firestore...');

    // Load data from JSON file with complete client data
    const jsonPath = path.join(__dirname, 'clients_extracted_updated.json');

    if (!fs.existsSync(jsonPath)) {
      throw new Error(`File not found: ${jsonPath}`);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const clientsData = JSON.parse(rawData);

    console.log(`📊 Found ${clientsData.length} clients to upload`);

    const batch = db.batch();
    let processedCount = 0;
    let errorCount = 0;
    const batchSize = 500; // Firestore batch limit

    for (let i = 0; i < clientsData.length; i++) {
      const client = clientsData[i];

      // Skip empty objects
      if (!client || !client.excelId) {
        console.log(`⚠️ Skipping empty object or missing excelId at index ${i}`);
        continue;
      }

      try {
        // Use excelId as document ID in Firestore
        const docRef = db.collection('clients').doc(client.excelId.toString());
        const convertedData = convertClientData(client);

        batch.set(docRef, convertedData, { merge: true });
        processedCount++;

        // Execute batch every batchSize operations or at the end
        if (processedCount % batchSize === 0 || i === clientsData.length - 1) {
          await batch.commit();
          console.log(`✅ Uploaded ${processedCount} clients (batch ${Math.ceil(processedCount / batchSize)})`);

          // Create new batch for next operations
          if (i < clientsData.length - 1) {
            const newBatch = db.batch();
            Object.assign(batch, newBatch);
          }
        }

        // Progress indicator
        if (processedCount % 100 === 0) {
          console.log(`📈 Processed ${processedCount}/${clientsData.length} clients`);
        }

      } catch (error) {
        errorCount++;
        console.error(`❌ Error processing client ${client.excelId}:`, error.message);

        // Continue with next client
        continue;
      }
    }

    console.log('\n🎉 Upload completed!');
    console.log(`✅ Successfully uploaded: ${processedCount} clients`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log(`📊 Total records: ${clientsData.length}`);

    // Check number of documents in collection
    const snapshot = await db.collection('clients').get();
    console.log(`📋 Documents in 'clients' collection: ${snapshot.size}`);

    // Final data verification
    console.log('\n🔍 Final verification - checking uploaded data...');
    const sampleDocs = await db.collection('clients').limit(3).get();
    let emailCount = 0, phoneCount = 0;

    sampleDocs.forEach(doc => {
      const data = doc.data();
      if (data.email && data.email.trim() !== '') emailCount++;
      if (data.phone && data.phone.trim() !== '') phoneCount++;
    });

    console.log(`Sample check: ${emailCount}/3 have email, ${phoneCount}/3 have phone`);

  } catch (error) {
    console.error('❌ Main application error:', error);
    process.exit(1);
  }
}

// Function to verify data before upload
async function verifyData() {
  try {
    const jsonPath = path.join(__dirname, 'clients_extracted_updated.json');
    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const clientsData = JSON.parse(rawData);

    console.log('🔍 Data verification...');
    console.log(`Total records: ${clientsData.length}`);

    const validClients = clientsData.filter(client => client && client.excelId);
    console.log(`Valid records with excelId: ${validClients.length}`);

    const uniqueExcelIds = new Set(validClients.map(c => c.excelId));
    console.log(`Unique excelIds: ${uniqueExcelIds.size}`);

    if (validClients.length !== uniqueExcelIds.size) {
      console.log('⚠️ WARNING: Found duplicate excelIds!');

      // Find duplicates
      const excelIdCounts = {};
      validClients.forEach(client => {
        excelIdCounts[client.excelId] = (excelIdCounts[client.excelId] || 0) + 1;
      });

      const duplicates = Object.entries(excelIdCounts).filter(([id, count]) => count > 1);
      console.log('Duplicates:', duplicates);
    }

    // Sample record
    console.log('\n📋 Sample converted record:');
    if (validClients.length > 0) {
      const example = convertClientData(validClients[0]);
      console.log(JSON.stringify(example, null, 2));
    }

    // Check data completeness
    const withEmail = validClients.filter(c => c.email && c.email !== 'brak').length;
    const withPhone = validClients.filter(c => c.phone && c.phone.trim() !== '').length;

    console.log(`\n📊 Data completeness:`);
    console.log(`Clients with email: ${withEmail}/${validClients.length} (${Math.round(withEmail / validClients.length * 100)}%)`);
    console.log(`Clients with phone: ${withPhone}/${validClients.length} (${Math.round(withPhone / validClients.length * 100)}%)`);

  } catch (error) {
    console.error('❌ Verification error:', error);
  }
}

// Główna funkcja
async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--verify')) {
    await verifyData();
    return;
  }

  if (args.includes('--help')) {
    console.log(`
📖 Usage:
  node upload_clients_from_normalized_json.js           - Upload data to Firestore
  node upload_clients_from_normalized_json.js --verify  - Verify data before upload
  node upload_clients_from_normalized_json.js --help    - Show this help
    `);
    return;
  }

  // First verify, then upload
  await verifyData();

  console.log('\n🤔 Do you want to continue with the upload? (y/N)');

  // Simple confirmation (in production could use readline)
  const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  });

  readline.question('Continue? (y/N): ', async (answer) => {
    if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
      await uploadClientsToFirestore();
    } else {
      console.log('🛑 Cancelled by user');
    }
    readline.close();
    process.exit(0);
  });
}

// Handle errors and graceful shutdown
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled rejection:', reason);
  process.exit(1);
});

process.on('SIGINT', () => {
  console.log('\n🛑 Interrupted by user');
  process.exit(0);
});

// Uruchom aplikację
main().catch(console.error);

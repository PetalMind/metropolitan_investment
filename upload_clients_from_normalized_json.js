const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Initialize Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://metropolitan-investment-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

// Function to generate UUID for document ID
function generateUUID() {
  return crypto.randomUUID();
}

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

// Funkcja do konwersji danych klienta - bardziej odporna na brakujące dane
function convertClientData(client) {
  return {
    // Structure matching Client.dart toFirestore()
    fullName: client.fullName || client.name || client.imie_nazwisko || 'Brak nazwy',
    name: client.fullName || client.name || client.imie_nazwisko || 'Brak nazwy',
    imie_nazwisko: client.fullName || client.name || client.imie_nazwisko || 'Brak nazwy', // Legacy compatibility

    excelId: client.excelId?.toString() || client.id?.toString() || 'brak',
    original_id: client.excelId?.toString() || client.id?.toString() || 'brak', // Legacy compatibility

    email: (client.email && client.email !== 'brak') ? client.email : '',

    phone: client.phone?.toString() || '',
    telefon: client.phone?.toString() || '', // Legacy compatibility

    address: client.address || '',
    pesel: client.pesel || null,

    companyName: client.companyName || null,
    nazwa_firmy: client.companyName || '', // Legacy compatibility

    type: mapClientType(client.type) || 'individual',
    notes: client.notes || '',
    votingStatus: mapVotingStatus(client.votingStatus) || 'undecided',
    colorCode: client.colorCode || '#FFFFFF',
    unviableInvestments: Array.isArray(client.unviableInvestments) ? client.unviableInvestments : [],

    // Dates - conversion to Timestamp (matching Client.dart) - zawsze ustawione
    createdAt: parseDate(client.createdAt) || admin.firestore.Timestamp.now(),
    updatedAt: parseDate(client.updatedAt) || admin.firestore.Timestamp.now(),
    created_at: client.createdAt || new Date().toISOString(), // Legacy compatibility
    uploaded_at: client.updatedAt || new Date().toISOString(), // Legacy compatibility
    uploadedAt: client.updatedAt || new Date().toISOString(), // Normalized name

    isActive: client.isActive !== false, // Default true

    additionalInfo: client.additionalInfo || {},

    // Source fields for compatibility
    sourceFile: client.additionalInfo?.sourceFile || client.additionalInfo?.source_file || 'clients_normalized_updated',
    source_file: client.additionalInfo?.sourceFile || client.additionalInfo?.source_file || 'clients_normalized_updated',

    // Add metadata about upload
    uploadedBy: 'batch_upload_script',
    uploadedAt_timestamp: admin.firestore.Timestamp.now()
  };
}

async function uploadClientsToFirestore() {
  try {
    console.log('🚀 Starting client upload to Firestore...');

    // Load data from JSON file with complete client data
    // Sprawdź różne możliwe pliki z danymi - priorytet dla clients_normalized_updated.json
    const possiblePaths = [
      path.join(__dirname, 'split_investment_data_normalized/clients_normalized_updated.json'),
      path.join(__dirname, 'clients_normalized_updated.json'),
      path.join(__dirname, 'clients_extracted_updated.json')
    ];

    let jsonPath;
    let clientsData;

    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        console.log(`📁 Found data file: ${filePath}`);
        jsonPath = filePath;
        break;
      }
    }

    if (!jsonPath) {
      throw new Error(`No client data file found. Checked paths: ${possiblePaths.join(', ')}`);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    clientsData = JSON.parse(rawData);

    console.log(`📁 Loading from: ${jsonPath}`);
    console.log(`📊 Found ${clientsData.length} clients to upload (will upload ALL records, including duplicates)`);

    let batch = db.batch();
    let processedCount = 0;
    let errorCount = 0;
    const batchSize = 500; // Firestore batch limit
    let batchOperations = 0; // Licznik operacji w bieżącym batch
    let batchNumber = 1;

    // Track processed excelIds to handle duplicates
    const excelIdCounters = new Map(); // excelId -> counter

    for (let i = 0; i < clientsData.length; i++) {
      const client = clientsData[i];

      // Skip tylko całkowicie puste obiekty
      if (!client) {
        console.log(`⚠️ Skipping null client at index ${i}`);
        continue;
      }

      // Generuj excelId jeśli brakuje
      let excelId = client.excelId || client.id || `missing_${i}`;
      excelId = excelId.toString();

      // Handle duplicates by adding suffix
      let documentId = excelId;
      if (excelIdCounters.has(excelId)) {
        const counter = excelIdCounters.get(excelId) + 1;
        excelIdCounters.set(excelId, counter);
        documentId = `${excelId}_dup${counter}`;
        console.log(`🔄 Duplicate excelId ${excelId}, using document ID: ${documentId}`);
      } else {
        excelIdCounters.set(excelId, 0);
      }

      try {
        // Use generated documentId as Firestore document ID
        const docRef = db.collection('clients').doc(documentId);
        const convertedData = convertClientData(client);

        // Ensure excelId is preserved in the document data
        convertedData.excelId = excelId;
        convertedData.documentId = documentId; // Add document ID for reference

        batch.set(docRef, convertedData, { merge: true });
        processedCount++;
        batchOperations++;

        // Execute batch every batchSize operations or at the end
        if (batchOperations >= batchSize || i === clientsData.length - 1) {
          console.log(`🔄 Executing batch ${batchNumber} with ${batchOperations} operations...`);
          await batch.commit();
          console.log(`✅ Uploaded ${processedCount} clients (batch ${batchNumber} completed)`);

          // Verify batch execution by checking collection size
          const currentSnapshot = await db.collection('clients').get();
          console.log(`📊 Current Firestore collection size: ${currentSnapshot.size} documents`);

          // Create new batch for next operations
          if (i < clientsData.length - 1) {
            batch = db.batch(); // POPRAWKA: właściwe tworzenie nowego batch
            batchOperations = 0; // Reset licznika
            batchNumber++;
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
    console.log(`📊 Total records processed: ${clientsData.length}`);
    console.log(`🔢 ExcelId counters: ${excelIdCounters.size} unique base excelIds`);

    // Count duplicates
    let duplicateCount = 0;
    excelIdCounters.forEach((count, excelId) => {
      if (count > 0) {
        duplicateCount += count;
        console.log(`   ${excelId}: ${count + 1} records (${count} duplicates)`);
      }
    });

    console.log(`🔄 Total duplicates handled: ${duplicateCount}`);

    // Check number of documents in collection
    const snapshot = await db.collection('clients').get();
    console.log(`📋 Final documents in 'clients' collection: ${snapshot.size}`);

    // SUCCESS ANALYSIS
    if (snapshot.size === processedCount) {
      console.log(`✅ SUCCESS: All ${processedCount} records uploaded successfully!`);
    } else {
      console.log(`🚨 MISMATCH: Expected ${processedCount} documents, but Firestore has ${snapshot.size}`);

      // Sample check - verify some documents exist
      console.log('\n🔍 Verifying random sample of uploaded documents...');
      const sampleExcelIds = Array.from(excelIdCounters.keys()).slice(0, 5);
      for (const excelId of sampleExcelIds) {
        const docRef = db.collection('clients').doc(excelId);
        const docSnap = await docRef.get();
        console.log(`   Doc ${excelId}: ${docSnap.exists ? 'EXISTS' : 'MISSING'}`);

        // Check duplicates too
        if (excelIdCounters.get(excelId) > 0) {
          const dupRef = db.collection('clients').doc(`${excelId}_dup1`);
          const dupSnap = await dupRef.get();
          console.log(`   Doc ${excelId}_dup1: ${dupSnap.exists ? 'EXISTS' : 'MISSING'}`);
        }
      }
    }

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
    // Sprawdź różne możliwe pliki z danymi
    const possiblePaths = [
      path.join(__dirname, 'clients_extracted_updated.json'),
      path.join(__dirname, 'split_investment_data_normalized/clients_normalized_updated.json'),
      path.join(__dirname, 'clients_normalized_updated.json')
    ];

    let jsonPath;
    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        console.log(`📁 Found data file for verification: ${filePath}`);
        jsonPath = filePath;
        break;
      }
    }

    if (!jsonPath) {
      throw new Error(`No client data file found. Checked paths: ${possiblePaths.join(', ')}`);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const clientsData = JSON.parse(rawData);

    console.log('🔍 Data verification...');
    console.log(`📁 Reading from: ${jsonPath}`);
    console.log(`Total records in JSON file: ${clientsData.length}`);

    const validClients = clientsData.filter(client => client && client.excelId);
    console.log(`Valid records with excelId: ${validClients.length}`);

    const uniqueExcelIds = new Set(validClients.map(c => c.excelId));
    console.log(`Unique excelIds: ${uniqueExcelIds.size}`);

    // Check current Firestore collection size
    console.log('\n📊 Current Firestore state...');
    const currentSnapshot = await db.collection('clients').get();
    console.log(`Current documents in Firestore 'clients' collection: ${currentSnapshot.size}`);

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

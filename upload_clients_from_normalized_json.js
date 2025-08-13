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
        jsonPath = filePath;
        break;
      }
    }

    if (!jsonPath) {
      throw new Error(`No client data file found. Checked paths: ${possiblePaths.join(', ')}`);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    clientsData = JSON.parse(rawData);

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
          await batch.commit();
          console.log(`✅ Uploaded ${processedCount} clients (batch ${batchNumber} completed)`);

          // Verify batch execution by checking collection size
          const currentSnapshot = await db.collection('clients').get();

          // Create new batch for next operations
          if (i < clientsData.length - 1) {
            batch = db.batch(); // POPRAWKA: właściwe tworzenie nowego batch
            batchOperations = 0; // Reset licznika
            batchNumber++;
          }
        }

        // Progress indicator
        if (processedCount % 100 === 0) {
        }

      } catch (error) {
        errorCount++;

        // Continue with next client
        continue;
      }
    }

    // Count duplicates
    let duplicateCount = 0;
    excelIdCounters.forEach((count, excelId) => {
      if (count > 0) {
        duplicateCount += count;
        console.log(`   ${excelId}: ${count + 1} records (${count} duplicates)`);
      }
    });

    // Check number of documents in collection
    const snapshot = await db.collection('clients').get();

    // SUCCESS ANALYSIS
    if (snapshot.size === processedCount) {
    } else {

      // Sample check - verify some documents exist
      const sampleExcelIds = Array.from(excelIdCounters.keys()).slice(0, 5);
      for (const excelId of sampleExcelIds) {
        const docRef = db.collection('clients').doc(excelId);
        const docSnap = await docRef.get();

        // Check duplicates too
        if (excelIdCounters.get(excelId) > 0) {
          const dupRef = db.collection('clients').doc(`${excelId}_dup1`);
          const dupSnap = await dupRef.get();
        }
      }
    }

    // Final data verification
    const sampleDocs = await db.collection('clients').limit(3).get();
    let emailCount = 0, phoneCount = 0;

    sampleDocs.forEach(doc => {
      const data = doc.data();
      if (data.email && data.email.trim() !== '') emailCount++;
      if (data.phone && data.phone.trim() !== '') phoneCount++;
    });

  } catch (error) {
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
        jsonPath = filePath;
        break;
      }
    }

    if (!jsonPath) {
      throw new Error(`No client data file found. Checked paths: ${possiblePaths.join(', ')}`);
    }

    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const clientsData = JSON.parse(rawData);

    const validClients = clientsData.filter(client => client && client.excelId);

    const uniqueExcelIds = new Set(validClients.map(c => c.excelId));

    // Check current Firestore collection size
    const currentSnapshot = await db.collection('clients').get();

    if (validClients.length !== uniqueExcelIds.size) {

      // Find duplicates
      const excelIdCounts = {};
      validClients.forEach(client => {
        excelIdCounts[client.excelId] = (excelIdCounts[client.excelId] || 0) + 1;
      });

      const duplicates = Object.entries(excelIdCounts).filter(([id, count]) => count > 1);
    }

    // Sample record
    if (validClients.length > 0) {
      const example = convertClientData(validClients[0]);
      console.log(JSON.stringify(example, null, 2));
    }

    // Check data completeness
    const withEmail = validClients.filter(c => c.email && c.email !== 'brak').length;
    const withPhone = validClients.filter(c => c.phone && c.phone.trim() !== '').length;

    console.log(`Clients with email: ${withEmail}/${validClients.length} (${Math.round(withEmail / validClients.length * 100)}%)`);
    console.log(`Clients with phone: ${withPhone}/${validClients.length} (${Math.round(withPhone / validClients.length * 100)}%)`);

  } catch (error) {
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
    }
    readline.close();
    process.exit(0);
  });
}

// Handle errors and graceful shutdown
process.on('unhandledRejection', (reason, promise) => {
  process.exit(1);
});

process.on('SIGINT', () => {
  process.exit(0);
});

// Uruchom aplikację
main().catch(console.error);

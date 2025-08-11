#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com/`
});

const db = admin.firestore();

async function uploadBatch(collectionName, documents, batchSize = 500) {
  console.log(`📦 Uploading ${documents.length} documents to collection '${collectionName}'...`);

  let uploadedCount = 0;
  let errorCount = 0;

  // Process in batches to avoid Firestore limits
  for (let i = 0; i < documents.length; i += batchSize) {
    const batch = db.batch();
    const currentBatch = documents.slice(i, i + batchSize);

    console.log(`📄 Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(documents.length / batchSize)} (${currentBatch.length} docs)...`);

    try {
      for (const doc of currentBatch) {
        // For clients, use their ID as document ID (no UUID generation)
        // For investments, generate document ID automatically
        let docRef;

        if (collectionName === 'clients') {
          // Use client ID as Firestore document ID - ensure it's a valid string
          const clientId = doc.id ? doc.id.toString().trim() : '';
          if (!clientId) {
            console.warn(`⚠️  Skipping client with empty ID: ${JSON.stringify(doc, null, 2)}`);
            continue;
          }
          docRef = db.collection(collectionName).doc(clientId);
        } else {
          // Auto-generate ID for investments
          docRef = db.collection(collectionName).doc();
        }

        // Clean up the document data
        const cleanDoc = { ...doc };

        // Replace null values with empty strings or appropriate defaults
        Object.keys(cleanDoc).forEach(key => {
          if (cleanDoc[key] === null) {
            // Replace null with appropriate default values
            if (key === 'unviableInvestments' || Array.isArray(doc[key])) {
              cleanDoc[key] = [];
            } else if (key === 'additionalInfo' || (typeof doc[key] === 'object' && doc[key] !== null)) {
              cleanDoc[key] = {};
            } else if (typeof doc[key] === 'boolean') {
              cleanDoc[key] = false;
            } else if (typeof doc[key] === 'number') {
              cleanDoc[key] = 0;
            } else {
              cleanDoc[key] = "";
            }
          }

          // Also clean nested objects
          if (typeof cleanDoc[key] === 'object' && cleanDoc[key] !== null && !Array.isArray(cleanDoc[key])) {
            Object.keys(cleanDoc[key]).forEach(nestedKey => {
              if (cleanDoc[key][nestedKey] === null) {
                cleanDoc[key][nestedKey] = "";
              }
            });
          }
        });

        // Convert date strings to Firestore Timestamps
        const dateFields = ['createdAt', 'updatedAt', 'uploadedAt', 'signedDate', 'investmentEntryDate', 'issueDate', 'maturityDate', 'repaymentDate'];

        dateFields.forEach(field => {
          if (cleanDoc[field] && cleanDoc[field] !== "" && cleanDoc[field] !== "NULL" && cleanDoc[field] !== null) {
            try {
              cleanDoc[field] = admin.firestore.Timestamp.fromDate(new Date(cleanDoc[field]));
            } catch (error) {
              console.warn(`⚠️  Could not convert date field '${field}': ${cleanDoc[field]}`);
              cleanDoc[field] = null; // Set to null if conversion fails
            }
          } else {
            cleanDoc[field] = null; // Set null for empty/invalid dates
          }
        });

        batch.set(docRef, cleanDoc);
      }

      await batch.commit();
      uploadedCount += currentBatch.length;
      console.log(`✅ Batch committed successfully. Total uploaded: ${uploadedCount}/${documents.length}`);

    } catch (error) {
      errorCount += currentBatch.length;
      console.error(`❌ Error uploading batch: ${error.message}`);
      console.error(`Failed documents: ${JSON.stringify(currentBatch.slice(0, 3), null, 2)}`);
    }

    // Small delay between batches
    if (i + batchSize < documents.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  console.log(`📊 Upload summary for '${collectionName}': ${uploadedCount} successful, ${errorCount} failed`);
  return { uploaded: uploadedCount, failed: errorCount };
}

async function loadJsonFile(filePath) {
  try {
    const data = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error(`❌ Error reading ${filePath}: ${error.message}`);
    return null;
  }
}

async function main() {
  console.log('🚀 Starting Firebase upload process...');

  const dataDir = './split_investment_data_normalized';
  const results = {};

  try {
    // 1. Upload Clients
    console.log('\n👥 === UPLOADING CLIENTS ===');
    const clients = await loadJsonFile(path.join(dataDir, 'clients_normalized.json'));
    if (clients) {
      results.clients = await uploadBatch('clients', clients);
    }

    // 2. Collect all investments from different files
    console.log('\n💰 === UPLOADING INVESTMENTS ===');

    const investmentFiles = [
      'apartments_normalized.json',
      'bonds_extracted.json',
      'loans_normalized.json',
      'shares_normalized.json'
    ];

    let allInvestments = [];

    for (const fileName of investmentFiles) {
      const filePath = path.join(dataDir, fileName);
      console.log(`📁 Loading ${fileName}...`);

      const data = await loadJsonFile(filePath);
      if (data && Array.isArray(data)) {
        console.log(`📊 Found ${data.length} records in ${fileName}`);
        allInvestments = allInvestments.concat(data);
      }
    }

    console.log(`📈 Total investments to upload: ${allInvestments.length}`);

    if (allInvestments.length > 0) {
      results.investments = await uploadBatch('investments', allInvestments);
    }

    // 3. Summary
    console.log('\n🎉 === UPLOAD COMPLETE ===');
    console.log('📊 Final Results:');

    Object.keys(results).forEach(collection => {
      const result = results[collection];
      console.log(`  ${collection}: ${result.uploaded} uploaded, ${result.failed} failed`);
    });

    const totalUploaded = Object.values(results).reduce((sum, r) => sum + r.uploaded, 0);
    const totalFailed = Object.values(results).reduce((sum, r) => sum + r.failed, 0);

    console.log(`🏆 Grand Total: ${totalUploaded} successful, ${totalFailed} failed`);

  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    console.error(error.stack);
  } finally {
    // Clean up
    console.log('🔧 Cleaning up...');
    process.exit(0);
  }
}

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n⏹️  Process interrupted by user');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  process.exit(1);
});

// Run the script
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { uploadBatch, loadJsonFile };

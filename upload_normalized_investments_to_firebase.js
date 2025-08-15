#!/usr/bin/env node

/**
 * Script for importing normalized investment data to Firebase
 * Uploads all .json files from split_investment_data_normalized/ folder
 * to 'investments' collection according to Investment.dart model
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./ServiceAccount.json');
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'metropolitan-investment'
  });
  console.log('✅ Firebase Admin SDK initialized with Service Account');
} catch (error) {
  console.error('❌ Firebase initialization error:', error.message);
  console.log('💡 Check if ServiceAccount.json file exists and is valid');
  process.exit(1);
}

const db = admin.firestore();

// Helper function for date parsing
function parseDate(dateString) {
  if (!dateString || dateString === 'NULL' || dateString === null) return null;

  try {
    // Handle different date formats
    const date = new Date(dateString);
    return date.toISOString();
  } catch (error) {
    console.warn(`⚠️  Cannot parse date: ${dateString}`);
    return null;
  }
}

// Helper function for safe number conversion
function safeToNumber(value, defaultValue = 0.0) {
  if (value === null || value === undefined || value === 'NULL') return defaultValue;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const cleaned = value.replace(/,/g, '');
    const parsed = parseFloat(cleaned);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}

// Helper function for safe int conversion
function safeToInt(value, defaultValue = null) {
  if (value === null || value === undefined || value === 'NULL') return defaultValue;
  if (typeof value === 'number') return Math.floor(value);
  if (typeof value === 'string') {
    const parsed = parseInt(value, 10);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}

// Product status mapping to enum
function mapProductStatus(status) {
  if (!status || status === 'NULL') return 'Active';
  switch (status) {
    case 'Nieaktywny': return 'Inactive';
    case 'Wykup wczesniejszy': return 'Early Redemption';
    case 'Zakończony': return 'Completed';
    default: return 'Active';
  }
}

// Market type mapping to enum
function mapMarketType(marketEntry) {
  if (!marketEntry || marketEntry === 'NULL') return 'Primary Market';
  switch (marketEntry) {
    case 'Rynek wtórny': return 'Secondary Market';
    case 'Odkup od Klienta': return 'Client Buyback';
    default: return 'Primary Market';
  }
}

// Product type mapping to enum
function mapProductType(productType) {
  switch (productType) {
    case 'Obligacje': return 'Bonds';
    case 'Pożyczka': return 'Loans';
    case 'Udziały': return 'Shares';
    case 'Apartamenty': return 'Apartments';
    default: return 'Bonds';
  }
}

// Helper function for cleaning undefined values
function cleanFirestoreValue(value) {
  if (value === undefined || value === null || value === 'NULL') return null;
  return value;
}

// Function for cleaning entire object from undefined values
function cleanFirestoreObject(obj) {
  const cleaned = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value !== undefined) {
      cleaned[key] = value;
    }
  }
  return cleaned;
}

// Function for mapping JSON data to Investment structure
function mapToInvestment(jsonData, generatedId = null) {
  const now = new Date().toISOString();

  const investmentData = {
    // ⭐ LOGICAL ID - use existing ID from JSON or generate for apartments
    id: jsonData.id || generatedId,

    // ⭐ NORMALIZED NAMES (priority) - according to new schema
    clientId: jsonData.clientId || '',
    clientName: jsonData.clientName || '',
    employeeId: '', // Not in JSON data
    employeeFirstName: '', // Not in JSON data
    employeeLastName: '', // Not in JSON data
    branch: jsonData.branch || '',
    productStatus: mapProductStatus(jsonData.productStatus || jsonData.status),
    productStatusEntry: mapMarketType(jsonData.productStatusEntry || jsonData.marketEntry),
    signingDate: parseDate(jsonData.signedDate),
    investmentEntryDate: parseDate(jsonData.investmentEntryDate),
    saleId: jsonData.salesId || jsonData.saleId || '',
    productType: mapProductType(jsonData.productType),
    productName: jsonData.productName || jsonData.projectName || '',
    productId: null, // Not in JSON data
    companyId: jsonData.companyId || '',
    shareCount: safeToInt(jsonData.sharesCount || jsonData.shareCount),
    investmentAmount: safeToNumber(jsonData.investmentAmount),
    paidAmount: safeToNumber(jsonData.paymentAmount || jsonData.investmentAmount),
    realizedCapital: safeToNumber(jsonData.additionalInfo?.realizedCapital || jsonData.realizedCapital),
    realizedInterest: safeToNumber(jsonData.realizedInterest || jsonData.additionalInfo?.realizedInterest),
    transferToOtherProduct: safeToNumber(jsonData.additionalInfo?.transferToOtherProduct || jsonData.transferToOtherProduct),
    remainingCapital: safeToNumber(jsonData.remainingCapital),
    remainingInterest: safeToNumber(jsonData.remainingInterest),

    // 🔥 CAPITAL FIELDS FROM MAIN LEVEL
    capitalSecuredByRealEstate: safeToNumber(jsonData.capitalSecuredByRealEstate),
    capitalForRestructuring: safeToNumber(jsonData.capitalForRestructuring),

    createdAt: jsonData.createdAt || now,
    updatedAt: jsonData.uploadedAt || now,
    uploadedAt: jsonData.uploadedAt || now,
    sourceFile: jsonData.sourceFile || 'normalized_import',

    // Bond/loan specific fields from additionalInfo
    bondName: cleanFirestoreValue(jsonData.additionalInfo?.bondName),
    interestRate: cleanFirestoreValue(jsonData.interestRate || jsonData.additionalInfo?.interestRate),
    issuer: cleanFirestoreValue(jsonData.additionalInfo?.issuer),
    loanNumber: cleanFirestoreValue(jsonData.loanNumber || jsonData.additionalInfo?.loanNumber),
    borrower: cleanFirestoreValue(jsonData.borrower || jsonData.additionalInfo?.borrower),
    collateral: cleanFirestoreValue(jsonData.collateral || jsonData.additionalInfo?.collateral),
    realEstateSecuredCapital: safeToNumber(jsonData.capitalSecuredByRealEstate),
    repaymentDate: parseDate(jsonData.repaymentDate),
    disbursementDate: parseDate(jsonData.disbursementDate),
    accruedInterest: safeToNumber(jsonData.accruedInterest),
    maturityDate: parseDate(jsonData.maturityDate),

    // Additional fields from new structure
    investmentType: mapProductType(jsonData.productType).toLowerCase(),
    realizedTax: safeToNumber(jsonData.realizedTax),
    remainingTax: safeToNumber(jsonData.remainingTax),
    advisor: jsonData.advisor || '',
    projectName: jsonData.projectName || '', // For apartments
  };

  // Clean undefined values before returning
  return cleanFirestoreObject(investmentData);
}

// Main function
async function uploadInvestmentsToFirebase() {
  console.log('🚀 Starting import of normalized investment data to Firebase...\n');

  const normalizedDataDir = './split_investment_data_normalized';
  const files = [
    'bonds_extracted.json',
    'loans_normalized.json',
    'shares_normalized.json',
    'apartments_normalized.json'
  ];

  let totalProcessed = 0;
  let totalUploaded = 0;
  let errors = 0;

  for (const filename of files) {
    const filePath = path.join(normalizedDataDir, filename);

    if (!fs.existsSync(filePath)) {
      console.log(`⚠️  File does not exist: ${filename}`);
      continue;
    }

    console.log(`📂 Processing file: ${filename}`);

    try {
      const fileContent = fs.readFileSync(filePath, 'utf8');
      const jsonData = JSON.parse(fileContent);

      if (!Array.isArray(jsonData)) {
        console.log(`❌ File ${filename} does not contain array data`);
        continue;
      }

      console.log(`📊 Found ${jsonData.length} records in ${filename}`);

      // Special processing for apartments - add ID if missing
      if (filename.includes('apartments')) {
        let idsAdded = 0;
        jsonData.forEach((item, index) => {
          if (!item.id) {
            const apartmentNumber = (index + 1).toString().padStart(4, '0');
            item.id = `apartment_${apartmentNumber}`;
            idsAdded++;
          }
        });
        if (idsAdded > 0) {
          console.log(`✨ Generated ${idsAdded} IDs for apartments`);
        }
      }

      // Process in batches of 500 records (Firestore batch limit)
      const batchSize = 500;
      const batches = [];

      for (let i = 0; i < jsonData.length; i += batchSize) {
        const batch = jsonData.slice(i, i + batchSize);
        batches.push(batch);
      }

      console.log(`🔄 Prepared ${batches.length} data batches`);

      for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        const batch = batches[batchIndex];
        const firestoreBatch = db.batch();

        for (let itemIndex = 0; itemIndex < batch.length; itemIndex++) {
          const item = batch[itemIndex];
          totalProcessed++;

          // Use ID from record (now all should have ID)
          const recordId = item.id;

          // Check if has required fields
          if (!recordId) {
            console.warn(`⚠️  Record without ID in ${filename}, skipping: ${JSON.stringify(item).substring(0, 100)}...`);
            errors++;
            continue;
          }

          try {
            const investmentData = mapToInvestment(item, recordId);
            const docRef = db.collection('investments').doc(recordId);
            firestoreBatch.set(docRef, investmentData, { merge: true });
            totalUploaded++;
          } catch (mapError) {
            console.error(`❌ Record mapping error ${recordId}:`, mapError.message);
            errors++;
          }
        }

        // Execute batch
        try {
          await firestoreBatch.commit();
          console.log(`✅ Sent batch ${batchIndex + 1}/${batches.length} (${batch.length} records)`);
        } catch (batchError) {
          console.error(`❌ Batch sending error ${batchIndex + 1}:`, batchError.message);
          errors += batch.length;
        }
      }

      console.log(`✅ Finished processing ${filename}\n`);

    } catch (error) {
      console.error(`❌ File processing error ${filename}:`, error.message);
      errors++;
    }
  }

  console.log('\n📋 IMPORT SUMMARY:');
  console.log(`📊 Records processed: ${totalProcessed}`);
  console.log(`✅ Records sent to Firebase: ${totalUploaded}`);
  console.log(`❌ Errors: ${errors}`);

  if (totalUploaded > 0) {
    console.log('\n🎉 Import completed successfully!');
    console.log(`🔍 Check 'investments' collection in Firebase Console`);
  } else {
    console.log('\n⚠️  No data sent to Firebase');
  }

  process.exit(0);
}

// Error handling
process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled error:', error);
  process.exit(1);
});

// Run script
uploadInvestmentsToFirebase().catch((error) => {
  console.error('❌ Main error:', error);
  process.exit(1);
});

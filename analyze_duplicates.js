const fs = require('fs');
const path = require('path');

// Sprawdź duplikaty w plikach JSON
async function analyzeDuplicates() {
  const filePath = path.join(__dirname, 'clients_extracted_updated.json');

  if (!fs.existsSync(filePath)) {
    console.log('❌ File not found:', filePath);
    return;
  }

  console.log('🔍 Analyzing duplicates in clients_extracted_updated.json...\n');

  const rawData = fs.readFileSync(filePath, 'utf8');
  const clientsData = JSON.parse(rawData);

  console.log(`📊 Total records: ${clientsData.length}`);

  // Analyze excelId duplicates
  const excelIdCounts = {};
  const validClients = [];

  clientsData.forEach((client, index) => {
    if (!client || !client.excelId) {
      console.log(`⚠️ Invalid client at index ${index}`);
      return;
    }

    validClients.push(client);
    const excelId = client.excelId.toString();
    excelIdCounts[excelId] = (excelIdCounts[excelId] || 0) + 1;
  });

  const uniqueExcelIds = Object.keys(excelIdCounts).length;
  const duplicates = Object.entries(excelIdCounts).filter(([id, count]) => count > 1);

  console.log(`✅ Valid clients: ${validClients.length}`);
  console.log(`🔢 Unique excelIds: ${uniqueExcelIds}`);
  console.log(`🔄 Duplicates found: ${duplicates.length}`);

  if (duplicates.length > 0) {
    console.log('\n📋 Duplicate excelIds:');
    duplicates.slice(0, 20).forEach(([id, count]) => {
      console.log(`   ${id}: ${count} times`);
    });

    if (duplicates.length > 20) {
      console.log(`   ... and ${duplicates.length - 20} more`);
    }
  }

  // Check if this explains the 500 vs 923 discrepancy
  const expectedFirestoreDocuments = uniqueExcelIds;
  console.log(`\n🔍 Expected Firestore documents: ${expectedFirestoreDocuments}`);
  console.log(`❓ This should explain why Firestore shows ${expectedFirestoreDocuments} instead of ${validClients.length}`);

  // Analyze first 500 vs remaining
  const first500 = validClients.slice(0, 500);
  const remaining = validClients.slice(500);

  const first500ExcelIds = new Set(first500.map(c => c.excelId.toString()));
  const remainingExcelIds = new Set(remaining.map(c => c.excelId.toString()));

  console.log(`\n📊 First 500 clients: ${first500ExcelIds.size} unique excelIds`);
  console.log(`📊 Remaining ${remaining.length} clients: ${remainingExcelIds.size} unique excelIds`);

  // Check overlap
  const overlap = [...first500ExcelIds].filter(id => remainingExcelIds.has(id));
  console.log(`🔄 Overlap between first 500 and remaining: ${overlap.length} excelIds`);

  if (overlap.length > 0) {
    console.log('   First few overlapping IDs:', overlap.slice(0, 10));
  }
}

analyzeDuplicates().catch(console.error);

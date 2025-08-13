const fs = require('fs');
const path = require('path');

// Sprawdź duplikaty w plikach JSON
async function analyzeDuplicates() {
  const filePath = path.join(__dirname, 'clients_extracted_updated.json');

  if (!fs.existsSync(filePath)) {
    return;
  }

  const rawData = fs.readFileSync(filePath, 'utf8');
  const clientsData = JSON.parse(rawData);

  // Analyze excelId duplicates
  const excelIdCounts = {};
  const validClients = [];

  clientsData.forEach((client, index) => {
    if (!client || !client.excelId) {
      return;
    }

    validClients.push(client);
    const excelId = client.excelId.toString();
    excelIdCounts[excelId] = (excelIdCounts[excelId] || 0) + 1;
  });

  const uniqueExcelIds = Object.keys(excelIdCounts).length;
  const duplicates = Object.entries(excelIdCounts).filter(([id, count]) => count > 1);

  if (duplicates.length > 0) {
    duplicates.slice(0, 20).forEach(([id, count]) => {
    });

    if (duplicates.length > 20) {
    }
  }

  // Check if this explains the 500 vs 923 discrepancy
  const expectedFirestoreDocuments = uniqueExcelIds;

  // Analyze first 500 vs remaining
  const first500 = validClients.slice(0, 500);
  const remaining = validClients.slice(500);

  const first500ExcelIds = new Set(first500.map(c => c.excelId.toString()));
  const remainingExcelIds = new Set(remaining.map(c => c.excelId.toString()));

  // Check overlap
  const overlap = [...first500ExcelIds].filter(id => remainingExcelIds.has(id));

  if (overlap.length > 0) {
    console.log('   First few overlapping IDs:', overlap.slice(0, 10));
  }
}

analyzeDuplicates().catch(console.error);

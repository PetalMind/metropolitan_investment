/**
 * Test eksportu Excel - debug problem z formatem pliku
 */

const { onCall } = require("firebase-functions/v2/https");
const { exportInvestorsAdvanced } = require('./services/advanced-export-service');
const fs = require('fs');
const path = require('path');

// Test direct Excel generation 
async function testDirectExcelGeneration() {
  console.log('🧪 [Excel Debug] Testing direct Excel generation...');

  try {
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Test');

    // Dodaj podstawowe dane testowe
    worksheet.addRow(['Nazwa klienta', 'Kwota', 'Status']);
    worksheet.addRow(['Jan Kowalski', 1000, 'Aktywny']);
    worksheet.addRow(['Anna Nowak', 2000, 'Nieaktywny']);

    // Stylizuj nagłówki
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE6E6FA' }
    };

    // Ustaw szerokości kolumn
    worksheet.columns = [
      { width: 20 },
      { width: 15 },
      { width: 15 }
    ];

    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');

    console.log(`✅ Buffer length: ${buffer.length} bytes`);
    console.log(`✅ Base64 length: ${base64Content.length} chars`);
    console.log(`✅ First 50 chars of base64: ${base64Content.substring(0, 50)}`);

    // Sprawdź czy to faktycznie poprawny Excel
    const testFilePath = path.join(__dirname, 'test-debug-excel.xlsx');
    fs.writeFileSync(testFilePath, buffer);
    console.log(`✅ Test file saved to: ${testFilePath}`);

    return {
      success: true,
      bufferLength: buffer.length,
      base64Length: base64Content.length,
      base64Sample: base64Content.substring(0, 100),
      testFilePath,
      fileData: base64Content
    };

  } catch (error) {
    console.error('❌ Direct Excel test failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Test advanced export Excel
async function testAdvancedExportExcel() {
  console.log('🧪 [Excel Debug] Testing advanced export Excel...');

  try {
    const testData = {
      clientIds: ['client_001', 'client_002'],
      exportFormat: 'excel',
      templateType: 'summary',
      options: {},
      requestedBy: 'test@metropolitan.pl'
    };

    const result = await exportInvestorsAdvanced(testData);

    if (result.success && result.fileData) {
      console.log(`✅ Advanced export success`);
      console.log(`✅ Filename: ${result.filename}`);
      console.log(`✅ FileSize: ${result.fileSize}`);
      console.log(`✅ Base64 length: ${result.fileData.length}`);
      console.log(`✅ First 50 chars: ${result.fileData.substring(0, 50)}`);

      // Zapisz test file
      const testBuffer = Buffer.from(result.fileData, 'base64');
      const testFilePath = path.join(__dirname, 'test-advanced-excel.xlsx');
      fs.writeFileSync(testFilePath, testBuffer);
      console.log(`✅ Advanced test file saved to: ${testFilePath}`);

      return {
        success: true,
        filename: result.filename,
        fileSize: result.fileSize,
        base64Length: result.fileData.length,
        base64Sample: result.fileData.substring(0, 100),
        testFilePath,
        fileData: result.fileData
      };
    } else {
      return {
        success: false,
        error: result.errorMessage || 'Unknown error'
      };
    }

  } catch (error) {
    console.error('❌ Advanced Excel test failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Cloud Function for testing
const testExcelDebug = onCall({ memory: '1GiB' }, async (request) => {
  console.log('🧪 [Excel Debug] Starting Excel debug tests...');

  const directTest = await testDirectExcelGeneration();
  const advancedTest = await testAdvancedExportExcel();

  const result = {
    timestamp: new Date().toISOString(),
    directTest,
    advancedTest,
    comparison: {
      bothSucceeded: directTest.success && advancedTest.success,
      sizesMatch: directTest.success && advancedTest.success ? 
        (directTest.bufferLength === advancedTest.fileSize) : false,
      base64Match: directTest.success && advancedTest.success ?
        (directTest.base64Sample === advancedTest.base64Sample) : false
    }
  };

  console.log('🎯 [Excel Debug] Test results:', JSON.stringify(result, null, 2));

  return result;
});

module.exports = {
  testExcelDebug
};
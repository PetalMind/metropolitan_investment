#!/usr/bin/env node

const path = require('path');
const fs = require('fs');

// Testowe dane z polskimi znakami
const testData = [
  {
    clientName: 'Jan Kowalski z ąćęłńóśźż',
    investmentCount: 2,
    totalInvestmentAmount: 100000,
    totalRemainingCapital: 80000,
    totalSecuredCapital: 60000,
    totalCapitalForRestructuring: 20000,
    riskLevel: 'Średnie',
    investmentDetails: [
      {
        displayName: 'Obligacja korporacyjna nr 1 z ąćęłńóśźż',
        investmentEntryDate: '2024-01-15',
        investmentAmount: 50000,
        remainingCapital: 45000,
        capitalSecuredByRealEstate: 30000,
        capitalForRestructuring: 15000
      },
      {
        displayName: 'Lokata terminowa z żółtą różą',
        investmentEntryDate: '2024-03-10',
        investmentAmount: 50000,
        remainingCapital: 35000,
        capitalSecuredByRealEstate: 30000,
        capitalForRestructuring: 5000
      }
    ]
  }
];

console.log('🧪 [TestPolishChars] Testowanie polskich znaków w eksporcie PDF...');

// Sprawdź czy funkcja export istnieje
try {
  const exportService = require('./services/advanced-export-service');

  // Test generowania PDF z polskimi znakami
  exportService.getAdvancedInvestorExport({
    selectedInvestors: ['test'],
    exportFormat: 'pdf',
    templateType: 'szczegolowy',
    customFileName: 'test_polskie_znaki'
  }, testData).then(result => {
    if (result.success) {
      console.log('✅ [TestPolishChars] PDF wygenerowany pomyślnie!');
      console.log(`📄 [TestPolishChars] Nazwa pliku: ${result.export.filename}`);
      console.log(`📏 [TestPolishChars] Rozmiar: ${result.export.fileSize} bajtów`);

      // Zapisz plik lokalnie do testów
      const testOutputPath = path.join(__dirname, 'test_polish_chars.pdf');
      const pdfBuffer = Buffer.from(result.export.fileData, 'base64');
      fs.writeFileSync(testOutputPath, pdfBuffer);
      console.log(`💾 [TestPolishChars] Test PDF zapisany: ${testOutputPath}`);
      console.log('🔍 [TestPolishChars] Sprawdź czy polskie znaki wyświetlają się poprawnie!');
    } else {
      console.error('❌ [TestPolishChars] Błąd generowania PDF:', result.error);
    }
  }).catch(error => {
    console.error('❌ [TestPolishChars] Wyjątek:', error);
  });

} catch (error) {
  console.error('❌ [TestPolishChars] Błąd ładowania serwisu:', error);
}

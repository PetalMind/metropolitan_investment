#!/usr/bin/env node

const path = require('path');
const fs = require('fs');

// Testowe dane z polskimi znakami i różnymi typami produktów
const testData = [
  {
    clientName: 'Jan Kowalski',
    investmentCount: 2,
    totalInvestmentAmount: 150000,
    totalRemainingCapital: 120000,
    totalSecuredCapital: 90000,
    totalCapitalForRestructuring: 30000,
    riskLevel: 'Średnie',
    investmentDetails: [
      {
        clientName: 'Jan Kowalski',
        productName: 'Obligacja korporacyjna Seria A',
        investmentType: 'Obligacja',
        investmentEntryDate: '15.01.2024',
        investmentAmount: 75000,
        remainingCapital: 65000,
        capitalSecuredByRealEstate: 50000,
        capitalForRestructuring: 15000
      },
      {
        clientName: 'Jan Kowalski',
        productName: 'Lokata terminowa 12M',
        investmentType: 'Lokata',
        investmentEntryDate: '10.03.2024',
        investmentAmount: 75000,
        remainingCapital: 55000,
        capitalSecuredByRealEstate: 40000,
        capitalForRestructuring: 15000
      }
    ]
  },
  {
    clientName: 'Firma ABC Sp. z o.o.',
    investmentCount: 1,
    totalInvestmentAmount: 200000,
    totalRemainingCapital: 180000,
    totalSecuredCapital: 150000,
    totalCapitalForRestructuring: 30000,
    riskLevel: 'Wysokie',
    investmentDetails: [
      {
        clientName: 'Firma ABC Sp. z o.o.',
        productName: 'Pożyczka hipoteczna na mieszkanie',
        investmentType: 'Pożyczka',
        investmentEntryDate: '20.02.2024',
        investmentAmount: 200000,
        remainingCapital: 180000,
        capitalSecuredByRealEstate: 150000,
        capitalForRestructuring: 30000
      }
    ]
  }
];

console.log('🧪 [TestExcelFormat] Testowanie nowego formatu Excel z podzielonymi kolumnami...');

// Sprawdź czy funkcja export istnieje
try {
  const exportService = require('./services/advanced-export-service');

  // Test generowania Excel z podzielonymi kolumnami
  exportService.getAdvancedInvestorExport({
    selectedInvestors: ['test'],
    exportFormat: 'excel',
    templateType: 'szczegolowy',
    customFileName: 'test_excel_podzielone_kolumny'
  }, testData).then(result => {
    if (result.success) {
      console.log('✅ [TestExcelFormat] Excel wygenerowany pomyślnie!');
      console.log(`📄 [TestExcelFormat] Nazwa pliku: ${result.export.filename}`);
      console.log(`📏 [TestExcelFormat] Rozmiar: ${result.export.fileSize} bajtów`);

      // Zapisz plik lokalnie do testów
      const testOutputPath = path.join(__dirname, 'test_excel_separated_columns.xlsx');
      const excelBuffer = Buffer.from(result.export.fileData, 'base64');
      fs.writeFileSync(testOutputPath, excelBuffer);
      console.log(`💾 [TestExcelFormat] Test Excel zapisany: ${testOutputPath}`);
      console.log('');
      console.log('🔍 [TestExcelFormat] Sprawdź czy Excel zawiera podzielone kolumny:');
      console.log('   1. Nazwisko / Nazwa firmy');
      console.log('   2. Nazwa produktu');
      console.log('   3. Typ produktu');
      console.log('   4. Data wejścia');
      console.log('   5. Kwota inwestycji (PLN) - z formatowaniem waluty');
      console.log('   6. Kapitał pozostały (PLN) - z formatowaniem waluty');
      console.log('   7. Kapitał zabezpieczony nieruchomością (PLN) - z formatowaniem waluty');
      console.log('   8. Kapitał do restrukturyzacji (PLN) - z formatowaniem waluty');
    } else {
      console.error('❌ [TestExcelFormat] Błąd generowania Excel:', result.error);
    }
  }).catch(error => {
    console.error('❌ [TestExcelFormat] Wyjątek:', error);
  });

} catch (error) {
  console.error('❌ [TestExcelFormat] Błąd ładowania serwisu:', error);
}

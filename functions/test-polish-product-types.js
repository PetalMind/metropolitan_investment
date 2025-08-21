#!/usr/bin/env node

const path = require('path');
const fs = require('fs');

// Testowe dane z różnymi typami produktów w języku angielskim 
const testData = [
  {
    clientName: 'Jan Kowalski',
    investmentCount: 4,
    totalInvestmentAmount: 400000,
    totalRemainingCapital: 350000,
    totalSecuredCapital: 280000,
    totalCapitalForRestructuring: 70000,
    riskLevel: 'Średnie',
    investmentDetails: [
      {
        clientName: 'Jan Kowalski',
        productName: 'Obligacja korporacyjna Seria A',
        investmentType: 'bonds', // Anglieskie - powinno stać się "Obligacje"
        investmentEntryDate: '15.01.2024',
        investmentAmount: 100000,
        remainingCapital: 90000,
        capitalSecuredByRealEstate: 70000,
        capitalForRestructuring: 20000
      },
      {
        clientName: 'Jan Kowalski',
        productName: 'Akcje spółki Tech',
        investmentType: 'shares', // Angielskie - powinno stać się "Akcje"
        investmentEntryDate: '10.02.2024',
        investmentAmount: 150000,
        remainingCapital: 130000,
        capitalSecuredByRealEstate: 100000,
        capitalForRestructuring: 30000
      },
      {
        clientName: 'Jan Kowalski',
        productName: 'Pożyczka hipoteczna centrum',
        investmentType: 'loans', // Angielskie - powinno stać się "Pożyczki"
        investmentEntryDate: '05.03.2024',
        investmentAmount: 100000,
        remainingCapital: 85000,
        capitalSecuredByRealEstate: 70000,
        capitalForRestructuring: 15000
      },
      {
        clientName: 'Jan Kowalski',
        productName: 'Apartament Wola inwestycja',
        investmentType: 'apartments', // Angielskie - powinno stać się "Apartamenty"
        investmentEntryDate: '20.04.2024',
        investmentAmount: 50000,
        remainingCapital: 45000,
        capitalSecuredByRealEstate: 40000,
        capitalForRestructuring: 5000
      }
    ]
  },
  {
    clientName: 'Anna Nowak',
    investmentCount: 2,
    totalInvestmentAmount: 300000,
    totalRemainingCapital: 270000,
    totalSecuredCapital: 200000,
    totalCapitalForRestructuring: 70000,
    riskLevel: 'Niskie',
    investmentDetails: [
      {
        clientName: 'Anna Nowak',
        productName: 'Obligacja skarbu państwa',
        investmentType: 'Bonds', // Wielka litera - powinno stać się "Obligacje"
        investmentEntryDate: '01.01.2024',
        investmentAmount: 200000,
        remainingCapital: 180000,
        capitalSecuredByRealEstate: 150000,
        capitalForRestructuring: 30000
      },
      {
        clientName: 'Anna Nowak',
        productName: 'Akcje deweloperskie',
        investmentType: 'Shares', // Wielka litera - powinno stać się "Akcje"
        investmentEntryDate: '15.05.2024',
        investmentAmount: 100000,
        remainingCapital: 90000,
        capitalSecuredByRealEstate: 50000,
        capitalForRestructuring: 40000
      }
    ]
  }
];

console.log('🧪 [TestPolishProductTypes] Testowanie mapowania typów produktów na język polski...');

// Sprawdź czy funkcja export istnieje
try {
  const exportService = require('./services/advanced-export-service');

  // Test generowania Excel z polskimi typami produktów
  exportService.getAdvancedInvestorExport({
    selectedInvestors: ['test'],
    exportFormat: 'excel',
    templateType: 'szczegolowy',
    customFileName: 'test_polskie_typy_produktow'
  }, testData).then(result => {
    if (result.success) {
      console.log('✅ [TestPolishProductTypes] Excel wygenerowany pomyślnie!');
      console.log(`📄 [TestPolishProductTypes] Nazwa pliku: ${result.export.filename}`);
      console.log(`📏 [TestPolishProductTypes] Rozmiar: ${result.export.fileSize} bajtów`);

      // Zapisz plik lokalnie do testów
      const testOutputPath = path.join(__dirname, 'test_polish_product_types.xlsx');
      const excelBuffer = Buffer.from(result.export.fileData, 'base64');
      fs.writeFileSync(testOutputPath, excelBuffer);
      console.log(`💾 [TestPolishProductTypes] Test Excel zapisany: ${testOutputPath}`);
      console.log('');
      console.log('🔍 [TestPolishProductTypes] Sprawdź czy w kolumnie "Typ produktu" masz polskie nazwy:');
      console.log('   ✅ bonds/Bonds → Obligacje');
      console.log('   ✅ shares/Shares → Akcje');
      console.log('   ✅ loans/Loans → Pożyczki');
      console.log('   ✅ apartments/Apartments → Apartamenty');
      console.log('');
      console.log('❌ Jeśli nadal widzisz angielskie nazwy (Bonds, Shares), to mapowanie nie działa!');
    } else {
      console.error('❌ [TestPolishProductTypes] Błąd generowania Excel:', result.error);
    }
  }).catch(error => {
    console.error('❌ [TestPolishProductTypes] Wyjątek:', error);
  });

} catch (error) {
  console.error('❌ [TestPolishProductTypes] Błąd ładowania serwisu:', error);
}

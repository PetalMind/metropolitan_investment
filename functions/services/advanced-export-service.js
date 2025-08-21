/**
 * Advanced Export Service - Zaawansowany eksport inwestorów
 * 
 * Serwis obsługujący eksport danych inwestorów do formatów:
 * - PDF (wysokiej jakości raporty) 
 * - Excel (zaawansowane arkusze z formatowaniem)
 * - Word (dokumenty biznesowe)
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Profesjonalne formatowanie zgodne z marką Metropolitan Investment
 * • Eksport do PDF, Excel, Word z pełnym brandingiem
 * • Prawdziwe pliki binarne (nie tekstowe z nieprawidłowym content-type)
 * 
 * 📦 WYMAGANE ZALEŻNOŚCI:
 * • exceljs: Generowanie prawdziwych plików Excel
 * • pdfkit: Generowanie praw  // Nagłówki zgodne z nowym formatem
  let csvContent = 'Inwestor - Produkt - Typ,Data wejścia,Kwota inwestycji,Kapitał pozostały,Kapitał zabezpieczony nieruchomością,Kapitał do restrukturyzacji\n';

  investorsData.forEach(investor => {
    // Dodaj każdą inwestycję jako osobny wiersz
    investor.investmentDetails.forEach(detail => {
      csvContent += `"${detail.displayName}","${detail.investmentEntryDate}",${detail.investmentAmount},${detail.remainingCapital},${detail.capitalSecuredByRealEstate},${detail.capitalForRestructuring}\n`;
    });plików PDF  
 * • docx: Generowanie prawdziwych plików Word
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");

// Test dostępności bibliotek eksportu
let EXPORT_LIBRARIES = {
  excel: false,
  pdf: false,
  word: false
};

// Sprawdź dostępność ExcelJS
try {
  require('exceljs');
  EXPORT_LIBRARIES.excel = true;
  console.log('✅ [AdvancedExportService] ExcelJS dostępne');
} catch (error) {
  console.warn('⚠️ [AdvancedExportService] ExcelJS niedostępne:', error.message);
}

// Sprawdź dostępność PDFKit
try {
  require('pdfkit');
  EXPORT_LIBRARIES.pdf = true;
  console.log('✅ [AdvancedExportService] PDFKit dostępne');
} catch (error) {
  console.warn('⚠️ [AdvancedExportService] PDFKit niedostępne:', error.message);
}

// Sprawdź dostępność docx
try {
  require('docx');
  EXPORT_LIBRARIES.word = true;
  console.log('✅ [AdvancedExportService] docx dostępne');
} catch (error) {
  console.warn('⚠️ [AdvancedExportService] docx niedostępne:', error.message);
}

const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

/**
 * Eksportuje dane inwestorów do zaawansowanych formatów
 * 
 * @param {Object} data - Dane wejściowe
 * @param {string[]} data.clientIds - Lista ID klientów do eksportu
 * @param {string} data.exportFormat - Format eksportu ('pdf'|'excel'|'word')
 * @param {string} data.templateType - Typ szablonu ('summary'|'detailed'|'financial')
 * @param {Object} data.options - Opcje eksportu
 * @param {string} data.requestedBy - Email osoby żądającej eksportu
 * 
 * @returns {Object} Wynikowy plik do pobrania
 */
const exportInvestorsAdvanced = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const startTime = Date.now();
  console.log(`📤 [AdvancedExportService] Rozpoczynam zaawansowany eksport`);
  console.log(`📊 [AdvancedExportService] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

  try {
    const {
      clientIds,
      exportFormat,
      templateType = 'summary',
      options = {},
      requestedBy
    } = request.data;

    // 🔍 WALIDACJA
    if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
      throw new HttpsError('invalid-argument', 'Wymagana jest lista clientIds');
    }

    if (!['pdf', 'excel', 'word'].includes(exportFormat)) {
      throw new HttpsError('invalid-argument', 'Nieprawidłowy format eksportu');
    }

    if (!requestedBy) {
      throw new HttpsError('unauthenticated', 'Wymagany requestedBy');
    }

    // 🔍 SPRAWDŹ DOSTĘPNOŚĆ BIBLIOTEK DLA DANEGO FORMATU
    const formatLibraryMap = {
      'excel': 'excel',
      'pdf': 'pdf',
      'word': 'word'
    };

    const requiredLibrary = formatLibraryMap[exportFormat];
    if (requiredLibrary && !EXPORT_LIBRARIES[requiredLibrary]) {
      console.warn(`⚠️ [AdvancedExportService] Biblioteka dla ${exportFormat} niedostępna, użyję fallback`);
    }

    // 🔍 POBIERZ DANE INWESTORÓW
    console.log(`🔍 [AdvancedExportService] Pobieram dane dla ${clientIds.length} inwestorów...`);

    const investorsData = await fetchInvestorsData(clientIds);

    if (investorsData.length === 0) {
      throw new HttpsError('not-found', 'Nie znaleziono danych inwestorów');
    }

    // 📤 GENERUJ EKSPORT
    let exportResult;
    const currentDate = new Date().toISOString().split('T')[0];

    switch (exportFormat) {
      case 'pdf':
        exportResult = await generatePDFExport(investorsData, templateType, options, currentDate);
        break;
      case 'excel':
        exportResult = await generateExcelExport(investorsData, templateType, options, currentDate);
        break;
      case 'word':
        exportResult = await generateWordExport(investorsData, templateType, options, currentDate);
        break;
    }

    // 📝 ZAPISZ HISTORIĘ
    await saveExportHistory({
      requestedBy,
      exportFormat,
      templateType,
      clientCount: investorsData.length,
      options,
      executedAt: new Date(),
      executionTimeMs: Date.now() - startTime,
      filename: exportResult.filename
    });

    console.log(`🎉 [AdvancedExportService] Eksport zakończony w ${Date.now() - startTime}ms`);
    console.log(`📋 [AdvancedExportService] Wynik eksportu:`, {
      filename: exportResult.filename,
      fileDataLength: exportResult.fileData?.length || 0,
      contentType: exportResult.contentType,
      fileSize: exportResult.fileSize
    });

    // WALIDACJA PRZED ZWRÓCENIEM - pomijamy null wartości
    const safeResult = {
      success: true,
      format: exportFormat,
      templateType,
      recordCount: investorsData.length,
      filename: exportResult.filename || 'unknown_file',
      fileData: exportResult.fileData || '',
      contentType: exportResult.contentType || 'application/octet-stream',
      downloadUrl: exportResult.downloadUrl || null,
      fileSize: exportResult.fileSize || 0,
      executionTimeMs: Date.now() - startTime
    };

    console.log(`✅ [AdvancedExportService] Bezpieczny wynik:`, {
      filename: safeResult.filename,
      fileDataLength: safeResult.fileData.length,
      contentType: safeResult.contentType
    });

    return safeResult;

  } catch (error) {
    console.error(`❌ [AdvancedExportService] Błąd:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else {
      throw new HttpsError('internal', 'Błąd podczas eksportu', error.message);
    }
  }
});

/**
 * Pobiera dane inwestorów z bazy danych
 */
async function fetchInvestorsData(clientIds) {
  console.log(`📊 [fetchInvestorsData] Rozpoczynam pobieranie danych dla clientIds:`, clientIds);
  const investorsData = [];

  // Przetwarzaj w batches po 10 (limit Firestore)
  for (let i = 0; i < clientIds.length; i += 10) {
    const batchClientIds = clientIds.slice(i, i + 10);
    console.log(`📦 [fetchInvestorsData] Przetwarzam batch ${i / 10 + 1}: ${batchClientIds.length} klientów`);

    try {
      // Pobierz inwestycje dla tej partii
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', 'in', batchClientIds)
        .get();

      console.log(`📋 [fetchInvestorsData] Znaleziono ${investmentsSnapshot.docs.length} inwestycji w batchu`);

      // Grupuj po clientId
      const investmentsByClient = {};
      investmentsSnapshot.docs.forEach(doc => {
        const investment = { id: doc.id, ...doc.data() };
        const clientId = investment.clientId;

        if (!investmentsByClient[clientId]) {
          investmentsByClient[clientId] = [];
        }
        investmentsByClient[clientId].push(investment);
      });

      console.log(`👥 [fetchInvestorsData] Klienci z inwestycjami:`, Object.keys(investmentsByClient));

      // Stwórz podsumowania
      for (const clientId of batchClientIds) {
        const investments = investmentsByClient[clientId] || [];
        if (investments.length > 0) {
          const investorSummary = createInvestorSummary(clientId, investments);
          if (investorSummary) {
            investorsData.push(investorSummary);
            console.log(`✅ [fetchInvestorsData] Dodano inwestora: ${clientId} (${investments.length} inwestycji)`);
          }
        } else {
          console.log(`⚠️ [fetchInvestorsData] Brak inwestycji dla klienta: ${clientId}`);
        }
      }

    } catch (error) {
      console.error(`❌ [AdvancedExportService] Błąd batch'a:`, error);
    }
  }

  console.log(`🎯 [fetchInvestorsData] Końcowy wynik: ${investorsData.length} inwestorów`);
  return investorsData;
}

/**
 * Tworzy podsumowanie inwestora z indywidualnymi inwestycjami
 */
function createInvestorSummary(clientId, investments) {
  if (!investments || investments.length === 0) return null;

  /**
   * Mapuje angielskie nazwy typów produktów na polskie
   */
  function mapProductTypeToPolish(englishType) {
    const typeMapping = {
      'bonds': 'Obligacje',
      'shares': 'Akcje',
      'loans': 'Pożyczki',
      'apartments': 'Apartamenty',
      'Bonds': 'Obligacje',
      'Shares': 'Akcje',
      'Loans': 'Pożyczki',
      'Apartments': 'Apartamenty'
    };

    return typeMapping[englishType] || englishType || 'Nieznany typ';
  }

  const firstInvestment = investments[0];

  // Podstawowe dane
  const clientName = safeToString(
    firstInvestment.clientName ||
    firstInvestment.imie_nazwisko ||
    'Nieznany klient'
  );

  // Przygotuj szczegóły każdej inwestycji zgodnie z formatem:
  // clientName - productName - investmentType
  const investmentDetails = investments.map(inv => {
    const productName = safeToString(inv.productName || inv.nazwa_produktu || 'Nieznany produkt');
    const rawInvestmentType = safeToString(inv.productType || inv.typ_produktu || 'Nieznany typ');
    const investmentType = mapProductTypeToPolish(rawInvestmentType); // Mapowanie na polskie nazwy
    const investmentEntryDate = inv.signingDate || inv.data_podpisania || inv.Data_podpisania || null;
    const investmentAmount = safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0);
    const remainingCapital = safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0);
    const capitalSecuredByRealEstate = safeToDouble(inv.capitalSecuredByRealEstate || inv.kapital_zabezpieczony_nieruchomoscami || 0);
    const capitalForRestructuring = safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0);

    return {
      // Format: clientName - productName - investmentType
      displayName: `${clientName} - ${productName} - ${investmentType}`,
      clientName,
      productName,
      investmentType,
      investmentEntryDate: investmentEntryDate ? new Date(investmentEntryDate).toLocaleDateString('pl-PL') : 'Brak daty',
      investmentAmount,
      remainingCapital,
      capitalSecuredByRealEstate,
      capitalForRestructuring,
      investmentId: inv.id
    };
  });

  // Obliczenia finansowe (sumy)
  let totalInvestment = 0;
  let totalRemaining = 0;
  let totalRealized = 0;
  let totalSecured = 0;
  let totalForRestructuring = 0;

  const productTypes = new Set();
  const statuses = new Set();

  investments.forEach(inv => {
    totalInvestment += safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0);
    totalRemaining += safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0);
    totalRealized += safeToDouble(inv.realizedCapital || inv.kapital_zrealizowany || 0);
    totalSecured += safeToDouble(inv.capitalSecuredByRealEstate || 0);
    totalForRestructuring += safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0);

    if (inv.productType) productTypes.add(inv.productType);
    if (inv.status) statuses.add(inv.status);
  });

  return {
    clientId,
    clientName,
    investmentCount: investments.length,
    totalInvestmentAmount: totalInvestment,
    totalRemainingCapital: totalRemaining,
    totalRealizedCapital: totalRealized,
    totalSecuredCapital: totalSecured,
    totalCapitalForRestructuring: totalForRestructuring,
    productTypes: Array.from(productTypes),
    statuses: Array.from(statuses),
    investmentDetails, // 🚀 NOWE: Szczegóły każdej inwestycji
    investments: investments,
    performanceRate: totalInvestment > 0 ? ((totalRealized / totalInvestment) * 100) : 0,
    riskLevel: calculateRiskLevel(totalSecured, totalRemaining)
  };
}

/**
 * Oblicza poziom ryzyka
 */
function calculateRiskLevel(secured, remaining) {
  if (remaining === 0) return 'BRAK';
  const securityRatio = secured / remaining;

  if (securityRatio >= 0.8) return 'NISKIE';
  if (securityRatio >= 0.5) return 'ŚREDNIE';
  return 'WYSOKIE';
}

/**
 * Generuje eksport PDF
 */
async function generatePDFExport(investorsData, templateType, options, currentDate) {
  console.log(`📄 [AdvancedExportService] Generuję prawdziwy PDF dla ${investorsData.length} inwestorów`);

  try {
    const PDFDocument = require('pdfkit');
    const path = require('path');

    const doc = new PDFDocument({
      bufferPages: true,
      compress: false,
      info: {
        Title: 'Metropolitan Investment - Raport Inwestorów',
        Author: 'Metropolitan Investment',
        CreationDate: new Date()
      }
    });

    // Konfiguracja polskiego fontu dla obsługi znaków diakrytycznych
    let fontRegistered = false;
    try {
      const fontBasePath = path.join(__dirname, '../assets/fonts');
      const fs = require('fs');

      // Sprawdź czy katalog fontów istnieje, jeśli nie - skopiuj z głównego projektu
      if (!fs.existsSync(fontBasePath)) {
        const sourceFontPath = path.join(__dirname, '../../assets/fonts');
        if (fs.existsSync(sourceFontPath)) {
          fs.mkdirSync(fontBasePath, { recursive: true });

          // Skopiuj potrzebne fonty
          const fontsToCopy = ['Montserrat-Regular.ttf', 'Montserrat-Bold.ttf', 'Montserrat-Medium.ttf'];
          fontsToCopy.forEach(fontFile => {
            const source = path.join(sourceFontPath, fontFile);
            const target = path.join(fontBasePath, fontFile);
            if (fs.existsSync(source)) {
              fs.copyFileSync(source, target);
            }
          });
          console.log('✅ [AdvancedExportService] Fonty Montserrat skopiowane do functions');
        }
      }

      // Rejestruj różne style fontów
      const regularFont = path.join(fontBasePath, 'Montserrat-Regular.ttf');
      const boldFont = path.join(fontBasePath, 'Montserrat-Bold.ttf');
      const mediumFont = path.join(fontBasePath, 'Montserrat-Medium.ttf');

      if (fs.existsSync(regularFont)) {
        doc.registerFont('Montserrat', regularFont);
        if (fs.existsSync(boldFont)) {
          doc.registerFont('Montserrat-Bold', boldFont);
        }
        if (fs.existsSync(mediumFont)) {
          doc.registerFont('Montserrat-Medium', mediumFont);
        }
        doc.font('Montserrat');
        fontRegistered = true;
        console.log('✅ [AdvancedExportService] Fonty Montserrat zarejestrowane dla polskich znaków');
      }
    } catch (fontError) {
      console.warn('⚠️ [AdvancedExportService] Błąd ładowania fontów:', fontError.message);
    }

    // Fallback na domyślny font jeśli Montserrat niedostępny
    if (!fontRegistered) {
      console.warn('⚠️ [AdvancedExportService] Używam domyślnego fontu Helvetica');
      doc.font('Helvetica');
    }

    // Buffer do zbierania danych PDF
    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));

    // Nagłówek dokumentu
    doc.font(fontRegistered ? 'Montserrat-Bold' : 'Helvetica-Bold').fontSize(20).text('METROPOLITAN INVESTMENT', 50, 50);
    doc.font(fontRegistered ? 'Montserrat-Medium' : 'Helvetica').fontSize(16).text(`Raport Inwestorów`, 50, 80);
    doc.font(fontRegistered ? 'Montserrat' : 'Helvetica').fontSize(12).text(`Data generowania: ${new Date().toLocaleString('pl-PL')}`, 50, 110);
    doc.text(`Liczba inwestorów: ${investorsData.length}`, 50, 130);

    let yPosition = 160;

    // Dane inwestorów
    investorsData.forEach((investor, index) => {
      // Sprawdź czy potrzebna nowa strona
      if (yPosition > 700) {
        doc.addPage();
        yPosition = 50;
      }

      // Informacje o inwestorze
      doc.font(fontRegistered ? 'Montserrat-Medium' : 'Helvetica-Bold').fontSize(14).text(`${index + 1}. INWESTOR: ${investor.clientName}`, 50, yPosition);
      yPosition += 30;

      doc.font(fontRegistered ? 'Montserrat' : 'Helvetica').fontSize(12).text(`INWESTYCJE (${investor.investmentCount}):`, 50, yPosition);
      yPosition += 20;

      // Szczegóły inwestycji
      investor.investmentDetails.forEach((detail, idx) => {
        if (yPosition > 700) {
          doc.addPage();
          yPosition = 50;
        }

        doc.font(fontRegistered ? 'Montserrat-Medium' : 'Helvetica').fontSize(11).text(`${idx + 1}. ${detail.displayName}`, 70, yPosition);
        yPosition += 15;

        doc.font(fontRegistered ? 'Montserrat' : 'Helvetica').fontSize(9)
          .text(`Data wejścia: ${detail.investmentEntryDate}`, 90, yPosition)
          .text(`Kwota inwestycji: ${detail.investmentAmount.toLocaleString('pl-PL')} PLN`, 90, yPosition + 12)
          .text(`Kapitał pozostały: ${detail.remainingCapital.toLocaleString('pl-PL')} PLN`, 90, yPosition + 24)
          .text(`Kapitał zabezpieczony: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL')} PLN`, 90, yPosition + 36)
          .text(`Do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL')} PLN`, 90, yPosition + 48);

        yPosition += 70;
      });

      // Podsumowanie inwestora
      doc.font(fontRegistered ? 'Montserrat' : 'Helvetica').fontSize(10).text(`Łączna kwota: ${investor.totalInvestmentAmount.toLocaleString('pl-PL')} PLN`, 70, yPosition);
      yPosition += 30;
    });

    // Zakończ dokument
    doc.end();

    // Czekaj na zakończenie i zwróć dane
    return new Promise((resolve, reject) => {
      doc.on('end', () => {
        try {
          const pdfBuffer = Buffer.concat(buffers);
          const base64Content = pdfBuffer.toString('base64');
          const filename = `PDF_metropolitan_${currentDate}.pdf`;

          console.log(`✅ [AdvancedExportService] PDF wygenerowany: ${pdfBuffer.length} bajtów`);

          resolve({
            filename,
            fileData: base64Content,
            downloadUrl: null,
            fileSize: pdfBuffer.length,
            contentType: 'application/pdf'
          });
        } catch (error) {
          reject(error);
        }
      });

      doc.on('error', reject);
    });

  } catch (error) {
    console.error(`❌ [AdvancedExportService] Błąd generowania PDF:`, error);

    // FALLBACK: Użyj tekstowy format z poprawnym content-type
    const textContent = generatePDFContent(investorsData, templateType, options);
    const base64Content = Buffer.from(textContent, 'utf8').toString('base64');
    const filename = `TXT_metropolitan_${currentDate}.txt`;

    return {
      filename,
      fileData: base64Content,
      downloadUrl: null,
      fileSize: textContent.length,
      contentType: 'text/plain'
    };
  }
}

/**
 * Generuje zawartość PDF z nowym formatem
 */
function generatePDFContent(investorsData, templateType, options) {
  const header = `
=== METROPOLITAN INVESTMENT ===
Raport Inwestorów 
Data generowania: ${new Date().toLocaleString('pl-PL')}
Liczba inwestorów: ${investorsData.length}

`;

  let content = header;

  investorsData.forEach((investor, index) => {
    content += `
${index + 1}. INWESTOR: ${investor.clientName}

   INWESTYCJE (${investor.investmentCount}):
`;

    // Dodaj szczegóły każdej inwestycji w nowym formacie
    investor.investmentDetails.forEach((detail, idx) => {
      content += `
   ${idx + 1}. ${detail.displayName}
      Data wejścia: ${detail.investmentEntryDate}
      Kwota inwestycji: ${detail.investmentAmount.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
      
      Kapitał pozostały: ${detail.remainingCapital.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
      Kapitał zabezpieczony nieruchomością: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
      Kapitał do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
`;
    });

    content += `
   PODSUMOWANIE INWESTORA:
   • Łączna kwota inwestycji: ${investor.totalInvestmentAmount.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   • Łączny kapitał pozostały: ${investor.totalRemainingCapital.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   • Łączny kapitał zabezpieczony: ${investor.totalSecuredCapital.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   • Łączny kapitał do restrukturyzacji: ${investor.totalCapitalForRestructuring.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   • Poziom ryzyka: ${investor.riskLevel}

`;
  });

  return content;
}

/**
 * Generuje eksport Excel
 */
async function generateExcelExport(investorsData, templateType, options, currentDate) {
  console.log(`📊 [AdvancedExportService] Generuję prawdziwy Excel dla ${investorsData.length} inwestorów`);

  try {
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Raport Inwestorów');

    // Nagłówki kolumn - podzielone na osobne kolumny w języku polskim
    const headers = [
      'Nazwisko / Nazwa firmy',
      'Nazwa produktu',
      'Typ produktu',
      'Data wejścia',
      'Kwota inwestycji (PLN)',
      'Kapitał pozostały (PLN)',
      'Kapitał zabezpieczony nieruchomością (PLN)',
      'Kapitał do restrukturyzacji (PLN)'
    ];

    // Dodaj nagłówki
    worksheet.addRow(headers);

    // Stylizuj nagłówki
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE6E6FA' }
    };

    // Dodaj dane - każde pole w osobnej kolumnie
    investorsData.forEach(investor => {
      investor.investmentDetails.forEach(detail => {
        worksheet.addRow([
          detail.clientName,           // Nazwisko / Nazwa firmy
          detail.productName,          // Nazwa produktu  
          detail.investmentType,       // Typ produktu
          detail.investmentEntryDate,  // Data wejścia
          detail.investmentAmount,     // Kwota inwestycji (PLN)
          detail.remainingCapital,     // Kapitał pozostały (PLN)
          detail.capitalSecuredByRealEstate, // Kapitał zabezpieczony nieruchomością (PLN)
          detail.capitalForRestructuring     // Kapitał do restrukturyzacji (PLN)
        ]);
      });
    });

    // Konfiguruj szerokości i formatowanie kolumn
    worksheet.columns = [
      { width: 25 }, // Nazwisko / Nazwa firmy
      { width: 30 }, // Nazwa produktu
      { width: 20 }, // Typ produktu  
      { width: 15 }, // Data wejścia
      { width: 20 }, // Kwota inwestycji (PLN)
      { width: 20 }, // Kapitał pozostały (PLN)
      { width: 25 }, // Kapitał zabezpieczony nieruchomością (PLN)
      { width: 25 }  // Kapitał do restrukturyzacji (PLN)
    ];

    // Formatowanie kolumn z kwotami jako waluty PLN
    const currencyFormat = '#,##0.00 "PLN"';

    // Zastosuj formatowanie waluty do kolumn z kwotami (kolumny 5-8)
    for (let i = 5; i <= 8; i++) {
      worksheet.getColumn(i).numFmt = currencyFormat;
    }

    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const filename = `Excel_metropolitan_${currentDate}.xlsx`;

    console.log(`✅ [AdvancedExportService] Excel wygenerowany: ${buffer.length} bajtów`);

    return {
      filename,
      fileData: base64Content,
      downloadUrl: null,
      fileSize: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

  } catch (error) {
    console.error(`❌ [AdvancedExportService] Błąd generowania Excel:`, error);

    // FALLBACK: Użyj CSV z poprawnym content-type
    const csvContent = generateExcelContent(investorsData, templateType, options);
    const base64Content = Buffer.from(csvContent, 'utf8').toString('base64');
    const filename = `CSV_metropolitan_${currentDate}.csv`;

    return {
      filename,
      fileData: base64Content,
      downloadUrl: null,
      fileSize: csvContent.length,
      contentType: 'text/csv'
    };
  }
}

/**
 * Generuje zawartość Excel z nowym formatem - podzielone kolumny
 */
function generateExcelContent(investorsData, templateType, options) {
  // Nagłówki zgodne z nowym formatem - podzielone kolumny w języku polskim
  let csvContent = 'Nazwisko / Nazwa firmy,Nazwa produktu,Typ produktu,Data wejścia,Kwota inwestycji (PLN),Kapitał pozostały (PLN),Kapitał zabezpieczony nieruchomością (PLN),Kapitał do restrukturyzacji (PLN)\n';

  investorsData.forEach(investor => {
    // Dodaj każdą inwestycję jako osobny wiersz z podzielonymi polami
    investor.investmentDetails.forEach(detail => {
      csvContent += `"${detail.clientName}","${detail.productName}","${detail.investmentType}","${detail.investmentEntryDate}",${detail.investmentAmount},${detail.remainingCapital},${detail.capitalSecuredByRealEstate},${detail.capitalForRestructuring}\n`;
    });
  });

  return csvContent;
}

/**
 * Generuje eksport Word
 */
async function generateWordExport(investorsData, templateType, options, currentDate) {
  console.log(`📝 [AdvancedExportService] Generuję prawdziwy Word dla ${investorsData.length} inwestorów`);

  try {
    const { Document, Packer, Paragraph, TextRun, HeadingLevel } = require('docx');

    // Tworzenie dokumentu
    const doc = new Document({
      sections: [{
        properties: {},
        children: [
          // Nagłówek dokumentu
          new Paragraph({
            heading: HeadingLevel.TITLE,
            children: [
              new TextRun({
                text: "METROPOLITAN INVESTMENT",
                bold: true,
                size: 32
              })
            ]
          }),

          new Paragraph({
            children: [
              new TextRun({
                text: `Raport Inwestorów`,
                bold: true,
                size: 24
              })
            ]
          }),

          new Paragraph({
            children: [
              new TextRun({
                text: `Data generowania: ${new Date().toLocaleString('pl-PL')}`,
                size: 20
              })
            ]
          }),

          new Paragraph({
            children: [
              new TextRun({
                text: `Liczba inwestorów: ${investorsData.length}`,
                size: 20
              })
            ]
          }),

          new Paragraph(""), // Pusty akapit

          // Dane inwestorów
          ...investorsData.flatMap((investor, index) => [
            new Paragraph({
              heading: HeadingLevel.HEADING_1,
              children: [
                new TextRun({
                  text: `${index + 1}. INWESTOR: ${investor.clientName}`,
                  bold: true
                })
              ]
            }),

            new Paragraph({
              children: [
                new TextRun({
                  text: `INWESTYCJE (${investor.investmentCount}):`,
                  bold: true
                })
              ]
            }),

            // Szczegóły inwestycji
            ...investor.investmentDetails.flatMap((detail, idx) => [
              new Paragraph({
                children: [
                  new TextRun({
                    text: `${idx + 1}. ${detail.displayName}`,
                    bold: true
                  })
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Data wejścia: ${detail.investmentEntryDate}`)
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Kwota inwestycji: ${detail.investmentAmount.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Kapitał pozostały: ${detail.remainingCapital.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Kapitał zabezpieczony nieruchomością: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Kapitał do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph(""), // Pusty akapit
            ]),

            // Podsumowanie inwestora
            new Paragraph({
              children: [
                new TextRun({
                  text: `PODSUMOWANIE: Łączna kwota inwestycji: ${investor.totalInvestmentAmount.toLocaleString('pl-PL')} PLN`,
                  bold: true
                })
              ]
            }),

            new Paragraph(""), // Separacja między inwestorami
          ])
        ]
      }]
    });

    // Generuj buffer
    const buffer = await Packer.toBuffer(doc);
    const base64Content = buffer.toString('base64');
    const filename = `Word_metropolitan_${currentDate}.docx`;

    console.log(`✅ [AdvancedExportService] Word wygenerowany: ${buffer.length} bajtów`);

    return {
      filename,
      fileData: base64Content,
      downloadUrl: null,
      fileSize: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    };

  } catch (error) {
    console.error(`❌ [AdvancedExportService] Błąd generowania Word:`, error);

    // FALLBACK: Użyj tekstowy format z poprawnym content-type
    const textContent = generateWordContent(investorsData, templateType, options);
    const base64Content = Buffer.from(textContent, 'utf8').toString('base64');
    const filename = `TXT_metropolitan_${currentDate}.txt`;

    return {
      filename,
      fileData: base64Content,
      downloadUrl: null,
      fileSize: textContent.length,
      contentType: 'text/plain'
    };
  }
}

/**
 * Generuje zawartość Word z nowym formatem
 */
function generateWordContent(investorsData, templateType, options) {
  let content = `METROPOLITAN INVESTMENT
Raport Inwestorów
Data: ${new Date().toLocaleString('pl-PL')}

`;

  investorsData.forEach((investor, index) => {
    content += `${index + 1}. INWESTOR: ${investor.clientName}

INWESTYCJE (${investor.investmentCount}):

`;

    investor.investmentDetails.forEach((detail, idx) => {
      content += `${idx + 1}. ${detail.displayName}
   Data wejścia: ${detail.investmentEntryDate}
   Kwota inwestycji: ${detail.investmentAmount.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   
   Kapitał pozostały: ${detail.remainingCapital.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   Kapitał zabezpieczony nieruchomością: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
   Kapitał do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}

`;
    });

    content += `PODSUMOWANIE:
Łączna kwota: ${investor.totalInvestmentAmount.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
Łączny kapitał pozostały: ${investor.totalRemainingCapital.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}
Poziom ryzyka: ${investor.riskLevel}

---

`;
  });

  return content;
}

/**
 * Zapisuje historię eksportu
 */
async function saveExportHistory(historyData) {
  try {
    await db.collection('advanced_export_history').add({
      ...historyData,
      status: 'completed'
    });
    console.log(`📝 [AdvancedExportService] Historia zapisana`);
  } catch (error) {
    console.warn(`⚠️ [AdvancedExportService] Błąd zapisu historii:`, error);
  }
}

module.exports = {
  exportInvestorsAdvanced
};

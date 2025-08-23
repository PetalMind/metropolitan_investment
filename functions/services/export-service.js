/**
 * Export Service - Eksport danych inwestorów
 * 
 * Serwis obsługujący eksport danych inwestorów do różnych formatów
 * (CSV, Excel, PDF) z możliwością wyboru konkretnych inwestorów.
 * 
 * 🎯 KLUCZOWE FUNKCJONALNOŚCI:
 * • Eksport listy wybranych inwestorów
 * • Generowanie raportów CSV/Excel
 * • Filtrowanie i sortowanie danych
 * • Bezpieczna obsługa danych osobowych
 * • Historia eksportów
 */

const { onRequest, onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const cors = require('cors')({ origin: true });
const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

// Import zaawansowanego serwisu eksportu dla PDF i Word
const advancedExportService = require('./advanced-export-service');

/**
 * Eksportuje dane wybranych inwestorów
 * 
 * @param {Object} data - Dane wejściowe
 * @param {string[]} data.clientIds - Lista ID klientów do eksportu
 * @param {string} data.exportFormat - Format eksportu ('csv'|'json'|'excel'|'pdf')
 * @param {string[]} data.includeFields - Pola do uwzględnienia w eksporcie
 * @param {Object} data.filters - Filtry danych (opcjonalnie)
 * @param {string} data.sortBy - Pole sortowania (opcjonalnie)
 * @param {boolean} data.sortDescending - Kierunek sortowania (opcjonalnie)
 * @param {string} data.exportTitle - Tytuł eksportu (opcjonalnie)
 * @param {string} data.requestedBy - Email osoby żądającej eksportu
 * @param {boolean} data.includePersonalData - Czy uwzględnić dane osobowe
 * 
 * @returns {Object} Dane eksportu lub URL do pobrania
 */
// Shared export implementation used by both callable and HTTP handlers
async function performExportLogic(requestData) {
  const startTime = Date.now();

  const {
    clientIds,
    exportFormat = 'csv',
    includeFields = ['clientName', 'totalInvestmentAmount', 'totalRemainingCapital', 'investmentCount'],
    filters = {},
    sortBy = 'totalRemainingCapital',
    sortDescending = true,
    exportTitle = 'Raport Inwestorów',
    requestedBy,
    includePersonalData = false
  } = requestData || {};

  // 🔍 VALIDATION
  if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
    throw new HttpsError('invalid-argument', 'Wymagana jest lista clientIds (niepusta tablica)');
  }

  if (clientIds.length > 1000) {
    throw new HttpsError('invalid-argument', 'Maksymalna liczba klientów w jednym eksporcie: 1000');
  }

  if (!requestedBy) {
    throw new HttpsError('unauthenticated', 'Wymagany jest requestedBy (email osoby żądającej)');
  }

  const supportedFormats = ['csv', 'json', 'excel', 'pdf', 'word'];
  if (!supportedFormats.includes(exportFormat)) {
    throw new HttpsError('invalid-argument', `Nieprawidłowy format eksportu. Dostępne: ${supportedFormats.join(', ')}`);
  }

  console.log(`🔍 [ExportService] Pobieram dane dla ${clientIds.length} klientów...`);

  const exportData = [];
  let totalProcessed = 0;
  let totalErrors = 0;

  for (let i = 0; i < clientIds.length; i += 10) {
    const batchClientIds = clientIds.slice(i, i + 10);

    try {
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', 'in', batchClientIds)
        .get();

      const investmentsByClient = {};
      investmentsSnapshot.docs.forEach(doc => {
        const investment = { id: doc.id, ...doc.data() };
        const clientId = investment.clientId;

        if (!investmentsByClient[clientId]) investmentsByClient[clientId] = [];
        investmentsByClient[clientId].push(investment);
      });

      for (const clientId of batchClientIds) {
        try {
          const clientInvestments = investmentsByClient[clientId] || [];
          if (clientInvestments.length === 0) {
            console.warn(`⚠️ [ExportService] Brak inwestycji dla klienta: ${clientId}`);
            continue;
          }

          const clientSummary = generateClientSummary(clientId, clientInvestments, includeFields, includePersonalData);
          if (passesFilters(clientSummary, filters)) exportData.push(clientSummary);
          totalProcessed++;
        } catch (clientError) {
          console.error(`❌ [ExportService] Błąd przetwarzania klienta ${clientId}:`, clientError);
          totalErrors++;
        }
      }
    } catch (batchError) {
      console.error(`❌ [ExportService] Błąd batch'a klientów:`, batchError);
      totalErrors += batchClientIds.length;
    }
  }

  if (exportData.length === 0) {
    throw new HttpsError('not-found', 'Nie znaleziono danych spełniających kryteria eksportu');
  }

  if (sortBy && exportData[0] && Object.prototype.hasOwnProperty.call(exportData[0], sortBy)) {
    exportData.sort((a, b) => {
      const aVal = a[sortBy] || 0;
      const bVal = b[sortBy] || 0;

      if (typeof aVal === 'string') {
        return sortDescending ? bVal.localeCompare(aVal, 'pl-PL') : aVal.localeCompare(bVal, 'pl-PL');
      }
      return sortDescending ? bVal - aVal : aVal - bVal;
    });
  }

  let exportResult;
  switch (exportFormat) {
    case 'csv':
      exportResult = generateCSVExport(exportData, exportTitle);
      break;
    case 'json':
      exportResult = generateJSONExport(exportData, exportTitle);
      break;
    case 'excel':
      exportResult = await generateExcelExport(exportData, exportTitle);
      break;
    case 'pdf':
      exportResult = await generateAdvancedExport(clientIds, 'pdf', exportTitle, requestedBy);
      break;
    case 'word':
      exportResult = await generateAdvancedExport(clientIds, 'word', exportTitle, requestedBy);
      break;
    default:
      throw new HttpsError('invalid-argument', `Nieobsługiwany format: ${exportFormat}`);
  }

  const historyRecord = {
    requestedBy,
    exportFormat,
    clientCount: exportData.length,
    totalProcessed,
    totalErrors,
    includeFields,
    filters,
    sortBy,
    sortDescending,
    includePersonalData,
    exportTitle,
    executedAt: new Date(),
    executionTimeMs: Date.now() - startTime,
    status: 'completed'
  };

  try {
    await db.collection('export_history').add(historyRecord);
    console.log(`📝 [ExportService] Historia eksportu zapisana`);
  } catch (historyError) {
    console.warn(`⚠️ [ExportService] Nie udało się zapisać historii:`, historyError);
  }

  const result = {
    success: true,
    format: exportFormat,
    recordCount: exportData.length,
    totalProcessed,
    totalErrors,
    executionTimeMs: Date.now() - startTime,
    exportTitle,
    data: exportResult.data,
    filename: exportResult.filename,
    size: exportResult.size || null
  };

  console.log(`🎉 [ExportService] Eksport zakończony pomyślnie w ${Date.now() - startTime}ms`);

  return result;
}

// Callable (existing) function - keep name and callable shape to avoid changing deployed trigger
const exportInvestorsData = onCall({ memory: '2GiB', timeoutSeconds: 540 }, async (req) => {
  const requestData = req.data || {};
  try {
    const result = await performExportLogic(requestData);
    return result;
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    console.error('❌ [ExportService] Błąd w exportInvestorsData (callable):', err);
    throw new HttpsError('internal', 'Błąd podczas eksportu danych', err.message || String(err));
  }
});

// New HTTP function with CORS handling - non-destructive additional endpoint
const exportInvestorsDataHttp = onRequest({ memory: '2GiB', timeoutSeconds: 540 }, async (req, res) => {
  cors(req, res, async () => {
    const requestData = (req.body && req.body.data) ? req.body.data : req.body || {};
    try {
      const result = await performExportLogic(requestData);
      return res.status(200).json({ result });
    } catch (error) {
      console.error('❌ [ExportService] Błąd podczas eksportu (http):', error);
      if (error instanceof HttpsError) {
        const codeMap = { 'invalid-argument': 400, 'unauthenticated': 401, 'not-found': 404, 'permission-denied': 403 };
        const status = codeMap[error.code] || 500;
        return res.status(status).json({ error: { code: error.code, message: error.message } });
      }
      return res.status(500).json({ error: { message: error.message || 'Błąd podczas eksportu danych' } });
    }
  });
});

/**
 * Generuje podsumowanie dla jednego klienta
 */
function generateClientSummary(clientId, investments, includeFields, includePersonalData) {
  if (!investments || investments.length === 0) {
    return null;
  }

  // Podstawowe informacje o kliencie (z pierwszej inwestycji)
  const firstInvestment = investments[0];
  const clientName = safeToString(firstInvestment.clientName || firstInvestment.imie_nazwisko || 'Nieznany klient');

  // Oblicz sumy finansowe
  let totalInvestmentAmount = 0;
  let totalRemainingCapital = 0;
  let totalRealizedCapital = 0;
  let totalCapitalSecured = 0;
  let totalCapitalForRestructuring = 0;

  const productTypes = new Set();
  const companies = new Set();
  const statuses = new Set();

  investments.forEach(investment => {
    totalInvestmentAmount += safeToDouble(investment.investmentAmount || investment.kwota_inwestycji || 0);
    totalRemainingCapital += safeToDouble(investment.remainingCapital || investment.kapital_pozostaly || 0);
    totalRealizedCapital += safeToDouble(investment.realizedCapital || investment.kapital_zrealizowany || 0);
    totalCapitalSecured += safeToDouble(investment.capitalSecuredByRealEstate || investment.kapital_zabezpieczony_nieruchomoscami || 0);
    totalCapitalForRestructuring += safeToDouble(investment.capitalForRestructuring || investment.kapital_do_restrukturyzacji || 0);

    if (investment.productType) productTypes.add(investment.productType);
    if (investment.creditorCompany || investment.companyId) companies.add(investment.creditorCompany || investment.companyId);
    if (investment.status) statuses.add(investment.status);
  });

  // Bazowe dane
  const summary = {
    clientId,
    clientName,
    investmentCount: investments.length,
    totalInvestmentAmount,
    totalRemainingCapital,
    totalRealizedCapital,
    totalCapitalSecured,
    totalCapitalForRestructuring,
    productTypes: Array.from(productTypes).join(', '),
    companies: Array.from(companies).join(', '),
    statuses: Array.from(statuses).join(', ')
  };

  // Dodaj dane osobowe jeśli wymagane
  if (includePersonalData) {
    summary.personalData = {
      email: firstInvestment.email || '',
      phone: firstInvestment.telefon || firstInvestment.phone || '',
      address: firstInvestment.adres || firstInvestment.address || '',
      pesel: firstInvestment.pesel || '',
      nip: firstInvestment.nip || ''
    };
  }

  // Filtruj pola według includeFields
  const filteredSummary = {};
  includeFields.forEach(field => {
    if (summary.hasOwnProperty(field)) {
      filteredSummary[field] = summary[field];
    }
  });

  // Dodaj zawsze clientId dla identyfikacji
  filteredSummary.clientId = clientId;

  return filteredSummary;
}

/**
 * Sprawdza czy rekord przechodzi przez filtry
 */
function passesFilters(record, filters) {
  if (!filters || Object.keys(filters).length === 0) {
    return true;
  }

  for (const [field, criteria] of Object.entries(filters)) {
    const value = record[field];

    if (criteria.min !== undefined && (value == null || value < criteria.min)) {
      return false;
    }
    if (criteria.max !== undefined && (value == null || value > criteria.max)) {
      return false;
    }
    if (criteria.equals !== undefined && value !== criteria.equals) {
      return false;
    }
    if (criteria.contains !== undefined && (!value || !value.toString().toLowerCase().includes(criteria.contains.toLowerCase()))) {
      return false;
    }
  }

  return true;
}

/**
 * Generuje eksport CSV
 */
function generateCSVExport(data, title) {
  if (data.length === 0) {
    return { data: '', filename: `${title}.csv`, size: 0 };
  }

  const headers = Object.keys(data[0]);
  const csvContent = [
    `"${title} - ${new Date().toLocaleString('pl-PL')}"`,
    '',
    headers.map(h => `"${h}"`).join(','),
    ...data.map(row =>
      headers.map(h => {
        const value = row[h];
        if (typeof value === 'number') {
          return value.toString().replace('.', ','); // Polski format liczb
        }
        return `"${(value || '').toString().replace(/"/g, '""')}"`;
      }).join(',')
    )
  ].join('\n');

  return {
    data: Buffer.from(csvContent, 'utf8').toString('base64'),
    filename: `${title}_${new Date().toISOString().split('T')[0]}.csv`,
    size: csvContent.length,
    contentType: 'text/csv'
  };
}

/**
 * Generuje eksport JSON
 */
function generateJSONExport(data, title) {
  const exportObj = {
    title,
    generatedAt: new Date().toISOString(),
    recordCount: data.length,
    data
  };

  const jsonString = JSON.stringify(exportObj, null, 2);

  return {
    data: Buffer.from(jsonString, 'utf8').toString('base64'),
    filename: `${title}_${new Date().toISOString().split('T')[0]}.json`,
    size: jsonString.length,
    contentType: 'application/json'
  };
}

/**
 * Generuje eksport Excel z prawdziwą biblioteką ExcelJS
 */
async function generateExcelExport(data, title) {
  try {
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Raport Inwestorów');

    if (data.length === 0) {
      return { data: '', filename: `${title}.xlsx`, size: 0 };
    }

    // Nagłówki
    const headers = Object.keys(data[0]);
    worksheet.addRow(headers);

    // Stylizuj nagłówki
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE6E6FA' }
    };

    // Dodaj dane
    data.forEach(row => {
      const rowValues = headers.map(h => row[h]);
      worksheet.addRow(rowValues);
    });

    // Konfiguruj szerokości kolumn
    worksheet.columns.forEach(column => {
      column.width = 20;
    });

    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();

    console.log(`✅ [ExportService] Excel wygenerowany: ${buffer.length} bajtów`);

    return {
      data: buffer.toString('base64'),
      filename: `${title}_${new Date().toISOString().split('T')[0]}.xlsx`,
      size: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

  } catch (error) {
    console.error('❌ [ExportService] Błąd generowania Excel:', error);

    // FALLBACK: Użyj CSV z poprawnym rozszerzeniem
    console.warn('⚠️ [ExportService] Excel export nie jest dostępny, zwracam CSV');
    const csvResult = generateCSVExport(data, title);

    return {
      data: Buffer.from(csvResult.data, 'utf8').toString('base64'),
      filename: csvResult.filename.replace('.csv', '.xlsx'),
      size: csvResult.size,
      contentType: 'text/csv'
    };
  }
}

/**
 * Generuje zaawansowany eksport (PDF/Word) bezpośrednio
 */
async function generateAdvancedExport(clientIds, format, title, requestedBy) {
  console.log(`🚀 [ExportService] Generuję zaawansowany eksport ${format} dla ${clientIds.length} klientów`);

  try {
    // Pobierz dane inwestorów bezpośrednio
    const investorsData = await fetchAdvancedInvestorsData(clientIds);

    if (investorsData.length === 0) {
      throw new Error('Nie znaleziono danych inwestorów');
    }

    const currentDate = new Date().toISOString().split('T')[0];

    // Generuj eksport w zależności od formatu
    switch (format) {
      case 'pdf':
        return await generateAdvancedPDFExport(investorsData, title, currentDate);
      case 'word':
        return await generateAdvancedWordExport(investorsData, title, currentDate);
      default:
        throw new Error(`Nieobsługiwany format: ${format}`);
    }

  } catch (error) {
    console.error(`❌ [ExportService] Błąd zaawansowanego eksportu ${format}:`, error);

    // Fallback: generuj prosty tekstowy eksport
    const fallbackContent = generateFallbackContent(clientIds, format, title);
    const base64Content = Buffer.from(fallbackContent, 'utf8').toString('base64');

    return {
      data: base64Content,
      filename: `${format}_fallback_${new Date().toISOString().split('T')[0]}.txt`,
      size: fallbackContent.length,
      contentType: 'text/plain'
    };
  }
}

/**
 * Pobiera dane inwestorów dla zaawansowanego eksportu
 */
async function fetchAdvancedInvestorsData(clientIds) {
  const investorsData = [];

  // Przetwarzaj w batches po 10 (limit Firestore)
  for (let i = 0; i < clientIds.length; i += 10) {
    const batchClientIds = clientIds.slice(i, i + 10);

    try {
      // Pobierz inwestycje dla tej partii
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', 'in', batchClientIds)
        .get();

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

      // Stwórz podsumowania
      for (const clientId of batchClientIds) {
        const investments = investmentsByClient[clientId] || [];
        if (investments.length > 0) {
          const investorSummary = createAdvancedInvestorSummary(clientId, investments);
          if (investorSummary) {
            investorsData.push(investorSummary);
          }
        }
      }

    } catch (error) {
      console.error(`❌ [ExportService] Błąd batch'a:`, error);
    }
  }

  return investorsData;
}

/**
 * Tworzy zaawansowane podsumowanie inwestora
 */
function createAdvancedInvestorSummary(clientId, investments) {
  if (!investments || investments.length === 0) return null;

  const firstInvestment = investments[0];
  const clientName = safeToString(
    firstInvestment.clientName ||
    firstInvestment.imie_nazwisko ||
    'Nieznany klient'
  );

  // Mapowanie typów produktów na polskie nazwy
  function mapProductTypeToPolish(englishType) {
    const typeMapping = {
      'bonds': 'Obligacje',
      'shares': 'Akcje',
      'loans': 'Pożyczki',
      'apartments': 'Apartamenty'
    };
    return typeMapping[englishType] || englishType || 'Nieznany typ';
  }

  // Przygotuj szczegóły każdej inwestycji
  const investmentDetails = investments.map(inv => {
    const productName = safeToString(inv.productName || inv.nazwa_produktu || 'Nieznany produkt');
    const rawInvestmentType = safeToString(inv.productType || inv.typ_produktu || 'Nieznany typ');
    const investmentType = mapProductTypeToPolish(rawInvestmentType);
    const investmentEntryDate = inv.signingDate || inv.data_podpisania || inv.Data_podpisania || null;

    return {
      displayName: `${clientName} - ${productName} - ${investmentType}`,
      clientName,
      productName,
      investmentType,
      investmentEntryDate: investmentEntryDate ? new Date(investmentEntryDate).toLocaleDateString('pl-PL') : 'Brak daty',
      investmentAmount: safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0),
      remainingCapital: safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0),
      capitalSecuredByRealEstate: safeToDouble(inv.capitalSecuredByRealEstate || inv.kapital_zabezpieczony_nieruchomoscami || 0),
      capitalForRestructuring: safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0),
      investmentId: inv.id
    };
  });

  // Obliczenia finansowe
  let totalInvestment = 0;
  let totalRemaining = 0;
  let totalSecured = 0;
  let totalForRestructuring = 0;

  investments.forEach(inv => {
    totalInvestment += safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0);
    totalRemaining += safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0);
    totalSecured += safeToDouble(inv.capitalSecuredByRealEstate || 0);
    totalForRestructuring += safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0);
  });

  return {
    clientId,
    clientName,
    investmentCount: investments.length,
    totalInvestmentAmount: totalInvestment,
    totalRemainingCapital: totalRemaining,
    totalSecuredCapital: totalSecured,
    totalCapitalForRestructuring: totalForRestructuring,
    investmentDetails
  };
}

/**
 * Generuje zaawansowany eksport PDF
 */
async function generateAdvancedPDFExport(investorsData, title, currentDate) {
  try {
    const PDFDocument = require('pdfkit');

    const doc = new PDFDocument({
      bufferPages: true,
      compress: false,
      info: {
        Title: 'Metropolitan Investment - Raport Inwestorów',
        Author: 'Metropolitan Investment',
        CreationDate: new Date()
      }
    });

    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));

    // Nagłówek dokumentu
    doc.font('Helvetica-Bold').fontSize(20).text('METROPOLITAN INVESTMENT', 50, 50);
    doc.font('Helvetica').fontSize(16).text(`${title}`, 50, 80);
    doc.fontSize(12).text(`Data generowania: ${new Date().toLocaleString('pl-PL')}`, 50, 110);
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
      doc.font('Helvetica-Bold').fontSize(14).text(`${index + 1}. INWESTOR: ${investor.clientName}`, 50, yPosition);
      yPosition += 30;

      doc.font('Helvetica').fontSize(12).text(`INWESTYCJE (${investor.investmentCount}):`, 50, yPosition);
      yPosition += 20;

      // Szczegóły inwestycji
      investor.investmentDetails.forEach((detail, idx) => {
        if (yPosition > 700) {
          doc.addPage();
          yPosition = 50;
        }

        doc.font('Helvetica-Bold').fontSize(11).text(`${idx + 1}. ${detail.displayName}`, 70, yPosition);
        yPosition += 15;

        doc.font('Helvetica').fontSize(9)
          .text(`Data wejścia: ${detail.investmentEntryDate}`, 90, yPosition)
          .text(`Kwota inwestycji: ${detail.investmentAmount.toLocaleString('pl-PL')} PLN`, 90, yPosition + 12)
          .text(`Kapitał pozostały: ${detail.remainingCapital.toLocaleString('pl-PL')} PLN`, 90, yPosition + 24)
          .text(`Kapitał zabezpieczony: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL')} PLN`, 90, yPosition + 36)
          .text(`Do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL')} PLN`, 90, yPosition + 48);

        yPosition += 70;
      });

      // Podsumowanie inwestora
      doc.font('Helvetica').fontSize(10).text(`Łączna kwota: ${investor.totalInvestmentAmount.toLocaleString('pl-PL')} PLN`, 70, yPosition);
      yPosition += 30;
    });

    doc.end();

    return new Promise((resolve, reject) => {
      doc.on('end', () => {
        try {
          const pdfBuffer = Buffer.concat(buffers);
          const base64Content = pdfBuffer.toString('base64');
          const filename = `PDF_metropolitan_${currentDate}.pdf`;

          resolve({
            data: base64Content,
            filename,
            size: pdfBuffer.length,
            contentType: 'application/pdf'
          });
        } catch (error) {
          reject(error);
        }
      });

      doc.on('error', reject);
    });

  } catch (error) {
    console.error(`❌ [ExportService] Błąd generowania PDF:`, error);
    throw error;
  }
}

/**
 * Generuje zaawansowany eksport Word
 */
async function generateAdvancedWordExport(investorsData, title, currentDate) {
  try {
    const { Document, Packer, Paragraph, TextRun, HeadingLevel } = require('docx');

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
                text: `${title}`,
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
                  new TextRun(`Kapitał zabezpieczony: ${detail.capitalSecuredByRealEstate.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph({
                children: [
                  new TextRun(`Do restrukturyzacji: ${detail.capitalForRestructuring.toLocaleString('pl-PL')} PLN`)
                ]
              }),

              new Paragraph(""), // Pusty akapit
            ]),

            // Podsumowanie inwestora
            new Paragraph({
              children: [
                new TextRun({
                  text: `Łączna kwota: ${investor.totalInvestmentAmount.toLocaleString('pl-PL')} PLN`,
                  bold: true
                })
              ]
            }),

            new Paragraph(""), // Separacja między inwestorami
          ])
        ]
      }]
    });

    const buffer = await Packer.toBuffer(doc);
    const base64Content = buffer.toString('base64');
    const filename = `Word_metropolitan_${currentDate}.docx`;

    return {
      data: base64Content,
      filename,
      size: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    };

  } catch (error) {
    console.error(`❌ [ExportService] Błąd generowania Word:`, error);
    throw error;
  }
}/**
 * Generuje fallback content gdy zaawansowany eksport nie działa
 */
function generateFallbackContent(clientIds, format, title) {
  return `METROPOLITAN INVESTMENT - ${title.toUpperCase()}
Format: ${format.toUpperCase()}
Data: ${new Date().toLocaleString('pl-PL')}

Eksport danych dla ${clientIds.length} klientów:
${clientIds.map((id, index) => `${index + 1}. Client ID: ${id}`).join('\n')}

UWAGA: To jest uproszczony eksport. 
Pełne dane będą dostępne po naprawie systemu eksportu.
`;
}

module.exports = {
  exportInvestorsData,
  exportInvestorsDataHttp, // 🚀 DODANE: Eksport funkcji HTTP z CORS
};

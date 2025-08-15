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

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

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
const exportInvestorsData = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const startTime = Date.now();
  console.log(`📤 [ExportService] Rozpoczynam eksport danych inwestorów`);
  console.log(`📊 [ExportService] Dane wejściowe:`, JSON.stringify(request.data, null, 2));

  try {
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
    } = request.data;

    // 🔍 WALIDACJA DANYCH WEJŚCIOWYCH
    if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Wymagana jest lista clientIds (niepusta tablica)'
      );
    }

    if (clientIds.length > 1000) {
      throw new HttpsError(
        'invalid-argument',
        'Maksymalna liczba klientów w jednym eksporcie: 1000'
      );
    }

    if (!requestedBy) {
      throw new HttpsError(
        'unauthenticated',
        'Wymagany jest requestedBy (email osoby żądającej)'
      );
    }

    const supportedFormats = ['csv', 'json', 'excel'];
    if (!supportedFormats.includes(exportFormat)) {
      throw new HttpsError(
        'invalid-argument',
        `Nieprawidłowy format eksportu. Dostępne: ${supportedFormats.join(', ')}`
      );
    }

    // 🔍 POBIERZ DANE KLIENTÓW I ICH INWESTYCJE
    console.log(`🔍 [ExportService] Pobieram dane dla ${clientIds.length} klientów...`);

    const exportData = [];
    let totalProcessed = 0;
    let totalErrors = 0;

    // Przetwórz klientów w batch'ach po 10 (limit Firestore 'in' query)
    for (let i = 0; i < clientIds.length; i += 10) {
      const batchClientIds = clientIds.slice(i, i + 10);

      try {
        // Pobierz inwestycje dla tej partii klientów
        const investmentsSnapshot = await db.collection('investments')
          .where('clientId', 'in', batchClientIds)
          .get();

        // Grupuj inwestycje według clientId
        const investmentsByClient = {};
        investmentsSnapshot.docs.forEach(doc => {
          const investment = { id: doc.id, ...doc.data() };
          const clientId = investment.clientId;

          if (!investmentsByClient[clientId]) {
            investmentsByClient[clientId] = [];
          }
          investmentsByClient[clientId].push(investment);
        });

        // Stwórz podsumowania dla każdego klienta
        for (const clientId of batchClientIds) {
          try {
            const clientInvestments = investmentsByClient[clientId] || [];

            if (clientInvestments.length === 0) {
              console.warn(`⚠️ [ExportService] Brak inwestycji dla klienta: ${clientId}`);
              continue;
            }

            const clientSummary = generateClientSummary(clientId, clientInvestments, includeFields, includePersonalData);

            // Zastosuj filtry
            if (passesFilters(clientSummary, filters)) {
              exportData.push(clientSummary);
            }

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
      throw new HttpsError(
        'not-found',
        'Nie znaleziono danych spełniających kryteria eksportu'
      );
    }

    console.log(`✅ [ExportService] Przetworzono ${totalProcessed} klientów, błędów: ${totalErrors}, eksportowanych: ${exportData.length}`);

    // 🔄 SORTOWANIE DANYCH
    if (sortBy && exportData[0] && exportData[0].hasOwnProperty(sortBy)) {
      exportData.sort((a, b) => {
        const aVal = a[sortBy] || 0;
        const bVal = b[sortBy] || 0;

        if (typeof aVal === 'string') {
          return sortDescending
            ? bVal.localeCompare(aVal, 'pl-PL')
            : aVal.localeCompare(bVal, 'pl-PL');
        } else {
          return sortDescending ? bVal - aVal : aVal - bVal;
        }
      });
    }

    // 📤 GENERUJ EKSPORT W WYMAGANYM FORMACIE
    let exportResult;

    switch (exportFormat) {
      case 'csv':
        exportResult = generateCSVExport(exportData, exportTitle);
        break;
      case 'json':
        exportResult = generateJSONExport(exportData, exportTitle);
        break;
      case 'excel':
        exportResult = generateExcelExport(exportData, exportTitle);
        break;
      default:
        throw new HttpsError('invalid-argument', `Nieobsługiwany format: ${exportFormat}`);
    }

    // 📝 ZAPISZ HISTORIĘ EKSPORTU
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

    // 🎯 ZWRÓĆ WYNIK
    const result = {
      success: true,
      format: exportFormat,
      recordCount: exportData.length,
      totalProcessed,
      totalErrors,
      executionTimeMs: Date.now() - startTime,
      exportTitle,
      data: exportResult.data, // Dane lub URL do pobrania
      filename: exportResult.filename,
      size: exportResult.size || null
    };

    console.log(`🎉 [ExportService] Eksport zakończony pomyślnie w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error(`❌ [ExportService] Błąd podczas eksportu:`, error);

    if (error instanceof HttpsError) {
      throw error;
    } else {
      throw new HttpsError(
        'internal',
        'Błąd podczas eksportu danych',
        error.message
      );
    }
  }
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
    data: csvContent,
    filename: `${title}_${new Date().toISOString().split('T')[0]}.csv`,
    size: csvContent.length
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
    data: jsonString,
    filename: `${title}_${new Date().toISOString().split('T')[0]}.json`,
    size: jsonString.length
  };
}

/**
 * Generuje eksport Excel (placeholder - wymagałby dodatkowych bibliotek)
 */
function generateExcelExport(data, title) {
  // Dla uproszczenia, zwracamy CSV z extensionem .xlsx
  // W produkcji należy użyć biblioteki jak 'xlsx' lub 'exceljs'

  console.warn('⚠️ [ExportService] Excel export nie jest w pełni zaimplementowany, zwracam CSV');
  const csvResult = generateCSVExport(data, title);

  return {
    data: csvResult.data,
    filename: csvResult.filename.replace('.csv', '.xlsx'),
    size: csvResult.size
  };
}

module.exports = {
  exportInvestorsData,
};

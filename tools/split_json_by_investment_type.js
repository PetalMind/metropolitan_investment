#!/usr/bin/env node

/**
 * Skrypt do podziału JSON-a na różne typy inwestycji zgodnie z modelami Flutter
 * Rozszerza dane o odpowiednie pola wymagane przez modele
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Ścieżka do pliku źródłowego JSON
const INPUT_FILE = process.argv[2] || 'tableConvert.com_n0b2g7.json';
const OUTPUT_DIR = 'split_investment_data';

// Sprawdź czy plik wejściowy istnieje
if (!fs.existsSync(INPUT_FILE)) {
  process.exit(1);
}

// Utwórz katalog wyjściowy jeśli nie istnieje
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Funkcje pomocnicze
function safeParseNumber(value, defaultValue = 0.0) {
  if (value === null || value === undefined) return defaultValue;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    // Usuń przecinki z formatowania liczb (np. "305,700.00" -> "305700.00")
    const cleaned = value.replace(/,/g, '');
    const parsed = parseFloat(cleaned);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}

function generateId() {
  return uuidv4();
}

function getCurrentTimestamp() {
  return new Date().toIso8601String();
}

// Funkcja do kategoryzacji typów inwestycji
function categorizeInvestment(data, index) {
  // Sprawdź czy to są dane klienta
  if (data['imie_nazwisko'] || data['name'] || data['email'] || data['telefon'] || data['phone']) {
    return 'clients';
  }

  // Sprawdź czy to dane apartamentów
  if (data['numer_apartamentu'] || data['powierzchnia'] || data['liczba_pokoi'] ||
    data['typ_produktu']?.toLowerCase().includes('apartament')) {
    return 'apartments';
  }

  const amount = safeParseNumber(data['Kapitał do restrukturyzacji'] || data['kapital_do_restrukturyzacji'] || data['kwota_inwestycji']);
  const productType = data['typ_produktu'] || '';

  // Kategoryzuj na podstawie typu produktu jeśli jest dostępny
  if (productType.toLowerCase().includes('obligacje') || productType.toLowerCase().includes('bond')) {
    return 'bonds';
  } else if (productType.toLowerCase().includes('udział') || productType.toLowerCase().includes('share')) {
    return 'shares';
  } else if (productType.toLowerCase().includes('pożyczka') || productType.toLowerCase().includes('loan')) {
    return 'loans';
  } else if (productType.toLowerCase().includes('apartament') || productType.toLowerCase().includes('apartment')) {
    return 'apartments';
  }

  // Logika kategoryzacji na podstawie kwoty lub wzorca
  if (amount === 0) {
    // Dla wartości 0 możemy przypisać różne typy na podstawie pozycji
    const types = ['bonds', 'shares', 'loans', 'apartments'];
    return types[index % types.length];
  }

  // Kategoryzuj na podstawie zakresu kwot
  if (amount > 0 && amount <= 50000) {
    return 'shares';  // Mniejsze kwoty to udziały
  } else if (amount > 50000 && amount <= 500000) {
    return 'bonds';   // Średnie kwoty to obligacje
  } else if (amount > 500000 && amount <= 1000000) {
    return 'loans';   // Większe kwoty to pożyczki
  } else {
    return 'apartments'; // Największe kwoty to apartamenty
  }
}

// Funkcja do tworzenia danych obligacji
function createBondData(originalData, index) {
  const amount = safeParseNumber(originalData['Kapitał do restrukturyzacji'] || originalData['kapital_do_restrukturyzacji'] || originalData['kwota_inwestycji']);
  const capitalSecured = safeParseNumber(originalData['Kapitał zabezpieczony nieruchomością'] || originalData['kapital_zabezpieczony_nieruchomoscia']);

  return {
    id: generateId(),
    typ_produktu: originalData['typ_produktu'] || 'Obligacje',
    kwota_inwestycji: originalData['kwota_inwestycji'] || amount * 1.2, // Symulujemy oryginalną kwotę inwestycji
    kapital_zrealizowany: Math.random() * amount * 0.3,
    kapital_pozostaly: amount,
    kapital_do_restrukturyzacji: amount,
    kapital_zabezpieczony_nieruchomoscia: capitalSecured || 0,
    odsetki_zrealizowane: Math.random() * amount * 0.1,
    odsetki_pozostale: Math.random() * amount * 0.05,
    podatek_zrealizowany: Math.random() * amount * 0.02,
    podatek_pozostaly: Math.random() * amount * 0.01,
    przekaz_na_inny_produkt: 0,
    source_file: originalData.source_file || 'tableConvert.com_n0b2g7.json',
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla obligacji
    emisja_data: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toIso8601String(),
    wykup_data: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toIso8601String(),
    oprocentowanie: (2 + Math.random() * 8).toFixed(2), // 2-10%
    nazwa_obligacji: `OBL-${String(index + 1).padStart(4, '0')}`,
    emitent: `Spółka ${Math.floor(Math.random() * 100) + 1} Sp. z o.o.`,
    status: Math.random() > 0.2 ? 'Aktywny' : 'Nieaktywny',
    // Kopiuj wszystkie dodatkowe pola z oryginalnych danych
    ...Object.fromEntries(
      Object.entries(originalData).filter(([key]) =>
        !['Kapitał do restrukturyzacji', 'Kapitał zabezpieczony nieruchomością'].includes(key)
      )
    )
  };
}

// Funkcja do tworzenia danych udziałów
function createShareData(originalData, index) {
  const amount = safeParseNumber(originalData['Kapitał do restrukturyzacji'] || originalData['kapital_do_restrukturyzacji'] || originalData['kwota_inwestycji']);
  const capitalSecured = safeParseNumber(originalData['Kapitał zabezpieczony nieruchomością'] || originalData['kapital_zabezpieczony_nieruchomoscia']);
  const sharesCount = Math.max(1, Math.floor(amount / (100 + Math.random() * 400)));

  return {
    id: generateId(),
    typ_produktu: originalData['typ_produktu'] || 'Udziały',
    kwota_inwestycji: originalData['kwota_inwestycji'] || amount,
    ilosc_udzialow: originalData['ilosc_udzialow'] || sharesCount,
    kapital_do_restrukturyzacji: amount,
    kapital_zabezpieczony_nieruchomoscia: capitalSecured || 0,
    source_file: originalData.source_file || 'tableConvert.com_n0b2g7.json',
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla udziałów
    cena_za_udzial: sharesCount > 0 ? (amount / sharesCount).toFixed(2) : '0.00',
    nazwa_spolki: `Invest ${Math.floor(Math.random() * 100) + 1} Sp. z o.o.`,
    procent_udzialow: (Math.random() * 10).toFixed(2),
    data_nabycia: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toIso8601String(),
    nip_spolki: `${Math.floor(Math.random() * 9000000000) + 1000000000}`,
    sektor: ['Technologie', 'Finanse', 'Nieruchomości', 'Energetyka'][Math.floor(Math.random() * 4)],
    status: Math.random() > 0.1 ? 'Aktywny' : 'Nieaktywny',
    // Kopiuj wszystkie dodatkowe pola z oryginalnych danych
    ...Object.fromEntries(
      Object.entries(originalData).filter(([key]) =>
        !['Kapitał do restrukturyzacji', 'Kapitał zabezpieczony nieruchomością'].includes(key)
      )
    )
  };
}

// Funkcja do tworzenia danych pożyczek
function createLoanData(originalData, index) {
  const amount = safeParseNumber(originalData['Kapitał do restrukturyzacji'] || originalData['kapital_do_restrukturyzacji'] || originalData['kwota_inwestycji']);
  const capitalSecured = safeParseNumber(originalData['Kapitał zabezpieczony nieruchomością'] || originalData['kapital_zabezpieczony_nieruchomoscia']);

  return {
    id: generateId(),
    typ_produktu: originalData['typ_produktu'] || 'Pożyczki',
    kwota_inwestycji: originalData['kwota_inwestycji'] || amount,
    kapital_do_restrukturyzacji: amount,
    kapital_zabezpieczony_nieruchomoscia: capitalSecured || 0,
    source_file: originalData.source_file || 'tableConvert.com_n0b2g7.json',
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla pożyczek
    pozyczka_numer: `POZ/${new Date().getFullYear()}/${String(index + 1).padStart(6, '0')}`,
    pozyczkobiorca: `Kredytobiorca ${Math.floor(Math.random() * 1000) + 1}`,
    oprocentowanie: (5 + Math.random() * 15).toFixed(2), // 5-20%
    data_udzielenia: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toIso8601String(),
    data_splaty: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toIso8601String(),
    kapital_pozostaly: amount * (0.6 + Math.random() * 0.4), // 60-100% pozostałe
    odsetki_naliczone: amount * (0.05 + Math.random() * 0.15), // 5-20% odsetek
    zabezpieczenie: ['Hipoteka', 'Zastaw', 'Poręczenie', 'Weksel'][Math.floor(Math.random() * 4)],
    status: ['Spłacana terminowo', 'Opóźnienia', 'Restrukturyzacja'][Math.floor(Math.random() * 3)],
    // Kopiuj wszystkie dodatkowe pola z oryginalnych danych
    ...Object.fromEntries(
      Object.entries(originalData).filter(([key]) =>
        !['Kapitał do restrukturyzacji', 'Kapitał zabezpieczony nieruchomością'].includes(key)
      )
    )
  };
}

// Główna funkcja przetwarzania
function processJsonFile() {

  try {
    const rawData = fs.readFileSync(INPUT_FILE, 'utf8');
    const jsonData = JSON.parse(rawData);

    // Kontenery dla różnych typów
    const bonds = [];
    const shares = [];
    const loans = [];

    // Statystyki
    let stats = {
      bonds: 0,
      shares: 0,
      loans: 0,
      totalValue: 0
    };

    // Przetwarzaj każdy rekord
    jsonData.forEach((item, index) => {
      const amount = safeParseNumber(item['Kapitał do restrukturyzacji']);
      const investmentType = categorizeInvestment(item['Kapitał do restrukturyzacji'], index);

      stats.totalValue += amount;

      switch (investmentType) {
        case 'bonds':
          bonds.push(createBondData(item, index));
          stats.bonds++;
          break;
        case 'shares':
          shares.push(createShareData(item, index));
          stats.shares++;
          break;
        case 'loans':
          loans.push(createLoanData(item, index));
          stats.loans++;
          break;
      }
    });

    // Zapisz pliki

    if (bonds.length > 0) {
      fs.writeFileSync(
        path.join(OUTPUT_DIR, 'bonds.json'),
        JSON.stringify(bonds, null, 2),
        'utf8'
      );
    }

    if (shares.length > 0) {
      fs.writeFileSync(
        path.join(OUTPUT_DIR, 'shares.json'),
        JSON.stringify(shares, null, 2),
        'utf8'
      );
    }

    if (loans.length > 0) {
      fs.writeFileSync(
        path.join(OUTPUT_DIR, 'loans.json'),
        JSON.stringify(loans, null, 2),
        'utf8'
      );
    }

    // Zapisz zbiorczy plik z metadanymi
    const metadata = {
      sourceFile: INPUT_FILE,
      processedAt: getCurrentTimestamp(),
      totalRecords: jsonData.length,
      statistics: stats,
      files: {
        bonds: bonds.length > 0 ? 'bonds.json' : null,
        shares: shares.length > 0 ? 'shares.json' : null,
        loans: loans.length > 0 ? 'loans.json' : null
      }
    };

    fs.writeFileSync(
      path.join(OUTPUT_DIR, 'metadata.json'),
      JSON.stringify(metadata, null, 2),
      'utf8'
    );

    // Wyświetl podsumowanie
    console.log(`Całkowita wartość: ${stats.totalValue.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}`);
    console.log(`Obligacje: ${stats.bonds} (${((stats.bonds / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Udziały: ${stats.shares} (${((stats.shares / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Pożyczki: ${stats.loans} (${((stats.loans / jsonData.length) * 100).toFixed(1)}%)`);

  } catch (error) {
    process.exit(1);
  }
}

// Dodaj metodę toIso8601String do Date.prototype jeśli nie istnieje
if (!Date.prototype.toIso8601String) {
  Date.prototype.toIso8601String = function () {
    return this.toISOString();
  };
}

// Uruchom skrypt
if (require.main === module) {
  processJsonFile();
}

module.exports = {
  processJsonFile,
  categorizeInvestment,
  createBondData,
  createShareData,
  createLoanData
};

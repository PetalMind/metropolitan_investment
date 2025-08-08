#!/usr/bin/env node

/**
 * Skrypt do podziału JSON-a na różne typy danych zgodnie z modelami Flutter
 * Obsługuje: obligacje, udziały, pożyczki, apartamenty, klienci
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
  console.error(`❌ Plik ${INPUT_FILE} nie istnieje`);
  console.log('Użycie: node split_json_by_investment_type_complete.js <ścieżka_do_pliku.json>');
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
  return new Date().toISOString();
}

// Funkcja do kategoryzacji typów danych
function categorizeData(data, index) {
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

  // Logika kategoryzacji na podstawie kwoty
  if (amount === 0) {
    const types = ['bonds', 'shares', 'loans', 'apartments'];
    return types[index % types.length];
  }

  // Kategoryzuj na podstawie zakresu kwot
  if (amount > 0 && amount <= 50000) {
    return 'shares';
  } else if (amount > 50000 && amount <= 500000) {
    return 'bonds';
  } else if (amount > 500000 && amount <= 1000000) {
    return 'loans';
  } else {
    return 'apartments';
  }
}

// Funkcja do tworzenia danych obligacji
function createBondData(originalData, index) {
  const amount = safeParseNumber(originalData['Kapitał do restrukturyzacji'] || originalData['kapital_do_restrukturyzacji'] || originalData['kwota_inwestycji']);
  const capitalSecured = safeParseNumber(originalData['Kapitał zabezpieczony nieruchomością'] || originalData['kapital_zabezpieczony_nieruchomoscia']);

  return {
    id: generateId(),
    typ_produktu: originalData['typ_produktu'] || 'Obligacje',
    kwota_inwestycji: originalData['kwota_inwestycji'] || amount * 1.2,
    kapital_zrealizowany: Math.random() * amount * 0.3,
    kapital_pozostaly: amount,
    kapital_do_restrukturyzacji: amount,
    kapital_zabezpieczony_nieruchomoscia: capitalSecured || 0,
    odsetki_zrealizowane: Math.random() * amount * 0.1,
    odsetki_pozostale: Math.random() * amount * 0.05,
    podatek_zrealizowany: Math.random() * amount * 0.02,
    podatek_pozostaly: Math.random() * amount * 0.01,
    przekaz_na_inny_produkt: 0,
    source_file: originalData.source_file || INPUT_FILE,
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla obligacji
    emisja_data: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    wykup_data: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    oprocentowanie: (2 + Math.random() * 8).toFixed(2),
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
    source_file: originalData.source_file || INPUT_FILE,
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla udziałów
    cena_za_udzial: sharesCount > 0 ? (amount / sharesCount).toFixed(2) : '0.00',
    nazwa_spolki: `Invest ${Math.floor(Math.random() * 100) + 1} Sp. z o.o.`,
    procent_udzialow: (Math.random() * 10).toFixed(2),
    data_nabycia: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
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
    source_file: originalData.source_file || INPUT_FILE,
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),
    // Dodatkowe pola specyficzne dla pożyczek
    pozyczka_numer: `POZ/${new Date().getFullYear()}/${String(index + 1).padStart(6, '0')}`,
    pozyczkobiorca: `Kredytobiorca ${Math.floor(Math.random() * 1000) + 1}`,
    oprocentowanie: (5 + Math.random() * 15).toFixed(2),
    data_udzielenia: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    data_splaty: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    kapital_pozostaly: amount * (0.6 + Math.random() * 0.4),
    odsetki_naliczone: amount * (0.05 + Math.random() * 0.15),
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

// Funkcja do tworzenia danych apartamentów
function createApartmentData(originalData, index) {
  const amount = safeParseNumber(originalData['Kapitał do restrukturyzacji'] || originalData['kapital_do_restrukturyzacji'] || originalData['kwota_inwestycji']);
  const capitalSecured = safeParseNumber(originalData['Kapitał zabezpieczony nieruchomością'] || originalData['kapital_zabezpieczony_nieruchomoscia']);
  const area = Math.random() * 80 + 20; // 20-100m²
  const roomCount = Math.floor(Math.random() * 4) + 1; // 1-4 pokoje

  return {
    id: generateId(),
    typ_produktu: originalData['typ_produktu'] || 'Apartamenty',
    kwota_inwestycji: originalData['kwota_inwestycji'] || amount,
    kapital_do_restrukturyzacji: amount,
    kapital_zabezpieczony_nieruchomoscia: capitalSecured || amount,
    source_file: originalData.source_file || INPUT_FILE,
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),

    // Pola specyficzne dla apartamentów
    numer_apartamentu: originalData['numer_apartamentu'] || `${Math.floor(Math.random() * 200) + 1}`,
    budynek: originalData['budynek'] || `Budynek ${String.fromCharCode(65 + Math.floor(Math.random() * 5))}`,
    adres: originalData['adres'] || `ul. Mieszkaniowa ${Math.floor(Math.random() * 100) + 1}, Warszawa`,
    powierzchnia: originalData['powierzchnia'] || area.toFixed(2),
    liczba_pokoi: originalData['liczba_pokoi'] || roomCount,
    pietro: originalData['pietro'] || Math.floor(Math.random() * 10) + 1,
    status: originalData['status'] || ['Dostępny', 'Sprzedany', 'Zarezerwowany'][Math.floor(Math.random() * 3)],
    cena_za_m2: originalData['cena_za_m2'] || (8000 + Math.random() * 7000).toFixed(2),
    data_oddania: originalData['data_oddania'] || new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    deweloper: originalData['deweloper'] || `Deweloper ${Math.floor(Math.random() * 20) + 1} Sp. z o.o.`,
    nazwa_projektu: originalData['nazwa_projektu'] || `Osiedle ${['Słoneczne', 'Zielone', 'Nowoczesne', 'Rodzinne'][Math.floor(Math.random() * 4)]}`,
    balkon: originalData['balkon'] || (Math.random() > 0.3 ? 1 : 0),
    miejsce_parkingowe: originalData['miejsce_parkingowe'] || (Math.random() > 0.5 ? 1 : 0),
    komorka_lokatorska: originalData['komorka_lokatorska'] || (Math.random() > 0.7 ? 1 : 0),

    // Kopiuj wszystkie dodatkowe pola z oryginalnych danych
    ...Object.fromEntries(
      Object.entries(originalData).filter(([key]) =>
        !['Kapitał do restrukturyzacji', 'Kapitał zabezpieczony nieruchomością'].includes(key)
      )
    )
  };
}

// Funkcja do tworzenia danych klientów
function createClientData(originalData, index) {
  const firstName = originalData['imie'] || `Imię${index + 1}`;
  const lastName = originalData['nazwisko'] || `Nazwisko${index + 1}`;
  const fullName = originalData['imie_nazwisko'] || originalData['name'] || `${firstName} ${lastName}`;

  return {
    id: generateId(),
    imie_nazwisko: fullName,
    name: fullName,
    email: originalData['email'] || `klient${index + 1}@example.com`,
    telefon: originalData['telefon'] || originalData['phone'] || `+48${Math.floor(Math.random() * 900000000) + 100000000}`,
    phone: originalData['phone'] || originalData['telefon'] || `+48${Math.floor(Math.random() * 900000000) + 100000000}`,
    address: originalData['address'] || originalData['adres'] || `ul. Kliencka ${Math.floor(Math.random() * 100) + 1}, Warszawa`,
    pesel: originalData['pesel'] || null,
    nazwa_firmy: originalData['nazwa_firmy'] || originalData['companyName'] || null,
    companyName: originalData['companyName'] || originalData['nazwa_firmy'] || null,
    type: originalData['type'] || 'individual',
    notes: originalData['notes'] || '',
    votingStatus: originalData['votingStatus'] || 'undecided',
    colorCode: originalData['colorCode'] || '#FFFFFF',
    unviableInvestments: originalData['unviableInvestments'] || [],
    isActive: originalData['isActive'] !== undefined ? originalData['isActive'] : true,
    source_file: originalData.source_file || INPUT_FILE,
    created_at: getCurrentTimestamp(),
    uploaded_at: getCurrentTimestamp(),

    // Kopiuj wszystkie dodatkowe pola z oryginalnych danych
    additionalInfo: {
      source_file: originalData.source_file || INPUT_FILE,
      ...Object.fromEntries(
        Object.entries(originalData).filter(([key]) =>
          !['imie_nazwisko', 'name', 'email', 'telefon', 'phone', 'address', 'adres'].includes(key)
        )
      )
    }
  };
}

// Główna funkcja przetwarzania
function processJsonFile() {
  console.log(`📖 Czytanie pliku: ${INPUT_FILE}`);

  try {
    const rawData = fs.readFileSync(INPUT_FILE, 'utf8');
    const jsonData = JSON.parse(rawData);

    console.log(`📊 Znaleziono ${jsonData.length} rekordów`);

    // Kontenery dla różnych typów
    const bonds = [];
    const shares = [];
    const loans = [];
    const apartments = [];
    const clients = [];

    // Statystyki
    let stats = {
      bonds: 0,
      shares: 0,
      loans: 0,
      apartments: 0,
      clients: 0,
      totalValue: 0
    };

    // Przetwarzaj każdy rekord
    jsonData.forEach((item, index) => {
      const amount = safeParseNumber(item['Kapitał do restrukturyzacji'] || item['kapital_do_restrukturyzacji'] || item['kwota_inwestycji']);
      const dataType = categorizeData(item, index);

      if (dataType !== 'clients') {
        stats.totalValue += amount;
      }

      switch (dataType) {
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
        case 'apartments':
          apartments.push(createApartmentData(item, index));
          stats.apartments++;
          break;
        case 'clients':
          clients.push(createClientData(item, index));
          stats.clients++;
          break;
      }
    });

    // Zapisz pliki
    console.log(`💾 Zapisywanie plików do katalogu: ${OUTPUT_DIR}`);

    const filesToSave = [
      { data: bonds, filename: 'bonds.json', label: 'Obligacje' },
      { data: shares, filename: 'shares.json', label: 'Udziały' },
      { data: loans, filename: 'loans.json', label: 'Pożyczki' },
      { data: apartments, filename: 'apartments.json', label: 'Apartamenty' },
      { data: clients, filename: 'clients.json', label: 'Klienci' }
    ];

    filesToSave.forEach(({ data, filename, label }) => {
      if (data.length > 0) {
        fs.writeFileSync(
          path.join(OUTPUT_DIR, filename),
          JSON.stringify(data, null, 2),
          'utf8'
        );
        console.log(`✅ ${label}: ${data.length} rekordów → ${filename}`);
      }
    });

    // Zapisz zbiorczy plik z metadanymi
    const metadata = {
      sourceFile: INPUT_FILE,
      processedAt: getCurrentTimestamp(),
      totalRecords: jsonData.length,
      statistics: stats,
      files: Object.fromEntries(
        filesToSave.map(({ data, filename, label }) => [
          filename.replace('.json', ''),
          data.length > 0 ? filename : null
        ])
      )
    };

    fs.writeFileSync(
      path.join(OUTPUT_DIR, 'metadata.json'),
      JSON.stringify(metadata, null, 2),
      'utf8'
    );

    // Wyświetl podsumowanie
    console.log('\n📈 PODSUMOWANIE:');
    console.log(`Całkowita wartość inwestycji: ${stats.totalValue.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN' })}`);
    console.log(`Obligacje: ${stats.bonds} (${((stats.bonds / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Udziały: ${stats.shares} (${((stats.shares / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Pożyczki: ${stats.loans} (${((stats.loans / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Apartamenty: ${stats.apartments} (${((stats.apartments / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`Klienci: ${stats.clients} (${((stats.clients / jsonData.length) * 100).toFixed(1)}%)`);
    console.log(`\n✨ Pliki zapisane w katalogu: ${OUTPUT_DIR}`);

  } catch (error) {
    console.error('❌ Błąd przetwarzania:', error.message);
    process.exit(1);
  }
}

// Uruchom skrypt
if (require.main === module) {
  processJsonFile();
}

module.exports = {
  processJsonFile,
  categorizeData,
  createBondData,
  createShareData,
  createLoanData,
  createApartmentData,
  createClientData
};

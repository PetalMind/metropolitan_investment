/**
 * 🚀 OPTYMALIZACJA INWESTORÓW PRODUKTÓW - Firebase Functions
 * Przeniesienie ciężkiej logiki wyszukiwania i grupowania na serwer Google
 * Zastępuje ProductInvestorsService po stronie klienta
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// 🎯 GŁÓWNA FUNKCJA: Pobieranie inwestorów dla produktu z zaawansowaną optymalizacją
exports.getProductInvestorsOptimized = onCall({
  memory: "2GiB",
  timeoutSeconds: 300,
  region: "europe-west1",
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();

  // Inicjalizuj Firestore wewnątrz funkcji
  const db = admin.firestore();

  console.log("🔍 [Product Investors] Rozpoczynam optymalizowane wyszukiwanie...", data);

  try {
    const {
      productName,
      productType, // 'bonds', 'shares', 'loans', 'apartments', 'other'
      searchStrategy = 'comprehensive', // 'exact', 'type', 'comprehensive'
      forceRefresh = false,
    } = data;

    if (!productName && !productType) {
      throw new HttpsError('invalid-argument', 'Wymagana nazwa produktu lub typ produktu');
    }

    // 💾 Cache Key
    const cacheKey = `product_investors_${productName || productType}_${searchStrategy}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Product Investors] Zwracam z cache");
        return {
          ...cached,
          fromCache: true,
          executionTime: Date.now() - startTime
        };
      }
    }

    // 📊 KROK 1: Równoległe pobieranie wszystkich potrzebnych danych
    console.log("📋 [Product Investors] Pobieranie danych...");

    // Zmniejsz limity dla testów
    const dataLimit = 1000; // Zamiast 50000
    const clientLimit = 500; // Zamiast 10000

    const [
      investmentsSnapshot,
      bondsSnapshot,
      sharesSnapshot,
      loansSnapshot,
      apartmentsSnapshot,
      clientsSnapshot,
    ] = await Promise.all([
      // Pobierz z głównej kolekcji investments (ograniczony limit)
      db.collection('investments').limit(dataLimit).get(),
      // Pobierz z dedykowanych kolekcji (ograniczone limity)
      db.collection('bonds').limit(dataLimit).get(),
      db.collection('shares').limit(dataLimit).get(),
      db.collection('loans').limit(dataLimit).get(),
      db.collection('apartments').limit(dataLimit).get(),
      // Pobierz klientów (ograniczony limit)
      db.collection('clients').limit(clientLimit).get(),
    ]);

    console.log(`📊 [Product Investors] Pobrane dane:
      - Investments: ${investmentsSnapshot.docs.length}
      - Bonds: ${bondsSnapshot.docs.length}  
      - Shares: ${sharesSnapshot.docs.length}
      - Loans: ${loansSnapshot.docs.length}
      - Apartments: ${apartmentsSnapshot.docs.length}
      - Clients: ${clientsSnapshot.docs.length}`);

    // 📊 KROK 2: Przygotuj mapę klientów dla szybkiego wyszukiwania
    const clientsMap = new Map();
    const clientsByExcelId = new Map();
    const clientsByName = new Map();

    clientsSnapshot.docs.forEach(doc => {
      const client = { id: doc.id, ...doc.data() };
      clientsMap.set(client.id, client);

      // Mapowanie po excelId dla Excel ID -> Firestore UUID
      if (client.excelId) {
        clientsByExcelId.set(client.excelId.toString(), client);
      }
      if (client.original_id) {
        clientsByExcelId.set(client.original_id.toString(), client);
      }

      // Mapowanie przez stare pole 'id' (numeryczne Excel ID)
      if (client.id && typeof client.id === 'number') {
        clientsByExcelId.set(client.id.toString(), client);
      }

      // Mapowanie po nazwie klienta (fallback)
      const clientName = client.fullName || client.imie_nazwisko || client.name;
      if (clientName) {
        clientsByName.set(clientName, client);
      }
    });

    console.log(`👥 [Product Investors] Utworzono mapowania:
      - UUID: ${clientsMap.size}
      - Excel ID: ${clientsByExcelId.size}  
      - Nazwy: ${clientsByName.size}`);

    console.log(`👥 [Product Investors] Mapa klientów: ${clientsMap.size} total, ${clientsByExcelId.size} z Excel ID`);

    // 📊 KROK 3: Zbierz wszystkie inwestycje z różnych kolekcji
    const allInvestments = [];

    // Helper do dodawania inwestycji z oznaczeniem kolekcji
    const addInvestments = (snapshot, collectionType) => {
      snapshot.docs.forEach(doc => {
        allInvestments.push({
          id: doc.id,
          collection_type: collectionType,
          ...doc.data(),
        });
      });
    };

    addInvestments(investmentsSnapshot, 'investments');
    addInvestments(bondsSnapshot, 'bonds');
    addInvestments(sharesSnapshot, 'shares');
    addInvestments(loansSnapshot, 'loans');
    addInvestments(apartmentsSnapshot, 'apartments');

    console.log(`💼 [Product Investors] Łącznie inwestycji: ${allInvestments.length}`);

    // 📊 KROK 4: Filtrowanie inwestycji według strategii wyszukiwania
    let matchingInvestments = [];

    if (searchStrategy === 'exact' && productName) {
      // Strategia dokładnej nazwy
      matchingInvestments = allInvestments.filter(investment => {
        const investmentProductName = getInvestmentProductName(investment);
        return investmentProductName === productName;
      });
      console.log(`🎯 [Product Investors] Strategia dokładna: ${matchingInvestments.length} inwestycji`);

    } else if (searchStrategy === 'type' && productType) {
      // Strategia według typu produktu
      const typeVariants = getProductTypeVariants(productType);
      matchingInvestments = allInvestments.filter(investment => {
        const investmentType = getInvestmentProductType(investment);
        return typeVariants.some(variant =>
          investmentType.toLowerCase().includes(variant.toLowerCase())
        );
      });
      console.log(`🎯 [Product Investors] Strategia typ: ${matchingInvestments.length} inwestycji`);

    } else {
      // Strategia komprehensywna (domyślna)
      matchingInvestments = findInvestmentsByComprehensiveSearch(
        allInvestments,
        productName,
        productType
      );
      console.log(`🎯 [Product Investors] Strategia komprehensywna: ${matchingInvestments.length} inwestycji`);
    }

    if (matchingInvestments.length === 0) {
      console.log("⚠️ [Product Investors] Brak pasujących inwestycji");
      const emptyResult = {
        investors: [],
        totalCount: 0,
        searchStrategy: searchStrategy,
        productName: productName || '',
        productType: productType || '',
        executionTime: Date.now() - startTime,
        fromCache: false,
        debugInfo: {
          totalInvestments: allInvestments.length,
          totalClients: clientsMap.size,
          searchCriteria: { productName, productType, searchStrategy }
        }
      };

      // Cache pustego wyniku na krótko (1 minuta)
      await setCachedResult(cacheKey, emptyResult, 60);
      return emptyResult;
    }

    // 📊 KROK 5: Grupowanie inwestycji według klientów z ulepszonym mapowaniem
    console.log("🔄 [Product Investors] Grupowanie według klientów...");
    const investmentsByClient = new Map();
    let mappedInvestments = 0;
    let unmappedInvestments = 0;

    matchingInvestments.forEach(investment => {
      // Pobierz identyfikatory klienta z inwestycji
      const excelClientId = investment.clientId || investment.ID_Klient || investment.id_klient?.toString();
      const clientName = investment.clientName || investment.Klient || investment.klient;

      let resolvedClient = null;

      // Strategia 1: Mapowanie przez Excel ID
      if (excelClientId && clientsByExcelId.has(excelClientId)) {
        resolvedClient = clientsByExcelId.get(excelClientId);
        mappedInvestments++;
        console.log(`✅ [Product Investors] Zmapowano przez Excel ID: ${excelClientId} -> ${resolvedClient.fullName || resolvedClient.imie_nazwisko || resolvedClient.name}`);
      }
      // Strategia 2: Mapowanie przez nazwę klienta (fallback)
      else if (clientName && clientsByName.has(clientName)) {
        resolvedClient = clientsByName.get(clientName);
        mappedInvestments++;
        console.log(`✅ [Product Investors] Zmapowano przez nazwę: ${clientName}`);
      }
      // Strategia 3: Nie udało się zmapować - loguj problem
      else {
        unmappedInvestments++;
        if (!excelClientId && !clientName) {
          console.warn(`⚠️ [Product Investors] Inwestycja bez ID klienta: ${investment.id}`);
        } else {
          console.warn(`❌ [Product Investors] Nie znaleziono klienta o ID: ${excelClientId} lub nazwie: ${clientName}`);
        }
        return; // Pomiń tę inwestycję
      }

      // Dodaj inwestycję do grupy klienta
      const clientKey = resolvedClient.id;
      if (!investmentsByClient.has(clientKey)) {
        investmentsByClient.set(clientKey, {
          client: resolvedClient,
          investments: []
        });
      }

      investmentsByClient.get(clientKey).investments.push({
        ...investment,
        resolvedClientId: resolvedClient.id,
        mappingMethod: excelClientId ? 'excelId' : 'name',
      });
    });

    console.log(`📊 [Product Investors] Statystyki mapowania:
      - Zmapowane inwestycje: ${mappedInvestments}
      - Niezmapowane inwestycje: ${unmappedInvestments}
      - Unikalnych klientów: ${investmentsByClient.size}`);

    matchingInvestments.forEach(investment => {
      // Spróbuj różne sposoby identyfikacji klienta
      const clientIdentifiers = extractClientIdentifiers(investment);
      let matchedClient = null;

      // Znajdź klienta według różnych identyfikatorów
      for (const identifier of clientIdentifiers) {
        if (clientsByExcelId.has(identifier)) {
          matchedClient = clientsByExcelId.get(identifier);
          break;
        }
      }

      // Fallback - spróbuj znaleźć po nazwie klienta
      if (!matchedClient) {
        const clientName = getInvestmentClientName(investment);
        if (clientName && clientName.trim()) {
          for (const [clientId, client] of clientsMap.entries()) {
            const clientDbName = client.imie_nazwisko || client.name || '';
            // Porównaj dokładnie lub podobnie (usuwając białe znaki)
            if (clientDbName.trim() === clientName.trim() ||
              clientDbName.toLowerCase().includes(clientName.toLowerCase()) ||
              clientName.toLowerCase().includes(clientDbName.toLowerCase())) {
              matchedClient = client;
              console.log(`✅ [Product Investors] Dopasowano klienta po nazwie: "${clientName}" -> "${clientDbName}"`);
              break;
            }
          }
        }
      }

      if (matchedClient) {
        const clientKey = matchedClient.id;
        if (!investmentsByClient.has(clientKey)) {
          investmentsByClient.set(clientKey, {
            client: matchedClient,
            investments: []
          });
        }
        investmentsByClient.get(clientKey).investments.push(investment);
      } else {
        console.log(`⚠️ [Product Investors] Nie można dopasować klienta dla inwestycji: ${investment.id}`);
      }
    });

    console.log(`👥 [Product Investors] Pogrupowane dla ${investmentsByClient.size} klientów`);

    // 📊 KROK 6: Tworzenie podsumowań inwestorów
    console.log("📈 [Product Investors] Tworzenie podsumowań...");
    const investors = [];

    for (const [clientId, clientData] of investmentsByClient.entries()) {
      const investorSummary = createProductInvestorSummary(
        clientData.client,
        clientData.investments
      );
      investors.push(investorSummary);
    }

    // 📊 KROK 7: Sortowanie według wartości inwestycji
    investors.sort((a, b) => b.viableRemainingCapital - a.viableRemainingCapital);

    // 📊 KROK 8: Oblicz statystyki
    const totalCapital = investors.reduce((sum, inv) => sum + inv.viableRemainingCapital, 0);
    const totalInvestments = investors.reduce((sum, inv) => sum + inv.investmentCount, 0);
    const avgCapital = investors.length > 0 ? totalCapital / investors.length : 0;

    const result = {
      investors,
      totalCount: investors.length,
      statistics: {
        totalCapital,
        totalInvestments,
        averageCapital: avgCapital,
        activeInvestors: investors.filter(inv => inv.client.isActive !== false).length,
      },
      searchStrategy,
      productName: productName || '',
      productType: productType || '',
      executionTime: Date.now() - startTime,
      fromCache: false,
      debugInfo: {
        totalInvestmentsScanned: allInvestments.length,
        matchingInvestments: matchingInvestments.length,
        totalClients: clientsMap.size,
        investmentsByClientGroups: investmentsByClient.size,
      }
    };

    // 💾 Cache wyników na 5 minut
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [Product Investors] Zakończone w ${result.executionTime}ms, zwracam ${investors.length} inwestorów`);
    return result;

  } catch (error) {
    console.error("❌ [Product Investors] Błąd:", {
      message: error.message,
      stack: error.stack,
      data: data,
      timestamp: new Date().toISOString()
    });

    throw new HttpsError(
      "internal",
      `Błąd podczas pobierania inwestorów produktu: ${error.message}`,
      {
        originalError: error.message,
        productName: data.productName,
        productType: data.productType,
        timestamp: new Date().toISOString()
      }
    );
  }
});

// 🛠️ HELPER FUNCTIONS

/**
 * Wyciąga nazwę produktu z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentProductName(investment) {
  // Użyj dokładnych nazw pól z Firestore
  return investment.Produkt_nazwa || // Główne pole
    investment.nazwa_obligacji ||  // Dla obligacji
    investment.productName ||      // Backup angielski
    investment.name ||             // Ogólny backup
    '';
}

/**
 * Wyciąga typ produktu z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentProductType(investment) {
  // Użyj dokładnych nazw pól z Firestore
  return investment.Typ_produktu ||    // Główne pole ("Obligacje")
    investment.productType ||     // Backup pole ("Obligacje")  
    investment.investment_type || // Angielska wersja ("bonds")
    investment.typ_produktu ||    // Lowercase backup
    investment.type ||            // Ogólny backup
    '';
}

/**
 * Wyciąga identyfikatory klienta z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function extractClientIdentifiers(investment) {
  const identifiers = [];

  // Główne pola ID klienta zgodne z Firestore
  if (investment.ID_Klient) identifiers.push(investment.ID_Klient.toString());
  if (investment.clientId) identifiers.push(investment.clientId.toString());
  if (investment.id_klient) identifiers.push(investment.id_klient.toString());
  if (investment.klient_id) identifiers.push(investment.klient_id.toString());

  return identifiers.filter(id => id && id !== 'undefined' && id !== 'NULL');
}

/**
 * Wyciąga nazwę klienta z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentClientName(investment) {
  // Główne pole nazwiska klienta w Firestore
  return investment.Klient ||      // Główne pole ("Piotr Gij")
    investment.klient ||      // Lowercase backup
    investment.clientName ||  // Angielski backup
    investment.client_name || // Snake case backup
    '';
}

/**
 * Zwraca warianty nazw typu produktu dla wyszukiwania
 */
function getProductTypeVariants(productType) {
  const variants = {
    'bonds': ['Obligacje', 'obligacje', 'Bond', 'Bonds'],
    'shares': ['Udziały', 'udziały', 'Share', 'Shares', 'Akcje', 'akcje'],
    'loans': ['Pożyczki', 'pożyczki', 'Loan', 'Loans', 'Pozyczki'],
    'apartments': ['Apartamenty', 'apartamenty', 'Apartment', 'Mieszkania'],
    'other': ['Inne', 'inne', 'Other', 'Pozostałe']
  };

  return variants[productType] || [productType];
}

/**
 * Komprehensywne wyszukiwanie inwestycji
 */
function findInvestmentsByComprehensiveSearch(allInvestments, productName, productType) {
  const matching = [];
  const searchTerms = [];

  // Przygotuj terminy wyszukiwania
  if (productName) {
    searchTerms.push(productName.toLowerCase());

    // Dodaj części nazwy (dla apartamentów typu "Nazwa - Budynek A1")
    const parts = productName.split(/[-–—_\s]+/).filter(p => p.length > 2);
    searchTerms.push(...parts.map(p => p.toLowerCase()));
  }

  if (productType) {
    const typeVariants = getProductTypeVariants(productType);
    searchTerms.push(...typeVariants.map(v => v.toLowerCase()));
  }

  console.log(`🔍 [Product Investors] Terminy wyszukiwania: ${searchTerms.join(', ')}`);

  allInvestments.forEach(investment => {
    const productNameInv = getInvestmentProductName(investment).toLowerCase();
    const productTypeInv = getInvestmentProductType(investment).toLowerCase();

    // Sprawdź czy którykolwiek termin występuje w nazwie lub typie produktu
    const matches = searchTerms.some(term =>
      productNameInv.includes(term) ||
      productTypeInv.includes(term) ||
      term.includes(productNameInv.split(/[-–—_\s]+/)[0]) // Sprawdź pierwsze słowo
    );

    if (matches) {
      matching.push(investment);
    }
  });

  return matching;
}

/**
 * Tworzy podsumowanie inwestora dla konkretnego produktu
 */
function createProductInvestorSummary(client, investments) {
  let totalViableCapital = 0;
  let totalInvestmentAmount = 0;
  let totalRealizedCapital = 0;

  const processedInvestments = investments.map(investment => {
    // Mapowanie kwoty inwestycji - sprawdź pola w kolejności priorytetów - NOWE POLA MAJĄ WYŻSZY PRIORYTET
    const amount = parseFloat(
      investment.Kwota_inwestycji ||        // Nowe pole (string)
      investment.kwota_inwestycji ||        // Stare pole (number)
      investment.investmentAmount ||        // Backup pole (number)
      0
    );

    // Mapowanie kapitału pozostałego - obsłuż różne formaty - NOWE POLA MAJĄ WYŻSZY PRIORYTET
    let remainingCapital = 0;

    if (investment['Kapital Pozostaly']) {
      // String z przecinkami: "200,000.00"
      const cleaned = investment['Kapital Pozostaly'].toString().replace(/,/g, '');
      remainingCapital = parseFloat(cleaned) || 0;
    } else if (investment.kapital_pozostaly) {
      // Number pole
      remainingCapital = parseFloat(investment.kapital_pozostaly) || 0;
    } else if (investment.remainingCapital) {
      // Backup number pole  
      remainingCapital = parseFloat(investment.remainingCapital) || 0;
    } else if (investment.kapital_do_restrukturyzacji) {
      // Alternative number pole
      remainingCapital = parseFloat(investment.kapital_do_restrukturyzacji) || 0;
    }

    // Mapowanie zrealizowanego kapitału - NOWE POLA MAJĄ WYŻSZY PRIORYTET
    let realizedCapital = 0;

    if (investment['Kapital zrealizowany']) {
      // String pole: "0.00"
      const cleaned = investment['Kapital zrealizowany'].toString().replace(/,/g, '');
      realizedCapital = parseFloat(cleaned) || 0;
    } else if (investment.kapital_zrealizowany) {
      // Number pole
      realizedCapital = parseFloat(investment.kapital_zrealizowany) || 0;
    } else if (investment.realizedCapital) {
      // Backup number pole
      realizedCapital = parseFloat(investment.realizedCapital) || 0;
    }

    // Mapowanie dodatkowych pól dla analiz
    const remainingInterest = parseFloat(investment.odsetki_pozostale || investment.remainingInterest || 0);
    const realizedInterest = parseFloat(investment.odsetki_zrealizowane || investment.realizedInterest || 0);
    const status = investment.Status_produktu || investment.status || 'Nieznany';

    totalInvestmentAmount += amount;
    totalViableCapital += remainingCapital;
    totalRealizedCapital += realizedCapital;

    return {
      id: investment.id,
      collection_type: investment.collection_type,
      // Podstawowe kwoty
      investmentAmount: amount,
      remainingCapital: remainingCapital,
      realizedCapital: realizedCapital,
      // Odsetki
      remainingInterest: remainingInterest,
      realizedInterest: realizedInterest,
      // Produkt info
      productName: getInvestmentProductName(investment),
      productType: getInvestmentProductType(investment),
      status: status,
      // Daty (konwersja stringów na daty)
      dataEmisji: convertFirestoreDate(investment.data_emisji),
      dataWykupu: convertFirestoreDate(investment.data_wykupu),
      dataPodpisania: convertFirestoreDate(investment.Data_podpisania),
      dataWejscia: convertFirestoreDate(investment.Data_wejscia_do_inwestycji),
      // Metadane
      idSprzedaz: investment.ID_Sprzedaz,
      oddzial: investment.Oddzial,
      opiekunMisa: investment['Opiekun z MISA'],
      // Raw data dla debugowania
      raw: investment
    };
  });

  // Mapuj status głosowania na podstawie danych klienta
  const mapVotingStatus = (status) => {
    if (!status) return 'undecided';
    const statusStr = status.toString().toLowerCase();

    if (statusStr.includes('tak') || statusStr === 'yes') return 'yes';
    if (statusStr.includes('nie') || statusStr === 'no') return 'no';
    if (statusStr.includes('wstrzymuj') || statusStr === 'abstain') return 'abstain';
    return 'undecided';
  };

  return {
    client: {
      id: client.id,
      name: client.imie_nazwisko || client.name || 'Nieznany klient',
      email: client.email || '',
      phone: client.telefon || client.phone || '',
      companyName: client.nazwa_firmy || client.companyName || null,
      isActive: client.isActive !== false,
      votingStatus: mapVotingStatus(client.votingStatus),
      // Dodatkowe pola klienta
      excelId: client.excelId || client.original_id,
      clientType: client.clientType || 'individual',
    },
    investments: processedInvestments,
    investmentCount: investments.length,
    totalInvestmentAmount,
    totalRealizedCapital,
    viableRemainingCapital: totalViableCapital,
    totalValue: totalViableCapital, // Dla kompatybilności z InvestorSummary
    // Dodatkowe metryki
    averageInvestment: investments.length > 0 ? totalViableCapital / investments.length : 0,
    hasMultipleInvestments: investments.length > 1,
    totalRemainingInterest: processedInvestments.reduce((sum, inv) => sum + inv.remainingInterest, 0),
    totalRealizedInterest: processedInvestments.reduce((sum, inv) => sum + inv.realizedInterest, 0),
    productSpecificData: {
      collections: [...new Set(investments.map(inv => inv.collection_type))],
      productTypes: [...new Set(investments.map(inv => getInvestmentProductType(inv)))],
      statuses: [...new Set(investments.map(inv => inv.Status_produktu || inv.status))],
      branches: [...new Set(investments.map(inv => inv.Oddzial).filter(Boolean))],
    }
  };
}

/**
 * Konwertuje różne formaty dat z Firestore na Date object
 */
function convertFirestoreDate(dateValue) {
  if (!dateValue) return null;

  // Jeśli to już Date object
  if (dateValue instanceof Date) return dateValue;

  // Jeśli to Firestore Timestamp
  if (dateValue && typeof dateValue.toDate === 'function') {
    return dateValue.toDate();
  }

  // Jeśli to string w formacie "2018-07-26 00:00:00" lub "7/31/18"
  if (typeof dateValue === 'string') {
    const parsed = new Date(dateValue);
    return isNaN(parsed.getTime()) ? null : parsed;
  }

  return null;
}

// 💾 CACHE FUNCTIONS (reuse from main index.js)
const cache = new Map();
const cacheTimestamps = new Map();

async function getCachedResult(key) {
  const timestamp = cacheTimestamps.get(key);
  if (!timestamp || Date.now() - timestamp > 300000) { // 5 minut
    cache.delete(key);
    cacheTimestamps.delete(key);
    return null;
  }
  return cache.get(key);
}

async function setCachedResult(key, data, ttlSeconds) {
  cache.set(key, data);
  cacheTimestamps.set(key, Date.now());

  setTimeout(() => {
    cache.delete(key);
    cacheTimestamps.delete(key);
  }, ttlSeconds * 1000);
}

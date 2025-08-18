/**
 * 🚀 OPTYMALIZACJA INWESTORÓW PRODUKTÓW - Firebase Functions
 * Przeniesienie ciężkiej logiki wyszukiwania i grupowania na serwer Google
 * Zastępuje ProductInvestorsService po stronie klienta
 */

const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { safeToDouble } = require("./utils/data-mapping");
const { getCachedResult, setCachedResult } = require("./utils/cache-utils");
const { calculateCapitalSecuredByRealEstate, getUnifiedField } = require("./utils/unified-statistics");

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
      productId,    // Dodane nowe pole - ID produktu dla dokładnego wyszukiwania
      productType, // 'bonds', 'shares', 'loans', 'apartments', 'other'
      searchStrategy = 'comprehensive', // 'exact', 'type', 'comprehensive', 'id'
      forceRefresh = false,
    } = data;

    if (!productName && !productType && !productId) {
      throw new HttpsError('invalid-argument', 'Wymagana nazwa produktu, ID produktu lub typ produktu');
    }

    // 💾 Cache Key - dodaj timestamp przy forceRefresh żeby unikać konfliktu
    const baseKey = `product_investors_${productId || productName || productType}_${searchStrategy}`;
    const cacheKey = forceRefresh ? `${baseKey}_fresh_${Date.now()}` : baseKey;

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

    // 📊 KROK 1: Pobieranie danych TYLKO z kolekcji 'investments'
    console.log("📋 [Product Investors] Pobieranie danych z kolekcji 'investments'...");

    // Zwiększ limit dla pełnych danych
    const dataLimit = 5000; // Zwiększony limit dla kolekcji investments
    const clientLimit = 1000; // Limit dla klientów

    const [
      investmentsSnapshot,
      clientsSnapshot,
    ] = await Promise.all([
      // Pobierz z głównej kolekcji investments (wszystkie typy produktów)
      db.collection('investments').limit(dataLimit).get(),
      // Pobierz klientów
      db.collection('clients').limit(clientLimit).get(),
    ]);

    console.log(`📊 [Product Investors] Pobrane dane:
      - Investments: ${investmentsSnapshot.docs.length}
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

    // Dodaj wszystkie inwestycje z kolekcji 'investments'
    addInvestments(investmentsSnapshot, 'investments');

    console.log(`💼 [Product Investors] Łącznie inwestycji: ${allInvestments.length}`);

    // 📊 KROK 4: Filtrowanie inwestycji według strategii wyszukiwania
    let matchingInvestments = [];

    if (searchStrategy === 'id' && productId) {
      // Strategia według ID produktu (najdokładniejsza)
      console.log(`🔍 [Product Investors] Szukam inwestycji z productId: ${productId}`);

      // Debug: sprawdź kilka pierwszych inwestycji
      console.log(`🔍 [Product Investors] Próbka pierwszych 3 inwestycji:`);
      allInvestments.slice(0, 3).forEach((inv, index) => {
        const invId = getInvestmentProductId(inv);
        const invName = getInvestmentProductName(inv);
        console.log(`  ${index}: productId="${invId}", productName="${invName}"`);
      });

      matchingInvestments = allInvestments.filter(investment => {
        const investmentProductId = getInvestmentProductId(investment);
        return investmentProductId === productId;
      });
      console.log(`🎯 [Product Investors] Strategia ID: ${matchingInvestments.length} inwestycji`);

      // Fallback: jeśli nie znaleziono po ID, spróbuj po nazwie
      if (matchingInvestments.length === 0 && productName) {
        console.log(`🔄 [Product Investors] Fallback ID->Name dla: ${productName}`);
        matchingInvestments = allInvestments.filter(investment => {
          const investmentProductName = getInvestmentProductName(investment);
          return investmentProductName === productName;
        });
        console.log(`🎯 [Product Investors] Fallback Name: ${matchingInvestments.length} inwestycji`);
      }

    } else if (searchStrategy === 'exact' && productName) {
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
      // Strategia komprehensywna (domyślna) z preferencją dla ID
      matchingInvestments = findInvestmentsByComprehensiveSearch(
        allInvestments,
        productName,
        productType,
        productId  // Dodano productId jako nowy parametr
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
              console.log(`✅[Product Investors] Dopasowano klienta po nazwie: "${clientName}" -> "${clientDbName}"`);
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
 * Wyciąga ID produktu z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentProductId(investment) {
  // 🚀 ENHANCED: Obsługa znormalizowanych pól z JSON importu
  return investment.productId ||       // Główne pole ID produktu w Firestore
    investment.id ||                   // 🚀 ENHANCED: Logiczne ID (apartment_0001, bond_0002, etc.)
    investment.product_id ||           // Alternatywna nazwa
    investment.id_produktu ||          // Polskie pole z ID
    investment.ID_Produktu ||          // Legacy polskie pole z dużymi literami
    '';
}

/**
 * Wyciąga nazwę produktu z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentProductName(investment) {
  // 🚀 ENHANCED: Obsługa znormalizowanych pól z JSON importu
  return investment.productName ||   // Główne pole w Firestore
    investment.projectName ||        // 🚀 ENHANCED: Pole z apartamentów (apartamenty używają projectName)
    investment.name ||               // Ogólny backup
    investment.Produkt_nazwa ||      // Legacy polskie pole (może być w starych danych)
    investment.nazwa_obligacji ||    // Legacy dla obligacji
    '';
}

/**
 * Wyciąga typ produktu z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentProductType(investment) {
  // Użyj dokładnych nazw pól z Firestore (angielskie nazwy)
  return investment.productType ||     // Główne pole w Firestore ("bond", "share", "loan", "apartment")
    investment.type ||                 // Ogólny backup  
    investment.investment_type ||      // Angielska wersja backup
    investment.Typ_produktu ||         // Legacy polskie pole z dużą literą
    investment.typ_produktu ||         // Legacy polskie pole z małą literą
    '';
}

/**
 * Wyciąga identyfikatory klienta z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function extractClientIdentifiers(investment) {
  const identifiers = [];

  // 🚀 ENHANCED: Obsługa znormalizowanych pól z JSON importu
  if (investment.clientId) identifiers.push(investment.clientId.toString());
  if (investment.client_id) identifiers.push(investment.client_id.toString());
  if (investment.ID_Klient) identifiers.push(investment.ID_Klient.toString()); // Legacy
  if (investment.id_klient) identifiers.push(investment.id_klient.toString()); // Legacy
  if (investment.klient_id) identifiers.push(investment.klient_id.toString()); // Legacy

  // 🚀 ENHANCED: Dodatkowe pola z znormalizowanych danych
  if (investment.saleId) identifiers.push(investment.saleId.toString());       // 🚀 ENHANCED: ID sprzedaży z apartamentów
  if (investment.excel_id) identifiers.push(investment.excel_id.toString());   // 🚀 ENHANCED: Excel ID

  return identifiers.filter(id => id && id !== 'undefined' && id !== 'NULL' && id !== 'null');
}

/**
 * Wyciąga nazwę klienta z inwestycji (mapowanie na rzeczywiste pola Firestore)
 */
function getInvestmentClientName(investment) {
  // Główne pole nazwiska klienta w Firestore (angielskie nazwy)
  return investment.clientName ||      // Główne pole w Firestore ("Piotr Gij")
    investment.client_name ||          // Backup z podkreślnikiem
    investment.fullName ||             // Backup z fullName
    investment.name ||                 // Ogólny backup
    investment.Klient ||               // Legacy polskie pole ("Piotr Gij")
    investment.klient ||               // Legacy polskie pole lowercase
    '';
}

/**
 * Zwraca warianty nazw typu produktu dla wyszukiwania (angielskie i legacy polskie)
 */
function getProductTypeVariants(productType) {
  const variants = {
    'bonds': ['bond', 'bonds', 'Bond', 'Bonds', 'Obligacje', 'obligacje'], // Głównie angielskie + legacy polskie
    'shares': ['share', 'shares', 'Share', 'Shares', 'Udziały', 'udziały', 'Akcje', 'akcje'], // Głównie angielskie + legacy polskie
    'loans': ['loan', 'loans', 'Loan', 'Loans', 'Pożyczki', 'pożyczki', 'Pozyczki'], // Głównie angielskie + legacy polskie
    'apartments': ['apartment', 'apartments', 'Apartment', 'Apartamenty', 'apartamenty', 'Mieszkania'], // Głównie angielskie + legacy polskie
    'other': ['other', 'Other', 'Inne', 'inne', 'Pozostałe']
  };

  return variants[productType] || [productType];
}

/**
 * Komprehensywne wyszukiwanie inwestycji z preferencją dla ID
 */
function findInvestmentsByComprehensiveSearch(allInvestments, productName, productType, productId) {
  let matching = [];

  // PRIORYTET 1: Wyszukaj po ID produktu (jeśli podany)
  if (productId) {
    console.log(`🎯 [Comprehensive] Próba 1: Wyszukiwanie po productId=${productId}`);
    matching = allInvestments.filter(investment => {
      const investmentProductId = getInvestmentProductId(investment);
      return investmentProductId === productId;
    });

    if (matching.length > 0) {
      console.log(`✅ [Comprehensive] Znaleziono ${matching.length} inwestycji po ID`);
      return matching;
    }
  }

  // PRIORYTET 2: Wyszukaj po dokładnej nazwie produktu
  if (productName) {
    console.log(`🎯 [Comprehensive] Próba 2: Wyszukiwanie po dokładnej nazwie="${productName}"`);

    // Debug: pokaż kilka przykładowych nazw produktów w inwestycjach
    const sampleNames = allInvestments.slice(0, 10).map(inv => getInvestmentProductName(inv)).filter(name => name);
    console.log(`🔍 [Comprehensive] Przykładowe nazwy w inwestycjach: ${sampleNames.slice(0, 5).join(', ')}`);

    matching = allInvestments.filter(investment => {
      const investmentProductName = getInvestmentProductName(investment);
      return investmentProductName === productName;
    });

    if (matching.length > 0) {
      console.log(`✅ [Comprehensive] Znaleziono ${matching.length} inwestycji po dokładnej nazwie`);
      return matching;
    } else {
      console.log(`⚠️ [Comprehensive] Brak inwestycji o dokładnej nazwie "${productName}"`);
    }
  }

  // PRIORYTET 3: Wyszukiwanie częściowe (stara logika)
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

  console.log(`🔍 [Comprehensive] Próba 3: Wyszukiwanie częściowe po terminach: ${searchTerms.join(', ')}`);

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

  console.log(`🔍 [Comprehensive] Znaleziono ${matching.length} inwestycji po wyszukiwaniu częściowym`);
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
    // Mapowanie kwoty inwestycji - używa unified field mapping
    const amount = getUnifiedField(investment, 'investmentAmount');

    // Mapowanie kapitału pozostałego - używa unified field mapping
    const remainingCapital = getUnifiedField(investment, 'remainingCapital');

    // Mapowanie zrealizowanego kapitału - używa unified field mapping
    const realizedCapital = getUnifiedField(investment, 'realizedCapital');

    // Mapowanie dodatkowych pól dla analiz - używa unified field mapping
    const remainingInterest = getUnifiedField(investment, 'remainingInterest');
    const realizedInterest = getUnifiedField(investment, 'realizedInterest');
    const status = getUnifiedField(investment, 'productStatus');

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
      // 🚀 ENHANCED: Dodatkowe pola finansowe z znormalizowanych danych - używa unified field mapping
      capitalForRestructuring: getUnifiedField(investment, 'capitalForRestructuring'),
      capitalSecuredByRealEstate: getUnifiedField(investment, 'capitalSecuredByRealEstate'),
      transferToOtherProduct: getUnifiedField(investment, 'transferToOtherProduct'),
      // Odsetki
      remainingInterest: remainingInterest,
      realizedInterest: realizedInterest,
      // 🚀 ENHANCED: Produkt info z obsługą projectName
      productName: getInvestmentProductName(investment),
      productType: getInvestmentProductType(investment),
      productId: getInvestmentProductId(investment), // 🚀 ENHANCED: Dodane productId
      projectName: investment.projectName || '', // 🚀 ENHANCED: Dedykowane pole dla apartamentów
      status: status,
      // 🚀 ENHANCED: Daty z obsługą znormalizowanych pól
      signedDate: convertFirestoreDate(investment.signedDate || investment.Data_podpisania),
      investmentEntryDate: convertFirestoreDate(investment.investmentEntryDate || investment.dataWejscia),
      issueDate: convertFirestoreDate(investment.issueDate || investment.data_emisji),
      redemptionDate: convertFirestoreDate(investment.redemptionDate || investment.data_wykupu),
      // 🚀 ENHANCED: Metadane z nowych pól
      saleId: investment.saleId || investment.ID_Sprzedaz, // 🚀 ENHANCED: ID sprzedaży
      advisor: investment.advisor || investment['Opiekun z MISA'], // 🚀 ENHANCED: Doradca
      branch: investment.branch || investment.Oddzial || investment.oddzial, // 🚀 ENHANCED: Oddział
      creditorCompany: investment.creditorCompany || '', // 🚀 ENHANCED: Firma wierzyciel
      companyId: investment.companyId || '', // 🚀 ENHANCED: ID spółki
      marketEntry: investment.marketEntry || '', // 🚀 ENHANCED: Wejście na rynek
      // Legacy metadane
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
      name: client.fullName || client.imie_nazwisko || client.name || 'Nieznany klient',
      email: client.email || '',
      phone: client.telefon || client.phone || '',
      companyName: client.nazwa_firmy || client.companyName || null,
      isActive: client.isActive !== false,
      votingStatus: mapVotingStatus(client.votingStatus),
      // Dodatkowe pola klienta
      excelId: client.excelId || client.original_id || client.id,
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

const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Import modularnych funkcji analitycznych
const advancedAnalytics = require("./advanced-analytics");
const dashboardSpecialized = require("./dashboard-specialized");
const productInvestorsOptimization = require("./product-investors-optimization");
const testFunction = require("./test-function");

admin.initializeApp();
const db = admin.firestore();

// Global options for all functions (region)  
setGlobalOptions({
  region: "europe-west1",
  cors: [
    "http://localhost:8080",
    "http://0.0.0.0:8080",
    "https://metropolitan-investment.web.app",
    "https://metropolitan-investment.firebaseapp.com"
  ]
});

/**
 * ZOPTYMALIZOWANA ANALITYKA INWESTORÓW - Firebase Functions
 * Przeniesienie ciężkich obliczeń na serwer Google
 */

// 🚀 GŁÓWNA FUNKCJA: Analityka inwestorów z cache
exports.getOptimizedInvestorAnalytics = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚀 [Analytics Functions] Rozpoczynam analizę...", data);

  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = "totalValue",
      sortAscending = false,
      searchQuery = null,
      forceRefresh = false,
    } = data;

    // 💾 Sprawdź cache
    const cacheKey = `analytics_${JSON.stringify(data)}`;
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Analytics Functions] Zwracam z cache");
        return cached;
      }
    }

    // 📊 KROK 1: Pobierz klientów - użyj prostego zapytania
    console.log("📋 [Analytics Functions] Pobieranie klientów...");
    const clientsSnapshot = await db.collection("clients")
      .limit(5000)
      .get();

    const clients = clientsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    console.log(
      `👥 [Analytics Functions] Znaleziono ${clients.length} klientów`,
    );

    // 📊 KROK 2: Pobierz wszystkie inwestycje oraz dedykowane kolekcje
    console.log("💼 [Analytics Functions] Pobieranie inwestycji...");

    // Równoległe pobieranie wszystkich kolekcji
    const [
      investmentsSnapshot,
      bondsSnapshot,
      sharesSnapshot,
      loansSnapshot,
      apartmentsSnapshot,
    ] = await Promise.all([
      db.collection("investments").limit(50000).get(),
      db.collection("bonds").limit(50000).get(),
      db.collection("shares").limit(50000).get(),
      db.collection("loans").limit(50000).get(),
      db.collection("apartments").limit(50000).get(),
    ]);

    const investments = investmentsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    const bonds = bondsSnapshot.docs.map((doc) => ({
      id: doc.id,
      collection_type: 'bonds',
      ...doc.data(),
    }));

    const shares = sharesSnapshot.docs.map((doc) => ({
      id: doc.id,
      collection_type: 'shares',
      ...doc.data(),
    }));

    const loans = loansSnapshot.docs.map((doc) => ({
      id: doc.id,
      collection_type: 'loans',
      ...doc.data(),
    }));

    const apartments = apartmentsSnapshot.docs.map((doc) => ({
      id: doc.id,
      collection_type: 'apartments',
      ...doc.data(),
    }));

    // 🐛 DEBUG: Loguj przykład apartamentu dla weryfikacji
    if (apartments.length > 0) {
      const sampleApartment = apartments[0];
      console.log(`🏠 [DEBUG] Sample apartment data:`, {
        id: sampleApartment.id,
        typ_produktu: sampleApartment.typ_produktu,
        kwota_inwestycji: sampleApartment.kwota_inwestycji,
        kapital_do_restrukturyzacji: sampleApartment.kapital_do_restrukturyzacji,
        kapital_zabezpieczony_nieruchomoscia: sampleApartment.kapital_zabezpieczony_nieruchomoscia,
        klient: sampleApartment.Klient,
        numer_apartamentu: sampleApartment.numer_apartamentu
      });
    }

    console.log(
      `💰 [Analytics Functions] Znaleziono dane:`,
      `\n  - Investments: ${investments.length}`,
      `\n  - Bonds: ${bonds.length}`,
      `\n  - Shares: ${shares.length}`,
      `\n  - Loans: ${loans.length}`,
      `\n  - Apartments: ${apartments.length}`,
    );

    // 📊 KROK 3: Grupuj wszystkie inwestycje według klientów
    const investmentsByClient = new Map();

    // Helper function to add investment to client map
    const addInvestmentToClient = (investment, clientNameField) => {
      const clientName = investment[clientNameField] || investment.klient;
      if (clientName) {
        if (!investmentsByClient.has(clientName)) {
          investmentsByClient.set(clientName, []);
        }
        investmentsByClient.get(clientName).push(investment);
      }
    };

    // Grupuj investments
    investments.forEach((investment) => {
      addInvestmentToClient(investment, 'klient');
    });

    // Grupuj bonds - mogą mieć różne pola dla nazwy klienta
    bonds.forEach((bond) => {
      addInvestmentToClient(bond, 'Klient');
    });

    // Grupuj shares
    shares.forEach((share) => {
      addInvestmentToClient(share, 'Klient');
    });

    // Grupuj loans  
    loans.forEach((loan) => {
      addInvestmentToClient(loan, 'Klient');
    });

    // Grupuj apartments
    apartments.forEach((apartment) => {
      addInvestmentToClient(apartment, 'Klient');
    });

    console.log(
      `🔍 [Analytics Functions] Mapa inwestycji: ` +
      `${investmentsByClient.size} unikalnych klientów`,
    );

    // Wyloguj kilka przykładów dla debugowania
    const sampleClients = Array.from(investmentsByClient.keys())
      .slice(0, 3);
    console.log(
      `📝 [Analytics Functions] Przykłady klientów z inwestycjami: ` +
      `${sampleClients.join(", ")}`,
    );

    // 📊 KROK 4: Utwórz InvestorSummary dla każdego klienta
    console.log(
      "🔄 [Analytics Functions] Tworzę podsumowania inwestorów...",
    );
    const investors = [];
    let clientsProcessed = 0;
    let batchNumber = 1;

    for (const client of clients) {
      clientsProcessed++;

      if (clientsProcessed % 10 === 0) {
        console.log(
          `📦 [OptimizedAnalytics] Przetwarzam batch ` +
          `${batchNumber}/${Math.ceil(clients.length / 10)} ` +
          `(10 klientów)`,
        );
        batchNumber++;
      }

      // Spróbuj dopasować po nazwie klienta
      const clientInvestments =
        investmentsByClient.get(client.imie_nazwisko) || [];

      if (clientInvestments.length === 0) continue;

      const investorSummary =
        createInvestorSummary(client, clientInvestments);

      // Zastosuj filtry
      if (searchQuery) {
        const searchLower = searchQuery.toLowerCase();
        const nameMatch =
          client.imie_nazwisko.toLowerCase().includes(searchLower);
        const emailMatch =
          (client.email || "").toLowerCase().includes(searchLower);

        if (!nameMatch && !emailMatch) {
          continue;
        }
      }

      investors.push(investorSummary);
    }

    console.log(
      `👥 [OptimizedAnalytics] Utworzono ${investors.length} ` +
      `podsumowań inwestorów`,
    );
    console.log("💾 [OptimizedAnalytics] Cache zaktualizowany");
    console.log(
      `✅ [OptimizedAnalytics] Analiza zakończona w ` +
      `${Date.now() - startTime}ms`,
    );

    // 📊 KROK 5: Sortowanie
    sortInvestors(investors, sortBy, sortAscending);

    // 📊 KROK 6: Paginacja
    const totalCount = investors.length;
    const startIndex = (page - 1) * pageSize;
    const endIndex = Math.min(startIndex + pageSize, totalCount);
    const paginatedInvestors = investors.slice(startIndex, endIndex);

    console.log(
      `📊 [OptimizedAnalytics] Zwracam ${paginatedInvestors.length} ` +
      `inwestorów ze strony ${page}`,
    );

    // 📊 KROK 7: Oblicz statystyki
    const totalViableCapital = investors.reduce(
      (sum, inv) => sum + inv.viableRemainingCapital, 0,
    );
    const votingDistribution = analyzeVotingDistribution(investors);

    // Wyloguj rozkład głosowania
    console.log("📊 [Voting Capital Distribution]");
    const yesPercent = totalViableCapital > 0 ?
      ((votingDistribution.yes.capital / totalViableCapital) * 100) : 0;
    console.log(
      `   TAK: ${votingDistribution.yes.capital.toFixed(2)} PLN ` +
      `(${yesPercent.toFixed(1)}%)`,
    );
    const noPercent = totalViableCapital > 0 ?
      ((votingDistribution.no.capital / totalViableCapital) * 100) : 0;
    console.log(
      `   NIE: ${votingDistribution.no.capital.toFixed(2)} PLN ` +
      `(${noPercent.toFixed(1)}%)`,
    );
    const abstainPercent = totalViableCapital > 0 ?
      ((votingDistribution.abstain.capital / totalViableCapital) * 100) : 0;
    console.log(
      `   WSTRZYMUJE: ` +
      `${votingDistribution.abstain.capital.toFixed(2)} ` +
      `PLN (${abstainPercent.toFixed(1)}%)`,
    );
    const undecidedPercent = totalViableCapital > 0 ?
      ((votingDistribution.undecided.capital / totalViableCapital) * 100) :
      0;
    console.log(
      `   NIEZDECYDOWANY: ` +
      `${votingDistribution.undecided.capital.toFixed(2)} PLN ` +
      `(${undecidedPercent.toFixed(1)}%)`,
    );
    console.log(
      `   ŁĄCZNIE WYKONALNY KAPITAŁ: ` +
      `${totalViableCapital.toFixed(2)} PLN`,
    );

    const result = {
      investors: paginatedInvestors,
      allInvestors: investors,
      totalCount,
      currentPage: page,
      pageSize,
      hasNextPage: endIndex < totalCount,
      hasPreviousPage: page > 1,
      totalViableCapital,
      votingDistribution,
      executionTime: Date.now() - startTime,
      source: "firebase-functions",
    };

    // 💾 Zapisz do cache
    await setCachedResult(cacheKey, result, 300);

    console.log(
      `🎉 [Analytics Functions] Analiza zakończona w ` +
      `${result.executionTime}ms`,
    );
    return result;
  } catch (error) {
    console.error("❌ [Analytics Functions] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas analizy",
      error.message,
    );
  }
});// � ZARZĄDZANIE DUŻYMI ZBIORAMI DANYCH

/**
 * Pobiera wszystkich klientów z paginacją i filtrowaniem
 */
exports.getAllClients = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  console.log("👥 [Get All Clients] Pobieranie klientów...", data);

  try {
    const {
      page = 1,
      pageSize = 500,
      searchQuery = null,
      sortBy = "imie_nazwisko",
      forceRefresh = false,
    } = data;

    // Cache dla klientów
    const cacheKey = `clients_${JSON.stringify(data)}`;
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Get All Clients] Zwracam z cache");
        return cached;
      }
    }

    const query = db.collection("clients");

    // Zastosuj wyszukiwanie jeśli jest
    if (searchQuery) {
      // Firestore nie ma full-text search, więc pobieramy wszystko
      // i filtrujemy lokalnie
      const allSnapshot = await query.limit(10000).get();
      const allClients = allSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      const searchLower = searchQuery.toLowerCase();
      const filteredClients = allClients.filter((client) =>
        (client.imie_nazwisko || "").toLowerCase()
          .includes(searchLower) ||
        (client.email || "").toLowerCase().includes(searchLower) ||
        (client.telefon || "").toLowerCase().includes(searchLower),
      ); // Paginacja po filtrowaniu
      const totalCount = filteredClients.length;
      const startIndex = (page - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, totalCount);
      const paginatedClients = filteredClients.slice(startIndex, endIndex);

      const result = {
        clients: paginatedClients,
        totalCount,
        currentPage: page,
        pageSize,
        hasNextPage: endIndex < totalCount,
        hasPreviousPage: page > 1,
        source: "firebase-functions-filtered",
      };

      await setCachedResult(cacheKey, result, 180); // 3 minuty cache
      return result;
    }

    // Bez wyszukiwania - zwykła paginacja bez sortowania dla większej niezawodności
    const snapshot = await query
      .limit(pageSize)
      .offset((page - 1) * pageSize)
      .get();

    const clients = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Policz total (może być kosztowne dla dużych zbiorów)
    const countSnapshot = await db.collection("clients").count().get();
    const totalCount = countSnapshot.data().count;

    const result = {
      clients,
      totalCount,
      currentPage: page,
      pageSize,
      hasNextPage: clients.length === pageSize,
      hasPreviousPage: page > 1,
      source: "firebase-functions",
    };

    await setCachedResult(cacheKey, result, 300); // 5 minut cache
    console.log(`✅ [Get All Clients] Zwrócono ${clients.length} klientów`);
    return result;
  } catch (error) {
    console.error("❌ [Get All Clients] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd pobierania klientów",
      error.message,
    );
  }
});

/**
 * Pobiera wszystkie inwestycje z paginacją i filtrowaniem
 */
exports.getAllInvestments = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  console.log("💼 [Get All Investments] Pobieranie inwestycji...", data);

  try {
    const {
      page = 1,
      pageSize = 500,
      clientFilter = null,
      productTypeFilter = null,
      sortBy = "data_kontraktu",
      forceRefresh = false,
    } = data;

    const cacheKey = `investments_${JSON.stringify(data)}`;
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Get All Investments] Zwracam z cache");
        return cached;
      }
    }

    let query = db.collection("investments");

    // Zastosuj filtry
    if (clientFilter) {
      query = query.where("klient", "==", clientFilter);
    }
    if (productTypeFilter) {
      query = query.where("typ_produktu", "==", productTypeFilter);
    }

    // Sortowanie - używaj tylko jeśli nie ma problemów z indeksami
    if (sortBy && sortBy.length > 0 && !clientFilter && !productTypeFilter) {
      // Tylko jeśli nie ma filtrów i sortBy jest niepusty - użyj sortowania
      try {
        if (sortBy === "data_kontraktu") {
          query = query.orderBy("data_kontraktu", "desc");
        } else {
          query = query.orderBy(sortBy);
        }
      } catch (e) {
        console.log(`⚠️ [Get All Investments] Nie można sortować po ${sortBy}, używam bez sortowania`);
        // Fallback - bez sortowania
      }
    }
    // Jeśli są filtry lub brak sortBy, nie używaj sortowania aby uniknąć błędów indeksów

    console.log(`🔍 [Get All Investments] Query: page=${page}, pageSize=${pageSize}, clientFilter=${clientFilter}, productTypeFilter=${productTypeFilter}, sortBy=${sortBy}`);

    // Paginacja
    const snapshot = await query
      .limit(pageSize)
      .offset((page - 1) * pageSize)
      .get();

    console.log(`📊 [Get All Investments] Pobrano ${snapshot.docs.length} dokumentów z Firestore`);

    const investments = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Dodaj obliczone pola
    const processedInvestments = investments.map((investment) => ({
      ...investment,
      investmentAmount: parseFloat(investment.wartosc_kontraktu || 0),
      remainingCapital: parseFloat(
        investment.remainingCapital || investment.wartosc_kontraktu || 0,
      ),
      realizedCapital: parseFloat(investment.realizedCapital || 0),
    }));

    console.log(`⚙️ [Get All Investments] Przetworzono ${processedInvestments.length} inwestycji`);

    // Policz total dla bieżących filtrów
    let countQuery = db.collection("investments");
    if (clientFilter) {
      countQuery = countQuery.where("klient", "==", clientFilter);
    }
    if (productTypeFilter) {
      countQuery = countQuery.where(
        "typ_produktu", "==", productTypeFilter,
      );
    }

    const countSnapshot = await countQuery.count().get();
    const totalCount = countSnapshot.data().count;

    const result = {
      investments: processedInvestments,
      totalCount,
      currentPage: page,
      pageSize,
      hasNextPage: investments.length === pageSize,
      hasPreviousPage: page > 1,
      appliedFilters: {
        clientFilter,
        productTypeFilter,
      },
      source: "firebase-functions",
      processingTimeMs: Date.now() - Date.now(), // Will be calculated properly
    };

    await setCachedResult(cacheKey, result, 300);
    console.log(
      `✅ [Get All Investments] Zwrócono ${processedInvestments.length} z ${totalCount} inwestycji (strona ${page})`,
    );
    return result;
  } catch (error) {
    console.error("❌ [Get All Investments] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd pobierania inwestycji",
      error.message,
    );
  }
});

/**
 * Pobiera statystyki całego systemu
 */
exports.getSystemStats = onCall({
  memory: "512MiB",
  timeoutSeconds: 120,
}, async (request) => {
  const data = request.data || {};
  console.log("📊 [System Stats] Obliczanie statystyk...");

  try {
    const { forceRefresh = false } = data;

    const cacheKey = "system_stats";
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [System Stats] Zwracam z cache");
        return cached;
      }
    }

    // Równoległe pobieranie statystyk
    const [
      clientsCount,
      investmentsCount,
      totalCapitalSnapshot,
    ] = await Promise.all([
      db.collection("clients").count().get(),
      db.collection("investments").count().get(),
      db.collection("investments").get(),
    ]);

    // Oblicz statystyki kapitału - używamy tylko kapital_pozostaly
    let totalRemainingCapital = 0;
    const productTypeStats = new Map();

    totalCapitalSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      // UŻYWAMY TYLKO kapital_pozostaly zgodnie z modelem Dart
      const remaining = parseFloat(data.kapital_pozostaly || 0);
      const productType = data.typ_produktu || "Nieznany";

      totalRemainingCapital += remaining;

      if (!productTypeStats.has(productType)) {
        productTypeStats.set(productType, {
          count: 0,
          remainingCapital: 0,
        });
      }

      const typeStats = productTypeStats.get(productType);
      typeStats.count++;
      typeStats.remainingCapital += remaining;
    });

    const result = {
      totalClients: clientsCount.data().count,
      totalInvestments: investmentsCount.data().count,
      totalRemainingCapital,
      averageCapitalPerClient:
        totalRemainingCapital / Math.max(clientsCount.data().count, 1),
      productTypeBreakdown: Array.from(productTypeStats.entries()).map(
        ([type, stats]) => ({
          productType: type,
          ...stats,
          averagePerInvestment: stats.remainingCapital /
            Math.max(stats.count, 1),
        }),
      ),
      lastUpdated: new Date().toISOString(),
      source: "firebase-functions",
    };

    await setCachedResult(cacheKey, result, 600); // 10 minut cache
    console.log("✅ [System Stats] Statystyki obliczone");
    return result;
  } catch (error) {
    console.error("❌ [System Stats] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd obliczania statystyk",
      error.message,
    );
  }
});

// �🛠️ HELPER FUNCTIONS

/**
 * Tworzy podsumowanie inwestora z jego inwestycji
 * Obsługuje wszystkie typy kolekcji: investments, bonds, shares, loans, apartments
 * @param {Object} client - Dane klienta
 * @param {Array} investments - Lista inwestycji
 * @return {Object} InvestorSummary
 */
function createInvestorSummary(client, investments) {
  let totalViableCapital = 0;
  let totalInvestmentAmount = 0;
  let bondsTotalValue = 0;
  let sharesTotalValue = 0;
  let loansTotalValue = 0;
  let apartmentsTotalValue = 0;
  let totalCapitalSecuredByRealEstate = 0;
  let totalCapitalForRestructuring = 0;

  const processedInvestments = investments.map((investment) => {
    // 📊 MAPOWANIE KWOTY INWESTYCJI - uwzględnij wszystkie warianty
    const amount = parseFloat(
      investment.kwota_inwestycji ||
      investment.Kwota_inwestycji ||
      investment.investmentAmount ||
      0
    );

    // 📊 MAPOWANIE KAPITAŁU POZOSTAŁEGO - uwzględnij wszystkie warianty  
    let remainingCapital = 0;
    if (investment['Kapital Pozostaly']) {
      const cleaned = investment['Kapital Pozostaly'].toString().replace(/,/g, '');
      remainingCapital = parseFloat(cleaned) || 0;
    } else if (investment.kapital_pozostaly) {
      remainingCapital = parseFloat(investment.kapital_pozostaly) || 0;
    } else if (investment.remainingCapital) {
      remainingCapital = parseFloat(investment.remainingCapital) || 0;
    } else if (investment.kapital_do_restrukturyzacji) {
      // 🔄 Fallback na kapitał do restrukturyzacji
      remainingCapital = parseFloat(investment.kapital_do_restrukturyzacji) || 0;
    }

    // 🐛 DEBUG: Loguj pierwsze kilka inwestycji z kapitałem
    if (remainingCapital > 0 && Math.random() < 0.01) { // 1% szans na log dla wydajności
      console.log(`🔍 [DEBUG] Investment mapping:`, {
        productType: investment.typ_produktu || investment.Typ_produktu,
        collectionType: investment.collection_type,
        remainingCapital: remainingCapital,
        fields: {
          'kapital_pozostaly': investment.kapital_pozostaly,
          'kapital_do_restrukturyzacji': investment.kapital_do_restrukturyzacji,
          'kapital_zabezpieczony_nieruchomoscia': investment.kapital_zabezpieczony_nieruchomoscia,
          'kwota_inwestycji': investment.kwota_inwestycji
        }
      });
    }

    // 📊 MAPOWANIE KAPITAŁU ZABEZPIECZONEGO NIERUCHOMOŚCIĄ
    const capitalSecuredByRealEstate = parseFloat(
      investment.kapital_zabezpieczony_nieruchomoscia ||
      investment.capitalSecuredByRealEstate ||
      0
    );

    // 📊 MAPOWANIE KAPITAŁU DO RESTRUKTURYZACJI  
    const capitalForRestructuring = parseFloat(
      investment.kapital_do_restrukturyzacji ||
      investment.capitalForRestructuring ||
      0
    );

    totalInvestmentAmount += amount;
    totalViableCapital += remainingCapital;
    totalCapitalSecuredByRealEstate += capitalSecuredByRealEstate;
    totalCapitalForRestructuring += capitalForRestructuring;

    // Kategoryzuj według typu kolekcji
    switch (investment.collection_type) {
      case 'bonds':
        bondsTotalValue += remainingCapital;
        break;
      case 'shares':
        sharesTotalValue += remainingCapital;
        break;
      case 'loans':
        loansTotalValue += remainingCapital;
        break;
      case 'apartments':
        apartmentsTotalValue += remainingCapital;
        break;
      default:
        // Dla głównej kolekcji investments próbuj określić typ po polach
        const productType = investment.typ_produktu || investment.Typ_produktu;
        if (productType) {
          if (productType.includes('Obligacje')) {
            bondsTotalValue += remainingCapital;
          } else if (productType.includes('Udziały')) {
            sharesTotalValue += remainingCapital;
          } else if (productType.includes('Pożyczki')) {
            loansTotalValue += remainingCapital;
          } else if (productType.includes('Apartamenty')) {
            apartmentsTotalValue += remainingCapital;
          }
        }
    }

    return {
      ...investment,
      investmentAmount: amount,
      remainingCapital: remainingCapital,
      capitalSecuredByRealEstate: capitalSecuredByRealEstate,
      capitalForRestructuring: capitalForRestructuring,
    };
  });

  return {
    client: {
      id: client.id,
      name: client.imie_nazwisko || client.name,
      email: client.email || "",
      phone: client.telefon || client.phone || "",
      isActive: client.isActive !== false,
      votingStatus: client.votingStatus || "undecided",
      unviableInvestments: client.unviableInvestments || [],
    },
    investments: processedInvestments,
    totalRemainingCapital: totalViableCapital,
    totalSharesValue: sharesTotalValue,
    totalBondsValue: bondsTotalValue,
    totalLoansValue: loansTotalValue,
    totalApartmentsValue: apartmentsTotalValue,
    totalValue: totalViableCapital,
    totalInvestmentAmount,
    totalRealizedCapital: 0, // Nie używamy już zrealizowanego kapitału
    capitalSecuredByRealEstate: totalCapitalSecuredByRealEstate,
    capitalForRestructuring: totalCapitalForRestructuring,
    investmentCount: investments.length,
    viableRemainingCapital: totalViableCapital,
    hasUnviableInvestments: false,
    // Dodatkowe statystyki
    productTypeDistribution: {
      bonds: bondsTotalValue,
      shares: sharesTotalValue,
      loans: loansTotalValue,
      apartments: apartmentsTotalValue,
    },
  };
}

/**
 * Sortuje inwestorów według wybranego kryterium
 * @param {Array} investors - Lista inwestorów
 * @param {string} sortBy - Kryterium sortowania
 * @param {boolean} ascending - Kierunek sortowania
 */
function sortInvestors(investors, sortBy, ascending) {
  const direction = ascending ? 1 : -1;

  investors.sort((a, b) => {
    let aVal; let bVal;

    switch (sortBy) {
      case "totalValue":
        aVal = a.totalValue;
        bVal = b.totalValue;
        break;
      case "name":
        aVal = a.client.name;
        bVal = b.client.name;
        return direction * aVal.localeCompare(bVal);
      case "investmentCount":
        aVal = a.investmentCount;
        bVal = b.investmentCount;
        break;
      case "viableCapital":
        aVal = a.viableRemainingCapital;
        bVal = b.viableRemainingCapital;
        break;
      default:
        aVal = a.totalValue;
        bVal = b.totalValue;
    }

    return direction * (aVal - bVal);
  });
}

/**
 * Analizuje rozkład głosowania kapitału
 * @param {Array} investors - Lista inwestorów
 * @return {Object} Rozkład głosowania
 */
function analyzeVotingDistribution(investors) {
  const distribution = {
    yes: { count: 0, capital: 0 },
    no: { count: 0, capital: 0 },
    abstain: { count: 0, capital: 0 },
    undecided: { count: 0, capital: 0 },
  };

  investors.forEach((investor) => {
    const status = investor.client.votingStatus || "undecided";
    const capital = investor.viableRemainingCapital;

    if (distribution[status]) {
      distribution[status].count++;
      distribution[status].capital += capital;
    } else {
      distribution.undecided.count++;
      distribution.undecided.capital += capital;
    }
  });

  return distribution;
}

// 💾 CACHE FUNCTIONS
const cache = new Map();
const cacheTimestamps = new Map();

/**
 * Pobiera wynik z cache
 * @param {string} key - Klucz cache
 * @return {Object|null} Wynik z cache lub null
 */
async function getCachedResult(key) {
  const timestamp = cacheTimestamps.get(key);
  if (!timestamp || Date.now() - timestamp > 300000) { // 5 minut
    cache.delete(key);
    cacheTimestamps.delete(key);
    return null;
  }
  return cache.get(key);
}

/**
 * Zapisuje wynik do cache
 * @param {string} key - Klucz cache
 * @param {Object} data - Dane do zapisania
 * @param {number} ttlSeconds - Czas życia w sekundach
 */
async function setCachedResult(key, data, ttlSeconds) {
  cache.set(key, data);
  cacheTimestamps.set(key, Date.now());

  // Automatyczne czyszczenie cache
  setTimeout(() => {
    cache.delete(key);
    cacheTimestamps.delete(key);
  }, ttlSeconds * 1000);
}

// 🛍️ FUNKCJA: Zarządzanie produktami z filtrowaniem
exports.getOptimizedProducts = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🛍️ [Products Functions] Rozpoczynam pobieranie produktów...", data);

  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = "name",
      sortAscending = true,
      searchQuery = null,
      productType = null,
      clientId = null,
      forceRefresh = false,
    } = data;

    // 💾 Sprawdź cache
    const cacheKey = `products_${JSON.stringify(data)}`;
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Products Functions] Zwracam z cache");
        return cached;
      }
    }

    // 📊 KROK 1: Pobierz produkty z filtrowaniem
    console.log("🛍️ [Products Functions] Pobieranie produktów...");
    let query = db.collection("products")
      .where("isActive", "==", true);

    // Filtruj według typu produktu
    if (productType) {
      query = query.where("type", "==", productType);
    }

    // Sortowanie - prostsze podejście bez złożonych indeksów
    if (sortBy === "name") {
      query = query.orderBy("name", sortAscending ? "asc" : "desc");
    } else if (sortBy === "createdAt") {
      query = query.orderBy("createdAt", sortAscending ? "asc" : "desc");
    }

    const productsSnapshot = await query.limit(pageSize * 10).get();
    let products = productsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    console.log(`🛍️ [Products Functions] Znaleziono ${products.length} produktów`);

    // 📊 KROK 2: Filtrowanie po nazwie (search) po stronie serwera
    if (searchQuery && searchQuery.trim() !== "") {
      const searchLower = searchQuery.toLowerCase();
      products = products.filter((product) => {
        return (
          product.name?.toLowerCase().includes(searchLower) ||
          product.companyName?.toLowerCase().includes(searchLower) ||
          product.type?.toLowerCase().includes(searchLower)
        );
      });
    }

    // 📊 KROK 3: Jeśli jest clientId, pobierz inwestycje klienta i filtruj produkty
    if (clientId) {
      console.log(`🔍 [Products Functions] Filtrowanie dla klienta: ${clientId}`);

      const investmentsSnapshot = await db.collection("investments")
        .where("clientId", "==", clientId)
        .get();

      const clientInvestments = investmentsSnapshot.docs.map((doc) => doc.data());

      // Wyciągnij unikalne nazwy produktów z inwestycji klienta
      const clientProductNames = [...new Set(
        clientInvestments.map(inv => inv.productName).filter(Boolean)
      )];

      // Filtruj produkty do tych, które ma klient
      if (clientProductNames.length > 0) {
        products = products.filter(product =>
          clientProductNames.includes(product.name)
        );
      } else {
        // Jeśli klient nie ma inwestycji, zwróć pustą listę
        products = [];
      }

      console.log(`🔍 [Products Functions] Po filtrowaniu klienta: ${products.length} produktów`);
    }

    // 📊 KROK 4: Paginacja
    const totalCount = products.length;
    const startIndex = (page - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedProducts = products.slice(startIndex, endIndex);

    // 📊 KROK 5: Statystyki
    const stats = {
      totalProducts: totalCount,
      currentPage: page,
      totalPages: Math.ceil(totalCount / pageSize),
      hasNextPage: endIndex < totalCount,
      hasPreviousPage: page > 1,
      productTypes: [...new Set(products.map(p => p.type))],
    };

    const result = {
      products: paginatedProducts,
      stats,
      metadata: {
        executionTime: Date.now() - startTime,
        timestamp: new Date().toISOString(),
        cacheUsed: false,
      },
    };

    // 💾 Cache wyników
    await setCachedResult(cacheKey, result, 300); // 5 minut cache

    console.log(
      `✅ [Products Functions] Zakończone w ${Date.now() - startTime}ms, ` +
      `zwracam ${paginatedProducts.length} produktów`,
    );

    return result;

  } catch (error) {
    console.error("❌ [Products Functions] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się pobrać produktów",
      error.message,
    );
  }
});

// 📊 FUNKCJA: Statystyki produktów
exports.getProductStats = onCall({
  memory: "1GiB",
  timeoutSeconds: 180,
}, async (request) => {
  const data = request.data || {};
  console.log("📊 [Product Stats] Rozpoczynam analizę statystyk produktów...");

  try {
    const { forceRefresh = false } = data;

    // 💾 Sprawdź cache
    const cacheKey = "product_stats";
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Product Stats] Zwracam z cache");
        return cached;
      }
    }

    // Pobierz wszystkie aktywne produkty
    const productsSnapshot = await db.collection("products")
      .where("isActive", "==", true)
      .get();

    const products = productsSnapshot.docs.map((doc) => doc.data());

    // Pobierz wszystkie inwestycje dla statystyk
    const investmentsSnapshot = await db.collection("investments")
      .get();

    const investments = investmentsSnapshot.docs.map((doc) => doc.data());

    // Analiza statystyk
    const productTypeStats = new Map();
    const productInvestmentStats = new Map();

    // Statystyki według typu produktu
    products.forEach((product) => {
      const type = product.type || "Nieznany";
      if (!productTypeStats.has(type)) {
        productTypeStats.set(type, { count: 0, products: [] });
      }
      productTypeStats.get(type).count++;
      productTypeStats.get(type).products.push(product.name);
    });

    // Statystyki inwestycji według produktów
    investments.forEach((investment) => {
      const productName = investment.productName || "Nieznany";
      if (!productInvestmentStats.has(productName)) {
        productInvestmentStats.set(productName, {
          investmentCount: 0,
          totalValue: 0,
          remainingCapital: 0,
        });
      }
      const stats = productInvestmentStats.get(productName);
      stats.investmentCount++;
      stats.totalValue += investment.investmentAmount || 0;
      stats.remainingCapital += investment.kapital_pozostaly || 0;
    });

    const result = {
      totalProducts: products.length,
      productTypeBreakdown: Array.from(productTypeStats.entries()).map(([type, data]) => ({
        type,
        count: data.count,
        products: data.products,
      })),
      topProductsByInvestments: Array.from(productInvestmentStats.entries())
        .map(([name, stats]) => ({
          productName: name,
          ...stats,
        }))
        .sort((a, b) => b.investmentCount - a.investmentCount)
        .slice(0, 10),
      metadata: {
        timestamp: new Date().toISOString(),
        cacheUsed: false,
      },
    };

    // 💾 Cache wyników na 10 minut
    await setCachedResult(cacheKey, result, 600);

    console.log("✅ [Product Stats] Statystyki produktów wygenerowane");
    return result;

  } catch (error) {
    console.error("❌ [Product Stats] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się wygenerować statystyk produktów",
      error.message,
    );
  }
});

// 🗑️ FUNKCJA: Czyszczenie cache po aktualizacji danych
exports.clearAnalyticsCache = onCall({
  memory: "256MiB",
  timeoutSeconds: 30,
}, async (request) => {
  console.log("🗑️ [Clear Cache] Żądanie czyszczenia cache...");

  try {
    // Wyczyść cache analytics
    const analyticsKeys = Array.from(cache.keys()).filter(key =>
      key.includes('analytics_') ||
      key.includes('clients_') ||
      key.includes('investments_')
    );

    analyticsKeys.forEach(key => {
      cache.delete(key);
      cacheTimestamps.delete(key);
    });

    console.log(`🗑️ [Clear Cache] Wyczyszczono ${analyticsKeys.length} kluczy cache`);
    console.log("✅ [Clear Cache] Cache wyczyszczony pomyślnie");

    return {
      success: true,
      clearedKeys: analyticsKeys.length,
      timestamp: new Date().toISOString(),
      message: "Cache analytics został wyczyszczony"
    };

  } catch (error) {
    console.error("❌ [Clear Cache] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas czyszczenia cache",
      error.message,
    );
  }
});

// ==========================================
// 🚀 FUNKCJE DLA POSZCZEGÓLNYCH KOLEKCJI
// ==========================================

// 💰 Pobierz wszystkie obligacje z paginacją i filtrowaniem
exports.getBonds = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = 'created_at',
      sortDirection = 'desc',
      searchQuery,
      minRemainingCapital,
      productType
    } = data;

    const offset = (page - 1) * pageSize;

    let query = db.collection('bonds')
      .orderBy(sortBy, sortDirection)
      .limit(pageSize)
      .offset(offset);

    // Dodaj filtry jeśli podane
    if (minRemainingCapital) {
      query = query.where('kapital_pozostaly', '>=', minRemainingCapital);
    }

    if (productType) {
      query = query.where('typ_produktu', '==', productType);
    }

    const snapshot = await query.get();

    // Mapuj dane zgodnie z modelem Bond.dart
    const bonds = snapshot.docs.map(doc => {
      const data = doc.data();

      // Helper do bezpiecznej konwersji na double
      const safeToDouble = (value, defaultValue = 0.0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') {
          const cleaned = value.replace(/,/g, '');
          const parsed = parseFloat(cleaned);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      return {
        id: doc.id,
        productType: data.typ_produktu || data.Typ_produktu || 'Obligacje',
        investmentAmount: safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji),
        realizedCapital: safeToDouble(data.kapital_zrealizowany),
        remainingCapital: safeToDouble(data.kapital_pozostaly || data['Kapital Pozostaly']),
        realizedInterest: safeToDouble(data.odsetki_zrealizowane),
        remainingInterest: safeToDouble(data.odsetki_pozostale),
        realizedTax: safeToDouble(data.podatek_zrealizowany),
        remainingTax: safeToDouble(data.podatek_pozostaly),
        transferToOtherProduct: safeToDouble(data.przekaz_na_inny_produkt),
        capitalForRestructuring: safeToDouble(data.kapital_do_restrukturyzacji),
        capitalSecuredByRealEstate: safeToDouble(data.kapital_zabezpieczony_nieruchomoscia),
        sourceFile: data.source_file || 'imported_data.json',
        createdAt: data.created_at,
        uploadedAt: data.uploaded_at,
        // Bond specific fields
        bondNumber: data.obligacja_numer,
        issuer: data.emitent,
        interestRate: data.oprocentowanie,
        issueDate: data.data_emisji,
        maturityDate: data.data_wykupu,
        accruedInterest: safeToDouble(data.odsetki_naliczone),
        nominalValue: safeToDouble(data.wartosc_nominalna),
        currentValue: safeToDouble(data.wartosc_biezaca),
        couponRate: data.stopa_kuponowa,
        couponFrequency: data.czestotliwosc_kuponow,
        rating: data.rating,
        totalValue: safeToDouble(data.kapital_pozostaly || data['Kapital Pozostaly']),
        ...data
      };
    });

    // Pobierz łączną liczbę dla paginacji
    const totalQuery = db.collection('bonds');
    const totalSnapshot = await totalQuery.get();
    const total = totalSnapshot.size;

    return {
      bonds,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasNextPage: page * pageSize < total,
      hasPreviousPage: page > 1,
      metadata: {
        searchQuery,
        minRemainingCapital,
        productType,
        processedAt: new Date().toISOString()
      }
    };
  } catch (error) {
    console.error('❌ Error fetching bonds:', error);
    throw new HttpsError('internal', 'Failed to fetch bonds');
  }
});

// 📊 Pobierz wszystkie udziały z zaawansowanym filtrowaniem
exports.getShares = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = 'created_at',
      sortDirection = 'desc',
      searchQuery,
      minSharesCount,
      productType
    } = data;

    const offset = (page - 1) * pageSize;

    let query = db.collection('shares')
      .orderBy(sortBy, sortDirection)
      .limit(pageSize)
      .offset(offset);

    // Dodaj filtry
    if (minSharesCount) {
      query = query.where('ilosc_udzialow', '>=', minSharesCount);
    }

    if (productType) {
      query = query.where('typ_produktu', '==', productType);
    }

    const snapshot = await query.get();

    // Mapuj dane zgodnie z modelem Share.dart
    const shares = snapshot.docs.map(doc => {
      const data = doc.data();

      const safeToDouble = (value, defaultValue = 0.0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') {
          const cleaned = value.replace(/,/g, '');
          const parsed = parseFloat(cleaned);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      const safeToInt = (value, defaultValue = 0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return Math.floor(value);
        if (typeof value === 'string') {
          const parsed = parseInt(value);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      return {
        id: doc.id,
        productType: data.typ_produktu || data.Typ_produktu || 'Udziały',
        investmentAmount: safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji),
        capitalForRestructuring: safeToDouble(data.kapital_do_restrukturyzacji),
        capitalSecuredByRealEstate: safeToDouble(data.kapital_zabezpieczony_nieruchomoscia),
        sourceFile: data.source_file || 'imported_data.json',
        createdAt: data.created_at,
        uploadedAt: data.uploaded_at,
        // Share specific fields
        sharesCount: safeToInt(data.ilosc_udzialow),
        pricePerShare: safeToDouble(data.cena_za_udzial),
        company: data.spolka,
        shareClass: data.klasa_udzialow,
        nominalValue: safeToDouble(data.wartosc_nominalna),
        bookValue: safeToDouble(data.wartosc_ksiegowa),
        marketValue: safeToDouble(data.wartosc_rynkowa),
        dividendsReceived: safeToDouble(data.dywidendy_otrzymane),
        votingRights: data.prawa_glosowania === 1 || data.prawa_glosowania === true,
        totalValue: safeToDouble(data.ilosc_udzialow) * safeToDouble(data.cena_za_udzial),
        ...data
      };
    });

    const totalQuery = db.collection('shares');
    const totalSnapshot = await totalQuery.get();
    const total = totalSnapshot.size;

    return {
      shares,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasNextPage: page * pageSize < total,
      hasPreviousPage: page > 1,
      metadata: {
        searchQuery,
        minSharesCount,
        productType,
        processedAt: new Date().toISOString()
      }
    };
  } catch (error) {
    console.error('❌ Error fetching shares:', error);
    throw new HttpsError('internal', 'Failed to fetch shares');
  }
});

// 💳 Pobierz wszystkie pożyczki z filtrowaniem
exports.getLoans = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = 'created_at',
      sortDirection = 'desc',
      searchQuery,
      minRemainingCapital,
      status,
      borrower
    } = data;

    const offset = (page - 1) * pageSize;

    let query = db.collection('loans')
      .orderBy(sortBy, sortDirection)
      .limit(pageSize)
      .offset(offset);

    // Dodaj filtry
    if (minRemainingCapital) {
      query = query.where('kapital_pozostaly', '>=', minRemainingCapital);
    }

    if (status) {
      query = query.where('status', '==', status);
    }

    if (borrower) {
      query = query.where('pozyczkobiorca', '==', borrower);
    }

    const snapshot = await query.get();

    // Mapuj dane zgodnie z modelem Loan.dart
    const loans = snapshot.docs.map(doc => {
      const data = doc.data();

      const safeToDouble = (value, defaultValue = 0.0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') {
          const cleaned = value.replace(/,/g, '');
          const parsed = parseFloat(cleaned);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      const parseDate = (dateStr) => {
        if (!dateStr || dateStr === 'NULL') return null;
        try {
          return new Date(dateStr).toISOString();
        } catch (e) {
          return null;
        }
      };

      return {
        id: doc.id,
        productType: data.typ_produktu || data.Typ_produktu || 'Pożyczki',
        investmentAmount: safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji),
        remainingCapital: safeToDouble(data.kapital_pozostaly || data['Kapital Pozostaly']),
        capitalForRestructuring: safeToDouble(data.kapital_do_restrukturyzacji),
        capitalSecuredByRealEstate: safeToDouble(data.kapital_zabezpieczony_nieruchomoscia),
        sourceFile: data.source_file || 'imported_data.json',
        createdAt: data.created_at,
        uploadedAt: data.uploaded_at,
        // Loan specific fields
        loanNumber: data.pozyczka_numer,
        borrower: data.pozyczkobiorca,
        interestRate: data.oprocentowanie,
        disbursementDate: parseDate(data.data_udzielenia),
        repaymentDate: parseDate(data.data_splaty),
        accruedInterest: safeToDouble(data.odsetki_naliczone),
        collateral: data.zabezpieczenie,
        status: data.status,
        totalValue: safeToDouble(data.kapital_pozostaly || data['Kapital Pozostaly']),
        ...data
      };
    });

    const totalQuery = db.collection('loans');
    const totalSnapshot = await totalQuery.get();
    const total = totalSnapshot.size;

    return {
      loans,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasNextPage: page * pageSize < total,
      hasPreviousPage: page > 1,
      metadata: {
        searchQuery,
        minRemainingCapital,
        status,
        borrower,
        processedAt: new Date().toISOString()
      }
    };
  } catch (error) {
    console.error('❌ Error fetching loans:', error);
    throw new HttpsError('internal', 'Failed to fetch loans');
  }
});

// 🏢 Pobierz wszystkie apartamenty z zaawansowanym filtrowaniem
exports.getApartments = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const data = request.data || {};
  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = 'created_at',
      sortDirection = 'desc',
      searchQuery,
      status,
      projectName,
      developer,
      minArea,
      maxArea,
      roomCount
    } = data;

    const offset = (page - 1) * pageSize;

    let query = db.collection('apartments')
      .orderBy(sortBy, sortDirection)
      .limit(pageSize)
      .offset(offset);

    // Dodaj filtry
    if (status) {
      query = query.where('status', '==', status);
    }

    if (projectName) {
      query = query.where('nazwa_projektu', '==', projectName);
    }

    if (developer) {
      query = query.where('deweloper', '==', developer);
    }

    if (minArea) {
      query = query.where('powierzchnia', '>=', minArea);
    }

    if (maxArea) {
      query = query.where('powierzchnia', '<=', maxArea);
    }

    if (roomCount) {
      query = query.where('liczba_pokoi', '==', roomCount);
    }

    const snapshot = await query.get();

    // Mapuj dane zgodnie z modelem Apartment.dart
    const apartments = snapshot.docs.map(doc => {
      const data = doc.data();

      const safeToDouble = (value, defaultValue = 0.0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') {
          const cleaned = value.replace(/,/g, '');
          const parsed = parseFloat(cleaned);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      const safeToInt = (value, defaultValue = 0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return Math.floor(value);
        if (typeof value === 'string') {
          const parsed = parseInt(value);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      const parseDate = (dateStr) => {
        if (!dateStr || dateStr === 'NULL') return null;
        try {
          return new Date(dateStr).toISOString();
        } catch (e) {
          return null;
        }
      };

      // Map apartment status
      const mapStatus = (status) => {
        switch (status?.toLowerCase()) {
          case 'dostępny':
          case 'available':
            return 'Dostępny';
          case 'sprzedany':
          case 'sold':
            return 'Sprzedany';
          case 'zarezerwowany':
          case 'reserved':
            return 'Zarezerwowany';
          case 'w budowie':
          case 'under construction':
            return 'W budowie';
          case 'gotowy':
          case 'ready':
            return 'Gotowy';
          default:
            return 'Dostępny';
        }
      };

      // Map apartment type based on room count
      const mapApartmentType = (roomCount) => {
        switch (roomCount) {
          case 1:
            return 'Kawalerka';
          case 2:
            return '2 pokoje';
          case 3:
            return '3 pokoje';
          case 4:
            return '4 pokoje';
          default:
            return roomCount > 4 ? 'Penthouse' : 'Inne';
        }
      };

      const area = safeToDouble(data.powierzchnia);
      const pricePerM2 = safeToDouble(data.cena_za_m2);
      const roomsCount = safeToInt(data.liczba_pokoi);

      return {
        id: doc.id,
        productType: data.typ_produktu || data.Typ_produktu || 'Apartamenty',
        investmentAmount: safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji),
        capitalForRestructuring: safeToDouble(data.kapital_do_restrukturyzacji),
        capitalSecuredByRealEstate: safeToDouble(data.kapital_zabezpieczony_nieruchomoscia),
        sourceFile: data.source_file || 'imported_data.json',
        createdAt: data.created_at,
        uploadedAt: data.uploaded_at,
        // Apartment specific fields
        apartmentNumber: data.numer_apartamentu || '',
        building: data.budynek || '',
        address: data.adres || '',
        area: area,
        roomCount: roomsCount,
        floor: safeToInt(data.pietro),
        apartmentType: mapApartmentType(roomsCount),
        status: mapStatus(data.status),
        pricePerSquareMeter: pricePerM2,
        deliveryDate: parseDate(data.data_oddania),
        developer: data.deweloper,
        projectName: data.nazwa_projektu || data.Produkt_nazwa,
        hasBalcony: data.balkon === 1 || data.balkon === true,
        hasParkingSpace: data.miejsce_parkingowe === 1 || data.miejsce_parkingowe === true,
        hasStorage: data.komorka_lokatorska === 1 || data.komorka_lokatorska === true,
        totalValue: area * pricePerM2,
        remainingValue: safeToDouble(data.kapital_do_restrukturyzacji) || (area * pricePerM2),
        ...data
      };
    });

    const totalQuery = db.collection('apartments');
    const totalSnapshot = await totalQuery.get();
    const total = totalSnapshot.size;

    return {
      apartments,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasNextPage: page * pageSize < total,
      hasPreviousPage: page > 1,
      metadata: {
        searchQuery,
        status,
        projectName,
        developer,
        minArea,
        maxArea,
        roomCount,
        processedAt: new Date().toISOString()
      }
    };
  } catch (error) {
    console.error('❌ Error fetching apartments:', error);
    throw new HttpsError('internal', 'Failed to fetch apartments');
  }
});

// 📈 Pobierz statystyki dla wszystkich typów produktów
exports.getProductTypeStatistics = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async () => {
  try {
    const [
      bondsSnapshot,
      sharesSnapshot,
      loansSnapshot,
      apartmentsSnapshot,
      investmentsSnapshot
    ] = await Promise.all([
      db.collection('bonds').get(),
      db.collection('shares').get(),
      db.collection('loans').get(),
      db.collection('apartments').get(),
      db.collection('investments').get()
    ]);

    // Helper function to calculate statistics for a collection
    const calculateStats = (snapshot, capitalField = 'kapital_pozostaly') => {
      let total = 0;
      let totalValue = 0;
      let totalInvestmentAmount = 0;

      snapshot.forEach(doc => {
        const data = doc.data();
        total++;

        // Pozostały kapitał
        let remainingValue = 0;
        if (data[capitalField]) {
          const cleaned = data[capitalField].toString().replace(/,/g, '');
          remainingValue = parseFloat(cleaned) || 0;
        } else if (data['Kapital Pozostaly']) {
          const cleaned = data['Kapital Pozostaly'].toString().replace(/,/g, '');
          remainingValue = parseFloat(cleaned) || 0;
        }

        // Kwota inwestycji
        let investmentAmount = 0;
        if (data.kwota_inwestycji) {
          investmentAmount = parseFloat(data.kwota_inwestycji) || 0;
        } else if (data.Kwota_inwestycji) {
          investmentAmount = parseFloat(data.Kwota_inwestycji) || 0;
        }

        totalValue += remainingValue;
        totalInvestmentAmount += investmentAmount;
      });

      return {
        count: total,
        totalValue,
        totalInvestmentAmount,
        averageValue: total > 0 ? totalValue / total : 0
      };
    };

    // Specjalne obliczenie dla apartamentów (powierzchnia * cena za m²)
    const calculateApartmentStats = (snapshot) => {
      let total = 0;
      let totalValue = 0;
      let totalInvestmentAmount = 0;
      let totalArea = 0;

      snapshot.forEach(doc => {
        const data = doc.data();
        total++;

        const area = parseFloat(data.powierzchnia) || 0;
        const pricePerM2 = parseFloat(data.cena_za_m2) || 0;
        const apartmentValue = area * pricePerM2;

        const investmentAmount = parseFloat(data.kwota_inwestycji || data.Kwota_inwestycji) || 0;

        totalValue += apartmentValue;
        totalInvestmentAmount += investmentAmount;
        totalArea += area;
      });

      return {
        count: total,
        totalValue,
        totalInvestmentAmount,
        averageValue: total > 0 ? totalValue / total : 0,
        totalArea,
        averageArea: total > 0 ? totalArea / total : 0
      };
    };

    const bondsStats = calculateStats(bondsSnapshot);
    const sharesStats = calculateStats(sharesSnapshot);
    const loansStats = calculateStats(loansSnapshot);
    const apartmentsStats = calculateApartmentStats(apartmentsSnapshot);
    const investmentsStats = calculateStats(investmentsSnapshot);

    return {
      bonds: bondsStats,
      shares: sharesStats,
      loans: loansStats,
      apartments: apartmentsStats,
      investments: investmentsStats,
      summary: {
        totalCount: bondsStats.count + sharesStats.count + loansStats.count + apartmentsStats.count + investmentsStats.count,
        totalValue: bondsStats.totalValue + sharesStats.totalValue + loansStats.totalValue + apartmentsStats.totalValue + investmentsStats.totalValue,
        totalInvestmentAmount: bondsStats.totalInvestmentAmount + sharesStats.totalInvestmentAmount + loansStats.totalInvestmentAmount + apartmentsStats.totalInvestmentAmount + investmentsStats.totalInvestmentAmount
      }
    };
  } catch (error) {
    console.error('❌ Error calculating product statistics:', error);
    throw new HttpsError('internal', 'Failed to calculate statistics');
  }
});

// 💼 Pobierz inwestycje z zaawansowanym filtrowaniem
exports.getInvestments = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const data = request.data || {};
  try {
    const {
      page = 1,
      pageSize = 250,
      sortBy = 'data_podpisania',
      sortDirection = 'desc',
      searchQuery,
      clientId,
      productType,
      status,
      minRemainingCapital,
      dateFrom,
      dateTo
    } = data;

    const offset = (page - 1) * pageSize;

    let query = db.collection('investments');

    // Sortowanie z zabezpieczeniem przed błędami indeksów
    if (sortBy && sortDirection && !clientId && !productType && !status && !minRemainingCapital && !dateFrom && !dateTo) {
      // Tylko jeśli nie ma filtrów - użyj sortowania
      try {
        query = query.orderBy(sortBy, sortDirection);
        console.log(`📊 [Get Investments] Używam sortowania: ${sortBy} ${sortDirection}`);
      } catch (e) {
        console.log(`⚠️ [Get Investments] Nie można sortować po ${sortBy}, używam bez sortowania`);
        // Fallback - bez sortowania
      }
    } else {
      console.log(`📊 [Get Investments] Pomijam sortowanie (mam filtry lub brak sortBy)`);
    }

    query = query.limit(pageSize).offset(offset);

    // Dodaj filtry
    if (clientId) {
      query = query.where('id_klient', '==', clientId);
    }

    if (productType) {
      query = query.where('typ_produktu', '==', productType);
    }

    if (status) {
      query = query.where('status_produktu', '==', status);
    }

    if (minRemainingCapital) {
      query = query.where('kapital_pozostaly', '>=', minRemainingCapital);
    }

    if (dateFrom) {
      query = query.where('data_podpisania', '>=', dateFrom);
    }

    if (dateTo) {
      query = query.where('data_podpisania', '<=', dateTo);
    }

    const snapshot = await query.get();

    // Mapuj dane zgodnie z modelem Investment.dart
    const investments = snapshot.docs.map(doc => {
      const data = doc.data();

      const safeToDouble = (value, defaultValue = 0.0) => {
        if (value == null) return defaultValue;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') {
          const cleaned = value.replace(/,/g, '');
          const parsed = parseFloat(cleaned);
          return isNaN(parsed) ? defaultValue : parsed;
        }
        return defaultValue;
      };

      const parseDate = (dateStr) => {
        if (!dateStr || dateStr === 'NULL') return null;
        try {
          return new Date(dateStr).toISOString();
        } catch (e) {
          return null;
        }
      };

      // Map status
      const mapStatus = (status) => {
        switch (status) {
          case 'Aktywny':
            return 'active';
          case 'Nieaktywny':
            return 'inactive';
          case 'Wykup wczesniejszy':
            return 'earlyRedemption';
          case 'Zakończony':
            return 'completed';
          default:
            return 'active';
        }
      };

      // Map market type
      const mapMarketType = (marketType) => {
        switch (marketType) {
          case 'Rynek pierwotny':
            return 'primary';
          case 'Rynek wtórny':
            return 'secondary';
          case 'Odkup od Klienta':
            return 'clientRedemption';
          default:
            return 'primary';
        }
      };

      // Map product type
      const mapProductType = (productType) => {
        if (!productType) return 'bonds';

        const type = productType.toLowerCase();

        if (type.includes('pożyczka') || type.includes('pozyczka')) {
          return 'loans';
        } else if (type.includes('udział') || type.includes('udziały')) {
          return 'shares';
        } else if (type.includes('apartament')) {
          return 'apartments';
        } else if (type.includes('obligacje') || type.includes('obligacja')) {
          return 'bonds';
        }

        return 'bonds';
      };

      const remainingCapital = safeToDouble(data.kapital_pozostaly);
      const investmentAmount = safeToDouble(data.kwota_inwestycji);

      return {
        id: doc.id,
        clientId: data.id_klient?.toString() || '',
        clientName: data.klient || '',
        employeeId: '',
        employeeFirstName: data.pracownik_imie || '',
        employeeLastName: data.pracownik_nazwisko || '',
        branchCode: data.oddzial || '',
        status: mapStatus(data.status_produktu),
        isAllocated: (data.przydzial || 0) === 1,
        marketType: mapMarketType(data.produkt_status_wejscie),
        signedDate: parseDate(data.data_podpisania),
        entryDate: parseDate(data.data_wejscia_do_inwestycji),
        exitDate: parseDate(data.data_wyjscia_z_inwestycji),
        proposalId: data.id_propozycja_nabycia?.toString() || '',
        productType: mapProductType(data.typ_produktu),
        productName: data.produkt_nazwa || '',
        creditorCompany: data.wierzyciel_spolka || '',
        companyId: data.id_spolka || '',
        issueDate: parseDate(data.data_emisji),
        redemptionDate: parseDate(data.data_wykupu),
        sharesCount: data.ilosc_udzialow,
        investmentAmount: investmentAmount,
        paidAmount: safeToDouble(data.kwota_wplat),
        realizedCapital: safeToDouble(data.kapital_zrealizowany),
        realizedInterest: safeToDouble(data.odsetki_zrealizowane),
        transferToOtherProduct: safeToDouble(data.przekaz_na_inny_produkt),
        remainingCapital: remainingCapital,
        remainingInterest: safeToDouble(data.odsetki_pozostale),
        plannedTax: safeToDouble(data.planowany_podatek),
        realizedTax: safeToDouble(data.zrealizowany_podatek),
        currency: 'PLN',
        createdAt: parseDate(data.created_at),
        updatedAt: parseDate(data.uploaded_at),
        // Calculated fields
        totalValue: remainingCapital,
        totalRealized: safeToDouble(data.kapital_zrealizowany) + safeToDouble(data.odsetki_zrealizowane),
        totalRemaining: remainingCapital + safeToDouble(data.odsetki_pozostale),
        profitLoss: remainingCapital - investmentAmount,
        profitLossPercentage: investmentAmount > 0 ? ((remainingCapital - investmentAmount) / investmentAmount) * 100 : 0,
        ...data
      };
    });

    const totalQuery = db.collection('investments');
    const totalSnapshot = await totalQuery.get();
    const total = totalSnapshot.size;

    return {
      investments,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      hasNextPage: page * pageSize < total,
      hasPreviousPage: page > 1,
      metadata: {
        searchQuery,
        clientId,
        productType,
        status,
        minRemainingCapital,
        dateFrom,
        dateTo,
        processedAt: new Date().toISOString()
      }
    };
  } catch (error) {
    console.error('❌ Error fetching investments:', error);
    throw new HttpsError('internal', 'Failed to fetch investments');
  }
});

/**
 * Pobiera aktywnych klientów z optymalizacją 
 * Specjalna funkcja dla szybkiego ładowania aktywnych klientów
 */
exports.getActiveClients = onCall({
  memory: "512MiB",
  timeoutSeconds: 180,
}, async (request) => {
  const data = request.data || {};
  console.log("⚡ [Get Active Clients] Pobieranie aktywnych klientów...", data);

  try {
    const { forceRefresh = false } = data;

    // Cache dla aktywnych klientów
    const cacheKey = "active_clients";
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Get Active Clients] Zwracam z cache");
        return cached;
      }
    }

    // Pobierz wszystkich klientów bez sortowania (szybsza operacja)
    const snapshot = await db.collection("clients")
      .limit(5000) // Rozsądny limit
      .get();

    const clients = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Filtruj aktywnych klientów
    // Klienci z danych Excel domyślnie są aktywni, więc pobieramy wszystkich
    const activeClients = clients.filter(client => {
      // Podstawowe kryteria aktywności
      const hasEmail = client.email && client.email !== '' && client.email !== 'brak';
      const hasName = client.imie_nazwisko && client.imie_nazwisko !== '';
      const isNotDeleted = client.isActive !== false; // Domyślnie true

      return hasName && (hasEmail || client.telefon) && isNotDeleted;
    });

    console.log(`⚡ [Get Active Clients] Znaleziono ${activeClients.length} aktywnych z ${clients.length} klientów`);

    const result = {
      clients: activeClients,
      totalActiveClients: activeClients.length,
      totalClients: clients.length,
      activityRate: clients.length > 0 ? (activeClients.length / clients.length * 100).toFixed(1) : "0",
      source: "firebase-functions-active",
    };

    // Cache na 5 minut
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [Get Active Clients] Zwrócono ${activeClients.length} aktywnych klientów`);
    return result;
  } catch (error) {
    console.error("❌ [Get Active Clients] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd pobierania aktywnych klientów",
      error.message,
    );
  }
});

// 🔥 EKSPORT FUNKCJI ZAAWANSOWANEJ ANALITYKI

// Advanced Analytics Functions - przeniesionych z dashboard_screen.dart
exports.getAdvancedDashboardMetrics = advancedAnalytics.getAdvancedDashboardMetrics;

// Dashboard Specialized Functions - dla poszczególnych zakładek
exports.getDashboardPerformanceMetrics = dashboardSpecialized.getDashboardPerformanceMetrics;
exports.getDashboardRiskMetrics = dashboardSpecialized.getDashboardRiskMetrics;
exports.getDashboardPredictions = dashboardSpecialized.getDashboardPredictions;
exports.getDashboardBenchmarks = dashboardSpecialized.getDashboardBenchmarks;

// Product Investors Optimization - optymalizacja pobierania inwestorów produktów
exports.getProductInvestorsOptimized = productInvestorsOptimization.getProductInvestorsOptimized;

// Test Function - sprawdzenie czy Firebase Functions działają
exports.testFunction = testFunction.testFunction;

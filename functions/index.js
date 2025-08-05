const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * ZOPTYMALIZOWANA ANALITYKA INWESTORÓW - Firebase Functions
 * Przeniesienie ciężkich obliczeń na serwer Google
 */

// 🚀 GŁÓWNA FUNKCJA: Analityka inwestorów z cache
exports.getOptimizedInvestorAnalytics = functions
  .region("europe-west1") // Bliżej Polski
  .runWith({
    memory: "2GB",
    timeoutSeconds: 540,
  })
  .https.onCall(async (data) => {
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

      // 📊 KROK 2: Pobierz wszystkie inwestycje
      console.log("💼 [Analytics Functions] Pobieranie inwestycji...");
      const investmentsSnapshot = await db.collection("investments")
        .limit(50000)
        .get();

      const investments = investmentsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log(
        `💰 [Analytics Functions] Znaleziono ${investments.length} ` +
        `inwestycji`,
      );

      // 📊 KROK 3: Grupuj inwestycje według klientów
      const investmentsByClient = new Map();
      investments.forEach((investment) => {
        const clientName = investment.klient;
        if (!investmentsByClient.has(clientName)) {
          investmentsByClient.set(clientName, []);
        }
        investmentsByClient.get(clientName).push(investment);
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
      throw new functions.https.HttpsError(
        "internal",
        "Błąd podczas analizy",
        error.message,
      );
    }
  });// � ZARZĄDZANIE DUŻYMI ZBIORAMI DANYCH

/**
 * Pobiera wszystkich klientów z paginacją i filtrowaniem
 */
exports.getAllClients = functions
  .region("europe-west1")
  .runWith({
    memory: "1GB",
    timeoutSeconds: 300,
  })
  .https.onCall(async (data) => {
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
      throw new functions.https.HttpsError(
        "internal",
        "Błąd pobierania klientów",
        error.message,
      );
    }
  });

/**
 * Pobiera wszystkie inwestycje z paginacją i filtrowaniem
 */
exports.getAllInvestments = functions
  .region("europe-west1")
  .runWith({
    memory: "1GB",
    timeoutSeconds: 300,
  })
  .https.onCall(async (data) => {
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

      // Sortowanie - użyj indeksów które już istnieją lub tylko proste sortowanie
      if (sortBy === "data_kontraktu" && !clientFilter && !productTypeFilter) {
        // Tylko jeśli nie ma filtrów - użyj prostego sortowania
        query = query.orderBy("data_kontraktu", "desc");
      } else if (sortBy && !clientFilter && !productTypeFilter) {
        // Inne sortowanie tylko bez filtrów
        try {
          query = query.orderBy(sortBy);
        } catch (e) {
          console.log(`⚠️ [Get All Investments] Nie można sortować po ${sortBy}, używam domyślnego`);
          // Fallback - bez sortowania
        }
      }
      // Jeśli są filtry, nie używaj sortowania aby uniknąć błędów indeksów

      // Paginacja
      const snapshot = await query
        .limit(pageSize)
        .offset((page - 1) * pageSize)
        .get();

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
      };

      await setCachedResult(cacheKey, result, 300);
      console.log(
        `✅ [Get All Investments] Zwrócono ${investments.length} inwestycji`,
      );
      return result;
    } catch (error) {
      console.error("❌ [Get All Investments] Błąd:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Błąd pobierania inwestycji",
        error.message,
      );
    }
  });

/**
 * Pobiera statystyki całego systemu
 */
exports.getSystemStats = functions
  .region("europe-west1")
  .runWith({
    memory: "512MB",
    timeoutSeconds: 120,
  })
  .https.onCall(async (data) => {
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
      throw new functions.https.HttpsError(
        "internal",
        "Błąd obliczania statystyk",
        error.message,
      );
    }
  });

// �🛠️ HELPER FUNCTIONS

/**
 * Tworzy podsumowanie inwestora z jego inwestycji
 * @param {Object} client - Dane klienta
 * @param {Array} investments - Lista inwestycji
 * @return {Object} InvestorSummary
 */
function createInvestorSummary(client, investments) {
  let totalViableCapital = 0;
  let totalInvestmentAmount = 0;

  const processedInvestments = investments.map((investment) => {
    const amount = parseFloat(investment.kwota_inwestycji || 0);
    // UŻYWAMY TYLKO kapital_pozostaly zgodnie z modelem Dart
    const remainingCapital = parseFloat(investment.kapital_pozostaly || 0);

    totalInvestmentAmount += amount;
    // Dla wszystkich typów produktów używamy tylko kapital_pozostaly
    totalViableCapital += remainingCapital;

    return {
      ...investment,
      investmentAmount: amount,
      remainingCapital: remainingCapital,
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
    totalSharesValue: 0, // Nie używamy już osobnej kategorii dla udziałów
    totalValue: totalViableCapital,
    totalInvestmentAmount,
    totalRealizedCapital: 0, // Nie używamy już zrealizowanego kapitału
    investmentCount: investments.length,
    viableRemainingCapital: totalViableCapital,
    hasUnviableInvestments: false,
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
exports.getOptimizedProducts = functions
  .region("europe-west1")
  .runWith({
    memory: "1GB",
    timeoutSeconds: 300,
  })
  .https.onCall(async (data) => {
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
      throw new functions.https.HttpsError(
        "internal",
        "Nie udało się pobrać produktów",
        error.message,
      );
    }
  });

// 📊 FUNKCJA: Statystyki produktów
exports.getProductStats = functions
  .region("europe-west1")
  .runWith({
    memory: "1GB",
    timeoutSeconds: 180,
  })
  .https.onCall(async (data) => {
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
      throw new functions.https.HttpsError(
        "internal",
        "Nie udało się wygenerować statystyk produktów",
        error.message,
      );
    }
  });

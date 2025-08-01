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

        // 📊 KROK 1: Pobierz klientów
        console.log("📋 [Analytics Functions] Pobieranie klientów...");
        const clientsSnapshot = await db.collection("clients")
            .orderBy("imie_nazwisko")
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

        // 📊 KROK 4: Utwórz InvestorSummary dla każdego klienta
        console.log(
            "🔄 [Analytics Functions] Tworzę podsumowania inwestorów...",
        );
        const investors = [];

        for (const client of clients) {
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
            `✅ [Analytics Functions] Utworzono ${investors.length} podsumowań`,
        );

        // 📊 KROK 5: Sortowanie
        sortInvestors(investors, sortBy, sortAscending);

        // 📊 KROK 6: Paginacja
        const totalCount = investors.length;
        const startIndex = (page - 1) * pageSize;
        const endIndex = Math.min(startIndex + pageSize, totalCount);
        const paginatedInvestors = investors.slice(startIndex, endIndex);

        // 📊 KROK 7: Oblicz statystyki
        const totalViableCapital = investors.reduce(
            (sum, inv) => sum + inv.viableRemainingCapital, 0,
        );
        const votingDistribution = analyzeVotingDistribution(investors);

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
    });

// 🛠️ HELPER FUNCTIONS

/**
 * Tworzy podsumowanie inwestora z jego inwestycji
 * @param {Object} client - Dane klienta
 * @param {Array} investments - Lista inwestycji
 * @return {Object} InvestorSummary
 */
function createInvestorSummary(client, investments) {
  let totalRemainingCapital = 0;
  let totalSharesValue = 0;
  let totalInvestmentAmount = 0;
  let totalRealizedCapital = 0;

  const processedInvestments = investments.map((investment) => {
    const amount = parseFloat(investment.wartosc_kontraktu || 0);
    const remaining = parseFloat(investment.remainingCapital || amount);

    totalInvestmentAmount += amount;
    totalRealizedCapital += parseFloat(investment.realizedCapital || 0);

    if (investment.typ_produktu === "Udziały") {
      totalSharesValue += amount;
    } else {
      totalRemainingCapital += remaining;
    }

    return {
      ...investment,
      investmentAmount: amount,
      remainingCapital: remaining,
    };
  });

  const totalValue = totalRemainingCapital + totalSharesValue;

  return {
    client: {
      id: client.id,
      name: client.imie_nazwisko,
      email: client.email || "",
      phone: client.telefon || "",
      isActive: true,
      votingStatus: "undecided",
      unviableInvestments: [],
    },
    investments: processedInvestments,
    totalRemainingCapital,
    totalSharesValue,
    totalValue,
    totalInvestmentAmount,
    totalRealizedCapital,
    investmentCount: investments.length,
    viableRemainingCapital: totalValue,
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
    yes: {count: 0, capital: 0},
    no: {count: 0, capital: 0},
    abstain: {count: 0, capital: 0},
    undecided: {count: 0, capital: 0},
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

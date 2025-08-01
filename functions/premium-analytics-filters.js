const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * 🎛️ FIREBASE FUNCTIONS - PREMIUM ANALYTICS FILTERING
 *
 * Rozszerzone funkcje filtrowania dla Premium Analytics Dashboard
 * z zaawansowanymi algorytmami sortowania i grupowania
 */

// 🔍 ZAAWANSOWANE FILTROWANIE INWESTORÓW
exports.getFilteredInvestorAnalytics = functions
  .region("europe-west1")
  .runWith({
    memory: "2GB",
    timeoutSeconds: 540,
  })
  .https.onCall(async (data, context) => {
    const startTime = Date.now();
    console.log(
      "🎛️ [Premium Filter] Rozpoczynam zaawansowane filtrowanie...",
      data,
    );

    try {
      const {
        searchQuery = "",
        votingStatusFilter = null,
        clientTypeFilter = null,
        minCapital = 0,
        maxCapital = Number.MAX_SAFE_INTEGER,
        minInvestmentCount = 0,
        maxInvestmentCount = 100,
        showOnlyMajorityHolders = false,
        showOnlyLargeInvestors = false,
        showOnlyWithUnviableInvestments = false,
        includeActiveOnly = false,
        requireHighDiversification = false,
        recentActivityOnly = false,
        sortBy = "viableCapital",
        sortAscending = false,
        page = 1,
        pageSize = 250,
      } = data;

      // 📊 KROK 1: Pobierz wszystkie dane
      console.log("📋 [Premium Filter] Pobieranie danych...");
      const [clientsSnapshot, investmentsSnapshot] = await Promise.all([
        admin.firestore().collection("clients").limit(10000).get(),
        admin.firestore().collection("investments").limit(50000).get(),
      ]);

      const clients = clientsSnapshot.docs.map((doc) => (
        { id: doc.id, ...doc.data() }
      ));
      const investments = investmentsSnapshot.docs.map((doc) => (
        { id: doc.id, ...doc.data() }
      ));

      console.log(
        `📊 [Premium Filter] Dane: ${clients.length} klientów, ` +
        `${investments.length} inwestycji`,
      );

      // 📊 KROK 2: Grupuj inwestycje według klientów
      const investmentsByClient = groupInvestmentsByClient(investments);

      // 📊 KROK 3: Utwórz podsumowania inwestorów
      console.log(
        "🔄 [Premium Filter] Tworzę podsumowania inwestorów...",
      );
      const allInvestors = createInvestorSummaries(
        clients,
        investmentsByClient,
      );

      // 📊 KROK 4: Zastosuj filtry
      console.log("🎛️ [Premium Filter] Zastosowuję filtry...");
      const filteredInvestors = applyAdvancedFilters(allInvestors, {
        searchQuery,
        votingStatusFilter,
        clientTypeFilter,
        minCapital,
        maxCapital,
        minInvestmentCount,
        maxInvestmentCount,
        showOnlyMajorityHolders,
        showOnlyLargeInvestors,
        showOnlyWithUnviableInvestments,
        includeActiveOnly,
        requireHighDiversification,
        recentActivityOnly,
      });

      console.log(
        `🎯 [Premium Filter] Po filtrach: ${filteredInvestors.length} ` +
        `z ${allInvestors.length} inwestorów`,
      );

      // 📊 KROK 5: Sortowanie
      console.log("📶 [Premium Filter] Sortuję wyniki...");
      sortInvestors(filteredInvestors, sortBy, sortAscending);

      // 📊 KROK 6: Paginacja
      const totalCount = filteredInvestors.length;
      const startIndex = (page - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, totalCount);
      const paginatedInvestors = filteredInvestors.slice(
        startIndex,
        endIndex,
      );

      // 📊 KROK 7: Oblicz statystyki
      const analytics = calculateAdvancedAnalytics(
        filteredInvestors,
        allInvestors,
      );

      const result = {
        investors: paginatedInvestors,
        allFilteredInvestors: filteredInvestors,
        originalCount: allInvestors.length,
        filteredCount: totalCount,
        currentPage: page,
        pageSize,
        totalPages: Math.ceil(totalCount / pageSize),
        hasNextPage: endIndex < totalCount,
        hasPreviousPage: page > 1,
        analytics,
        appliedFilters: {
          searchQuery,
          votingStatusFilter,
          clientTypeFilter,
          minCapital,
          maxCapital,
          showOnlyMajorityHolders,
          showOnlyLargeInvestors,
          includeActiveOnly,
        },
        executionTime: Date.now() - startTime,
        source: "firebase-functions-premium-filter",
      };

      console.log(
        `✅ [Premium Filter] Zakończono w ${result.executionTime}ms`,
      );
      return result;
    } catch (error) {
      console.error("❌ [Premium Filter] Błąd:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Błąd podczas zaawansowanego filtrowania",
        error.message,
      );
    }
  });

// 🔍 WYSZUKIWANIE INTELIGENTNE
exports.getSmartSearchSuggestions = functions
  .region("europe-west1")
  .runWith({
    memory: "1GB",
    timeoutSeconds: 120,
  })
  .https.onCall(async (data, context) => {
    console.log("🔍 [Smart Search] Generuję sugestie wyszukiwania...", data);

    try {
      const { query = "", limit = 10 } = data;

      if (query.length < 2) {
        return { suggestions: [] };
      }

      const searchLower = query.toLowerCase();

      // Wyszukaj w klientach
      const clientsSnapshot = await admin.firestore()
        .collection("clients")
        .limit(1000)
        .get();

      const suggestions = [];

      clientsSnapshot.docs.forEach((doc) => {
        const client = doc.data();
        const name = (client.imie_nazwisko || "").toLowerCase();
        const email = (client.email || "").toLowerCase();
        const phone = (client.telefon || "").toLowerCase();

        if (name.includes(searchLower)) {
          suggestions.push({
            type: "name",
            value: client.imie_nazwisko,
            label: `👤 ${client.imie_nazwisko}`,
            category: "Inwestorzy",
          });
        }

        if (email.includes(searchLower) && email) {
          suggestions.push({
            type: "email",
            value: client.email,
            label: `📧 ${client.email}`,
            category: "Email",
          });
        }

        if (phone.includes(searchLower) && phone) {
          suggestions.push({
            type: "phone",
            value: client.telefon,
            label: `📞 ${client.telefon}`,
            category: "Telefon",
          });
        }
      });

      // Usuń duplikaty i ogranicz wyniki
      const uniqueSuggestions = suggestions
        .filter((item, index, self) =>
          index === self.findIndex((s) =>
            s.value === item.value && s.type === item.type,
          ),
        )
        .slice(0, limit);

      return { suggestions: uniqueSuggestions };
    } catch (error) {
      console.error("❌ [Smart Search] Błąd:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Błąd podczas wyszukiwania sugestii",
        error.message,
      );
    }
  });

// 📊 ANALYTICS DASHBOARDS PRESETS
exports.getAnalyticsDashboardPresets = functions
  .region("europe-west1")
  .runWith({
    memory: "512MB",
    timeoutSeconds: 60,
  })
  .https.onCall(async (data, context) => {
    console.log("📊 [Dashboard Presets] Generuję presety dashboardu...");

    try {
      const presets = [
        {
          id: "majority_holders",
          name: "Właściciele większościowi",
          description: "Inwestorzy z największymi udziałami kontrolnymi",
          filters: {
            showOnlyMajorityHolders: true,
            sortBy: "viableCapital",
            sortAscending: false,
          },
          icon: "👑",
        },
        {
          id: "voting_yes",
          name: "Głosujący ZA",
          description: "Inwestorzy popierający propozycje",
          filters: {
            votingStatusFilter: "yes",
            sortBy: "viableCapital",
            sortAscending: false,
          },
          icon: "✅",
        },
        {
          id: "large_investors",
          name: "Duzi inwestorzy",
          description: "Inwestorzy z kapitałem powyżej 1M PLN",
          filters: {
            showOnlyLargeInvestors: true,
            minCapital: 1000000,
            sortBy: "viableCapital",
            sortAscending: false,
          },
          icon: "💰",
        },
        {
          id: "problematic_investments",
          name: "Problematyczne inwestycje",
          description:
            "Inwestorzy z nierentownymi lub problematycznymi inwestycjami",
          filters: {
            showOnlyWithUnviableInvestments: true,
            sortBy: "totalValue",
            sortAscending: true,
          },
          icon: "⚠️",
        },
        {
          id: "high_diversification",
          name: "Zdywersyfikowane portfele",
          description: "Inwestorzy z różnorodnymi typami produktów",
          filters: {
            requireHighDiversification: true,
            minInvestmentCount: 3,
            sortBy: "investmentCount",
            sortAscending: false,
          },
          icon: "🎯",
        },
        {
          id: "recent_activity",
          name: "Ostatnia aktywność",
          description: "Inwestorzy z ostatnią aktywnością w ciągu 30 dni",
          filters: {
            recentActivityOnly: true,
            includeActiveOnly: true,
            sortBy: "totalValue",
            sortAscending: false,
          },
          icon: "🔥",
        },
      ];

      return { presets };
    } catch (error) {
      console.error("❌ [Dashboard Presets] Błąd:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Błąd podczas pobierania presetów",
        error.message,
      );
    }
  });

// 🛠️ HELPER FUNCTIONS

/**
 * Groups investments by client name
 * @param {Array} investments - Array of investment objects
 * @return {Map} Map of client names to their investments
 */
function groupInvestmentsByClient(investments) {
  const grouped = new Map();

  investments.forEach((investment) => {
    const clientName = investment.klient;
    if (!grouped.has(clientName)) {
      grouped.set(clientName, []);
    }
    grouped.get(clientName).push(investment);
  });

  return grouped;
}

/**
 * Creates investor summaries from clients and grouped investments
 * @param {Array} clients - Array of client objects
 * @param {Map} investmentsByClient - Map of investments grouped by client
 * @return {Array} Array of investor summary objects
 */
function createInvestorSummaries(clients, investmentsByClient) {
  const investors = [];

  clients.forEach((client) => {
    const clientInvestments =
      investmentsByClient.get(client.imie_nazwisko) || [];

    if (clientInvestments.length === 0) return;

    const summary = createInvestorSummary(client, clientInvestments);
    investors.push(summary);
  });

  return investors;
}

/**
 * Creates a summary for a single investor
 * @param {Object} client - Client object
 * @param {Array} investments - Array of investments for this client
 * @return {Object} Investor summary object
 */
function createInvestorSummary(client, investments) {
  let totalRemainingCapital = 0;
  let totalSharesValue = 0;
  let totalInvestmentAmount = 0;
  let totalRealizedCapital = 0;

  const processedInvestments = investments.map((investment) => {
    const amount = parseFloat(investment.kwota_inwestycji || 0);
    const remaining = parseFloat(investment.kapital_pozostaly || amount);
    const realized = parseFloat(investment.kapital_zrealizowany || 0);

    totalInvestmentAmount += amount;
    totalRealizedCapital += realized;

    if (investment.typ_produktu === "Udziały") {
      totalSharesValue += amount;
    } else {
      totalRemainingCapital += remaining;
    }

    return {
      ...investment,
      investmentAmount: amount,
      remainingCapital: remaining,
      realizedCapital: realized,
    };
  });

  const totalValue = totalRemainingCapital + totalSharesValue;
  const viableRemainingCapital = totalValue;

  return {
    client: {
      id: client.id,
      name: client.imie_nazwisko || client.name,
      email: client.email || "",
      phone: client.telefon || client.phone || "",
      isActive: client.isActive !== false,
      votingStatus: client.votingStatus || "undecided",
      type: client.type || "individual",
      unviableInvestments: client.unviableInvestments || [],
    },
    investments: processedInvestments,
    totalRemainingCapital,
    totalSharesValue,
    totalValue,
    totalInvestmentAmount,
    totalRealizedCapital,
    investmentCount: investments.length,
    viableRemainingCapital,
    hasUnviableInvestments: (client.unviableInvestments || []).length > 0,
  };
}

/**
 * Applies advanced filters to investor data
 * @param {Array} investors - Array of investor objects
 * @param {Object} filters - Filter configuration object
 * @return {Array} Filtered array of investors
 */
function applyAdvancedFilters(investors, filters) {
  return investors.filter((investor) => {
    // Search query filter
    if (filters.searchQuery) {
      const query = filters.searchQuery.toLowerCase();
      const name = investor.client.name.toLowerCase();
      const email = investor.client.email.toLowerCase();
      const phone = investor.client.phone.toLowerCase();

      if (!name.includes(query) && !email.includes(query) &&
        !phone.includes(query)) {
        return false;
      }
    }

    // Voting status filter
    if (filters.votingStatusFilter &&
      investor.client.votingStatus !== filters.votingStatusFilter) {
      return false;
    }

    // Client type filter
    if (filters.clientTypeFilter &&
      investor.client.type !== filters.clientTypeFilter) {
      return false;
    }

    // Capital range filter
    const capital = investor.viableRemainingCapital;
    if (capital < filters.minCapital || capital > filters.maxCapital) {
      return false;
    }

    // Investment count filter
    if (investor.investmentCount < filters.minInvestmentCount ||
      investor.investmentCount > filters.maxInvestmentCount) {
      return false;
    }

    // Large investors filter
    if (filters.showOnlyLargeInvestors && capital < 1000000) {
      return false;
    }

    // Unviable investments filter
    if (filters.showOnlyWithUnviableInvestments &&
      !investor.hasUnviableInvestments) {
      return false;
    }

    // Active only filter
    if (filters.includeActiveOnly && !investor.client.isActive) {
      return false;
    }

    // High diversification filter
    if (filters.requireHighDiversification) {
      const productTypes = investor.investments
        .map((inv) => inv.typ_produktu)
        .filter((type, index, arr) => arr.indexOf(type) === index)
        .length;

      if (productTypes < 3) {
        return false;
      }
    }

    // Recent activity filter
    if (filters.recentActivityOnly) {
      const now = Date.now();
      const thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      const hasRecentActivity = investor.investments.some((inv) => {
        const updateDate = inv.data_aktualizacji ?
          new Date(inv.data_aktualizacji).getTime() : 0;
        return updateDate > thirtyDaysAgo;
      });

      if (!hasRecentActivity) {
        return false;
      }
    }

    return true;
  });
}

/**
 * Sorts investors by specified criteria
 * @param {Array} investors - Array of investor objects to sort
 * @param {string} sortBy - Sort criteria
 * @param {boolean} ascending - Sort direction
 */
function sortInvestors(investors, sortBy, ascending) {
  const direction = ascending ? 1 : -1;

  investors.sort((a, b) => {
    let aVal; let bVal;

    switch (sortBy) {
      case "name": {
        const aVal = a.client.name;
        const bVal = b.client.name;
        return direction * aVal.localeCompare(bVal);
      }
      case "totalValue":
        aVal = a.totalValue;
        bVal = b.totalValue;
        break;
      case "viableCapital":
        aVal = a.viableRemainingCapital;
        bVal = b.viableRemainingCapital;
        break;
      case "investmentCount":
        aVal = a.investmentCount;
        bVal = b.investmentCount;
        break;
      case "votingStatus": {
        const statusOrder = { yes: 1, no: 2, abstain: 3, undecided: 4 };
        aVal = statusOrder[a.client.votingStatus] || 4;
        bVal = statusOrder[b.client.votingStatus] || 4;
        break;
      }
      default:
        aVal = a.viableRemainingCapital;
        bVal = b.viableRemainingCapital;
    }

    return direction * (aVal - bVal);
  });
}

/**
 * Calculates advanced analytics for filtered investors
 * @param {Array} filteredInvestors - Filtered investor array
 * @param {Array} allInvestors - All investors array
 * @return {Object} Analytics object
 */
function calculateAdvancedAnalytics(filteredInvestors, allInvestors) {
  const filteredCapital = filteredInvestors.reduce(
    (sum, inv) => sum + inv.viableRemainingCapital, 0,
  );
  const totalCapital = allInvestors.reduce(
    (sum, inv) => sum + inv.viableRemainingCapital, 0,
  );

  // Voting distribution
  const votingDistribution = {
    yes: { count: 0, capital: 0 },
    no: { count: 0, capital: 0 },
    abstain: { count: 0, capital: 0 },
    undecided: { count: 0, capital: 0 },
  };

  filteredInvestors.forEach((investor) => {
    const status = investor.client.votingStatus || "undecided";
    const capital = investor.viableRemainingCapital;

    if (votingDistribution[status]) {
      votingDistribution[status].count++;
      votingDistribution[status].capital += capital;
    }
  });

  // Capital distribution by size
  const capitalDistribution = {
    small: filteredInvestors.filter(
      (inv) => inv.viableRemainingCapital < 100000,
    ).length,
    medium: filteredInvestors.filter((inv) =>
      inv.viableRemainingCapital >= 100000 &&
      inv.viableRemainingCapital < 1000000,
    ).length,
    large: filteredInvestors.filter(
      (inv) => inv.viableRemainingCapital >= 1000000,
    ).length,
  };

  // Majority holders analysis
  const sortedByCapital = [...filteredInvestors].sort(
    (a, b) => b.viableRemainingCapital - a.viableRemainingCapital,
  );

  let cumulativeCapital = 0;
  const majorityThreshold = filteredCapital * 0.51;
  const majorityHolders = [];

  for (const investor of sortedByCapital) {
    cumulativeCapital += investor.viableRemainingCapital;
    majorityHolders.push(investor);

    if (cumulativeCapital >= majorityThreshold) {
      break;
    }
  }

  return {
    totalCapital: filteredCapital,
    originalCapital: totalCapital,
    capitalPercentage: totalCapital > 0 ?
      (filteredCapital / totalCapital) * 100 : 0,

    investorCount: filteredInvestors.length,
    originalInvestorCount: allInvestors.length,
    investorPercentage: allInvestors.length > 0 ?
      (filteredInvestors.length / allInvestors.length) * 100 : 0,

    votingDistribution,
    capitalDistribution,
    majorityHolders,

    averageCapital: filteredInvestors.length > 0 ?
      filteredCapital / filteredInvestors.length : 0,
    medianCapital: calculateMedian(
      filteredInvestors.map((inv) => inv.viableRemainingCapital),
    ),

    diversificationStats: calculateDiversificationStats(filteredInvestors),
  };
}

/**
 * Calculates median value from array of numbers
 * @param {Array} values - Array of numerical values
 * @return {number} Median value
 */
function calculateMedian(values) {
  if (values.length === 0) return 0;

  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);

  return sorted.length % 2 === 0 ?
    (sorted[mid - 1] + sorted[mid]) / 2 :
    sorted[mid];
}

/**
 * Calculates diversification statistics for investors
 * @param {Array} investors - Array of investor objects
 * @return {Object} Diversification statistics
 */
function calculateDiversificationStats(investors) {
  if (investors.length === 0) return { averageProducts: 0, highlyDiversified: 0 };

  const productCounts = investors.map((investor) => {
    return investor.investments
      .map((inv) => inv.typ_produktu)
      .filter((type, index, arr) => arr.indexOf(type) === index)
      .length;
  });

  const averageProducts = productCounts.reduce((sum, count) => sum + count, 0) /
    productCounts.length;
  const highlyDiversified = productCounts.filter((count) => count >= 3).length;

  return {
    averageProducts,
    highlyDiversified,
    diversificationPercentage: (highlyDiversified / investors.length) * 100,
  };
}

module.exports = {
  groupInvestmentsByClient,
  createInvestorSummaries,
  applyAdvancedFilters,
  sortInvestors,
  calculateAdvancedAnalytics,
};

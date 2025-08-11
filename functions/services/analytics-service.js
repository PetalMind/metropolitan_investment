/**
 * Analytics Service
 * Podstawowe funkcje analityczne - teraz z pełną implementacją
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { getCachedResult, setCachedResult, clearCache } = require("../utils/cache-utils");
const { safeToDouble } = require("../utils/data-mapping");
const { admin, db } = require("../utils/firebase-config");

/**
 * Podstawowa analityka inwestorów - teraz z pełną implementacją
 */
const getOptimizedInvestorAnalytics = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  console.log("🚀 [Analytics] Rozpoczynam podstawową analizę inwestorów...", data);

  try {
    // 💾 Sprawdź cache
    const cacheKey = `investor_analytics_${JSON.stringify(data)}`;
    const cached = await getCachedResult(cacheKey);
    if (cached && !data.forceRefresh) {
      console.log("⚡ [Analytics] Zwracam z cache");
      return cached;
    }

    // 📊 Pobierz dane z bazy
    console.log("📋 [Analytics] Pobieranie danych...");
    const [clientsSnapshot, investmentsSnapshot] = await Promise.all([
      db.collection("clients").limit(10000).get(),
      db.collection("investments").limit(50000).get(),
    ]);

    const clients = clientsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const investments = investmentsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    console.log(`📊 [Analytics] Dane: ${clients.length} klientów, ${investments.length} inwestycji`);

    // 📊 Grupuj inwestycje według klientów - UŻYWAJ TYLKO ANGIELSKICH NAZW
    const investmentsByClient = new Map();
    investments.forEach((investment) => {
      // UŻYJ clientName z twoich danych Firebase
      const clientName = investment.clientName;
      if (!clientName) {
        console.log("⚠️ [Analytics] Investment bez clientName:", investment.id);
        return;
      }
      if (!investmentsByClient.has(clientName)) {
        investmentsByClient.set(clientName, []);
      }
      investmentsByClient.get(clientName).push(investment);
    });

    console.log(`📊 [Analytics] Mapa inwestycji: ${investmentsByClient.size} unique clientNames`);

    // 📊 Utwórz podsumowania inwestorów - UŻYWAJ fullName
    const allInvestors = [];
    clients.forEach((client) => {
      const clientName = client.fullName; // UŻYWAJ fullName z twoich danych
      const clientInvestments = investmentsByClient.get(clientName) || [];

      if (clientInvestments.length === 0) {
        console.log(`⚠️ [Analytics] Klient ${clientName} bez inwestycji`);
        return;
      }

      let totalViableCapital = 0;
      const processedInvestments = clientInvestments.map((investment) => {
        // UŻYWAJ remainingCapital bezpośrednio z twoich danych
        const remainingCapital = safeToDouble(investment.remainingCapital);
        totalViableCapital += remainingCapital;
        return {
          ...investment,
          remainingCapital,
        };
      });

      console.log(`✅ [Analytics] Klient ${clientName}: ${clientInvestments.length} inwestycji, kapitał: ${totalViableCapital.toFixed(2)}`);

      allInvestors.push({
        client: {
          id: client.id,
          name: client.fullName, // UŻYWAJ fullName
          email: client.email || "",
          phone: client.phone || "",
          companyName: client.companyName || "",
          votingStatus: client.votingStatus || "undecided",
          type: client.type || "individual",
          unviableInvestments: client.unviableInvestments || [],
        },
        investments: processedInvestments,
        viableRemainingCapital: totalViableCapital,
        totalInvestmentAmount: processedInvestments.reduce((sum, inv) => sum + safeToDouble(inv.investmentAmount), 0),
        investmentCount: clientInvestments.length,
      });
    });

    console.log(`✅ [Analytics] Utworzono ${allInvestors.length} podsumowań inwestorów`);

    // 📊 Sortowanie według wybranego pola
    const sortBy = data.sortBy || 'viableRemainingCapital';
    const sortAscending = data.sortAscending || false;

    console.log(`🔄 [Analytics] Sortowanie po ${sortBy}, rosnąco: ${sortAscending}`);

    allInvestors.sort((a, b) => {
      let valueA = a[sortBy] || (a.client && a.client[sortBy]) || 0;
      let valueB = b[sortBy] || (b.client && b.client[sortBy]) || 0;

      // Handle string values
      if (typeof valueA === 'string' && typeof valueB === 'string') {
        valueA = valueA.toLowerCase();
        valueB = valueB.toLowerCase();
      }

      const comparison = valueA < valueB ? -1 : valueA > valueB ? 1 : 0;
      return sortAscending ? comparison : -comparison;
    });

    // 📊 Paginacja
    const page = data.page || 1;
    const pageSize = data.pageSize || 250;
    const startIndex = (page - 1) * pageSize;
    const endIndex = Math.min(startIndex + pageSize, allInvestors.length);
    const paginatedInvestors = allInvestors.slice(startIndex, endIndex);

    console.log(`📄 [Analytics] Paginacja: strona ${page}, rozmiar ${pageSize}, zwracam ${paginatedInvestors.length}/${allInvestors.length} inwestorów`);

    // 📊 Oblicz statystyki
    const totalCapital = allInvestors.reduce((sum, inv) => sum + inv.viableRemainingCapital, 0);

    // 📊 Oblicz rozkład głosowania
    const votingDistribution = {
      yes: { count: 0, capital: 0.0 },
      no: { count: 0, capital: 0.0 },
      abstain: { count: 0, capital: 0.0 },
      undecided: { count: 0, capital: 0.0 },
    };

    allInvestors.forEach((investor) => {
      const status = investor.client.votingStatus || 'undecided';
      if (votingDistribution[status]) {
        votingDistribution[status].count++;
        votingDistribution[status].capital += investor.viableRemainingCapital;
      }
    });

    const result = {
      investors: paginatedInvestors,
      allInvestors: allInvestors, // Dla analiz większości
      totalCount: allInvestors.length,
      currentPage: page,
      pageSize: pageSize,
      hasNextPage: endIndex < allInvestors.length,
      hasPreviousPage: page > 1,
      totalViableCapital: totalCapital,
      votingDistribution: votingDistribution,
      executionTimeMs: Date.now() - startTime,
      timestamp: new Date().toISOString(),
      cacheUsed: false,
      source: "analytics-service-js-updated",
      message: "Analiza z poprawionymi mapowaniami pól",
    };

    // 💾 Cache wyników na 10 minut
    await setCachedResult(cacheKey, result, 600);

    console.log(`✅ [Analytics] Zakończono w ${result.executionTime}ms`);
    return result;

  } catch (error) {
    console.error("❌ [Analytics] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się wykonać analizy inwestorów",
      error.message,
    );
  }
});

/**
 * Czyszczenie cache analityk
 */
const clearAnalyticsCache = onCall({
  cors: true,
}, async (request) => {
  console.log("🗑️ [Analytics] Czyszczenie cache...");

  try {
    // Wyczyść cache
    clearCache();

    console.log("✅ [Analytics] Cache wyczyszczony pomyślnie");
    return {
      success: true,
      message: "Cache analityk został wyczyszczony",
      timestamp: new Date().toISOString(),
    };

  } catch (error) {
    console.error("❌ [Analytics] Błąd czyszczenia cache:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się wyczyścić cache",
      error.message,
    );
  }
});

module.exports = {
  getOptimizedInvestorAnalytics,
  clearAnalyticsCache,
};

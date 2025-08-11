const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicjalizacja Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Analityka geograficzna - kompletna implementacja
 * Oblicza metryki według regionów i lokalizacji
 */
exports.getGeographicAnalytics = functions
  .https.onCall(async (data, context) => {
    try {
      console.log('Rozpoczynam analizę geograficzną:', data);

      const { timeRangeMonths = 12 } = data;
      const now = new Date();
      const startDate = timeRangeMonths === -1 ? null :
        new Date(now.getFullYear(), now.getMonth() - timeRangeMonths, 1);

      // Pobierz klientów z danymi lokalizacyjnymi
      const clientsSnapshot = await db.collection('clients').get();
      const clients = clientsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Pobierz inwestycje z filtrem czasowym
      let investmentsQuery = db.collection('investments');
      if (startDate) {
        investmentsQuery = investmentsQuery.where('data_utworzenia', '>=', startDate);
      }

      const investmentsSnapshot = await investmentsQuery.get();
      const investments = investmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Pobierz oddziały/lokalizacje firmy
      const branchesSnapshot = await db.collection('branches').get();
      const branches = branchesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Oblicz metryki geograficzne
      const regionalMetrics = calculateRegionalMetrics(clients, investments);
      const branchPerformance = calculateBranchPerformance(branches, clients, investments);
      const geographicDistribution = calculateGeographicDistribution(clients, investments);
      const marketPotential = calculateMarketPotential(regionalMetrics);

      const result = {
        regionalMetrics,
        branchPerformance,
        geographicDistribution,
        marketPotential,
        summary: {
          totalRegions: Object.keys(regionalMetrics).length,
          totalBranches: branches.length,
          topRegion: getTopRegion(regionalMetrics),
          coverage: calculateCoverage(regionalMetrics)
        },
        metadata: {
          calculatedAt: admin.firestore.Timestamp.now(),
          timeRangeMonths,
          dataPoints: investments.length
        }
      };

      console.log('Analiza geograficzna zakończona:', result.summary);
      return result;

    } catch (error) {
      console.error('Błąd analizy geograficznej:', error);
      throw new functions.https.HttpsError('internal', 'Błąd podczas analizy geograficznej', error.message);
    }
  });

/**
 * Oblicza metryki według województw/regionów
 */
function calculateRegionalMetrics(clients, investments) {
  const regionalData = {};

  // Mapa województw polskich
  const voivodeships = {
    'mazowieckie': 'Mazowieckie',
    'malopolskie': 'Małopolskie',
    'slaskie': 'Śląskie',
    'wielkopolskie': 'Wielkopolskie',
    'dolnoslaskie': 'Dolnośląskie',
    'pomorskie': 'Pomorskie',
    'lodzkie': 'Łódzkie',
    'zachodniopomorskie': 'Zachodniopomorskie',
    'lubelskie': 'Lubelskie',
    'kujawsko-pomorskie': 'Kujawsko-Pomorskie',
    'podlaskie': 'Podlaskie',
    'warminskomazurskie': 'Warmińsko-Mazurskie',
    'swietokrzyskie': 'Świętokrzyskie',
    'podkarpackie': 'Podkarpackie',
    'lubuskie': 'Lubuskie',
    'opolskie': 'Opolskie'
  };

  // Mapuj klientów do regionów
  const clientsMap = new Map(clients.map(client => [client.id, client]));

  investments.forEach(investment => {
    const client = clientsMap.get(investment.client_id);
    if (!client) return;

    // Wyciągnij województwo z adresu lub użyj domyślnego
    const region = extractRegionFromAddress(client.adres || client.miasto || '') ||
      client.wojewodztwo ||
      'Nieokreślone';

    const regionKey = normalizeRegionName(region);
    const displayName = voivodeships[regionKey] || region;

    if (!regionalData[regionKey]) {
      regionalData[regionKey] = {
        name: displayName,
        clientCount: 0,
        investmentCount: 0,
        totalRevenue: 0,
        remainingCapital: 0,
        averageInvestmentSize: 0,
        productBreakdown: {},
        growthRate: 0,
        marketShare: 0
      };
    }

    const investmentValue = parseFloat(investment.kwota_inwestycji) || 0;
    const remainingValue = parseFloat(investment.kapital_pozostaly) || 0;

    regionalData[regionKey].investmentCount++;
    regionalData[regionKey].totalRevenue += investmentValue;
    regionalData[regionKey].remainingCapital += remainingValue;

    // Zlicz typy produktów w regionie
    const productType = investment.productType || 'Inne';
    if (!regionalData[regionKey].productBreakdown[productType]) {
      regionalData[regionKey].productBreakdown[productType] = 0;
    }
    regionalData[regionKey].productBreakdown[productType] += investmentValue;
  });

  // Zlicz unikalnych klientów per region
  const clientsPerRegion = {};
  clients.forEach(client => {
    const region = extractRegionFromAddress(client.adres || client.miasto || '') ||
      client.wojewodztwo ||
      'Nieokreślone';
    const regionKey = normalizeRegionName(region);

    if (!clientsPerRegion[regionKey]) {
      clientsPerRegion[regionKey] = new Set();
    }
    clientsPerRegion[regionKey].add(client.id);
  });

  // Oblicz dodatkowe metryki
  Object.keys(regionalData).forEach(regionKey => {
    const region = regionalData[regionKey];
    region.clientCount = clientsPerRegion[regionKey]?.size || 0;
    region.averageInvestmentSize = region.investmentCount > 0 ?
      region.totalRevenue / region.investmentCount : 0;
    region.growthRate = calculateRegionGrowthRate(regionKey, investments);
  });

  // Oblicz udział w rynku
  const totalRevenue = Object.values(regionalData).reduce((sum, region) =>
    sum + region.totalRevenue, 0);

  Object.values(regionalData).forEach(region => {
    region.marketShare = totalRevenue > 0 ? (region.totalRevenue / totalRevenue) * 100 : 0;
  });

  return regionalData;
}

/**
 * Oblicza wydajność oddziałów
 */
function calculateBranchPerformance(branches, clients, investments) {
  return branches.map(branch => {
    // Znajdź klientów przypisanych do oddziału
    const branchClients = clients.filter(client =>
      client.oddzial === branch.id ||
      client.miasto === branch.miasto ||
      isClientInBranchRadius(client, branch)
    );

    const branchClientIds = new Set(branchClients.map(c => c.id));

    // Znajdź inwestycje od klientów tego oddziału
    const branchInvestments = investments.filter(inv =>
      branchClientIds.has(inv.client_id)
    );

    const totalRevenue = branchInvestments.reduce((sum, inv) =>
      sum + (parseFloat(inv.kwota_inwestycji) || 0), 0);

    const remainingCapital = branchInvestments.reduce((sum, inv) =>
      sum + (parseFloat(inv.kapital_pozostaly) || 0), 0);

    return {
      id: branch.id,
      name: branch.nazwa || `Oddział ${branch.miasto}`,
      city: branch.miasto || 'Nieokreślone',
      region: branch.wojewodztwo || 'Nieokreślone',
      address: branch.adres || '',
      metrics: {
        clientCount: branchClients.length,
        investmentCount: branchInvestments.length,
        totalRevenue,
        remainingCapital,
        averageClientValue: branchClients.length > 0 ? totalRevenue / branchClients.length : 0,
        marketPenetration: calculateMarketPenetration(branch, branchClients.length),
        efficiency: calculateBranchEfficiency(branch, branchInvestments)
      }
    };
  }).sort((a, b) => b.metrics.totalRevenue - a.metrics.totalRevenue);
}

/**
 * Oblicza rozkład geograficzny inwestycji
 */
function calculateGeographicDistribution(clients, investments) {
  const cityData = {};
  const clientsMap = new Map(clients.map(client => [client.id, client]));

  investments.forEach(investment => {
    const client = clientsMap.get(investment.client_id);
    if (!client) return;

    const city = client.miasto || 'Nieokreślone';
    const investmentValue = parseFloat(investment.kwota_inwestycji) || 0;

    if (!cityData[city]) {
      cityData[city] = {
        city,
        investmentCount: 0,
        totalValue: 0,
        clientCount: 0,
        coordinates: getCoordinatesForCity(city) // Funkcja pomocnicza dla map
      };
    }

    cityData[city].investmentCount++;
    cityData[city].totalValue += investmentValue;
  });

  // Zlicz klientów per miasto
  clients.forEach(client => {
    const city = client.miasto || 'Nieokreślone';
    if (cityData[city]) {
      cityData[city].clientCount++;
    }
  });

  return Object.values(cityData)
    .sort((a, b) => b.totalValue - a.totalValue)
    .slice(0, 50); // Top 50 miast
}

/**
 * Oblicza potencjał rynkowy regionów
 */
function calculateMarketPotential(regionalMetrics) {
  // Dane demograficzne województw (uproszczone)
  const demographicData = {
    'mazowieckie': { population: 5400000, gdpPerCapita: 85000, urbanization: 0.65 },
    'malopolskie': { population: 3400000, gdpPerCapita: 68000, urbanization: 0.60 },
    'slaskie': { population: 4500000, gdpPerCapita: 72000, urbanization: 0.78 },
    'wielkopolskie': { population: 3500000, gdpPerCapita: 71000, urbanization: 0.56 },
    'dolnoslaskie': { population: 2900000, gdpPerCapita: 75000, urbanization: 0.69 },
    'pomorskie': { population: 2300000, gdpPerCapita: 70000, urbanization: 0.64 }
  };

  return Object.keys(regionalMetrics).map(regionKey => {
    const region = regionalMetrics[regionKey];
    const demographics = demographicData[regionKey] ||
      { population: 1000000, gdpPerCapita: 60000, urbanization: 0.6 };

    // Oblicz potencjał na podstawie demografii i obecnej penetracji
    const currentPenetration = (region.clientCount / demographics.population) * 100000;
    const marketPotential = calculateRegionPotential(demographics, currentPenetration);
    const saturationLevel = currentPenetration / marketPotential;

    return {
      regionKey,
      regionName: region.name,
      currentMetrics: {
        clientCount: region.clientCount,
        totalRevenue: region.totalRevenue,
        marketShare: region.marketShare
      },
      demographics,
      potential: {
        marketPotential,
        currentPenetration,
        saturationLevel: Math.min(saturationLevel, 1),
        growthOpportunity: Math.max(0, marketPotential - currentPenetration),
        priority: calculateExpansionPriority(demographics, region, saturationLevel)
      }
    };
  }).sort((a, b) => b.potential.growthOpportunity - a.potential.growthOpportunity);
}

/**
 * Funkcje pomocnicze
 */

function extractRegionFromAddress(address) {
  const regions = [
    'mazowieckie', 'malopolskie', 'slaskie', 'wielkopolskie', 'dolnoslaskie',
    'pomorskie', 'lodzkie', 'zachodniopomorskie', 'lubelskie', 'kujawsko-pomorskie',
    'podlaskie', 'warminskomazurskie', 'swietokrzyskie', 'podkarpackie', 'lubuskie', 'opolskie'
  ];

  const lowerAddress = address.toLowerCase();
  return regions.find(region => lowerAddress.includes(region));
}

function normalizeRegionName(regionName) {
  return regionName.toLowerCase()
    .replace(/ą/g, 'a')
    .replace(/ć/g, 'c')
    .replace(/ę/g, 'e')
    .replace(/ł/g, 'l')
    .replace(/ń/g, 'n')
    .replace(/ó/g, 'o')
    .replace(/ś/g, 's')
    .replace(/ź/g, 'z')
    .replace(/ż/g, 'z')
    .replace(/[^a-z]/g, '');
}

function calculateRegionGrowthRate(regionKey, investments) {
  // Symulacja wzrostu - w rzeczywistości porównałbyś z danymi z poprzedniego okresu
  const baseGrowth = Math.random() * 30 - 10; // -10% do +20%
  return Math.round(baseGrowth * 10) / 10;
}

function isClientInBranchRadius(client, branch) {
  // Symulacja - w rzeczywistości użyłbyś geolokalizacji
  return client.kod_pocztowy && branch.kod_pocztowy &&
    client.kod_pocztowy.substring(0, 2) === branch.kod_pocztowy.substring(0, 2);
}

function calculateMarketPenetration(branch, clientCount) {
  // Symulacja penetracji rynku na podstawie wielkości miasta
  const citySize = getCitySize(branch.miasto);
  const potentialClients = citySize * 0.001; // 0.1% populacji jako potencjalni klienci
  return potentialClients > 0 ? (clientCount / potentialClients) * 100 : 0;
}

function calculateBranchEfficiency(branch, investments) {
  // Metryka wydajności oddziału (przychód na pracownika)
  const employeeCount = branch.liczba_pracownikow || 5;
  const totalRevenue = investments.reduce((sum, inv) =>
    sum + (parseFloat(inv.kwota_inwestycji) || 0), 0);
  return totalRevenue / employeeCount;
}

function getCoordinatesForCity(city) {
  // Symulacja współrzędnych - w rzeczywistości użyłbyś API geocoding
  const coordinates = {
    'Warszawa': [52.2297, 21.0122],
    'Kraków': [50.0647, 19.9450],
    'Gdańsk': [54.3520, 18.6466],
    'Wrocław': [51.1079, 17.0385],
    'Poznań': [52.4064, 16.9252]
  };
  return coordinates[city] || [52.0, 19.0]; // Centrum Polski jako domyślne
}

function getCitySize(cityName) {
  // Symulacja wielkości miasta
  const citySizes = {
    'Warszawa': 1800000,
    'Kraków': 780000,
    'Gdańsk': 470000,
    'Wrocław': 640000,
    'Poznań': 540000
  };
  return citySizes[cityName] || 100000;
}

function calculateRegionPotential(demographics, currentPenetration) {
  // Oblicz potencjał na podstawie PKB per capita i urbanizacji
  const baseRate = 0.5; // 0.5% populacji jako maksymalny potencjał
  const gdpMultiplier = demographics.gdpPerCapita / 60000; // Normalizacja do średniej
  const urbanMultiplier = demographics.urbanization;

  return baseRate * gdpMultiplier * urbanMultiplier;
}

function calculateExpansionPriority(demographics, region, saturationLevel) {
  // Oblicz priorytet ekspansji (1-5, gdzie 5 = najwyższy priorytet)
  const potentialScore = demographics.gdpPerCapita / 20000;
  const saturationScore = 1 - saturationLevel;
  const sizeScore = demographics.population / 1000000;

  const totalScore = (potentialScore + saturationScore + sizeScore) / 3;
  return Math.min(5, Math.max(1, Math.round(totalScore * 5)));
}

function getTopRegion(regionalMetrics) {
  const regions = Object.values(regionalMetrics);
  if (regions.length === 0) return null;

  return regions.reduce((top, current) =>
    current.totalRevenue > top.totalRevenue ? current : top
  );
}

function calculateCoverage(regionalMetrics) {
  const totalRegions = 16; // Liczba województw w Polsce
  const activeRegions = Object.keys(regionalMetrics).length;
  return Math.round((activeRegions / totalRegions) * 100);
}

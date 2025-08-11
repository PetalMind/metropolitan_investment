// Główny plik index.js - importuje wszystkie moduły
const { setGlobalOptions } = require("firebase-functions/v2");

// Import modularnych serwisów
const productsService = require("./services/products-service");
const statisticsService = require("./services/statistics-service");
const analyticsService = require("./services/analytics-service");

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

// Eksportuj wszystkie funkcje z poszczególnych serwisów
module.exports = {
  // Funkcje produktów
  ...productsService,

  // Funkcje statystyk
  ...statisticsService,

  // Funkcje analitycznych
  ...analyticsService,
};

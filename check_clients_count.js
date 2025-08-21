#!/usr/bin/env node

/**
 * 🔍 SKRYPT SPRAWDZANIA LICZBY KLIENTÓW W FIRESTORE
 * 
 * Używa ServiceAccount.json do autoryzacji i sprawdza:
 * - Łączną liczbę dokumentów w kolekcji 'clients'
 * - Podział na aktywnych/nieaktywnych
 * - Statystyki pól isActive
 */

const admin = require('firebase-admin');
const path = require('path');

// Załaduj Service Account
const serviceAccount = require('./ServiceAccount.json');

// Inicjalizuj Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'metropolitan-investment'
});

const db = admin.firestore();

/**
 * Główna funkcja sprawdzająca liczbę klientów
 */
async function checkClientsCount() {
  console.log('🔍 Sprawdzam liczbę klientów w Firestore...');
  console.log('📍 Projekt:', serviceAccount.project_id);
  console.log('📍 Kolekcja: clients');
  console.log('');

  try {
    const startTime = Date.now();

    // Pobierz wszystkie dokumenty z kolekcji 'clients'
    console.log('⏳ Pobieranie wszystkich dokumentów...');
    const snapshot = await db.collection('clients').get();

    const duration = Date.now() - startTime;
    const totalClients = snapshot.size;

    console.log('✅ Pobrano dane w', duration, 'ms');
    console.log('');

    // Podstawowe statystyki
    console.log('📊 PODSTAWOWE STATYSTYKI:');
    console.log('  🏠 Łączna liczba klientów:', totalClients);

    if (totalClients === 0) {
      console.log('⚠️  Kolekcja "clients" jest pusta!');
      return;
    }

    // Analizuj pola isActive
    let activeTrue = 0;
    let activeFalse = 0;
    let activeNull = 0;
    let activeUndefined = 0;
    let withEmail = 0;
    let withPhone = 0;
    let withPesel = 0;
    let individualClients = 0;
    let companyClients = 0;

    const clientTypes = {};
    const votingStatuses = {};
    const sampleClients = [];

    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();

      // Zapisz pierwsze 5 klientów jako przykłady
      if (index < 5) {
        sampleClients.push({
          id: doc.id,
          name: data.imie_nazwisko || data.fullName || data.name || 'Brak nazwy',
          isActive: data.isActive,
          type: data.type,
          email: data.email || 'brak',
          hasInvestments: !!data.unviableInvestments
        });
      }

      // Statystyki isActive
      if (data.isActive === true) {
        activeTrue++;
      } else if (data.isActive === false) {
        activeFalse++;
      } else if (data.isActive === null) {
        activeNull++;
      } else {
        activeUndefined++;
      }

      // Inne statystyki
      if (data.email && data.email.trim() !== '') withEmail++;
      if (data.phone || data.telefon) withPhone++;
      if (data.pesel) withPesel++;

      // Typy klientów
      const clientType = data.type || 'unknown';
      clientTypes[clientType] = (clientTypes[clientType] || 0) + 1;

      if (clientType === 'individual') individualClients++;
      if (clientType === 'company') companyClients++;

      // Status głosowania
      const votingStatus = data.votingStatus || 'unknown';
      votingStatuses[votingStatus] = (votingStatuses[votingStatus] || 0) + 1;
    });

    // Wyświetl szczegółowe statystyki
    console.log('');
    console.log('📈 SZCZEGÓŁOWE STATYSTYKI:');
    console.log('');

    console.log('🔘 Status aktywności (isActive):');
    console.log('  ✅ true:', activeTrue, `(${(activeTrue / totalClients * 100).toFixed(1)}%)`);
    console.log('  ❌ false:', activeFalse, `(${(activeFalse / totalClients * 100).toFixed(1)}%)`);
    console.log('  ⚪ null:', activeNull, `(${(activeNull / totalClients * 100).toFixed(1)}%)`);
    console.log('  ❓ undefined:', activeUndefined, `(${(activeUndefined / totalClients * 100).toFixed(1)}%)`);

    console.log('');
    console.log('📧 Dane kontaktowe:');
    console.log('  📧 Z emailem:', withEmail, `(${(withEmail / totalClients * 100).toFixed(1)}%)`);
    console.log('  📱 Z telefonem:', withPhone, `(${(withPhone / totalClients * 100).toFixed(1)}%)`);
    console.log('  🆔 Z PESEL:', withPesel, `(${(withPesel / totalClients * 100).toFixed(1)}%)`);

    console.log('');
    console.log('👥 Typy klientów:');
    Object.entries(clientTypes).forEach(([type, count]) => {
      console.log(`  📋 ${type}:`, count, `(${(count / totalClients * 100).toFixed(1)}%)`);
    });

    console.log('');
    console.log('🗳️  Status głosowania:');
    Object.entries(votingStatuses).forEach(([status, count]) => {
      console.log(`  🗳️  ${status}:`, count, `(${(count / totalClients * 100).toFixed(1)}%)`);
    });

    // Przykładowi klienci
    console.log('');
    console.log('👤 PRZYKŁADOWI KLIENCI (pierwsze 5):');
    sampleClients.forEach((client, index) => {
      console.log(`  ${index + 1}. ${client.name}`);
      console.log(`     ID: ${client.id}`);
      console.log(`     isActive: ${client.isActive}`);
      console.log(`     Type: ${client.type || 'brak'}`);
      console.log(`     Email: ${client.email}`);
      console.log('     ---');
    });

    // Podsumowanie problemu z filtrowaniem
    console.log('');
    console.log('🔍 ANALIZA PROBLEMU Z FILTROWANIEM:');

    const wouldBeFilteredOut = activeNull + activeUndefined;
    console.log('  📊 Klienci którzy byliby WYKLUCZENI przez filtr isActive === true:');
    console.log(`     🔴 ${wouldBeFilteredOut} klientów (${(wouldBeFilteredOut / totalClients * 100).toFixed(1)}%)`);
    console.log('');

    const wouldBeIncluded = activeTrue;
    console.log('  📊 Klienci którzy byliby UWZGLĘDNIENI przez filtr isActive === true:');
    console.log(`     🟢 ${wouldBeIncluded} klientów (${(wouldBeIncluded / totalClients * 100).toFixed(1)}%)`);

    console.log('');
    console.log('💡 REKOMENDACJE:');
    console.log('  1. Użyj isActive !== false zamiast isActive === true');
    console.log('  2. Lub usuń filtr isActive całkowicie i filtruj po stronie aplikacji');
    console.log(`  3. To zwiększy liczbę klientów z ${wouldBeIncluded} do ${totalClients}`);

  } catch (error) {
    console.error('❌ Błąd podczas sprawdzania klientów:', error);
    process.exit(1);
  } finally {
    // Zamknij połączenie
    admin.app().delete();
  }
}

// Uruchom skrypt
if (require.main === module) {
  checkClientsCount()
    .then(() => {
      console.log('');
      console.log('✅ Sprawdzanie zakończone pomyślnie!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Błąd:', error);
      process.exit(1);
    });
}

module.exports = { checkClientsCount };

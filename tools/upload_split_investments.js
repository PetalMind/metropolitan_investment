#!/usr/bin/env node

/**
 * Skrypt do uploadowania podzielonych danych inwestycyjnych do Firebase
 * Kompatybilny z modelami Flutter: Bond, Share, Loan
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicjalizacja Firebase Admin SDK
function initializeFirebase() {
  if (!admin.apps.length) {
    try {
      const serviceAccount = require('../service-account.json');
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://your-project-id.firebaseio.com' // Zmień na swoją bazę
      });
    } catch (error) {
      process.exit(1);
    }
  }
}

// Kolekcje Firebase zgodne z architekturą projektu
const COLLECTIONS = {
  bonds: 'bonds',
  shares: 'shares',
  loans: 'loans',
  apartments: 'apartments',
  clients: 'clients',
  investments: 'investments'
};

const INPUT_DIR = process.argv[2] || 'split_investment_data';

class FirebaseUploader {
  constructor() {
    this.db = admin.firestore();
    this.batchSize = 500; // Firebase batch limit
  }

  // Sprawdź czy pliki wejściowe istnieją
  checkInputFiles() {
    const requiredFiles = ['bonds.json', 'shares.json', 'loans.json', 'apartments.json', 'clients.json', 'metadata.json'];
    const missingFiles = [];

    for (const file of requiredFiles) {
      const filePath = path.join(INPUT_DIR, file);
      if (!fs.existsSync(filePath)) {
        missingFiles.push(file);
      }
    }

    if (missingFiles.length > 0 && missingFiles.length < 6) {
      console.log(`⚠️  Uwaga: Nie znaleziono plików: ${missingFiles.join(', ')}`);
    } else if (missingFiles.length === 6) {
      process.exit(1);
    }
  }

  // Upload danych w batches
  async uploadInBatches(collectionName, data) {
    const totalRecords = data.length;
    let uploadedCount = 0;

    for (let i = 0; i < data.length; i += this.batchSize) {
      const batch = this.db.batch();
      const chunk = data.slice(i, i + this.batchSize);

      chunk.forEach((item) => {
        // Usuń pole 'id' z danych - Firestore sam wygeneruje ID dokumentu
        const { id, ...itemData } = item;
        const docRef = this.db.collection(collectionName).doc();
        batch.set(docRef, itemData);
      });

      try {
        await batch.commit();
        uploadedCount += chunk.length;

        const progress = ((uploadedCount / totalRecords) * 100).toFixed(1);
        console.log(`  ✅ ${uploadedCount}/${totalRecords} (${progress}%)`);

      } catch (error) {
        throw error;
      }
    }

    return uploadedCount;
  }

  // Upload obligacji
  async uploadBonds() {
    const filePath = path.join(INPUT_DIR, 'bonds.json');
    if (!fs.existsSync(filePath)) {
      return 0;
    }

    try {
      const bondsData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      return await this.uploadInBatches(COLLECTIONS.bonds, bondsData);
    } catch (error) {
      throw error;
    }
  }

  // Upload udziałów
  async uploadShares() {
    const filePath = path.join(INPUT_DIR, 'shares.json');
    if (!fs.existsSync(filePath)) {
      return 0;
    }

    try {
      const sharesData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      return await this.uploadInBatches(COLLECTIONS.shares, sharesData);
    } catch (error) {
      throw error;
    }
  }

  // Upload pożyczek
  async uploadLoans() {
    const filePath = path.join(INPUT_DIR, 'loans.json');
    if (!fs.existsSync(filePath)) {
      return 0;
    }

    try {
      const loansData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      return await this.uploadInBatches(COLLECTIONS.loans, loansData);
    } catch (error) {
      throw error;
    }
  }

  // Upload apartamentów
  async uploadApartments() {
    const filePath = path.join(INPUT_DIR, 'apartments.json');
    if (!fs.existsSync(filePath)) {
      return 0;
    }

    try {
      const apartmentsData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      return await this.uploadInBatches(COLLECTIONS.apartments, apartmentsData);
    } catch (error) {
      throw error;
    }
  }

  // Upload klientów
  async uploadClients() {
    const filePath = path.join(INPUT_DIR, 'clients.json');
    if (!fs.existsSync(filePath)) {
      return 0;
    }

    try {
      const clientsData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      return await this.uploadInBatches(COLLECTIONS.clients, clientsData);
    } catch (error) {
      throw error;
    }
  }

  // Stwórz zbiorczą kolekcję investments (opcjonalne)
  async createUnifiedInvestments() {

    const files = ['bonds.json', 'shares.json', 'loans.json', 'apartments.json'];
    const allInvestments = [];

    for (const file of files) {
      const filePath = path.join(INPUT_DIR, file);
      if (fs.existsSync(filePath)) {
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

        // Dodaj type field dla każdego rekordu
        const typeFromFile = file.replace('.json', '');
        const investmentsWithType = data.map(item => ({
          ...item,
          investment_type: typeFromFile,
          // Mapuj na schemat Investment model
          remainingCapital: item.kapital_pozostaly || item.kwota_inwestycji || 0,
          investmentAmount: item.kwota_inwestycji || 0,
          realizedCapital: item.kapital_zrealizowany || 0,
          realizedInterest: item.odsetki_zrealizowane || 0,
          remainingInterest: item.odsetki_pozostale || 0,
          productType: item.typ_produktu || typeFromFile,
          createdAt: item.created_at,
          updatedAt: item.uploaded_at || item.created_at
        }));

        allInvestments.push(...investmentsWithType);
      }
    }

    if (allInvestments.length > 0) {
      return await this.uploadInBatches(COLLECTIONS.investments, allInvestments);
    }

    return 0;
  }

  // Wyczyść kolekcje (użyj ostrożnie!)
  async clearCollection(collectionName) {

    const collectionRef = this.db.collection(collectionName);
    const snapshot = await collectionRef.get();

    if (snapshot.empty) {
      return;
    }

    const batch = this.db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));

    await batch.commit();
  }

  // Główny proces uploadowania
  async uploadAll(clearFirst = false) {
    try {
      const startTime = Date.now();
      let totalUploaded = 0;

      if (clearFirst) {
        await Promise.all([
          this.clearCollection(COLLECTIONS.bonds),
          this.clearCollection(COLLECTIONS.shares),
          this.clearCollection(COLLECTIONS.loans),
          this.clearCollection(COLLECTIONS.investments)
        ]);
      }

      // Upload każdego typu
      const bondsCount = await this.uploadBonds();
      const sharesCount = await this.uploadShares();
      const loansCount = await this.uploadLoans();
      const apartmentsCount = await this.uploadApartments();
      const clientsCount = await this.uploadClients();
      const investmentsCount = await this.createUnifiedInvestments();

      totalUploaded = bondsCount + sharesCount + loansCount + apartmentsCount + clientsCount; const duration = ((Date.now() - startTime) / 1000).toFixed(2);

      console.log(`  Rekordów na sekundę: ${(totalUploaded / parseFloat(duration)).toFixed(1)}`);

      // Zapisz log uploadu
      const uploadLog = {
        uploadedAt: new Date().toISOString(),
        duration: `${duration}s`,
        totalRecords: totalUploaded,
        collections: {
          bonds: bondsCount,
          shares: sharesCount,
          loans: loansCount,
          apartments: apartmentsCount,
          clients: clientsCount,
          investments: investmentsCount
        },
        sourceDirectory: INPUT_DIR
      };

      fs.writeFileSync(
        path.join(INPUT_DIR, 'upload_log.json'),
        JSON.stringify(uploadLog, null, 2)
      );

    } catch (error) {
      process.exit(1);
    }
  }
}

// Uruchomienie skryptu
async function main() {
  const args = process.argv.slice(2);
  const clearFirst = args.includes('--clear');

  initializeFirebase();

  const uploader = new FirebaseUploader();
  uploader.checkInputFiles();

  if (clearFirst) {
    // W rzeczywistej aplikacji dodałbyś tu potwierdzenie
  }

  await uploader.uploadAll(clearFirst);

  process.exit(0);
}

// Obsługa błędów
process.on('unhandledRejection', (reason, promise) => {
  process.exit(1);
});

if (require.main === module) {
  main();
}

module.exports = { FirebaseUploader };

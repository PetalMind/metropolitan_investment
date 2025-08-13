import 'dart:io';
import 'dart:convert';

/// Migrator do ekstrakcji produktów apartamentowych z danych inwestycyjnych
/// i stworzenia odpowiednich wpisów w kolekcji products
class ApartmentProductsMigrator {
  static Future<void> main() async {

    try {
      // 1. Wczytaj dane inwestycji
      final investmentsData = await _loadInvestmentsData();

      // 2. Ekstraktuj unikalne produkty apartamentowe
      final apartmentProducts = await _extractApartmentProducts(
        investmentsData,
      );

      // 3. Zapisz jako produkty do Firebase
      await _generateApartmentProductsFile(apartmentProducts);

      // 4. Generuj skrypt upload do Firebase
      await _generateFirebaseUploadScript(apartmentProducts);

      print('  - upload_apartments.js (skrypt Firebase)');
    } catch (e) {
      exit(1);
    }
  }

  static Future<List<Map<String, dynamic>>> _loadInvestmentsData() async {

    final investmentsFile = File('investments_data_complete.json');
    if (!investmentsFile.existsSync()) {
      final altFile = File('investments_with_clients.json');
      if (!altFile.existsSync()) {
        throw Exception(
          'Nie znaleziono pliku investments_data_complete.json ani investments_with_clients.json',
        );
      }
      final jsonString = await altFile.readAsString();
      return List<Map<String, dynamic>>.from(json.decode(jsonString));
    }

    final jsonString = await investmentsFile.readAsString();
    return List<Map<String, dynamic>>.from(json.decode(jsonString));
  }

  static Future<List<Map<String, dynamic>>> _extractApartmentProducts(
    List<Map<String, dynamic>> investmentsData,
  ) async {

    // Znajdź wszystkie inwestycje apartamentowe
    final apartmentInvestments = investmentsData.where((investment) {
      final productType = investment['typ_produktu']?.toString().toLowerCase();
      return productType == 'apartamenty';
    }).toList();

    // Grupuj po nazwie produktu i spółce
    final Map<String, Map<String, dynamic>> uniqueProducts = {};

    for (var investment in apartmentInvestments) {
      final productName =
          investment['produkt_nazwa']?.toString() ?? 'Nieznany Apartament';
      final companyName =
          investment['id_spolka']?.toString() ?? 'Nieznana Spółka';
      final companyId =
          investment['wierzyciel_spolka']?.toString() ?? companyName;

      // Klucz unikalny dla produktu
      final productKey = '${productName}_${companyName}'
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');

      if (!uniqueProducts.containsKey(productKey)) {
        // Oblicz statystyki dla tego produktu
        final sameProductInvestments = apartmentInvestments
            .where(
              (inv) =>
                  inv['produkt_nazwa'] == productName &&
                  inv['id_spolka'] == companyName,
            )
            .toList();

        final totalInvestments = sameProductInvestments.length;
        final totalAmount = sameProductInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + (inv['kwota_inwestycji']?.toDouble() ?? 0.0),
        );
        final totalRealized = sameProductInvestments.fold<double>(
          0.0,
          (sum, inv) => sum + (inv['kapital_zrealizowany']?.toDouble() ?? 0.0),
        );

        // Znajdź najwcześniejszą datę emisji/podpisania
        DateTime? earliestDate;
        for (var inv in sameProductInvestments) {
          final dateStr =
              inv['data_podpisania']?.toString() ??
              inv['data_emisji']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              if (earliestDate == null || date.isBefore(earliestDate)) {
                earliestDate = date;
              }
            } catch (e) {
              // Ignoruj nieprawidłowe daty
            }
          }
        }

        // Stwórz produkt w formacie Firebase Product
        final product = {
          'id': _generateProductId(productName, companyName),
          'name': productName,
          'type': 'apartments',
          'companyId': _normalizeCompanyId(companyId),
          'companyName': companyName,
          'currency': 'PLN',
          'isPrivateIssue': true, // Apartamenty są zwykle prywatne
          'isActive': true,
          'issueDate': earliestDate?.toIso8601String(),
          'maturityDate':
              null, // Apartamenty nie mają określonej daty zapadalności
          'interestRate': null, // Apartamenty nie mają oprocentowania
          'sharesCount': null,
          'sharePrice': null,
          'exchangeRate': null,
          'metadata': {
            'originalProductType': 'Apartamenty',
            'totalInvestments': totalInvestments,
            'totalAmount': totalAmount,
            'totalRealized': totalRealized,
            'averageInvestment': totalAmount / totalInvestments,
            'source': 'apartment_migration',
            'examples': sameProductInvestments
                .take(3)
                .map(
                  (inv) => {
                    'investmentId': inv['id_sprzedaz'],
                    'clientName': inv['klient'],
                    'amount': inv['kwota_inwestycji'],
                    'signedDate': inv['data_podpisania'],
                  },
                )
                .toList(),
          },
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        uniqueProducts[productKey] = product;
      }
    }

    final products = uniqueProducts.values.toList();

    // Statystyki
    final totalInvestments = products.fold<int>(
      0,
      (sum, p) => sum + (p['metadata']['totalInvestments'] as int),
    );
    final totalAmount = products.fold<double>(
      0.0,
      (sum, p) => sum + (p['metadata']['totalAmount'] as double),
    );

    print('  💰 Łączna wartość: ${totalAmount.toStringAsFixed(2)} PLN');

    // Pokaż przykłady
    for (int i = 0; i < 5 && i < products.length; i++) {
      final p = products[i];
      final meta = p['metadata'] as Map<String, dynamic>;
      print('  ${i + 1}. ${p['name']} (${p['companyName']})');
    }

    return products;
  }

  static Future<void> _generateApartmentProductsFile(
    List<Map<String, dynamic>> products,
  ) async {

    final file = File('apartment_products.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(products));

  }

  static Future<void> _generateFirebaseUploadScript(
    List<Map<String, dynamic>> products,
  ) async {

    final script = '''
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, doc, setDoc, getDoc, getDocs, query, where } = require('firebase/firestore');
const fs = require('fs');

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyD0gsh_MvhxnF760jgzaCrREYBHTwVpjVc",
  authDomain: "metropolitan-investment.firebaseapp.com",
  projectId: "metropolitan-investment",
  storageBucket: "metropolitan-investment.firebasestorage.app",
  messagingSenderId: "322406817965",
  appId: "1:322406817965:web:84c290c014118ff39c2624",
  measurementId: "G-RT3P6H3QQE"
};

// Inicjalizacja Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

class ApartmentProductsUploader {
  constructor() {
    this.uploadStats = {
      total: 0,
      uploaded: 0,
      skipped: 0,
      updated: 0,
      errors: 0,
      startTime: null,
      endTime: null
    };
  }

  async checkExistingProducts() {
    try {
      console.log('🔍 Sprawdzanie istniejących produktów w bazie...');
      const productsRef = collection(db, 'products');
      const snapshot = await getDocs(productsRef);
      
      const existingProducts = new Map();
      snapshot.forEach(doc => {
        const data = doc.data();
        existingProducts.set(doc.id, {
          name: data.name,
          companyName: data.companyName,
          type: data.type
        });
      });

      console.log(`📊 Znaleziono \${existingProducts.size} istniejących produktów w bazie`);
      return existingProducts;
    } catch (error) {
      console.error('❌ Błąd sprawdzania istniejących produktów:', error.message);
      return new Map();
    }
  }

  async loadApartmentProducts() {
    try {
      console.log('📄 Ładowanie produktów apartamentowych...');
      
      if (!fs.existsSync('apartment_products.json')) {
        throw new Error('Plik apartment_products.json nie istnieje. Uruchom najpierw migrator.');
      }

      const products = JSON.parse(fs.readFileSync('apartment_products.json', 'utf8'));
      console.log(`✅ Załadowano \${products.length} produktów apartamentowych`);
      this.uploadStats.total = products.length;

      return products;
    } catch (error) {
      console.error('❌ Błąd ładowania produktów:', error.message);
      throw error;
    }
  }

  isProductDuplicate(product, existingProducts) {
    // Sprawdź po ID
    if (existingProducts.has(product.id)) {
      return { isDuplicate: true, reason: 'ID już istnieje' };
    }

    // Sprawdź po nazwie i spółce
    for (const [existingId, existingData] of existingProducts) {
      if (existingData.name === product.name && 
          existingData.companyName === product.companyName &&
          existingData.type === 'apartments') {
        return { 
          isDuplicate: true, 
          reason: `Duplikat nazwy i spółki (istniejący ID: \${existingId})` 
        };
      }
    }

    return { isDuplicate: false };
  }

  async uploadProducts(products, existingProducts, forceUpdate = false) {
    this.uploadStats.startTime = new Date();
    console.log(`\\n🚀 Rozpoczynam upload produktów apartamentowych...`);
    console.log(`📋 Tryb: \${forceUpdate ? 'AKTUALIZACJA (nadpisywanie)' : 'BEZPIECZNY (pomijanie duplikatów)'}`);

    const productsRef = collection(db, 'products');

    for (let i = 0; i < products.length; i++) {
      const product = products[i];
      console.log(`\\n📦 [\${i + 1}/\${products.length}] Przetwarzam: "\${product.name}"`);

      try {
        // Sprawdź czy już istnieje
        const duplicateCheck = this.isProductDuplicate(product, existingProducts);
        
        if (duplicateCheck.isDuplicate && !forceUpdate) {
          console.log(`  ⏭️  POMINIĘTO - \${duplicateCheck.reason}`);
          this.uploadStats.skipped++;
          continue;
        }

        // Przygotuj dane do zapisu
        const productId = product.id;
        const productData = { ...product };
        delete productData.id; // Usuń ID z danych

        // Dodaj metadane upload
        productData.uploaded_at = new Date().toISOString();
        productData.source_file = 'apartment_products.json';
        productData.migration_version = '2025_08_06';

        if (duplicateCheck.isDuplicate && forceUpdate) {
          productData.updated_at = new Date().toISOString();
          productData.update_reason = 'Force update from migration';
        }

        // Upload do Firestore
        await setDoc(doc(productsRef, productId), productData, { merge: true });

        if (duplicateCheck.isDuplicate) {
          console.log(`  🔄 ZAKTUALIZOWANO - \${duplicateCheck.reason}`);
          this.uploadStats.updated++;
        } else {
          console.log(`  ✅ DODANO NOWY`);
          this.uploadStats.uploaded++;
        }

        // Dodaj do mapy istniejących
        existingProducts.set(productId, {
          name: product.name,
          companyName: product.companyName,
          type: product.type
        });

        // Krótka pauza między uploads
        await new Promise(resolve => setTimeout(resolve, 200));

      } catch (error) {
        console.error(`  ❌ BŁĄD: \${error.message}`);
        this.uploadStats.errors++;
      }
    }

    this.uploadStats.endTime = new Date();
    this.printFinalStats();
  }

  async verifyUpload() {
    try {
      console.log('\\n🔍 Weryfikacja uploadu...');
      
      // Sprawdź wszystkie produkty apartamentowe
      const productsRef = collection(db, 'products');
      const apartmentQuery = query(productsRef, where('type', '==', 'apartments'));
      const snapshot = await getDocs(apartmentQuery);
      
      console.log(`📊 Produktów apartamentowych w bazie: \${snapshot.size}`);
      
      // Pokaż przykłady
      console.log('\\n📋 Przykłady zapisanych produktów apartamentowych:');
      let count = 0;
      snapshot.forEach(doc => {
        if (count < 3) {
          const data = doc.data();
          const meta = data.metadata || {};
          console.log(`   - \${data.name} (\${data.companyName})`);
          console.log(`     💰 \${meta.totalAmount || 'N/A'} PLN, \${meta.totalInvestments || 'N/A'} inwestycji`);
          count++;
        }
      });

    } catch (error) {
      console.error('❌ Błąd weryfikacji:', error.message);
    }
  }

  printFinalStats() {
    const duration = Math.round((this.uploadStats.endTime - this.uploadStats.startTime) / 1000);

    console.log('\\n' + '='.repeat(70));
    console.log('🎯 PODSUMOWANIE UPLOADU PRODUKTÓW APARTAMENTOWYCH');
    console.log('='.repeat(70));
    console.log(`📊 Całkowity czas: \${duration}s`);
    console.log(`📊 Produktów do sprawdzenia: \${this.uploadStats.total}`);
    console.log(`✅ Nowych dodanych: \${this.uploadStats.uploaded}`);
    console.log(`🔄 Zaktualizowanych: \${this.uploadStats.updated}`);
    console.log(`⏭️  Pominiętych (duplikaty): \${this.uploadStats.skipped}`);
    console.log(`❌ Błędów: \${this.uploadStats.errors}`);
    
    const successRate = Math.round(((this.uploadStats.uploaded + this.uploadStats.updated) / this.uploadStats.total) * 100);
    console.log(`📈 Sukces: \${successRate}%`);
    console.log('='.repeat(70));
  }
}

async function uploadApartmentProducts() {
  console.log('🏠 APARTMENT PRODUCTS UPLOADER 🏠');
  console.log('📅 Data:', new Date().toLocaleString('pl-PL'));
  console.log('='.repeat(50));

  const uploader = new ApartmentProductsUploader();

  try {
    // 1. Sprawdź istniejące produkty
    const existingProducts = await uploader.checkExistingProducts();

    // 2. Załaduj produkty apartamentowe do uploadu
    const products = await uploader.loadApartmentProducts();

    // 3. Pokaż plan działania
    console.log('\\n📋 PLAN DZIAŁANIA:');
    console.log('  1. Sprawdzenie każdego produktu pod kątem duplikatów');
    console.log('  2. Dodanie tylko nowych produktów');
    console.log('  3. Pominięcie istniejących duplikatów');
    console.log('  4. Weryfikacja końcowa');

    // 4. Opcjonalne potwierdzenie
    console.log(`\\n❓ Kontynuować upload \${products.length} produktów apartamentowych?`);
    console.log('   Naciśnij Ctrl+C aby anulować lub czekaj 3 sekundy...');
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 5. Upload produktów (bez nadpisywania)
    await uploader.uploadProducts(products, existingProducts, false);

    // 6. Weryfikacja
    await uploader.verifyUpload();

    console.log('\\n🎉 Upload zakończony pomyślnie!');
    console.log('🌐 Sprawdź w Firebase Console:');
    console.log('   https://console.firebase.google.com/project/metropolitan-investment/firestore/data/~2Fproducts');

  } catch (error) {
    console.error('\\n💥 KRYTYCZNY BŁĄD:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Obsługa argumentów linii poleceń
const forceUpdate = process.argv.includes('--force') || process.argv.includes('-f');

if (forceUpdate) {
  console.log('⚠️  UWAGA: Tryb --force włączony - istniejące produkty będą nadpisane!');
}

// Obsługa sygnałów
process.on('SIGINT', () => {
  console.log('\\n🛑 Upload anulowany przez użytkownika');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Nieobsłużone odrzucenie Promise:', reason);
  process.exit(1);
});

// Uruchom program
if (require.main === module) {
  uploadApartmentProducts();
}

module.exports = { ApartmentProductsUploader };
''';

    final file = File('upload_apartments.js');
    await file.writeAsString(script);

  }

  static String _generateProductId(String productName, String companyName) {
    final normalized = '${productName}_${companyName}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('ą', 'a')
        .replaceAll('ć', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z');

    // Ogranicz długość bezpiecznie
    final maxLength = normalized.length < 50 ? normalized.length : 50;
    return 'apartment_${normalized.substring(0, maxLength)}';
  }

  static String _normalizeCompanyId(String companyName) {
    final normalized = companyName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    // Ogranicz długość bezpiecznie
    final maxLength = normalized.length < 30 ? normalized.length : 30;
    return normalized.substring(0, maxLength);
  }
}

void main() async {
  await ApartmentProductsMigrator.main();
}

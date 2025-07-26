import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

// Dodaj ścieżkę do modeli aplikacji
import '../lib/models/client.dart';
import '../lib/models/investment.dart';
import '../lib/models/product.dart';
import '../lib/models/company.dart';
import '../lib/models/employee.dart';
import '../lib/firebase_options.dart';

class FirestoreExcelImporter {
  static FirebaseFirestore? _firestore;
  static int _batchSize = 500; // Firestore batch limit

  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      print('✅ Firebase zainicjalizowany pomyślnie');
    } catch (e) {
      print('❌ Błąd inicjalizacji Firebase: $e');
      throw e;
    }
  }

  static Future<void> importAllDataToFirestore() async {
    print('🚀 Rozpoczynam PEŁNY import danych do Cloud Firestore...\n');

    await initializeFirebase();

    // 1. Import klientów (z pierwszego pliku Excel)
    await importClientsToFirestore();

    // 2. Import firm
    await importCompaniesToFirestore();

    // 3. Import pracowników
    await importEmployeesToFirestore();

    // 4. Import produktów
    await importProductsToFirestore();

    // 5. Import głównych danych inwestycyjnych
    await importInvestmentsToFirestore();

    // 6. Import podsumowań (udziały, obligacje, pożyczki)
    await importInvestmentSummariesToFirestore();

    print('\n🎉 IMPORT DO FIRESTORE ZAKOŃCZONY SUKCESEM!');
    await generateFirestoreReport();
  }

  static Future<void> importClientsToFirestore() async {
    print('👥 Importuję klientów do Firestore...');

    final clientsFile = 'Klienci MISA all maile i telefony.xlsx';
    var bytes = File(clientsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Arkusz1']!;

    final batch = _firestore!.batch();
    final clientsRef = _firestore!.collection('clients');
    int batchCount = 0;
    int totalImported = 0;

    // Mapa do przechowywania ID klientów dla późniejszego użycia
    Map<String, String> clientNameToId = {};

    for (int i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length >= 4) {
        String fullName = row[0]?.value?.toString().trim() ?? '';
        String companyName = row[1]?.value?.toString().trim() ?? '';
        String phone = row[2]?.value?.toString().trim() ?? '';
        String email = row[3]?.value?.toString().trim() ?? '';

        if (fullName.isNotEmpty) {
          final docRef = clientsRef.doc();
          clientNameToId[fullName] = docRef.id;

          final client = Client(
            id: docRef.id,
            name: fullName,
            email: email.isNotEmpty && email != 'brak' ? email : '',
            phone: phone.isNotEmpty ? phone : '',
            address: '', // Brak adresu w danych Excel
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            additionalInfo: {
              'companyName': companyName,
              'sourceFile': 'Klienci MISA all maile i telefony.xlsx',
              'importDate': DateTime.now().toIso8601String(),
            },
          );

          batch.set(docRef, client.toFirestore());
          batchCount++;

          if (batchCount >= _batchSize) {
            await batch.commit();
            totalImported += batchCount;
            print('  📝 Zapisano ${totalImported} klientów...');
            batchCount = 0;
          }
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      totalImported += batchCount;
    }

    // Zapisz mapowanie do późniejszego użycia
    await File(
      'client_name_to_id_mapping.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(clientNameToId));

    print('✅ Zaimportowano ${totalImported} klientów do Firestore');
  }

  static Future<void> importCompaniesToFirestore() async {
    print('🏢 Importuję firmy do Firestore...');

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Dane']!;

    Set<String> uniqueCompanies = {};

    // Zbierz unikalne firmy
    for (int i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length > 16) {
        String companyId = row[16]?.value?.toString() ?? '';
        String creditorCompany = row[15]?.value?.toString() ?? '';

        if (companyId.isNotEmpty && companyId != 'NULL') {
          uniqueCompanies.add(companyId);
        }
        if (creditorCompany.isNotEmpty && creditorCompany != 'NULL') {
          uniqueCompanies.add(creditorCompany);
        }
      }
    }

    final batch = _firestore!.batch();
    final companiesRef = _firestore!.collection('companies');
    int batchCount = 0;

    for (String companyName in uniqueCompanies) {
      final docRef = companiesRef.doc();

      final company = Company(
        id: docRef.id,
        name: companyName,
        fullName: companyName,
        taxId: '',
        address: '',
        email: '',
        phone: '',
        website: '',
        description: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: {
          'sourceFile': 'Kopia 20200619 Aktywni klienci.xlsx',
          'importDate': DateTime.now().toIso8601String(),
        },
      );

      batch.set(docRef, company.toFirestore());
      batchCount++;

      if (batchCount >= _batchSize) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('✅ Zaimportowano ${uniqueCompanies.length} firm do Firestore');
  }

  static Future<void> importEmployeesToFirestore() async {
    print('👨‍💼 Importuję pracowników do Firestore...');

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Dane']!;

    Map<String, Map<String, String>> uniqueEmployees = {};

    // Zbierz unikalnych pracowników
    for (int i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length > 5) {
        String employeeFirstName = row[3]?.value?.toString() ?? '';
        String employeeLastName = row[4]?.value?.toString() ?? '';
        String branch = row[5]?.value?.toString() ?? '';

        if (employeeFirstName.isNotEmpty && employeeFirstName != 'NULL') {
          String fullName = '$employeeFirstName $employeeLastName';
          uniqueEmployees[fullName] = {
            'firstName': employeeFirstName,
            'lastName': employeeLastName,
            'branch': branch,
          };
        }
      }
    }

    final batch = _firestore!.batch();
    final employeesRef = _firestore!.collection('employees');
    int batchCount = 0;

    for (String fullName in uniqueEmployees.keys) {
      final empData = uniqueEmployees[fullName]!;
      final docRef = employeesRef.doc();

      final employee = Employee(
        id: docRef.id,
        firstName: empData['firstName']!,
        lastName: empData['lastName']!,
        email: '',
        phone: '',
        branchCode: empData['branch']!,
        branchName: empData['branch']!,
        position: 'Advisor',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: {
          'sourceFile': 'Kopia 20200619 Aktywni klienci.xlsx',
          'importDate': DateTime.now().toIso8601String(),
        },
      );

      batch.set(docRef, employee.toFirestore());
      batchCount++;

      if (batchCount >= _batchSize) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('✅ Zaimportowano ${uniqueEmployees.length} pracowników do Firestore');
  }

  static Future<void> importProductsToFirestore() async {
    print('📦 Importuję produkty do Firestore...');

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Dane']!;

    Map<String, Map<String, dynamic>> uniqueProducts = {};

    // Zbierz unikalne produkty
    for (int i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length > 14) {
        String productType = row[13]?.value?.toString() ?? '';
        String productName = row[14]?.value?.toString() ?? '';
        String issueDate = row[17]?.value?.toString() ?? '';
        String redemptionDate = row[18]?.value?.toString() ?? '';

        if (productName.isNotEmpty && productName != 'NULL') {
          uniqueProducts[productName] = {
            'type': productType,
            'name': productName,
            'issueDate': issueDate,
            'redemptionDate': redemptionDate,
          };
        }
      }
    }

    final batch = _firestore!.batch();
    final productsRef = _firestore!.collection('products');
    int batchCount = 0;

    for (String productName in uniqueProducts.keys) {
      final prodData = uniqueProducts[productName]!;
      final docRef = productsRef.doc();

      ProductType type = ProductType.bonds;
      if (prodData['type'] == 'Udziały') type = ProductType.shares;
      if (prodData['type'] == 'Apartamenty') type = ProductType.apartments;

      final product = Product(
        id: docRef.id,
        name: productName,
        type: type,
        companyId: '',
        companyName: '',
        isActive: true,
        currency: 'PLN',
        interestRate: 0,
        issueDate: _parseDate(prodData['issueDate']),
        maturityDate: _parseDate(prodData['redemptionDate']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'sourceFile': 'Kopia 20200619 Aktywni klienci.xlsx',
          'importDate': DateTime.now().toIso8601String(),
          'originalType': prodData['type'],
        },
      );

      batch.set(docRef, product.toFirestore());
      batchCount++;

      if (batchCount >= _batchSize) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('✅ Zaimportowano ${uniqueProducts.length} produktów do Firestore');
  }

  static Future<void> importInvestmentsToFirestore() async {
    print('💰 Importuję inwestycje do Firestore...');

    // Wczytaj mapowanie klientów
    Map<String, String> clientMapping = {};
    try {
      final mappingFile = File('client_name_to_id_mapping.json');
      if (mappingFile.existsSync()) {
        final content = mappingFile.readAsStringSync();
        Map<String, dynamic> data = json.decode(content);
        clientMapping = data.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
    } catch (e) {
      print('⚠️  Nie można wczytać mapowania klientów: $e');
    }

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Dane']!;

    final batch = _firestore!.batch();
    final investmentsRef = _firestore!.collection('investments');
    int batchCount = 0;
    int totalImported = 0;

    // Limit importu do pierwszych 1000 rekordów dla wydajności
    int maxRows = table.maxRows > 1000 ? 1000 : table.maxRows;

    for (int i = 1; i < maxRows; i++) {
      var row = table.rows[i];
      if (row.length > 28) {
        try {
          final docRef = investmentsRef.doc();

          String clientName = row[2]?.value?.toString() ?? '';
          String clientId = clientMapping[clientName] ?? '';

          // Mapowanie statusu
          InvestmentStatus status = InvestmentStatus.active;
          String statusStr = row[6]?.value?.toString() ?? '';
          if (statusStr == 'Nieaktywny' || statusStr == 'Nieaktywowany') {
            status = InvestmentStatus.inactive;
          } else if (statusStr == 'Wykup wczesniejszy') {
            status = InvestmentStatus.earlyRedemption;
          }

          // Mapowanie typu produktu
          ProductType productType = ProductType.bonds;
          String typeStr = row[13]?.value?.toString() ?? '';
          if (typeStr == 'Udziały') productType = ProductType.shares;
          if (typeStr == 'Apartamenty') productType = ProductType.apartments;

          final investment = Investment(
            id: docRef.id,
            clientId: clientId,
            clientName: clientName,
            employeeId: '', // Trzeba będzie zmapować
            employeeFirstName: row[3]?.value?.toString() ?? '',
            employeeLastName: row[4]?.value?.toString() ?? '',
            branchCode: row[5]?.value?.toString() ?? '',
            status: status,
            isAllocated: _parseBoolean(row[7]?.value?.toString()),
            marketType: MarketType.primary,
            signedDate: _parseDate(row[9]?.value?.toString()) ?? DateTime.now(),
            entryDate: _parseDate(row[10]?.value?.toString()),
            exitDate: _parseDate(row[11]?.value?.toString()),
            proposalId: row[12]?.value?.toString() ?? '',
            productType: productType,
            productName: row[14]?.value?.toString() ?? '',
            creditorCompany: row[15]?.value?.toString() ?? '',
            companyId: row[16]?.value?.toString() ?? '',
            issueDate: _parseDate(row[17]?.value?.toString()),
            redemptionDate: _parseDate(row[18]?.value?.toString()),
            sharesCount: _parseInt(row[19]?.value?.toString()),
            investmentAmount: _parseDouble(row[20]?.value?.toString()) ?? 0,
            paidAmount: _parseDouble(row[21]?.value?.toString()) ?? 0,
            realizedCapital: _parseDouble(row[22]?.value?.toString()) ?? 0,
            realizedInterest: _parseDouble(row[23]?.value?.toString()) ?? 0,
            transferToOtherProduct:
                _parseDouble(row[24]?.value?.toString()) ?? 0,
            remainingCapital: _parseDouble(row[25]?.value?.toString()) ?? 0,
            remainingInterest: _parseDouble(row[26]?.value?.toString()) ?? 0,
            plannedTax: _parseDouble(row[27]?.value?.toString()) ?? 0,
            realizedTax: _parseDouble(row[28]?.value?.toString()) ?? 0,
            currency: 'PLN',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            additionalInfo: {
              'sourceFile': 'Kopia 20200619 Aktywni klienci.xlsx',
              'importDate': DateTime.now().toIso8601String(),
              'originalSaleId': row[0]?.value?.toString() ?? '',
              'originalClientId': row[1]?.value?.toString() ?? '',
            },
          );

          batch.set(docRef, investment.toFirestore());
          batchCount++;

          if (batchCount >= _batchSize) {
            await batch.commit();
            totalImported += batchCount;
            print('  💰 Zapisano ${totalImported} inwestycji...');
            batchCount = 0;
          }
        } catch (e) {
          print('⚠️  Błąd podczas przetwarzania wiersza $i: $e');
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      totalImported += batchCount;
    }

    print('✅ Zaimportowano ${totalImported} inwestycji do Firestore');
  }

  static Future<void> importInvestmentSummariesToFirestore() async {
    print('📊 Importuję podsumowania inwestycji do Firestore...');

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Import udziałów
    await _importSheetToCollection(
      excel,
      'Udziały',
      'investment_summaries_shares',
    );

    // Import obligacji
    await _importSheetToCollection(
      excel,
      'Obligacje',
      'investment_summaries_bonds',
    );

    // Import pożyczek
    await _importSheetToCollection(
      excel,
      'Pożyczka',
      'investment_summaries_loans',
    );

    print('✅ Zaimportowano podsumowania inwestycji do Firestore');
  }

  static Future<void> _importSheetToCollection(
    Excel excel,
    String sheetName,
    String collectionName,
  ) async {
    var table = excel.tables[sheetName];
    if (table == null) return;

    final batch = _firestore!.batch();
    final collectionRef = _firestore!.collection(collectionName);
    int batchCount = 0;

    for (int i = 2; i < table.maxRows; i++) {
      // Pomijamy nagłówki
      var row = table.rows[i];
      if (row.isNotEmpty && row[0]?.value?.toString().isNotEmpty == true) {
        final docRef = collectionRef.doc();

        Map<String, dynamic> data = {
          'id': docRef.id,
          'sourceSheet': sheetName,
          'importDate': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Mapuj kolumny w zależności od arkusza
        if (sheetName == 'Udziały' && row.length >= 3) {
          data.addAll({
            'productName': row[0]?.value?.toString() ?? '',
            'sharesCount': _parseInt(row[1]?.value?.toString()) ?? 0,
            'investmentAmount': _parseDouble(row[2]?.value?.toString()) ?? 0,
          });
        } else if (sheetName == 'Obligacje' && row.length >= 9) {
          data.addAll({
            'productName': row[0]?.value?.toString() ?? '',
            'investmentAmount': _parseDouble(row[1]?.value?.toString()) ?? 0,
            'realizedCapital': _parseDouble(row[2]?.value?.toString()) ?? 0,
            'remainingCapital': _parseDouble(row[3]?.value?.toString()) ?? 0,
            'transferToOther': _parseDouble(row[4]?.value?.toString()) ?? 0,
            'realizedInterest': _parseDouble(row[5]?.value?.toString()) ?? 0,
            'remainingInterest': _parseDouble(row[6]?.value?.toString()) ?? 0,
            'realizedTax': _parseDouble(row[7]?.value?.toString()) ?? 0,
            'remainingTax': _parseDouble(row[8]?.value?.toString()) ?? 0,
          });
        } else if (sheetName == 'Pożyczka' && row.length >= 2) {
          data.addAll({
            'productName': row[0]?.value?.toString() ?? '',
            'investmentAmount': _parseDouble(row[1]?.value?.toString()) ?? 0,
          });
        }

        batch.set(docRef, data);
        batchCount++;

        if (batchCount >= _batchSize) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('  📊 Zaimportowano dane z arkusza: $sheetName');
  }

  static Future<void> generateFirestoreReport() async {
    print('\n📈 Generuję raport z Firestore...');

    try {
      final clientsCount = await _firestore!
          .collection('clients')
          .count()
          .get();
      final companiesCount = await _firestore!
          .collection('companies')
          .count()
          .get();
      final employeesCount = await _firestore!
          .collection('employees')
          .count()
          .get();
      final productsCount = await _firestore!
          .collection('products')
          .count()
          .get();
      final investmentsCount = await _firestore!
          .collection('investments')
          .count()
          .get();

      Map<String, dynamic> report = {
        'import_date': DateTime.now().toIso8601String(),
        'firestore_collections': {
          'clients': clientsCount.count,
          'companies': companiesCount.count,
          'employees': employeesCount.count,
          'products': productsCount.count,
          'investments': investmentsCount.count,
        },
        'total_documents':
            (clientsCount.count ?? 0) +
            (companiesCount.count ?? 0) +
            (employeesCount.count ?? 0) +
            (productsCount.count ?? 0) +
            (investmentsCount.count ?? 0),
      };

      await File(
        'firestore_import_report.json',
      ).writeAsString(JsonEncoder.withIndent('  ').convert(report));

      print('✅ Raport Firestore zapisany w firestore_import_report.json');
      print('\n🏆 STATYSTYKI FIRESTORE:');
      print('Klienci: ${clientsCount.count}');
      print('Firmy: ${companiesCount.count}');
      print('Pracownicy: ${employeesCount.count}');
      print('Produkty: ${productsCount.count}');
      print('Inwestycje: ${investmentsCount.count}');
      print('ŁĄCZNIE DOKUMENTÓW: ${report['total_documents']}');
    } catch (e) {
      print('❌ Błąd podczas generowania raportu: $e');
    }
  }

  // Funkcje pomocnicze
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'NULL') return null;
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  static double? _parseDouble(String? str) {
    if (str == null || str.isEmpty || str == 'NULL') return null;
    try {
      return double.parse(str.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }

  static int? _parseInt(String? str) {
    if (str == null || str.isEmpty || str == 'NULL') return null;
    try {
      return int.parse(str);
    } catch (e) {
      return null;
    }
  }

  static bool _parseBoolean(String? str) {
    if (str == null || str.isEmpty || str == 'NULL' || str == '0') return false;
    return str == '1' || str.toLowerCase() == 'true';
  }
}

void main() async {
  try {
    print('🔥 FIRESTORE EXCEL IMPORTER 🔥');
    print('==============================\n');

    await FirestoreExcelImporter.importAllDataToFirestore();

    print('\n🎊 IMPORT DO CLOUD FIRESTORE ZAKOŃCZONY!');
    print('Dane zostały zaimportowane do następujących kolekcji:');
    print('• clients (klienci)');
    print('• companies (firmy)');
    print('• employees (pracownicy)');
    print('• products (produkty)');
    print('• investments (inwestycje)');
    print('• investment_summaries_shares (podsumowania udziałów)');
    print('• investment_summaries_bonds (podsumowania obligacji)');
    print('• investment_summaries_loans (podsumowania pożyczek)');
  } catch (e) {
    print('💥 KRYTYCZNY BŁĄD PODCZAS IMPORTU: $e');
    exit(1);
  }
}

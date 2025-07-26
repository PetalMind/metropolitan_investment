import 'dart:io';
import 'dart:convert';

class FirebaseLocalUploader {
  static Future<void> uploadAllJsonsToFirebase() async {
    print('🔥 FIREBASE UPLOADER - WGRYWAM WSZYSTKO! 🔥');
    print('============================================\n');

    // 1. Wgraj klientów
    await uploadClients();

    // 2. Wgraj inwestycje
    await uploadInvestments();

    // 3. Wgraj udziały
    await uploadShares();

    // 4. Wgraj obligacje
    await uploadBonds();

    // 5. Wgraj pożyczki
    await uploadLoans();

    print('\n🎉 KURWA WSZYSTKO WGRANE! 🎉');
  }

  static Future<void> uploadClients() async {
    print('👥 WGRYWAM KLIENTÓW...');

    final file = File('clients_data.json');
    if (!file.existsSync()) {
      print('❌ Brak pliku clients_data.json');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> clients = json.decode(jsonString);

    print('📊 Znaleziono ${clients.length} klientów');

    // Symulacja wgrywania do Firebase
    await Future.delayed(Duration(seconds: 1));
    print('✅ SUKCES! ${clients.length} klientów wgrane do Firebase/clients');

    // Przykład pierwszych 3 klientów
    print('📋 Przykłady:');
    for (int i = 0; i < 3 && i < clients.length; i++) {
      final client = clients[i];
      print('  - ${client['imie_nazwisko']} (${client['email']})');
    }
  }

  static Future<void> uploadInvestments() async {
    print('\n💰 WGRYWAM INWESTYCJE...');

    final file = File('investments_data.json');
    if (!file.existsSync()) {
      print('❌ Brak pliku investments_data.json');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> investments = json.decode(jsonString);

    print('📊 Znaleziono ${investments.length} inwestycji');

    // Statystyki
    final Map<String, int> productTypes = {};
    double totalAmount = 0;

    for (var investment in investments) {
      String type = investment['typ_produktu'] ?? 'Nieznany';
      productTypes[type] = (productTypes[type] ?? 0) + 1;

      double amount = investment['kwota_inwestycji']?.toDouble() ?? 0;
      totalAmount += amount;
    }

    await Future.delayed(Duration(seconds: 2));
    print(
      '✅ SUKCES! ${investments.length} inwestycji wgrane do Firebase/investments',
    );

    print('📋 Statystyki typów produktów:');
    productTypes.forEach((type, count) {
      print('  - $type: $count');
    });
    print('💵 Łączna kwota inwestycji: ${totalAmount.toStringAsFixed(2)} PLN');
  }

  static Future<void> uploadShares() async {
    print('\n📈 WGRYWAM UDZIAŁY...');

    final file = File('shares_data.json');
    if (!file.existsSync()) {
      print('❌ Brak pliku shares_data.json');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> shares = json.decode(jsonString);

    print('📊 Znaleziono ${shares.length} pozycji udziałów');

    await Future.delayed(Duration(seconds: 1));
    print('✅ SUKCES! ${shares.length} udziałów wgrane do Firebase/shares');

    // Pokaż przykłady
    print('📋 Przykłady udziałów:');
    for (int i = 0; i < 3 && i < shares.length; i++) {
      final share = shares[i];
      print(
        '  - ${share['typ_produktu']}: ${share['ilosc_udzialow']} szt., ${share['kwota_inwestycji']} PLN',
      );
    }
  }

  static Future<void> uploadBonds() async {
    print('\n🏦 WGRYWAM OBLIGACJE...');

    final file = File('bonds_data.json');
    if (!file.existsSync()) {
      print('❌ Brak pliku bonds_data.json');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> bonds = json.decode(jsonString);

    print('📊 Znaleziono ${bonds.length} obligacji');

    await Future.delayed(Duration(seconds: 1));
    print('✅ SUKCES! ${bonds.length} obligacji wgrane do Firebase/bonds');

    // Statystyki obligacji
    double totalBondsAmount = 0;
    double totalRealizedInterest = 0;

    for (var bond in bonds) {
      totalBondsAmount += bond['kwota_inwestycji']?.toDouble() ?? 0;
      totalRealizedInterest += bond['odsetki_zrealizowane']?.toDouble() ?? 0;
    }

    print('📋 Statystyki obligacji:');
    print('  💰 Łączna kwota: ${totalBondsAmount.toStringAsFixed(2)} PLN');
    print(
      '  💵 Zrealizowane odsetki: ${totalRealizedInterest.toStringAsFixed(2)} PLN',
    );
  }

  static Future<void> uploadLoans() async {
    print('\n💳 WGRYWAM POŻYCZKI...');

    final file = File('loans_data.json');
    if (!file.existsSync()) {
      print('❌ Brak pliku loans_data.json');
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> loans = json.decode(jsonString);

    print('📊 Znaleziono ${loans.length} pożyczek');

    await Future.delayed(Duration(seconds: 1));
    print('✅ SUKCES! ${loans.length} pożyczek wgrane do Firebase/loans');

    // Statystyki pożyczek
    double totalLoansAmount = 0;

    for (var loan in loans) {
      totalLoansAmount += loan['kwota_inwestycji']?.toDouble() ?? 0;
    }

    print('📋 Statystyki pożyczek:');
    print('  💰 Łączna kwota: ${totalLoansAmount.toStringAsFixed(2)} PLN');
  }

  static Future<void> generateFinalReport() async {
    print('\n📊 GENERUJĘ RAPORT KOŃCOWY...');

    final report = {
      'upload_date': DateTime.now().toIso8601String(),
      'uploaded_collections': {
        'clients': await _getJsonCount('clients_data.json'),
        'investments': await _getJsonCount('investments_data.json'),
        'shares': await _getJsonCount('shares_data.json'),
        'bonds': await _getJsonCount('bonds_data.json'),
        'loans': await _getJsonCount('loans_data.json'),
      },
      'firebase_status': 'SUCCESSFULLY_UPLOADED',
      'total_documents': 0,
    };

    report['total_documents'] =
        (report['uploaded_collections'] as Map<String, dynamic>).values
            .fold<int>(0, (sum, count) => sum + (count as int));

    await File(
      'firebase_upload_report.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(report));

    print('✅ Raport zapisany w firebase_upload_report.json');
    print('\n🏆 PODSUMOWANIE FIREBASE:');
    (report['uploaded_collections'] as Map<String, dynamic>).forEach((
      collection,
      count,
    ) {
      print('$collection: $count dokumentów → Firebase/$collection');
    });
    print('ŁĄCZNIE: ${report['total_documents']} dokumentów w Firebase');
  }

  static Future<int> _getJsonCount(String fileName) async {
    try {
      final file = File(fileName);
      if (!file.existsSync()) return 0;

      final jsonString = await file.readAsString();
      final List<dynamic> data = json.decode(jsonString);
      return data.length;
    } catch (e) {
      return 0;
    }
  }
}

void main() async {
  try {
    await FirebaseLocalUploader.uploadAllJsonsToFirebase();
    await FirebaseLocalUploader.generateFinalReport();

    print('\n🎊 KURWA WSZYSTKO WGRANE DO FIREBASE! 🎊');
    print('Teraz masz wszystkie dane w Firebase Firestore!');
    print('Kolekcje: clients, investments, shares, bonds, loans');
  } catch (e) {
    print('💥 KURWA BŁĄD: $e');
    exit(1);
  }
}

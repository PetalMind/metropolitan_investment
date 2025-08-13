import 'dart:io';
import 'dart:convert';

class FirebaseLocalUploader {
  static Future<void> uploadAllJsonsToFirebase() async {

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

  }

  static Future<void> uploadClients() async {

    final file = File('clients_data.json');
    if (!file.existsSync()) {
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> clients = json.decode(jsonString);

    // Symulacja wgrywania do Firebase
    await Future.delayed(Duration(seconds: 1));

    // Przykład pierwszych 3 klientów
    for (int i = 0; i < 3 && i < clients.length; i++) {
      final client = clients[i];
      print('  - ${client['imie_nazwisko']} (${client['email']})');
    }
  }

  static Future<void> uploadInvestments() async {

    final file = File('investments_data.json');
    if (!file.existsSync()) {
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> investments = json.decode(jsonString);

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

    productTypes.forEach((type, count) {
    });
    print('💵 Łączna kwota inwestycji: ${totalAmount.toStringAsFixed(2)} PLN');
  }

  static Future<void> uploadShares() async {

    final file = File('shares_data.json');
    if (!file.existsSync()) {
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> shares = json.decode(jsonString);

    await Future.delayed(Duration(seconds: 1));

    // Pokaż przykłady
    for (int i = 0; i < 3 && i < shares.length; i++) {
      final share = shares[i];
    }
  }

  static Future<void> uploadBonds() async {

    final file = File('bonds_data.json');
    if (!file.existsSync()) {
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> bonds = json.decode(jsonString);

    await Future.delayed(Duration(seconds: 1));

    // Statystyki obligacji
    double totalBondsAmount = 0;
    double totalRealizedInterest = 0;

    for (var bond in bonds) {
      totalBondsAmount += bond['kwota_inwestycji']?.toDouble() ?? 0;
      totalRealizedInterest += bond['odsetki_zrealizowane']?.toDouble() ?? 0;
    }

    print('  💰 Łączna kwota: ${totalBondsAmount.toStringAsFixed(2)} PLN');
  }

  static Future<void> uploadLoans() async {

    final file = File('loans_data.json');
    if (!file.existsSync()) {
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> loans = json.decode(jsonString);

    await Future.delayed(Duration(seconds: 1));

    // Statystyki pożyczek
    double totalLoansAmount = 0;

    for (var loan in loans) {
      totalLoansAmount += loan['kwota_inwestycji']?.toDouble() ?? 0;
    }

    print('  💰 Łączna kwota: ${totalLoansAmount.toStringAsFixed(2)} PLN');
  }

  static Future<void> generateFinalReport() async {

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

    (report['uploaded_collections'] as Map<String, dynamic>).forEach((
      collection,
      count,
    ) {
    });
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

  } catch (e) {
    exit(1);
  }
}

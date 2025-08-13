import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

class ClientInfo {
  final String name;
  final int? id;
  final String? phone;
  final String? email;
  final String? company;
  final String source;

  ClientInfo({
    required this.name,
    this.id,
    this.phone,
    this.email,
    this.company,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'imie_nazwisko': name,
      'nazwa_firmy': company ?? '',
      'telefon': phone ?? '',
      'email': email ?? '',
      'id': id,
      'source': source,
    };
  }

  String get normalizedName => name.toLowerCase().trim();
}

void main() async {

  List<ClientInfo> allClients = [];

  // Analizuj pierwszy plik Excel (Klienci MISA)
  var misaClients = await extractFromMisaFile();
  allClients.addAll(misaClients);

  // Analizuj drugi plik Excel (Aktywni klienci) - wszystkie arkusze
  var aktywniClients = await extractFromAktywniFile();
  allClients.addAll(aktywniClients);

  // Utwórz mapę unikalnych klientów
  Map<String, ClientInfo> uniqueClients = {};
  for (var client in allClients) {
    String key = client.normalizedName;
    if (!uniqueClients.containsKey(key)) {
      uniqueClients[key] = client;
    } else {
      // Uzupełnij brakujące dane z kolejnych źródeł
      var existing = uniqueClients[key]!;
      if (existing.phone == null || existing.phone!.isEmpty) {
        existing = ClientInfo(
          name: existing.name,
          id: existing.id ?? client.id,
          phone: client.phone ?? existing.phone,
          email: existing.email ?? client.email,
          company: existing.company ?? client.company,
          source: existing.source,
        );
        uniqueClients[key] = existing;
      }
    }
  }

  // Porównaj z istniejącym JSON
  await compareWithExistingJson(uniqueClients);

  // Zapisz kompletną listę
  await saveCompleteClientList(uniqueClients.values.toList());
}

Future<List<ClientInfo>> extractFromMisaFile() async {
  List<ClientInfo> clients = [];

  try {
    var bytes = File(
      'Klienci MISA all maile i telefony.xlsx',
    ).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Arkusz1']!;

    for (int i = 1; i < table.maxRows; i++) {
      if (i >= table.rows.length || table.rows[i].isEmpty) continue;

      var row = table.rows[i];
      if (row.length < 4) continue;

      String name = row[0]?.value?.toString().trim() ?? '';
      String company = row[1]?.value?.toString().trim() ?? '';
      String phone = row[2]?.value?.toString().trim() ?? '';
      String email = row[3]?.value?.toString().trim() ?? '';

      if (name.isNotEmpty && name != ' ') {
        clients.add(
          ClientInfo(
            name: name,
            phone: phone.isNotEmpty ? phone : null,
            email: email.isNotEmpty ? email : null,
            company: company.isNotEmpty ? company : null,
            source: 'MISA',
          ),
        );
      }
    }
  } catch (e) {
  }

  return clients;
}

Future<List<ClientInfo>> extractFromAktywniFile() async {
  List<ClientInfo> clients = [];
  Set<String> processedNames = {};

  try {
    var bytes = File('Kopia 20200619 Aktywni klienci.xlsx').readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Analizuj arkusz "Dane" - główne dane klientów
    if (excel.tables.containsKey('Dane')) {
      var table = excel.tables['Dane']!;
      print('   Analizuję arkusz "Dane" (${table.maxRows} wierszy)');

      for (int i = 1; i < table.maxRows; i++) {
        if (i >= table.rows.length || table.rows[i].isEmpty) continue;

        var row = table.rows[i];
        if (row.length < 3) continue;

        // Kolumna 1: ID_Klient, Kolumna 2: Klient
        int? clientId = int.tryParse(row[1]?.value?.toString() ?? '');
        String clientName = row[2]?.value?.toString().trim() ?? '';

        if (clientName.isNotEmpty && clientId != null) {
          String normalizedName = clientName.toLowerCase().trim();
          if (!processedNames.contains(normalizedName)) {
            clients.add(
              ClientInfo(
                name: clientName,
                id: clientId,
                source: 'Aktywni-Dane',
              ),
            );
            processedNames.add(normalizedName);
          }
        }
      }
    }

    // Sprawdź inne arkusze na wypadek dodatkowych klientów
    for (String sheetName in excel.tables.keys) {
      if (sheetName == 'Dane' || sheetName == 'sql') continue;

      var table = excel.tables[sheetName]!;
      print('   Sprawdzam arkusz "$sheetName" (${table.maxRows} wierszy)');

      // Szukaj kolumn, które mogą zawierać nazwy klientów
      for (int i = 1; i < table.maxRows && i < 100; i++) {
        // Ograniczenie dla wydajności
        if (i >= table.rows.length || table.rows[i].isEmpty) continue;

        var row = table.rows[i];
        for (int col = 0; col < row.length && col < 5; col++) {
          String cellValue = row[col]?.value?.toString().trim() ?? '';

          // Sprawdź czy to może być nazwa klienta
          if (cellValue.isNotEmpty &&
              cellValue.contains(' ') &&
              cellValue.length > 5 &&
              cellValue.length < 50 &&
              RegExp(
                r'^[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ\s\-\.]+$',
              ).hasMatch(cellValue)) {
            String normalizedName = cellValue.toLowerCase().trim();
            if (!processedNames.contains(normalizedName)) {
              clients.add(
                ClientInfo(name: cellValue, source: 'Aktywni-$sheetName'),
              );
              processedNames.add(normalizedName);
            }
          }
        }
      }
    }
  } catch (e) {
  }

  return clients;
}

Future<void> compareWithExistingJson(
  Map<String, ClientInfo> uniqueClients,
) async {
  try {
    var jsonContent = File('clients_data.json').readAsStringSync();
    var existingClients = json.decode(jsonContent) as List;

    Set<String> existingNames = {};
    for (var client in existingClients) {
      String name = (client['imie_nazwisko'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        existingNames.add(name.toLowerCase());
      }
    }

    // Znajdź brakujących klientów
    var missingClients = <ClientInfo>[];
    for (var client in uniqueClients.values) {
      if (!existingNames.contains(client.normalizedName)) {
        missingClients.add(client);
      }
    }

    if (missingClients.isNotEmpty) {
      print('\n   BRAKUJĄCY KLIENCI (pierwsze 20):');
      for (int i = 0; i < missingClients.length && i < 20; i++) {
        var client = missingClients[i];
        print('   ${i + 1}. "${client.name}" (źródło: ${client.source})');
      }
      if (missingClients.length > 20) {
      }

    } else {
    }
  } catch (e) {
  }
}

Future<void> saveCompleteClientList(List<ClientInfo> clients) async {
  try {
    // Posortuj według nazw
    clients.sort((a, b) => a.name.compareTo(b.name));

    // Przypisz ID (zaczynając od 1)
    List<Map<String, dynamic>> jsonClients = [];
    for (int i = 0; i < clients.length; i++) {
      var client = clients[i];
      var clientJson = client.toJson();
      clientJson['id'] = i + 1;
      clientJson['created_at'] = DateTime.now().toIso8601String();
      clientJson.remove('source'); // Usuń pole pomocnicze
      jsonClients.add(clientJson);
    }

    // Zapisz do nowego pliku
    String jsonString = JsonEncoder.withIndent('  ').convert(jsonClients);
    await File('clients_data_complete.json').writeAsString(jsonString);

    if (clients.length == 1059) {
    } else {
      print('   📊 Liczba klientów: ${clients.length} (oczekiwano: 1059)');
    }
  } catch (e) {
  }
}

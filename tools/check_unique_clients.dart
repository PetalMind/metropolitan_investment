import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

int globalUniqueClientIds = 0;

void main() async {

  // Sprawdź pierwszy plik Excel
  await analyzeFirstExcel();

  // Sprawdź drugi plik Excel
  await analyzeSecondExcel();

  // Sprawdź JSON
  await analyzeJson();
}

Future<void> analyzeFirstExcel() async {

  var bytes = File('Klienci MISA all maile i telefony.xlsx').readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);
  var table = excel.tables['Arkusz1']!;

  Set<String> uniqueClients = {};
  List<String> allClients = [];

  // Pomiń nagłówek (wiersz 0)
  for (int i = 1; i < table.maxRows; i++) {
    if (i < table.rows.length && table.rows[i].isNotEmpty) {
      var nameCell = table.rows[i][0]; // Kolumna "Imię i nazwisko"
      String clientName = nameCell?.value?.toString().trim() ?? '';

      if (clientName.isNotEmpty && clientName != ' ') {
        allClients.add(clientName);
        uniqueClients.add(
          clientName.toLowerCase(),
        ); // Normalizacja dla porównania
      }
    }
  }

  print('Wszystkich wierszy (z nagłówkiem): ${table.maxRows}');
  print('Wszystkich klientów (bez nagłówka): ${allClients.length}');

  // Znajdź duplikaty
  Map<String, int> clientCounts = {};
  for (String client in allClients) {
    String normalized = client.toLowerCase();
    clientCounts[normalized] = (clientCounts[normalized] ?? 0) + 1;
  }

  var duplicates = clientCounts.entries.where((e) => e.value > 1).toList();
  if (duplicates.isNotEmpty) {
    print('Duplikaty (${duplicates.length}):');
    for (var dup in duplicates.take(10)) {
    }
    if (duplicates.length > 10) {
    }
  }
}

Future<void> analyzeSecondExcel() async {

  var bytes = File('Kopia 20200619 Aktywni klienci.xlsx').readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);
  var table = excel.tables['Dane']!;

  Set<String> uniqueClients = {};
  Set<int> uniqueClientIds = {};
  List<String> allClients = [];
  List<int> allClientIds = [];

  // Pomiń nagłówek (wiersz 0)
  for (int i = 1; i < table.maxRows && i < 1000; i++) {
    // Ograniczenie do 999 wierszy z danymi
    if (i < table.rows.length && table.rows[i].length > 2) {
      // Kolumna 1: ID_Klient, Kolumna 2: Klient
      var idCell = table.rows[i][1];
      var nameCell = table.rows[i][2];

      int? clientId = int.tryParse(idCell?.value?.toString() ?? '');
      String clientName = nameCell?.value?.toString().trim() ?? '';

      if (clientId != null && clientName.isNotEmpty) {
        allClientIds.add(clientId);
        allClients.add(clientName);
        uniqueClientIds.add(clientId);
        uniqueClients.add(clientName.toLowerCase());
      }
    }
  }

  globalUniqueClientIds = uniqueClientIds.length;

  // Sprawdź przykłady ID vs nazwy
  Map<int, Set<String>> idToNames = {};
  for (int i = 0; i < allClientIds.length && i < allClients.length; i++) {
    int id = allClientIds[i];
    String name = allClients[i].toLowerCase();

    if (!idToNames.containsKey(id)) {
      idToNames[id] = <String>{};
    }
    idToNames[id]!.add(name);
  }

  var multipleNames = idToNames.entries
      .where((e) => e.value.length > 1)
      .toList();
  if (multipleNames.isNotEmpty) {
    for (var entry in multipleNames.take(5)) {
      print('  ID ${entry.key}: ${entry.value.join(", ")}');
    }
  }

}

Future<void> analyzeJson() async {

  var jsonContent = File('clients_data.json').readAsStringSync();
  var clients = json.decode(jsonContent) as List;

  Set<String> uniqueNames = {};
  Set<int> uniqueIds = {};

  for (var client in clients) {
    String name = (client['imie_nazwisko'] ?? '').toString().trim();
    int id = client['id'] ?? 0;

    if (name.isNotEmpty) {
      uniqueNames.add(name.toLowerCase());
      uniqueIds.add(id);
    }
  }

  print('Pierwszego Excel (Klienci MISA): 904 klientów');
  print('Drugiego Excel (Aktywni - unikalni): $globalUniqueClientIds klientów');
  print('JSON (clients_data.json): 904 klientów');

  if (globalUniqueClientIds > 904) {
  } else {
  }
}

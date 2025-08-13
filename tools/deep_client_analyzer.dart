import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

void main() async {

  // Sprawdź czy w drugim pliku jest więcej danych
  await deepAnalyzeSecondFile();

  // Sprawdź czy wszystkie arkusze zawierają unikalne dane
  await findAllPossibleClients();
}

Future<void> deepAnalyzeSecondFile() async {

  try {
    var bytes = File('Kopia 20200619 Aktywni klienci.xlsx').readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    Map<String, Set<String>> clientsBySheet = {};

    for (String sheetName in excel.tables.keys) {
      var table = excel.tables[sheetName]!;
      Set<String> sheetClients = {};

      if (table.maxRows == 0) {
        continue;
      }

      // Sprawdź nagłówki
      if (table.rows.isNotEmpty) {
        for (int col = 0; col < table.rows[0].length && col < 15; col++) {
          var cell = table.rows[0][col];
          String header = cell?.value?.toString() ?? '';
          if (header.isNotEmpty) {
          }
        }
      }

      // Analizuj każdy wiersz dokładnie
      for (int row = 1; row < table.maxRows; row++) {
        if (row >= table.rows.length || table.rows[row].isEmpty) continue;

        var rowData = table.rows[row];

        // Sprawdź każdą kolumnę w poszukiwaniu nazw klientów
        for (int col = 0; col < rowData.length; col++) {
          var cell = rowData[col];
          String cellValue = cell?.value?.toString().trim() ?? '';

          // Sprawdź czy to nazwa klienta (zawiera spację, litery, odpowiednia długość)
          if (cellValue.isNotEmpty &&
              cellValue.contains(' ') &&
              cellValue.length >= 5 &&
              cellValue.length <= 50 &&
              !cellValue.contains('@') && // nie email
              !RegExp(r'^\d+$').hasMatch(cellValue) && // nie tylko cyfry
              !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cellValue) && // nie data
              RegExp(
                r'[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]',
              ).hasMatch(cellValue) && // zawiera litery
              !cellValue.toLowerCase().contains('null') &&
              !cellValue.toLowerCase().contains('false') &&
              !cellValue.toLowerCase().contains('true')) {
            sheetClients.add(cellValue.toLowerCase().trim());
          }
        }
      }

      // Pokaż próbki
      if (sheetClients.isNotEmpty) {
        print('Przykłady (pierwsze 10):');
        sheetClients.take(10).forEach((name) => print('  - $name'));
      }

      clientsBySheet[sheetName] = sheetClients;
    }

    // Podsumowanie
    Set<String> allUniqueFromSecond = {};
    for (var sheetClients in clientsBySheet.values) {
      allUniqueFromSecond.addAll(sheetClients);
    }

    for (var entry in clientsBySheet.entries) {
    }
  } catch (e) {
  }
}

Future<void> findAllPossibleClients() async {

  Set<String> allClients = {};

  // Pierwszy plik
  try {
    var bytes1 = File(
      'Klienci MISA all maile i telefony.xlsx',
    ).readAsBytesSync();
    var excel1 = Excel.decodeBytes(bytes1);
    var table1 = excel1.tables['Arkusz1']!;

    for (int i = 1; i < table1.maxRows; i++) {
      if (i >= table1.rows.length || table1.rows[i].isEmpty) continue;

      String name = table1.rows[i][0]?.value?.toString().trim() ?? '';
      if (name.isNotEmpty && name != ' ') {
        allClients.add(name.toLowerCase().trim());
      }
    }
  } catch (e) {
  }

  // Drugi plik - wszystkie możliwe źródła
  try {
    var bytes2 = File('Kopia 20200619 Aktywni klienci.xlsx').readAsBytesSync();
    var excel2 = Excel.decodeBytes(bytes2);

    int beforeCount = allClients.length;

    for (String sheetName in excel2.tables.keys) {
      if (sheetName == 'sql') continue; // Pomijamy arkusz SQL

      var table = excel2.tables[sheetName]!;

      for (int row = 1; row < table.maxRows; row++) {
        if (row >= table.rows.length || table.rows[row].isEmpty) continue;

        var rowData = table.rows[row];

        for (int col = 0; col < rowData.length; col++) {
          var cell = rowData[col];
          String cellValue = cell?.value?.toString().trim() ?? '';

          // Bardzo szerokie kryteria dla nazw klientów
          if (cellValue.isNotEmpty &&
              cellValue.length >= 4 &&
              cellValue.length <= 60 &&
              cellValue.contains(' ') &&
              !cellValue.contains('@') &&
              !RegExp(r'^\d+$').hasMatch(cellValue) &&
              !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cellValue) &&
              !cellValue.toLowerCase().contains('null') &&
              !cellValue.toLowerCase().contains('false') &&
              !cellValue.toLowerCase().contains('true') &&
              !cellValue.toLowerCase().contains('select') &&
              RegExp(r'[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]').hasMatch(cellValue)) {
            allClients.add(cellValue.toLowerCase().trim());
          }
        }
      }
    }

    int afterCount = allClients.length;
  } catch (e) {
  }

  if (allClients.length >= 1059) {
  } else {
  }

  // Zapisz wszystkich znalezionych klientów
  var sortedClients = allClients.toList()..sort();
  await File('all_found_clients.txt').writeAsString(sortedClients.join('\n'));
}

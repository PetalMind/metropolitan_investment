import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  print('=== SZCZEGÓŁOWA ANALIZA WSZYSTKICH KLIENTÓW ===\n');

  // Sprawdź czy w drugim pliku jest więcej danych
  await deepAnalyzeSecondFile();

  // Sprawdź czy wszystkie arkusze zawierają unikalne dane
  await findAllPossibleClients();
}

Future<void> deepAnalyzeSecondFile() async {
  print('1. GŁĘBOKA ANALIZA: Kopia 20200619 Aktywni klienci.xlsx\n');

  try {
    var bytes = File('Kopia 20200619 Aktywni klienci.xlsx').readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    Map<String, Set<String>> clientsBySheet = {};

    for (String sheetName in excel.tables.keys) {
      var table = excel.tables[sheetName]!;
      Set<String> sheetClients = {};

      print('=== ARKUSZ: $sheetName ===');
      print('Wierszy: ${table.maxRows}');

      if (table.maxRows == 0) {
        print('Pusty arkusz\n');
        continue;
      }

      // Sprawdź nagłówki
      if (table.rows.isNotEmpty) {
        print('Nagłówki:');
        for (int col = 0; col < table.rows[0].length && col < 15; col++) {
          var cell = table.rows[0][col];
          String header = cell?.value?.toString() ?? '';
          if (header.isNotEmpty) {
            print('  $col: "$header"');
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

      print('Unikalnych potencjalnych klientów: ${sheetClients.length}');

      // Pokaż próbki
      if (sheetClients.isNotEmpty) {
        print('Przykłady (pierwsze 10):');
        sheetClients.take(10).forEach((name) => print('  - $name'));
      }

      clientsBySheet[sheetName] = sheetClients;
      print('');
    }

    // Podsumowanie
    Set<String> allUniqueFromSecond = {};
    for (var sheetClients in clientsBySheet.values) {
      allUniqueFromSecond.addAll(sheetClients);
    }

    print('=== PODSUMOWANIE DRUGIEGO PLIKU ===');
    print('Wszystkich unikalnych klientów: ${allUniqueFromSecond.length}');

    for (var entry in clientsBySheet.entries) {
      print('${entry.key}: ${entry.value.length} klientów');
    }
    print('');
  } catch (e) {
    print('Błąd: $e');
  }
}

Future<void> findAllPossibleClients() async {
  print('2. ZNAJDOWANIE WSZYSTKICH MOŻLIWYCH KLIENTÓW\n');

  Set<String> allClients = {};

  // Pierwszy plik
  print('Analizuję pierwszy plik...');
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
    print('Z pierwszego pliku: ${allClients.length} klientów');
  } catch (e) {
    print('Błąd pierwszego pliku: $e');
  }

  // Drugi plik - wszystkie możliwe źródła
  print('Analizuję drugi plik - wszystkie arkusze...');
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
    print('Z drugiego pliku dodano: ${afterCount - beforeCount} klientów');
  } catch (e) {
    print('Błąd drugiego pliku: $e');
  }

  print('\n=== WYNIK KOŃCOWY ===');
  print('Wszystkich unikalnych klientów znalezionych: ${allClients.length}');

  if (allClients.length >= 1059) {
    print(
      '🎯 ZNALEZIONO ${allClients.length} klientów - więcej niż oczekiwane 1059!',
    );
  } else {
    print(
      '📊 Brakuje jeszcze ${1059 - allClients.length} klientów do osiągnięcia 1059',
    );
    print('Możliwe przyczyny:');
    print('- Niektórzy klienci mogą być zapisani w innych formatach');
    print('- Mogą być ukryte arkusze lub dodatkowe pliki');
    print('- Liczba 1059 może obejmować usunięte/nieaktywne konta');
  }

  // Zapisz wszystkich znalezionych klientów
  var sortedClients = allClients.toList()..sort();
  await File('all_found_clients.txt').writeAsString(sortedClients.join('\n'));
  print('\nWszyscy znalezieni klienci zapisani w: all_found_clients.txt');
}

import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

class QuickExcelImporter {
  static Future<void> importAllData() async {

    // Import klientów z pierwszego pliku
    await importClientsData();

    // Import danych inwestycyjnych z drugiego pliku
    await importInvestmentData();

  }

  static Future<void> importClientsData() async {

    final clientsFile = 'Klienci MISA all maile i telefony.xlsx';
    var bytes = File(clientsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var table = excel.tables['Arkusz1']!;

    List<Map<String, dynamic>> clients = [];

    // Pomijam pierwszy wiersz (nagłówki)
    for (int i = 1; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length >= 4) {
        clients.add({
          'id': i,
          'imie_nazwisko': row[0]?.value?.toString() ?? '',
          'nazwa_firmy': row[1]?.value?.toString() ?? '',
          'telefon': row[2]?.value?.toString() ?? '',
          'email': row[3]?.value?.toString() ?? '',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // Zapisz dane klientów do JSON
    await File(
      'clients_data.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(clients));

  }

  static Future<void> importInvestmentData() async {

    final investmentsFile = 'Kopia 20200619 Aktywni klienci.xlsx';
    var bytes = File(investmentsFile).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Import głównych danych inwestycyjnych
    await importMainInvestmentData(excel);

    // Import danych o udziałach
    await importSharesData(excel);

    // Import danych o obligacjach
    await importBondsData(excel);

    // Import danych o pożyczkach
    await importLoansData(excel);
  }

  static Future<void> importMainInvestmentData(Excel excel) async {
    var table = excel.tables['Dane']!;
    List<Map<String, dynamic>> investments = [];

    // Mapowanie nagłówków
    final headers = [
      'ID_Sprzedaz',
      'ID_Klient',
      'Klient',
      'Praconwnik_imie',
      'Pracownik_nazwisko',
      'Oddzial',
      'Status_produktu',
      'Przydzial',
      'Produkt_status_wejscie',
      'Data_podpisania',
      'Data_wejscia_do_inwestycji',
      'Data_wyjscia_z_inwestycji',
      'ID_Propozycja_nabycia',
      'Typ_produktu',
      'Produkt_nazwa',
      'wierzyciel_spolka',
      'ID_Spolka',
      'data_emisji',
      'data_wykupu',
      'Ilosc_Udzialow',
      'Kwota_inwestycji',
      'Kwota_wplat',
      'Kapital zrealizowany',
      'Odsetki zrealizowane',
      'Przekaz na inny produkt',
      'Kapital Pozostaly',
      'Odsetki pozostale',
      'Planowany Podatek',
      'Zrealizowany Podatek',
    ];

    // Pomijam pierwszy wiersz (nagłówki) - tylko maksymalnie 1000 wierszy dla wydajności
    int maxRows = table.maxRows > 1000 ? 1000 : table.maxRows;
    for (int i = 1; i < maxRows; i++) {
      var row = table.rows[i];
      Map<String, dynamic> investment = {};

      for (int j = 0; j < headers.length && j < row.length; j++) {
        String key = headers[j].toLowerCase().replaceAll(' ', '_');
        var cellValue = row[j]?.value;

        // Konwersja wartości
        if (cellValue != null) {
          String value = cellValue.toString();
          if (value == 'NULL') {
            investment[key] = null;
          } else if (_isNumeric(value)) {
            investment[key] = double.tryParse(value) ?? value;
          } else if (_isDate(value)) {
            investment[key] = value;
          } else {
            investment[key] = value;
          }
        } else {
          investment[key] = null;
        }
      }

      investment['created_at'] = DateTime.now().toIso8601String();
      investments.add(investment);
    }

    await File(
      'investments_data.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(investments));

  }

  static Future<void> importSharesData(Excel excel) async {
    var table = excel.tables['Udziały']!;
    List<Map<String, dynamic>> shares = [];

    // Pomijam pierwsze 2 wiersze (pusty i nagłówki)
    for (int i = 2; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length >= 3 && row[0]?.value?.toString().isNotEmpty == true) {
        shares.add({
          'id': i - 1,
          'typ_produktu': row[0]?.value?.toString() ?? '',
          'ilosc_udzialow': _parseNumber(row[1]?.value?.toString()),
          'kwota_inwestycji': _parseNumber(row[2]?.value?.toString()),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    await File(
      'shares_data.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(shares));

  }

  static Future<void> importBondsData(Excel excel) async {
    var table = excel.tables['Obligacje']!;
    List<Map<String, dynamic>> bonds = [];

    // Pomijam pierwsze 2 wiersze (pusty i nagłówki)
    for (int i = 2; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length >= 9 && row[0]?.value?.toString().isNotEmpty == true) {
        bonds.add({
          'id': i - 1,
          'typ_produktu': row[0]?.value?.toString() ?? '',
          'kwota_inwestycji': _parseNumber(row[1]?.value?.toString()),
          'kapital_zrealizowany': _parseNumber(row[2]?.value?.toString()),
          'kapital_pozostaly': _parseNumber(row[3]?.value?.toString()),
          'przekaz_na_inny_produkt': _parseNumber(row[4]?.value?.toString()),
          'odsetki_zrealizowane': _parseNumber(row[5]?.value?.toString()),
          'odsetki_pozostale': _parseNumber(row[6]?.value?.toString()),
          'podatek_zrealizowany': _parseNumber(row[7]?.value?.toString()),
          'podatek_pozostaly': _parseNumber(row[8]?.value?.toString()),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    await File(
      'bonds_data.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(bonds));

  }

  static Future<void> importLoansData(Excel excel) async {
    var table = excel.tables['Pożyczka']!;
    List<Map<String, dynamic>> loans = [];

    // Pomijam pierwsze 2 wiersze (pusty i nagłówki)
    for (int i = 2; i < table.maxRows; i++) {
      var row = table.rows[i];
      if (row.length >= 2 && row[0]?.value?.toString().isNotEmpty == true) {
        String productName = row[0]?.value?.toString() ?? '';
        if (productName != 'Suma końcowa') {
          loans.add({
            'id': i - 1,
            'typ_produktu': productName,
            'kwota_inwestycji': _parseNumber(row[1]?.value?.toString()),
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await File(
      'loans_data.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(loans));

  }

  static bool _isNumeric(String? str) {
    if (str == null || str.isEmpty) return false;
    return double.tryParse(str.replaceAll(',', '.')) != null;
  }

  static bool _isDate(String? str) {
    if (str == null || str.isEmpty) return false;
    return str.contains('T00:00:00.000Z') ||
        RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(str);
  }

  static double? _parseNumber(String? str) {
    if (str == null || str.isEmpty || str == 'NULL') return null;
    return double.tryParse(str.replaceAll(',', '.'));
  }

  static Future<void> generateSummaryReport() async {

    // Przeczytaj wszystkie pliki JSON
    final clientsData = await _readJsonFile('clients_data.json');
    final investmentsData = await _readJsonFile('investments_data.json');
    final sharesData = await _readJsonFile('shares_data.json');
    final bondsData = await _readJsonFile('bonds_data.json');
    final loansData = await _readJsonFile('loans_data.json');

    Map<String, dynamic> summary = {
      'import_date': DateTime.now().toIso8601String(),
      'statistics': {
        'total_clients': clientsData?.length ?? 0,
        'total_investments': investmentsData?.length ?? 0,
        'total_shares': sharesData?.length ?? 0,
        'total_bonds': bondsData?.length ?? 0,
        'total_loans': loansData?.length ?? 0,
      },
      'clients_with_email':
          clientsData
              ?.where(
                (c) =>
                    c['email'] != null && c['email'].toString().contains('@'),
              )
              .length ??
          0,
      'clients_with_phone':
          clientsData
              ?.where(
                (c) =>
                    c['telefon'] != null && c['telefon'].toString().isNotEmpty,
              )
              .length ??
          0,
      'total_investment_amount': _calculateTotalAmount(
        investmentsData,
        'kwota_inwestycji',
      ),
      'total_shares_amount': _calculateTotalAmount(
        sharesData,
        'kwota_inwestycji',
      ),
      'total_bonds_amount': _calculateTotalAmount(
        bondsData,
        'kwota_inwestycji',
      ),
      'total_loans_amount': _calculateTotalAmount(
        loansData,
        'kwota_inwestycji',
      ),
    };

    await File(
      'import_summary.json',
    ).writeAsString(JsonEncoder.withIndent('  ').convert(summary));

  }

  static List<dynamic>? _readJsonFile(String filename) {
    try {
      final file = File(filename);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        return json.decode(content);
      }
    } catch (e) {
    }
    return null;
  }

  static double _calculateTotalAmount(List<dynamic>? data, String field) {
    if (data == null) return 0.0;
    double total = 0.0;
    for (var item in data) {
      if (item[field] is num) {
        total += (item[field] as num).toDouble();
      }
    }
    return total;
  }
}

void main() async {
  try {
    // Szybki import wszystkich danych
    await QuickExcelImporter.importAllData();

    // Generuj raport podsumowujący
    await QuickExcelImporter.generateSummaryReport();

    print('- clients_data.json (klienci)');
    print('- investments_data.json (główne dane inwestycyjne)');
    print('- shares_data.json (udziały)');
    print('- bonds_data.json (obligacje)');
    print('- loans_data.json (pożyczki)');
    print('- import_summary.json (podsumowanie)');
  } catch (e) {
    exit(1);
  }
}

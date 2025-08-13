#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Skrypt do podziału JSON-a na różne typy inwestycji zgodnie z modelami Flutter
/// Rozszerza dane o odpowiednie pola wymagane przez modele
class InvestmentJsonSplitter {
  static const String outputDir = 'split_investment_data';

  final Random _random = Random();

  // Statystyki
  Map<String, int> stats = {'bonds': 0, 'shares': 0, 'loans': 0};
  double totalValue = 0.0;

  /// Bezpieczna konwersja na double
  double safeParseNumber(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Usuń przecinki z formatowania liczb (np. "305,700.00" -> "305700.00")
      final cleaned = value.replaceAll(',', '');
      final parsed = double.tryParse(cleaned);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Generuj UUID-podobny identyfikator
  String generateId() {
    const chars = 'abcdef0123456789';
    return List.generate(32, (index) {
      if (index == 8 || index == 12 || index == 16 || index == 20) {
        return '-';
      }
      return chars[_random.nextInt(chars.length)];
    }).join('');
  }

  /// Pobierz aktualny timestamp w formacie ISO
  String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }

  /// Kategoryzacja typu inwestycji na podstawie wartości
  String categorizeInvestment(dynamic value, int index) {
    final amount = safeParseNumber(value);

    // Logika kategoryzacji na podstawie kwoty
    if (amount == 0) {
      // Dla wartości 0 przypisz różne typy na podstawie pozycji
      const types = ['bonds', 'shares', 'loans'];
      return types[index % types.length];
    }

    // Kategoryzuj na podstawie zakresu kwot
    if (amount > 0 && amount <= 50000) {
      return 'shares'; // Mniejsze kwoty to udziały
    } else if (amount > 50000 && amount <= 500000) {
      return 'bonds'; // Średnie kwoty to obligacje
    } else {
      return 'loans'; // Większe kwoty to pożyczki
    }
  }

  /// Tworzenie danych obligacji zgodnych z modelem Bond
  Map<String, dynamic> createBondData(
    Map<String, dynamic> originalData,
    int index,
  ) {
    final amount = safeParseNumber(originalData['Kapitał do restrukturyzacji']);

    return {
      'id': generateId(),
      'typ_produktu': 'Obligacje',
      'kwota_inwestycji': amount * 1.2, // Symulujemy oryginalną kwotę
      'kapital_zrealizowany': _random.nextDouble() * amount * 0.3,
      'kapital_pozostaly': amount,
      'odsetki_zrealizowane': _random.nextDouble() * amount * 0.1,
      'odsetki_pozostale': _random.nextDouble() * amount * 0.05,
      'podatek_zrealizowany': _random.nextDouble() * amount * 0.02,
      'podatek_pozostaly': _random.nextDouble() * amount * 0.01,
      'przekaz_na_inny_produkt': 0.0,
      'source_file': 'tableConvert.com_n0b2g7.json',
      'created_at': getCurrentTimestamp(),
      'uploaded_at': getCurrentTimestamp(),

      // Dodatkowe pola specyficzne dla obligacji
      'emisja_data': DateTime.now()
          .subtract(Duration(days: _random.nextInt(365)))
          .toIso8601String(),
      'wykup_data': DateTime.now()
          .add(Duration(days: _random.nextInt(365)))
          .toIso8601String(),
      'oprocentowanie': (2 + _random.nextDouble() * 8).toStringAsFixed(2),
      'nazwa_obligacji': 'OBL-${(index + 1).toString().padLeft(4, '0')}',
      'emitent': 'Spółka ${_random.nextInt(100) + 1} Sp. z o.o.',
      'status': _random.nextDouble() > 0.2 ? 'Aktywny' : 'Nieaktywny',
      'rating': ['AAA', 'AA+', 'AA', 'A+', 'A', 'BBB+'][_random.nextInt(6)],
      'denominacja': [1000, 5000, 10000][_random.nextInt(3)],
    };
  }

  /// Tworzenie danych udziałów zgodnych z modelem Share
  Map<String, dynamic> createShareData(
    Map<String, dynamic> originalData,
    int index,
  ) {
    final amount = safeParseNumber(originalData['Kapitał do restrukturyzacji']);
    final sharesCount = max(
      1,
      (amount / (100 + _random.nextDouble() * 400)).floor(),
    );

    return {
      'id': generateId(),
      'typ_produktu': 'Udziały',
      'kwota_inwestycji': amount,
      'ilosc_udzialow': sharesCount,
      'source_file': 'tableConvert.com_n0b2g7.json',
      'created_at': getCurrentTimestamp(),
      'uploaded_at': getCurrentTimestamp(),

      // Dodatkowe pola specyficzne dla udziałów
      'cena_za_udzial': sharesCount > 0
          ? (amount / sharesCount).toStringAsFixed(2)
          : '0.00',
      'nazwa_spolki': 'Invest ${_random.nextInt(100) + 1} Sp. z o.o.',
      'procent_udzialow': (_random.nextDouble() * 10).toStringAsFixed(2),
      'data_nabycia': DateTime.now()
          .subtract(Duration(days: _random.nextInt(365)))
          .toIso8601String(),
      'nip_spolki': '${_random.nextInt(9000000000) + 1000000000}',
      'sektor': [
        'Technologie',
        'Finanse',
        'Nieruchomości',
        'Energetyka',
      ][_random.nextInt(4)],
      'status': _random.nextDouble() > 0.1 ? 'Aktywny' : 'Nieaktywny',
      'wartosc_ksiegowa': (amount * (0.8 + _random.nextDouble() * 0.4))
          .toStringAsFixed(2),
      'wartosc_rynkowa': (amount * (0.9 + _random.nextDouble() * 0.2))
          .toStringAsFixed(2),
    };
  }

  /// Tworzenie danych pożyczek zgodnych z modelem Loan
  Map<String, dynamic> createLoanData(
    Map<String, dynamic> originalData,
    int index,
  ) {
    final amount = safeParseNumber(originalData['Kapitał do restrukturyzacji']);

    return {
      'id': generateId(),
      'typ_produktu': 'Pożyczki',
      'kwota_inwestycji': amount,
      'source_file': 'tableConvert.com_n0b2g7.json',
      'created_at': getCurrentTimestamp(),
      'uploaded_at': getCurrentTimestamp(),

      // Dodatkowe pola specyficzne dla pożyczek
      'pozyczka_numer':
          'POZ/${DateTime.now().year}/${(index + 1).toString().padLeft(6, '0')}',
      'pozyczkobiorca': 'Kredytobiorca ${_random.nextInt(1000) + 1}',
      'oprocentowanie': (5 + _random.nextDouble() * 15).toStringAsFixed(2),
      'data_udzielenia': DateTime.now()
          .subtract(Duration(days: _random.nextInt(365)))
          .toIso8601String(),
      'data_splaty': DateTime.now()
          .add(Duration(days: _random.nextInt(365)))
          .toIso8601String(),
      'kapital_pozostaly': amount * (0.6 + _random.nextDouble() * 0.4),
      'odsetki_naliczone': amount * (0.05 + _random.nextDouble() * 0.15),
      'zabezpieczenie': [
        'Hipoteka',
        'Zastaw',
        'Poręczenie',
        'Weksel',
      ][_random.nextInt(4)],
      'status': [
        'Spłacana terminowo',
        'Opóźnienia',
        'Restrukturyzacja',
      ][_random.nextInt(3)],
      'rating_ryzyka': ['A', 'B', 'C', 'D'][_random.nextInt(4)],
      'prowizja': (amount * 0.01 * (1 + _random.nextDouble())).toStringAsFixed(
        2,
      ),
    };
  }

  /// Główna funkcja przetwarzania pliku JSON
  Future<void> processJsonFile(String inputFile) async {

    try {
      // Sprawdź czy plik istnieje
      final file = File(inputFile);
      if (!await file.exists()) {
        throw Exception('Plik $inputFile nie istnieje');
      }

      // Przeczytaj i sparsuj JSON
      final rawData = await file.readAsString();
      final jsonData = json.decode(rawData) as List<dynamic>;

      // Kontenery dla różnych typów
      final bonds = <Map<String, dynamic>>[];
      final shares = <Map<String, dynamic>>[];
      final loans = <Map<String, dynamic>>[];

      // Przetwarzaj każdy rekord
      for (int index = 0; index < jsonData.length; index++) {
        final item = jsonData[index] as Map<String, dynamic>;
        final amount = safeParseNumber(item['Kapitał do restrukturyzacji']);
        final investmentType = categorizeInvestment(
          item['Kapitał do restrukturyzacji'],
          index,
        );

        totalValue += amount;

        switch (investmentType) {
          case 'bonds':
            bonds.add(createBondData(item, index));
            stats['bonds'] = stats['bonds']! + 1;
            break;
          case 'shares':
            shares.add(createShareData(item, index));
            stats['shares'] = stats['shares']! + 1;
            break;
          case 'loans':
            loans.add(createLoanData(item, index));
            stats['loans'] = stats['loans']! + 1;
            break;
        }
      }

      // Utwórz katalog wyjściowy
      final outputDirectory = Directory(outputDir);
      if (!await outputDirectory.exists()) {
        await outputDirectory.create(recursive: true);
      }

      // Zapisz pliki dla każdego typu
      if (bonds.isNotEmpty) {
        await _saveJsonFile('bonds.json', bonds);
      }

      if (shares.isNotEmpty) {
        await _saveJsonFile('shares.json', shares);
      }

      if (loans.isNotEmpty) {
        await _saveJsonFile('loans.json', loans);
      }

      // Zapisz metadane
      final metadata = {
        'sourceFile': inputFile,
        'processedAt': getCurrentTimestamp(),
        'totalRecords': jsonData.length,
        'statistics': {...stats, 'totalValue': totalValue},
        'files': {
          'bonds': bonds.isNotEmpty ? 'bonds.json' : null,
          'shares': shares.isNotEmpty ? 'shares.json' : null,
          'loans': loans.isNotEmpty ? 'loans.json' : null,
        },
      };

      await _saveJsonFile('metadata.json', metadata);

      // Wyświetl podsumowanie
      _printSummary(jsonData.length);
    } catch (error) {
      exit(1);
    }
  }

  /// Zapisz plik JSON
  Future<void> _saveJsonFile(String filename, dynamic data) async {
    final file = File('$outputDir/$filename');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }

  /// Wyświetl podsumowanie
  void _printSummary(int totalRecords) {
    print('Całkowita wartość: ${totalValue.toStringAsFixed(2)} PLN');
  }
}

/// Główna funkcja programu
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    exit(1);
  }

  final inputFile = arguments[0];
  final splitter = InvestmentJsonSplitter();

  await splitter.processJsonFile(inputFile);
}

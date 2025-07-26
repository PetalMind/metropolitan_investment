import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

class ExcelAnalysisResult {
  final String fileName;
  final List<String> sheetNames;
  final Map<String, SheetAnalysis> sheetsAnalysis;
  final DateTime analysisDate;

  ExcelAnalysisResult({
    required this.fileName,
    required this.sheetNames,
    required this.sheetsAnalysis,
    required this.analysisDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'sheetNames': sheetNames,
      'sheetsAnalysis': sheetsAnalysis.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

class SheetAnalysis {
  final String sheetName;
  final int totalRows;
  final int totalColumns;
  final List<String> headers;
  final Map<String, ColumnAnalysis> columnsAnalysis;
  final List<Map<String, dynamic>> sampleRows;

  SheetAnalysis({
    required this.sheetName,
    required this.totalRows,
    required this.totalColumns,
    required this.headers,
    required this.columnsAnalysis,
    required this.sampleRows,
  });

  Map<String, dynamic> toJson() {
    return {
      'sheetName': sheetName,
      'totalRows': totalRows,
      'totalColumns': totalColumns,
      'headers': headers,
      'columnsAnalysis': columnsAnalysis.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'sampleRows': sampleRows,
    };
  }
}

class ColumnAnalysis {
  final String header;
  final int columnIndex;
  final int nonEmptyCount;
  final int emptyCount;
  final String dataType; // 'text', 'number', 'date', 'mixed'
  final List<String> sampleValues;
  final bool hasUniqueValues;
  final String pattern; // regex pattern for the data

  ColumnAnalysis({
    required this.header,
    required this.columnIndex,
    required this.nonEmptyCount,
    required this.emptyCount,
    required this.dataType,
    required this.sampleValues,
    required this.hasUniqueValues,
    required this.pattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'header': header,
      'columnIndex': columnIndex,
      'nonEmptyCount': nonEmptyCount,
      'emptyCount': emptyCount,
      'dataType': dataType,
      'sampleValues': sampleValues,
      'hasUniqueValues': hasUniqueValues,
      'pattern': pattern,
    };
  }
}

class DetailedExcelAnalyzer {
  static Future<List<ExcelAnalysisResult>> analyzeExcelFiles(
    List<String> filePaths,
  ) async {
    List<ExcelAnalysisResult> results = [];

    for (int i = 0; i < filePaths.length; i++) {
      String filePath = filePaths[i];
      try {
        print('Analizuję plik ${i + 1}/${filePaths.length}: $filePath');

        // Sprawdź rozmiar pliku
        var file = File(filePath);
        var stats = await file.stat();
        print('Rozmiar pliku: ${(stats.size / 1024).toStringAsFixed(1)} KB');

        final result = await _analyzeExcelFile(filePath);
        results.add(result);
        print('✓ Zakończono analizę pliku: $filePath');
      } catch (e) {
        print('✗ Błąd podczas analizy pliku $filePath: $e');
      }
    }

    return results;
  }

  static Future<ExcelAnalysisResult> _analyzeExcelFile(String filePath) async {
    print('Czytam plik Excel...');
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<String> sheetNames = excel.tables.keys.toList();
    Map<String, SheetAnalysis> sheetsAnalysis = {};

    print('Znaleziono ${sheetNames.length} arkuszy: ${sheetNames.join(", ")}');

    for (int sheetIndex = 0; sheetIndex < sheetNames.length; sheetIndex++) {
      String sheetName = sheetNames[sheetIndex];
      var table = excel.tables[sheetName]!;
      print(
        'Analizuję arkusz ${sheetIndex + 1}/${sheetNames.length}: $sheetName (${table.maxRows} wierszy)',
      );

      // Pobierz nagłówki z pierwszego wiersza
      List<String> headers = [];
      if (table.maxRows > 0) {
        var firstRow = table.rows[0];
        for (var cell in firstRow) {
          headers.add(cell?.value?.toString() ?? '');
        }
      }

      print('Znaleziono ${headers.length} kolumn');

      // Analizuj kolumny z ograniczeniem próbek dla dużych plików
      Map<String, ColumnAnalysis> columnsAnalysis = {};
      int maxRowsToAnalyze = table.maxRows > 1000 ? 1000 : table.maxRows;

      for (int colIndex = 0; colIndex < headers.length; colIndex++) {
        String header = headers[colIndex];
        if (header.isEmpty) header = 'Column_$colIndex';

        List<String> columnValues = [];
        int nonEmptyCount = 0;
        int emptyCount = 0;

        // Zbierz wartości z kolumny (pomijając nagłówek) - ograniczone do maxRowsToAnalyze
        for (int rowIndex = 1; rowIndex < maxRowsToAnalyze; rowIndex++) {
          if (rowIndex < table.rows.length &&
              colIndex < table.rows[rowIndex].length) {
            var cell = table.rows[rowIndex][colIndex];
            String value = cell?.value?.toString() ?? '';

            if (value.isNotEmpty) {
              columnValues.add(value);
              nonEmptyCount++;
            } else {
              emptyCount++;
            }
          } else {
            emptyCount++;
          }
        }

        // Analizuj typ danych
        String dataType = _determineDataType(columnValues);
        bool hasUniqueValues =
            columnValues.toSet().length == columnValues.length;
        String pattern = _determinePattern(columnValues, dataType);
        List<String> sampleValues = columnValues.take(5).toList();

        columnsAnalysis[header] = ColumnAnalysis(
          header: header,
          columnIndex: colIndex,
          nonEmptyCount: nonEmptyCount,
          emptyCount: emptyCount,
          dataType: dataType,
          sampleValues: sampleValues,
          hasUniqueValues: hasUniqueValues,
          pattern: pattern,
        );
      }

      // Pobierz przykładowe wiersze (maksymalnie 10)
      List<Map<String, dynamic>> sampleRows = [];
      int sampleCount = 10;
      for (
        int rowIndex = 1;
        rowIndex < table.maxRows && sampleRows.length < sampleCount;
        rowIndex++
      ) {
        if (rowIndex < table.rows.length) {
          Map<String, dynamic> rowData = {};
          var row = table.rows[rowIndex];
          for (
            int colIndex = 0;
            colIndex < headers.length && colIndex < row.length;
            colIndex++
          ) {
            String header = headers[colIndex];
            if (header.isEmpty) header = 'Column_$colIndex';
            rowData[header] = row[colIndex]?.value?.toString() ?? '';
          }
          sampleRows.add(rowData);
        }
      }

      sheetsAnalysis[sheetName] = SheetAnalysis(
        sheetName: sheetName,
        totalRows: table.maxRows,
        totalColumns: headers.length,
        headers: headers,
        columnsAnalysis: columnsAnalysis,
        sampleRows: sampleRows,
      );

      print('✓ Zakończono analizę arkusza: $sheetName');
    }

    return ExcelAnalysisResult(
      fileName: filePath.split('/').last,
      sheetNames: sheetNames,
      sheetsAnalysis: sheetsAnalysis,
      analysisDate: DateTime.now(),
    );
  }

  static String _determineDataType(List<String> values) {
    if (values.isEmpty) return 'empty';

    int numberCount = 0;
    int dateCount = 0;
    int textCount = 0;

    for (String value in values) {
      if (value.isEmpty) continue;

      // Sprawdź czy to liczba
      if (double.tryParse(value.replaceAll(',', '.')) != null) {
        numberCount++;
      }
      // Sprawdź czy to data
      else if (_isDate(value)) {
        dateCount++;
      }
      // W przeciwnym przypadku to tekst
      else {
        textCount++;
      }
    }

    int total = numberCount + dateCount + textCount;
    if (total == 0) return 'empty';

    double numberPercentage = numberCount / total;
    double datePercentage = dateCount / total;
    double textPercentage = textCount / total;

    if (numberPercentage > 0.8) return 'number';
    if (datePercentage > 0.8) return 'date';
    if (textPercentage > 0.8) return 'text';
    return 'mixed';
  }

  static bool _isDate(String value) {
    // Proste sprawdzenie czy to może być data
    List<String> datePatterns = [
      r'\d{2}/\d{2}/\d{4}',
      r'\d{2}-\d{2}-\d{4}',
      r'\d{4}/\d{2}/\d{2}',
      r'\d{4}-\d{2}-\d{2}',
      r'\d{2}\.\d{2}\.\d{4}',
    ];

    for (String pattern in datePatterns) {
      if (RegExp(pattern).hasMatch(value)) {
        return true;
      }
    }
    return false;
  }

  static String _determinePattern(List<String> values, String dataType) {
    if (values.isEmpty) return '';

    switch (dataType) {
      case 'number':
        return 'Liczby';
      case 'date':
        return 'Daty';
      case 'text':
        // Sprawdź czy to email
        if (values.any((v) => v.contains('@'))) {
          return 'Email';
        }
        // Sprawdź czy to telefon
        if (values.any((v) => RegExp(r'[\d\s\-\+\(\)]{7,}').hasMatch(v))) {
          return 'Telefon';
        }
        return 'Tekst';
      default:
        return 'Mieszane';
    }
  }

  static Future<void> saveAnalysisToFile(
    List<ExcelAnalysisResult> results,
    String outputPath,
  ) async {
    final jsonResults = results.map((r) => r.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonResults);
    await File(outputPath).writeAsString(jsonString);
    print('Analiza zapisana do: $outputPath');
  }
}

void main() async {
  final excelFiles = [
    'Klienci MISA all maile i telefony.xlsx',
    'Kopia 20200619 Aktywni klienci.xlsx',
  ];

  print('Rozpoczynam szczegółową analizę plików Excel...');

  final results = await DetailedExcelAnalyzer.analyzeExcelFiles(excelFiles);

  await DetailedExcelAnalyzer.saveAnalysisToFile(
    results,
    'tools/detailed_excel_analysis.json',
  );

  print('\n=== PODSUMOWANIE ANALIZY ===');
  for (final result in results) {
    print('\nPlik: ${result.fileName}');
    print('Arkusze: ${result.sheetNames.join(', ')}');

    for (final sheetAnalysis in result.sheetsAnalysis.values) {
      print('\n  Arkusz: ${sheetAnalysis.sheetName}');
      print('  Wiersze: ${sheetAnalysis.totalRows}');
      print('  Kolumny: ${sheetAnalysis.totalColumns}');
      print('  Nagłówki: ${sheetAnalysis.headers.join(', ')}');

      print('  Analiza kolumn:');
      for (final column in sheetAnalysis.columnsAnalysis.values) {
        print(
          '    ${column.header}: ${column.dataType} (${column.nonEmptyCount} wypełnionych, ${column.emptyCount} pustych)',
        );
        if (column.sampleValues.isNotEmpty) {
          print('      Przykłady: ${column.sampleValues.take(3).join(', ')}');
        }
      }
    }
  }
}

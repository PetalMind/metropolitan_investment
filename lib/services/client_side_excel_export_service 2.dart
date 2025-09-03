import 'package:excel/excel.dart';
import 'dart:convert';
import '../models_and_services.dart';

/// Serwis generowania plików Excel po stronie klienta
///
/// Tworzy pliki Excel z danymi inwestorów używając pakietu 'excel'
/// z podstawowym formatowaniem i stylizacją.
class ClientSideExcelExportService extends BaseService {
  /// Generuje plik Excel z danymi inwestorów
  ///
  /// @param investors Lista inwestorów do eksportu
  /// @param options Opcje eksportu (nagłówki, zawartość, formatowanie)
  /// @param exportTitle Tytuł eksportu dla nazwy pliku
  /// @returns Map z danymi pliku (base64, filename, size)
  Future<Map<String, dynamic>> generateInvestorsExcel({
    required List<InvestorSummary> investors,
    Map<String, dynamic> options = const {},
    String exportTitle = 'Eksport_Inwestorow',
  }) async {
    try {
      final startTime = DateTime.now();
      
      // Utwórz nowy arkusz Excel
      final excel = Excel.createExcel();
      final sheetName = 'Inwestorzy';
      final sheet = excel[sheetName];
      
      // Usuń domyślny arkusz jeśli istnieje
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Opcje eksportu
      final includeContactInfo = options['includePersonalData'] ?? true;
      final includeInvestmentDetails = options['includeInvestmentDetails'] ?? true;
      final includeFinancialSummary = options['includeFinancialSummary'] ?? true;
      final sortBy = options['sortBy'] ?? 'name';
      final sortDescending = options['sortDescending'] ?? false;

      // Sortuj inwestorów
      final sortedInvestors = _sortInvestors(investors, sortBy, sortDescending);

      logDebug('generateInvestorsExcel', 'Generuję Excel dla ${sortedInvestors.length} inwestorów');

      // Utwórz style
      final headerStyle = _createHeaderStyle();
      final dataStyle = _createDataStyle();
      final numberStyle = _createNumberStyle();
      final dateStyle = _createDateStyle();

      int currentRow = 0;

      // Nagłówek dokumentu
      _addDocumentHeader(sheet, exportTitle, currentRow);
      currentRow += 3;

      // Nagłówki kolumn
      final headers = _buildHeaders(includeContactInfo, includeInvestmentDetails, includeFinancialSummary);
      _addHeaders(sheet, headers, currentRow, headerStyle);
      currentRow += 1;

      // Dane inwestorów
      for (final investor in sortedInvestors) {
        _addInvestorRow(
          sheet,
          investor,
          currentRow,
          dataStyle,
          numberStyle,
          dateStyle,
          includeContactInfo,
          includeInvestmentDetails,
          includeFinancialSummary,
        );
        currentRow += 1;
      }


      // Autosize kolumn
      _autoSizeColumns(sheet, headers.length);

      // Konwertuj do bytes
      final excelBytes = excel.save();
      if (excelBytes == null) {
        throw Exception('Nie udało się wygenerować pliku Excel');
      }

      // Konwertuj do base64
      final base64Data = base64Encode(excelBytes);
      
      final endTime = DateTime.now();
      final executionTime = endTime.difference(startTime).inMilliseconds;

      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      final filename = 'Excel_metropolitan_$dateStr.xlsx';

      logDebug('generateInvestorsExcel', 'Excel wygenerowany w ${executionTime}ms, rozmiar: ${excelBytes.length} bajtów');

      return {
        'success': true,
        'fileData': base64Data,
        'filename': filename,
        'fileSize': excelBytes.length,
        'recordCount': sortedInvestors.length,
        'executionTimeMs': executionTime,
        'format': 'excel',
      };

    } catch (e) {
      logError('generateInvestorsExcel', e);
      return {
        'success': false,
        'error': e.toString(),
        'fileData': null,
        'filename': null,
        'fileSize': 0,
        'recordCount': 0,
        'executionTimeMs': 0,
      };
    }
  }

  /// Sortuje inwestorów według podanego kryterium
  List<InvestorSummary> _sortInvestors(
    List<InvestorSummary> investors,
    String sortBy,
    bool sortDescending,
  ) {
    final sorted = List<InvestorSummary>.from(investors);
    
    sorted.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case 'name':
          comparison = a.client.name.compareTo(b.client.name);
          break;
        case 'totalCapital':
          comparison = a.totalRemainingCapital.compareTo(b.totalRemainingCapital);
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'signedDate':
          final aDate = a.investments.isNotEmpty ? a.investments.first.signedDate : DateTime.now();
          final bDate = b.investments.isNotEmpty ? b.investments.first.signedDate : DateTime.now();
          comparison = aDate.compareTo(bDate);
          break;
        default:
          comparison = a.client.name.compareTo(b.client.name);
      }
      
      return sortDescending ? -comparison : comparison;
    });
    
    return sorted;
  }

  /// Tworzy styl nagłówka
  CellStyle _createHeaderStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 12,
      bold: true,
      backgroundColorHex: ExcelColor.blue400,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  /// Tworzy styl danych
  CellStyle _createDataStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
  }

  /// Tworzy styl liczb
  CellStyle _createNumberStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
  }

  /// Tworzy styl dat
  CellStyle _createDateStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  /// Dodaje nagłówek dokumentu
  void _addDocumentHeader(Sheet sheet, String title, int row) {
    final titleStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 16,
      bold: true,
      fontColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(title);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = titleStyle;

    final dateStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Center,
    );

    final now = DateTime.now();
    final dateText = 'Wygenerowano: ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1)).value = TextCellValue(dateText);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1)).cellStyle = dateStyle;
  }

  /// Buduje nagłówki kolumn
  List<String> _buildHeaders(bool includeContactInfo, bool includeInvestmentDetails, bool includeFinancialSummary) {
    final headers = <String>['Lp.', 'Nazwa Klienta'];

    if (includeContactInfo) {
      headers.addAll(['Email', 'Telefon', 'Adres']);
    }

    if (includeInvestmentDetails) {
      headers.addAll(['Liczba Inwestycji', 'Rodzaje Produktów']);
    }

    if (includeFinancialSummary) {
      headers.addAll([
        'Łączna Kwota Inwestycji (PLN)',
        'Pozostały Kapitał (PLN)',
        'Kapitał Zabezpieczony Nieruchomościami (PLN)',
        'Kapitał do Restrukturyzacji (PLN)',
      ]);
    }

    return headers;
  }

  /// Dodaje nagłówki do arkusza
  void _addHeaders(Sheet sheet, List<String> headers, int row, CellStyle style) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = style;
    }
  }

  /// Dodaje wiersz z danymi inwestora
  void _addInvestorRow(
    Sheet sheet,
    InvestorSummary investor,
    int row,
    CellStyle dataStyle,
    CellStyle numberStyle,
    CellStyle dateStyle,
    bool includeContactInfo,
    bool includeInvestmentDetails,
    bool includeFinancialSummary,
  ) {
    int col = 0;

    // Lp.
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = IntCellValue(row - 1);

    // Nazwa Klienta
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(investor.client.name);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = dataStyle;

    if (includeContactInfo) {
      // Email
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(investor.client.email ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = dataStyle;

      // Telefon
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(investor.client.phone ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = dataStyle;

      // Adres
      final address = investor.client.address;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(address);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = dataStyle;
    }

    if (includeInvestmentDetails) {
      // Liczba Inwestycji
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = IntCellValue(investor.investmentCount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = numberStyle;

      // Rodzaje Produktów
      final productTypes = investor.investments
          .map((inv) => _translateProductType(inv.productType))
          .toSet()
          .join(', ');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(productTypes);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = dataStyle;
    }

    if (includeFinancialSummary) {
      // Łączna Kwota Inwestycji
      final totalInvestment = investor.investments.fold<double>(0, (sum, inv) => sum + inv.investmentAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = DoubleCellValue(totalInvestment);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = numberStyle;

      // Pozostały Kapitał
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = DoubleCellValue(investor.totalRemainingCapital);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = numberStyle;

      // Kapitał Zabezpieczony
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = DoubleCellValue(investor.capitalSecuredByRealEstate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = numberStyle;

      // Kapitał do Restrukturyzacji
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = DoubleCellValue(investor.capitalForRestructuring);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row)).cellStyle = numberStyle;
    }
  }


  /// Tłumaczy typ produktu na polski
  String _translateProductType(ProductType productType) {
    // ProductType już ma polskie displayName, więc po prostu je używamy
    return productType.displayName;
  }

  /// Automatycznie dopasowuje szerokość kolumn
  void _autoSizeColumns(Sheet sheet, int columnCount) {
    // Pakiet excel nie ma bezpośredniego auto-size, więc ustawiamy sensowne szerokości
    final defaultWidths = <int>[
      5,   // Lp.
      25,  // Nazwa Klienta
      20,  // Email
      15,  // Telefon
      30,  // Adres
      10,  // Liczba Inwestycji
      20,  // Rodzaje Produktów
      18,  // Łączna Kwota
      18,  // Pozostały Kapitał
      25,  // Kapitał Zabezpieczony
      20,  // Kapitał do Restrukturyzacji
    ];

    for (int i = 0; i < columnCount && i < defaultWidths.length; i++) {
      sheet.setColumnWidth(i, defaultWidths[i].toDouble());
    }
  }
}
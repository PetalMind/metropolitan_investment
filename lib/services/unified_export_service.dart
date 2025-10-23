import 'package:excel/excel.dart';
import 'dart:convert';
import '../models_and_services.dart';

/// Ujednolicony serwis eksportu danych do różnych formatów
///
/// Zapewnia spójne generowanie eksportów w formatach Excel, PDF i Word
/// z identycznymi danymi i strukturą dla wszystkich formatów.
class UnifiedExportService extends BaseService {
  /// Generuje ujednolicony Excel z dokładnie tymi samymi danymi co PDF/Word
  ///
  /// @param investors Lista inwestorów do eksportu
  /// @param options Opcje eksportu (nagłówki, zawartość, formatowanie)
  /// @param exportTitle Tytuł eksportu dla nazwy pliku
  /// @returns Map z danymi pliku (base64, filename, size)
  Future<Map<String, dynamic>> generateUnifiedExcel({
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

      // Opcje eksportu - identyczne dla wszystkich formatów eksportu
      final includeContactInfo = options['includePersonalData'] ?? true;
      final includeInvestmentDetails =
          options['includeInvestmentDetails'] ?? true;
      final includeFinancialSummary =
          options['includeFinancialSummary'] ?? true;
      final sortBy = options['sortBy'] ?? 'name';
      final sortDescending = options['sortDescending'] ?? false;

      // Sortuj inwestorów
      final sortedInvestors = _sortInvestors(investors, sortBy, sortDescending);

      logDebug(
        'generateUnifiedExcel',
        'Generuję Excel dla ${sortedInvestors.length} inwestorów',
      );

      // Utwórz style
      final headerStyle = _createHeaderStyle();
      final dataStyle = _createDataStyle();
      final numberStyle = _createNumberStyle();
      final dateStyle = _createDateStyle();
      final titleStyle = _createTitleStyle();
      final subtitleStyle = _createSubtitleStyle();

      int currentRow = 0;

      // Nagłówek dokumentu
      _addDocumentHeader(
        sheet,
        exportTitle,
        currentRow,
        titleStyle,
        subtitleStyle,
      );
      currentRow += 3;

      // Nagłówki kolumn
      final headers = _buildHeaders(
        includeContactInfo,
        includeInvestmentDetails,
        includeFinancialSummary,
      );
      _addHeaders(sheet, headers, currentRow, headerStyle);
      currentRow += 1;

      // Dane inwestorów - każda inwestycja w osobnym wierszu
      for (final investor in sortedInvestors) {
        // Wyświetlaj każdą inwestycję w osobnym wierszu
        if (investor.investments.isEmpty) {
          // Jeśli nie ma inwestycji, pokaż pusty wiersz z danymi inwestora
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
            showInvestmentInSeparateRows: true,
          );
          currentRow += 1;
        } else {
          // Dla każdej inwestycji dodaj osobny wiersz
          for (int i = 0; i < investor.investments.length; i++) {
            final investment = investor.investments[i];
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
              showInvestmentInSeparateRows: true,
              singleInvestment: investment,
              isFirstRow: i == 0, // Tylko pierwszy wiersz ma liczbę inwestycji
            );
            currentRow += 1;
          }
        }
      }

      // Podsumowanie statystyczne (dodatkowy element - taki sam jak w PDF/Word)
      currentRow += 2;
      _addSummarySection(
        sheet,
        sortedInvestors,
        currentRow,
        titleStyle,
        numberStyle,
      );

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
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final filename = 'Raport_Inwestorow_$dateStr.xlsx';

      logDebug(
        'generateUnifiedExcel',
        'Excel wygenerowany w ${executionTime}ms, rozmiar: ${excelBytes.length} bajtów',
      );

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
      logError('generateUnifiedExcel', e);
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
          comparison = a.totalRemainingCapital.compareTo(
            b.totalRemainingCapital,
          );
          break;
        case 'investmentCount':
          comparison = a.investmentCount.compareTo(b.investmentCount);
          break;
        case 'signedDate':
          final aDate = a.investments.isNotEmpty
              ? a.investments.first.signedDate
              : DateTime.now();
          final bDate = b.investments.isNotEmpty
              ? b.investments.first.signedDate
              : DateTime.now();
          comparison = aDate.compareTo(bDate);
          break;
        default:
          comparison = a.client.name.compareTo(b.client.name);
      }

      return sortDescending ? -comparison : comparison;
    });

    return sorted;
  }

  /// Tworzy styl tytułu głównego
  CellStyle _createTitleStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 18,
      bold: true,
      fontColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  /// Tworzy styl podtytułu
  CellStyle _createSubtitleStyle() {
    return CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 11,
      fontColorHex: ExcelColor.grey600,
      horizontalAlign: HorizontalAlign.Center,
    );
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
  void _addDocumentHeader(
    Sheet sheet,
    String title,
    int row,
    CellStyle titleStyle,
    CellStyle subtitleStyle,
  ) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      title,
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .cellStyle =
        titleStyle;

    final now = DateTime.now();
    final dateText =
        'Wygenerowano: ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1))
        .value = TextCellValue(
      dateText,
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1))
            .cellStyle =
        subtitleStyle;
  }

  /// Buduje nagłówki kolumn
  List<String> _buildHeaders(
    bool includeContactInfo,
    bool includeInvestmentDetails,
    bool includeFinancialSummary,
  ) {
    final headers = <String>['Lp.', 'Nazwa Klienta'];

    if (includeContactInfo) {
      headers.addAll(['Email', 'Telefon', 'Adres']);
    }

    if (includeInvestmentDetails) {
      headers.addAll([
        'Liczba Inwestycji',
        'Nazwa Inwestycji', // Teraz pokazuje pojedynczą inwestycję
        'Rodzaj Produktu', // Zmieniono na pojedynczy rodzaj
      ]);
    }

    if (includeFinancialSummary) {
      headers.addAll([
        'Kwota Inwestycji (PLN)', // Usunięto "Łączna" bo pokazujemy pojedyncze
        'Pozostały Kapitał (PLN)',
        'Kapitał Zabezpieczony Nieruchomościami (PLN)',
        'Kapitał do Restrukturyzacji (PLN)',
      ]);
    }

    return headers;
  }

  /// Dodaje nagłówki do arkusza
  void _addHeaders(
    Sheet sheet,
    List<String> headers,
    int row,
    CellStyle style,
  ) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = style;
    }
  }

  /// Dodaje wiersz z danymi inwestora i jego inwestycji
  /// @param showInvestmentInSeparateRows - jeśli true, każda inwestycja będzie w osobnym wierszu
  void _addInvestorRow(
    Sheet sheet,
    InvestorSummary investor,
    int row,
    CellStyle dataStyle,
    CellStyle numberStyle,
    CellStyle dateStyle,
    bool includeContactInfo,
    bool includeInvestmentDetails,
    bool includeFinancialSummary, {
    bool showInvestmentInSeparateRows = true,
    Investment? singleInvestment,
    bool isFirstRow = true,
  }) {
    int col = 0;

    // Lp.
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
        .value = IntCellValue(
      row - 1,
    );

    // Nazwa Klienta
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
        .value = TextCellValue(
      investor.client.name,
    );
    sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
            )
            .cellStyle =
        dataStyle;

    if (includeContactInfo) {
      // Email
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(
        investor.client.email,
      );
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          dataStyle;

      // Telefon
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(
        investor.client.phone,
      );
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          dataStyle;

      // Adres
      final address = _formatAddress(investor.client);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(
        address,
      );
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          dataStyle;
    }

    if (includeInvestmentDetails) {
      // Liczba Inwestycji - pokazujemy tylko w pierwszym wierszu jeśli mamy wiele inwestycji
      if (isFirstRow || !showInvestmentInSeparateRows) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = IntCellValue(
          investor.investmentCount,
        );
      } else {
        // Puste pole dla kolejnych inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(
          '',
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          numberStyle;

      // Nazwa Inwestycji - jedna inwestycja na wiersz lub wszystkie złączone przecinkami
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Pojedyncza inwestycja w tym wierszu
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(
          singleInvestment.productName,
        );
      } else {
        // Wszystkie inwestycje złączone przecinkami (stary sposób)
        final investmentNames = investor.investments
            .map((inv) => inv.productName)
            .join(', ');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(
          investmentNames,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          dataStyle;

      // Rodzaj Produktu - jeden typ na wiersz lub wszystkie złączone przecinkami
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Typ pojedynczej inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(
          _translateProductType(singleInvestment.productType),
        );
      } else {
        // Wszystkie typy złączone przecinkami (stary sposób)
        final productTypes = investor.investments
            .map((inv) => _translateProductType(inv.productType))
            .toSet()
            .join(', ');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(
          productTypes,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          dataStyle;
    }

    if (includeFinancialSummary) {
      // Kwota Inwestycji - pojedyncza lub łączna
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Kwota pojedynczej inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          singleInvestment.investmentAmount,
        );
      } else {
        // Łączna kwota wszystkich inwestycji (stary sposób)
        final totalInvestment = investor.investments.fold<double>(
          0,
          (sum, inv) => sum + inv.investmentAmount,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          totalInvestment,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          numberStyle;

      // Pozostały Kapitał - pojedynczy lub łączny
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Kapitał pozostały dla pojedynczej inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          singleInvestment.remainingCapital,
        );
      } else {
        // Łączny kapitał pozostały (stary sposób)
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          investor.totalRemainingCapital,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          numberStyle;

      // Kapitał Zabezpieczony - pojedynczy lub łączny
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Kapitał zabezpieczony dla pojedynczej inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          singleInvestment.capitalSecuredByRealEstate,
        );
      } else {
        // Łączny kapitał zabezpieczony (stary sposób)
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          investor.capitalSecuredByRealEstate,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          numberStyle;

      // Kapitał do Restrukturyzacji - pojedynczy lub łączny
      if (showInvestmentInSeparateRows && singleInvestment != null) {
        // Kapitał do restrukturyzacji dla pojedynczej inwestycji
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          singleInvestment.capitalForRestructuring,
        );
      } else {
        // Łączny kapitał do restrukturyzacji (stary sposób)
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = DoubleCellValue(
          investor.capitalForRestructuring,
        );
      }
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row),
              )
              .cellStyle =
          numberStyle;
    }
  }

  /// Formatuje adres klienta w jednolity sposób
  String _formatAddress(Client client) {
    // W modelu Client adres jest już przechowywany jako pojedyncze pole,
    // więc po prostu go zwracamy lub zwracamy pusty string jeśli nie istnieje
    return client.address;
  }

  /// Tłumaczy typ produktu na polski
  String _translateProductType(ProductType productType) {
    return productType.displayName;
  }

  /// Dodaje sekcję podsumowania (taka sama jak w PDF i Word)
  void _addSummarySection(
    Sheet sheet,
    List<InvestorSummary> investors,
    int startRow,
    CellStyle titleStyle,
    CellStyle numberStyle,
  ) {
    // Tytuł sekcji podsumowania
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow))
        .value = TextCellValue(
      'Podsumowanie Eksportu',
    );
    sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow),
            )
            .cellStyle =
        titleStyle;

    // Dodaj daty raportu do podsumowania - identycznie jak w PDF/Word
    final now = DateTime.now();
    final dateString =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 1),
        )
        .value = TextCellValue(
      'Data raportu: $dateString',
    );

    int row = startRow + 3;

    // Nagłówek sekcji statystycznej
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
        .value = TextCellValue(
      'Statystyki Inwestorów',
    );

    // Statystyki
    final totalInvestors = investors.length;
    final totalInvestments = investors.fold<int>(
      0,
      (sum, investor) => sum + investor.investmentCount,
    );
    final totalCapital = investors.fold<double>(
      0,
      (sum, investor) => sum + investor.totalRemainingCapital,
    );
    final totalSecuredCapital = investors.fold<double>(
      0,
      (sum, investor) => sum + investor.capitalSecuredByRealEstate,
    );
    final totalCapitalForRestructuring = investors.fold<double>(
      0,
      (sum, investor) => sum + investor.capitalForRestructuring,
    );
    final initialInvestment = investors.fold<double>(
      0,
      (sum, investor) =>
          sum +
          investor.investments.fold<double>(
            0,
            (sum2, inv) => sum2 + inv.investmentAmount,
          ),
    );

    // Dodaj statystyki
    _addSummaryRow(
      sheet,
      row++,
      'Liczba Inwestorów:',
      totalInvestors,
      numberStyle,
    );
    _addSummaryRow(
      sheet,
      row++,
      'Liczba Inwestycji:',
      totalInvestments,
      numberStyle,
    );
    _addSummaryRow(
      sheet,
      row++,
      'Średnia liczba inwestycji na inwestora:',
      totalInvestors > 0 ? (totalInvestments / totalInvestors) : 0,
      numberStyle,
    );

    row++;
    // Nagłówek sekcji finansowej
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
        .value = TextCellValue(
      'Podsumowanie Finansowe',
    );

    _addSummaryRow(
      sheet,
      row++,
      'Początkowa wartość inwestycji (PLN):',
      initialInvestment,
      numberStyle,
    );
    _addSummaryRow(
      sheet,
      row++,
      'Łączny Kapitał Pozostały (PLN):',
      totalCapital,
      numberStyle,
    );
    _addSummaryRow(
      sheet,
      row++,
      'Łączny Kapitał Zabezpieczony (PLN):',
      totalSecuredCapital,
      numberStyle,
    );
    _addSummaryRow(
      sheet,
      row++,
      'Łączny Kapitał do Restrukturyzacji (PLN):',
      totalCapitalForRestructuring,
      numberStyle,
    );

    row++;
    // Wskaźniki
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
        .value = TextCellValue(
      'Wskaźniki',
    );

    // Procent kapitału zabezpieczonego
    final securedPercentage = totalCapital > 0
        ? (totalSecuredCapital / totalCapital * 100)
        : 0;
    _addSummaryRow(
      sheet,
      row++,
      'Procent Kapitału Zabezpieczonego:',
      securedPercentage,
      numberStyle,
      isPercentage: true,
    );

    // Dodatkowe wskaźniki - dokładnie te same, które są w PDF/Word
    final riskRatio = totalCapital > 0
        ? (totalCapitalForRestructuring / totalCapital * 100)
        : 0;
    _addSummaryRow(
      sheet,
      row++,
      'Wskaźnik ryzyka (kapitał do restrukturyzacji / kapitał całkowity):',
      riskRatio,
      numberStyle,
      isPercentage: true,
    );

    final returnOnInvestment = initialInvestment > 0
        ? ((initialInvestment - totalCapital) / initialInvestment * 100)
        : 0;
    _addSummaryRow(
      sheet,
      row++,
      'Zwrot z inwestycji do tej pory:',
      returnOnInvestment,
      numberStyle,
      isPercentage: true,
    );
  }

  /// Dodaje wiersz z podsumowaniem
  void _addSummaryRow(
    Sheet sheet,
    int row,
    String label,
    dynamic value,
    CellStyle numberStyle, {
    bool isPercentage = false,
    int decimalPlaces = 2,
  }) {
    // Etykieta
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      label,
    );

    // Wartość
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      if (isPercentage) {
        cell.value = TextCellValue('${value.toStringAsFixed(decimalPlaces)}%');
      } else {
        cell.value = DoubleCellValue(value);
      }
    } else {
      cell.value = TextCellValue(value.toString());
    }
    cell.cellStyle = numberStyle;
  }

  /// Automatycznie dopasowuje szerokość kolumn
  void _autoSizeColumns(Sheet sheet, int columnCount) {
    // Pakiet excel nie ma bezpośredniego auto-size, więc ustawiamy sensowne szerokości
    final defaultWidths = <int>[
      5, // Lp.
      25, // Nazwa Klienta
      22, // Email
      15, // Telefon
      30, // Adres
      10, // Liczba Inwestycji
      30, // Nazwa Inwestycji (zwiększono dla lepszej czytelności)
      18, // Rodzaj Produktu (pojedynczy)
      16, // Kwota Inwestycji (pojedyncza)
      16, // Pozostały Kapitał (pojedynczy)
      22, // Kapitał Zabezpieczony (pojedynczy)
      22, // Kapitał do Restrukturyzacji (pojedynczy)
    ];

    for (int i = 0; i < columnCount && i < defaultWidths.length; i++) {
      sheet.setColumnWidth(i, defaultWidths[i].toDouble());
    }
  }
}

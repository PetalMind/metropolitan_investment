import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// 📧 MODEL ZAPLANOWANEGO EMAILA
///
/// Reprezentuje email zaplanowany do wysłania w przyszłości.
/// Zawiera wszystkie dane potrzebne do wysłania emaila wraz z metadanymi.
class ScheduledEmail {
  final String id;
  final List<InvestorSummary> recipients;
  final String subject;
  final String htmlContent;
  final DateTime scheduledDateTime;
  final String senderEmail;
  final String senderName;
  final bool includeInvestmentDetails;
  final Map<String, String> additionalRecipients;
  final ScheduledEmailStatus status;
  final DateTime createdAt;
  final String createdBy;
  final String? notes;
  final DateTime? updatedAt;
  final DateTime? sentAt;
  final DateTime? cancelledAt;
  final List<EmailSendResult>? sendResults;
  final int? successCount;
  final int? totalCount;
  final String? errorMessage;

  const ScheduledEmail({
    required this.id,
    required this.recipients,
    required this.subject,
    required this.htmlContent,
    required this.scheduledDateTime,
    required this.senderEmail,
    required this.senderName,
    required this.includeInvestmentDetails,
    required this.additionalRecipients,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.notes,
    this.updatedAt,
    this.sentAt,
    this.cancelledAt,
    this.sendResults,
    this.successCount,
    this.totalCount,
    this.errorMessage,
  });

  /// Konwertuj do Map dla Firestore
  Map<String, dynamic> toMap() {
    return {
      'recipientsCount': recipients.length,
      'recipientsEmails': recipients.map((r) => r.client.email).toList(),
      'subject': subject,
      'htmlContent': htmlContent,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'senderEmail': senderEmail,
      'senderName': senderName,
      'includeInvestmentDetails': includeInvestmentDetails,
      'additionalRecipients': additionalRecipients,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'notes': notes,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'sendResultsCount': sendResults?.length,
      'successCount': successCount,
      'totalCount': totalCount,
      'errorMessage': errorMessage,
    };
  }

  /// Utwórz z Map z Firestore
  factory ScheduledEmail.fromMap(Map<String, dynamic> map, String id) {
    return ScheduledEmail(
      id: id,
      recipients: [], // Will be loaded separately if needed
      subject: map['subject'] as String? ?? '',
      htmlContent: map['htmlContent'] as String? ?? '',
      scheduledDateTime:
          (map['scheduledDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderEmail: map['senderEmail'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      includeInvestmentDetails:
          map['includeInvestmentDetails'] as bool? ?? true,
      additionalRecipients: Map<String, String>.from(
        map['additionalRecipients'] as Map? ?? {},
      ),
      status: ScheduledEmailStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ScheduledEmailStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? 'unknown',
      notes: map['notes'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      sendResults: null, // Simplified for now
      successCount: map['successCount'] as int?,
      totalCount: map['totalCount'] as int?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// Skopiuj z nowymi wartościami
  ScheduledEmail copyWith({
    String? id,
    List<InvestorSummary>? recipients,
    String? subject,
    String? htmlContent,
    DateTime? scheduledDateTime,
    String? senderEmail,
    String? senderName,
    bool? includeInvestmentDetails,
    Map<String, String>? additionalRecipients,
    ScheduledEmailStatus? status,
    DateTime? createdAt,
    String? createdBy,
    String? notes,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? cancelledAt,
    List<EmailSendResult>? sendResults,
    int? successCount,
    int? totalCount,
    String? errorMessage,
  }) {
    return ScheduledEmail(
      id: id ?? this.id,
      recipients: recipients ?? this.recipients,
      subject: subject ?? this.subject,
      htmlContent: htmlContent ?? this.htmlContent,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      includeInvestmentDetails:
          includeInvestmentDetails ?? this.includeInvestmentDetails,
      additionalRecipients: additionalRecipients ?? this.additionalRecipients,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      sendResults: sendResults ?? this.sendResults,
      successCount: successCount ?? this.successCount,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Czy email można edytować
  bool get canEdit => status == ScheduledEmailStatus.pending;

  /// Czy email można anulować
  bool get canCancel => status == ScheduledEmailStatus.pending;

  /// Czy email został pomyślnie wysłany
  bool get wasSuccessful => status == ScheduledEmailStatus.sent;

  /// Czy email się nie udał
  bool get failed =>
      status == ScheduledEmailStatus.failed ||
      status == ScheduledEmailStatus.partiallyFailed;

  /// Ile czasu zostało do wysłania
  Duration? get timeUntilSend {
    if (status != ScheduledEmailStatus.pending) return null;
    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now)) return Duration.zero;
    return scheduledDateTime.difference(now);
  }

  /// Czytelny format czasu do wysłania
  String get timeUntilSendFormatted {
    final duration = timeUntilSend;
    if (duration == null) return 'N/A';

    if (duration == Duration.zero) return 'Gotowy do wysłania';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days dni, $hours godz.';
    } else if (hours > 0) {
      return '$hours godz., $minutes min.';
    } else {
      return '$minutes min.';
    }
  }

  @override
  String toString() {
    return 'ScheduledEmail(id: $id, subject: $subject, status: $status, scheduledDateTime: $scheduledDateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledEmail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 🎯 STATUS ZAPLANOWANEGO EMAILA
enum ScheduledEmailStatus {
  /// Oczekuje na wysłanie
  pending('pending', 'Oczekuje', '⏳'),

  /// W trakcie wysyłania
  sending('sending', 'Wysyłanie', '📤'),

  /// Wysłany pomyślnie
  sent('sent', 'Wysłany', '✅'),

  /// Wysłanie nie udało się
  failed('failed', 'Nieudany', '❌'),

  /// Częściowo nieudany (niektóre emaile się udały)
  partiallyFailed('partiallyFailed', 'Częściowo nieudany', '⚠️'),

  /// Anulowany przez użytkownika
  cancelled('cancelled', 'Anulowany', '🚫');

  const ScheduledEmailStatus(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  /// Czy status oznacza zakończenie procesu
  bool get isCompleted =>
      [sent, failed, partiallyFailed, cancelled].contains(this);

  /// Czy status oznacza sukces
  bool get isSuccessful => this == sent;

  /// Czy status oznacza błąd
  bool get isError => [failed, partiallyFailed].contains(this);
}

/// 📄 MODEL DANYCH TABELI
///
/// Reprezentuje tabelę w edytorze emaili z danymi i formatowaniem.
class TableData {
  final String id;
  final List<List<String>> rows;
  final List<String> headers;
  final TableStyle style;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TableData({
    required this.id,
    required this.rows,
    required this.headers,
    required this.style,
    required this.createdAt,
    this.updatedAt,
  });

  /// Konwertuj do Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rows': rows,
      'headers': headers,
      'style': style.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Utwórz z Map
  factory TableData.fromMap(Map<String, dynamic> map) {
    return TableData(
      id: map['id'] as String? ?? '',
      rows:
          (map['rows'] as List<dynamic>?)
              ?.map((row) => (row as List<dynamic>).cast<String>())
              .toList() ??
          [],
      headers: (map['headers'] as List<dynamic>?)?.cast<String>() ?? [],
      style: TableStyle.fromMap(map['style'] as Map<String, dynamic>? ?? {}),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Skopiuj z nowymi wartościami
  TableData copyWith({
    String? id,
    List<List<String>>? rows,
    List<String>? headers,
    TableStyle? style,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableData(
      id: id ?? this.id,
      rows: rows ?? this.rows,
      headers: headers ?? this.headers,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Dodaj wiersz
  TableData addRow(List<String> row) {
    return copyWith(rows: [...rows, row], updatedAt: DateTime.now());
  }

  /// Usuń wiersz
  TableData removeRow(int index) {
    if (index < 0 || index >= rows.length) return this;

    final newRows = List<List<String>>.from(rows);
    newRows.removeAt(index);

    return copyWith(rows: newRows, updatedAt: DateTime.now());
  }

  /// Dodaj kolumnę
  TableData addColumn(String header) {
    final newHeaders = [...headers, header];
    final newRows = rows.map((row) => [...row, '']).toList();

    return copyWith(
      headers: newHeaders,
      rows: newRows,
      updatedAt: DateTime.now(),
    );
  }

  /// Usuń kolumnę
  TableData removeColumn(int index) {
    if (index < 0 || index >= headers.length) return this;

    final newHeaders = List<String>.from(headers);
    newHeaders.removeAt(index);

    final newRows = rows.map((row) {
      final newRow = List<String>.from(row);
      if (index < newRow.length) newRow.removeAt(index);
      return newRow;
    }).toList();

    return copyWith(
      headers: newHeaders,
      rows: newRows,
      updatedAt: DateTime.now(),
    );
  }

  /// Aktualizuj komórkę
  TableData updateCell(int rowIndex, int columnIndex, String value) {
    if (rowIndex < 0 || rowIndex >= rows.length) return this;
    if (columnIndex < 0 || columnIndex >= headers.length) return this;

    final newRows = List<List<String>>.from(rows);
    final newRow = List<String>.from(newRows[rowIndex]);

    // Uzupełnij wiersz jeśli za krótki
    while (newRow.length <= columnIndex) {
      newRow.add('');
    }

    newRow[columnIndex] = value;
    newRows[rowIndex] = newRow;

    return copyWith(rows: newRows, updatedAt: DateTime.now());
  }

  /// Konwertuj do HTML
  String toHtml() {
    final buffer = StringBuffer();

    // Otwarcie tabeli z stylami
    buffer.write('<table');
    if (style.borderWidth > 0) {
      buffer.write(' border="${style.borderWidth}"');
    }
    buffer.write(' style="');
    buffer.write('border-collapse: collapse;');
    if (style.width != null) {
      buffer.write(' width: ${style.width};');
    }
    buffer.write('">');

    // Nagłówki
    if (headers.isNotEmpty) {
      buffer.write('<thead><tr>');
      for (final header in headers) {
        buffer.write('<th style="');
        buffer.write('padding: ${style.cellPadding}px;');
        buffer.write(
          ' border: ${style.borderWidth}px solid ${style.borderColor};',
        );
        buffer.write(' background-color: ${style.headerBackgroundColor};');
        buffer.write(' color: ${style.headerTextColor};');
        buffer.write(' font-weight: bold;');
        buffer.write('">$header</th>');
      }
      buffer.write('</tr></thead>');
    }

    // Wiersze danych
    buffer.write('<tbody>');
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final isEven = i % 2 == 0;
      final bgColor = isEven ? style.evenRowColor : style.oddRowColor;

      buffer.write('<tr>');
      for (int j = 0; j < headers.length; j++) {
        final cellValue = j < row.length ? row[j] : '';
        buffer.write('<td style="');
        buffer.write('padding: ${style.cellPadding}px;');
        buffer.write(
          ' border: ${style.borderWidth}px solid ${style.borderColor};',
        );
        buffer.write(' background-color: $bgColor;');
        buffer.write('">$cellValue</td>');
      }
      buffer.write('</tr>');
    }
    buffer.write('</tbody>');

    buffer.write('</table>');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'TableData(id: $id, headers: $headers, rows: ${rows.length})';
  }
}

/// 🎨 STYL TABELI
class TableStyle {
  final int borderWidth;
  final String borderColor;
  final double cellPadding;
  final String? width;
  final String headerBackgroundColor;
  final String headerTextColor;
  final String evenRowColor;
  final String oddRowColor;

  const TableStyle({
    this.borderWidth = 1,
    this.borderColor = '#cccccc',
    this.cellPadding = 8.0,
    this.width,
    this.headerBackgroundColor = '#f5f5f5',
    this.headerTextColor = '#333333',
    this.evenRowColor = '#ffffff',
    this.oddRowColor = '#f9f9f9',
  });

  /// Domyślny styl
  factory TableStyle.defaultStyle() => const TableStyle();

  /// Styl profesjonalny
  factory TableStyle.professional() => const TableStyle(
    borderWidth: 1,
    borderColor: '#ddd',
    cellPadding: 12.0,
    width: '100%',
    headerBackgroundColor: '#2c5aa0',
    headerTextColor: '#ffffff',
    evenRowColor: '#ffffff',
    oddRowColor: '#f8f9fa',
  );

  /// Styl minimalny
  factory TableStyle.minimal() => const TableStyle(
    borderWidth: 0,
    borderColor: 'transparent',
    cellPadding: 6.0,
    headerBackgroundColor: 'transparent',
    headerTextColor: '#333333',
    evenRowColor: 'transparent',
    oddRowColor: 'transparent',
  );

  /// Konwertuj do Map
  Map<String, dynamic> toMap() {
    return {
      'borderWidth': borderWidth,
      'borderColor': borderColor,
      'cellPadding': cellPadding,
      'width': width,
      'headerBackgroundColor': headerBackgroundColor,
      'headerTextColor': headerTextColor,
      'evenRowColor': evenRowColor,
      'oddRowColor': oddRowColor,
    };
  }

  /// Utwórz z Map
  factory TableStyle.fromMap(Map<String, dynamic> map) {
    return TableStyle(
      borderWidth: map['borderWidth'] as int? ?? 1,
      borderColor: map['borderColor'] as String? ?? '#cccccc',
      cellPadding: (map['cellPadding'] as num?)?.toDouble() ?? 8.0,
      width: map['width'] as String?,
      headerBackgroundColor:
          map['headerBackgroundColor'] as String? ?? '#f5f5f5',
      headerTextColor: map['headerTextColor'] as String? ?? '#333333',
      evenRowColor: map['evenRowColor'] as String? ?? '#ffffff',
      oddRowColor: map['oddRowColor'] as String? ?? '#f9f9f9',
    );
  }

  /// Skopiuj z nowymi wartościami
  TableStyle copyWith({
    int? borderWidth,
    String? borderColor,
    double? cellPadding,
    String? width,
    String? headerBackgroundColor,
    String? headerTextColor,
    String? evenRowColor,
    String? oddRowColor,
  }) {
    return TableStyle(
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      cellPadding: cellPadding ?? this.cellPadding,
      width: width ?? this.width,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      evenRowColor: evenRowColor ?? this.evenRowColor,
      oddRowColor: oddRowColor ?? this.oddRowColor,
    );
  }
}

/// 🖼️ MODEL DANYCH OBRAZKA
///
/// Reprezentuje obrazek w edytorze emaili z metadanymi i opcjami wyświetlania.
class ImageData {
  final String id;
  final String fileName;
  final String? filePath; // Lokalna ścieżka
  final String? url; // URL (po upload)
  final String? base64Data; // Dane base64
  final int? fileSizeBytes;
  final String? mimeType;
  final ImageAlignment alignment;
  final ImageSize size;
  final String? altText;
  final String? caption;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ImageData({
    required this.id,
    required this.fileName,
    this.filePath,
    this.url,
    this.base64Data,
    this.fileSizeBytes,
    this.mimeType,
    this.alignment = ImageAlignment.left,
    this.size = ImageSize.medium,
    this.altText,
    this.caption,
    required this.createdAt,
    this.updatedAt,
  });

  /// Konwertuj do Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'url': url,
      'base64Data': base64Data,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'alignment': alignment.name,
      'size': size.name,
      'altText': altText,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Utwórz z Map
  factory ImageData.fromMap(Map<String, dynamic> map) {
    return ImageData(
      id: map['id'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      filePath: map['filePath'] as String?,
      url: map['url'] as String?,
      base64Data: map['base64Data'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      mimeType: map['mimeType'] as String?,
      alignment: ImageAlignment.values.firstWhere(
        (a) => a.name == map['alignment'],
        orElse: () => ImageAlignment.left,
      ),
      size: ImageSize.values.firstWhere(
        (s) => s.name == map['size'],
        orElse: () => ImageSize.medium,
      ),
      altText: map['altText'] as String?,
      caption: map['caption'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Skopiuj z nowymi wartościami
  ImageData copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? url,
    String? base64Data,
    int? fileSizeBytes,
    String? mimeType,
    ImageAlignment? alignment,
    ImageSize? size,
    String? altText,
    String? caption,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImageData(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      base64Data: base64Data ?? this.base64Data,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      alignment: alignment ?? this.alignment,
      size: size ?? this.size,
      altText: altText ?? this.altText,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Czy obrazek ma dane do wyświetlenia
  bool get hasDisplayData =>
      url != null || base64Data != null || filePath != null;

  /// Czy obrazek został uploadowany
  bool get isUploaded => url != null;

  /// Rozmiar pliku w formacie czytelnym
  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Nieznany';

    final sizeInKB = fileSizeBytes! / 1024;
    if (sizeInKB < 1024) {
      return '${sizeInKB.toStringAsFixed(1)} KB';
    } else {
      final sizeInMB = sizeInKB / 1024;
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
  }

  /// Konwertuj do HTML
  String toHtml() {
    if (!hasDisplayData) return '';

    final buffer = StringBuffer();

    // Kontener z alignmentem
    buffer.write(
      '<div style="text-align: ${alignment.cssValue}; margin: 10px 0;">',
    );

    // Tag obrazka
    buffer.write('<img');

    // Źródło obrazka
    if (url != null) {
      buffer.write(' src="$url"');
    } else if (base64Data != null) {
      final mimePrefix = mimeType ?? 'image/jpeg';
      buffer.write(' src="data:$mimePrefix;base64,$base64Data"');
    }

    // Alt text
    if (altText != null) {
      buffer.write(' alt="$altText"');
    }

    // Styl rozmiaru
    buffer.write(' style="');
    buffer.write(size.cssStyle);
    buffer.write(' height: auto;');
    buffer.write(' display: block;');
    if (alignment == ImageAlignment.center) {
      buffer.write(' margin-left: auto; margin-right: auto;');
    }
    buffer.write('"');

    buffer.write('>');

    // Caption
    if (caption != null && caption!.isNotEmpty) {
      buffer.write('<p style="');
      buffer.write('font-size: 12px;');
      buffer.write(' color: #666;');
      buffer.write(' margin: 5px 0 0 0;');
      buffer.write(' font-style: italic;');
      buffer.write(' text-align: ${alignment.cssValue};');
      buffer.write('">$caption</p>');
    }

    buffer.write('</div>');

    return buffer.toString();
  }

  @override
  String toString() {
    return 'ImageData(id: $id, fileName: $fileName, size: $size)';
  }
}

/// 🎯 WYRÓWNANIE OBRAZKA
enum ImageAlignment {
  left('left', 'Po lewej'),
  center('center', 'Wyśrodkowany'),
  right('right', 'Po prawej');

  const ImageAlignment(this.cssValue, this.displayName);

  final String cssValue;
  final String displayName;
}

/// 📏 ROZMIAR OBRAZKA
enum ImageSize {
  small('small', 'Mały', 'max-width: 150px;'),
  medium('medium', 'Średni', 'max-width: 300px;'),
  large('large', 'Duży', 'max-width: 500px;'),
  full('full', 'Pełny', 'max-width: 100%;');

  const ImageSize(this.name, this.displayName, this.cssStyle);

  final String name;
  final String displayName;
  final String cssStyle;
}

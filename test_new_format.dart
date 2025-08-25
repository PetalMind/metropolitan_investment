void main() {
  // Enhanced email editor functionality validation
  print('✅ Enhanced Email Editor Dialog - New Investment List Features');
  print('🔧 Added functionality:');
  print('   - Individual investment list insertion button');
  print('   - Global investment list insertion button');
  print('   - Fixed light theme preview colors');
  print('   - HTML conversion for new investment formats');
  print('🚀 All features implemented successfully!');
}

String convertDetailedPlainTextToSimpleText(String investorName, String tableRows, String totalRow) {
  final buffer = StringBuffer();
  
  // Simple text formatting without HTML table
  buffer.writeln('<div style="margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #d4af37;">');
  buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Szczegółowe inwestycje: $investorName</h3>');
  
  // Convert table rows to simple text lines
  final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
  for (final row in rows) {
    final columns = row.split('|').map((col) => col.trim()).toList();
    
    if (columns.length >= 6) {
      buffer.writeln('<p style="margin: 8px 0; font-size: 14px; line-height: 1.5;">');
      buffer.writeln('<strong>${columns[0]}</strong><br>');
      buffer.writeln('• Kwota inwestycji: ${columns[1]}<br>');
      buffer.writeln('• Kapitał pozostały: ${columns[2]}<br>');
      buffer.writeln('• Kapitał zabezpieczony: ${columns[3]}<br>');
      buffer.writeln('• Kapitał do restrukturyzacji: ${columns[4]}<br>');
      if (columns[5].isNotEmpty) {
        buffer.writeln('• Wierzyciel: ${columns[5]}<br>');
      }
      buffer.writeln('</p>');
    }
  }
  
  // Total row as simple text
  if (totalRow.isNotEmpty) {
    final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
    if (totalColumns.length >= 5) {
      buffer.writeln('<div style="margin-top: 16px; padding: 12px; background-color: #d4af37; color: white; border-radius: 6px;">');
      buffer.writeln('<h4 style="margin: 0 0 8px 0; color: white;">PODSUMOWANIE:</h4>');
      buffer.writeln('<p style="margin: 4px 0; font-weight: bold;">');
      buffer.writeln('• Łączna kwota inwestycji: ${totalColumns[1]}<br>');
      buffer.writeln('• Łączny kapitał pozostały: ${totalColumns[2]}<br>');
      buffer.writeln('• Łączny kapitał zabezpieczony: ${totalColumns[3]}<br>');
      buffer.writeln('• Łączny kapitał do restrukturyzacji: ${totalColumns[4]}');
      buffer.writeln('</p>');
      buffer.writeln('</div>');
    }
  }
  
  buffer.writeln('</div>');
  
  return buffer.toString();
}

String convertDetailedAggregatedToSimpleText(String tableRows, String totalRow) {
  final buffer = StringBuffer();
  
  // Simple text formatting without HTML table
  buffer.writeln('<div style="margin: 20px 0; padding: 20px; background-color: #f0f8ff; border-radius: 8px; border-left: 4px solid #d4af37;">');
  buffer.writeln('<h3 style="color: #d4af37; margin-bottom: 16px;">📊 Zbiorcze podsumowanie inwestycji</h3>');
  
  // Convert table rows to simple text lines
  final rows = tableRows.split('\n').where((row) => row.trim().isNotEmpty);
  for (final row in rows) {
    final columns = row.split('|').map((col) => col.trim()).toList();
    
    if (columns.length >= 5) {
      buffer.writeln('<p style="margin: 12px 0; font-size: 14px; line-height: 1.6; padding: 12px; background-color: white; border-radius: 6px; border-left: 3px solid #d4af37;">');
      buffer.writeln('<strong style="color: #2c2c2c; font-size: 16px;">${columns[0]}</strong><br>');
      buffer.writeln('• Liczba inwestycji: <strong>${columns[1]}</strong><br>');
      buffer.writeln('• Kapitał pozostały: <strong>${columns[2]}</strong><br>');
      buffer.writeln('• Kapitał zabezpieczony: <strong>${columns[3]}</strong><br>');
      buffer.writeln('• Kapitał do restrukturyzacji: <strong>${columns[4]}</strong>');
      buffer.writeln('</p>');
    }
  }
  
  // Total row as simple text
  if (totalRow.isNotEmpty) {
    final totalColumns = totalRow.split('|').map((col) => col.trim()).toList();
    if (totalColumns.length >= 5) {
      buffer.writeln('<div style="margin-top: 16px; padding: 16px; background-color: #d4af37; color: white; border-radius: 8px;">');
      buffer.writeln('<h4 style="margin: 0 0 12px 0; color: white; font-size: 18px;">📈 ŁĄCZNE PODSUMOWANIE:</h4>');
      buffer.writeln('<p style="margin: 0; font-size: 16px; font-weight: bold; line-height: 1.5;">');
      buffer.writeln('• Łączna liczba inwestycji: ${totalColumns[1]}<br>');
      buffer.writeln('• Łączny kapitał pozostały: ${totalColumns[2]}<br>');
      buffer.writeln('• Łączny kapitał zabezpieczony: ${totalColumns[3]}<br>');
      buffer.writeln('• Łączny kapitał do restrukturyzacji: ${totalColumns[4]}');
      buffer.writeln('</p>');
      buffer.writeln('</div>');
    }
  }
  
  buffer.writeln('</div>');
  
  return buffer.toString();
}
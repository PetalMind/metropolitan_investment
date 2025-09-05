import 'lib/services/font_family_service.dart';
import 'lib/services/email_html_converter_service.dart';

/// Test mapowania czcionek od wyboru do HTML
void main() {
  print('🧪 TEST MAPOWANIA CZCIONEK FLUTTER QUILL → HTML EMAIL\n');
  
  // Test 1: Sprawdź lokalne czcionki
  print('📋 1. LOKALNE CZCIONKI Z ASSETS/FONTS/:');
  final localFonts = FontFamilyService.getLocalFonts();
  localFonts.forEach((name, value) {
    print('   $name → $value');
  });
  
  print('\n📧 2. MAPOWANIE DO CSS FONT-FAMILY (dla emaili):');
  localFonts.keys.forEach((fontName) {
    final cssFont = FontFamilyService.getCssFontFamily(fontName);
    final emailFont = FontFamilyService.getEmailSafeFontFamily(fontName);
    print('   $fontName:');
    print('     → CSS: $cssFont');
    print('     → Email: $emailFont');
  });
  
  print('\n🔄 3. TEST INTERPRETERA EmailHtmlConverterService:');
  localFonts.keys.forEach((fontName) {
    final cssResult = EmailHtmlConverterService.getCssFontFamily(fontName);
    print('   $fontName → $cssResult');
  });
  
  print('\n⚠️ 4. TEST SYSTEMOWYCH CZCIONEK (co się stanie):');
  final systemFonts = ['Arial', 'Helvetica', 'Times New Roman', 'Courier New', 'Roboto'];
  systemFonts.forEach((fontName) {
    final cssResult = EmailHtmlConverterService.getCssFontFamily(fontName);
    print('   $fontName → $cssResult');
  });
  
  print('\n✅ 5. TEST FLOW: QUILL DROPDOWN → EMAIL HTML');
  print('   Użytkownik wybiera w dropdown: "Arial"');
  print('   Quill zapisuje atrybut: font="Arial"');
  print('   EmailHtmlConverterService._convertFontAttribute("Arial") →');
  print('   getCssFontFamily("Arial") → ${EmailHtmlConverterService.getCssFontFamily('Arial')}');
  print('   HTML output: font-family: ${EmailHtmlConverterService.getCssFontFamily('Arial')} !important');
  
  print('\n🎯 WNIOSEK:');
  if (EmailHtmlConverterService.getCssFontFamily('Arial') != 'Arial, Arial, sans-serif') {
    print('   ✅ Systemowe czcionki są MAPOWANE na lokalne czcionki!');
  } else {
    print('   ❌ Systemowe czcionki NIE SĄ mapowane na lokalne!');
  }
}
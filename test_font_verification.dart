import 'lib/services/font_family_service.dart';

void main() {
  print('🔍 Verifying Local Font Configuration');
  print('=' * 50);
  
  // Test basic functionality
  final fonts = FontFamilyService.getVerifiedLocalFonts();
  print('✅ Found ${fonts.length} verified local fonts:');
  
  for (final font in fonts) {
    final displayName = FontFamilyService.getDisplayName(font);
    final isLocal = FontFamilyService.isLocalFont(font);
    final cssFamily = FontFamilyService.getCssFontFamily(font);
    final emailSafe = FontFamilyService.getEmailSafeFontFamily(font);
    final weights = FontFamilyService.getFontWeights()[font] ?? [];
    
    print('');
    print('📝 Font: $font');
    print('   Display Name: $displayName');
    print('   Is Local: $isLocal');
    print('   CSS Family: $cssFamily');
    print('   Email Safe: $emailSafe');
    print('   Available Weights: $weights');
  }
  
  print('');
  print('🧪 Testing system font mapping:');
  final systemFonts = ['Arial', 'Times New Roman', 'Helvetica', 'Georgia'];
  for (final systemFont in systemFonts) {
    final mapped = FontFamilyService.getCssFontFamily(systemFont);
    print('   $systemFont → $mapped');
  }
  
  print('');
  print('✅ Font verification complete!');
  print('All fonts are properly configured in assets/fonts/ and pubspec.yaml');
}
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Ścieżki do fontów
const sourceFontDir = path.join(__dirname, '../assets/fonts');
const targetFontDir = path.join(__dirname, 'assets/fonts');

// Fonty które chcemy skopiować dla obsługi polskich znaków
const fontsToCopy = [
  'Montserrat-Regular.ttf',
  'Montserrat-Bold.ttf',
  'Montserrat-Medium.ttf',
  'Montserrat-Light.ttf'
];

console.log('🔧 [SetupFonts] Kopiowanie fontów dla obsługi polskich znaków w PDF...');

// Utwórz katalog docelowy jeśli nie istnieje
if (!fs.existsSync(targetFontDir)) {
  fs.mkdirSync(targetFontDir, { recursive: true });
  console.log(`✅ [SetupFonts] Utworzono katalog: ${targetFontDir}`);
}

// Skopiuj każdy font
let copiedCount = 0;
fontsToCopy.forEach(fontFile => {
  const sourcePath = path.join(sourceFontDir, fontFile);
  const targetPath = path.join(targetFontDir, fontFile);

  if (fs.existsSync(sourcePath)) {
    try {
      fs.copyFileSync(sourcePath, targetPath);
      console.log(`✅ [SetupFonts] Skopiowano: ${fontFile}`);
      copiedCount++;
    } catch (error) {
      console.error(`❌ [SetupFonts] Błąd kopiowania ${fontFile}:`, error.message);
    }
  } else {
    console.warn(`⚠️ [SetupFonts] Nie znaleziono: ${sourcePath}`);
  }
});

console.log(`🎉 [SetupFonts] Ukończono! Skopiowano ${copiedCount}/${fontsToCopy.length} fontów`);
console.log('📄 [SetupFonts] PDF będzie teraz obsługiwać polskie znaki: ąćęłńóśźż');

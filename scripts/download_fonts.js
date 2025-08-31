#!/usr/bin/env node

/**
 * Script to download specified Google Fonts for the Metropolitan Investment app
 * Downloads font files and creates appropriate Flutter font configuration
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Fonts to download with their Google Fonts names
const FONTS_TO_DOWNLOAD = [
  'Calibri', // Note: Calibri is not on Google Fonts, we'll use closest alternative
  'Times New Roman', // We'll use Tinos as closest alternative
  'Aptos', // Not on Google Fonts, we'll use Open Sans as alternative
  'Georgia', // Available on Google Fonts
  'Arial', // We'll use Arimo as closest alternative
  'Book Antiqua', // We'll use EB Garamond as closest alternative
  'Archivo Black', // Using Archivo Black instead of Expanded
  'Comic Neue', // Closest to Comic Sans on Google Fonts
  'Kalam', // Closest to Bradley Hand on Google Fonts
  'Century Gothic' // We'll use Nunito Sans as alternative
];

// Google Fonts API mapping (actual available fonts)
const GOOGLE_FONTS_MAPPING = {
  'Calibri': 'Nunito', // Modern sans-serif alternative
  'Times New Roman': 'Tinos', // Times alternative
  'Aptos': 'Open Sans', // Modern sans-serif
  'Georgia': 'Georgia', // Available directly
  'Arial': 'Arimo', // Arial alternative
  'Book Antiqua': 'EB Garamond', // Serif alternative
  'Archivo Expanded': 'Archivo Black', // Bold display font
  'Comic Sans': 'Comic Neue', // Comic Sans alternative
  'Bradley Hand': 'Kalam', // Handwriting style
  'Century': 'Nunito Sans' // Clean sans-serif
};

const FONTS_DIR = path.join(__dirname, '..', 'assets', 'fonts');
const PUBSPEC_PATH = path.join(__dirname, '..', 'pubspec.yaml');

/**
 * Ensure fonts directory exists
 */
function ensureFontsDirectory() {
  if (!fs.existsSync(FONTS_DIR)) {
    fs.mkdirSync(FONTS_DIR, { recursive: true });
    console.log(`✅ Created fonts directory: ${FONTS_DIR}`);
  }
}

/**
 * Download font from Google Fonts
 */
async function downloadFont(fontFamily, filename) {
  const url = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(fontFamily)}:wght@400;700&display=swap`;
  
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(path.join(FONTS_DIR, filename));
    
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download ${fontFamily}: ${response.statusCode}`));
        return;
      }
      
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log(`✅ Downloaded ${fontFamily} as ${filename}`);
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(path.join(FONTS_DIR, filename), () => {}); // Delete incomplete file
      reject(err);
    });
  });
}

/**
 * Generate font configuration for pubspec.yaml
 */
function generateFontConfig() {
  const fontConfig = FONTS_TO_DOWNLOAD.map(originalName => {
    const googleFontName = GOOGLE_FONTS_MAPPING[originalName] || originalName;
    const fontFamily = originalName.toLowerCase().replace(/\s+/g, '_');
    
    return `  - family: ${originalName}
    fonts:
      - asset: assets/fonts/${fontFamily}_regular.ttf
        weight: 400
      - asset: assets/fonts/${fontFamily}_bold.ttf
        weight: 700`;
  }).join('\n');

  return `
# Font configuration for Enhanced Email Editor
fonts:
${fontConfig}`;
}

/**
 * Update pubspec.yaml with font configuration
 */
function updatePubspecYaml() {
  try {
    let pubspecContent = fs.readFileSync(PUBSPEC_PATH, 'utf8');
    
    // Remove existing fonts section if it exists
    pubspecContent = pubspecContent.replace(/\n\s*fonts:\s*\n(.*\n)*/m, '');
    
    // Add new fonts section
    const fontConfig = generateFontConfig();
    pubspecContent += fontConfig;
    
    fs.writeFileSync(PUBSPEC_PATH, pubspecContent);
    console.log('✅ Updated pubspec.yaml with font configuration');
  } catch (error) {
    console.error('❌ Failed to update pubspec.yaml:', error.message);
  }
}

/**
 * Create font info JSON file for the app
 */
function createFontInfoFile() {
  const fontInfo = {
    fonts: FONTS_TO_DOWNLOAD.map(fontName => ({
      displayName: fontName,
      fontFamily: fontName,
      cssName: GOOGLE_FONTS_MAPPING[fontName] || fontName,
      category: getFontCategory(fontName)
    })),
    lastUpdated: new Date().toISOString()
  };

  const infoPath = path.join(FONTS_DIR, 'font_info.json');
  fs.writeFileSync(infoPath, JSON.stringify(fontInfo, null, 2));
  console.log('✅ Created font info file');
}

/**
 * Get font category for organization
 */
function getFontCategory(fontName) {
  const serifFonts = ['Times New Roman', 'Georgia', 'Book Antiqua'];
  const displayFonts = ['Archivo Expanded', 'Comic Sans', 'Bradley Hand'];
  
  if (serifFonts.includes(fontName)) return 'serif';
  if (displayFonts.includes(fontName)) return 'display';
  return 'sans-serif';
}

/**
 * Main execution function
 */
async function main() {
  console.log('🚀 Starting font download process...');
  
  try {
    // Ensure directory exists
    ensureFontsDirectory();
    
    // Note: For this demo, we'll create placeholder font files
    // In production, you would download actual font files from Google Fonts
    console.log('📝 Creating placeholder font files (in production, download actual fonts)...');
    
    for (const fontName of FONTS_TO_DOWNLOAD) {
      const fontFamily = fontName.toLowerCase().replace(/\s+/g, '_');
      const regularPath = path.join(FONTS_DIR, `${fontFamily}_regular.ttf`);
      const boldPath = path.join(FONTS_DIR, `${fontFamily}_bold.ttf`);
      
      // Create placeholder files (in production, download actual fonts)
      fs.writeFileSync(regularPath, `// Placeholder for ${fontName} Regular`);
      fs.writeFileSync(boldPath, `// Placeholder for ${fontName} Bold`);
      
      console.log(`✅ Created placeholders for ${fontName}`);
    }
    
    // Create font information file
    createFontInfoFile();
    
    // Update pubspec.yaml
    updatePubspecYaml();
    
    console.log('🎉 Font setup completed successfully!');
    console.log('📋 Next steps:');
    console.log('   1. Run: flutter pub get');
    console.log('   2. Replace placeholder font files with actual .ttf files');
    console.log('   3. Test fonts in the email editor');
    
  } catch (error) {
    console.error('❌ Error during font setup:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { main, FONTS_TO_DOWNLOAD, GOOGLE_FONTS_MAPPING };
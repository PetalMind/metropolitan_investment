#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const https = require('https');
const { URL } = require('url');

// Clean download script for fonts used in the repo
// Usage: node scripts/download_fonts_clean.js [--dry-run] [--force]

const argv = process.argv.slice(2);
const dryRun = argv.includes('--dry-run');
const force = argv.includes('--force');

const outDir = path.resolve(__dirname, '..', 'assets', 'fonts');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

const fonts = {
    'Montserrat-Regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-Regular.ttf',
    'Montserrat-Bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-Bold.ttf',
    'Montserrat-Black.ttf': 'https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-Black.ttf',
    'Montserrat-Italic.ttf': 'https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-Italic.ttf',
    'archivo_black_regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/archivoblack/ArchivoBlack-Regular.ttf',
    'archivo_black_bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/archivoblack/ArchivoBlack-Regular.ttf',
    'kalam_regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/kalam/Kalam-Regular.ttf',
    'kalam_bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/kalam/Kalam-Bold.ttf',
    'comic_neue_regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/comicneue/ComicNeue-Regular.ttf',
    'comic_neue_bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/comicneue/ComicNeue-Bold.ttf',
    // proprietary / unavailable
    'aptos_regular.ttf': null,
    'aptos_bold.ttf': null,
    'calibri_regular.ttf': null,
    'calibri_bold.ttf': null,
    'arial_regular.ttf': null,
    'arial_bold.ttf': null,
    'georgia_regular.ttf': null,
    'georgia_bold.ttf': null,
    'century_gothic_regular.ttf': null,
    'century_gothic_bold.ttf': null,
    'book_antiqua_regular.ttf': null,
    'book_antiqua_bold.ttf': null,
    'times_new_roman_regular.ttf': null,
    'times_new_roman_bold.ttf': null,
};

function download(url, dest) {
    return new Promise((resolve, reject) => {
        if (!url) return reject(new Error('No URL provided'));
        const u = new URL(url);
        const options = { hostname: u.hostname, path: u.pathname + (u.search || ''), protocol: u.protocol, headers: { 'User-Agent': 'metropolitan-download-script/1.0' } };
        https.get(url, options, (res) => {
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) return download(res.headers.location, dest).then(resolve).catch(reject);
            if (res.statusCode !== 200) return reject(new Error(`Failed to download ${url} (status ${res.statusCode})`));
            const fileStream = fs.createWriteStream(dest);
            res.pipe(fileStream);
            fileStream.on('finish', () => fileStream.close(resolve));
            fileStream.on('error', reject);
        }).on('error', reject);
    });
}

async function run() {
    console.log('Downloading fonts to:', outDir);
    console.log('Options:', { dryRun, force });
    for (const [name, url] of Object.entries(fonts)) {
        const dest = path.join(outDir, name);
        if (!url) { console.log(`Skipping ${name}: no public URL available (proprietary or unknown).`); continue; }
        if (fs.existsSync(dest) && !force) { console.log(`Skipping ${name}: already exists (use --force to overwrite).`); continue; }
        console.log((dryRun ? '[DRY]' : '[DOWNLOAD]'), name, '->', url);
        if (dryRun) continue;
        try { await download(url, dest); console.log('Saved', dest); } catch (err) { console.error('Error downloading', name, err.message); }
    }
    console.log('Done.');
}

if (require.main === module) { run().catch(err => { console.error(err); process.exit(1); }); }

module.exports = { run };

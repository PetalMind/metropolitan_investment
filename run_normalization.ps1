# Skrypt PowerShell do normalizacji nazw pól JSON
# Metropolitan Investment - Normalizacja nazywnictwa

Write-Host "🔄 Normalizacja nazw pól JSON - Metropolitan Investment" -ForegroundColor Green
Write-Host "=" -ForegroundColor Yellow -NoNewline
Write-Host ("=" * 60) -ForegroundColor Yellow

# Sprawdź czy Python jest dostępny
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python dostępny: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Python nie jest dostępny. Zainstaluj Python 3.x" -ForegroundColor Red
    exit 1
}

# Sprawdź czy katalog istnieje
if (!(Test-Path "split_investment_data")) {
    Write-Host "❌ Katalog 'split_investment_data' nie istnieje!" -ForegroundColor Red
    exit 1
}

# Lista plików JSON
$jsonFiles = @("clients.json", "apartments.json", "loans.json", "shares.json")
$existingFiles = @()

foreach ($file in $jsonFiles) {
    $filePath = "split_investment_data\$file"
    if (Test-Path $filePath) {
        $existingFiles += $file
        $size = (Get-Item $filePath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "📄 Znaleziono: $file ($sizeKB KB)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Brak pliku: $file" -ForegroundColor Yellow
    }
}

if ($existingFiles.Count -eq 0) {
    Write-Host "❌ Nie znaleziono plików JSON do przetworzenia!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔧 Rozpoczynam normalizację..." -ForegroundColor Blue

# Uruchom skrypt Python
try {
    python normalize_json_fields.py
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Normalizacja zakończona pomyślnie!" -ForegroundColor Green
        
        # Uruchom walidację
        Write-Host "`n🔍 Uruchamiam walidację..." -ForegroundColor Blue
        python validate_json_normalization.py
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Walidacja zakończona!" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Błąd podczas normalizacji!" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Błąd uruchamiania skryptu: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Yellow
Write-Host "🎉 Proces zakończony!" -ForegroundColor Green
Write-Host "`n📋 Podsumowanie:" -ForegroundColor Cyan
Write-Host "   - Przetworzono pliki: $($existingFiles -join ', ')" -ForegroundColor White
Write-Host "   - Utworzono kopie zapasowe (.backup)" -ForegroundColor White
Write-Host "   - Znormalizowano nazwy pól zgodnie z konwencjami projektu" -ForegroundColor White

Write-Host "`n💾 Kopie zapasowe:" -ForegroundColor Cyan
foreach ($file in $existingFiles) {
    $backupPath = "split_investment_data\$file.backup"
    if (Test-Path $backupPath) {
        $size = (Get-Item $backupPath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "   📁 $file.backup ($sizeKB KB)" -ForegroundColor White
    }
}

Write-Host "`n🔗 Następne kroki:" -ForegroundColor Cyan
Write-Host "   1. Sprawdź logi powyżej pod kątem ostrzeżeń" -ForegroundColor White
Write-Host "   2. Przetestuj import danych do Firebase" -ForegroundColor White
Write-Host "   3. W razie problemów przywróć z kopii .backup" -ForegroundColor White

Read-Host "`nNaciśnij Enter, aby zakończyć"

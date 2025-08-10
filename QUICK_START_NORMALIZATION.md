# 🚀 Szybki Start - Normalizacja JSON

## ⚡ Najszybsza opcja (1 komenda)

### Linux/macOS:
```bash
chmod +x run_normalization.sh && ./run_normalization.sh
```

### Windows (PowerShell):
```powershell
.\run_normalization.ps1
```

---

## 📋 Krok po kroku

### 1. Sprawdź strukturę plików (opcjonalnie)
```bash
python3 preview_json_structure.py
```

### 2. Uruchom normalizację
```bash
python3 normalize_json_fields.py
```

### 3. Sprawdź wyniki
```bash
python3 validate_json_normalization.py
```

---

## 🎯 Co się dzieje?

1. **Backup**: Tworzone są kopie `.backup` wszystkich plików
2. **Mapowanie**: Polskie nazwy → Angielskie nazwy
3. **Walidacja**: Sprawdzenie poprawności zmian

### Przykłady zmian:
```
"Kapital Pozostaly" → "remainingCapital"
"Kwota_inwestycji" → "investmentAmount" 
"imie_nazwisko" → "fullName"
"pozyczka_numer" → "loanNumber"
```

---

## 🔙 W razie problemów

### Przywróć wszystkie pliki:
```bash
python3 restore_backups.py
# Wybierz opcję 3
```

### Przywróć pojedynczy plik:
```bash
mv split_investment_data/clients.json.backup split_investment_data/clients.json
```

---

## ✅ Gotowe!

Twoje pliki JSON są teraz ujednolicone i gotowe do importu w Firebase! 🎉

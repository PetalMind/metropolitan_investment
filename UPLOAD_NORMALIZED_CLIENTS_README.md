# Upload Normalized Clients to Firebase

Skrypt do wdrażania znormalizowanych danych klientów z pliku `split_investment_data_normalized/clients_normalized.json` do Firebase Firestore.

## Wymagania

1. **Firebase Admin SDK**: Zainstalowany via npm
2. **Plik service-account.json**: W głównym katalogu projektu
3. **Plik danych**: `split_investment_data_normalized/clients_normalized.json`

## Struktura danych wejściowych

Skrypt oczekuje danych w formacie:
```json
[
  {
    "id": 1,
    "fullName": "Imię Nazwisko",
    "companyName": "",
    "phone": "123456789",
    "email": "email@example.com",
    "created_at": "2025-07-22T13:06:44.356678"
  }
]
```

## Użycie

### Podstawowe komendy

```bash
# Normalny upload (prawdziwy zapis do bazy)
node upload_normalized_clients.js

# Lub przez npm script
npm run upload-normalized-clients
```

### Tryby zaawansowane

```bash
# Symulacja (dry run) - bez zapisu do bazy, tylko walidacja
node upload_normalized_clients.js --dry-run
npm run upload-normalized-clients:dry-run

# Czyszczenie kolekcji przed uploadem
node upload_normalized_clients.js --cleanup

# Szczegółowy raport i statystyki
node upload_normalized_clients.js --report

# Pełny tryb: czyszczenie + upload + raport
node upload_normalized_clients.js --cleanup --report
npm run upload-normalized-clients:full
```

## Mapowanie danych

Skrypt mapuje pola z pliku znormalizowanego na prostą strukturę Firebase:

| Źródło (JSON) | Docelowe (Firestore) | Typ | Opis |
|---------------|---------------------|-----|------|
| `id` | `id` | number | Numeryczne ID klienta |
| `fullName` | `fullName` | string | Pełna nazwa klienta |
| `companyName` | `companyName` | string | Nazwa firmy |
| `phone` | `phone` | string | Numer telefonu |
| `email` | `email` | string | Adres email |
| `created_at` | `createdAt` | timestamp | Data utworzenia |
| - | `uploadedAt` | timestamp | Data uploadu |
| - | `dataVersion` | string | "2.0" |
| - | `migrationSource` | string | "normalized_json_import" |

### Obsługa spółek

Skrypt automatycznie obsługuje przypadek gdy `fullName` jest puste (dotyczy spółek):
- **Jeśli `fullName` jest puste lub zawiera tylko białe znaki**: Użyje `companyName` jako `fullName`
- **Przykład**: `fullName: " "` + `companyName: "ODDK Sp. z o.o. Sp.k."` → `fullName: "ODDK Sp. z o.o. Sp.k."`
- **Logowanie**: Pokaże komunikat `🏢 ID X: Używam companyName "..." jako fullName`

### Dodatkowe pola

Skrypt automatycznie dodaje metadane:
- **Document ID**: Używa oryginalnego `id` klienta jako string
- `dataVersion: "2.0"`: Wersja struktury danych
- `migrationSource: "normalized_json_import"`: Źródło importu
- `uploadedAt`: Timestamp uploadu do Firebase

## Bezpieczeństwo

- **DRY RUN**: Zawsze uruchom najpierw `--dry-run` aby sprawdzić dane
- **BACKUP**: Skrypt może wyczyścić kolekcję z `--cleanup`
- **WALIDACJA**: Sprawdza wymagane pola przed zapisem

## Przykład sesji

```bash
# 1. Sprawdź dane bez zapisu
npm run upload-normalized-clients:dry-run

# 2. Jeśli wszystko OK, wykonaj prawdziwy upload
npm run upload-normalized-clients:full
```

## Rozwiązywanie problemów

### Błąd: Brak pliku service-account.json
```
Skopiuj plik service-account.json do głównego katalogu projektu
```

### Błąd: Plik clients_normalized.json nie istnieje
```
Sprawdź czy plik istnieje w: split_investment_data_normalized/clients_normalized.json
```

### Błąd Firebase: Permission denied
```
Sprawdź uprawnienia w service-account.json (role: Firebase Admin)
```

## Logi i monitoring

Skrypt wyświetla szczegółowe logi:
- ✅ Pomyślne operacje  
- ❌ Błędy i problemy
- 📊 Statystyki i podsumowania
- 🔗 Mapowanie ID dla debugowania

## Integracja z projektem

Skrypt jest zintegrowany z systemem:
- **Package.json**: Scripts dla łatwego uruchomienia
- **Firebase Admin**: Używa tej samej konfiguracji co inne skrypty
- **Prosta struktura**: Minimalna struktura danych zgodna z wymaganiami
- **Document ID**: Używa oryginalnego ID klienta (przewidywalne identyfikatory)

## Przykład struktury w Firebase

```
clients/
  ├── "1"/
  │   ├── id: 1 (number)
  │   ├── fullName: "ABZ Media Artur Bogoryja-Zakrzewski" (string)
  │   ├── companyName: "" (string)
  │   ├── phone: "" (string)
  │   ├── email: "" (string)
  │   ├── dataVersion: "2.0" (string)
  │   ├── migrationSource: "normalized_json_import" (string)
  │   ├── createdAt: July 31, 2025 at 5:43:09 PM UTC+2 (timestamp)
  │   └── uploadedAt: August 10, 2025 at 2:15:21 PM UTC+2 (timestamp)
  ├── "10"/
  ├── "100"/
  └── ...
```

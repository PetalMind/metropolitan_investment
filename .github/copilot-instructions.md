# Metropolitan Investment - AI Assistant Guidelines

## Project Overview
Flutter-based investment management platform with Firebase backend, specialized in sophisticated analytics and server-side processing. Manages clients, investments (unified across product types), employees, and complex investor analytics through Firebase Functions architecture.

## Architecture & Key Components

### Frontend (Flutter)
- **State Management**: Dual system using `provider` (auth) + `flutter_riverpod` (data state)
- **Routing**: Go Router with shell layout architecture in `lib/config/app_routes.dart`
- **Theme**: Professional dark theme with gold accents - use `AppTheme` class constants
- **Models**: Central export from `lib/models_and_services.dart` - **ALWAYS import from here**

### Backend (Firebase)  
- **Region**: `europe-west1` for all Firebase Functions (closer to Poland)
- **Firestore**: Unified data architecture with optimized compound indexes
- **Functions**: Modular system with specialized analytics modules (Node.js 20)
- **Authentication**: Firebase Auth with custom `AuthProvider` and redirect logic

### Critical Service Pattern
All services extend `BaseService` with 5-minute TTL caching:
# Metropolitan Investment - AI Assistant Guidelines

## Project Overview
Flutter-based investment management platform with Firebase backend, specialized in sophisticated analytics and server-side processing. Manages clients, investments (unified across product types), employees, and complex investor analytics through Firebase Functions architecture.

## Architecture & Key Components

### Frontend (Flutter)
- **State Management**: Dual system using `provider` (auth) + `flutter_riverpod` (data state)
- **Routing**: Go Router with shell layout architecture in `lib/config/app_routes.dart`
- **Theme**: Professional dark theme with gold accents - use `AppTheme` class constants
- **Models**: Central export from `lib/models_and_services.dart` - **ALWAYS import from here**

### Backend (Firebase)  
- **Region**: `europe-west1` for all Firebase Functions (closer to Poland)
- **Firestore**: Unified data architecture with optimized compound indexes
- **Functions**: Modular system with specialized analytics modules (Node.js 20)
- **Authentication**: Firebase Auth with custom `AuthProvider` and redirect logic

### Critical Service Pattern
All services extend `BaseService` with 5-minute TTL caching:
```dart
// Standard pattern for all services
Future<T> getCachedData<T>(String cacheKey, Future<T> Function() query)
// Use FirebaseFirestore.instance directly
// Error handling: logError() in debug mode, return null for not found
```

### Unified Data Architecture (Critical)
**Single Source of Truth:** All product data stored in `investments` collection only

**Field mapping pattern (CRITICAL naming conventions):**
```dart
// Code uses ENGLISH property names, Firebase stores POLISH field names (legacy + normalized)
// Investment model handles both automatically in fromFirestore()
remainingCapital    // Code property <- maps from 'remainingCapital' | 'kapital_pozostaly' | 'Kapital Pozostaly'
investmentAmount    // Code property <- maps from 'investmentAmount' | 'kwota_inwestycji' | 'Kwota_inwestycji'
clientId            // Code property <- maps from 'clientId' | 'klient' | 'ID_Klient'
signedDate          // Code property <- maps from 'signingDate' | 'data_podpisania' | 'Data_podpisania'
productType         // Code property <- maps from 'productType' | 'typ_produktu' | 'Typ_produktu'
```

**Logical IDs System:** Uses semantic IDs like `bond_0001`, `loan_0005`, `apartment_0045` instead of UUIDs
**Legacy Collections:** `bonds`, `shares`, `loans`, `apartments`, `products` are deprecated and empty.

### Unified Data Architecture (Critical)
**Single Source of Truth:** All product data stored in `investments` collection only

**Field mapping pattern (CRITICAL naming conventions):**
```dart
// Code uses ENGLISH property names, Firebase stores POLISH field names (legacy + normalized)
// Investment model handles both automatically in fromFirestore()
remainingCapital    // Code property <- maps from 'remainingCapital' | 'kapital_pozostaly' | 'Kapital Pozostaly'
investmentAmount    // Code property <- maps from 'investmentAmount' | 'kwota_inwestycji' | 'Kwota_inwestycji'
clientId            // Code property <- maps from 'clientId' | 'klient' | 'ID_Klient'
signedDate          // Code property <- maps from 'signingDate' | 'data_podpisania' | 'Data_podpisania'
productType         // Code property <- maps from 'productType' | 'typ_produktu' | 'Typ_produktu'
```

**Legacy Collections:** `bonds`, `shares`, `loans`, `apartments`, `products` are deprecated and empty.

## Development Workflows

### Building & Running
```bash
flutter pub get
flutter run                    # Debug mode
flutter build web --release    # Production web build
flutter clean                  # Clean build artifacts
flutter analyze                # Static analysis
```

### Firebase Functions (Critical)
```bash
cd functions
npm install
firebase deploy --only functions  # Deploy to Europe-West1
npm run test                      # Run test_analytics.js
firebase functions:log            # View logs
firebase emulators:start --only functions  # Local testing
```

### Data Migration & Tools
Excel import and analysis tools in root directory:
```bash
# Data extraction from Excel
dart run tools/complete_client_extractor.dart
dart run tools/complete_investment_extractor.dart

# Firebase upload with normalized field mapping
node upload_clients_to_firebase.js
node upload_normalized_investments_to_firebase.js

# Field mapping utilities
node field-mapping-utils.js      # Test field mappings
```

### Database Management  
```bash
firebase deploy --only firestore:indexes    # Deploy compound indexes
firebase deploy --only functions           # Deploy to europe-west1
firebase deploy --only firestore:rules     # Deploy security rules
```

## Project-Specific Conventions

### Service Architecture
- **Base Pattern**: All services extend `BaseService` with caching
- **Naming**: `firebase_functions_*_service.dart` for server-side calls, `optimized_*_service.dart` for performance
- **Analytics Services**: Client-side filtering + server-side aggregation pattern
- **Field Mapping**: `field-mapping-utils.js` handles Polish⟷English field mapping uniformly

### Navigation Pattern
```dart
// Routes in AppRoutes class with typed generators
AppRoutes.clientDetailsPath(id)
// Shell layout wraps authenticated routes  
// Extension methods on BuildContext for type-safe navigation
context.goToClientDetails(id)
```

### Model Structure
- **Client**: Polish fields (`imie_nazwisko`, `nazwa_firmy`) with `votingStatus`
- **Investment**: Uses field mapping system for Polish⟷English translation
- **InvestorSummary**: Aggregates client + investments with `viableRemainingCapital`

### Analytics Architecture
**Critical pattern**: Client-side filtering + server-side aggregation
1. `PremiumInvestorAnalyticsScreen` → `firebase_functions_analytics_service.dart`
2. Server processes in `functions/index.js` with modular services (`functions/services/`)
3. Results cached: 5min server-side, 2min client-side

### UI Component Patterns
- **Widgets**: Central exports from `lib/models_and_services.dart`
- **Dialogs**: Located in `lib/widgets/dialogs/` with consistent theming
- **Theme**: `AppTheme` class provides dark theme with gold accents
- **Loading**: `shimmer` package with custom `PremiumLoadingWidget`

## Integration Points

### Firebase Functions Communication
```dart
// Always use europe-west1 region
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('getOptimizedInvestorAnalytics')
    .call(data);
```

### State Management Bridge
```dart
// Auth (Provider pattern)
context.read<AuthProvider>().signOut()
// Data state (Riverpod)  
ref.watch(clientsProvider)
```

### Cross-Platform Support
- Web: `responsive_framework` for breakpoints
- Mobile: Standard Material Design
- Charts: `fl_chart` + `syncfusion_flutter_charts`

## Performance Patterns

### Data Loading Strategy
- Use Firebase Functions for analytics (>1000 records)
- Pagination with `pageSize: 250` for large datasets  
- Map-based caching in services with TTL

### UI Optimization
- Lazy loading with `ListView.builder`
- `shimmer` package for loading states
- Cached network images for assets

## Testing & Debugging

### Test Structure
- Unit tests in `test/` directory using `flutter_test`
- Firebase Functions tests: `functions/test_*.js`
- Mock services available when Firebase unavailable

### Common Issues
- **Firestore indexes**: Check `firestore.indexes.json` for compound indexes
- **Memory**: Functions configured for 2GB memory allocation
- **Client ID mapping**: Complex system due to data migration - use `ClientIdMappingService`

## Key Dependencies
```yaml
# State Management
provider: ^6.1.2
flutter_riverpod: ^2.5.1
# Navigation  
go_router: ^16.1.0
# Firebase
firebase_core: ^4.0.0
cloud_firestore: ^6.0.0
cloud_functions: ^6.0.0
# Charts & Analytics
fl_chart: ^1.0.0
syncfusion_flutter_charts: ^30.2.4
# UI Enhancement
responsive_framework: ^1.5.1
shimmer: ^3.0.0
```

## Documentation Files
Key documentation in root directory:
- `CLAUDE.md` - Alternative AI assistant guidelines with comprehensive commands
- `FIRESTORE_INDEXES_OPTIMIZED.md` - Database performance patterns
- Various `*_GUIDE.md` and `*_README.md` files for specific features
# .github/copilot-instructions.md

Purpose: Short, actionable guidance so an AI coding agent can be productive quickly in this repo.

Quick summary
- Tech stack: Flutter (Dart) frontend + Firebase backend (Firestore, Auth, Cloud Functions). Cloud Functions live in `functions/` (Node.js). Data-migration & utilities live in root `tools/` and many JS helpers.
- Single source of truth: product data consolidated in `investments` collection (legacy collections like `bonds`, `shares`, `loans`, `apartments` are deprecated).

Where to start (files to open)
- `lib/models_and_services.dart` — central barrel export; import models/services from here.
- `lib/services/` — business logic, services extend `BaseService` (caching pattern).
- `lib/screens/` — UI screens; `lib/widgets/dialogs/` for modal patterns.
- `functions/` — cloud functions and server-side analytics; tests in `functions/test_*.js`.
- `firebase_options.dart`, `firestore.indexes.json`, `firebase.json` — important config for deploy and indexing.
- `CLAUDE.md` and `README.md` — longer existing AI guidance and workflows.

Project-specific conventions (must-follow)
- ALWAYS import models/services via `lib/models_and_services.dart` (do not import individual model files).
- Field-mapping: code uses English properties while Firestore contains Polish legacy field names. Use the model's fromFirestore()/toFirestore() helpers and `field-mapping-utils.js` when updating mapping logic.
- Logical IDs: product IDs are semantic (e.g. `bond_0001`, `loan_0005`, `apartment_0045`) — do not replace with UUIDs.
- Services pattern: most services extend `BaseService` and implement a caching TTL (5 minutes). Look for `DataCacheService` / `WebOptimizedCacheService` for web behavior.
- Firebase Functions region: use `europe-west1` for client calls: e.g. `FirebaseFunctions.instanceFor(region: 'europe-west1')`.
- Pagination & heavy queries: use server-side functions for >1000 records; client page size defaults to 250.

Common commands (quick)
- Flutter: `flutter pub get`, `flutter run`, `flutter build web --release`, `flutter analyze`.
- Functions: `cd functions && npm install`, `firebase emulators:start --only functions`, `firebase deploy --only functions`.
- Data tools: root JS scripts and `tools/` Dart scripts — examples in `CLAUDE.md`.

Patterns & examples you should follow when changing code
- Navigation: routes defined in `lib/config/app_routes.dart`; use typed route helpers (e.g. `AppRoutes.clientDetailsPath(id)`) or provided context extension methods.
- Auth & RBAC: `AuthProvider` (Provider) controls isAdmin and gating in UI; use `Consumer<AuthProvider>` checks in widgets when adding privileged UX.
- Analytics: heavy aggregation should be routed to cloud functions (`functions/`) and cached server-side (5m). Use `firebase_functions_analytics_service.dart` wrapper.
- Change history: use `InvestmentChangeHistoryService` for recording edits; only admins may perform destructive updates.

What NOT to change without checks
- Firestore field names or ID formats without updating `field-mapping-utils.js` and migration scripts.
- Cloud Functions region or function signatures without running the emulator and relevant function tests.
- Central barrel exports in `lib/models_and_services.dart` — many files depend on that import path.

Testing & verification
- Run unit/widget tests: `flutter test` (check `test/`), run function tests under `functions/` (`npm run test`).
- Use Firebase emulator for local function testing and logs: `firebase emulators:start` and `firebase functions:log`.

If you need more context
- Read `CLAUDE.md` for additional developer commands and background.
- Search for `ClientIdMappingService`, `BaseService`, and `investments` to understand ID & mapping logic quickly.

Feedback
- If anything here is unclear or missing, tell me which area (data mapping, functions, UI patterns, or deploy steps) you want expanded and I will iterate.

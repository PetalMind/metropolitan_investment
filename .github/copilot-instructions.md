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

**Legacy Collections:** `bonds`, `shares`, `loans`, `apartments`, `products` are deprecated and empty.

## Development Workflows

### Building & Running
```bash
flutter pub get
flutter run                    # Debug mode
flutter build web --release    # Production web build
```

### Firebase Functions (Critical)
```bash
cd functions
npm install
firebase deploy --only functions  # Deploy to Europe-West1
npm test                          # Run test_analytics.js
```

### Data Migration & Tools
Excel import and analysis tools in root directory:
```bash
dart run tools/complete_client_extractor.dart    # Extract clients from Excel
dart run tools/complete_investment_extractor.dart # Extract investments  
node upload_clients_to_firebase.js              # Upload to Firestore
```

### Database Management  
```bash
firebase deploy --only firestore:indexes    # Deploy compound indexes
firebase deploy --only functions           # Deploy to europe-west1
```

## Project-Specific Conventions

### Service Architecture
- **Base Pattern**: All services extend `BaseService` with caching
- **Naming**: `firebase_functions_*_service.dart` for server-side calls, `optimized_*_service.dart` for performance
- **Analytics Services**: Client-side filtering + server-side aggregation pattern

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
- **Investment**: Uses `kapital_pozostaly` → `remainingCapital` mapping
- **InvestorSummary**: Aggregates client + investments with `viableRemainingCapital`

### Analytics Architecture
**Critical pattern**: Client-side filtering + server-side aggregation
1. `PremiumInvestorAnalyticsScreen` → `firebase_functions_analytics_service.dart`
2. Server processes in `functions/index.js` with modular services
3. Results cached: 5min server-side, 2min client-side

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

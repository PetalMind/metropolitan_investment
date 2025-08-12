# Metropolitan Investment - AI Assistant Guidelines

## Project Overview
Flutter-based investment management platform with Firebase backend, specialized in sophisticated analytics and server-side processing. Manages clients, investments (unified across product types), employees, and complex investor analytics through Firebase Functions architecture.

## Architecture & Key Components

### Frontend (Flutter)
- **State Management**: Dual system using `provider` (auth) + `flutter_riverpod` (data state)
- **Routing**: Go Router with shell layout architecture in `lib/config/app_routes.dart`
- **Theme**: Professional dark theme (`AppThemePro.professionalTheme`) with gold accents
- **Models**: Central export from `lib/models_and_services.dart` - **ALWAYS import from here**

### Backend (Firebase)  
- **Region**: `europe-west1` for all Firebase Functions (closer to Poland)
- **Firestore**: Unified data architecture with optimized compound indexes
- **Functions**: Modular system with specialized analytics modules (2GB memory allocation)
- **Authentication**: Firebase Auth with custom `AuthProvider` and redirect logic

### Critical Service Pattern
All services extend `BaseService` with 5-minute TTL caching:
- Use `FirebaseFirestore.instance` directly
- Cache with `getCachedData<T>(cacheKey, query)` method  
- Error handling: `logError()` in debug mode, return `null` for not found

### Unified Data Architecture (Critical)
**Single Source of Truth:** All product data stored in `investments` collection only

**Core field mappings (CRITICAL naming conventions):**
```dart
// Database field -> Code property
'kapital_pozostaly' -> remainingCapital    // Main capital metric
'kwota_inwestycji' -> investmentAmount     // Original investment  
'productType' -> UnifiedProductType        // apartments|bonds|shares|loans
'klient' -> clientId                       // Client reference field
'data_podpisania' -> signedDate           // Contract date
```

**Legacy Collections:** `bonds`, `shares`, `loans`, `apartments`, `products` are deprecated and empty.

**Analytics Architecture:** Server-side processing through Firebase Functions
- Client-side services: `firebase_functions_*_service.dart`
- Server-side modules: `functions/services/`, `functions/analytics/`  
- Specialized functions: `dashboard-specialized.js`, `advanced-analytics.js`

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
node test_analytics.js           # Test analytics modules locally
```

### Data Migration & Tools
Excel import and analysis tools in `tools/` directory:
```bash
dart run tools/complete_client_extractor.dart    # Extract clients from Excel
dart run tools/complete_investment_extractor.dart # Extract investments  
dart run tools/diagnose_statistics.dart         # Statistics diagnostics
node upload_clients_to_firebase.js              # Upload to Firestore
```

### Database Management  
Critical indexes in `firestore.indexes.json`:
```bash
firebase deploy --only firestore:indexes    # Deploy required compound indexes
firebase deploy --only functions           # Deploy to europe-west1
```

## Project-Specific Conventions

## Project-Specific Conventions

### Model Structure
- **Client**: `imie_nazwisko`, `email`, `telefon`, `nazwa_firmy`, `votingStatus`
- **Investment**: Uses `kapital_pozostaly` field (stored) mapped to `remainingCapital` (code) - CRITICAL naming convention
- **InvestorSummary**: Aggregates client + investments with `viableRemainingCapital` (only executable investments)

### Service Naming
- Optimized services: `optimized_*_service.dart` for performance-critical operations
- Firebase Functions services: `firebase_functions_*_service.dart` for server-side calls
- Base services: Standard CRUD operations extending `BaseService`

### Navigation Pattern
- Routes defined in `AppRoutes` class with typed path generators
- Shell layout wraps authenticated routes in `MainLayout`
- Extension methods on `BuildContext` for type-safe navigation

### Analytics Architecture
Critical pattern: Client-side filtering + server-side aggregation
1. `PremiumInvestorAnalyticsScreen` calls `firebase_functions_analytics_service.dart`
2. Server processes in `functions/index.js` with memory optimization
3. Results cached for 5 minutes server-side, 2 minutes client-side

### Error Handling
- Services: Return `null` on not found, throw for system errors
- UI: Use `FutureBuilder` with error states
- Firebase Functions: Use `HttpsError` with proper error codes

## Integration Points

### Firebase Functions Communication
```dart
// Call server-side analytics
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('getOptimizedInvestorAnalytics')
    .call(data);
```

### State Management Bridge
Provider wraps Riverpod for auth state, Riverpod for data state:
```dart
// Auth (Provider)
context.read<AuthProvider>().signOut()

// Data (Riverpod)  
ref.watch(clientsProvider)
```

### Cross-Platform Considerations
- Web: Uses `responsive_framework` for breakpoints
- Mobile: Standard Flutter Material Design
- Assets: Structured in `assets/` with proper pubspec.yaml declarations

## Performance Patterns

### Data Loading
- Use Firebase Functions for analytics (>1000 records)
- Implement pagination with `pageSize: 250` for large datasets
- Cache results in services using simple Map-based cache

### UI Optimization
- Lazy loading with `ListView.builder` for large lists
- Use `shimmer` package for loading states
- `fl_chart` and `syncfusion_flutter_charts` for visualizations

## Testing & Debugging

### Test Structure
- Unit tests in `test/` directory
- Use `flutter_test` framework
- Test Firebase services with mocked Firestore

### Common Issues
- **Firestore indexes**: Check `firestore.indexes.json` for required composite indexes
- **CORS**: Documented in `CORS_DEVELOPMENT_GUIDE.md`
- **Memory**: Firebase Functions use 2GB memory for analytics operations

## Documentation Files
Key documentation files in root directory:
- `PREMIUM_ANALYTICS_FILTERING_GUIDE.md` - Filter system architecture
- `INVESTOR_ANALYTICS_README.md` - Analytics feature documentation
- `FIRESTORE_INDEXES_OPTIMIZED.md` - Database performance patterns
- `MAJORITY_COALITION_ANALYSIS.md` - Voting status analytics
- `CLAUDE.md` - Alternative AI assistant guidelines

# Metropolitan Investment - AI Assistant Guidelines

## Project Overview
This is a Flutter-based investment management platform with Firebase backend and advanced analytics. The system manages clients, investments (shares, bonds, loans), employees, and complex investor analytics with server-side processing.

## Architecture & Key Components

### Frontend (Flutter)
- **State Management**: Dual system using `provider` + `flutter_riverpod` (see `main.dart` lines 11-21)
- **Routing**: Go Router with shell layout architecture in `lib/config/app_routes.dart`
- **Theme**: Dark-first design system in `lib/theme/app_theme.dart`
- **Models**: Central export from `lib/models_and_services.dart` - always import from here

### Backend (Firebase)
- **Firestore**: Main database with optimized indexes (see `firestore.indexes.json`)
- **Functions**: Heavy analytics processing in `functions/index.js` (Europe-West1 region)
- **Analytics**: Server-side investor analytics with 5-minute caching
- **Authentication**: Firebase Auth with custom `AuthProvider`

### Critical Service Pattern
All services extend `BaseService` and follow this pattern:
- Use `FirebaseFirestore.instance` directly
- Implement error handling with try-catch
- Return `Future<List<T>>` or `Future<T?>`
- Cache frequently accessed data

## Development Workflows

### Building & Running
```bash
flutter pub get
flutter run                    # Debug mode
flutter build web --release    # Production web build
```

### Firebase Functions
```bash
cd functions
npm install
firebase deploy --only functions  # Deploy to Europe-West1
```

### Data Migration Tools
Use scripts in `tools/` directory for Excel imports:
```bash
dart run tools/complete_client_extractor.dart    # Extract clients from Excel
node upload_clients_to_firebase.js               # Upload to Firestore
```

## Project-Specific Conventions

### Model Structure
- **Client**: `imie_nazwisko`, `email`, `telefon`, `nazwa_firmy`
- **Investment**: Uses `kapital_pozostaly` field (NOT `remainingCapital`) for consistency
- **InvestorSummary**: Aggregates client + investments with `viableRemainingCapital`

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

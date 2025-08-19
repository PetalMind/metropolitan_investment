# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Flutter Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app in development mode  
- `flutter build web` - Build for web deployment
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (macOS only)
- `flutter test` - Run unit and widget tests
- `flutter analyze` - Run static analysis
- `flutter clean` - Clean build artifacts

### Firebase Cloud Functions
- `cd functions && npm install` - Install Cloud Functions dependencies
- `cd functions && firebase deploy --only functions` - Deploy functions to europe-west1
- `cd functions && firebase functions:log` - View function logs
- `cd functions && firebase emulators:start --only functions` - Local testing
- `cd functions && npm run test` - Run function tests (test_analytics.js)

### Data Management & Migration
- `npm run upload` - Upload JSON data to Firebase using upload.js
- `npm run upload-clients` - Upload clients data using upload_clients_to_firebase.js
- `npm run upload-normalized` - Upload normalized data with field mapping
- `npm run upload-investments` - Upload investment data to Firebase
- `npm run upload-normalized:dry-run` - Dry run upload without making changes
- `npm run upload-normalized:full` - Full upload with cleanup and reporting
- `dart run tools/complete_client_extractor.dart` - Extract clients from Excel
- `dart run tools/complete_investment_extractor.dart` - Extract investments from Excel
- `node field-mapping-utils.js` - Test field mapping system
- `npm run fix-missing-clients` - Fix missing client references
- `npm run validate-investments` - Validate investment data integrity

### Testing
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter test test/premium_analytics_filtering_test.dart` - Run analytics filtering tests
- `flutter test test/enhanced_voting_status_service_test.dart` - Run voting status tests

## Architecture Overview

### Project Structure
This is a Flutter investment management application called "Metropolitan Investment" with Firebase backend integration.

**Key Directories:**
- `lib/` - Main Flutter application code
- `lib/screens/` - UI screens (dashboard, analytics, clients, investments, etc.)
- `lib/services/` - Business logic and Firebase integration services
- `lib/models/` - Data models (Client, Investment, Product, Company, etc.)
- `lib/widgets/` - Reusable UI components
- `lib/providers/` - State management (Provider pattern)
- `functions/` - Firebase Cloud Functions
- `tools/` - Data migration and utility scripts

### Core Architecture Patterns

**State Management:**
- Uses Provider pattern for global state (AuthProvider, InvestorAnalyticsProvider)
- Riverpod for newer components
- Services follow repository pattern with caching

**Navigation:**
- GoRouter for declarative routing
- Shell routes with MainLayout for consistent navigation
- Route-based authentication with redirect logic

**Firebase Integration:**
- Firestore for data persistence with offline support
- Cloud Functions for server-side logic
- Firebase Auth for user authentication
- Region set to 'europe-west1'

**Data Models:**
- Client, Investment, Product, Company, Employee core entities
- InvestorSummary for analytics aggregation
- Models support both local and Firebase serialization

### Key Services Architecture

**Base Service Pattern:**
- `BaseService` provides common CRUD operations
- Individual services extend base functionality
- Caching layer via `DataCacheService` and `WebOptimizedCacheService`
- Services handle both online/offline scenarios

**Analytics Services:**
- `InvestorAnalyticsService` - Core analytics functionality
- `PremiumAnalyticsFilterService` - Advanced filtering
- `EnhancedInvestorAnalyticsService` - Extended analytics features
- `FirebaseFunctionsAnalyticsService` - Server-side analytics

**Optimization Services:**
- Services prefixed with 'optimized_' contain performance improvements
- Client voting status optimization for large datasets
- Cached data services for web performance

### Theme System
- `AppTheme` provides dark theme with gold accents
- Professional financial styling
- Responsive design using `responsive_framework`
- Material Design 3 components

### Data Migration Tools
The `tools/` directory contains various migration utilities:
- Excel to Firebase importers
- Data correlation and analysis tools
- Client/investment linking utilities
- Firebase migration simulators

### Firebase Configuration
- Main config in `firebase_options.dart` (auto-generated)
- Local config template in `lib/config/firebase_config_local.dart.example`
- Firestore rules defined in `lib/services/firebase_config.dart`
- Cloud Functions in `functions/index.js`

### Important Implementation Notes

**Unified Data Architecture (Critical):**
- All product data stored in single `investments` collection (bonds, loans, shares, apartments)
- Uses logical IDs: `bond_0001`, `loan_0005`, `apartment_0045` instead of UUIDs
- Field mapping system: English code properties ↔ Polish Firebase field names
- Legacy collections (`bonds`, `shares`, `loans`, `apartments`, `products`) are deprecated

**Field Mapping Pattern:**
```dart
// Code uses English properties, Firebase stores Polish fields
remainingCapital    // maps from 'remainingCapital' | 'kapital_pozostaly' | 'Kapital Pozostaly'
investmentAmount    // maps from 'investmentAmount' | 'kwota_inwestycji' | 'Kwota_inwestycji'
clientId            // maps from 'clientId' | 'klient' | 'ID_Klient'
signedDate          // maps from 'signingDate' | 'data_podpisania' | 'Data_podpisania'
```

**Client ID Mapping:**
- Complex client ID mapping system exists due to data migration
- Use `ClientIdMappingService` for client references
- Multiple backup services exist for investment and client handling

**State Management Dual System:**
- Provider pattern for authentication (`AuthProvider`)
- Riverpod for data state management
- All models export from `lib/models_and_services.dart` (ALWAYS import from here)

**Premium Analytics:**
- Advanced investor analytics with filtering and pagination
- Voting status analysis for investment decisions  
- Charts and visualization using Syncfusion and fl_chart
- Export capabilities to PDF and Excel

**Caching Strategy:**
- BaseService provides 5-minute TTL caching for all services
- Multi-level caching for performance
- Debug widgets available for cache inspection
- Web-optimized cache service for browser deployment

**Development vs Production:**
- Firebase initialization wrapped in try-catch for development
- Mock services available when Firebase unavailable
- Debug modes and cache inspection tools included

**Role-Based Access Control (RBAC):**
- `AuthProvider.isAdmin` determines admin access throughout the app
- RBAC constants defined in `lib/constants/rbac_constants.dart`
- UI components use `Consumer<AuthProvider>` to conditionally show admin features
- Critical operations (edit, delete) are restricted to admin users only

**Change History System:**
- `InvestmentChangeHistoryService` tracks all investment modifications
- `ProductChangeHistoryService` aggregates history for product-related changes
- History dialogs available for both investments and products
- All users can view history, but only admins can make changes

### Testing Strategy
- Widget tests in `test/` directory
- Premium analytics filtering has dedicated test coverage
- Mock data and services available for testing

### Deployment
- Web deployment ready with Firebase Hosting
- Mobile builds configured for Android/iOS
- Cloud Functions deployed to europe-west1 region

## Development Workflows

### Service Architecture Pattern
All services follow this pattern:
```dart
// Services extend BaseService with 5-minute TTL caching
class SomeService extends BaseService {
  Future<T> getCachedData<T>(String cacheKey, Future<T> Function() query);
  // Use FirebaseFirestore.instance directly
  // Error handling: logError() in debug mode, return null for not found
}
```

### Navigation Pattern
```dart
// Routes in AppRoutes class with typed generators
AppRoutes.clientDetailsPath(id)
// Shell layout wraps authenticated routes  
// Extension methods on BuildContext for type-safe navigation
context.goToClientDetails(id)
```

### Firebase Functions Communication
```dart
// Always use europe-west1 region
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('getOptimizedInvestorAnalytics')
    .call(data);
```

### Model Import Convention
```dart
// ALWAYS import models and services from central export
import '../models_and_services.dart';
// NEVER import individual files like:
// import '../models/client.dart'; // ❌ DON'T DO THIS
```

### Performance Optimization
- Use Firebase Functions for analytics with >1000 records
- Pagination with `pageSize: 250` for large datasets
- Map-based caching in services with TTL
- Lazy loading with `ListView.builder`
- `shimmer` package for loading states

### UI Component Patterns
```dart
// Dialog pattern for product/client details
showDialog(
  context: context,
  builder: (context) => EnhancedProductDetailsDialog(
    product: product,
    onShowInvestors: () => _showInvestors(product),
  ),
);

// RBAC-aware UI components
Consumer<AuthProvider>(
  builder: (context, auth, child) {
    final canEdit = auth.isAdmin;
    return IconButton(
      onPressed: canEdit ? _handleEdit : null,
      icon: Icon(Icons.edit, color: canEdit ? Colors.white : Colors.grey),
      tooltip: canEdit ? 'Edit' : 'Insufficient permissions',
    );
  },
);
```

### Widget Architecture
- Dialogs in `lib/widgets/dialogs/` follow consistent patterns
- Premium widgets (loading, error) provide consistent UX
- History dialogs support both tabbed views and detailed statistics
- All modals use responsive design with `MediaQuery` constraints

## Key Dependencies & Versions
```yaml
# Core Framework
flutter: sdk: flutter
dart: ^3.8.1

# State Management
provider: ^6.1.2
flutter_riverpod: ^2.5.1

# Navigation  
go_router: ^16.1.0

# Firebase
firebase_core: ^4.0.0
cloud_firestore: ^6.0.0
cloud_functions: ^6.0.0
firebase_auth: ^6.0.0

# Charts & Analytics
fl_chart: ^1.0.0
syncfusion_flutter_charts: ^30.2.4

# UI Enhancement
responsive_framework: ^1.5.1
shimmer: ^3.0.0
material_design_icons_flutter: ^7.0.7296
```
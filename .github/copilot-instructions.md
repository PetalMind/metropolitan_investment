# Metropolitan Investment - AI Assistant Guidelines

## Project Overview
Flutter-based investment management platform with Firebase backend, specialized in sophisticated analytics and server-side processing. Manages clients, investments (unified across product types), employees, and complex investor analytics through Firebase Functions architecture.

## Architecture & Key Components

### Frontend (Flutter)
- **State Management**: Dual system using `provider` (auth) + `flutter_riverpod` (data state)
- **Routing**: Go Router with shell layout architecture in `lib/config/app_routes.dart`
- **Theme**: Professional dark theme with gold accents - use `AppTheme` class constants
- **Models**: Central export from `lib/models_and_services.dart` - **ALWAYS import from here**
- **Rich Text**: Advanced email editor with HTML support (`WowEmailEditorScreen`)

### Backend (Firebase)
- **Region**: `europe-west1` for all Firebase Functions (closer to Poland)
- **Firestore**: Unified data architecture with optimized compound indexes
- **Functions**: Modular system with specialized analytics modules (Node.js 20)
- **Authentication**: Firebase Auth with custom `AuthProvider` and redirect logic
- **Email System**: Nodemailer integration with SMTP configuration and scheduling

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
```

**Logical Product IDs:**
```dart
// Use semantic IDs instead of UUIDs
bond_0001, loan_0005, share_0123, apartment_0045
// NEVER use UUIDs - maintain consistency with existing ID format
```

## Where to Look First

### Central Files
- `lib/models_and_services.dart` — **CRITICAL**: Central barrel export for all models/services
- `lib/config/app_routes.dart` — Navigation and routing architecture
- `lib/services/base_service.dart` — Service foundation pattern
- `lib/theme/app_theme.dart` — Professional theme system

### Key Directories
- `lib/services/` — Business logic with BaseService pattern
- `lib/widgets/` — Reusable UI components and dialogs
- `lib/screens/` — Main application screens
- `functions/` — Firebase Cloud Functions (modular analytics)
- Root directory — Data migration and utility scripts

## Critical Conventions (Follow Exactly)

### Import Pattern (Strictly Enforced)
```dart
// ✅ CORRECT - Always import from central barrel export
import '../models_and_services.dart';

// ❌ INCORRECT - Never import individual model files
import '../models/client.dart';
import '../services/client_service.dart';
```

### Firebase Functions Communication
```dart
// Always use europe-west1 region (critical for performance)
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('functionName')
    .call(data);
```

### Service Architecture Pattern
```dart
// All services extend BaseService with 5-minute TTL caching
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

### RBAC-Aware UI Components
```dart
// Role-based access control with Consumer<AuthProvider>
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

## Developer Workflows

### Flutter Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run development app
- `flutter build web --release` - Build for web deployment
- `flutter build apk` - Build Android APK
- `flutter analyze` - Run static analysis

### Firebase Functions
- `cd functions && npm install` - Install function dependencies
- `cd functions && firebase deploy --only functions` - Deploy to europe-west1
- `cd functions && firebase emulators:start --only functions` - Local testing
- `cd functions && npm run test` - Run function tests

### Data Management & Migration
- `npm run upload-normalized:full` - Upload normalized data with cleanup
- `npm run validate-investments` - Validate investment data integrity
- `npm run fix-missing-clients` - Fix missing client references
- `dart run tools/complete_client_extractor.dart` - Extract clients from Excel

## Project-Specific Patterns & Examples

### UI Component Patterns
```dart
// Advanced email editor integration with HTML support
showDialog(
  context: context,
  builder: (context) => WowEmailEditorScreen(
    selectedInvestors: selectedInvestors,
    initialSubject: 'Investment Update',
    initialMessage: '<p>Professional HTML content...</p>',
  ),
);

// Animated, responsive dialog pattern
showDialog(
  context: context,
  builder: (context) => EnhancedProductDetailsDialog(
    product: product,
    onShowInvestors: () => _showInvestors(product),
  ),
);

// Professional loading states with shimmer
PremiumShimmerLoadingWidget(
  isLoading: isLoading,
  child: DataTableWidget(data: data),
);
```

### Analytics Implementation
```dart
// Server-side analytics for large datasets
final analytics = await FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('getOptimizedInvestorAnalytics')
    .call({'productId': productId, 'pageSize': 250});

// Client-side caching with TTL
final cachedData = await service.getCachedData(
  'analytics_$productId',
  () => fetchAnalytics(productId),
);
```

### Data Migration Scripts
```javascript
// Field mapping utility for Polish/English translation
const fieldMappingUtils = require('./field-mapping-utils');
// Use for all Firebase data operations
const normalizedData = fieldMappingUtils.normalizeFields(rawData);
```

## Quick Checks Before Edits

### Data Integrity
- Do not change Firestore field names without migration scripts
- Maintain logical ID format (bond_0001, loan_0005, etc.)
- Test field mapping with `field-mapping-utils.js`
- Run `firebase emulators:start` before deploying functions

### Code Quality
- Always import from `lib/models_and_services.dart`
- Use BaseService pattern for new services
- Follow RBAC patterns for admin-restricted features
- Test with both admin and user roles

### Performance
- Use Firebase Functions for datasets >1000 records
- Implement pagination with `pageSize: 250`
- Leverage 5-minute TTL caching in services
- Use `ListView.builder` for large lists

## Key Dependencies & Versions

### Core Framework
- Flutter: ^3.8.1
- Dart: ^3.8.1

### State Management
- Provider: ^6.1.2
- Riverpod: ^2.5.1

### Firebase
- Firebase Core: ^4.0.0
- Cloud Firestore: ^6.0.0
- Cloud Functions: ^6.0.0

### UI Enhancement
- Responsive Framework: ^1.5.1
- Shimmer: ^3.0.0
- Syncfusion Charts: ^30.2.4
- Flutter HTML: ^3.0.0 (for rich text editor)

### Email System
- Flutter Quill: ^11.4.2 (rich text editor)
- HTML Editor Enhanced: ^2.7.1 (HTML editing)
- Nodemailer: ^6.9.0 (backend email service)

## Development Environment Setup

1. **Flutter Setup**: `flutter pub get`
2. **Firebase Config**: Copy `firebase_config_local.dart.example` to `firebase_config_local.dart`
3. **Functions Setup**: `cd functions && npm install`
4. **Local Testing**: `firebase emulators:start --only functions`

## Common Pitfalls to Avoid

- **Import Errors**: Never import individual model files
- **Region Issues**: Always specify `europe-west1` for Firebase Functions
- **ID Conflicts**: Use logical IDs, never UUIDs
- **Cache Issues**: Clear cache when modifying data operations
- **RBAC Bypass**: Always check `auth.isAdmin` for restricted features

## Need More Context?

- Read `CLAUDE.md` for extended developer commands
- Check `functions/field-mapping-utils.js` for data transformation logic
- Review `lib/services/base_service.dart` for service architecture
- Examine `lib/widgets/enhanced_clients_header.dart` for UI patterns

---

*This document is maintained for AI coding assistants. Last updated: September 2025*

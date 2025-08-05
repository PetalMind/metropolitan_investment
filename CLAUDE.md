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

### Firebase/Node.js Scripts
- `npm run upload` - Upload JSON data to Firebase using upload.js
- `npm run upload-clients` - Upload clients data using upload_clients_to_firebase.js
- `npm install firebase-admin` - Install Firebase dependencies

### Testing
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter test test/premium_analytics_filtering_test.dart` - Run analytics filtering tests

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

**Client ID Mapping:**
- Complex client ID mapping system exists due to data migration
- Use `ClientIdMappingService` for client references
- Multiple backup services exist for investment and client handling

**Premium Analytics:**
- Advanced investor analytics with filtering and pagination
- Voting status analysis for investment decisions  
- Charts and visualization using Syncfusion and fl_chart
- Export capabilities to PDF and Excel

**Caching Strategy:**
- Multi-level caching for performance
- Debug widgets available for cache inspection
- Web-optimized cache service for browser deployment

**Development vs Production:**
- Firebase initialization wrapped in try-catch for development
- Mock services available when Firebase unavailable
- Debug modes and cache inspection tools included

### Testing Strategy
- Widget tests in `test/` directory
- Premium analytics filtering has dedicated test coverage
- Mock data and services available for testing

### Deployment
- Web deployment ready with Firebase Hosting
- Mobile builds configured for Android/iOS
- Cloud Functions deployed to europe-west1 region
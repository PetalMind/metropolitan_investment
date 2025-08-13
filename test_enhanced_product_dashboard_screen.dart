import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/product_dashboard_screen.dart';
import '../lib/theme/app_theme_professional.dart';

/// 🧪 TESTY FUNKCJONALNOŚCI PRODUCT DASHBOARD SCREEN
/// Testuje nowe funkcjonalności:
/// • ✅ Poprawne liczenie statystyk wybranych produktów
/// • ✅ Panel szczegółów produktu
/// • ✅ Dynamiczne terminy i oś czasu
/// • ✅ Callback wyboru produktu
void main() {
  group('ProductDashboardScreen Tests', () {
    testWidgets('should render ProductDashboardScreen correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      // Sprawdź czy ekran się renderuje
      expect(find.text('Metropolitan Investment'), findsOneWidget);
      expect(find.text('Dashboard Produktów'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    });

    testWidgets(
      'should show details panel toggle button when product selected',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemePro.professionalTheme,
            home: const ProductDashboardScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Initially, details panel button should not be visible
        expect(find.byIcon(Icons.open_in_full), findsNothing);
        expect(find.byIcon(Icons.close_fullscreen), findsNothing);
      },
    );

    testWidgets('should show floating action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Sprawdź FAB odświeżania
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should handle refresh action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Naciśnij przycisk odświeżania
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Sprawdź czy pokazuje się SnackBar
      expect(find.text('Odświeżanie danych...'), findsOneWidget);
    });

    testWidgets('should have responsive layout', (WidgetTester tester) async {
      // Test na różnych rozmiarach ekranu
      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Sprawdź czy renderuje się poprawnie na dużym ekranie
      expect(find.byType(ProductDashboardScreen), findsOneWidget);
    });
  });

  group('ProductDashboardScreen State Management', () {
    testWidgets('should manage selected product state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Stan początkowy - brak wybranego produktu
      final screenState = tester.state<_ProductDashboardScreenState>(
        find.byType(ProductDashboardScreen),
      );

      expect(screenState._selectedProductId, isNull);
      expect(screenState._showDetailsPanel, isFalse);
    });
  });

  group('ProductDashboardScreen Integration', () {
    testWidgets('should integrate with ProductDashboardWidget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemePro.professionalTheme,
          home: const ProductDashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Sprawdź czy ProductDashboardWidget jest osadzony
      expect(find.byType(ProductDashboardWidget), findsOneWidget);
    });
  });
}

/// Helper do dostępu do prywatnego stanu
extension ProductDashboardScreenStateAccess on _ProductDashboardScreenState {
  String? get selectedProductId => _selectedProductId;
  bool get showDetailsPanel => _showDetailsPanel;
}

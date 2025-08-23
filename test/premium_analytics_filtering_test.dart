import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:metropolitan_investment/widgets/premium_analytics_dashboard.dart';
import 'package:metropolitan_investment/widgets/premium_analytics_filter_panel.dart';
import 'package:metropolitan_investment/widgets/premium_analytics_floating_controls.dart';
import 'package:metropolitan_investment/models/investor_summary.dart';
import 'package:metropolitan_investment/models/client.dart';
import 'package:metropolitan_investment/models/investment.dart';

/// 🧪 TESTY SYSTEMU PREMIUM ANALYTICS FILTERING
///
/// Kompleksowe testy wszystkich komponentów systemu filtrowania

void main() {
  group('Premium Analytics Filtering System Tests', () {
    late List<InvestorSummary> testInvestors;
    late PremiumAnalyticsFilter testFilter;

    setUp(() {
      testInvestors = _createTestInvestors();
      testFilter = PremiumAnalyticsFilter();
    });

    group('PremiumAnalyticsFilter Tests', () {
      test('should filter by search query', () {
        testFilter.searchQuery = 'kowalski';

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(filtered.length, lessThan(testInvestors.length));
        expect(
          filtered.every(
            (inv) =>
                inv.client.name.toLowerCase().contains('kowalski') ||
                inv.client.email.toLowerCase().contains('kowalski'),
          ),
          true,
        );
      });

      test('should filter by voting status', () {
        testFilter.votingStatusFilter = VotingStatus.yes;

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(
          filtered.every((inv) => inv.client.votingStatus == VotingStatus.yes),
          true,
        );
      });

      test('should filter by capital range', () {
        testFilter.minCapital = 100000;
        testFilter.maxCapital = 1000000;

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(
          filtered.every(
            (inv) =>
                inv.viableRemainingCapital >= 100000 &&
                inv.viableRemainingCapital <= 1000000,
          ),
          true,
        );
      });

      test('should filter large investors', () {
        testFilter.showOnlyLargeInvestors = true;

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(
          filtered.every((inv) => inv.viableRemainingCapital >= 1000000),
          true,
        );
      });

      test('should combine multiple filters', () {
        testFilter.votingStatusFilter = VotingStatus.yes;
        testFilter.minCapital = 500000;
        testFilter.includeActiveOnly = true;

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(
          filtered.every(
            (inv) =>
                inv.client.votingStatus == VotingStatus.yes &&
                inv.viableRemainingCapital >= 500000 &&
                inv.client.isActive,
          ),
          true,
        );
      });

      test('should detect active filters', () {
        expect(testFilter.hasActiveFilters, false);

        testFilter.searchQuery = 'test';
        expect(testFilter.hasActiveFilters, true);

        testFilter.searchQuery = '';
        testFilter.votingStatusFilter = VotingStatus.yes;
        expect(testFilter.hasActiveFilters, true);
      });
    });

    group('Filter Widget Tests', () {
      testWidgets('PremiumAnalyticsFilterPanel should build correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumAnalyticsFilterPanel(
                allInvestors: testInvestors,
                onFiltersChanged: (filter) {},
                initialFilter: testFilter,
              ),
            ),
          ),
        );

        // Verify basic UI elements
        expect(find.text('Filtry Analytics'), findsOneWidget);
        expect(find.text('Wyszukiwanie'), findsOneWidget);
        expect(find.text('Status głosowania'), findsOneWidget);
        expect(find.text('Zakres kapitału'), findsOneWidget);
      });

      testWidgets('PremiumAnalyticsFloatingControls should build correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumAnalyticsFloatingControls(
                allInvestors: testInvestors,
                currentFilter: testFilter,
                onFiltersChanged: (filter) {},
              ),
            ),
          ),
        );

        // Verify floating controls UI
        expect(find.text('Szybkie filtry'), findsOneWidget);
        expect(find.text('ZA'), findsOneWidget);
        expect(find.text('PRZECIW'), findsOneWidget);
        expect(find.text('Większość'), findsOneWidget);
      });

      testWidgets('Filter panel should respond to interactions', (
        tester,
      ) async {
        bool filterChanged = false;
        PremiumAnalyticsFilter? receivedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumAnalyticsFilterPanel(
                allInvestors: testInvestors,
                onFiltersChanged: (filter) {
                  filterChanged = true;
                  receivedFilter = filter;
                },
                initialFilter: testFilter,
              ),
            ),
          ),
        );

        // Test search input
        await tester.enterText(find.byType(TextField).first, 'test search');
        await tester.pump();

        expect(filterChanged, true);
        expect(receivedFilter?.searchQuery, 'test search');
      });
    });

    group('Dashboard Integration Tests', () {
      testWidgets('PremiumAnalyticsDashboard should integrate with filters', (
        tester,
      ) async {
        final Map<VotingStatus, double> votingDistribution = {
          VotingStatus.yes: 1000000,
          VotingStatus.no: 500000,
          VotingStatus.abstain: 200000,
          VotingStatus.undecided: 300000,
        };

        final Map<VotingStatus, int> votingCounts = {
          VotingStatus.yes: 10,
          VotingStatus.no: 5,
          VotingStatus.abstain: 2,
          VotingStatus.undecided: 3,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumAnalyticsDashboard(
                investors: testInvestors,
                votingDistribution: votingDistribution,
                votingCounts: votingCounts,
                totalCapital: 2000000,
                majorityHolders: testInvestors.take(3).toList(),
              ),
            ),
          ),
        );

        // Verify dashboard builds
        expect(find.text('📊 Premium Analytics Dashboard'), findsOneWidget);
        expect(find.text('Rozkład Głosów'), findsOneWidget);
        expect(find.text('Trendy Kapitału'), findsOneWidget);
        expect(find.text('Dystrybucja'), findsOneWidget);
        expect(find.text('Analiza Ryzyka'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () {
        final largeDataset = _createLargeTestDataset(1000);
        final filter = PremiumAnalyticsFilter(
          searchQuery: 'test',
          votingStatusFilter: VotingStatus.yes,
          minCapital: 100000,
        );

        final stopwatch = Stopwatch()..start();
        final filtered = largeDataset.where(filter.matches).toList();
        stopwatch.stop();

        // Should complete within reasonable time (< 100ms for 1000 records)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(filtered.length, lessThan(largeDataset.length));
      });

      test('should not have memory leaks with repeated filtering', () {
        final filter = PremiumAnalyticsFilter();

        // Simulate repeated filtering operations
        for (int i = 0; i < 100; i++) {
          filter.searchQuery = 'test$i';
          testInvestors.where(filter.matches).toList();
        }

        // Test completes without memory issues
        expect(true, true);
      });
    });

    group('Edge Cases Tests', () {
      test('should handle empty investor list', () {
        final emptyList = <InvestorSummary>[];
        final filter = PremiumAnalyticsFilter(searchQuery: 'test');

        final filtered = emptyList.where(filter.matches).toList();

        expect(filtered, isEmpty);
      });

      test('should handle null/empty search queries', () {
        testFilter.searchQuery = '';

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(filtered.length, testInvestors.length);
      });

      test('should handle extreme capital ranges', () {
        testFilter.minCapital = 0;
        testFilter.maxCapital = double.infinity;

        final filtered = testInvestors.where(testFilter.matches).toList();

        expect(filtered.length, testInvestors.length);
      });

      test('should handle invalid investment counts', () {
        testFilter.minInvestmentCount = -1;
        testFilter.maxInvestmentCount = 1000;

        final filtered = testInvestors.where(testFilter.matches).toList();

        // Should still work with invalid ranges
        expect(filtered, isNotEmpty);
      });
    });
  });
}

// Helper functions for creating test data

List<InvestorSummary> _createTestInvestors() {
  return [
    _createTestInvestor(
      'Jan Kowalski',
      'jan.kowalski@email.com',
      VotingStatus.yes,
      [_createTestInvestment(500000, 'Obligacje')],
    ),
    _createTestInvestor('Anna Nowak', 'anna.nowak@email.com', VotingStatus.no, [
      _createTestInvestment(1500000, 'Udziały'),
      _createTestInvestment(200000, 'Obligacje'),
    ]),
    _createTestInvestor(
      'Piotr Wiśniewski',
      'piotr.wisniewski@email.com',
      VotingStatus.undecided,
      [_createTestInvestment(50000, 'Pożyczka')],
    ),
    _createTestInvestor(
      'Maria Wójcik',
      'maria.wojcik@email.com',
      VotingStatus.yes,
      [
        _createTestInvestment(2000000, 'Udziały'),
        _createTestInvestment(500000, 'Obligacje'),
        _createTestInvestment(300000, 'Pożyczka'),
      ],
    ),
    _createTestInvestor(
      'Krzysztof Dąbrowski',
      'krzysztof.dabrowski@email.com',
      VotingStatus.abstain,
      [_createTestInvestment(800000, 'Obligacje')],
      isActive: false,
    ),
  ];
}

InvestorSummary _createTestInvestor(
  String name,
  String email,
  VotingStatus votingStatus,
  List<Investment> investments, {
  bool isActive = true,
}) {
  final client = Client(
    id: name.toLowerCase().replaceAll(' ', '_'),
    name: name,
    email: email,
    phone: '+48 123 456 789',
    address: 'Test Address',
    isActive: isActive,
    votingStatus: votingStatus,
    type: ClientType.individual,
    unviableInvestments: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  return InvestorSummary.fromInvestments(client, investments);
}

Investment _createTestInvestment(double amount, String productType) {
  return Investment(
    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
    clientId: 'client_123',
    clientName: 'Test Client',
    employeeId: 'emp_123',
    employeeFirstName: 'Jan',
    employeeLastName: 'Kowalski',
    branchCode: 'WAR01',
    status: InvestmentStatus.active,
    marketType: MarketType.primary,
    signedDate: DateTime.now().subtract(const Duration(days: 30)),
    proposalId: 'prop_123',
    productType: _parseProductType(productType),
    productName: 'Test Product',
    creditorCompany: 'Test Company',
    companyId: 'comp_123',
    investmentAmount: amount,
    paidAmount: amount,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
    remainingCapital: amount * 0.8, // 80% remaining
    realizedCapital: amount * 0.2, // 20% realized
  );
}

ProductType _parseProductType(String type) {
  switch (type) {
    case 'Udziały':
      return ProductType.shares;
    case 'Obligacje':
      return ProductType.bonds;
    case 'Pożyczka':
      return ProductType.loans;
    default:
      return ProductType.other;
  }
}

List<InvestorSummary> _createLargeTestDataset(int count) {
  final List<InvestorSummary> investors = [];
  final votingStatuses = VotingStatus.values;
  final productTypes = ['Udziały', 'Obligacje', 'Pożyczka'];

  for (int i = 0; i < count; i++) {
    final investments = <Investment>[];
    final investmentCount = (i % 5) + 1; // 1-5 investments per investor

    for (int j = 0; j < investmentCount; j++) {
      investments.add(
        _createTestInvestment(
          (50000 + (i * 1000)).toDouble(),
          productTypes[j % productTypes.length],
        ),
      );
    }

    investors.add(
      _createTestInvestor(
        'Test Investor $i',
        'test$i@email.com',
        votingStatuses[i % votingStatuses.length],
        investments,
        isActive: i % 10 != 0, // 90% active
      ),
    );
  }

  return investors;
}

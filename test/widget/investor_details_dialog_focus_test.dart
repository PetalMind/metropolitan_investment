import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:metropolitan_investment/models_and_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metropolitan_investment/widgets/investor_analytics/dialogs/investor_details_dialog.dart';

void main() {
  testWidgets('InvestorDetailsDialog - Tab traversal reaches all major controls in order', (WidgetTester tester) async {
    // Build minimal Client
    final client = Client(
      id: 'client-1',
      excelId: null,
      name: 'Test Client',
      email: '',
      phone: '',
      address: '',
      pesel: null,
      companyName: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Build a couple of minimal investments
    final investments = List<Investment>.generate(
      2,
      (i) => Investment(
        id: 'inv-$i',
        clientId: client.id,
        clientName: client.name,
        employeeId: '',
        employeeFirstName: '',
        employeeLastName: '',
        branchCode: '',
        status: InvestmentStatus.active,
        marketType: MarketType.primary,
        signedDate: DateTime.now(),
        proposalId: 'p$i',
        productType: ProductType.bonds,
        productName: 'Product $i',
        creditorCompany: 'Company',
        companyId: 'company-1',
        investmentAmount: 1000.0 + i,
        paidAmount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final summary = InvestorSummary.withoutCalculations(client, investments);

    // Initialize Firebase (some services used by the dialog expect a Firebase app)
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Pump the dialog inside a MaterialApp so focus and theme work
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: InvestorDetailsDialog(
              investor: summary,
              analyticsService: InvestorAnalyticsService(),
              onUpdate: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Send a series of Tab events and record focused nodes' debug labels when available
    final observed = <String>[];
    String? lastObserved;

    for (var i = 0; i < 40; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      final primary = FocusManager.instance.primaryFocus;
      final label = primary?.debugLabel;

      if (label != null && label != lastObserved) {
        observed.add(label);
        lastObserved = label;
      }
    }

    // We expect these debug labels to appear and to be in the correct order
    final expectedOrder = [
      'dedupeSwitch',
      'editButton',
      'closeButton',
      'votingSelector',
      'notesField',
      'cancelButton',
      'saveButton',
    ];

    for (final label in expectedOrder) {
      expect(observed.contains(label), isTrue, reason: 'Expected to observe focus on $label. Observed: $observed');
    }

    // Check ordering
    final indices = expectedOrder.map((l) => observed.indexOf(l)).toList();
    for (var i = 0; i < indices.length - 1; i++) {
      expect(indices[i] < indices[i + 1], isTrue,
          reason: 'Expected ${expectedOrder[i]} to appear before ${expectedOrder[i + 1]}. Observed indices: $indices');
    }
  });
}

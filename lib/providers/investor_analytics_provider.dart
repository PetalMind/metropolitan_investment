import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/investor_analytics/investor_analytics_state_service.dart';

/// Provider wrapper dla InvestorAnalyticsStateService
class InvestorAnalyticsProvider extends StatelessWidget {
  final Widget child;

  const InvestorAnalyticsProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvestorAnalyticsStateService(),
      child: child,
    );
  }
}

/// MultiProvider wrapper dla wszystkich providerów analityki inwestorów
class InvestorAnalyticsMultiProvider extends StatelessWidget {
  final Widget child;

  const InvestorAnalyticsMultiProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => InvestorAnalyticsStateService(),
        ),
        // Dodaj inne providery tutaj gdy będą potrzebne
      ],
      child: child,
    );
  }
}

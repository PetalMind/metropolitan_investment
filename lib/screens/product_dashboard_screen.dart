import 'package:flutter/material.dart';
import '../widgets/dashboard/product_dashboard_widget.dart';
import '../theme/app_theme_professional.dart';

/// 🚀 SCREEN DEMONSTRACYJNY NOWEGO DASHBOARD PRODUKTÓW
/// Nowoczesny ekran pokazujący funkcjonalność ProductDashboardWidget
class ProductDashboardScreen extends StatelessWidget {
  const ProductDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemePro.professionalTheme,
      child: Scaffold(
        backgroundColor: AppThemePro.backgroundPrimary,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: AppThemePro.accentGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metropolitan Investment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppThemePro.textPrimary,
                    ),
                  ),
                  Text(
                    'Dashboard Produktów',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppThemePro.accentGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: AppThemePro.backgroundPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [],
        ),
        body: const ProductDashboardWidget(),
        // Optional floating action button for quick actions
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Quick action - could be to add new product or refresh data
            // For now, we'll just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Odświeżanie danych...'),
                backgroundColor: AppThemePro.accentGold,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          backgroundColor: AppThemePro.accentGold,
          foregroundColor: AppThemePro.primaryDark,
          icon: const Icon(Icons.refresh),
          label: const Text(
            'Odśwież',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/dashboard/product_dashboard_widget.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../theme/app_theme_professional.dart';
import '../providers/auth_provider.dart';
import '../models_and_services.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🚀 SCREEN DEMONSTRACYJNY NOWEGO DASHBOARD PRODUKTÓW
/// Nowoczesny ekran pokazujący funkcjonalność ProductDashboardWidget
///
/// ✨ NOWE FUNKCJONALNOŚCI:
/// • 🔍 Szczegóły wybranego produktu/inwestycji
/// • 📅 Dynamiczne terminy i oś czasu
/// • 💰 Poprawione obliczenia statystyk wybranych produktów
/// • 🎯 Integracja z zunifikowanymi serwisami
class ProductDashboardScreen extends StatefulWidget {
  const ProductDashboardScreen({super.key});

  @override
  State<ProductDashboardScreen> createState() => _ProductDashboardScreenState();
}

class _ProductDashboardScreenState extends State<ProductDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  /// Initialize dashboard
  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoading = false;
    });

    // Note: Startup sound is played by ProductDashboardWidget via DashboardAudioService
    // when data loads successfully. No need to duplicate it here.
    if (kDebugMode) {
      debugPrint('🏠 Dashboard screen initialized - audio handled by widget');
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemePro.professionalTheme,
      child: Scaffold(
        backgroundColor: AppThemePro.backgroundPrimary,
        appBar: _buildAppBar(context),
        body: _isLoading
            ? const Center(
                child: MetropolitanLoadingWidget.products(),
              )
            : const ProductDashboardWidget(),
      ),
    );
  }

  @override
  void dispose() {
    // Removed unused avatar animation disposal
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
      actions: [
   
      ],
    );
  }



}

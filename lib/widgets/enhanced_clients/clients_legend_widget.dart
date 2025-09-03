import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';
import '../../models_and_services.dart';

/// 🎯 ELEGANCKA LEGENDA EKRANU KLIENTÓW
///
/// Wyjaśnia znaczenie:
/// - Złotych wyróżnień (TOP 50 inwestorów)
/// - Kwot wyświetlanych na kartach klientów
/// - Kolorów statusów i trybów zaznaczania
/// - Ikon i wskaźników
class ClientsLegendWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const ClientsLegendWidget({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<ClientsLegendWidget> createState() => _ClientsLegendWidgetState();
}

class _ClientsLegendWidgetState extends State<ClientsLegendWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0),
    ));

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ClientsLegendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.backgroundSecondary,
            AppThemePro.backgroundPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🎯 HEADER Z PRZYCISKIEM ROZWIJANIA
          _buildLegendHeader(),
          
          // 🎯 ROZWIJANA ZAWARTOŚĆ
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildLegendContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendHeader() {
    return InkWell(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppThemePro.accentGold.withOpacity(0.3),
                    AppThemePro.accentGold.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                color: AppThemePro.accentGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📖 Legenda i Objaśnienia',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kliknij, aby ${widget.isExpanded ? 'ukryć' : 'wyświetlić'} wyjaśnienia oznaczeń',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: widget.isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppThemePro.accentGold,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // 🎯 ZMNIEJSZONE: 20 -> 12
      child: Column(
        children: [
          // Separator
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12), // 🎯 ZMNIEJSZONE: 16 -> 12
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppThemePro.accentGold.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 🌟 ZŁOTE WYRÓŻNIENIA
          _buildLegendSection(
            title: '✨ Złote Wyróżnienia',
            icon: Icons.star,
            iconColor: AppThemePro.accentGold,
            items: [
              LegendItem(
                icon: Icons.star,
                iconColor: AppThemePro.accentGold,
                title: 'TOP 50 Inwestorów',
                description: 'Klienci z największym kapitałem pozostałym',
                decoration: _buildGlowDecoration(AppThemePro.accentGold),
              ),
            ],
          ),

          const SizedBox(height: 12), // 🎯 ZMNIEJSZONE: 20 -> 12

          // 💰 KWOTY NA KARTACH
          _buildLegendSection(
            title: '💰 Kwoty na Kartach Klientów',
            icon: Icons.account_balance_wallet,
            iconColor: AppThemePro.statusInfo,
            items: [
              LegendItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppTheme.secondaryGold,
                title: 'Kapitał Pozostały',
                description: 'Łączna kwota aktywnych inwestycji klienta (PLN)',
                decoration: _buildStandardDecoration(AppTheme.secondaryGold),
              ),
              LegendItem(
                icon: Icons.trending_up_outlined,
                iconColor: AppTheme.infoColor,
                title: 'Liczba Inwestycji',
                description: 'Ile produktów inwestycyjnych posiada klient',
                decoration: _buildStandardDecoration(AppTheme.infoColor),
              ),
              LegendItem(
                icon: Icons.security_outlined,
                iconColor: AppTheme.successColor,
                title: 'Kapitał Zabezpieczony',
                description: 'Kwota zabezpieczona nieruchomościami (PLN)',
                decoration: _buildStandardDecoration(AppTheme.successColor),
              ),
            ],
          ),

          const SizedBox(height: 12), // 🎯 ZMNIEJSZONE: 20 -> 12

          // 🎨 KOLORY I STATUSY
          _buildLegendSection(
            title: '🎨 Kolory i Statusy',
            icon: Icons.palette,
            iconColor: AppThemePro.bondsBlue,
            items: [
              LegendItem(
                icon: Icons.check_circle,
                iconColor: AppTheme.successColor,
                title: 'Klient Aktywny',
                description: 'Zielony wskaźnik - klient ma aktywne inwestycje',
                decoration: _buildStandardDecoration(AppTheme.successColor),
              ),
              LegendItem(
                icon: Icons.cancel,
                iconColor: AppTheme.errorColor,
                title: 'Klient Nieaktywny',
                description: 'Czerwony wskaźnik - klient wstrzymany/zamknięty',
                decoration: _buildStandardDecoration(AppTheme.errorColor),
              ),
              LegendItem(
                icon: Icons.email,
                iconColor: AppTheme.infoColor,
                title: 'Tryb Email',
                description: 'Niebieskie zaznaczenie podczas wyboru odbiorców',
                decoration: _buildStandardDecoration(AppTheme.infoColor),
              ),
              LegendItem(
                icon: Icons.file_download,
                iconColor: AppTheme.successColor,
                title: 'Tryb Eksportu',
                description: 'Zielone zaznaczenie podczas wyboru do eksportu',
                decoration: _buildStandardDecoration(AppTheme.successColor),
              ),
            ],
          ),

          const SizedBox(height: 10), // 🎯 ZMNIEJSZONE: 16 -> 10

          // 📊 DODATKOWE INFORMACJE
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildLegendSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<LegendItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek sekcji
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8), // 🎯 ZMNIEJSZONE: 12 -> 8
        
        // Lista elementów
        ...items.map((item) => _buildLegendItem(item)),
      ],
    );
  }

  Widget _buildLegendItem(LegendItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), // 🎯 ZMNIEJSZONE: 8 -> 6
      padding: const EdgeInsets.all(10), // 🎯 ZMNIEJSZONE: 12 -> 10
      decoration: item.decoration,
      child: Row(
        children: [
          Icon(
            item.icon,
            color: item.iconColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12), // 🎯 ZMNIEJSZONE: 16 -> 12
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.statusInfo.withOpacity(0.08),
            AppThemePro.accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.statusInfo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppThemePro.statusInfo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ Przydatne Informacje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Dane aktualizowane w czasie rzeczywistym z Firebase\n'
                  '• TOP 50 to ranking wg kapitału pozostałego\n'
                  '• Kapitał zabezpieczony = pozostały - do restrukturyzacji\n'
                  '• Długie naciśnięcie karty włącza tryb zaznaczania',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildGlowDecoration(Color color) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _buildStandardDecoration(Color color) {
    return BoxDecoration(
      color: AppThemePro.backgroundSecondary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
    );
  }
}

/// Model elementu legendy
class LegendItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final BoxDecoration decoration;

  LegendItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.decoration,
  });
}
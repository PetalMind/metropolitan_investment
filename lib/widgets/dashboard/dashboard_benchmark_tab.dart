import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DashboardBenchmarkTab extends StatelessWidget {
  final bool isMobile;

  const DashboardBenchmarkTab({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: const Column(
              children: [
                Icon(Icons.compare, size: 64, color: AppTheme.successColor),
                SizedBox(height: 16),
                Text(
                  'Porównanie z benchmarkami',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Porównanie z rynkowymi benchmarkami będzie dostępne wkrótce',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

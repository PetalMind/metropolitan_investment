import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Widget do testowania nawigacji do analityki inwestorów z parametrem wyszukiwania
class InvestorAnalyticsNavigationTester extends StatelessWidget {
  const InvestorAnalyticsNavigationTester({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Nawigacji do Analityki',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Testuj przekierowanie do analityki inwestorów z wyszukiwaniem:',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton(
                context,
                'Jan Kowalski',
                'Test wyszukiwania imienia i nazwiska',
              ),
              _buildTestButton(
                context,
                'ABC Spółka',
                'Test wyszukiwania nazwy firmy',
              ),
              _buildTestButton(
                context,
                'Inwestor',
                'Test wyszukiwania słowa kluczowego',
              ),
              _buildTestButton(
                context,
                'test@example.com',
                'Test wyszukiwania adresu email',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.infoPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Po kliknięciu nastąpi przejście do zakładki "Inwestorzy" z automatycznym wyszukiwaniem wybranego tekstu.',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String searchTerm,
    String description,
  ) {
    return Tooltip(
      message: description,
      child: ElevatedButton(
        onPressed: () {
          // Wykonaj nawigację z parametrem search
          context.go(
            '/investor-analytics?search=${Uri.encodeComponent(searchTerm)}',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(searchTerm, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

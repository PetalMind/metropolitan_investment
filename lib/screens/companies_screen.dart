import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.gradientDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zarządzanie Spółkami',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: AppTheme.textOnPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Emitenci produktów inwestycyjnych',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textOnPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Nowa Spółka'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceCard,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Moduł Spółek',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'W przygotowaniu...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
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
                        'Zarządzanie Pracownikami',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: AppTheme.textOnPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zespół Cosmopolitan Investment',
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
                  label: const Text('Nowy Pracownik'),
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
                  Icon(Icons.people, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Moduł Pracowników',
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

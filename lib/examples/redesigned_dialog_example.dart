import 'package:flutter/material.dart';
import '../screens/wow_email_editor_screen.dart';
import '../models_and_services.dart';

/// **PRZYKŁAD UŻYCIA WOW EKRANU EDYTORA EMAIL**
/// 
/// Pokazuje najpiękniejszy ekran edytora email w Flutter
class RedesignedDialogExample extends StatelessWidget {
  const RedesignedDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WOW Email Editor ✨'),
        backgroundColor: const Color(0xFF1a1a1a),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF2d2d2d),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 OPIS ZMIAN
              _buildChangeDescription(),
              const SizedBox(height: 32),
              
              // 🎯 GŁÓWNE FUNKCJE
              _buildMainFeatures(),
              const SizedBox(height: 32),
              
              // 🚀 PRZYCISK TESTOWY
              Center(
                child: _buildTestButton(context),
              ),
              
              const SizedBox(height: 24),
              
              // 📝 INSTRUKCJE
              _buildInstructions(),
              
              // Extra padding at bottom for better scroll experience
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeDescription() {
    return Card(
      color: const Color(0xFF2d2d2d),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'WOW Email Editor - Ultimate UI/UX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Najpiękniejszy ekran edytora email w Flutter z glassmorphism, zaawansowanymi animacjami i perfekcyjnym responsive design.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFeatures() {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Glassmorphism UI',
        'description': 'BackdropFilter i zaawansowane efekty wizualne',
        'color': const Color(0xFFD4AF37),
      },
      {
        'icon': Icons.animation,
        'title': 'WOW Animacje',
        'description': 'ElasticOut, EaseInOutCubic, Bounce Effects',
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': Icons.settings,
        'title': 'Zwijane Sekcje',
        'description': '"Ukryj/Pokaż sekcje" z płynną animacją',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Icons.phone_android,
        'title': 'Perfect Responsive',
        'description': 'Edytor ma priorytet na mobile/tablet',
        'color': const Color(0xFF9C27B0),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Główne Ulepszenia:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: features.map((feature) {
            return Card(
              color: const Color(0xFF2d2d2d),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4AF37),
            Color(0xFFB8941F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _openRedesignedDialog(context),
        icon: const Icon(Icons.launch, color: Colors.black),
        label: const Text(
          'Otwórz WOW Screen ✨',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: const Color(0xFF2d2d2d),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Jak korzystać z WOW ekranu:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Kliknij "Ukryj/Pokaż sekcje" aby zwijać ustawienia\n'
              '2. Wypełnij podstawowe informacje z glassmorphism polami\n'
              '3. Używaj edytora z priorytetem responsywności na mobile\n'
              '4. Kliknij strzałkę rozwijania do animacji edytora\n'
              '5. Dodaj inwestycje z prawdziwymi danymi finansowymi\n'
              '6. Ciesz się WOW animacjami i efektami!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WOW efekty: Glassmorphism, ElasticOut, EaseInOutCubic, BackdropFilter!',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRedesignedDialog(BuildContext context) {
    // Tworzenie przykładowych danych inwestorów
    final mockInvestors = [
      InvestorSummary(
        client: Client(
          id: 'client_001',
          name: 'Jan Kowalski',
          email: 'jan.kowalski@example.com',
          phone: '+48123456789',
          address: 'Warszawa, ul. Główna 123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        investments: [],
        totalRemainingCapital: 150000.0,
        totalSharesValue: 25000.0,
        totalValue: 175000.0,
        totalInvestmentAmount: 150000.0,
        totalRealizedCapital: 0.0,
        capitalSecuredByRealEstate: 100000.0,
        capitalForRestructuring: 0.0,
        investmentCount: 3,
      ),
      InvestorSummary(
        client: Client(
          id: 'client_002',
          name: 'Anna Nowak',
          email: 'anna.nowak@example.com',
          phone: '+48987654321',
          address: 'Kraków, ul. Piękna 45',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        investments: [],
        totalRemainingCapital: 85000.0,
        totalSharesValue: 15000.0,
        totalValue: 100000.0,
        totalInvestmentAmount: 85000.0,
        totalRealizedCapital: 0.0,
        capitalSecuredByRealEstate: 60000.0,
        capitalForRestructuring: 0.0,
        investmentCount: 2,
      ),
    ];

    // Otwórz WOW screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WowEmailEditorScreen(
          selectedInvestors: mockInvestors,
          initialSubject: 'WOW Email Editor - Ultimate UI/UX Test ✨',
          initialMessage:
              'To jest przykład użycia najpiękniejszego ekranu edytora email w Flutter z glassmorphism, zaawansowanymi animacjami i perfekcyjnym responsive design.',
        ),
      ),
    ).then((result) {
      if (result == true) {
        _showSuccessMessage(context);
      }
    });
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Ekran został zamknięty - tutaj byłaby logika wysyłania'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
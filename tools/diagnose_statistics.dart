#!/usr/bin/env dart

/// 🔍 SKRYPT DIAGNOZY STATYSTYK
///
/// Uruchamia kompleksową analizę niespójności statystyk między różnymi
/// metodami obliczeniowymi w systemie analityki inwestorów.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metropolitan_investment/services/statistics_diagnostic_service.dart';
import 'package:metropolitan_investment/firebase_options.dart';

Future<void> main(List<String> args) async {
  print('🔍 DIAGNOZA STATYSTYK METROPOLITAN INVESTMENT');
  print('=' * 60);

  try {
    // Initialize Firebase
    print('🔥 Łączenie z Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase połączony pomyślnie\n');

    // Run diagnostic
    print('🎯 Uruchamianie diagnozy...');
    final diagnosticService = StatisticsDiagnosticService();
    final report = await diagnosticService.diagnoseInconsistencies();

    // Generate summary report
    print('\n📋 RAPORT PODSUMOWUJĄCY');
    print('-' * 40);

    if (report.inconsistencies.isEmpty) {
      print('🎉 SUKCES: Wszystkie statystyki są spójne!');
      print('   Nie wykryto niespójności między metodami obliczeniowymi.');
    } else {
      print(
        '⚠️  UWAGA: Znaleziono ${report.inconsistencies.length} niespójności',
      );
      print('   Wymaga to natychmiastowej naprawy w systemie!');

      print('\n🔥 KRYTYCZNE PROBLEMY:');
      final criticalIssues = report.inconsistencies
          .where((inc) => inc.severity == 'CRITICAL')
          .toList();

      if (criticalIssues.isNotEmpty) {
        for (final issue in criticalIssues) {
          print(
            '   • ${issue.metric}: różnica ${issue.difference.toStringAsFixed(2)} PLN',
          );
        }
        print('\n💡 ZALECANE DZIAŁANIA:');
        print('   1. Natychmiast zunifikuj definicje totalValue');
        print('   2. Zsynchronizuj obliczenia viableCapital');
        print('   3. Zaimplementuj zunifikowany serwis statystyk');
        print('   4. Uruchom testy integracjne');
      }
    }

    // Exit code based on results
    if (report.inconsistencies.any((inc) => inc.severity == 'CRITICAL')) {
      print('\n❌ Zakończenie z kodem błędu 2 (krytyczne niespójności)');
      exit(2);
    } else if (report.inconsistencies.isNotEmpty) {
      print('\n⚠️  Zakończenie z kodem błędu 1 (niespójności wymagają uwagi)');
      exit(1);
    } else {
      print('\n✅ Zakończenie z kodem sukcesu 0');
      exit(0);
    }
  } catch (e) {
    print('\n❌ BŁĄD DIAGNOZY: $e');
    print('   Sprawdź połączenie z Firebase i spróbuj ponownie.');
    exit(3);
  }
}

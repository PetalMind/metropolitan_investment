#!/usr/bin/env dart

/// 🔍 SKRYPT DIAGNOZY STATYSTYK
///
/// Uruchamia kompleksową analizę niespójności statystyk między różnymi
/// metodami obliczeniowymi w systemie analityki inwestorów.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/services/statistics_diagnostic_service.dart';
import '../lib/firebase_options.dart';

Future<void> main(List<String> args) async {

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Run diagnostic
    final diagnosticService = StatisticsDiagnosticService();
    final report = await diagnosticService.diagnoseInconsistencies();

    // Generate summary report

    if (report.inconsistencies.isEmpty) {
    } else {

      final criticalIssues = report.inconsistencies
          .where((inc) => inc.severity == 'CRITICAL')
          .toList();

      if (criticalIssues.isNotEmpty) {
        for (final issue in criticalIssues) {
        }
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
      exit(0);
    }
  } catch (e) {
    exit(3);
  }
}

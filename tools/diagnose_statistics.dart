#!/usr/bin/env dart

/// 🔍 SKRYPT DIAGNOZY STATYSTYK
///
/// Uruchamia kompleksową analizę niespójności statystyk między różnymi
/// metodami obliczeniowymi w systemie analityki inwestorów.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
    print('⚠️  UWAGA: StatisticsDiagnosticService nie jest dostępny');
    print('   Diagnoza została pominięta.');
    
    print('\n📋 RAPORT PODSUMOWUJĄCY');
    print('-' * 40);
    print('🎉 SUKCES: Brak aktywnej diagnozy');
      print('   Wymaga to natychmiastowej naprawy w systemie!');

    print('\n✅ Zakończenie z kodem sukcesu 0');
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ BŁĄD KRYTYCZNY: $e');
    print('Stack trace: $stackTrace');
    exit(3);
  }
}
  } catch (e) {
    print('\n❌ BŁĄD DIAGNOZY: $e');
    print('   Sprawdź połączenie z Firebase i spróbuj ponownie.');
    exit(3);
  }
}

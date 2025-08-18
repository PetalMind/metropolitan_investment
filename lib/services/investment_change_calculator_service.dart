import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Serwis do obliczania zmian procentowych na podstawie historii inwestycji
class InvestmentChangeCalculatorService {
  final InvestmentChangeHistoryService _historyService = InvestmentChangeHistoryService();
  
  /// Oblicza zmiany procentowe dla konkretnego pola inwestycji
  /// 
  /// [investmentId] - ID inwestycji
  /// [fieldName] - nazwa pola (np. 'remainingCapital', 'investmentAmount')
  /// [currentValue] - obecna wartość pola
  /// [maxHistoryEntries] - maksymalna liczba wpisów historii do analizy (domyślnie 10)
  /// 
  /// Zwraca [FieldChangeInfo] z informacjami o zmianach lub null jeśli brak danych
  Future<FieldChangeInfo?> calculateFieldChange({
    required String investmentId,
    required String fieldName,
    required double currentValue,
    int maxHistoryEntries = 10,
  }) async {
    try {
      // Pobierz historię zmian dla tej inwestycji
      final history = await _historyService.getInvestmentHistory(investmentId);
      
      if (history.isEmpty) {
        return null;
      }
      
      // Znajdź najnowszą zmianę tego pola
      InvestmentChangeHistory? latestChangeEntry;
      FieldChange? latestFieldChange;
      
      for (final entry in history.take(maxHistoryEntries)) {
        for (final fieldChange in entry.fieldChanges) {
          if (fieldChange.fieldName == fieldName) {
            latestChangeEntry = entry;
            latestFieldChange = fieldChange;
            break;
          }
        }
        if (latestFieldChange != null) break;
      }
      
      if (latestFieldChange == null) {
        return null;
      }
      
      // Oblicz zmiany
      final oldValue = _parseValue(latestFieldChange.oldValue);
      final changeAmount = currentValue - oldValue;
      final changePercentage = oldValue != 0 ? (changeAmount / oldValue) * 100 : 0.0;
      
      return FieldChangeInfo(
        fieldName: fieldName,
        fieldDisplayName: latestFieldChange.fieldDisplayName,
        oldValue: oldValue,
        currentValue: currentValue,
        changeAmount: changeAmount,
        changePercentage: changePercentage,
        changeDate: latestChangeEntry?.changedAt ?? DateTime.now(),
        changedBy: latestChangeEntry?.userName ?? 'Nieznany',
      );
      
    } catch (e) {
      debugPrint('❌ [InvestmentChangeCalculatorService] Error calculating field change: $e');
      return null;
    }
  }
  
  /// Oblicza wszystkie zmiany procentowe dla inwestycji
  /// 
  /// [investmentId] - ID inwestycji
  /// [currentValues] - mapa obecnych wartości pól
  /// 
  /// Zwraca mapę z informacjami o zmianach dla każdego pola
  Future<Map<String, FieldChangeInfo>> calculateAllFieldChanges({
    required String investmentId,
    required Map<String, double> currentValues,
    int maxHistoryEntries = 10,
  }) async {
    final result = <String, FieldChangeInfo>{};
    
    for (final entry in currentValues.entries) {
      final changeInfo = await calculateFieldChange(
        investmentId: investmentId,
        fieldName: entry.key,
        currentValue: entry.value,
        maxHistoryEntries: maxHistoryEntries,
      );
      
      if (changeInfo != null) {
        result[entry.key] = changeInfo;
      }
    }
    
    return result;
  }
  
  /// Oblicza trend zmian dla pola (wzrost/spadek na podstawie ostatnich zmian)
  /// 
  /// [investmentId] - ID inwestycji
  /// [fieldName] - nazwa pola
  /// [trendPeriod] - liczba ostatnich zmian do analizy trendu (domyślnie 3)
  /// 
  /// Zwraca [TrendInfo] z informacjami o trendzie
  Future<TrendInfo?> calculateFieldTrend({
    required String investmentId,
    required String fieldName,
    int trendPeriod = 3,
  }) async {
    try {
      final history = await _historyService.getInvestmentHistory(investmentId);
      
      if (history.isEmpty) {
        return null;
      }
      
      // Znajdź wszystkie zmiany tego pola w historii
      final fieldChanges = <FieldChange>[];
      final changeDates = <DateTime>[];
      
      for (final entry in history) {
        for (final fieldChange in entry.fieldChanges) {
          if (fieldChange.fieldName == fieldName) {
            fieldChanges.add(fieldChange);
            changeDates.add(entry.changedAt);
          }
        }
      }
      
      if (fieldChanges.length < 2) {
        return null; // Potrzebujemy przynajmniej 2 zmiany do analizy trendu
      }
      
      // Weź ostatnie zmiany do analizy trendu
      final recentChanges = fieldChanges.take(trendPeriod).toList();
      final recentDates = changeDates.take(trendPeriod).toList();
      
      // Oblicz trend - czy wartości generalnie rosną czy maleją
      double totalChange = 0;
      int positiveChanges = 0;
      int negativeChanges = 0;
      
      for (final change in recentChanges) {
        final oldVal = _parseValue(change.oldValue);
        final newVal = _parseValue(change.newValue);
        final difference = newVal - oldVal;
        
        totalChange += difference;
        
        if (difference > 0) {
          positiveChanges++;
        } else if (difference < 0) {
          negativeChanges++;
        }
      }
      
      // Określ typ trendu
      TrendType trendType;
      if (positiveChanges > negativeChanges) {
        trendType = TrendType.upward;
      } else if (negativeChanges > positiveChanges) {
        trendType = TrendType.downward;
      } else {
        trendType = TrendType.stable;
      }
      
      return TrendInfo(
        fieldName: fieldName,
        trendType: trendType,
        totalChange: totalChange,
        changesAnalyzed: recentChanges.length,
        positiveChanges: positiveChanges,
        negativeChanges: negativeChanges,
        firstChangeDate: recentDates.isNotEmpty ? recentDates.last : DateTime.now(),
        lastChangeDate: recentDates.isNotEmpty ? recentDates.first : DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('❌ [InvestmentChangeCalculatorService] Error calculating trend: $e');
      return null;
    }
  }
  
  /// Pomocnicza funkcja do parsowania wartości
  double _parseValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(' ', '').replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}

/// Model informacji o zmianie pola
class FieldChangeInfo {
  final String fieldName;
  final String fieldDisplayName;
  final double oldValue;
  final double currentValue;
  final double changeAmount;
  final double changePercentage;
  final DateTime changeDate;
  final String changedBy;
  
  const FieldChangeInfo({
    required this.fieldName,
    required this.fieldDisplayName,
    required this.oldValue,
    required this.currentValue,
    required this.changeAmount,
    required this.changePercentage,
    required this.changeDate,
    required this.changedBy,
  });
  
  /// Czy zmiana jest dodatnia (wzrost)
  bool get isPositive => changeAmount > 0;
  
  /// Czy zmiana jest znacząca (> 1%)
  bool get isSignificant => changePercentage.abs() > 1.0;
  
  /// Opis zmiany w formacie czytelnym dla użytkownika
  String get changeDescription {
    final direction = isPositive ? 'wzrost' : 'spadek';
    final percentageFormatted = '${changePercentage.abs().toStringAsFixed(1)}%';
    return '$direction o $percentageFormatted';
  }
  
  /// Sformatowana kwota zmiany
  String get formattedChangeAmount {
    final sign = isPositive ? '+' : '';
    return '$sign${CurrencyFormatter.formatCurrency(changeAmount)}';
  }
}

/// Model informacji o trendzie
class TrendInfo {
  final String fieldName;
  final TrendType trendType;
  final double totalChange;
  final int changesAnalyzed;
  final int positiveChanges;
  final int negativeChanges;
  final DateTime firstChangeDate;
  final DateTime lastChangeDate;
  
  const TrendInfo({
    required this.fieldName,
    required this.trendType,
    required this.totalChange,
    required this.changesAnalyzed,
    required this.positiveChanges,
    required this.negativeChanges,
    required this.firstChangeDate,
    required this.lastChangeDate,
  });
  
  /// Opis trendu
  String get trendDescription {
    switch (trendType) {
      case TrendType.upward:
        return 'Trend wzrostowy';
      case TrendType.downward:
        return 'Trend spadkowy';
      case TrendType.stable:
        return 'Trend stabilny';
    }
  }
  
  /// Siła trendu (0-1)
  double get trendStrength {
    if (changesAnalyzed == 0) return 0.0;
    
    final dominantChanges = trendType == TrendType.upward 
        ? positiveChanges 
        : trendType == TrendType.downward 
            ? negativeChanges 
            : 0;
            
    return dominantChanges / changesAnalyzed;
  }
}

/// Typy trendów
enum TrendType {
  upward,   // Trend wzrostowy
  downward, // Trend spadkowy
  stable,   // Trend stabilny
}
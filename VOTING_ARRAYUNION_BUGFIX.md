# Poprawka błędu ArrayUnion + ServerTimestamp w systemie głosowania

## Problem
```
❌ [cloud_firestore/invalid-argument] Function arrayUnion() called with invalid data. 
serverTimestamp() can only be used with update() and set() (found in document clients/100)
```

## Przyczyna
Błąd występował w `EnhancedVotingStatusService.updateVotingStatusWithHistory()` gdzie próbowano użyć `FieldValue.serverTimestamp()` wewnątrz `FieldValue.arrayUnion()`, co nie jest dozwolone w Firestore.

## Kod powodujący błąd
```dart
'votingStatusHistory': FieldValue.arrayUnion([
  {
    'previousStatus': oldStatus.name,
    'newStatus': newStatus.name,
    'timestamp': FieldValue.serverTimestamp(), // ❌ BŁĄD - nie można używać w arrayUnion
    'reason': reason ?? 'Status update',
    'additionalData': additionalChanges ?? {},
  },
]),
```

## Poprawka
Zastąpiono `FieldValue.serverTimestamp()` przez `Timestamp.now()` w kontekście `arrayUnion`:

```dart
// ✅ POPRAWKA
final now = Timestamp.now();
await _clientService.updateClientFields(clientId, {
  'votingStatus': newStatus.name,
  'lastVotingStatusUpdate': FieldValue.serverTimestamp(), // OK - na poziomie dokumentu
  'votingStatusHistory': FieldValue.arrayUnion([
    {
      'previousStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'timestamp': now, // ✅ Używamy Timestamp.now() zamiast FieldValue.serverTimestamp()
      'reason': reason ?? 'Status update',
      'additionalData': additionalChanges ?? {},
    },
  ]),
});
```

## Dotknięte pliki
- ✅ `lib/services/enhanced_voting_status_service.dart` - NAPRAWIONE

## Reguly Firestore
1. `FieldValue.serverTimestamp()` może być używane tylko na poziomie pól dokumentu
2. W kontekście `FieldValue.arrayUnion()`, `FieldValue.serverTimestamp()` nie jest dozwolone
3. W takich przypadkach należy używać `Timestamp.now()` 

## Testowanie
Utworzono `VotingSystemBugfixTest` widget do weryfikacji poprawki:
- Test aktualizacji statusu głosowania 
- Test zapisywania historii głosowania
- Weryfikacja braku błędów Firestore

## Impact
- ✅ Dialogi klientów działają bez błędów
- ✅ Historia głosowania zapisuje się poprawnie  
- ✅ `UnifiedVotingService` działa bez problemów
- ✅ Zachowana kompatybilność z existing data

## Deployment
Poprawka została wdrożona w:
- `EnhancedVotingStatusService` - podstawowy serwis
- Wszystkie zależne komponenty używają tego serwisu przez `UnifiedVotingService`
- Batch operations również naprawione (używają tego samego flow)

## Monitoring
Po wdrożeniu należy monitorować:
- Brak błędów `[cloud_firestore/invalid-argument]` w logach
- Poprawne zapisywanie historii głosowania
- Działanie dialogów klientów i inwestorów

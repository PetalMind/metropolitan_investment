---
mode: agent
---
Opis zadania (BEAST MODE dla modelu pracującego w tym repo):

Cel: Daj modelowi (agentowi) maksymalnie szczegółowe, praktyczne i kontekstowe instrukcje, dzięki którym wykona zmiany, naprawy, refaktoryzacje, testy i wdrożenia w repozytorium "metropolitan_investment" szybko, bezpiecznie i zgodnie z konwencjami projektu.

Język i forma:
- Pisz w języku polskim, zwięźle, bez zbędnych ozdobników.
- Tam, gdzie to konieczne dla precyzji instrukcji technicznych, używaj fragmentów kodu lub ścieżek plików w backtickach.

Kluczowe założenia projektu (wyciągnięte z `CLAUDE.md`):
- Flutter frontend (Dart) + Firebase backend (Firestore, Auth, Functions).
- Wszystkie modele i serwisy należy importować z `lib/models_and_services.dart`.
- Region funkcji Cloud Functions: `europe-west1` — używaj `FirebaseFunctions.instanceFor(region: 'europe-west1')`.
- Wszystkie produkty inwestycyjne przechowywane w jednej kolekcji Firestore `investments` (konwencja ID: `bond_0001`, `loan_0005`, etc.).
- System mapowania pól: kod używa angielskich nazw, Firestore może mieć nazwy polskie — użyj istniejących `fromFirestore()` / `toFirestore()` i `field-mapping-utils.js` gdy modyfikujesz zapisy lub migracje.
- Usuwaj/edytuj tylko po uwzględnieniu migracji i indeksów; nie zmieniaj formatów ID bez skryptu migracyjnego.

Zakres poleceń jakie agent może wykonywać (priorytety):
1. Analiza kodu: znajdź miejsca łamiące konwencje (nieużywanie `models_and_services.dart`, hardkodowane regiony, stare kolekcje: `bonds`, `shares`), wygeneruj listę poprawek.
2. Poprawki kodu: wprowadz konkretne zmiany zgodnie z konwencjami (np. zamień importy, ujednolić pola, naprawić mapowania pól), tworząc minimalne, bezpieczne patche.
3. Testy: dodaj lub zaktualizuj testy jednostkowe (Flutter/Dart lub Node.js dla funkcji) — przynajmniej jeden happy-path i 1-2 edge-case dla zmian.
4. Weryfikacja: uruchom `flutter analyze`, `flutter test` (lub `cd functions && npm test`) i popraw zgłoszone błędy (do 3 iteracji). Jeśli błąd nie może być naprawiony od razu, opisz przyczynę i proponowane następne kroki.
5. Dokumentacja: zaktualizuj `CLAUDE.md` lub dodaj krótką notatkę/README z opisem zmiany, koniecznymi migracjami i poleceniami deploy.

Szczegółowy kontrakt (wewnętrzne reguły wykonawcze):
- Wejścia: zmiany w repo (pliki Dart/JS/TS), testy, skrypty migracyjne.
- Wyjścia: poprawiony kod, nowe/zmodyfikowane testy, wynik działania analiz i testów, patch do review.
- Warunki sukcesu: projekt buduje się i analizuje bez błędów krytycznych (PASS dla `flutter analyze` i `npm test` w funkcjach) ORAZ nowe/zmienione testy przechodzą lokalnie.
- Tryby błędów: jeśli zmiana wymaga migracji bazy, wygeneruj skrypt migracyjny i oznacz zadanie jako wymagające zatwierdzenia (manual approval) przed deployem.

Quality gates (krótkie i wymierne):
- Lint/Analiza: `flutter analyze` -> zero nowych warningów klasy krytycznej.
- Testy: uruchomione testy jednostkowe -> wszystkie nowe testy zielone; jeśli pełny test suite jest długi, uruchom testy odpowiednie dla zmienionych modułów.
- Kompilacja: dla zmian Dart — `flutter build` (jeśli zmiana dotyczy UI/kompilacji) lub minimalne smoke build, dla funkcji Node.js -> `npm run test`.
- Bezpieczeństwo danych: nie zmieniaj mapowania istniejących Firestore fields bez migracji i dokumentacji.

Reguły commit/patch:
- Małe, atomowe commity z opisem (PL): "Poprawa: ...", "Fix: ..." lub "Refactor: ...". Jeśli edytujesz wiele plików, podziel na logiczne kroki.
- Nigdy nie usuwaj bez kopi zapasowej (np. `clients_extracted.json`) bez wyraźnego powodu i zgody.

Przykładowe checklisty dla typowych zadań (używaj ich jako template):
- Refactor importów do `models_and_services.dart`:
	- znajdź importy łamiące regułę
	- zastąp je importem z `lib/models_and_services.dart`
	- uruchom `flutter analyze` i `flutter test` dla powiązanych testów

- Aktualizacja mapowania pól Firestore:
	- zaktualizuj `fromFirestore()`/`toFirestore()` w modelu
	- uruchom `node field-mapping-utils.js` (lokalnie) do weryfikacji
	- dodaj test jednostkowy w `functions/test_*.js` lub Dart test
	- przygotuj skrypt migracyjny i plan migracji w `tools/` jeśli konieczne

Edge-cases i ryzyka (co sprawdzić zawsze):
- Zmiana nazw pól może złamać istniejące indeksy i zapytania — sprawdź `firestore.indexes.json`.
- Duże migracje danych powinny być wykonywane przy emulacji lub w batchach (skrypty w `tools/`).
- Uprawnienia i RBAC: krytyczne operacje muszą być zablokowane dla nie-adminów (sprawdź `AuthProvider.isAdmin`).

Jak pisać komunikaty do reviewerów (szablon):
"Co robi zmiana: <krótki opis>\nDlaczego: <powód>\nTesty: <które testy uruchomione>\nRyzyka: <lista>\nKroki deployu: <komendy>"

Polecenia operacyjne (przykłady, które model może zasugerować lub uruchomić):
```bash
# Flutter: analiza i testy
flutter pub get
flutter analyze
flutter test test/widget_test.dart

# Functions: testy i emulacja
cd functions && npm install
cd functions && npm run test
cd functions && firebase emulators:start --only functions
```

Wskazówki debugowe i narzędzia pomocnicze:
- Użyj `grep` / `rg` do znalezienia "banned" patterns (np. `import '../models/client.dart'`).
- Do walidacji mapowania pól uruchom `node field-mapping-utils.js`.
- Sprawdź listę plików danych w repo (np. `clients_extracted.json`) przed operacjami masowymi.

Format odpowiedzi agenta (obowiązkowy):
1) Krótki plan w 2-3 punktach (co zrobię teraz). 
2) Lista zmian (plik, krótki opis). 
3) Wyniki testów/analizy (PASS/FAIL + skrócone logi). 
4) Checklist "co jeszcze" i rekomendacje do deployu.

Przykładowe prompt-internal (dla szybkiego użycia):
"Jesteś agentem pracującym na repozytorium 'metropolitan_investment'. Twoim zadaniem jest X. Stosuj konwencje z `CLAUDE.md`. Wygeneruj listę plików do zmiany i utwórz atomowe patche, uruchom `flutter analyze` i testy dla zmienionych modułów. Odpowiedz w formacie: plan, zmiany, wyniki, dalsze kroki."

Uwaga końcowa:
Ten plik jest "beast mode" promptem — powinien być krótko dostępny i łatwy do kopiowania przez inne agentowe systemy. Aktualizuj go gdy projekt zmienia krytyczne konwencje (np. region funkcji, centralny barrel export, schemat kolekcji Firestore).

# 🧪 Testowanie Nowego Dialogu Edytora Email

## 🚀 Jak uruchomić test

### Opcja 1: Bezpośrednia ścieżka URL
```
Idź do: http://localhost:PORT/test-dialog
```

### Opcja 2: Programowo w kodzie
```dart
import 'package:go_router/go_router.dart';

// W dowolnym miejscu w kodzie:
context.go('/test-dialog');
```

### Opcja 3: Dodaj przycisk testowy
```dart
import '../widgets/debug/test_dialog_button.dart';

// W build() method dowolnego ekranu:
Stack(
  children: [
    // Twój główny content
    YourMainContent(),
    
    // Floating button do testów
    TestDialogButton(),
  ],
)
```

## 📝 Co testować

### 1. **Podstawowe funkcje**
- [ ] Otwórz dialog - czy się ładuje
- [ ] Wypełnij email nadawcy
- [ ] Wypełnij temat  
- [ ] Napisz treść w edytorze

### 2. **Narzędzia formatowania**
- [ ] **Bold (B)** - pogrub tekst
- [ ] **Italic (I)** - kursywa
- [ ] **Underline (U)** - podkreślenie
- [ ] **Wybierz czcionkę** - testuj różne czcionki
- [ ] **Rozmiar tekstu** - zmień rozmiar
- [ ] **Kolory** - zmień kolor tekstu
- [ ] **Nagłówki** - H1, H2, H3
- [ ] **Listy** - punktowe i numerowane

### 3. **Szybkie akcje**
- [ ] **"Dodaj sekcję inwestycji"** - wstawi tekst placeholder
- [ ] **"Wyczyść wszystko"** - wyczyści edytor (z potwierdzeniem)
- [ ] **"Podgląd email"** - pokaże popup z podglądem HTML

### 4. **Responsywność**
- [ ] **Desktop** - pełny widok
- [ ] **Tablet** - średni layout
- [ ] **Mobile** - uproszczony layout (< 600px)

### 5. **UX/UI sprawdzenia**
- [ ] Czy wszystkie przyciski mają jasne opisy?
- [ ] Czy instrukcje są czytelne?
- [ ] Czy layout jest logiczny (góra → dół)?
- [ ] Czy nie ma overflow/scroll problemów?

## 🎯 Konkretny plan testowania

### Test 1: Podstawowe flow
```
1. Otwórz /test-dialog
2. Kliknij "Otwórz Nowy Dialog"
3. Sprawdź czy banner z instrukcjami jest czytelny
4. Wypełnij email: test@example.com
5. Wpisz temat: "Test wiadomości"
6. Napisz treść: "To jest test nowego interfejsu"
7. Kliknij "Wyślij Wiadomości"
8. Sprawdź czy pokazuje się sukces/błąd
```

### Test 2: Formatowanie tekstu
```
1. Napisz tekst: "To jest test formatowania"
2. Zaznacz słowo "test"
3. Kliknij B (bold)
4. Zaznacz słowo "formatowania"  
5. Kliknij I (italic)
6. Wybierz czcionkę "Times New Roman"
7. Zmień rozmiar na "Duży (18px)"
8. Kliknij "Podgląd email"
9. Sprawdź czy formatowanie się wyświetla
```

### Test 3: Szybkie akcje
```
1. Kliknij "Dodaj sekcję inwestycji"
2. Sprawdź czy wstawił tekst o inwestycjach
3. Napisz jeszcze jakąś treść
4. Kliknij "Wyczyść wszystko"
5. Potwierdź - sprawdź czy wyczyściło
6. Napisz nową treść
7. Kliknij "Podgląd email"
8. Sprawdź czy podgląd działa
```

### Test 4: Responsywność
```
1. Otwórz Developer Tools (F12)
2. Ustaw rozmiar: 1200px (desktop)
   - Sprawdź pełny layout
3. Ustaw rozmiar: 800px (tablet)
   - Sprawdź średni layout
4. Ustaw rozmiar: 400px (mobile)
   - Sprawdź czy jest uproszczony
   - Czy wszystko się mieści
```

## 🐛 Na co zwrócić uwagę (potencjalne problemy)

### CSS/Layout problemy:
- Overflow - czy tekst nie wychodzi poza ramki
- Scroll - czy można przewijać długą treść
- Przyciski - czy nie są za małe na mobile
- Popup podglądu - czy nie jest za duży/mały

### Funkcjonalność:
- Czy formatowanie się zachowuje
- Czy kolory działają
- Czy czcionki się zmieniają
- Czy "Wyczyść" rzeczywiście czyści

### UX problemy:
- Czy instrukcje są jasne
- Czy użytkownik wie co robić
- Czy błędy są czytelne
- Czy loading states działają

## 📊 Porównanie z starym dialogiem

### Sprawdź te rzeczy w porównaniu:

| Co sprawdzić | Stary Dialog | Nowy Dialog |
|--------------|--------------|-------------|
| **Ilość kroków do napisania email** | ??? | 3-4 kroki |
| **Czas znalezienia formatowania** | ??? | Natychmiastowy |
| **Confusion podczas użytkowania** | ??? | Minimalny |
| **Mobilność** | ??? | Responsive |

## 💡 Feedback do zebrania

### Pytania do użytkowników:
1. **"Czy od razu wiesz co robić?"** (intuicyjność)
2. **"Które funkcje są najważniejsze?"** (priorytety)
3. **"Co jest mylące?"** (problemy UX)
4. **"Czego brakuje?"** (missing features)
5. **"Jak porównujesz ze starym?"** (improvement)

### Metryki do zmierzenia:
- Czas od otwarcia do wysłania pierwszego email
- Ile razy użytkownik się "gubi"
- Czy używa "Podgląd" czy nie
- Które fonty wybiera najczęściej

## 🔧 Debug mode

W trybie debug dostępne są dodatkowe narzędzia:

```dart
// Banner na górze ekranu
TestDialogBanner()

// Floating button
TestDialogButton()
```

Pokazują się tylko w debug mode (nie w produkcji).

## 🎉 Sukces oznacza:

✅ **Użytkownik intuicyjnie wie co robić**
✅ **Nie gubi się w interfejsie**  
✅ **Może szybko sformatować tekst**
✅ **Podgląd działa poprawnie**
✅ **Dialog jest responsywny**
✅ **Kod jest czystszy i prostszy**

**Jeśli to wszystko działa - nowy dialog jest gotowy! 🚀**
# 🏛️ Metropolitan Logo Widget

Profesjonalny widget logo dla aplikacji Metropolitan Investment z zaawansowanymi efektami wizualnymi i animacjami.

## ✨ Funkcjonalności

- **🎨 SVG Logo**: Wykorzystuje prawdziwe logo firmy bez tła
- **🌈 Dynamiczne kolory**: Obsługa różnych kolorów i motywów
- **✨ Animacje**: Floating, rotation, glow, hover effects
- **📱 Responsywny**: Automatyczne skalowanie dla różnych rozmiarów
- **🎯 Interaktywny**: Obsługa gestów i callbacków
- **🔧 Konfigurowalny**: Różne style i rozmiary

## 🚀 Podstawowe użycie

```dart
import 'package:metropolitan_investment/widgets/metropolitan_logo_widget.dart';

// Logo podstawowe
MetropolitanLogoWidget()

// Logo animowane dla splash screen
MetropolitanLogoWidget.splash()

// Logo dla nawigacji
MetropolitanLogoWidget.navigation()

// Logo kompaktowe
MetropolitanLogoWidget.compact()
```

## 🎨 Style dostępne

### 1. Premium Style
Pełny efekt z kontenerem, cieniami i animacjami:
```dart
MetropolitanLogoWidget(
  size: 160,
  style: MetropolitanLogoStyle.premium,
  animated: true,
)
```

### 2. Simple Style
Prosty kontener z logo:
```dart
MetropolitanLogoWidget(
  size: 80,
  style: MetropolitanLogoStyle.simple,
)
```

### 3. Minimal Style
Tylko SVG bez kontenera:
```dart
MetropolitanLogoWidget(
  size: 40,
  style: MetropolitanLogoStyle.minimal,
)
```

## 🎛️ Parametry konfiguracji

| Parametr | Typ | Domyślnie | Opis |
|----------|-----|-----------|------|
| `size` | `double` | `120.0` | Szerokość logo |
| `color` | `Color?` | `null` | Kolor logo (domyślnie biały) |
| `animated` | `bool` | `false` | Czy logo ma być animowane |
| `enableHover` | `bool` | `true` | Czy włączyć efekt hover |
| `onTap` | `VoidCallback?` | `null` | Callback po kliknięciu |
| `style` | `MetropolitanLogoStyle` | `premium` | Styl wyświetlania |

## 📱 Gotowe warianty

### Splash Screen
```dart
MetropolitanLogoWidget.splash(
  // size: 160, animated: true, enableHover: false
)
```

### Navigation Bar
```dart
MetropolitanLogoWidget.navigation(
  onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
  // size: 40, style: simple
)
```

### Compact Header
```dart
MetropolitanLogoWidget.compact(
  // size: 80, style: minimal
)
```

## 🎨 Przykłady kolorów

```dart
// Złoty akcent (domyślny)
MetropolitanLogoWidget(color: AppThemePro.accentGold)

// Biały tekst
MetropolitanLogoWidget(color: AppThemePro.textPrimary)

// Sukces
MetropolitanLogoWidget(color: AppThemePro.statusSuccess)

// Info
MetropolitanLogoWidget(color: AppThemePro.statusInfo)
```

## 🔧 Extension Methods

### Metropolitan Branding Container
```dart
MetropolitanLogoWidget.compact()
  .withMetropolitanBranding(
    padding: EdgeInsets.all(24),
    backgroundColor: AppThemePro.surfaceCard,
  )
```

## 🎯 Przykład w AppBar

```dart
AppBar(
  leading: Padding(
    padding: EdgeInsets.all(8.0),
    child: MetropolitanLogoWidget.navigation(
      onTap: () => context.go('/dashboard'),
    ),
  ),
  title: Text('Metropolitan Investment'),
)
```

## 🎬 Animacje

Widget obsługuje następujące animacje:

- **Rotation**: Delikatny obrót podczas ładowania
- **Scale**: Powiększenie przy hover
- **Glow**: Pulsujące świecenie
- **Shimmer**: Efekt błyszczenia
- **Float**: Subtelne unoszenie

## 📋 Wymagania

- Flutter SDK ≥ 3.0.0
- flutter_svg: ^2.0.10+1
- app_theme_professional.dart

## 💡 Wskazówki

1. **Performance**: Dla statycznych logo używaj `animated: false`
2. **Accessibility**: Logo automatycznie ma semantykę dla czytników ekranu
3. **Theming**: Kolor automatycznie się dostosowuje do `currentColor` w SVG
4. **Responsive**: Używaj `MediaQuery` dla dynamicznych rozmiarów

## 🔄 Integracja z istniejącym kodem

Zamień istniejące logo:
```dart
// Stary kod
Image.asset('assets/logos/logo.png')

// Nowy kod
MetropolitanLogoWidget.navigation()
```

## 🌟 Najlepsze praktyki

1. **Nawigacja**: Zawsze dodawaj `onTap` callback dla logo w nawigacji
2. **Loading**: Używaj animacji tylko podczas ładowania
3. **Contrast**: Sprawdź kontrast kolorów dla dostępności
4. **Performance**: Unikaj animacji na listach z wieloma elementami

---

*Stworzony dla Metropolitan Investment - Professional Investment Management Platform*

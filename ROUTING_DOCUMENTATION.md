# System Routingu - Cosmopolitan Investment

## Przegląd

Aplikacja została zaktualizowana z nowoczesnym systemem routingu opartym o **go_router** pakiet, który zastępuje tradycyjny Navigator. Nowy system oferuje:

- 🔄 Deklaratywne zarządzanie trasami
- 🔐 Zintegrowaną autentyfikację i autoryzację
- 🏗️ Shell routing dla wspólnej nawigacji
- 📱 Responsywny design
- 🚀 Lepszą wydajność i UX

## Struktura Routingu

### Główne trasy aplikacji

```
/                           # Root - przekierowuje do AuthWrapper
├── /login                  # Ekran logowania  
├── /register              # Ekran rejestracji
└── /main                   # Główna aplikacja (wymaga autoryzacji)
    ├── /dashboard          # Dashboard z analizami
    ├── /investments        # Zarządzanie inwestycjami
    ├── /clients           # Zarządzanie klientami
    ├── /products          # Zarządzanie produktami
    ├── /companies         # Zarządzanie spółkami
    ├── /employees         # Zarządzanie pracownikami
    ├── /analytics         # Zaawansowane analizy
    └── /investor-analytics # Analizy inwestorów
```

## Kluczowe Komponenty

### 1. AppRouter (`lib/config/routes.dart`)

Główna klasa konfigurująca system routingu:

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      // Logika autoryzacji i przekierowań
    },
    routes: [
      // Konfiguracja wszystkich tras
    ],
  );
}
```

#### Funkcjonalności:
- **Automatyczne przekierowania** na podstawie stanu autoryzacji
- **Shell routing** dla wspólnego layoutu nawigacji
- **Lazy loading** ekranów
- **Obsługa błędów** i stanów ładowania

### 2. MainScreenLayout

Nowy responsywny layout z boczną nawigacją:

```dart
class MainScreenLayout extends StatefulWidget {
  final Widget content;
  
  // Komponenty:
  // - NavigationRail z rozwijaniem/zwijaniem
  // - Responsywny design
  // - Menu użytkownika
  // - Zarządzanie stanem nawigacji
}
```

#### Cechy:
- 📱 **Responsywność**: Automatyczne dostosowanie do rozmiaru ekranu
- 🎨 **Nowoczesny design**: Material Design 3 z gradientami
- ⚡ **Płynne animacje**: Smooth transitions między sekcjami
- 👤 **Menu użytkownika**: Profil, ustawienia, wylogowanie

### 3. AuthWrapper

Komponent zarządzający autoryzacją:

```dart
class AuthWrapper extends StatelessWidget {
  // Sprawdza stan autoryzacji
  // Wyświetla odpowiedni ekran (login/main)
  // Obsługuje loading states
}
```

## Nawigacja w Aplikacji

### Podstawowe funkcje nawigacji

```dart
// Przejście do konkretnej sekcji
context.go(AppRoutes.dashboard);
context.go(AppRoutes.investments);

// Powrót
context.pop();

// Zastąpienie aktualnej trasy
context.pushReplacement(AppRoutes.login);
```

### Przekierowania w zależności od autoryzacji

```dart
redirect: (context, state) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final isAuthenticated = authProvider.isLoggedIn;
  
  // Sprawdza stan i przekierowuje odpowiednio
  if (!isAuthenticated && !isPublicPath) {
    return AppRoutes.login;
  }
  
  if (isAuthenticated && isPublicPath) {
    return AppRoutes.main;
  }
  
  return null;
}
```

## Struktura Plików

```
lib/
├── config/
│   └── routes.dart              # Główna konfiguracja routingu
├── screens/
│   ├── login_screen.dart        # Ekran logowania
│   ├── register_screen.dart     # Ekran rejestracji
│   ├── dashboard_screen.dart    # Dashboard główny
│   ├── investments_screen.dart  # Zarządzanie inwestycjami
│   ├── clients_screen.dart      # Zarządzanie klientami
│   ├── products_screen.dart     # Zarządzanie produktami
│   ├── companies_screen.dart    # Zarządzanie spółkami
│   ├── employees_screen.dart    # Zarządzanie pracownikami
│   ├── analytics_screen.dart    # Analizy podstawowe
│   └── investor_analytics_screen.dart # Analizy inwestorów
├── widgets/
│   └── auth_wrapper.dart        # Komponent autoryzacji
└── main.dart                    # Konfiguracja aplikacji
```

## Responsywność

System został zaprojektowany z myślą o różnych rozmiarach ekranów:

### Mobile (< 768px)
- Kompaktowa nawigacja
- Pojedyncza kolumna contentu
- Minimalne padding
- Touch-friendly interfejs

### Tablet (768px - 1024px)
- Dwukolumnowy layout
- Rozszerzona nawigacja
- Większe elementy UI
- Optymalizacja dla touch i kursor

### Desktop (> 1024px)
- Pełna nawigacja z etykietami
- Multi-kolumnowy layout
- Hover effects
- Shortcuts klawiszowe

## Integracje

### Provider Integration
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    // Obsługa stanu autoryzacji
    // Aktualizacja UI w zależności od stanu użytkownika
  },
)
```

### Theme Integration
```dart
// Automatyczne zastosowanie AppTheme
// Responsywne kolory i rozmiary
// Dark/Light mode support
```

## Bezpieczeństwo

### Ochrona Tras
- **Autoryzacja**: Sprawdzanie isLoggedIn przed dostępem
- **Przekierowania**: Automatyczne przekierowanie na login
- **Session handling**: Integracja z AuthProvider
- **State persistence**: Zachowanie stanu nawigacji

### Walidacja Dostępu
```dart
// Publiczne trasy (dostępne bez logowania)
final publicPaths = [
  AppRoutes.login,
  AppRoutes.register,
];

// Sprawdzanie uprawnień
if (!isAuthenticated && !isPublicPath) {
  return AppRoutes.login;
}
```

## Wydajność

### Optymalizacje
- **Lazy Loading**: Ekrany ładowane na żądanie
- **State Management**: Efektywne zarządzanie stanem nawigacji
- **Memory Management**: Proper disposal of resources
- **Animation Performance**: Smooth 60fps transitions

### Caching
- **Route State**: Zachowywanie stanu tras
- **Screen State**: Persistent data między nawigacją
- **User Preferences**: Zapisywanie ustawień nawigacji

## Rozszerzalność

System został zaprojektowany z myślą o łatwym rozszerzaniu:

### Dodawanie Nowych Sekcji

1. **Dodaj nową trasę**:
```dart
static const String newSection = '/new-section';
```

2. **Utwórz screen component**:
```dart
class NewSectionScreen extends StatelessWidget {
  // Implementation
}
```

3. **Dodaj do routingu**:
```dart
GoRoute(
  path: AppRoutes.newSection,
  builder: (context, state) => const NewSectionScreen(),
),
```

4. **Dodaj do nawigacji**:
```dart
NavigationItem(
  icon: Icons.new_icon,
  label: 'Nowa Sekcja',
  route: AppRoutes.newSection,
),
```

### Sub-Routes
Możliwość dodawania pod-tras dla szczegółowych widoków:

```dart
GoRoute(
  path: AppRoutes.newSection,
  builder: (context, state) => const NewSectionScreen(),
  routes: [
    GoRoute(
      path: 'details/:id',
      builder: (context, state) => DetailsScreen(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

## Migracja z Poprzedniej Wersji

### Zmiany w Navigation Calls

**Poprzednio:**
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

**Obecnie:**
```dart
context.go(AppRoutes.newRoute);
// lub
context.push(AppRoutes.newRoute);
```

### Aktualizacja main.dart

**Poprzednio:**
```dart
MaterialApp(
  home: AuthWrapper(),
)
```

**Obecnie:**
```dart
MaterialApp.router(
  routerConfig: AppRouter.router,
)
```

## Testowanie

### Unit Tests
```dart
testWidgets('Navigation test', (WidgetTester tester) async {
  // Test nawigacji między ekranami
  // Weryfikacja przekierowań autoryzacji
  // Sprawdzanie responsywności
});
```

### Integration Tests
```dart
// Testy pełnych przepływów nawigacyjnych
// Sprawdzanie state persistence
// Performance benchmarks
```

## Najlepsze Praktyki

### 1. Używaj Named Routes
```dart
// Dobrze
context.go(AppRoutes.dashboard);

// Unikaj
context.go('/dashboard');
```

### 2. Zarządzanie State
```dart
// Używaj Provider dla global state
// Local state tylko dla UI specifics
// Cleanup w dispose methods
```

### 3. Error Handling
```dart
// Zawsze obsłuż błędy nawigacji
// Fallback routes dla nieprawidłowych URL
// User feedback dla błędów
```

### 4. Performance
```dart
// Lazy load heavy screens
// Preload krytyczne dane
// Debounce rapid navigation calls
```

## Debugowanie

### Routing Logs
```dart
// Enable routing logs w debug mode
GoRouter.routerDelegate.debugLogEnabled = true;
```

### Common Issues
1. **Redirect loops**: Sprawdź logikę w redirect function
2. **State loss**: Upewnij się o proper Provider scope
3. **Performance**: Monituj rebuild cycles
4. **Deep links**: Test URL handling

---

**Podsumowanie**: Nowy system routingu oferuje nowoczesne, skalowalne i wydajne zarządzanie nawigacją z pełną integracją autoryzacji, responsywnym designem i gotowością na przyszłe rozszerzenia.

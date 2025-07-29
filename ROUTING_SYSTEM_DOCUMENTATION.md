# 🚀 Nowoczesny System Routingu - Cosmopolitan Investment

## 📋 Przegląd Systemu

Aplikacja **Metropolitan Investment** została wyposażona w nowoczesny, zaawansowany system routingu oparty na **go_router**, który zastępuje tradycyjną nawigację. System oferuje:

- 🎯 **Deklaratywne zarządzanie trasami** z typowanymi parametrami
- 🔐 **Zintegrowaną autoryzację** z automatycznymi przekierowaniami
- 🏗️ **Shell routing** dla wspólnego layoutu
- 📱 **Pełną responsywność** (mobile/tablet/desktop)
- ⚡ **Płynne animacje** przejść między ekranami
- 🛡️ **Bezpieczną nawigację** z walidacją tras
- 🔧 **Łatwą rozszerzalność** dla nowych funkcji

---

## 🗺️ Mapa Tras Aplikacji

### 📊 **Architektura Nawigacji**

```
🏠 ROOT (/)
├── 🔐 Autoryzacja
│   ├── /login              # Logowanie z "Zapamiętaj mnie"
│   ├── /register           # Rejestracja nowych użytkowników
│   └── /forgot-password    # Reset hasła
│
└── 🏢 Główna Aplikacja (wymaga autoryzacji)
    ├── 📈 /dashboard       # Dashboard z kluczowymi metrykami
    ├── 💰 /investments     # Portfel inwestycji
    │   ├── /add           # Dodanie nowej inwestycji
    │   ├── /:id           # Szczegóły inwestycji
    │   └── /:id/edit      # Edycja inwestycji
    ├── 👥 /clients        # Baza klientów
    │   ├── /add           # Nowy klient
    │   ├── /:id           # Profil klienta
    │   └── /:id/edit      # Edycja klienta
    ├── 📦 /products       # Produkty inwestycyjne
    │   ├── /:id           # Szczegóły produktu
    │   └── /add           # Nowy produkt
    ├── 🏢 /companies      # Zarządzanie spółkami
    │   ├── /:id           # Profil spółki
    │   └── /add           # Nowa spółka
    ├── 👨‍💼 /employees      # Zespół i organizacja
    │   ├── /:id           # Profil pracownika
    │   └── /add           # Nowy pracownik
    ├── 📊 /analytics      # Zaawansowane analizy
    ├── 👥 /investor-analytics # Analiza inwestorów
    ├── 👤 /profile        # Profil użytkownika
    ├── ⚙️ /settings       # Ustawienia aplikacji
    ├── 📄 /reports        # Raporty i eksporty
    └── 🔔 /notifications  # Powiadomienia
```

---

## 🏗️ Komponenty Systemu

### 1. **🎯 AppRoutes** - Definicje tras
```dart
class AppRoutes {
  // Publiczne trasy
  static const String login = '/login';
  static const String register = '/register';
  
  // Główne sekcje
  static const String dashboard = '/dashboard';
  static const String investments = '/investments';
  // ... więcej tras
  
  // Metody pomocnicze
  static String investmentDetailsPath(String id) => '/investments/$id';
  static String editInvestmentPath(String id) => '/investments/$id/edit';
}
```

### 2. **🧭 MainNavigationItems** - Elementy nawigacji
```dart
class MainNavigationItems {
  static final List<NavigationItem> items = [
    NavigationItem(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    // ... więcej elementów
  ];
}
```

### 3. **🏠 MainLayout** - Główny layout z nawigacją
- **NavigationRail** z rozwijaniem/zwijaniem
- **Menu użytkownika** z pełną funkcjonalnością  
- **Responsywny design** dla wszystkich urządzeń
- **FAB** z szybkimi akcjami (tablet/desktop)

### 4. **🛡️ Ochrona tras** - Autoryzacja i przekierowania
```dart
redirect: (context, state) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final isAuthenticated = authProvider.isLoggedIn;
  
  if (!isAuthenticated && !isPublicRoute) {
    return AppRoutes.login;  // Przekierowanie na login
  }
  
  if (isAuthenticated && isPublicRoute) {
    return AppRoutes.dashboard;  // Przekierowanie dla zalogowanych
  }
  
  return null; // Brak przekierowania
}
```

---

## 🎨 Funkcjonalności UI/UX

### **📱 Responsywność**

#### Mobile (< 768px)
- Kompaktowa nawigacja z ikonami
- Swipe gestures dla przejść
- Touch-optimized interface
- Single-column layouts

#### Tablet (768px - 1024px)  
- Dwukolumnowy layout
- Rozszerzona nawigacja z etykietami
- FAB z quick actions
- Touch + mouse support

#### Desktop (> 1024px)
- Pełna nawigacja z opisami
- Multi-kolumnowe widoki
- Hover effects
- Keyboard shortcuts

### **⚡ Animacje i Przejścia**

```dart
// Animowane przejścia między ekranami
CustomTransitionPage<void>(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut))
      ),
      child: child,
    );
  },
  transitionDuration: Duration(milliseconds: 300),
)
```

### **🎯 Menu Użytkownika**

- **Avatar użytkownika** z inicjałami
- **Informacje o profilu** (imię, email, rola)
- **Szybki dostęp** do ustawień
- **Bezpieczne wylogowanie** z opcjami

---

## 🔧 Użycie w Kodzie

### **Podstawowa nawigacja**
```dart
// Przejście do sekcji
context.go(AppRoutes.dashboard);
context.go(AppRoutes.investments);

// Przejście z parametrami
context.go(AppRoutes.investmentDetailsPath('inv-123'));
context.goToInvestmentDetails('inv-123');  // Extension method

// Powrót
context.pop();

// Zastąpienie aktualnej trasy
context.pushReplacement(AppRoutes.login);
```

### **Rozszerzenia dla łatwiejszej nawigacji**
```dart
extension BuildContextRouterExtensions on BuildContext {
  void goToInvestmentDetails(String id) {
    go(AppRoutes.investmentDetailsPath(id));
  }
  
  void goToEditInvestment(String id) {
    go(AppRoutes.editInvestmentPath(id));
  }
  
  bool isCurrentRoute(String route) {
    final currentRoute = GoRouterState.of(this).matchedLocation;
    return currentRoute == route;
  }
}
```

### **Sprawdzanie aktywnej trasy**
```dart
// W widgetach
final isInvestments = context.isInSection(AppRoutes.investments);
final isDashboard = context.isCurrentRoute(AppRoutes.dashboard);

// Aktywny element nawigacji
final activeItem = MainNavigationItems.getActiveItem(currentRoute);
final activeIndex = MainNavigationItems.getActiveIndex(currentRoute);
```

---

## 🛡️ Bezpieczeństwo i Autoryzacja

### **Ochrona tras**
- **Automatyczne przekierowania** na login dla niezalogowanych
- **Session validation** przy każdej nawigacji
- **Role-based access** (przygotowane na przyszłość)
- **Deep link protection** - bezpieczne URL-e

### **Stan autoryzacji**
```dart
redirect: (context, state) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // Sprawdzenie stanu ładowania
  if (authProvider.isLoading || authProvider.isInitializing) {
    return null; // Czekaj na inicjalizację
  }
  
  // Logika przekierowań
  final isAuthenticated = authProvider.isLoggedIn;
  final isPublicRoute = AppRoutes.isPublicRoute(state.matchedLocation);
  
  if (!isAuthenticated && !isPublicRoute) {
    return AppRoutes.login;
  }
  
  return null;
}
```

### **Zarządzanie sesjami**
- **Remember Me** - długotrwałe sesje
- **Auto-logout** po wygaśnięciu
- **Secure storage** dla tokenów
- **Multi-device** synchronization

---

## 🚀 Wydajność i Optymalizacja

### **Lazy Loading**
```dart
// Ekrany ładowane na żądanie
GoRoute(
  path: AppRoutes.analytics,
  pageBuilder: (context, state) => _buildPageWithTransition(
    context,
    state,
    const AnalyticsScreen(), // Loaded only when accessed
  ),
),
```

### **State Management**
- **Persistent navigation state** między sesjami
- **Optimized rebuilds** tylko dla aktywnych tras
- **Memory management** z proper disposal
- **Background loading** dla kluczowych danych

### **Caching i Performance**
- **Route state caching** dla szybszych przejść
- **Image preloading** dla głównych sekcji
- **Data prefetching** w tle
- **60fps animations** z GPU acceleration

---

## 🔄 Migracja z Poprzedniej Wersji

### **Zmiany w Navigation Calls**

**❌ Poprzednio:**
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => InvestmentScreen()),
);
```

**✅ Obecnie:**
```dart
context.go(AppRoutes.investments);
// lub z extension methods
context.goToInvestments();
```

### **Aktualizacja main.dart**

**❌ Poprzednio:**
```dart
MaterialApp(
  home: MainScreen(),
  routes: {...},
)
```

**✅ Obecnie:**
```dart
MaterialApp.router(
  routerConfig: AppRouter.router,
)
```

---

## 🧪 Testowanie

### **Unit Tests**
```dart
testWidgets('Navigation should work correctly', (WidgetTester tester) async {
  // Test podstawowej nawigacji
  await tester.pumpWidget(MyApp());
  
  // Tap na element nawigacji
  await tester.tap(find.byIcon(Icons.trending_up));
  await tester.pumpAndSettle();
  
  // Verify new route
  expect(find.byType(InvestmentsScreen), findsOneWidget);
});
```

### **Integration Tests**
```dart
// Test pełnych przepływów nawigacyjnych
group('Navigation Flow Tests', () {
  testWidgets('Login -> Dashboard -> Investments flow', (tester) async {
    // Test complete user journey
  });
  
  testWidgets('Deep link handling', (tester) async {
    // Test URL-based navigation
  });
});
```

---

## ⚙️ Konfiguracja i Dostosowanie

### **Dodawanie nowych tras**

1. **Dodaj trasę do AppRoutes:**
```dart
static const String newSection = '/new-section';
static const String newSectionDetails = '/new-section/:id';
```

2. **Utwórz screen component:**
```dart
class NewSectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
}
```

3. **Dodaj do routingu:**
```dart
GoRoute(
  path: AppRoutes.newSection,
  pageBuilder: (context, state) => _buildPageWithTransition(
    context,
    state,
    const NewSectionScreen(),
  ),
  routes: [
    GoRoute(
      path: ':id',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context,
        state,
        NewSectionDetailsScreen(
          id: state.pathParameters['id']!,
        ),
      ),
    ),
  ],
),
```

4. **Dodaj do nawigacji:**
```dart
NavigationItem(
  route: AppRoutes.newSection,
  label: 'Nowa Sekcja',
  icon: Icons.new_icon,
  selectedIcon: Icons.new_icon_selected,
),
```

### **Customizacja animacji**
```dart
// Custom transition
static Page<void> _buildCustomTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade transition
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
```

---

## 🐛 Debugowanie i Rozwiązywanie Problemów

### **Włączenie logowania routingu**
```dart
// W debug mode
GoRouter.routerDelegate.debugLogEnabled = true;
```

### **Typowe problemy**

| Problem | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| **Redirect loops** | Błędna logika w redirect function | Sprawdź warunki autoryzacji |
| **State loss** | Nieprawidłowy Provider scope | Upewnij się o correct context |
| **Slow transitions** | Ciężkie widget rebuilds | Optymalizuj widget tree |
| **Deep links fail** | Brak obsługi parametrów | Sprawdź path parameters |

### **Narzędzia debugowania**
```dart
// Current route info
final currentRoute = GoRouterState.of(context).matchedLocation;
final pathParams = GoRouterState.of(context).pathParameters;
final queryParams = GoRouterState.of(context).queryParameters;

print('Current route: $currentRoute');
print('Path params: $pathParams');
print('Query params: $queryParams');
```

---

## 📈 Przyszłe Rozszerzenia

### **Planowane funkcjonalności**
- 🔐 **Role-based routing** - różne trasy dla różnych ról
- 🌐 **Multi-language URLs** - lokalizowane adresy
- 📊 **Analytics tracking** - automatyczne śledzenie nawigacji
- 🔄 **Offline routing** - obsługa trybu offline
- 📱 **PWA support** - Progressive Web App routing
- 🎯 **Smart preloading** - inteligentne ładowanie tras

### **Przygotowane hooks**
```dart
// Przygotowane na role-based access
NavigationItem(
  requiresPermission: true,
  permission: 'admin',
  // ...
),

// Przygotowane na badges/notifications
NavigationItem(
  badge: '5', // Notification count
  // ...
),
```

---

## ✅ Podsumowanie

Nowy system routingu w **Metropolitan Investment** oferuje:

🎯 **Nowoczesną architekturę** - Zgodną z najlepszymi praktykami Flutter  
🔐 **Pełną integrację z autoryzacją** - Bezpieczna nawigacja  
📱 **Responsywny design** - Działający na wszystkich urządzeniach  
⚡ **Wysoką wydajność** - Optymalizowane przejścia i ładowanie  
🔧 **Łatwą rozszerzalność** - Gotową na przyszłe funkcjonalności  
🛡️ **Bezpieczeństwo** - Chronione trasy i walidacja  
🧪 **Testowalność** - Łatwe unit i integration testing  

System jest gotowy do użycia w produkcji i stanowi solidną podstawę dla dalszego rozwoju aplikacji.

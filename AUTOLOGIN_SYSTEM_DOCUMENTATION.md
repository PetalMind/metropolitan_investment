# System Zarządzania Autologowaniem - Dokumentacja

## Przegląd

System zarządzania autologowaniem w aplikacji Cosmopolitan Investment został znacznie ulepszony aby zapewnić lepsze doświadczenie użytkownika oraz bezpieczeństwo. System wykorzystuje kombinację Firebase Authentication, SharedPreferences oraz zaawansowane zarządzanie stanem.

## Nowe Funkcjonalności

### 1. 🔐 Inteligentny Autologin
- **Zapamiętywanie logowania**: Użytkownicy mogą wybrać opcję "Zapamiętaj mnie"
- **Automatyczne uzupełnianie**: Ostatni używany email jest automatycznie uzupełniany
- **Zarządzanie sesją**: Inteligentne zarządzanie czasem wygaśnięcia sesji
- **Bezpieczne przechowywanie**: Wszystkie preferencje są bezpiecznie przechowywane lokalnie

### 2. 🚪 Ulepszone Wylogowanie
- **Opcjonalne czyszczenie danych**: Użytkownik może wybrać czy wyczyścić zapisane dane
- **Automatyczne przekierowanie**: Natychmiastowe przekierowanie na ekran logowania
- **Zarządzanie pamięcią**: Czyste wyczyszczenie stanu aplikacji

### 3. 🎮 Lepsze Zarządzanie Stanem
- **Rozdzielone stany ładowania**: `isLoading` vs `isInitializing`
- **Lepsze UX**: Użytkownik widzi odpowiednie komunikaty w każdym stanie
- **Płynne przejścia**: Brak migotania podczas zmiany stanów

## Architektura

### UserPreferencesService

```dart
class UserPreferencesService {
  // Singleton pattern dla globalnego dostępu
  static UserPreferencesService? _instance;
  
  // Główne funkcjonalności:
  - setRememberMe(bool) / getRememberMe()
  - setLastEmail(String) / getLastEmail()
  - setAutoLoginEnabled(bool) / getAutoLoginEnabled()
  - isSessionExpired() / shouldAutoLogin()
  - clearAuthPreferences()
}
```

**Kluczowe metody:**
- `shouldAutoLogin()`: Sprawdza czy autologin powinien być wykonany
- `saveLoginPreferences()`: Zapisuje preferencje po udanym logowaniu
- `getSavedLoginData()`: Pobiera dane do auto-uzupełniania formularza

### Ulepszony AuthService

```dart
class AuthService {
  // Nowe metody:
  - signIn(..., rememberMe: bool)  // Z obsługą zapamiętywania
  - signOut(clearRememberMe: bool) // Z opcją czyszczenia
  - shouldAutoLogin()              // Sprawdzenie czy auto-login
  - getLastSavedEmail()           // Pobranie ostatniego emaila
}
```

### Ulepszony AuthProvider

```dart
class AuthProvider {
  // Nowe właściwości:
  bool isInitializing;  // Stan inicjalizacji (oddzielny od ładowania)
  
  // Nowe metody:
  - signIn(..., rememberMe: bool)
  - signOut(clearRememberMe: bool)
  - getSavedLoginData()
  - shouldAutoLogin()
}
```

## Przepływ Procesów

### 1. Proces Logowania

```
1. Użytkownik otwiera aplikację
2. AuthWrapper sprawdza stan autoryzacji
3. Jeśli isInitializing=true -> pokazuje AuthLoadingScreen
4. Jeśli użytkownik nie zalogowany -> LoginScreen
5. LoginScreen automatycznie ładuje zapisane dane
6. Użytkownik loguje się (opcjonalnie z "Zapamiętaj mnie")
7. System zapisuje preferencje jeśli zaznaczono
8. Przekierowanie do głównej aplikacji
```

### 2. Proces Wylogowania

```
1. Użytkownik klika "Wyloguj"
2. Pojawia się dialog z opcjami:
   - "Wyczyść zapisane dane logowania" (checkbox)
3. Po potwierdzeniu:
   - signOut(clearRememberMe: selectedOption)
   - Czyszczenie stanu aplikacji
   - Przekierowanie na LoginScreen
4. LoginScreen może nadal pokazać ostatni email (jeśli nie wyczyszczono)
```

### 3. Autologin przy Starcie

```
1. App starts -> AuthProvider._initializeAuth()
2. Firebase authStateChanges triggers
3. Jeśli user != null && shouldAutoLogin() == true:
   - Automatyczne zalogowanie
   - Ładowanie profilu użytkownika
   - Przekierowanie do głównej aplikacji
4. W przeciwnym razie -> LoginScreen
```

## Bezpieczeństwo

### Zarządzanie Sesjami
- **Timeout sesji**: Domyślnie 30 dni dla "Zapamiętaj mnie"
- **Automatyczne wygaśnięcie**: Sprawdzanie czy sesja jest aktualna
- **Bezpieczne przechowywanie**: Wykorzystanie SharedPreferences (szyfrowane na iOS/Android)

### Ochrona Danych
- **Minimalne dane**: Przechowywane są tylko email i flagi preferencji
- **Brak haseł**: Hasła nigdy nie są przechowywane lokalnie
- **Opcjonalne czyszczenie**: Użytkownik kontroluje kiedy dane są usuwane

## Konfiguracja

### Parametry Sesji

```dart
// W UserPreferencesService można dostosować:
static const String _sessionTimeoutKey = 'session_timeout';

// Domyślne wartości:
- Session timeout: 30 dni (43200 minut)
- Auto login: enabled (true)
- Biometric auth: disabled (false, przygotowane na przyszłość)
```

### Routing Guards

```dart
// W AppRouter redirect logic:
- isLoading || isInitializing -> null (no redirect)
- !authenticated && !publicPath -> login
- authenticated && publicPath -> main
```

## Użycie w Kodzie

### Logowanie z Remember Me

```dart
final success = await authProvider.signIn(
  email,
  password,
  rememberMe: _rememberMe, // Z checkboxa UI
);
```

### Wylogowanie z Opcjami

```dart
await authProvider.signOut(
  clearRememberMe: clearSavedData, // Z dialog checkboxa
);
```

### Sprawdzenie Zapisanych Danych

```dart
final savedData = await authProvider.getSavedLoginData();
// Zwraca: {rememberMe, lastEmail, autoLoginEnabled, sessionExpired, shouldAutoLogin}
```

## Testowanie

### Scenariusze Testowe

1. **Pierwszy login**:
   - Login bez "Zapamiętaj mnie" -> dane nie zapisane
   - Login z "Zapamiętaj mnie" -> email zapisany

2. **Ponowne otwarcie aplikacji**:
   - Z remember me -> autologin lub auto-fill emaila
   - Bez remember me -> czysty formularz

3. **Wylogowanie**:
   - Bez czyszczenia -> email pozostaje do następnego razu
   - Z czyszczeniem -> wszystkie dane usunięte

4. **Wygaśnięcie sesji**:
   - Po 30 dniach -> automatyczne wylogowanie
   - Sprawdzenie przy każdym uruchomieniu

## Migracja z Poprzedniej Wersji

System jest w pełni backward-compatible:
- Istniejące sessje Firebase pozostają aktywne
- Brak zapisanych preferencji = zachowanie jak wcześniej
- Stopniowe wprowadzanie nowych funkcji

## Przyszłe Rozszerzenia

System przygotowany na:
- **Biometric authentication** (Face ID, Touch ID, Fingerprint)
- **Multi-account support** 
- **Advanced session management**
- **Security policies** (force logout, password policies)

---

## Quick Reference

| Akcja | Metoda | Opis |
|-------|--------|------|
| Login z remember me | `authProvider.signIn(email, password, rememberMe: true)` | Loguje i zapisuje preferencje |
| Wylogowanie z czyszczeniem | `authProvider.signOut(clearRememberMe: true)` | Wylogowuje i czyści dane |
| Sprawdź czy autologin | `authProvider.shouldAutoLogin()` | Bool czy wykonać autologin |
| Pobierz zapisane dane | `authProvider.getSavedLoginData()` | Map z preferencjami |
| Wyczyść preferencje | `preferencesService.clearAuthPreferences()` | Czyści dane auth |

System zapewnia intuicyjne i bezpieczne zarządzanie autoryzacją z pełną kontrolą użytkownika nad zapisywanymi danymi.

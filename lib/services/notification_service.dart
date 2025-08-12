import 'package:flutter/material.dart';

/// Service do zarządzania powiadomieniami w aplikacji
/// Używany do wyświetlania badge'ów w sidebarze i innych miejscach
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Liczniki powiadomień dla różnych sekcji
  int _calendarNotifications = 0;
  int _clientNotifications = 0;
  int _analyticsNotifications = 0;
  int _generalNotifications = 0;

  // Getters
  int get calendarNotifications => _calendarNotifications;
  int get clientNotifications => _clientNotifications;
  int get analyticsNotifications => _analyticsNotifications;
  int get generalNotifications => _generalNotifications;
  int get totalNotifications =>
      _calendarNotifications +
      _clientNotifications +
      _analyticsNotifications +
      _generalNotifications;

  // Metody do aktualizacji powiadomień
  void updateCalendarNotifications(int count) {
    if (_calendarNotifications != count) {
      _calendarNotifications = count;
      notifyListeners();
    }
  }

  void updateClientNotifications(int count) {
    if (_clientNotifications != count) {
      _clientNotifications = count;
      notifyListeners();
    }
  }

  void updateAnalyticsNotifications(int count) {
    if (_analyticsNotifications != count) {
      _analyticsNotifications = count;
      notifyListeners();
    }
  }

  void updateGeneralNotifications(int count) {
    if (_generalNotifications != count) {
      _generalNotifications = count;
      notifyListeners();
    }
  }

  // Czyszczenie powiadomień
  void clearCalendarNotifications() {
    updateCalendarNotifications(0);
  }

  void clearClientNotifications() {
    updateClientNotifications(0);
  }

  void clearAnalyticsNotifications() {
    updateAnalyticsNotifications(0);
  }

  void clearGeneralNotifications() {
    updateGeneralNotifications(0);
  }

  void clearAllNotifications() {
    _calendarNotifications = 0;
    _clientNotifications = 0;
    _analyticsNotifications = 0;
    _generalNotifications = 0;
    notifyListeners();
  }

  // Pobierz liczbę powiadomień dla konkretnej trasy
  int getNotificationsForRoute(String route) {
    switch (route) {
      case '/calendar':
        return _calendarNotifications;
      case '/clients':
        return _clientNotifications;
      case '/analytics':
      case '/investor-analytics':
        return _analyticsNotifications;
      default:
        return 0;
    }
  }

  // Czy są jakieś powiadomienia dla trasy
  bool hasNotificationsForRoute(String route) {
    return getNotificationsForRoute(route) > 0;
  }
}

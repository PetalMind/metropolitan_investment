# 🚀 EMAIL & EXPORT - DEPLOYMENT GUIDE

## 📋 STAN AKTUALNY

### ✅ CO JEST GOTOWE:
- **Backend Services**: Email (DEV mode) + Export (pełna wersja)
- **Flutter Integration**: EmailAndExportService z type-safe models
- **UI Components**: InvestorEmailDialog + InvestorExportDialog
- **Multi-Selection**: Premium Analytics z batch operations

### ⚠️ ROZWIĄZANY PROBLEM:
**Błąd**: `Cannot find module 'nodemailer'`  
**Rozwiązanie**: Użyto email-service-dev.js (mock version) zamiast email-service.js

## 🔧 KROKI DEPLOYMENT

### 1. Instalacja Dependencies (Wymagane!)
```bash
cd functions
npm install
npm install nodemailer@^6.9.0
```

### 2. Deploy Firebase Functions
```bash
firebase deploy --only functions
```

### 3. Test Funkcjonalności
```bash
# Flutter app
flutter pub get
flutter run
```

## 🎯 TESTOWANIE EMAIL & EXPORT

### A. Email Functionality (DEV Mode)
1. Otwórz **Premium Analytics**
2. Kliknij **"Akcje" → "Wybór wielu inwestorów"**
3. Wybierz kilku inwestorów (checkboxes)
4. Kliknij **Floating Action Button → Email**
5. Wypełnij formularz email:
   - ✅ Twój email
   - ✅ Szablon (Summary/Detailed/Custom)
   - ✅ Temat i dodatkową wiadomość
6. Kliknij **"Wyślij Email"**
7. **Wynik**: Mock email z warning DEV MODE ⚠️

### B. Export Functionality
1. W tym samym trybie selection
2. Kliknij **FAB → Export**
3. Wybierz opcje eksportu:
   - ✅ Format: CSV/JSON/Excel
   - ✅ Sortowanie i filtrowanie
   - ✅ Zawartość: kontakty, inwestycje, statystyki
4. Kliknij **"Eksportuj"**
5. **Wynik**: Plik do pobrania z danymi

### C. Multi-Selection UI
1. **Normal mode**: Standardowe karty/lista/tabela
2. **Selection mode**: Checkboxes + visual feedback
3. **Select All/Clear**: Batch selection controls
4. **Visual indicators**: Highlighting, borders, icons
5. **Context switching**: AppBar zmienia tytuł i info

## 🔄 PRZEJŚCIE NA PRODUCTION EMAIL

### 1. Zainstaluj nodemailer
```bash
cd functions
npm install nodemailer@^6.9.0
```

### 2. Zmień import w index.js
```javascript
// Z:
const emailService = require("./services/email-service-dev");

// Na:
const emailService = require("./services/email-service");
```

### 3. Skonfiguruj SMTP
```bash
firebase functions:config:set \
  email.smtp_host="smtp.gmail.com" \
  email.smtp_port="587" \
  email.smtp_user="your-email@gmail.com" \
  email.smtp_password="your-app-password"
```

### 4. Deploy production version
```bash
firebase deploy --only functions
```

## 📧 KONFIGURACJA SMTP

### Gmail Setup
1. Włącz **2-Step Verification**
2. Wygeneruj **App Password**:
   - Google Account → Security → App passwords
   - App: Mail, Device: Other (Firebase Functions)
3. Użyj App Password w konfiguracji

### Alternative SMTP Providers
- **SendGrid**: Professional email service
- **Mailgun**: Developer-friendly API
- **AWS SES**: Amazon Simple Email Service
- **Outlook**: Microsoft SMTP

## 🚨 TROUBLESHOOTING

### Problem: "Cannot find module 'nodemailer'"
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm install nodemailer@^6.9.0
```

### Problem: SMTP Authentication Failed  
```bash
# Sprawdź konfigurację
firebase functions:config:get

# Zaktualizuj credentials
firebase functions:config:set email.smtp_password="NEW_APP_PASSWORD"
```

### Problem: Email nie dochodzi
1. **Sprawdź spam folder**
2. **Verify SMTP settings** (host, port, credentials)
3. **Check Firebase Functions logs**: `firebase functions:log`
4. **Test z Gmail/Outlook** first

### Problem: Export nie działa
1. **Firestore rules**: Upewnij się że funkcja ma dostęp do `investments`
2. **Large datasets**: Export max 1000 klientów jednocześnie
3. **Memory limits**: Sprawdź czy funkcja nie przekracza limitu pamięci

## 📊 MONITORING & LOGS

### Firebase Console
- **Functions**: Monitoring, logs, performance
- **Firestore**: Usage, query performance
- **Authentication**: User activity

### Debugging Commands
```bash
# Functions logs
firebase functions:log

# Local emulator
firebase emulators:start --only functions

# Test specific function
firebase functions:shell
```

## 🎉 SUCCESS CRITERIA

### ✅ Email Working When:
- Mock emails generate in DEV mode ⚠️
- Production emails deliver to inbox ✉️
- History saved in `email_history` collection 📝
- Error handling works (invalid emails, SMTP failures) 🛡️

### ✅ Export Working When:
- CSV files download with proper encoding 📄
- JSON exports with structured data 🗂️
- Excel files (currently CSV with .xlsx extension) 📊
- Filtering and sorting works correctly 🔍

### ✅ UI Working When:
- Multi-selection mode toggles smoothly 🎛️
- Visual feedback clear (checkboxes, highlighting) 👁️
- Batch operations work on selected items 🔄
- Context switching (normal ↔ selection) intuitive 🔄

---

**Status**: ✅ **READY FOR TESTING**  
**Next**: Install nodemailer → Configure SMTP → Deploy production

🚀 **Happy Testing!**

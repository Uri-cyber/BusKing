# 📱 BusAlert Mobile App (Flutter)

<div dir="rtl">

אפליקציית Mobile ל-BusAlert - מערכת התרעות חכמה להגעת אוטובוסים בזמן אמת.

## 📋 תוכן עניינים

- [תכונות](#features)
- [דרישות](#requirements)
- [התקנה](#installation)
- [הרצה](#running)
- [מבנה הפרויקט](#structure)
- [תיעוד](#documentation)

---

## <a name="features"></a>✨ תכונות

### ✅ מומש

- **Authentication** - התחברות עם SMS verification
- **Home Screen** - רשימת מסלולים קבועים
- **Add Route** - הוספת מסלול חדש עם:
  - בחירת תחנה וקו
  - בחירת ימים ושעות
  - הגדרת זמן התרעה
- **Checklist Management** - ניהול צ'קליסט אישי
- **Settings** - הגדרות אפליקציה והתנתקות
- **State Management** - Provider לניהול state
- **API Integration** - חיבור מלא ל-Backend API
- **WebSocket** - תמיכה בעדכונים בזמן אמת
- **RTL Support** - תמיכה מלאה בעברית

### ⏳ בפיתוח

- Onboarding screens
- Active tracking screen
- Push Notifications
- GPS & Geofencing
- תרגום לשפות נוספות

---

## <a name="requirements"></a>⚙️ דרישות

- **Flutter SDK** >= 3.0.0
- **Dart SDK** >= 3.0.0
- **Android Studio** או **Xcode**
- **Backend API** רץ (ראה `/backend`)

---

## <a name="installation"></a>📦 התקנה

### 1. התקן Flutter

עקוב אחרי ההוראות ב-[flutter.dev](https://flutter.dev/docs/get-started/install)

### 2. Clone הפרויקט

```bash
git clone https://github.com/Uri-cyber/BusKing.git
cd BusKing/frontend/mobile
```

### 3. התקן Dependencies

```bash
flutter pub get
```

### 4. הגדר את ה-Backend URL

ערוך את `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://YOUR_IP:3000/api/v1';
static const String wsUrl = 'ws://YOUR_IP:3000/ws';
```

**שים לב:** אם אתה רץ על emulator:
- Android: השתמש ב-`10.0.2.2` במקום `localhost`
- iOS: השתמש ב-`localhost`

---

## <a name="running"></a>🚀 הרצה

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Web (אופציונלי)

```bash
flutter run -d chrome
```

---

## <a name="structure"></a>📁 מבנה הפרויקט

```
lib/
├── config/
│   ├── app_config.dart       # הגדרות כלליות
│   └── app_theme.dart         # ערכות נושא
├── models/
│   ├── user.dart              # User & UserSettings
│   ├── route.dart             # UserRoute
│   └── checklist_item.dart    # ChecklistItem
├── providers/
│   ├── auth_provider.dart     # ניהול authentication
│   ├── route_provider.dart    # ניהול מסלולים
│   └── checklist_provider.dart # ניהול צ'קליסט
├── screens/
│   ├── splash_screen.dart     # מסך פתיחה
│   ├── login_screen.dart      # התחברות
│   ├── verify_screen.dart     # אימות SMS
│   ├── home_screen.dart       # מסך ראשי
│   ├── add_route_screen.dart  # הוספת מסלול
│   ├── checklist_screen.dart  # ניהול צ'קליסט
│   └── settings_screen.dart   # הגדרות
├── services/
│   ├── api_service.dart       # שכבת API
│   └── websocket_service.dart # WebSocket
├── widgets/
│   └── route_card.dart        # כרטיס מסלול
└── main.dart                  # Entry point
```

---

## <a name="documentation"></a>📚 תיעוד

### Models

**User & UserSettings**
```dart
class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final UserSettings settings;
}
```

**UserRoute**
```dart
class UserRoute {
  final String id;
  final String stopId;
  final String routeNumber;
  final List<int> daysOfWeek;
  final String timeWindowStart;
  final String timeWindowEnd;
  final int alertMinutesBefore;
}
```

### Providers

**AuthProvider**
```dart
// התחברות
await authProvider.register(phoneNumber, name);
await authProvider.verify(phoneNumber, code);

// התנתקות
await authProvider.logout();

// בדיקת סטטוס
bool isAuthenticated = authProvider.isAuthenticated;
```

**RouteProvider**
```dart
// טעינת מסלולים
await routeProvider.loadRoutes();

// הוספת מסלול
await routeProvider.createRoute(routeData);

// מחיקת מסלול
await routeProvider.deleteRoute(routeId);

// הפעלה/כיבוי
await routeProvider.toggleRoute(routeId, true);
```

### API Service

```dart
final apiService = ApiService();

// Auth
await apiService.register(phoneNumber, name);
await apiService.verify(phoneNumber, code);
final user = await apiService.getProfile();

// Routes
final routes = await apiService.getRoutes();
await apiService.createRoute(routeData);
await apiService.deleteRoute(routeId);

// Checklist
final items = await apiService.getChecklist();
await apiService.createChecklistItem(name, emoji, context);
```

### WebSocket

```dart
final ws = WebSocketService();

// התחברות
ws.connect(token);

// האזנה לאירועים
ws.onBusUpdate = (data) {
  print('Bus ETA: ${data['eta_minutes']} minutes');
};

ws.onAlertTriggered = (data) {
  print('Alert: ${data['message']}');
};

// ניתוק
ws.disconnect();
```

---

## 🎨 Theme & Styling

האפליקציה משתמשת ב-Material Design 3 עם:
- תמיכה ב-RTL (Right-to-Left) לעברית
- Light theme (Dark theme מוכן אבל לא פעיל)
- גופן Heebo לעברית
- צבעים נגישים

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Widget tests
flutter test test/widget_test.dart
```

---

## 📱 Build for Production

### Android (APK)

```bash
flutter build apk --release
```

הקובץ יהיה ב-`build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

---

## 🐛 Troubleshooting

### בעיות נפוצות

**1. Cannot connect to backend**
```
ודא ש-Backend רץ ושה-URL נכון ב-app_config.dart
```

**2. WebSocket not connecting**
```
בדוק את ה-JWT token ושה-WebSocket server רץ
```

**3. SMS not received**
```
בדוק את הגדרות Twilio ב-Backend
```

---

## 📄 License

MIT License - ראה LICENSE בשורש הפרויקט

---

**Built with ❤️ using Flutter**

</div>

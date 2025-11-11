# 📘 BusAlert - אפיון מלא ומסמך טכני למפתח

<div dir="rtl">

**גרסה:** 1.0.2
**תאריך:** נובמבר 2025
**מחבר:** Uri Cyber - BusAlert Team

---

## 📑 תוכן עניינים

1. [סקירה כללית](#overview)
2. [הבעיה והפתרון](#problem-solution)
3. [פונקציונליות מפורטת](#features)
4. [ארכיטקטורה טכנית](#architecture)
5. [User Flow ומסכים](#screens)
6. [הוראות פיתוח למפתח](#dev-instructions)
7. [API ואינטגרציות](#api-integrations)
8. [טיימליין ואבני דרך](#timeline)

---

## <a name="overview"></a>1. סקירה כללית

### שם המוצר
**BusAlert** - מערכת התרעות חכמה להגעת אוטובוסים בזמן אמת

### Vision Statement
להפוך את הנסיעה בתחבורה ציבורית לחוויה חלקה ונטולת מתח, על ידי מתן מידע פרואקטיבי במקום ריאקטיבי.

### Target Audience
- נוסעים קבועים בתחבורה ציבורית (עובדים, סטודנטים)
- משתמשים בני 18-65
- בעלי סמארטפון עם אינטרנט
- משתמשי WhatsApp (90%+ משוק ישראל)

### Key Metrics (KPIs)

| מדד | יעד MVP | יעד 6 חודשים |
|-----|---------|--------------|
| דיוק התרעות | ≥ 90% | ≥ 95% |
| Daily Active Users | 200 | 2,000 |
| Retention (7 days) | 40% | 60% |
| זמן ממוצע חיסכון בהמתנה | ≥ 6 דקות | ≥ 8 דקות |
| NPS (שביעות רצון) | ≥ 40 | ≥ 60 |

---

## <a name="problem-solution"></a>2. הבעיה והפתרון

### 🔴 הבעיה הקיימת

1. **לפתוח אפליקציית תחבורה ציבורית שוב ושוב**
   - משתמשים צריכים לבדוק ידנית את זמני ההגעה
   - בזבוז זמן וסוללה

2. **אי ודאות - "האם כדאי לי לצאת עכשיו?"**
   - חוסר ודאות גורם לחרדה
   - יציאה מוקדמת מדי = המתנה בתחנה
   - יציאה מאוחרת = החמצת האוטובוס

3. **שכחת פריטים חשובים לפני יציאה מהבית**
   - טלפון, מפתחות, ארנק
   - מטריה בגשם, מים בחום

4. **חרדה מפני החמצת האוטובוס**
   - מתח קבוע לאורך הבוקר
   - פגיעה בפרודוקטיביות

5. **בזבוז זמן בתחנה בגלל מידע לא מדויק**
   - אוטובוסים מאחרים ללא התראה
   - ביטולים ללא הודעה מוקדמת

### 🟢 הפתרון שלנו

**BusAlert** מספקת מעקב פרואקטיבי אוטומטי עם:

- ✅ **התרעות מדורגות בזמן אמת** (10 דק' → 5 דק' → 2 דק')
- ✅ **צ'קליסט אישי דינמי** (לפי מזג אוויר ושעה)
- ✅ **אוטומציה מבוססת לו"ז** (הגדרת מסלולים קבועים)
- ✅ **אינטגרציה עם WhatsApp** (ללא צורך באפליקציה נוספת)
- ✅ **למידה חכמה של הרגלי נסיעה**

---

## <a name="features"></a>3. פונקציונליות מפורטת

### 3.1 Core Features (MVP)

#### A. מעקב אוטומטי אחר אוטובוס

**תיאור:** המשתמש מגדיר תחנה, קו ומועד נסיעה רגיל - המערכת עוקבת אוטומטית.

**User Story:**
> "כמשתמש, אני רוצה שהאפליקציה תעקוב אוטומטית אחרי קו 18 כל יום ב' ו-ד' בשעה 7:45, כדי שלא אצטרך לזכור להפעיל מעקב ידנית."

**תהליך:**
1. המשתמש מגדיר "מסלול קבוע"
2. המערכת מתעוררת אוטומטית בחלון הזמן שהוגדר
3. מתחילה polling לשרת GTFS-RT
4. מחשבת ETA (Estimated Time of Arrival)
5. שולחת התרעות מדורגות

**פרמטרים להגדרה:**
- תחנה (בחירה ממפה או מספר תחנה)
- מספר קו
- ימי שבוע (א'-ש' + בחירה מרובה)
- חלון זמן (למשל: 07:30-08:00)
- כמה דקות לפני להתריע (ברירת מחדל: 5 דקות)

**טכני:**
```typescript
interface UserRoute {
    stop_id: string;
    route_number: string;
    days_of_week: number[];  // [1,3,4] = Mon, Wed, Thu
    time_window_start: string; // "07:30"
    time_window_end: string;   // "08:00"
    alert_minutes_before: number; // 5
}
```

#### B. התרעות מדורגות חכמות

**תיאור:** במקום התרעה אחת, שלוש התרעות בשלבים שונים.

**שלושת השלבים:**

1. **שלב 1: התרעה ראשונית (10 דקות)**
   ```
   🚌 קו 18
   מגיע לתחנה רחוב הרצל בעוד 10 דקות
   ⏰ התרעה נוספת תגיע בעוד 5 דקות
   ```

2. **שלב 2: התרעה + צ'קליסט (5 דקות)**
   ```
   🚌 קו 18 מגיע בעוד 5 דקות!

   ✅ תזכורת - אל תשכח:
   1. 📱 טלפון
   2. 🔑 מפתחות
   3. 💳 ארנק
   4. ☂️ מטריה (גשום היום)

   🏃‍♂️ זמן לצאת!
   ```

3. **שלב 3: התרעה דחופה (2 דקות)**
   ```
   🚨 דחוף!
   קו 18 מגיע בעוד 2 דקות!
   🏃‍♂️ צא עכשיו!

   [👍 יצאתי] [⏭ דלג]
   ```

**Logic מיוחדת:**
- אם האוטובוס מאחר ב-5+ דקות → שלח עדכון
- אם האוטובוס בוטל → הצע אלטרנטיבות
- אם יש 2+ אוטובוסים באותו קו → התרעה על הראשון

**טכני:**
```typescript
enum AlertType {
    INITIAL = 'initial',      // 10 minutes
    CHECKLIST = 'checklist',  // 5 minutes
    URGENT = 'urgent',        // 2 minutes
    DELAYED = 'delayed',      // if delayed 5+ min
    CANCELLED = 'cancelled'   // if cancelled
}
```

#### C. צ'קליסט אישי ודינמי

**תיאור:** רשימה מותאמת אישית של פריטים לא לשכוח, שמשתנה לפי הקשר.

**סוגי צ'קליסט:**

1. **צ'קליסט בסיסי (קבוע):**
   - 📱 טלפון
   - 🔑 מפתחות
   - 💳 ארנק
   - 🎧 אוזניות

2. **צ'קליסט דינמי (לפי הקשר):**
   - ☂️ אם גשום → מטריה
   - 🥐 אם בוקר (05:00-12:00) → ארוחת בוקר
   - 💧 אם חם (+30°) → בקבוק מים
   - 🧥 אם ערב חורף → מעיל

3. **צ'קליסט מותאם אישית:**
   - המשתמש יכול להוסיף פריטים משלו
   - דוגמאות: "תרופות", "תיק ספורט", "משקפיים"

**אינטראקציה:**
- ב-WhatsApp: כפתורים ללחיצה (Quick Reply Buttons)
- ב-Push: רשימה פשוטה

**למידה חכמה (Future):**
> "שמתי לב שלעולם לא לוקח 'בקבוק מים', להסיר מהרשימה?"

**טכני:**
```typescript
interface ChecklistItem {
    item_name: string;
    emoji: string;
    context: 'always' | 'morning' | 'evening' | 'rainy' | 'hot' | 'cold';
    condition_value?: string; // e.g., "temp > 30"
}
```

#### D. אינטגרציה מלאה עם WhatsApp

**תיאור:** כל ההתרעות והשליטה דרך WhatsApp Business Cloud API.

**תכונות:**

1. **שליחת התרעות:**
   - הודעות טקסט עם אמוג'י
   - כפתורי Quick Reply
   - תמונות מפה (אופציונלי)

2. **שיחה דו-כיוונית**

3. **פקודות זמינות:**
   - "מתי קו X" - בדיקה ידנית
   - "עקוב קו X" - הפעלת מעקב חד פעמי
   - "הפסק" - עצירת מעקב
   - "מסלולים" - רשימת המסלולים הקבועים
   - "הגדרות" - לינק לאפליקציה

**Technical Implementation:**
- WhatsApp Business Cloud API (Meta)
- Webhooks לקבלת הודעות
- Template Messages לאישור

**טכני:**
```typescript
// WhatsApp message format
{
    messaging_product: "whatsapp",
    to: "+972501234567",
    type: "interactive",
    interactive: {
        type: "button",
        body: { text: "קו 18 מגיע בעוד 2 דקות!" },
        action: {
            buttons: [
                { type: "reply", reply: { id: "on_my_way", title: "👍 יצאתי" } }
            ]
        }
    }
}
```

#### E. זיהוי מיקום אוטומטי (Geofencing)

**תיאור:** האפליקציה מזהה באיזו תחנה אתה נמצא אוטומטית.

**תהליך:**
1. המשתמש מפעיל "מצא את התחנה הכי קרובה"
2. GPS מזהה מיקום (±50 מטר)
3. שאילתה למאגר תחנות
4. הצגה: "נראה שאתה בתחנה 3045 (רחוב הרצל/וייצמן), נכון?"
5. אישור → שמירה כתחנה מועדפת

**Geofencing חכם למעקב:**
- הגדרת "גדר וירטואלית" ברדיוס 200 מטר מהבית
- הפעלת GPS רק כשאתה בתוך הגדר בחלון הזמן
- חיסכון דרמטי בסוללה (60-80%)

**Settings:**
- הפעלה/כיבוי GPS
- דיוק מיקום (דיוק vs. חיסכון סוללה)
- אישור מיקום ידני

**טכני:**
```typescript
interface GeoFence {
    center: { lat: number; lon: number };
    radius: number; // meters
    time_window: { start: string; end: string };
}

// Haversine formula for distance calculation
function calculateDistance(
    lat1: number, lon1: number,
    lat2: number, lon2: number
): number
```

### 3.2 Advanced Features (Post-MVP)

#### F. למידה חכמה (ML-Based)

**תיאור:** המערכת לומדת את הרגלי הנסיעה ומציעה אוטומציה.

**דוגמאות:**

1. **זיהוי דפוס:**
   > "שמתי לב שכל יום ב' ו-ד' בשעה 7:45 אתה נוסע בקו 18 מתחנה 3045. רוצה שאגדיר מסלול אוטומטי?"

2. **חריגות:**
   > "בדרך כלל אתה יוצא ב-7:45, אבל היום זה כבר 7:50. עדיין לעקוב?"

3. **אופטימיזציה:**
   > "קו 18 לרוב מאחר ב-5 דקות. כדאי לצאת ב-7:50 במקום 7:45"

**Technical:**
- שמירת היסטוריית נסיעות
- אלגוריתם זיהוי דפוסים (סטטיסטי בסיסי)
- Optional: ML model למידול איחורים

#### G. שיתוף מיקום בזמן אמת

**תיאור:** שליחת לינק לחבר שיראה איפה אתה ואיפה האוטובוס.

**User Story:**
> "שלחתי לחבר שלי לינק והוא רואה שאני בדרך באוטובוס, עוד 10 דקות אגיע"

**תהליך:**
1. לחיצה על "שתף מיקום"
2. יצירת unique link (expires שעתיים)
3. שליחה ב-WhatsApp/SMS
4. הצופה רואה מפה עם:
   - 🚌 מיקום האוטובוס
   - 📍 מיקום המשתמש
   - 🏁 מיקום היעד
   - זמן משוער להגעה

**Privacy:**
- הלינק תקף רק לזמן מוגבל
- אפשר לבטל בכל רגע
- אין אחסון מיקום אחרי סיום הנסיעה

#### H. אינטגרציה עם יומן

**תיאור:** חיבור ליומן Google/Apple לזיהוי פגישות ואוטומציה.

**דוגמה:**
```
יומן: "פגישה ברחוב רוטשילד 22 ב-09:00"
→ BusAlert: "צריך לצאת ב-08:15 כדי להגיע ב-08:55"
→ התרעה אוטומטית ב-08:05
```

**Technical:**
- Google Calendar API / Apple Calendar
- חישוב reverse: מהיעד + זמן פגישה → מתי לצאת
- Optional: שילוב עם Waze/Google Maps למסלול מלא

#### I. סטטיסטיקות ותובנות

**תיאור:** מסך אישי עם נתונים על השימוש.

**נתונים:**
- כמה אוטובוסים תפסת החודש
- כמה זמן חסכת בהמתנה (vs. בלי האפליקציה)
- האוטובוס הכי פופולרי שלך
- זמן הממוצע שלך ליציאה מהבית
- דירוג דיוק התחזיות (Feedback loop)

**UI:**
- גרפים פשוטים
- Achievements: "🏆 תפסת 50 אוטובוסים!"

### 3.3 הגדרות ותכונות נוספות

#### מצב "שקט" בלילה
- אוטומטי: 22:00-06:00
- ניתן להתאמה אישית
- גם בשקט - שמירת התרעות בהיסטוריה

#### בחירת ערוץ התרעה
- WhatsApp (ברירת מחדל)
- Push Notification
- SMS (בתשלום)
- שילוב: WhatsApp + Push

#### שפות
- עברית (RTL)
- אנגלית
- ערבית (Future)

#### נגישות (Accessibility)
- תמיכה ב-Voice Over / TalkBack
- ניגודיות גבוהה
- גופנים גדולים

---

## <a name="architecture"></a>4. ארכיטקטורה טכנית

### 4.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                         │
├─────────────────────────────────────────────────────────┤
│   Mobile App     💬 WhatsApp      🌐 Web Dashboard      │
│ (Flutter/RN)   (Bot Interface)     (Admin Panel)        │
└───────────────┬─────────────────────────────────────────┘
                │
                │ REST API / WebSocket
                ↓
┌─────────────────────────────────────────────────────────┐
│                 API GATEWAY LAYER                       │
│           (Node.js + Express + TypeScript)              │
│   - Authentication (JWT)                                │
│   - Rate Limiting                                       │
│   - Request Routing                                     │
└───────────────┬─────────────────────────────────────────┘
                │
     ┌──────────┴──────────┐
     ↓                     ↓
┌──────────────┐     ┌──────────────┐
│  BUSINESS    │     │  REAL-TIME   │
│   LOGIC      │     │   TRACKING   │
│  SERVICE     │     │   SERVICE    │
│              │     │              │
│ - User Mgmt  │     │ - GTFS Poll  │
│ - Routes     │     │ - ETA Calc   │
│ - Checklist  │     │ - Alerts     │
│ - Settings   │     │ - WebSocket  │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └──────────┬─────────┘
                  ↓
┌─────────────────────────────────────────────────────────┐
│               INTEGRATION LAYER                         │
├─────────────────────────────────────────────────────────┤
│ 🚌 GTFS-RT API  💬 WhatsApp API  🌤 Weather API         │
│  (MOT Israel)    (Meta Cloud)    (OpenWeather)          │
│                                                          │
│ 📍 Maps API     📧 Notifications  📅 Calendar API       │
│ (Google Maps)   (FCM/APNS)       (Google/Apple)         │
└───────────────┬─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────────────────┐
│                    DATA LAYER                           │
├─────────────────────────────────────────────────────────┤
│ 💾 PostgreSQL   🔥 Redis        📦 S3/Storage           │
│  (User Data,    (Cache,         (Logs,                  │
│   Routes,       Sessions,       Analytics)              │
│   Checklist)    Real-time)                              │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Tech Stack המומלץ

#### Frontend

**אפליקציה ניידת:**
- **Framework:** Flutter (preferred) או React Native

**למה Flutter?**
- קוד אחד ל-iOS + Android
- ביצועים מעולים
- UI עשיר ומהיר לפיתוח
- תמיכה טובה ב-RTL (עברית)

**ספריות עיקריות:**
```yaml
dependencies:
  flutter_map: ^5.0.0           # Maps
  geolocator: ^10.1.0           # GPS
  socket_io_client: ^2.0.3      # WebSocket
  http: ^1.1.0                  # REST API
  provider: ^6.1.1              # State management
  shared_preferences: ^2.2.2    # Local storage
  firebase_messaging: ^14.7.6   # Push notifications
```

**Web Dashboard (Optional):**
- React.js + Tailwind CSS
- Admin panel בלבד

#### Backend

**Framework:** Node.js + Express.js + TypeScript

**למה Node.js?**
- מעולה ל-Real-time (WebSocket)
- אקוסיסטם עשיר
- Performance טוב ל-I/O intensive
- קל למצוא מפתחים

**Structure:**
```
backend/
├── src/
│   ├── config/       # Database, Redis, Logger
│   ├── controllers/  # Request handlers
│   ├── middleware/   # Auth, validation
│   ├── models/       # Database models
│   ├── routes/       # API routes
│   ├── services/     # Business logic
│   ├── types/        # TypeScript types
│   ├── utils/        # Helpers
│   └── index.ts      # Entry point
```

**Key Libraries:**
```json
{
  "express": "^4.18.2",
  "pg": "^8.11.3",
  "redis": "^4.6.10",
  "jsonwebtoken": "^9.0.2",
  "socket.io": "^4.6.2",
  "axios": "^1.6.2",
  "node-cron": "^3.0.3",
  "winston": "^3.11.0"
}
```

#### Database

**Primary Database:** PostgreSQL 14+

**למה PostgreSQL?**
- Relational data (users, routes, alerts)
- JSON support (JSONB) להגדרות
- גיאוגרפי (PostGIS extension)
- ACID compliance
- Open source

**Cache:** Redis 7+

**למה Redis?**
- מהיר מאוד (in-memory)
- Cache GTFS data
- Session management
- Real-time counters

**Structure:**
```sql
-- Main tables
users
user_routes
checklist_items
alert_history
tracking_sessions
gtfs_stops
gtfs_routes
verification_codes
shared_locations
```

### 4.3 APIs & Integrations

#### 1. GTFS-Realtime (משרד התחבורה)

**Endpoint:** `https://gtfs.mot.gov.il/gtfsrt/siri/vehicle_monitoring`

**תדירות:** כל 20 שניות

**שימוש:** נתוני מיקום בזמן אמת

**Example Request:**
```http
GET /gtfsrt/siri/vehicle_monitoring?LineRef=18&MonitoringRef=3045
```

**Response Format:** SIRI XML/JSON

#### 2. WhatsApp Business Cloud API

**Base URL:** `https://graph.facebook.com/v18.0`

**Endpoint:** `/{phone_number_id}/messages`

**Authentication:** Bearer token

**Example:**
```json
POST /{phone_number_id}/messages
{
  "messaging_product": "whatsapp",
  "to": "972501234567",
  "type": "text",
  "text": { "body": "קו 18 מגיע בעוד 5 דקות!" }
}
```

#### 3. OpenWeatherMap API

**Endpoint:** `https://api.openweathermap.org/data/2.5/weather`

**שימוש:** צ'קליסט חכם (גשם/חום)

**Example:**
```http
GET /data/2.5/weather?lat=32.08&lon=34.78&appid=YOUR_KEY&units=metric
```

#### 4. Firebase Cloud Messaging

**Endpoint:** `https://fcm.googleapis.com/fcm/send`

**שימוש:** Push Notifications

#### 5. Google/Apple Calendar API

**שימוש:** זיהוי אירועים ופגישות (Post-MVP)

### 4.4 Data Flow Diagram

```
תרחיש: משתמש מקבל התרעה

[Tracking Service (Cron)]
    │ Every 20 seconds
    ├─> Query DB: Get active routes for current time
    │
    ├─> For each route:
    │   ├─> [GTFS Service]
    │   │   └─> Fetch bus ETA from GTFS API
    │   │       └─> Cache in Redis (60s TTL)
    │   │
    │   ├─> [Alert Engine]
    │   │   ├─> Calculate: Should send alert?
    │   │   │   ├─> ETA <= 10 min → Initial Alert
    │   │   │   ├─> ETA <= 5 min → Checklist Alert
    │   │   │   └─> ETA <= 2 min → Urgent Alert
    │   │   │
    │   │   ├─> [Weather Service]
    │   │   │   └─> Get contextual checklist
    │   │   │
    │   │   └─> [WhatsApp Service]
    │   │       └─> Send formatted message
    │   │
    │   └─> [WebSocket Service]
    │       └─> Emit real-time update to connected clients
    │
    └─> Log alert to database
```

---

## <a name="screens"></a>5. User Flow ומסכים

### 5.1 רשימת מסכים

1. **Onboarding** (3 מסכים)
2. **Login / Registration**
3. **Home Screen**
4. **Add Route**
5. **Active Tracking**
6. **Checklist Management**
7. **Route History**
8. **Settings**
9. **Statistics** (Optional)

### 5.2 תיאור מפורט

*(מסכים מפורטים כבר מופיעים במסמך המקורי שקיבלת)*

---

## <a name="dev-instructions"></a>6. הוראות פיתוח למפתח

### 6.1 Setup & Environment

**Prerequisites:**
```bash
node >= 18.0.0
npm >= 9.0.0
postgresql >= 14
redis >= 7
docker & docker-compose (optional)
```

### 6.2 Backend Setup

```bash
# Clone repository
git clone https://github.com/Uri-cyber/BusKing.git
cd BusKing/backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your API keys

# Run migrations
npm run migrate

# Seed sample data
npm run seed

# Start development server
npm run dev
```

### 6.3 Database Schema

מלא - ראה `database/schema.sql`

טבלאות עיקריות:
- `users` - משתמשים
- `user_routes` - מסלולים קבועים
- `checklist_items` - פריטי צ'קליסט
- `alert_history` - היסטוריית התרעות
- `tracking_sessions` - מעקבים פעילים
- `gtfs_stops` - תחנות GTFS
- `gtfs_routes` - קווי אוטובוס

### 6.4 Project Structure

```
BusKing/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.ts
│   │   │   ├── redis.ts
│   │   │   └── logger.ts
│   │   ├── controllers/
│   │   │   ├── authController.ts
│   │   │   ├── routeController.ts
│   │   │   └── checklistController.ts
│   │   ├── middleware/
│   │   │   ├── auth.ts
│   │   │   └── validation.ts
│   │   ├── models/
│   │   │   ├── User.ts
│   │   │   ├── Route.ts
│   │   │   └── Checklist.ts
│   │   ├── routes/
│   │   │   ├── authRoutes.ts
│   │   │   ├── routeRoutes.ts
│   │   │   └── checklistRoutes.ts
│   │   ├── services/
│   │   │   ├── gtfsService.ts
│   │   │   ├── whatsappService.ts
│   │   │   ├── weatherService.ts
│   │   │   ├── alertEngine.ts
│   │   │   ├── trackingService.ts
│   │   │   └── websocketService.ts
│   │   ├── types/
│   │   │   └── index.ts
│   │   ├── utils/
│   │   │   ├── jwt.ts
│   │   │   └── sms.ts
│   │   └── index.ts
│   ├── tests/
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
├── database/
│   └── schema.sql
├── scripts/
│   ├── migrate.js
│   └── seed.js
├── docs/
│   ├── TECHNICAL_SPEC.md
│   └── API_REFERENCE.md
├── docker-compose.yml
└── README.md
```

---

## <a name="api-integrations"></a>7. API ואינטגרציות

### 7.1 סקירה כללית

**Base URL (Production):**
```
https://api.busalert.app/v1
```

**Authentication:**
```
Authorization: Bearer <jwt_token>
```

### 7.2 Auth API

#### POST /auth/register
```json
Request:
{
  "phone_number": "+972501234567",
  "name": "יוסי כהן"
}

Response:
{
  "status": "success",
  "message": "Verification code sent via SMS",
  "data": {
    "user_id": "uuid"
  }
}
```

#### POST /auth/verify
```json
Request:
{
  "phone_number": "+972501234567",
  "code": "123456"
}

Response:
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "name": "יוסי כהן"
    }
  }
}
```

### 7.3 Routes API

#### POST /routes
```json
Request:
{
  "stop_id": "3045",
  "stop_name": "רחוב הרצל 45",
  "route_number": "18",
  "route_name": "תל אביב תחנה מרכזית",
  "days_of_week": [1,3,4],
  "time_window_start": "07:30",
  "time_window_end": "08:00",
  "alert_minutes_before": 5
}

Response:
{
  "status": "success",
  "message": "Route created successfully",
  "data": {
    "route_id": "uuid"
  }
}
```

### 7.4 WebSocket Events

**Connection:**
```javascript
const socket = io('wss://api.busalert.app/ws', {
  auth: { token: 'jwt_token' }
});
```

**Events:**
- `bus_update` - עדכון מיקום אוטובוס
- `alert_triggered` - התרעה נשלחה
- `tracking_status` - שינוי במעקב

---

## <a name="timeline"></a>8. טיימליין ואבני דרך

### 8.1 שלבי פיתוח עיקריים

| שלב | משך | תיאור |
|-----|------|--------|
| **שלב 1: אפיון והקמה** | שבוע 1-2 | הקמת מאגר Git, מבנה פרויקט, DB ו-Redis |
| **שלב 2: Backend בסיסי** | שבוע 3-4 | פיתוח API (Auth, Routes, Checklist, Alerts) + GTFS |
| **שלב 3: אפליקציה ניידת** | שבוע 5-7 | בניית מסכי Flutter + חיבור ל-API |
| **שלב 4: התרעות בזמן אמת** | שבוע 8 | שילוב Socket.io + WhatsApp Cloud |
| **שלב 5: בדיקות ו-QA** | שבוע 9-10 | בדיקות עומס, E2E, תיקוני באגים |
| **שלב 6: השקת MVP** | שבוע 11 | גרסת בטא ל-100 משתמשים ראשונים |
| **שלב 7: פיצ'רים מתקדמים** | שבוע 12-14 | למידה חכמה, יומן, סטטיסטיקות |

### 8.2 אבני דרך (Milestones)

| M# | שם | יעד |
|----|-----|-----|
| **M1** | System Setup Complete | DB ושרת רצה מקומית |
| **M2** | Core Backend Ready | API מלא פעיל מול GTFS אמיתי |
| **M3** | Frontend Integration | אפליקציה מחוברת בזמן אמת |
| **M4** | MVP Launch | גרסת TestFlight / Play Beta |
| **M5** | Analytics Feedback | Dashboard נתונים ו-Feedback |
| **M6** | Smart Automation v2.0 | למידה חכמה והצעות אוטומטיות |

### 8.3 KPIs ומדדי הצלחה

| מדד | יעד MVP | יעד חצי שנה |
|------|---------|-------------|
| דיוק התרעות | ≥ 90% | ≥ 95% |
| Daily Active Users | 200 | 2,000 |
| Retention (7 days) | 40% | 60% |
| זמן המתנה שנחסך | ≥ 6 דקות | ≥ 8 דקות |
| באגים קריטיים | ≤ 5 | ≤ 2 |

### 8.4 תוכניות המשך (Future Roadmap)

1. **BusAlert Premium** - גרסה בתשלום עם SMS, תעדוף התרעות ודו"חות מתקדמים
2. **אינטגרציה לשעונים חכמים** - תמיכה ב-Wear OS / Apple Watch
3. **שיתוף בזמן אמת** - "חבר מחכה בתחנה" עם מפה חיה
4. **Assistant חכם** - זיהוי עיכובים וחיזוי ETA מדויק בעזרת AI
5. **שיתופי פעולה עם חברות תחבורה** - אגד, דן, מטרופולין למידע מדויק ברמת שניות

---

## ✅ סוף מסמך

**BusAlert - אפיון מלא ומסמך טכני**
**גרסה 1.0.2, נובמבר 2025**

---

**Built with ❤️ in Tel Aviv**

</div>

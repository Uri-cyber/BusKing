# 🚌 BusAlert - מערכת התרעות חכמה להגעת אוטובוסים

<div dir="rtl">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)
![TypeScript](https://img.shields.io/badge/typescript-%5E5.3.3-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📋 תוכן עניינים

- [סקירה כללית](#overview)
- [תכונות עיקריות](#features)
- [דרישות מערכת](#requirements)
- [התקנה](#installation)
- [הרצה](#running)
- [תיעוד API](#api-docs)
- [ארכיטקטורה](#architecture)
- [פיתוח](#development)
- [רישיון](#license)

## <a name="overview"></a>🎯 סקירה כללית

**BusAlert** היא מערכת חכמה ומתקדמת למעקב והתרעות על הגעת אוטובוסים בזמן אמת.

### Vision Statement
להפוך את הנסיעה בתחבורה ציבורית לחוויה חלקה ונטולת מתח, על ידי מתן מידע פרואקטיבי במקום ריאקטיבי.

### קהל היעד
- נוסעים קבועים בתחבורה ציבורית (עובדים, סטודנטים)
- משתמשים בני 18-65
- בעלי סמארטפון עם אינטרנט
- משתמשי WhatsApp (90%+ משוק ישראל)

## <a name="features"></a>✨ תכונות עיקריות

### 🔄 Core Features (MVP)

1. **מעקב אוטומטי אחר אוטובוס**
   - הגדרת מסלולים קבועים
   - מעקב אוטומטי לפי לוח זמנים
   - חישוב ETA (Estimated Time of Arrival) בזמן אמת

2. **התרעות מדורגות חכמות**
   - שלב 1: התרעה ראשונית (10 דקות)
   - שלב 2: התרעה + צ'קליסט (5 דקות)
   - שלב 3: התרעה דחופה (2 דקות)
   - עדכונים על איחורים וביטולים

3. **צ'קליסט אישי ודינמי**
   - רשימת פריטים מותאמת אישית
   - צ'קליסט דינמי לפי מזג אוויר (מטריה, בקבוק מים)
   - צ'קליסט לפי שעה (ארוחת בוקר, מעיל)

4. **אינטגרציה מלאה עם WhatsApp**
   - כל ההתרעות דרך WhatsApp Business API
   - כפתורי Quick Reply
   - שיחה דו-כיוונית
   - פקודות טקסט

5. **זיהוי מיקום אוטומטי (Geofencing)**
   - זיהוי תחנה אוטומטי
   - חיסכון בסוללה (60-80%)
   - הפעלת GPS רק בחלון הזמן הרלוונטי

### 🚀 Advanced Features (Post-MVP)

- למידה חכמה (ML) של הרגלי נסיעה
- שיתוף מיקום בזמן אמת
- אינטגרציה עם יומן (Google/Apple Calendar)
- סטטיסטיקות ותובנות אישיות

## <a name="requirements"></a>⚙️ דרישות מערכת

### Software Requirements
- Node.js >= 18.0.0
- PostgreSQL >= 14
- Redis >= 7
- Docker & Docker Compose (אופציונלי)

### API Keys Required
- WhatsApp Business Cloud API (Meta)
- Twilio (לאימות SMS)
- OpenWeatherMap API
- Firebase Cloud Messaging (לPush Notifications)

## <a name="installation"></a>📦 התקנה

### התקנה רגילה

```bash
# Clone the repository
git clone https://github.com/Uri-cyber/BusKing.git
cd BusKing

# Install backend dependencies
cd backend
npm install

# Setup environment variables
cp .env.example .env
# ערוך את קובץ .env והוסף את ה-API Keys שלך

# Run database migrations
npm run migrate

# Seed sample data
npm run seed
```

### התקנה עם Docker

```bash
# Clone the repository
git clone https://github.com/Uri-cyber/BusKing.git
cd BusKing

# Create .env file from example
cp backend/.env.example .env
# ערוך את קובץ .env והוסף את ה-API Keys שלך

# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f backend
```

## <a name="running"></a>🚀 הרצה

### Development Mode

```bash
cd backend
npm run dev
```

השרת יתחיל על:
- API: `http://localhost:3000`
- WebSocket: `ws://localhost:3000/ws`
- Health Check: `http://localhost:3000/health`

### Production Mode

```bash
cd backend
npm run build
npm start
```

### עם Docker

```bash
docker-compose up -d
```

## <a name="api-docs"></a>📚 תיעוד API

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication
כל הבקשות המאובטחות דורשות:
```
Authorization: Bearer <jwt_token>
```

### Endpoints

#### Authentication
- `POST /auth/register` - רישום משתמש חדש
- `POST /auth/verify` - אימות קוד SMS
- `GET /auth/me` - קבלת פרופיל משתמש
- `PUT /auth/settings` - עדכון הגדרות

#### Routes (מסלולים)
- `POST /routes` - יצירת מסלול חדש
- `GET /routes` - קבלת כל המסלולים
- `GET /routes/:id` - קבלת מסלול ספציפי
- `PUT /routes/:id` - עדכון מסלול
- `DELETE /routes/:id` - מחיקת מסלול
- `PATCH /routes/:id/toggle` - הפעלה/כיבוי מסלול

#### Checklist
- `GET /checklist` - קבלת רשימת פריטים
- `GET /checklist/contextual` - צ'קליסט קונטקסטואלי
- `POST /checklist` - הוספת פריט
- `DELETE /checklist/:id` - מחיקת פריט

### WebSocket Events

חיבור:
```javascript
const socket = io('ws://localhost:3000/ws', {
  auth: { token: 'your_jwt_token' }
});
```

אירועים:
- `bus_update` - עדכון מיקום אוטובוס
- `alert_triggered` - התרעה נשלחה
- `tracking_status` - שינוי במעקב

לתיעוד מלא ראה: [docs/API_REFERENCE.md](docs/API_REFERENCE.md)

## <a name="architecture"></a>🏗️ ארכיטקטורה

```
┌─────────────────────────────────────────┐
│         Client Layer                    │
│  Mobile App | WhatsApp | Web Dashboard │
└────────────────┬────────────────────────┘
                 │ REST API / WebSocket
                 ↓
┌─────────────────────────────────────────┐
│         API Gateway Layer               │
│  Node.js + Express + TypeScript         │
│  Authentication | Rate Limiting         │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┴────────────┐
    ↓                         ↓
┌──────────┐           ┌──────────────┐
│ Business │           │  Real-time   │
│  Logic   │           │   Tracking   │
│ Service  │           │   Service    │
└────┬─────┘           └──────┬───────┘
     │                        │
     └──────────┬─────────────┘
                ↓
┌─────────────────────────────────────────┐
│       Integration Layer                 │
│  GTFS-RT | WhatsApp | Weather | Maps    │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  PostgreSQL | Redis | S3                │
└─────────────────────────────────────────┘
```

### Tech Stack

**Backend:**
- Node.js 18+ with TypeScript
- Express.js
- Socket.io (WebSocket)
- PostgreSQL 14
- Redis 7

**APIs & Integrations:**
- GTFS-Realtime (משרד התחבורה)
- WhatsApp Business Cloud API
- OpenWeatherMap API
- Twilio (SMS)
- Firebase Cloud Messaging

## <a name="development"></a>👨‍💻 פיתוח

### Project Structure

```
BusKing/
├── backend/
│   ├── src/
│   │   ├── config/         # Database, Redis, Logger
│   │   ├── controllers/    # Route handlers
│   │   ├── middleware/     # Auth, validation
│   │   ├── models/         # Database models
│   │   ├── routes/         # API routes
│   │   ├── services/       # Business logic
│   │   ├── types/          # TypeScript types
│   │   ├── utils/          # Helpers
│   │   └── index.ts        # Main app
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── database/
│   └── schema.sql          # Database schema
├── scripts/
│   ├── migrate.js          # Database migration
│   └── seed.js             # Sample data
├── docs/
│   ├── TECHNICAL_SPEC.md   # מסמך טכני מלא
│   └── API_REFERENCE.md    # תיעוד API
├── docker-compose.yml
└── README.md
```

### Running Tests

```bash
npm test
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### בעיות נפוצות

1. **Database connection failed**
   ```bash
   # בדוק שPostgreSQL רץ
   docker-compose ps
   # או
   sudo systemctl status postgresql
   ```

2. **Redis connection error**
   ```bash
   # בדוק שRedis רץ
   redis-cli ping
   ```

3. **Port already in use**
   ```bash
   # מצא תהליכים על port 3000
   lsof -i :3000
   # הרוג תהליך
   kill -9 <PID>
   ```

## 📊 KPIs & Success Metrics

| Metric | Target MVP | Target 6 Months |
|--------|-----------|-----------------|
| דיוק התרעות | ≥ 90% | ≥ 95% |
| Daily Active Users | 200 | 2,000 |
| Retention (7 days) | 40% | 60% |
| זמן המתנה שנחסך | ≥ 6 דקות | ≥ 8 דקות |

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Uri Cyber** - Lead Developer & Product Owner
- **BusAlert Team** - Full Stack Development

## 📞 Contact & Support

- GitHub Issues: [https://github.com/Uri-cyber/BusKing/issues](https://github.com/Uri-cyber/BusKing/issues)
- Email: support@busalert.app

---

**Built with ❤️ in Tel Aviv**

</div>

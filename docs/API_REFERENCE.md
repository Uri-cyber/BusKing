# 📚 BusAlert API Reference

<div dir="rtl">

**Version:** 1.0.0
**Base URL:** `https://api.busalert.app/v1` (Production)
**Base URL (Dev):** `http://localhost:3000/api/v1`

---

## 📑 Table of Contents

1. [Authentication](#authentication)
2. [Auth Endpoints](#auth-endpoints)
3. [Routes Endpoints](#routes-endpoints)
4. [Checklist Endpoints](#checklist-endpoints)
5. [Tracking Endpoints](#tracking-endpoints)
6. [Alerts Endpoints](#alerts-endpoints)
7. [WebSocket API](#websocket-api)
8. [Error Handling](#error-handling)
9. [Rate Limiting](#rate-limiting)

---

## <a name="authentication"></a>🔐 Authentication

### Headers

כל הבקשות המאובטחות דורשות כותרת Authorization:

```http
Authorization: Bearer <jwt_token>
```

### Getting a Token

1. Register/Login with phone number
2. Verify SMS code
3. Receive JWT token
4. Use token in Authorization header

### Token Expiration

- Default: 7 days
- Refresh: Login again with phone number

---

## <a name="auth-endpoints"></a>👤 Auth Endpoints

### POST /auth/register

רישום משתמש חדש או שליחת קוד אימות למשתמש קיים.

**Request:**
```json
{
  "phone_number": "+972501234567",
  "name": "יוסי כהן"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Verification code sent via SMS",
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Validation:**
- `phone_number`: חייב להיות בפורמט +972XXXXXXXXX
- `name`: אופציונלי, 2-100 תווים

**SMS Example:**
```
BusAlert - קוד האימות שלך: 123456
הקוד תקף ל-10 דקות.
```

---

### POST /auth/verify

אימות קוד SMS והתחברות.

**Request:**
```json
{
  "phone_number": "+972501234567",
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAwIiwicGhvbmVfbnVtYmVyIjoiKzk3MjUwMTIzNDU2NyIsImlhdCI6MTYzMjEyMzQ1NiwiZXhwIjoxNjMyNzI4MjU2fQ.abc123...",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "יוסי כהן",
      "phone_number": "+972501234567",
      "settings": {
        "preferred_channel": "whatsapp",
        "quiet_mode": true,
        "quiet_hours": ["22:00", "06:00"],
        "language": "he",
        "alert_minutes_before": 5
      }
    }
  }
}
```

**Response (400 Bad Request):**
```json
{
  "status": "error",
  "message": "Invalid or expired verification code"
}
```

**Validation:**
- `code`: בדיוק 6 ספרות
- Code valid for: 10 minutes
- Max attempts: unlimited (but rate limited)

---

### GET /auth/me

קבלת פרופיל המשתמש המחובר.

**Headers:**
```http
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "phone_number": "+972501234567",
    "name": "יוסי כהן",
    "settings": {
      "preferred_channel": "whatsapp",
      "quiet_mode": true,
      "quiet_hours": ["22:00", "06:00"],
      "language": "he",
      "alert_minutes_before": 5
    },
    "created_at": "2025-11-01T08:30:00.000Z"
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "status": "error",
  "message": "Invalid or expired token"
}
```

---

### PUT /auth/settings

עדכון הגדרות משתמש.

**Headers:**
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request (partial update allowed):**
```json
{
  "preferred_channel": "push",
  "quiet_mode": false,
  "language": "en",
  "alert_minutes_before": 10
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Settings updated successfully",
  "data": {
    "settings": {
      "preferred_channel": "push",
      "quiet_mode": false,
      "quiet_hours": ["22:00", "06:00"],
      "language": "en",
      "alert_minutes_before": 10
    }
  }
}
```

**Available Settings:**
- `preferred_channel`: "whatsapp" | "push" | "sms"
- `quiet_mode`: boolean
- `quiet_hours`: [start_time, end_time] (HH:MM format)
- `language`: "he" | "en" | "ar"
- `alert_minutes_before`: number (1-60)

---

## <a name="routes-endpoints"></a>🚌 Routes Endpoints

### POST /routes

יצירת מסלול חדש למעקב אוטומטי.

**Headers:**
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request:**
```json
{
  "stop_id": "3045",
  "stop_name": "רחוב הרצל 45 / וייצמן",
  "route_number": "18",
  "route_name": "תל אביב תחנה מרכזית - בת ים",
  "days_of_week": [1, 2, 3, 4, 5],
  "time_window_start": "07:30",
  "time_window_end": "08:00",
  "alert_minutes_before": 5
}
```

**Field Descriptions:**
- `stop_id`: מזהה תחנה (מ-GTFS)
- `stop_name`: שם התחנה (אופציונלי)
- `route_number`: מספר קו
- `route_name`: שם הקו (אופציונלי)
- `days_of_week`: מערך ימים (0=ראשון, 1=שני, ..., 6=שבת)
- `time_window_start`: שעת התחלה (HH:MM)
- `time_window_end`: שעת סיום (HH:MM)
- `alert_minutes_before`: כמה דקות לפני להתריע (1-60)

**Response (201 Created):**
```json
{
  "status": "success",
  "message": "Route created successfully",
  "data": {
    "route_id": "660e8400-e29b-41d4-a716-446655440001",
    "route": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "stop_id": "3045",
      "stop_name": "רחוב הרצל 45 / וייצמן",
      "route_number": "18",
      "route_name": "תל אביב תחנה מרכזית - בת ים",
      "days_of_week": [1, 2, 3, 4, 5],
      "time_window_start": "07:30",
      "time_window_end": "08:00",
      "alert_minutes_before": 5,
      "is_active": true,
      "created_at": "2025-11-12T08:00:00.000Z",
      "updated_at": "2025-11-12T08:00:00.000Z"
    }
  }
}
```

---

### GET /routes

קבלת כל המסלולים של המשתמש.

**Headers:**
```http
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "stop_id": "3045",
      "stop_name": "רחוב הרצל 45 / וייצמן",
      "route_number": "18",
      "route_name": "תל אביב תחנה מרכזית - בת ים",
      "days_of_week": [1, 2, 3, 4, 5],
      "time_window_start": "07:30",
      "time_window_end": "08:00",
      "alert_minutes_before": 5,
      "is_active": true,
      "created_at": "2025-11-12T08:00:00.000Z"
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440002",
      "stop_id": "4567",
      "stop_name": "דיזנגוף / פרישמן",
      "route_number": "5",
      "days_of_week": [0, 6],
      "time_window_start": "18:00",
      "time_window_end": "19:00",
      "alert_minutes_before": 10,
      "is_active": true,
      "created_at": "2025-11-11T10:30:00.000Z"
    }
  ]
}
```

---

### GET /routes/:id

קבלת מסלול ספציפי.

**Headers:**
```http
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "stop_id": "3045",
    "route_number": "18",
    "days_of_week": [1, 2, 3, 4, 5],
    "is_active": true
  }
}
```

**Response (404 Not Found):**
```json
{
  "status": "error",
  "message": "Route not found"
}
```

---

### PUT /routes/:id

עדכון מסלול קיים.

**Request (partial update):**
```json
{
  "alert_minutes_before": 10,
  "time_window_start": "07:45"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Route updated successfully",
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "alert_minutes_before": 10,
    "time_window_start": "07:45",
    "updated_at": "2025-11-12T09:00:00.000Z"
  }
}
```

---

### DELETE /routes/:id

מחיקת מסלול.

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Route deleted successfully"
}
```

---

### PATCH /routes/:id/toggle

הפעלה/כיבוי מסלול.

**Request:**
```json
{
  "is_active": false
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Route deactivated successfully",
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "is_active": false
  }
}
```

---

## <a name="checklist-endpoints"></a>✅ Checklist Endpoints

### GET /checklist

קבלת כל פריטי הצ'קליסט (ברירת מחדל + מותאמים אישית).

**Headers:**
```http
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440003",
      "user_id": null,
      "item_name": "טלפון",
      "emoji": "📱",
      "is_default": true,
      "context": "always",
      "display_order": 1,
      "is_active": true
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440004",
      "user_id": null,
      "item_name": "מטריה",
      "emoji": "☂️",
      "is_default": true,
      "context": "rainy",
      "display_order": 5,
      "is_active": true
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440010",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "item_name": "תרופות",
      "emoji": "💊",
      "is_default": false,
      "context": "morning",
      "display_order": 0,
      "is_active": true
    }
  ]
}
```

---

### GET /checklist/contextual

קבלת צ'קליסט מותאם לפי הקשר (מזג אוויר + זמן).

**Query Parameters:**
- `weather`: "rainy" | "hot" | "cold"
- `time`: "morning" | "evening"

**Example Request:**
```http
GET /api/v1/checklist/contextual?weather=rainy&time=morning
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440003",
      "item_name": "טלפון",
      "emoji": "📱",
      "context": "always"
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440004",
      "item_name": "מטריה",
      "emoji": "☂️",
      "context": "rainy"
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440007",
      "item_name": "ארוחת בוקר",
      "emoji": "🥐",
      "context": "morning"
    }
  ]
}
```

---

### POST /checklist

הוספת פריט חדש לצ'קליסט.

**Request:**
```json
{
  "item_name": "תיק ספורט",
  "emoji": "🎒",
  "context": "evening"
}
```

**Response (201 Created):**
```json
{
  "status": "success",
  "message": "Checklist item created successfully",
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440020",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "item_name": "תיק ספורט",
    "emoji": "🎒",
    "context": "evening",
    "is_default": false,
    "display_order": 0,
    "created_at": "2025-11-12T10:00:00.000Z"
  }
}
```

---

### DELETE /checklist/:id

מחיקת פריט מהצ'קליסט.

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Checklist item deleted successfully"
}
```

**Note:** ניתן למחוק רק פריטים שהמשתמש יצר (לא ברירת מחדל).

---

### PATCH /checklist/:id/order

עדכון סדר פריט בצ'קליסט.

**Request:**
```json
{
  "new_order": 3
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Checklist order updated successfully",
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440020",
    "display_order": 3
  }
}
```

---

## <a name="tracking-endpoints"></a>📡 Tracking Endpoints

### GET /tracking/active

בדיקה אם יש מעקב פעיל כרגע.

**Headers:**
```http
Authorization: Bearer <jwt_token>
```

**Response (200 OK) - Active:**
```json
{
  "status": "success",
  "data": {
    "active": true,
    "route": "18",
    "stop_name": "רחוב הרצל 45",
    "eta_minutes": 6,
    "bus_location": {
      "lat": 32.084,
      "lon": 34.772
    }
  }
}
```

**Response (200 OK) - Not Active:**
```json
{
  "status": "success",
  "data": {
    "active": false
  }
}
```

---

### POST /tracking/start

הפעלת מעקב ידני (חד פעמי).

**Request:**
```json
{
  "stop_id": "3045",
  "route_number": "18"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Tracking started",
  "data": {
    "session_id": "880e8400-e29b-41d4-a716-446655440030"
  }
}
```

---

### POST /tracking/stop

עצירת מעקב פעיל.

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Tracking stopped"
}
```

---

## <a name="alerts-endpoints"></a>🔔 Alerts Endpoints

### GET /alerts/history

שליפת היסטוריית התרעות.

**Query Parameters:**
- `limit`: מספר תוצאות (default: 50, max: 100)
- `offset`: offset לpagination

**Example:**
```http
GET /api/v1/alerts/history?limit=20&offset=0
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440040",
      "route": "18",
      "alert_type": "initial",
      "eta": 10,
      "sent_at": "2025-11-12T07:40:00.000Z",
      "was_accurate": true
    },
    {
      "id": "990e8400-e29b-41d4-a716-446655440041",
      "route": "18",
      "alert_type": "checklist",
      "eta": 5,
      "sent_at": "2025-11-12T07:45:00.000Z",
      "was_accurate": null
    }
  ]
}
```

---

### PUT /alerts/:id/feedback

שליחת פידבק על דיוק התרעה.

**Request:**
```json
{
  "was_accurate": true
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Feedback received"
}
```

---

## <a name="websocket-api"></a>🔌 WebSocket API

### Connection

**Endpoint:** `ws://localhost:3000/ws` (Dev)
**Endpoint:** `wss://api.busalert.app/ws` (Production)

**Authentication:**
```javascript
const socket = io('ws://localhost:3000/ws', {
  path: '/ws',
  auth: {
    token: 'your_jwt_token_here'
  }
});
```

### Events

#### Client → Server

**`ping`** - בדיקת חיבור
```javascript
socket.emit('ping');
```

**`get_tracking_status`** - בקשה לסטטוס מעקב
```javascript
socket.emit('get_tracking_status');
```

#### Server → Client

**`pong`** - תשובה לping
```javascript
socket.on('pong', (data) => {
  console.log('Timestamp:', data.timestamp);
});
```

**`bus_update`** - עדכון מיקום אוטובוס
```javascript
socket.on('bus_update', (data) => {
  console.log('Route:', data.route_number);
  console.log('ETA:', data.eta_minutes);
  console.log('Location:', data.vehicle_location);
});
```

**Payload:**
```json
{
  "route_number": "18",
  "stop_id": "3045",
  "eta_minutes": 7,
  "vehicle_location": {
    "lat": 32.084,
    "lon": 34.772
  }
}
```

**`alert_triggered`** - התרעה נשלחה
```javascript
socket.on('alert_triggered', (data) => {
  console.log('Alert type:', data.alert_type);
  console.log('Message:', data.message);
});
```

**Payload:**
```json
{
  "alert_type": "urgent",
  "route_number": "18",
  "eta_minutes": 2,
  "message": "קו 18 מגיע בעוד 2 דקות!"
}
```

**`tracking_status`** - שינוי במצב מעקב
```javascript
socket.on('tracking_status', (data) => {
  console.log('Status:', data.status);
});
```

**Payload:**
```json
{
  "status": "started",
  "route_number": "18",
  "stop_id": "3045"
}
```

---

## <a name="error-handling"></a>⚠️ Error Handling

### Error Response Format

```json
{
  "status": "error",
  "message": "Human-readable error message",
  "error": "Technical error details (dev only)"
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Success |
| 201 | Created | Resource created |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Invalid/missing token |
| 403 | Forbidden | No permission |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

### Common Errors

**Invalid Token:**
```json
{
  "status": "error",
  "message": "Invalid or expired token"
}
```

**Validation Error:**
```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": [
    {
      "field": "phone_number",
      "message": "Invalid Israeli phone number format (+972XXXXXXXXX)"
    }
  ]
}
```

**Rate Limit Exceeded:**
```json
{
  "status": "error",
  "message": "Too many requests from this IP, please try again later."
}
```

---

## <a name="rate-limiting"></a>🚦 Rate Limiting

### Limits

- **Default:** 100 requests per 15 minutes per IP
- **Auth endpoints:** No special limit
- **Protected endpoints:** Require valid JWT

### Rate Limit Headers

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1636722000
```

### When Limit Exceeded

**Status:** 429 Too Many Requests

**Response:**
```json
{
  "status": "error",
  "message": "Too many requests from this IP, please try again later."
}
```

**Retry After:** 15 minutes (900 seconds)

---

## 📞 Support

**Issues:** https://github.com/Uri-cyber/BusKing/issues
**Email:** support@busalert.app

---

**Built with ❤️ in Tel Aviv**

</div>

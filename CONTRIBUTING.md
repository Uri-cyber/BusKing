# Contributing to BusAlert

<div dir="rtl">

תודה שאתה מעוניין לתרום ל-BusAlert! 🎉

## איך לתרום?

### 1. Fork את הפרויקט

לחץ על כפתור "Fork" בראש העמוד ב-GitHub.

### 2. Clone את ה-Fork שלך

```bash
git clone https://github.com/YOUR_USERNAME/BusKing.git
cd BusKing
```

### 3. צור Branch חדש

```bash
git checkout -b feature/amazing-feature
```

שימו לב לקונבנציית השמות:
- `feature/` - פיצ'ר חדש
- `fix/` - תיקון באג
- `docs/` - שינויים בדוקומנטציה
- `refactor/` - שינויים ארכיטקטוניים

### 4. עשה את השינויים שלך

ודא שאתה עוקב אחרי:
- **Code Style** - השתמש ב-TypeScript types
- **Comments** - הוסף הערות בעברית או אנגלית
- **Tests** - כתוב טסטים לקוד חדש
- **Documentation** - עדכן את ה-README אם צריך

### 5. Commit השינויים

```bash
git add .
git commit -m "feat: הוספת פיצ'ר מדהים"
```

**Commit Message Format:**
```
<type>: <description>

[optional body]
```

**Types:**
- `feat` - פיצ'ר חדש
- `fix` - תיקון באג
- `docs` - דוקומנטציה
- `style` - עיצוב קוד
- `refactor` - שינוי ארכיטקטוני
- `test` - הוספת טסטים
- `chore` - משימות תחזוקה

**דוגמאות:**
```bash
git commit -m "feat: הוספת תמיכה בשעון חכם"
git commit -m "fix: תיקון באג בחישוב ETA"
git commit -m "docs: עדכון README"
```

### 6. Push ל-GitHub

```bash
git push origin feature/amazing-feature
```

### 7. פתח Pull Request

1. עבור ל-GitHub repository שלך
2. לחץ על "Compare & pull request"
3. תאר את השינויים שעשית
4. שלח את ה-PR!

## קוד אתי (Code of Conduct)

### ✅ עשה:
- היה מכבד וחביב
- כתוב קוד נקי וקריא
- הוסף טסטים
- עדכן דוקומנטציה
- עזור לאחרים בissues

### ❌ אל תעשה:
- לא לשלוח spam
- לא לפרסם מידע אישי
- לא להעתיק קוד ללא ייחוס
- לא לפרסם תוכן פוגעני

## סוגי תרומות

### 🐛 דיווח על באגים

פתח issue חדש עם:
- תיאור הבעיה
- שלבים לשחזור
- התנהגות צפויה
- התנהגות בפועל
- צילומי מסך (אם רלוונטי)

### 💡 הצעות לפיצ'רים

פתח issue חדש עם:
- תיאור הפיצ'ר
- למה זה שימושי
- דוגמאות שימוש
- עיצוב UI (אם רלוונטי)

### 📝 שיפור דוקומנטציה

תמיד מוזמנים לשפר:
- README
- API Reference
- Technical Spec
- Code comments

### 🧪 כתיבת טסטים

אנחנו תמיד צריכים יותר טסטים:
- Unit tests
- Integration tests
- E2E tests

## הקמת סביבת פיתוח

### דרישות

- Node.js >= 18.0.0
- PostgreSQL >= 14
- Redis >= 7
- Docker (אופציונלי)

### התקנה

```bash
# Clone
git clone https://github.com/Uri-cyber/BusKing.git
cd BusKing

# Install dependencies
cd backend
npm install

# Setup environment
cp .env.example .env
# ערוך את .env

# Setup database
npm run migrate
npm run seed

# Run development server
npm run dev
```

### הרצת טסטים

```bash
npm test
```

### בניית Production

```bash
npm run build
```

## Style Guide

### TypeScript

```typescript
// ✅ Good
interface User {
    id: string;
    name: string;
}

async function getUser(id: string): Promise<User> {
    // ...
}

// ❌ Bad
function getUser(id) {
    // ...
}
```

### Naming Conventions

- **Files:** camelCase.ts
- **Classes:** PascalCase
- **Functions:** camelCase
- **Constants:** UPPER_SNAKE_CASE
- **Interfaces:** PascalCase

### Comments

```typescript
// ✅ Good - מסביר למה
// We use Redis cache here because GTFS API is rate limited
const cached = await getCache(key);

// ❌ Bad - מסביר מה
// Get from cache
const cached = await getCache(key);
```

## שאלות?

יש לך שאלות? פתח issue או שלח מייל ל-support@busalert.app

## רישיון

על ידי תרומה לפרויקט, אתה מסכים שהתרומה שלך תהיה תחת רישיון MIT.

---

**תודה על התרומה! 🙏**

</div>

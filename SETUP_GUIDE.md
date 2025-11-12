# BusAlert Setup Guide

## 🎯 Quick Start

This guide will help you get BusAlert running on your machine.

---

## ✅ What's Already Done

- ✅ **All source code** written and committed to Git
- ✅ **Backend** (Node.js + TypeScript) - 28 files
- ✅ **Mobile App** (Flutter) - 27 files
- ✅ **Tests** (Unit, Widget, Integration)
- ✅ **CI/CD** (GitHub Actions workflows)
- ✅ **Documentation** (Technical specs, API reference, ML guide)
- ✅ **Docker** configuration
- ✅ **Database** schema

---

## 🚀 Setup Steps

### 1. Prerequisites

Install the following:

```bash
# Node.js 18+ (Backend)
node --version  # Should be 18+

# PostgreSQL 14+ (Database)
psql --version  # Should be 14+

# Redis 7+ (Cache)
redis-cli --version  # Should be 7+

# Flutter 3.16+ (Mobile)
flutter --version  # Should be 3.16+

# Docker (Optional)
docker --version
docker-compose --version
```

---

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create .env file
cp ../.env.example .env

# Edit .env with your configuration
nano .env

# Setup database
psql -U postgres
CREATE DATABASE busalert;
\q

# Run migrations
psql -U postgres -d busalert -f ../database/schema.sql

# Start Redis (in separate terminal)
redis-server

# Start backend
npm run dev
```

**Backend will run on:** `http://localhost:3000`

---

### 3. Mobile App Setup

```bash
cd frontend/mobile

# Get Flutter dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create

# Configure Firebase
# 1. Create Firebase project at https://console.firebase.google.com
# 2. Download google-services.json for Android
# 3. Download GoogleService-Info.plist for iOS
# 4. Place them in:
#    - android/app/google-services.json
#    - ios/Runner/GoogleService-Info.plist

# Configure Google Maps
# Add your API key to:
# - android/app/src/main/AndroidManifest.xml
# - ios/Runner/Info.plist

# Run on emulator/device
flutter run
```

---

### 4. Using Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

**Services:**
- Backend: `http://localhost:3000`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

---

## 🔑 Required API Keys

### 1. Israel Ministry of Transport (GTFS)
- Register at: https://www.gov.il/he/Departments/General/gtfs_info
- Add to `.env`: `MOT_API_KEY=your_key`

### 2. WhatsApp Business (Optional)
- Setup at: https://business.facebook.com/wa/manage/
- Add to `.env`: `WHATSAPP_ACCESS_TOKEN=your_token`

### 3. Google Maps
- Get key: https://console.cloud.google.com/google/maps-apis
- Enable: Maps SDK for Android, Maps SDK for iOS
- Add to mobile app manifests

### 4. Firebase
- Create project: https://console.firebase.google.com
- Enable: Cloud Messaging, Authentication
- Download config files

### 5. OpenWeatherMap (Optional)
- Get key: https://openweathermap.org/api
- Add to `.env`: `OPENWEATHER_API_KEY=your_key`

---

## 📱 Mobile App Build

### Android

```bash
cd frontend/mobile

# Debug build
flutter build apk --debug

# Release build (requires signing)
# 1. Create keystore:
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias release

# 2. Configure android/key.properties
cp android/key.properties.example android/key.properties
# Edit with your keystore info

# 3. Build release
flutter build apk --release
# Or
flutter build appbundle --release
```

**Output:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
# Requires macOS
cd frontend/mobile

# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Debug build
flutter build ios --debug --no-codesign

# Release build (requires Apple Developer account)
flutter build ipa --release
```

---

## 🧪 Running Tests

### Backend Tests

```bash
cd backend
npm test
npm run test:coverage
```

### Mobile Tests

```bash
cd frontend/mobile

# Unit & Widget tests
flutter test

# Integration tests (requires emulator/device)
flutter test integration_test/app_test.dart
```

---

## 🔍 Verification

### Backend Health Check

```bash
curl http://localhost:3000/health

# Should return:
{
  "status": "ok",
  "timestamp": "2025-01-12T...",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

### Mobile App Check

```bash
cd frontend/mobile
flutter doctor

# All checks should pass:
✓ Flutter
✓ Android toolchain
✓ Xcode (macOS only)
✓ Connected devices
```

---

## 🐛 Troubleshooting

### Backend won't start

**Problem:** `Error: connect ECONNREFUSED`

**Solution:**
- Check PostgreSQL is running: `pg_isready`
- Check Redis is running: `redis-cli ping`
- Verify `.env` configuration

### Mobile app won't build

**Problem:** `google-services.json not found`

**Solution:**
- Download from Firebase Console
- Place in `android/app/google-services.json`

**Problem:** `CocoaPods not installed`

**Solution:**
```bash
sudo gem install cocoapods
cd ios && pod install
```

### TypeScript errors

**Problem:** Type errors when compiling

**Solution:**
```bash
cd backend
npm install --save-dev @types/pg @types/node-cron
```

---

## 📚 Next Steps

After setup:

1. **Create test user:**
   ```bash
   curl -X POST http://localhost:3000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"phone_number": "0501234567", "name": "Test User"}'
   ```

2. **Test mobile app** with test credentials

3. **Review documentation:**
   - API Reference: `docs/API_REFERENCE.md`
   - Technical Spec: `docs/TECHNICAL_SPEC.md`
   - ML Guide: `docs/ML_GUIDE.md`

4. **Configure CI/CD:**
   - Add secrets to GitHub repository
   - Review `.github/workflows/*.yml`

---

## 🆘 Need Help?

- 📖 Documentation: `docs/`
- 🐛 Issues: https://github.com/Uri-cyber/BusKing/issues
- 💬 Discussions: https://github.com/Uri-cyber/BusKing/discussions

---

**Last Updated:** 2025-01-12
**Version:** 1.0.0

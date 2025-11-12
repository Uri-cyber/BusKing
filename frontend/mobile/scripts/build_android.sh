#!/bin/bash
# Android Build Script for BusAlert
# Usage: ./scripts/build_android.sh [dev|staging|prod] [debug|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
FLAVOR=${1:-prod}
BUILD_TYPE=${2:-release}

echo -e "${GREEN}🚀 Building BusAlert Android App${NC}"
echo -e "Flavor: ${YELLOW}$FLAVOR${NC}"
echo -e "Build Type: ${YELLOW}$BUILD_TYPE${NC}"
echo ""

# Validate flavor
if [[ ! "$FLAVOR" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid flavor. Use: dev, staging, or prod${NC}"
    exit 1
fi

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(debug|release)$ ]]; then
    echo -e "${RED}❌ Invalid build type. Use: debug or release${NC}"
    exit 1
fi

# Check for signing config in release
if [ "$BUILD_TYPE" == "release" ]; then
    if [ ! -f "android/key.properties" ]; then
        echo -e "${RED}❌ Missing android/key.properties for release build${NC}"
        echo -e "${YELLOW}💡 Copy android/key.properties.example to android/key.properties and configure it${NC}"
        exit 1
    fi
fi

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Generate launcher icons
echo -e "${YELLOW}🎨 Generating launcher icons...${NC}"
flutter pub run flutter_launcher_icons

# Generate splash screen
echo -e "${YELLOW}✨ Generating splash screen...${NC}"
flutter pub run flutter_native_splash:create

# Build based on flavor and type
if [ "$BUILD_TYPE" == "release" ]; then
    echo -e "${YELLOW}🔨 Building Release APK...${NC}"
    flutter build apk --release --flavor $FLAVOR --split-per-abi

    echo -e "${YELLOW}📦 Building Release App Bundle...${NC}"
    flutter build appbundle --release --flavor $FLAVOR

    APK_PATH="build/app/outputs/flutter-apk/app-${FLAVOR}-release.apk"
    AAB_PATH="build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"

    echo ""
    echo -e "${GREEN}✅ Build Complete!${NC}"
    echo -e "APK: ${YELLOW}$APK_PATH${NC}"
    echo -e "App Bundle: ${YELLOW}$AAB_PATH${NC}"

    # Show APK size
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "APK Size: ${YELLOW}$APK_SIZE${NC}"
    fi

    # Show AAB size
    if [ -f "$AAB_PATH" ]; then
        AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
        echo -e "AAB Size: ${YELLOW}$AAB_SIZE${NC}"
    fi
else
    echo -e "${YELLOW}🔨 Building Debug APK...${NC}"
    flutter build apk --debug --flavor $FLAVOR

    APK_PATH="build/app/outputs/flutter-apk/app-${FLAVOR}-debug.apk"

    echo ""
    echo -e "${GREEN}✅ Build Complete!${NC}"
    echo -e "APK: ${YELLOW}$APK_PATH${NC}"
fi

# Install to device (optional)
echo ""
read -p "Install on connected device? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flutter install --flavor $FLAVOR
    echo -e "${GREEN}✅ App installed on device${NC}"
fi

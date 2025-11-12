#!/bin/bash
# iOS Build Script for BusAlert
# Usage: ./scripts/build_ios.sh [dev|staging|prod] [debug|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ iOS builds require macOS${NC}"
    exit 1
fi

# Default values
FLAVOR=${1:-prod}
BUILD_TYPE=${2:-release}

echo -e "${GREEN}🚀 Building BusAlert iOS App${NC}"
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

# Install CocoaPods dependencies
echo -e "${YELLOW}📦 Installing CocoaPods dependencies...${NC}"
cd ios
pod install
cd ..

# Build based on build type
if [ "$BUILD_TYPE" == "release" ]; then
    echo -e "${YELLOW}🔨 Building Release IPA...${NC}"
    flutter build ipa --release --flavor $FLAVOR --export-options-plist=ios/ExportOptions.plist

    IPA_PATH="build/ios/ipa/*.ipa"

    echo ""
    echo -e "${GREEN}✅ Build Complete!${NC}"
    echo -e "IPA: ${YELLOW}$IPA_PATH${NC}"

    # Show IPA size
    if ls build/ios/ipa/*.ipa 1> /dev/null 2>&1; then
        IPA_SIZE=$(du -h build/ios/ipa/*.ipa | cut -f1)
        echo -e "IPA Size: ${YELLOW}$IPA_SIZE${NC}"
    fi

    # Option to upload to TestFlight
    echo ""
    echo -e "${YELLOW}💡 To upload to TestFlight:${NC}"
    echo -e "   xcrun altool --upload-app -f build/ios/ipa/BusAlert.ipa -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"
else
    echo -e "${YELLOW}🔨 Building Debug App...${NC}"
    flutter build ios --debug --flavor $FLAVOR --no-codesign

    APP_PATH="build/ios/iphoneos/Runner.app"

    echo ""
    echo -e "${GREEN}✅ Build Complete!${NC}"
    echo -e "App: ${YELLOW}$APP_PATH${NC}"
fi

# Install to simulator (debug only)
if [ "$BUILD_TYPE" == "debug" ]; then
    echo ""
    read -p "Install on iOS Simulator? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        flutter run --flavor $FLAVOR
        echo -e "${GREEN}✅ App running on simulator${NC}"
    fi
fi

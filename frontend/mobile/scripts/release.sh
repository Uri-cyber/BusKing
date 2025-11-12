#!/bin/bash
# Release Script for BusAlert
# Usage: ./scripts/release.sh [major|minor|patch]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

echo -e "${BLUE}📦 BusAlert Release Script${NC}"
echo -e "Current Version: ${YELLOW}$CURRENT_VERSION+$CURRENT_BUILD${NC}"
echo ""

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Determine new version
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo -e "${RED}❌ Invalid bump type. Use: major, minor, or patch${NC}"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((CURRENT_BUILD + 1))

echo -e "New Version: ${GREEN}$NEW_VERSION+$NEW_BUILD${NC}"
echo ""

# Confirm
read -p "Proceed with release? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Release cancelled${NC}"
    exit 0
fi

# Update pubspec.yaml
echo -e "${YELLOW}📝 Updating pubspec.yaml...${NC}"
sed -i.bak "s/^version:.*/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
rm pubspec.yaml.bak

# Generate changelog entry
CHANGELOG_FILE="CHANGELOG.md"
RELEASE_DATE=$(date +"%Y-%m-%d")

if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "# Changelog" > "$CHANGELOG_FILE"
    echo "" >> "$CHANGELOG_FILE"
fi

echo -e "${YELLOW}📋 Generating changelog entry...${NC}"

# Create temp changelog
cat > temp_changelog.md << EOF
## [$NEW_VERSION] - $RELEASE_DATE

### Added
-

### Changed
-

### Fixed
-

EOF

# Prepend to existing changelog
cat "$CHANGELOG_FILE" >> temp_changelog.md
mv temp_changelog.md "$CHANGELOG_FILE"

echo -e "${GREEN}✅ Changelog template created${NC}"
echo -e "${YELLOW}💡 Please edit $CHANGELOG_FILE to add release notes${NC}"
echo ""

# Open changelog in editor
if command -v ${EDITOR:-nano} &> /dev/null; then
    read -p "Open changelog in editor? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} "$CHANGELOG_FILE"
    fi
fi

# Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
flutter test

# Build release
echo -e "${YELLOW}🔨 Building release...${NC}"
echo ""
read -p "Build Android? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/build_android.sh prod release
fi

echo ""
read -p "Build iOS? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ./scripts/build_ios.sh prod release
    else
        echo -e "${YELLOW}⚠️  iOS builds require macOS${NC}"
    fi
fi

# Git operations
echo ""
echo -e "${YELLOW}📦 Committing changes...${NC}"

git add pubspec.yaml "$CHANGELOG_FILE"
git commit -m "chore: release v$NEW_VERSION"

echo -e "${GREEN}✅ Changes committed${NC}"

# Create git tag
echo -e "${YELLOW}🏷️  Creating git tag...${NC}"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

echo -e "${GREEN}✅ Tag created: v$NEW_VERSION${NC}"

# Push to remote
echo ""
read -p "Push to remote? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
    git push origin "v$NEW_VERSION"
    echo -e "${GREEN}✅ Pushed to remote${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Release v$NEW_VERSION complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Monitor GitHub Actions for build status"
echo -e "  2. Test the release builds"
echo -e "  3. Upload to Play Store / TestFlight"
echo -e "  4. Announce the release"

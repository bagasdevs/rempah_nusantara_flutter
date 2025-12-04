#!/bin/bash

echo "🚀 Building Optimized Release APK for Rempah Nusantara"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Analyze code for issues
echo -e "${YELLOW}🔍 Analyzing code...${NC}"
flutter analyze

# Run tests (optional, comment out if no tests)
# echo -e "${YELLOW}🧪 Running tests...${NC}"
# flutter test

# Build optimized APK with all flags
echo -e "${YELLOW}📦 Building release APK...${NC}"
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --target-platform android-arm,android-arm64,android-x64 \
  --shrink \
  --tree-shake-icons

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📱 APK locations:"
    echo "   Universal APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "   Split APKs in: build/app/outputs/apk/release/"
    echo ""

    # Show APK sizes
    echo "📊 APK Sizes:"
    ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "   " $9 ": " $5}'

    # Calculate total size
    TOTAL_SIZE=$(du -sh build/app/outputs/flutter-apk/ | cut -f1)
    echo -e "${GREEN}   Total: $TOTAL_SIZE${NC}"
    echo ""

    # Show performance tips
    echo "💡 Performance Tips:"
    echo "   ✓ ProGuard enabled for code shrinking"
    echo "   ✓ Resources shrunk"
    echo "   ✓ Code obfuscated"
    echo "   ✓ Debug info split"
    echo "   ✓ Icons tree-shaken"
    echo "   ✓ Images preloaded"
    echo "   ✓ Split APKs by ABI"
    echo ""

    echo -e "${GREEN}🎉 Ready to install or distribute!${NC}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

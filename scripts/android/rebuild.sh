#!/bin/bash

# Quick Android Rebuild Script
# Fixes common build issues by doing a clean rebuild

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "Android Clean Rebuild"
echo "========================================"
echo ""

# Source environment
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/29.0.13846066"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# Step 1: Build frontend
echo -e "${BLUE}Step 1/7:${NC} Building frontend..."
npm run build
echo -e "${GREEN}✓ Frontend built${NC}"
echo ""

# Step 2: Verify dist directory
echo -e "${BLUE}Step 2/7:${NC} Verifying dist directory..."
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    echo -e "${RED}✗ dist directory missing or incomplete${NC}"
    exit 1
fi
echo -e "${GREEN}✓ dist directory exists with $(ls dist/assets | wc -l | xargs) asset files${NC}"
echo ""

# Step 3: Clean Android build
echo -e "${BLUE}Step 3/7:${NC} Cleaning Android build..."
rm -rf src-tauri/gen/android/app/build
rm -rf src-tauri/gen/android/.gradle
echo -e "${GREEN}✓ Android build cleaned${NC}"
echo ""

# Step 4: Check device connection
echo -e "${BLUE}Step 4/7:${NC} Checking device connection..."
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No device/emulator connected${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "Start an emulator with: $SCRIPT_DIR/emulator.sh start"
    echo ""
    read -p "Start an emulator now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting emulator..."
        "$SCRIPT_DIR/emulator.sh" start
    else
        exit 1
    fi
else
    echo -e "${GREEN}✓ Device connected${NC}"
fi
echo ""

# Step 5: Uninstall old app
echo -e "${BLUE}Step 5/7:${NC} Uninstalling old app (if exists)..."
adb uninstall org.circuitassistant.camc 2>/dev/null || echo "No existing app to uninstall"
echo -e "${GREEN}✓ Old app removed${NC}"
echo ""

# Step 6: Clear logs
echo -e "${BLUE}Step 6/7:${NC} Clearing logcat..."
adb logcat -c
echo -e "${GREEN}✓ Logs cleared${NC}"
echo ""

# Step 7: Build and run
echo -e "${BLUE}Step 7/7:${NC} Building and deploying to Android..."
echo "This may take a few minutes..."
echo ""

npm run tauri:android:dev

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "If the app crashes, run:"
echo "  ./scripts/android/debug.sh crash"
echo ""
echo "To watch live logs:"
echo "  ./scripts/android/debug.sh watch"
echo ""




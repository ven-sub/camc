#!/bin/bash

# Android Emulator Management Script
# This script helps manage Android emulators for development

set -e

# Source environment variables
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default emulator name
DEFAULT_AVD="Pixel_7_API_34"
SYSTEM_IMAGE="system-images;android-34;google_apis;arm64-v8a"

echo "========================================="
echo "Android Emulator Manager"
echo "========================================="
echo ""

# Function to list emulators
list_emulators() {
    echo "Available emulators (from Android Studio and CLI):"
    local AVDS=$(emulator -list-avds 2>/dev/null)
    if [ -z "$AVDS" ]; then
        echo "  None found"
    else
        echo "$AVDS" | while read avd; do
            echo "  • $avd"
        done
    fi
    echo ""
    echo "💡 You can use any of these with: $0 start EMULATOR_NAME"
}

# Function to check if emulator is running
check_running() {
    RUNNING=$(adb devices | grep "emulator" | wc -l)
    if [ "$RUNNING" -gt 0 ]; then
        echo -e "${GREEN}✓ Emulator is running${NC}"
        adb devices | grep "emulator"
        return 0
    else
        echo -e "${YELLOW}No emulator currently running${NC}"
        return 1
    fi
}

# Function to create emulator
create_emulator() {
    local AVD_NAME="${1:-$DEFAULT_AVD}"
    
    echo "Creating emulator: $AVD_NAME"
    echo ""
    
    # Check if system image is installed
    echo "Checking for system image..."
    if ! sdkmanager --list_installed 2>/dev/null | grep -q "$SYSTEM_IMAGE"; then
        echo "Installing system image: $SYSTEM_IMAGE"
        echo "This may take several minutes..."
        yes | sdkmanager "$SYSTEM_IMAGE"
    else
        echo -e "${GREEN}✓ System image already installed${NC}"
    fi
    
    # Create AVD
    echo ""
    echo "Creating AVD..."
    echo "no" | avdmanager create avd \
        --name "$AVD_NAME" \
        --package "$SYSTEM_IMAGE" \
        --device "pixel_7" \
        --force
    
    echo -e "${GREEN}✓ Emulator created: $AVD_NAME${NC}"
}

# Function to start emulator
start_emulator() {
    local AVD_NAME="${1:-$DEFAULT_AVD}"
    
    # Check if already running
    if check_running > /dev/null 2>&1; then
        echo "An emulator is already running."
        return 0
    fi
    
    # Check if AVD exists
    if ! emulator -list-avds 2>/dev/null | grep -q "^$AVD_NAME$"; then
        echo -e "${RED}✗ Emulator '$AVD_NAME' not found${NC}"
        echo ""
        echo "Available emulators:"
        list_emulators
        echo "Create it with: $0 create $AVD_NAME"
        exit 1
    fi
    
    echo "Starting emulator: $AVD_NAME"
    echo "The emulator will open in a new window..."
    nohup emulator -avd "$AVD_NAME" > /dev/null 2>&1 &
    
    # Wait for emulator to boot
    echo "Waiting for emulator to boot..."
    adb wait-for-device
    echo -e "${GREEN}✓ Emulator is booting (this may take a minute)${NC}"
    
    # Wait for boot to complete
    while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 1
        echo -n "."
    done
    echo ""
    echo -e "${GREEN}✓ Emulator fully booted and ready!${NC}"
}

# Function to stop emulator
stop_emulator() {
    echo "Stopping emulator..."
    adb emu kill 2>/dev/null || true
    echo -e "${GREEN}✓ Emulator stopped${NC}"
}

# Function to delete emulator
delete_emulator() {
    local AVD_NAME="${1:-$DEFAULT_AVD}"
    
    echo "Deleting emulator: $AVD_NAME"
    avdmanager delete avd --name "$AVD_NAME"
    echo -e "${GREEN}✓ Emulator deleted${NC}"
}

# Main command handling
case "${1:-help}" in
    list)
        list_emulators
        check_running || true
        ;;
    create)
        create_emulator "$2"
        ;;
    start)
        start_emulator "$2"
        ;;
    stop)
        stop_emulator
        ;;
    restart)
        stop_emulator
        sleep 2
        start_emulator "$2"
        ;;
    delete)
        delete_emulator "$2"
        ;;
    status)
        check_running || true
        ;;
    help|*)
        echo "Usage: $0 [command] [emulator-name]"
        echo ""
        echo "Commands:"
        echo "  list              List all available emulators (Android Studio + CLI)"
        echo "  create [name]     Create a new emulator (default: $DEFAULT_AVD)"
        echo "  start [name]      Start an emulator (works with Android Studio emulators)"
        echo "  stop              Stop the running emulator"
        echo "  restart [name]    Restart the emulator"
        echo "  delete [name]     Delete an emulator"
        echo "  status            Check if emulator is running"
        echo "  help              Show this help message"
        echo ""
        echo "💡 Tip: You can use emulators created in Android Studio!"
        echo ""
        echo "Examples:"
        echo "  $0 list                              # See all available emulators"
        echo "  $0 start Medium_Phone_API_36.0       # Start existing Android Studio emulator"
        echo "  $0 create                            # Create default emulator"
        echo "  $0 start                             # Start default emulator"
        echo ""
        ;;
esac


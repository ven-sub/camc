#!/bin/bash

# Android Debug Helper Script
# Helps capture logs and debug crashes

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_PACKAGE="org.circuitassistant.camc"

echo "========================================"
echo "Android Debug Helper"
echo "========================================"
echo ""

# Function to check if device is connected
check_device() {
    DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        echo -e "${RED}✗ No Android device/emulator connected${NC}"
        echo "Start an emulator with: ./android-emulator.sh start"
        exit 1
    fi
    echo -e "${GREEN}✓ Device connected${NC}"
}

# Function to check if app is installed
check_app_installed() {
    if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
        echo -e "${GREEN}✓ App is installed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ App is not installed${NC}"
        return 1
    fi
}

# Function to get app info
app_info() {
    echo ""
    echo "=== App Information ==="
    if check_app_installed; then
        echo "Package: $APP_PACKAGE"
        adb shell dumpsys package "$APP_PACKAGE" | grep -E "versionName|versionCode" | head -2
    fi
}

# Function to capture crash logs
capture_crash_logs() {
    local OUTPUT_FILE="android-crash-$(date +%Y%m%d-%H%M%S).log"
    
    echo ""
    echo "=== Capturing Crash Logs ==="
    echo "Looking for crashes in last 500 lines..."
    echo ""
    
    # Get recent logs with crash info
    adb logcat -d -v time | tail -500 | grep -E "(FATAL|AndroidRuntime|CRASH|circuit|camc)" > "$OUTPUT_FILE"
    
    if [ -s "$OUTPUT_FILE" ]; then
        echo -e "${RED}Crash logs found and saved to: $OUTPUT_FILE${NC}"
        echo ""
        echo "=== Recent Crash Information ==="
        cat "$OUTPUT_FILE" | tail -50
    else
        echo "No crash logs found in recent logs"
        rm "$OUTPUT_FILE"
    fi
}

# Function to watch live logs
watch_logs() {
    echo ""
    echo "=== Live Log Stream (Ctrl+C to stop) ==="
    echo "Filtering for app-related logs..."
    echo ""
    adb logcat | grep --line-buffered -E "(circuit|camc|AndroidRuntime|FATAL|ERROR|RustStdoutStderr)"
}

# Function to watch live logs (all)
watch_logs_all() {
    echo ""
    echo "=== Live Log Stream - ALL (Ctrl+C to stop) ==="
    echo ""
    adb logcat -v time
}

# Function to clear logs
clear_logs() {
    echo "Clearing logcat buffer..."
    adb logcat -c
    echo -e "${GREEN}✓ Logs cleared${NC}"
}

# Function to uninstall app
uninstall_app() {
    echo "Uninstalling app..."
    adb uninstall "$APP_PACKAGE" 2>/dev/null
    echo -e "${GREEN}✓ App uninstalled${NC}"
}

# Function to get stack trace
get_stack_trace() {
    echo ""
    echo "=== Getting Stack Trace from Tombstone ==="
    adb shell "ls -lt /data/tombstones/ 2>/dev/null | head -5" || echo "No tombstones found"
}

# Function to check app permissions
check_permissions() {
    echo ""
    echo "=== App Permissions ==="
    if check_app_installed; then
        adb shell dumpsys package "$APP_PACKAGE" | grep -A 20 "granted=true"
    fi
}

# Function to launch app and capture logs
launch_and_capture() {
    local OUTPUT_FILE="app-launch-$(date +%Y%m%d-%H%M%S).log"
    
    echo ""
    echo "=== Launch App and Capture Logs ==="
    echo "This will:"
    echo "  1. Clear old logs"
    echo "  2. Launch your app"
    echo "  3. Capture all logs for 10 seconds"
    echo "  4. Save to: $OUTPUT_FILE"
    echo ""
    
    echo "Clearing old logs..."
    adb logcat -c
    
    echo "Launching app..."
    adb shell am start -n "$APP_PACKAGE/.MainActivity" 2>&1
    
    echo ""
    echo "Capturing logs for 10 seconds..."
    echo "(Logs are being saved to $OUTPUT_FILE)"
    echo ""
    
    # Capture logs for 10 seconds
    adb logcat -v time > "$OUTPUT_FILE" &
    LOGCAT_PID=$!
    
    sleep 10
    kill $LOGCAT_PID 2>/dev/null
    
    echo ""
    echo "=== Log capture complete ==="
    echo "Saved to: $OUTPUT_FILE"
    echo ""
    echo "Analyzing for errors..."
    echo ""
    
    # Show errors and crashes
    grep -E "(FATAL|AndroidRuntime|CRASH|circuit|camc|Error|Exception)" "$OUTPUT_FILE" | tail -100
    
    echo ""
    echo "=== Full log saved to: $OUTPUT_FILE ==="
    echo ""
    echo "To view full log: cat $OUTPUT_FILE"
    echo "To search for specific error: grep 'YourError' $OUTPUT_FILE"
}

# Main menu
case "${1:-help}" in
    crash)
        check_device
        capture_crash_logs
        ;;
    watch)
        check_device
        watch_logs
        ;;
    watch-all)
        check_device
        watch_logs_all
        ;;
    clear)
        check_device
        clear_logs
        ;;
    info)
        check_device
        app_info
        check_permissions
        ;;
    uninstall)
        check_device
        uninstall_app
        ;;
    stack)
        check_device
        get_stack_trace
        ;;
    launch)
        check_device
        launch_and_capture
        ;;
    full-debug)
        check_device
        app_info
        check_permissions
        capture_crash_logs
        ;;
    help|*)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  crash        Capture and display crash logs"
        echo "  launch       Launch app and capture startup logs"
        echo "  watch        Watch live filtered logs (app-related)"
        echo "  watch-all    Watch all live logs"
        echo "  clear        Clear the logcat buffer"
        echo "  info         Show app information and permissions"
        echo "  uninstall    Uninstall the app from device"
        echo "  stack        Get stack trace from tombstones"
        echo "  full-debug   Run full diagnostic (info + crash logs)"
        echo "  help         Show this help"
        echo ""
        echo "Debugging Workflows:"
        echo ""
        echo "After crash:"
        echo "  1. $0 crash           # Capture crash logs"
        echo ""
        echo "Fresh launch debugging:"
        echo "  1. $0 clear           # Clear old logs"
        echo "  2. $0 launch          # Launch app and capture logs"
        echo ""
        echo "Live debugging:"
        echo "  $0 watch              # Watch filtered logs"
        echo ""
        ;;
esac




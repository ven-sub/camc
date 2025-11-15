#!/bin/bash

# Android Development Setup Script
# Usage:
#   ./setup.sh              - Full setup (install NDK, SDK components)
#   ./setup.sh --env-only   - Just set environment variables (for sourcing)
#   source ./setup.sh --env-only

# Set environment variables
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_VERSION="29.0.13846066"
export NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# If --env-only flag, just set environment and exit
if [ "${1}" = "--env-only" ]; then
    echo "Android environment variables set:"
    echo "ANDROID_HOME: $ANDROID_HOME"
    echo "NDK_HOME: $NDK_HOME"
    echo "PATH updated with Android tools"
    return 0 2>/dev/null || exit 0
fi

set -e

echo "========================================="
echo "Android Development Setup Script"
echo "========================================="
echo ""

echo "✓ Environment variables set:"
echo "  ANDROID_HOME: $ANDROID_HOME"
echo "  NDK_HOME: $NDK_HOME"
echo ""

# Check if cmdline-tools exists
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    echo "✗ Android cmdline-tools not found at expected location"
    exit 1
fi
echo "✓ Android cmdline-tools found"

# Check if NDK is already installed
if [ -d "$NDK_HOME" ] && [ -f "$NDK_HOME/ndk-build" ]; then
    echo "✓ NDK already installed at $NDK_HOME"
else
    echo "Installing Android NDK $NDK_VERSION..."
    echo "This may take several minutes depending on your internet connection."
    sdkmanager --install "ndk;$NDK_VERSION"
    
    if [ -d "$NDK_HOME" ] && [ -f "$NDK_HOME/ndk-build" ]; then
        echo "✓ NDK installed successfully"
    else
        echo "✗ NDK installation failed"
        exit 1
    fi
fi

# Install additional required tools
echo ""
echo "Installing additional Android SDK components..."
sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To use these settings in your current shell, run:"
echo "  source ./scripts/android/setup.sh --env-only"
echo ""
echo "Or add to your ~/.zshrc for permanent setup:"
echo "  export ANDROID_HOME=\"$HOME/Library/Android/sdk\""
echo "  export NDK_HOME=\"\$ANDROID_HOME/ndk/$NDK_VERSION\""
echo "  export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator\""
echo ""
echo "Next steps:"
echo "  1. Run: npm run android:init"
echo "  2. Run: npm run tauri:android:dev"
echo ""




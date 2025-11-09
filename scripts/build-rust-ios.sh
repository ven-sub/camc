#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_TAURI="$ROOT_DIR/src-tauri"
EXTERNALS_DIR="$SRC_TAURI/gen/apple/Externals"
BUILD_DIR="$ROOT_DIR/build/rust-ios-xcframework"

echo "Building Rust device+sim libs and creating XCFramework..."

mkdir -p "$EXTERNALS_DIR" "$BUILD_DIR"

# Ensure common targets are installed (ignore errors)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios-sim || true

# Find simulator SDK path
SIM_SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null || true)
echo "Simulator SDK: $SIM_SDKROOT"

cd "$SRC_TAURI"

echo "Building device (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios || true

echo "Building simulator (aarch64-apple-ios-sim)..."
SDKROOT="$SIM_SDKROOT" cargo build --release --target aarch64-apple-ios-sim || true

if rustup target list --installed | grep -q "x86_64-apple-ios-sim"; then
  echo "Building simulator (x86_64-apple-ios-sim)..."
  SDKROOT="$SIM_SDKROOT" cargo build --release --target x86_64-apple-ios-sim || true
fi

# Prepare staging for xcframework
STAGE="$BUILD_DIR/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/device" "$STAGE/sim_arm64" "$STAGE/sim_x86_64" "$STAGE/headers"

DEV_LIB="$SRC_TAURI/target/aarch64-apple-ios/release/libcircuit_assistant_mobile_companion.a"
SIM_ARM_LIB="$SRC_TAURI/target/aarch64-apple-ios-sim/release/libcircuit_assistant_mobile_companion.a"
SIM_X86_LIB="$SRC_TAURI/target/x86_64-apple-ios-sim/release/libcircuit_assistant_mobile_companion.a"

if [ -f "$DEV_LIB" ]; then
  cp -f "$DEV_LIB" "$STAGE/device/libapp.a"
  echo "Copied device lib"
fi
if [ -f "$SIM_ARM_LIB" ]; then
  cp -f "$SIM_ARM_LIB" "$STAGE/sim_arm64/libapp.a"
  echo "Copied sim arm64 lib"
fi
if [ -f "$SIM_X86_LIB" ]; then
  cp -f "$SIM_X86_LIB" "$STAGE/sim_x86_64/libapp.a"
  echo "Copied sim x86_64 lib"
fi

# Create minimal headers dir required by xcodebuild -library -headers
echo "// dummy header for libapp" > "$STAGE/headers/libapp.h"

# Build XCFramework
XCOUT="$EXTERNALS_DIR/libapp.xcframework"
echo "Creating XCFramework at $XCOUT"
rm -rf "$XCOUT"

XCODEBUILD_ARGS=()
if [ -f "$STAGE/device/libapp.a" ]; then
  XCODEBUILD_ARGS+=( -library "$STAGE/device/libapp.a" -headers "$STAGE/headers" )
fi
if [ -f "$STAGE/sim_arm64/libapp.a" ]; then
  XCODEBUILD_ARGS+=( -library "$STAGE/sim_arm64/libapp.a" -headers "$STAGE/headers" )
fi
if [ -f "$STAGE/sim_x86_64/libapp.a" ]; then
  XCODEBUILD_ARGS+=( -library "$STAGE/sim_x86_64/libapp.a" -headers "$STAGE/headers" )
fi

if [ ${#XCODEBUILD_ARGS[@]} -eq 0 ]; then
  echo "No libraries were built - skipping XCFramework creation"
else
  xcodebuild -create-xcframework "${XCODEBUILD_ARGS[@]}" -output "$XCOUT"
  echo "XCFramework created: $XCOUT"
fi

# Also keep a simulator lib copy for backward compatibility (flat .a in Externals arch/config)
mkdir -p "$EXTERNALS_DIR/arm64/Release" "$EXTERNALS_DIR/arm64/release" "$EXTERNALS_DIR/arm64/Debug" "$EXTERNALS_DIR/arm64/debug"
if [ -f "$STAGE/sim_arm64/libapp.a" ]; then
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/arm64/release/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/arm64/Release/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/arm64/debug/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/arm64/Debug/libapp.a"
fi

# Populate x86_64 folders with sim_arm64 copy for compatibility (Xcode may look there)
mkdir -p "$EXTERNALS_DIR/x86_64/Release" "$EXTERNALS_DIR/x86_64/release" "$EXTERNALS_DIR/x86_64/Debug" "$EXTERNALS_DIR/x86_64/debug"
if [ -f "$STAGE/sim_arm64/libapp.a" ]; then
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/x86_64/release/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/x86_64/Release/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/x86_64/debug/libapp.a"
  cp -f "$STAGE/sim_arm64/libapp.a" "$EXTERNALS_DIR/x86_64/Debug/libapp.a"
fi

echo "Done. xcframework and compatibility libs are in $EXTERNALS_DIR"

exit 0

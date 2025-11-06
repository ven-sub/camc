#!/bin/bash
# Script to create the Tauri wrapper script for iOS builds
# This is extracted to avoid GitHub Actions expression length limits

set -e

WRAPPER_SCRIPT="$1"
if [ -z "$WRAPPER_SCRIPT" ]; then
    echo "Error: WRAPPER_SCRIPT path not provided"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Write the wrapper script
cat > "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
#!/bin/bash
set -e
set -x

# Log to file for debugging (Xcode may suppress stderr)
LOG_FILE="${TMPDIR:-/tmp}/tauri-wrapper.log"
echo "=== Wrapper Script Started === $(date)" > "$LOG_FILE"
echo "Log file: $LOG_FILE" >> "$LOG_FILE"
echo "Script location: ${BASH_SOURCE[0]}" >> "$LOG_FILE"
echo "SRCROOT=${SRCROOT}" >> "$LOG_FILE"
echo "CONFIGURATION=${CONFIGURATION}" >> "$LOG_FILE"
echo "PWD=$(pwd)" >> "$LOG_FILE"

# Also output to stderr for Xcode
exec 2>&1
exec > >(tee -a "$LOG_FILE" 2>&1)

echo "Script location: ${BASH_SOURCE[0]}"
echo "SRCROOT=${SRCROOT}"
echo "CONFIGURATION=${CONFIGURATION}"
echo "PWD=$(pwd)"

# Set environment variables to force production build (not dev server)
# CRITICAL: Tauri uses debug vs release build profile to determine dev vs prod mode
# We MUST use release profile to get bundled assets instead of dev server
export RUST_BACKTRACE=full
export CI=true

# Force Cargo to build in release mode (this is what Tauri checks)
# Without this, Tauri builds in debug mode and tries to connect to devUrl
export TAURI_CLI_PROFILE=release

echo "=== Environment Variables Set ==="
echo "TAURI_SKIP_DEV_SERVER=${TAURI_SKIP_DEV_SERVER}"
echo "TAURI_DEV_HOST=${TAURI_DEV_HOST}"
echo "RUST_BACKTRACE=${RUST_BACKTRACE}"
echo "CI=${CI}"
echo "=== End Environment Variables ==="
echo ""

# Create dev server addr file with dummy host and start dummy TCP listener
# Tauri CLI REQUIRES this file to exist and will panic if missing
# Tauri will try to connect, so we create a dummy listener that accepts and closes
SERVER_ADDR_FILE="${TMPDIR:-/tmp}/org.circuitassistant.camc-server-addr"
DUMMY_HOST="127.0.0.1"
DUMMY_PORT="12345"

echo "Creating dev server addr file: $SERVER_ADDR_FILE"
mkdir -p "$(dirname "$SERVER_ADDR_FILE")" || { echo "ERROR: Failed to create directory"; exit 1; }
echo "${DUMMY_HOST}:${DUMMY_PORT}" > "$SERVER_ADDR_FILE" || { echo "ERROR: Failed to write server addr file"; exit 1; }
echo "Wrote dummy host to server addr file: ${DUMMY_HOST}:${DUMMY_PORT}"
echo ""

# Start dummy TCP listener in background that accepts and immediately closes connections
# This prevents "Connection refused" errors while satisfying Tauri's connection attempt
DUMMY_PID_FILE="${TMPDIR:-/tmp}/tauri-dummy-server.pid"
if [ -f "$DUMMY_PID_FILE" ]; then
    OLD_PID=$(cat "$DUMMY_PID_FILE" 2>/dev/null)
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$DUMMY_PID_FILE"
fi

if command -v socat >/dev/null 2>&1; then
    echo "Starting dummy TCP server with socat on ${DUMMY_HOST}:${DUMMY_PORT}"
    socat TCP-LISTEN:${DUMMY_PORT},bind=${DUMMY_HOST},fork,reuseaddr EXEC:"/bin/true" >/dev/null 2>&1 &
    echo $! > "$DUMMY_PID_FILE"
elif command -v python3 >/dev/null 2>&1; then
    echo "Starting dummy TCP server with Python on ${DUMMY_HOST}:${DUMMY_PORT}"
    PYTHON_SCRIPT="${TMPDIR:-/tmp}/tauri-dummy-server.py"
    # Copy the Python script from the repository
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    cp "$PROJECT_ROOT/.github/scripts/tauri-dummy-server.py" "$PYTHON_SCRIPT" 2>/dev/null || {
        # Fallback: create a simple server inline if script not found
        python3 << 'SIMPLE_SERVER_EOF' >/dev/null 2>&1 &
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 12345))
s.listen(5)
while True:
  try:
    conn, addr = s.accept()
    conn.close()
  except:
    break
SIMPLE_SERVER_EOF
        echo $! > "$DUMMY_PID_FILE"
    }
    if [ -f "$PYTHON_SCRIPT" ]; then
        python3 "$PYTHON_SCRIPT" >/dev/null 2>&1 &
        echo $! > "$DUMMY_PID_FILE"
    fi
elif command -v nc >/dev/null 2>&1; then
    echo "Starting dummy TCP server with nc on ${DUMMY_HOST}:${DUMMY_PORT}"
    while true; do nc -l ${DUMMY_HOST} ${DUMMY_PORT} >/dev/null 2>&1; done &
    echo $! > "$DUMMY_PID_FILE"
else
    echo "WARNING: No suitable tool (socat/nc/python3) found for dummy server"
    echo "Tauri may fail with Connection refused - checking if port is available"
fi

sleep 0.5
echo "Dummy server started (PID: $(cat "$DUMMY_PID_FILE" 2>/dev/null || echo unknown))"
echo ""

# Cleanup function to kill dummy server on exit
cleanup_dummy_server() {
    if [ -f "$DUMMY_PID_FILE" ]; then
        DUMMY_PID=$(cat "$DUMMY_PID_FILE" 2>/dev/null)
        if kill -0 "$DUMMY_PID" 2>/dev/null; then
            kill "$DUMMY_PID" 2>/dev/null || true
            echo "Stopped dummy TCP server"
        fi
        rm -f "$DUMMY_PID_FILE"
    fi
}
trap cleanup_dummy_server EXIT
echo ""

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Ensure npm/node are in PATH
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"
# Add node_modules/.bin to PATH if it exists
if [ -d "node_modules/.bin" ]; then
    export PATH="$PROJECT_ROOT/node_modules/.bin:$PATH"
fi

# Set up iOS cross-compilation environment for Rust
# CRITICAL: Build scripts run on macOS, but target compiles for iOS
# We must explicitly set the macOS SDK for build scripts
MACOS_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
export SDKROOT="$MACOS_SDK_PATH"

# Target-specific settings for iOS cross-compilation
export CC_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang)"
export CXX_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang++)"
export AR_aarch64_apple_ios="$(xcrun --sdk iphoneos --find ar)"
export CARGO_TARGET_AARCH64_APPLE_IOS_LINKER="$(xcrun --sdk iphoneos --find clang)"

# Ensure build scripts use macOS SDK (not iOS SDK)
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CFLAGS_aarch64_apple_darwin="-isysroot $MACOS_SDK_PATH"
export CXXFLAGS_aarch64_apple_darwin="-isysroot $MACOS_SDK_PATH"

echo "Running: npm run -- tauri ios xcode-script $*"
echo "PATH: $PATH"
echo "SDKROOT: $SDKROOT"
echo "CC_aarch64_apple_ios: $CC_aarch64_apple_ios"
echo "npm location: $(which npm 2>/dev/null || echo 'not found')"
echo "npx location: $(which npx 2>/dev/null || echo 'not found')"

# Always run Tauri build to ensure iOS FFI exports are generated
echo "=== Running Tauri build to generate iOS FFI exports ==="
cd "$PROJECT_ROOT" || { echo "ERROR: Failed to cd to $PROJECT_ROOT"; exit 1; }
echo "Current directory: $(pwd)"
echo "Log file location: $LOG_FILE"
echo "Starting Tauri build at $(date)"

# Force --configuration to Release to ensure Cargo builds in release mode
# Even if Xcode passes "Debug", we override it because we NEED release builds for production
# This ensures Tauri uses bundled assets (frontendDist) instead of dev server (devUrl)
FORCE_CONFIG="Release"
echo "Forcing configuration to: $FORCE_CONFIG (overriding Xcode's ${CONFIGURATION:-unknown})"

# Replace any --configuration argument with Release
FILTERED_ARGS=()
SKIP_NEXT=false
for arg in "$@"; do
    if [ "$SKIP_NEXT" = true ]; then
        SKIP_NEXT=false
        FILTERED_ARGS+=("$FORCE_CONFIG")
        continue
    fi
    if [ "$arg" = "--configuration" ]; then
        SKIP_NEXT=true
        FILTERED_ARGS+=("$arg")
    else
        FILTERED_ARGS+=("$arg")
    fi
done

echo "Running: npm run -- tauri ios xcode-script ${FILTERED_ARGS[*]}"

npm run -- tauri ios xcode-script "${FILTERED_ARGS[@]}"
TAURI_EXIT_CODE=$?
echo "Tauri build completed with exit code: $TAURI_EXIT_CODE"
echo "Log file contents:"
cat "$LOG_FILE" 2>/dev/null || echo "Log file not found"
exit $TAURI_EXIT_CODE
WRAPPER_EOF

chmod +x "$WRAPPER_SCRIPT"
echo "Wrapper script created at: $WRAPPER_SCRIPT"


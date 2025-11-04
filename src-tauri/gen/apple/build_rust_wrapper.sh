#!/bin/bash
set -e
set -x
exec >&2

echo "=== Wrapper Script Started ==="
echo "Script location: ${BASH_SOURCE[0]}"
echo "SRCROOT=${SRCROOT}"
echo "CONFIGURATION=${CONFIGURATION}"

# Set environment variables to prevent dev server connection in CI
export TAURI_SKIP_DEV_SERVER=1
export TAURI_DEV_HOST="127.0.0.1:1"
export RUST_BACKTRACE=full
export CI=true
export RELEASE_BUILD=true

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
    # Prefer Python over nc for better control
    # Handle WebSocket handshake to prevent "UnexpectedEof" errors
    echo "Starting dummy TCP server with Python on ${DUMMY_HOST}:${DUMMY_PORT}"
    PYTHON_SCRIPT="${TMPDIR:-/tmp}/tauri-dummy-server.py"
    cat > "$PYTHON_SCRIPT" << 'PYTHON_SCRIPT_EOF'
import socket
import sys
import hashlib
import base64

def handle_websocket_handshake(conn):
    """Handle WebSocket HTTP upgrade request and keep connection alive"""
    try:
        request = conn.recv(4096).decode('utf-8')
        if not request:
            return
        lines = request.split('\r\n')
        key = None
        for line in lines:
            if line.startswith('Sec-WebSocket-Key:'):
                key = line.split(':', 1)[1].strip()
                break
        if key:
            magic_string = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
            accept_key = base64.b64encode(
                hashlib.sha1((key + magic_string).encode()).digest()
            ).decode()
            accept_header = 'Sec-WebSocket-Accept: ' + accept_key + '\r\n'
            response = (
                'HTTP/1.1 101 Switching Protocols\r\n'
                'Upgrade: websocket\r\n'
                'Connection: Upgrade\r\n'
                + accept_header +
                '\r\n'
            )
            conn.send(response.encode('utf-8'))
            
            # Keep connection open and handle WebSocket frames with JSON-RPC responses
            # Tauri will send JSON-RPC requests, we need to respond appropriately
            conn.settimeout(30.0)  # Longer timeout to allow Tauri to complete
            try:
                while True:
                    data = conn.recv(4096)
                    if not data:
                        break
                    
                    # Parse WebSocket frame (simplified - assumes masked client frames)
                    if len(data) < 6:
                        break
                    
                    # Check for close frame
                    if (data[0] & 0x0F) == 0x8:
                        close_frame = bytearray([0x88, 0x00])
                        conn.send(close_frame)
                        break
                    
                    # For text frames, decode and respond with JSON-RPC response
                    if (data[0] & 0x0F) == 0x1:  # Text frame
                        # Extract payload (skip frame header and mask)
                        mask_start = 2
                        if data[1] & 0x7F == 126:
                            mask_start = 4
                        elif data[1] & 0x7F == 127:
                            mask_start = 10
                        mask = data[mask_start:mask_start+4]
                        payload_start = mask_start + 4
                        payload_len = data[1] & 0x7F
                        if payload_len == 126:
                            payload_len = (data[2] << 8) | data[3]
                            payload_start = 8
                        elif payload_len == 127:
                            payload_start = 14
                        
                        payload = bytearray()
                        for i in range(payload_len):
                            payload.append(data[payload_start + i] ^ mask[i % 4])
                        
                        # Try to parse as JSON-RPC and send appropriate response
                        try:
                            import json
                            req = json.loads(payload.decode('utf-8'))
                            method = req.get("method", "")
                            
                            # Build complete CLI options response that Tauri expects
                            # Include all common fields that Tauri CLI might need
                            result = {
                                "dev": False,
                                "args": [],
                                "noise_level": "Polite",
                                "target": None,
                                "features": [],
                                "release": False,
                                "debug": False,
                                "verbose": False,
                                "vars": {},
                                "config": []
                            }
                            
                            # Send JSON-RPC response
                            response_obj = {
                                "jsonrpc": "2.0",
                                "id": req.get("id"),
                                "result": result
                            }
                            response_json = json.dumps(response_obj)
                            # Send as WebSocket text frame
                            response_frame = bytearray([0x81])  # FIN + text frame
                            response_len = len(response_json)
                            if response_len < 126:
                                response_frame.append(response_len)
                            elif response_len < 65536:
                                response_frame.append(126)
                                response_frame.append((response_len >> 8) & 0xFF)
                                response_frame.append(response_len & 0xFF)
                            response_frame.extend(response_json.encode('utf-8'))
                            conn.send(response_frame)
                        except:
                            # If JSON parsing fails, just keep connection open
                            pass
            except socket.timeout:
                pass
            except:
                pass
        else:
            response = 'HTTP/1.1 200 OK\r\n\r\n'
            conn.send(response.encode('utf-8'))
    except:
        pass
    finally:
        conn.close()

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 12345))
s.listen(5)
while True:
    try:
        conn, addr = s.accept()
        handle_websocket_handshake(conn)
    except:
        break
PYTHON_SCRIPT_EOF
    python3 "$PYTHON_SCRIPT" >/dev/null 2>&1 &
    echo $! > "$DUMMY_PID_FILE"
elif command -v nc >/dev/null 2>&1; then
    echo "Starting dummy TCP server with nc on ${DUMMY_HOST}:${DUMMY_PORT}"
    while true; do nc -l ${DUMMY_HOST} ${DUMMY_PORT} >/dev/null 2>&1; done &
    echo $! > "$DUMMY_PID_FILE"
else
    echo "WARNING: No suitable tool (socat/python3/nc) found for dummy server"
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
# Important: Don't set SDKROOT globally as it affects build scripts (which need macOS SDK)
# Only set target-specific variables
export CC_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang)"
export CXX_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang++)"
export AR_aarch64_apple_ios="$(xcrun --sdk iphoneos --find ar)"
export CARGO_TARGET_AARCH64_APPLE_IOS_LINKER="$(xcrun --sdk iphoneos --find clang)"
# Build scripts should use host toolchain, so ensure macOS SDK for them
export MACOSX_DEPLOYMENT_TARGET="10.15"

echo "Running: npm run -- tauri ios xcode-script $*"
echo "PATH: $PATH"
echo "SDKROOT: $SDKROOT"
echo "CC_aarch64_apple_ios: $CC_aarch64_apple_ios"
echo "npm location: $(which npm 2>/dev/null || echo 'not found')"
echo "npx location: $(which npx 2>/dev/null || echo 'not found')"

# Use npx to ensure tauri is found, or fall back to npm run
if command -v npx >/dev/null 2>&1; then
    echo "Using npx to run tauri..."
    npx --no-install tauri ios xcode-script "$@" || npm run -- tauri ios xcode-script "$@"
else
    npm run -- tauri ios xcode-script "$@"
fi
TAURI_EXIT_CODE=$?
echo "Tauri build completed with exit code: $TAURI_EXIT_CODE"
exit $TAURI_EXIT_CODE

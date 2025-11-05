#!/bin/bash
# Local script to build iOS app and upload to TestFlight
# This replicates the GitHub Actions workflow locally

set -e

echo "=== Building iOS App Locally for TestFlight ==="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if required tools are installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm not found. Please install Node.js.${NC}"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo not found. Please install Rust.${NC}"
    exit 1
fi

# Load secrets from build-ios-secrets.txt if it exists
# Check Shared folder first, then current directory
SHARED_SECRETS="/Users/vensubramanian/Downloads/Shared/build-ios-secrets.txt"
SECRETS_FILE="build-ios-secrets.txt"

if [ -f "$SHARED_SECRETS" ]; then
    SECRETS_FILE="$SHARED_SECRETS"
    echo -e "${YELLOW}Using secrets from Shared folder: $SECRETS_FILE${NC}"
elif [ -f "$SECRETS_FILE" ]; then
    echo -e "${YELLOW}Using secrets from current directory: $SECRETS_FILE${NC}"
fi

if [ -f "$SECRETS_FILE" ]; then
    echo -e "${YELLOW}Loading secrets from $SECRETS_FILE...${NC}"
    
    # Parse the secrets file (handles multiline values including base64)
    CURRENT_VAR=""
    CURRENT_VALUE=""
    IN_MULTILINE=false
    IN_BASE64=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines (but handle them differently for base64 vs multiline)
        if [[ -z "$line" ]]; then
            # For multiline (PRIVATE KEY), empty lines are part of the value
            if [ "$IN_MULTILINE" = true ]; then
                CURRENT_VALUE="$CURRENT_VALUE"$'\n'
            fi
            # For base64, empty lines are separators - skip them
            # The value continues on the next non-empty line
            continue
        fi
        
        # Check if this line starts a variable assignment
        if [[ "$line" =~ ^[[:space:]]*([A-Z_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            # Export previous variable if we were collecting multiline or base64
            if [ -n "$CURRENT_VAR" ]; then
                # For base64, remove any trailing newlines/whitespace
                if [ "$IN_BASE64" = true ]; then
                    CURRENT_VALUE=$(echo -n "$CURRENT_VALUE" | tr -d '\n\r')
                    if [ -n "$DEBUG_SECRETS" ]; then
                        echo "Debug: Exporting base64 var $CURRENT_VAR, length: ${#CURRENT_VALUE}"
                    fi
                fi
                export "$CURRENT_VAR"="$CURRENT_VALUE"
                CURRENT_VAR=""
                CURRENT_VALUE=""
                IN_BASE64=false
                IN_MULTILINE=false
            fi
            
            # Start new variable
            CURRENT_VAR="${BASH_REMATCH[1]}"
            CURRENT_VALUE="${BASH_REMATCH[2]}"
            
            # Check if this is a multiline value (starts with -----BEGIN)
            if [[ "$CURRENT_VALUE" =~ ^-----BEGIN ]]; then
                IN_MULTILINE=true
                IN_BASE64=false
            elif [[ "$CURRENT_VAR" =~ _BASE64$ ]]; then
                # Base64 value - may continue on next lines until we see a new VAR= assignment
                # For now, mark as base64 and continue (will export when next var is found or at EOF)
                IN_BASE64=true
                IN_MULTILINE=false
                if [ -n "$DEBUG_SECRETS" ]; then
                    echo "Debug: Set IN_BASE64=true for $CURRENT_VAR, value length: ${#CURRENT_VALUE}"
                fi
            else
                IN_MULTILINE=false
                IN_BASE64=false
                # Single line value - export immediately
                export "$CURRENT_VAR"="$CURRENT_VALUE"
                CURRENT_VAR=""
                CURRENT_VALUE=""
            fi
        elif [ "$IN_MULTILINE" = true ] && [ -n "$CURRENT_VAR" ]; then
            # Continue collecting multiline value (PRIVATE KEY)
            CURRENT_VALUE="$CURRENT_VALUE"$'\n'"$line"
            # Check if we've reached the end
            if [[ "$line" =~ ^-----END ]]; then
                export "$CURRENT_VAR"="$CURRENT_VALUE"
                CURRENT_VAR=""
                CURRENT_VALUE=""
                IN_MULTILINE=false
            fi
        elif [ "$IN_BASE64" = true ] && [ -n "$CURRENT_VAR" ]; then
            # Continue collecting base64 value (may span multiple lines)
            # Check if this line starts a new variable (stops base64 collection)
            if [[ "$line" =~ ^[[:space:]]*[A-Z_]+[[:space:]]*= ]]; then
                # New variable starts - export previous base64 variable first
                # Remove any trailing newlines/whitespace from base64 value
                CURRENT_VALUE=$(echo -n "$CURRENT_VALUE" | tr -d '\n\r')
                export "$CURRENT_VAR"="$CURRENT_VALUE"
                CURRENT_VAR=""
                CURRENT_VALUE=""
                IN_BASE64=false
                # Process this line as new variable
                if [[ "$line" =~ ^[[:space:]]*([A-Z_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
                    CURRENT_VAR="${BASH_REMATCH[1]}"
                    CURRENT_VALUE="${BASH_REMATCH[2]}"
                    if [[ "$CURRENT_VALUE" =~ ^-----BEGIN ]]; then
                        IN_MULTILINE=true
                        IN_BASE64=false
                    elif [[ "$CURRENT_VAR" =~ _BASE64$ ]]; then
                        IN_BASE64=true
                        IN_MULTILINE=false
                    else
                        export "$CURRENT_VAR"="$CURRENT_VALUE"
                        CURRENT_VAR=""
                        CURRENT_VALUE=""
                        IN_BASE64=false
                    fi
                fi
            else
                # Continue base64 value (remove leading/trailing whitespace and newlines)
                TRIMMED_LINE=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ -n "$TRIMMED_LINE" ]; then
                    # Remove any newlines from the trimmed line and append
                    TRIMMED_LINE=$(echo -n "$TRIMMED_LINE" | tr -d '\n\r')
                    CURRENT_VALUE="$CURRENT_VALUE$TRIMMED_LINE"
                fi
            fi
        fi
    done < "$SECRETS_FILE"
    
    # Export last variable if still collecting
    if [ -n "$CURRENT_VAR" ]; then
        # For base64, remove trailing newlines/whitespace
        if [ "$IN_BASE64" = true ]; then
            CURRENT_VALUE=$(echo -n "$CURRENT_VALUE" | tr -d '\n\r')
        fi
        export "$CURRENT_VAR"="$CURRENT_VALUE"
    fi
    
    # Debug: Show what variables were loaded
    if [ -n "$DEBUG_SECRETS" ]; then
        echo "Debug: Loaded variables:"
        env | grep -E "(APPSTORE_|IOS_)" | sed 's/=.*/=***/' || true
    fi
    echo -e "${GREEN}✓ Secrets loaded${NC}"
else
    echo -e "${YELLOW}Warning: $SECRETS_FILE not found, checking environment variables...${NC}"
fi

# Check for App Store Connect API credentials
if [ -z "$APPSTORE_KEY_ID" ] || [ -z "$APPSTORE_ISSUER_ID" ] || [ -z "$APPSTORE_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: App Store Connect API credentials not found${NC}"
    echo "Please create $SECRETS_FILE with:"
    echo "  APPSTORE_KEY_ID=your-key-id"
    echo "  APPSTORE_ISSUER_ID=your-issuer-id"
    echo "  APPSTORE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
    echo ""
    echo "Or set them as environment variables:"
    echo "  export APPSTORE_KEY_ID='your-key-id'"
    echo "  export APPSTORE_ISSUER_ID='your-issuer-id'"
    echo "  export APPSTORE_PRIVATE_KEY='your-private-key'"
    exit 1
fi

# Check for provisioning profile
PROVISIONING_PROFILE_UUID="${PROVISIONING_PROFILE_UUID:-95c1181d-ee52-4cd0-ba2a-4eebb8f10b2d}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-Y573Y5T7X3}"

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Step 0: Install provisioning profile and certificate if available
# Check for actual .mobileprovision file first (from Shared folder), then base64
SHARED_PROFILE="/Users/vensubramanian/Downloads/Shared/CAMC_iOS_MoCom.mobileprovision"
PROVISIONING_PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROVISIONING_PROFILES_DIR"
PROVISIONING_PROFILE_PATH="$PROVISIONING_PROFILES_DIR/$PROVISIONING_PROFILE_UUID.mobileprovision"

if [ -f "$SHARED_PROFILE" ]; then
    echo -e "${YELLOW}Step 0: Installing provisioning profile from Shared folder...${NC}"
    cp "$SHARED_PROFILE" "$PROVISIONING_PROFILE_PATH"
    echo -e "${GREEN}✓ Provisioning profile copied from $SHARED_PROFILE${NC}"
elif [ -n "$IOS_PROVISIONING_PROFILE_BASE64" ]; then
    echo -e "${YELLOW}Step 0: Installing provisioning profile from base64...${NC}"
    # Decode and save provisioning profile
    echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 -d > "$PROVISIONING_PROFILE_PATH"
    echo -e "${GREEN}✓ Provisioning profile installed from base64${NC}"
fi

# Verify it was installed
if [ -f "$PROVISIONING_PROFILE_PATH" ]; then
    PROFILE_UUID=$(/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< "$(security cms -D -i "$PROVISIONING_PROFILE_PATH")" 2>/dev/null || echo "unknown")
    echo "Profile UUID: $PROFILE_UUID"
    echo "Profile path: $PROVISIONING_PROFILE_PATH"
    echo ""
else
    echo -e "${YELLOW}Warning: Provisioning profile not found. Archive may fail.${NC}"
    echo ""
fi

# Debug: Check if certificate variables are set (from secrets file or environment)
if [ -z "$IOS_CERTIFICATE_BASE64" ]; then
    echo -e "${YELLOW}Note: IOS_CERTIFICATE_BASE64 not found in secrets file${NC}"
    echo -e "${YELLOW}You can export it as an environment variable: export IOS_CERTIFICATE_BASE64='...'${NC}"
fi
if [ -z "$IOS_CERTIFICATE_PASSWORD" ]; then
    echo -e "${YELLOW}Note: IOS_CERTIFICATE_PASSWORD not found in secrets file${NC}"
    echo -e "${YELLOW}You can export it as an environment variable: export IOS_CERTIFICATE_PASSWORD='...'${NC}"
fi

if [ -n "$IOS_CERTIFICATE_BASE64" ] && [ -n "$IOS_CERTIFICATE_PASSWORD" ]; then
    echo -e "${YELLOW}Step 0b: Installing code signing certificate...${NC}"
    CERT_TEMP=$(mktemp).p12
    
    # Decode base64 certificate
    echo "$IOS_CERTIFICATE_BASE64" | base64 -d > "$CERT_TEMP" 2>&1
    if [ ! -s "$CERT_TEMP" ]; then
        echo -e "${RED}Error: Failed to decode certificate base64${NC}"
        rm -f "$CERT_TEMP"
    else
        # Import certificate into keychain
        IMPORT_OUTPUT=$(security import "$CERT_TEMP" \
            -k ~/Library/Keychains/login.keychain \
            -P "$IOS_CERTIFICATE_PASSWORD" \
            -T /usr/bin/codesign \
            -T /usr/bin/security \
            2>&1)
        IMPORT_EXIT=$?
        
        if [ $IMPORT_EXIT -eq 0 ]; then
            echo -e "${GREEN}✓ Certificate imported successfully${NC}"
        else
            # Check if it's already installed (exit code 1 is common for already-installed certs)
            if echo "$IMPORT_OUTPUT" | grep -qi "already exists\|duplicate"; then
                echo -e "${YELLOW}Certificate already exists in keychain${NC}"
            else
                echo -e "${YELLOW}Warning: Certificate import may have failed:${NC}"
                echo "$IMPORT_OUTPUT" | head -5
            fi
        fi
        
        # Clean up temp file
        rm -f "$CERT_TEMP"
        
        # Verify certificate is installed
        echo "Installed certificates:"
        security find-identity -v -p codesigning | grep -i "distribution\|Y573Y5T7X3" || echo "No distribution certificates found for team Y573Y5T7X3"
        echo ""
    fi
else
    echo -e "${YELLOW}Warning: Certificate not installed (missing base64 or password)${NC}"
    echo ""
fi

# Step 1: Generate Tauri iOS project
echo -e "${YELLOW}Step 1: Generating Tauri iOS project...${NC}"
npm run tauri ios init || echo "iOS project may already exist"

# Set build number - use timestamp for local builds to ensure uniqueness
BUILD_NUMBER=$(date +%Y%m%d%H%M)
echo "Setting build number to: $BUILD_NUMBER"

# Ensure export compliance key is in Info.plist (fixes "Missing Compliance" in TestFlight)
INFO_PLIST="src-tauri/gen/apple/circuit-assistant-mobile-companion_iOS/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    # Update CFBundleVersion to use build number
    perl -i -pe "s|<key>CFBundleVersion</key>\s*<string>[^<]*</string>|<key>CFBundleVersion</key>\n\t<string>$BUILD_NUMBER</string>|" "$INFO_PLIST"
    echo -e "${GREEN}✓ Updated CFBundleVersion to: $BUILD_NUMBER${NC}"
    
    # Check if export compliance key already exists
    if ! grep -q "ITSAppUsesNonExemptEncryption" "$INFO_PLIST"; then
        echo -e "${YELLOW}Adding export compliance key to Info.plist...${NC}"
        # Add the key before the closing </dict> tag
        perl -i -pe 's|</dict>\s*</plist>|\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n</dict>\n</plist>|' "$INFO_PLIST"
        echo -e "${GREEN}✓ Export compliance key added${NC}"
    else
        echo -e "${GREEN}✓ Export compliance key already present${NC}"
    fi
    
    # Display version info
    echo "Version information:"
    grep -A1 "CFBundleShortVersionString\|CFBundleVersion" "$INFO_PLIST" | head -4
else
    echo -e "${RED}Error: Info.plist not found${NC}"
fi

echo -e "${GREEN}✓ iOS project generated${NC}"
echo ""

# Step 2: Ensure assets directory exists
echo -e "${YELLOW}Step 2: Setting up assets directory...${NC}"
mkdir -p src-tauri/gen/apple/assets
echo -e "${GREEN}✓ Assets directory ready${NC}"
echo ""

# Step 3: Create wrapper script (same as GitHub Actions)
echo -e "${YELLOW}Step 3: Creating wrapper script...${NC}"
XCODE_PROJECT="src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj"
PROJECT_FILE="$XCODE_PROJECT/project.pbxproj"
WRAPPER_SCRIPT="src-tauri/gen/apple/build_rust_wrapper.sh"

# Check if Xcode project exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Error: Xcode project not found at $PROJECT_FILE${NC}"
    echo "Please run 'npm run tauri ios init' first"
    exit 1
fi

# Create wrapper script (simplified version for local testing)
cat > "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
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
WRAPPER_EOF

chmod +x "$WRAPPER_SCRIPT"
echo -e "${GREEN}✓ Wrapper script created${NC}"
echo ""

# Step 4: Update Xcode project to use wrapper script
echo -e "${YELLOW}Step 4: Updating Xcode project to use wrapper script...${NC}"
if grep -q "npm run -- tauri ios xcode-script" "$PROJECT_FILE"; then
    # Replace npm command with wrapper script, and also fix the arch argument format
    # The issue is that ${FORCE_COLOR} might be empty, causing "0" to appear, which Tauri misinterprets
    # We'll replace the command and ensure arch is passed correctly
    perl -i -pe 's|(shellScript = ")npm run -- tauri ios xcode-script |$1\${SRCROOT}/build_rust_wrapper.sh |g' "$PROJECT_FILE"
    # Fix the FORCE_COLOR issue - the project file has "0" where FORCE_COLOR was empty
    # Replace " 0 " or " 0" at the end before ${ARCHS} with just a space
    perl -i -pe 's| --configuration \$\{CONFIGURATION:\?\} 0 \$\{ARCHS:\?\}| --configuration \$\{CONFIGURATION:\?\} \$\{ARCHS:\?\}|g' "$PROJECT_FILE"
    perl -i -pe 's| --configuration \$\{CONFIGURATION:\?\} 0"| --configuration \$\{CONFIGURATION:\?\}"|g' "$PROJECT_FILE"
    echo -e "${GREEN}✓ Project file updated${NC}"
else
    echo -e "${YELLOW}Project file already uses wrapper script${NC}"
    # Still fix the FORCE_COLOR/arch issue even if wrapper is already set
    perl -i -pe 's| --configuration \$\{CONFIGURATION:\?\} 0 \$\{ARCHS:\?\}| --configuration \$\{CONFIGURATION:\?\} \$\{ARCHS:\?\}|g' "$PROJECT_FILE" || true
fi

# Fix: Remove libapp.a from Resources build phase (it should only be in Frameworks)
# App Store validation fails if libapp.a is copied into the app bundle
if grep -q "libapp.a in Resources" "$PROJECT_FILE"; then
    echo -e "${YELLOW}Removing libapp.a from Resources phase (should only be in Frameworks)...${NC}"
    perl -i -pe 's|^\s*D85AEC8F3A553813F4C8FFE9 /\* libapp\.a in Resources \*/.*\n||g' "$PROJECT_FILE"
    # Also remove the trailing comma if it was the last item
    perl -i -pe 's|,\s*D85AEC8F3A553813F4C8FFE9 /\* libapp\.a in Resources \*/||g' "$PROJECT_FILE"
    echo -e "${GREEN}✓ Removed libapp.a from Resources phase${NC}"
fi
echo ""

# Step 5: Create ExportOptions.plist
echo -e "${YELLOW}Step 5: Creating ExportOptions.plist...${NC}"
mkdir -p build
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>org.circuitassistant.camc</key>
        <string>$PROVISIONING_PROFILE_UUID</string>
    </dict>
</dict>
</plist>
EOF
echo -e "${GREEN}✓ ExportOptions.plist created${NC}"
echo ""

# Step 6: Archive the app
echo -e "${YELLOW}Step 6: Archiving iOS app...${NC}"
SCHEME="circuit-assistant-mobile-companion_iOS"
ARCHIVE_PATH="$PWD/build/ios.xcarchive"
EXPORT_PATH="$PWD/build/ios-export"

# Set environment variables
export TAURI_SKIP_DEV_SERVER=1
export TAURI_DEV_HOST="127.0.0.1:1"
export CI=true
export RELEASE_BUILD=true

# Archive
set +e  # Don't exit on error, we'll check manually
ARCHIVE_OUTPUT=$(xcodebuild archive \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_UUID" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    2>&1)
ARCHIVE_EXIT_CODE=$?
set -e  # Re-enable exit on error

# Display output (beautify if available)
if command -v xcbeautify >/dev/null 2>&1; then
    echo "$ARCHIVE_OUTPUT" | xcbeautify
else
    echo "$ARCHIVE_OUTPUT"
fi

# Check if archive was successful
if [ $ARCHIVE_EXIT_CODE -ne 0 ] || [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive failed (exit code: $ARCHIVE_EXIT_CODE)${NC}"
    echo ""
    echo "Last 50 lines of archive output:"
    echo "$ARCHIVE_OUTPUT" | tail -50
    exit 1
fi
echo -e "${GREEN}✓ Archive created at $ARCHIVE_PATH${NC}"
echo ""

# Step 7: Export IPA
echo -e "${YELLOW}Step 7: Exporting IPA...${NC}"
set +e  # Don't exit on error, we'll check manually
EXPORT_OUTPUT=$(xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist build/ExportOptions.plist \
    2>&1)
EXPORT_EXIT_CODE=$?
set -e  # Re-enable exit on error

# Display output (beautify if available)
if command -v xcbeautify >/dev/null 2>&1; then
    echo "$EXPORT_OUTPUT" | xcbeautify
else
    echo "$EXPORT_OUTPUT"
fi

if [ $EXPORT_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Error: Export failed (exit code: $EXPORT_EXIT_CODE)${NC}"
    echo ""
    echo "Last 50 lines of export output:"
    echo "$EXPORT_OUTPUT" | tail -50
    exit 1
fi

IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
if [ -z "$IPA_FILE" ]; then
    echo -e "${RED}Error: IPA file not found${NC}"
    ls -la "$EXPORT_PATH" || echo "Export path does not exist"
    exit 1
fi
echo -e "${GREEN}✓ IPA created at $IPA_FILE${NC}"
echo ""

# Step 8: Upload to TestFlight
echo -e "${YELLOW}Step 8: Uploading to TestFlight...${NC}"

# Check if we have App Store Connect API credentials
if [ -n "$APPSTORE_KEY_ID" ] && [ -n "$APPSTORE_ISSUER_ID" ] && [ -n "$APPSTORE_PRIVATE_KEY" ]; then
    # Extract private key and save as .p8 file for xcrun altool
    PRIVATE_KEY_DIR="$HOME/.appstoreconnect/private_keys"
    mkdir -p "$PRIVATE_KEY_DIR"
    PRIVATE_KEY_FILE="$PRIVATE_KEY_DIR/AuthKey_${APPSTORE_KEY_ID}.p8"
    
    # Save the private key (it's already in PEM format from secrets file)
    echo "$APPSTORE_PRIVATE_KEY" > "$PRIVATE_KEY_FILE"
    chmod 600 "$PRIVATE_KEY_FILE"
    echo "Saved private key to $PRIVATE_KEY_FILE"
    
    # Use xcrun altool for upload
    echo "Using xcrun altool for upload..."
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_FILE" \
        --apiKey "$APPSTORE_KEY_ID" \
        --apiIssuer "$APPSTORE_ISSUER_ID" && {
        echo -e "${GREEN}✓ Upload to TestFlight completed!${NC}"
        echo ""
        echo -e "${GREEN}Build complete! Check App Store Connect for the new build.${NC}"
        # Clean up private key file
        rm -f "$PRIVATE_KEY_FILE"
        exit 0
    } || {
        echo -e "${YELLOW}Upload failed. You can manually upload using Transporter app:${NC}"
        echo "  IPA: $IPA_FILE"
        # Clean up private key file
        rm -f "$PRIVATE_KEY_FILE"
        exit 1
    }
elif command -v bundle &> /dev/null && [ -f "Gemfile" ]; then
    echo "Using fastlane for upload..."
    bundle exec fastlane ios testflight ipa:"$IPA_FILE" && {
        echo -e "${GREEN}✓ Upload to TestFlight completed!${NC}"
        exit 0
    } || {
        echo -e "${YELLOW}Fastlane upload failed.${NC}"
        echo -e "${GREEN}IPA file ready for manual upload: $IPA_FILE${NC}"
        exit 1
    }
else
    echo -e "${YELLOW}Credentials not found. Skipping upload.${NC}"
    echo -e "${GREEN}IPA file ready for manual upload: $IPA_FILE${NC}"
    echo ""
    echo "To upload manually:"
    echo "  1. Open Transporter app (from App Store)"
    echo "  2. Drag and drop: $IPA_FILE"
    echo "  3. Click Deliver"
    exit 0
fi

echo -e "${GREEN}✓ Upload to TestFlight completed!${NC}"
echo ""
echo -e "${GREEN}Build complete! Check App Store Connect for the new build.${NC}"


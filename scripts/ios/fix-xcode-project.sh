#!/bin/bash
# Automatically fix Xcode project issues after tauri ios init
# Run this after generating the Xcode project

set -e

PROJECT_FILE="src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Xcode project not found at $PROJECT_FILE"
    echo "Run 'tauri ios init' first"
    exit 1
fi

echo "🔧 Fixing Xcode project issues..."
echo ""

# Fix 1: Remove stray '0' argument from tauri ios xcode-script command
echo "1. Removing stray '0' from xcode-script command..."
perl -i -pe 's| --configuration \$\{CONFIGURATION:\?\} 0 \$\{ARCHS:\?\}| --configuration \$\{CONFIGURATION:\?\} \$\{ARCHS:\?\}|g' "$PROJECT_FILE"
perl -i -pe 's| --configuration \$\{CONFIGURATION:\?\} 0"| --configuration \$\{CONFIGURATION:\?\}"|g' "$PROJECT_FILE"

# Fix 2: Remove libapp.a from Resources build phase (if present)
echo "2. Ensuring libapp.a is only in Frameworks (not Resources)..."
perl -i -pe 's|^\s*D85AEC8F3A553813F4C8FFE9 /\* libapp\.a in Resources \*/.*\n||g' "$PROJECT_FILE"
perl -i -pe 's|,\s*D85AEC8F3A553813F4C8FFE9 /\* libapp\.a in Resources \*/||g' "$PROJECT_FILE"

echo ""
echo "✅ Xcode project fixes applied!"
echo ""
echo "You can now open the project in Xcode and build."




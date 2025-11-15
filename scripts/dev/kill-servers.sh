#!/bin/bash

# Script to kill any running dev servers and free up ports

echo "Killing dev servers and freeing ports..."

# Kill processes on port 1421 (Vite)
if lsof -ti:1421 > /dev/null 2>&1; then
    echo "  • Killing process on port 1421..."
    lsof -ti:1421 | xargs kill -9 2>/dev/null
    echo "    ✓ Port 1421 freed"
else
    echo "    ✓ Port 1421 already free"
fi

# Kill any Vite processes
if pgrep -f "vite" > /dev/null 2>&1; then
    echo "  • Killing Vite processes..."
    pkill -f "vite"
    echo "    ✓ Vite processes killed"
else
    echo "    ✓ No Vite processes running"
fi

# Kill any Tauri Android processes
if pgrep -f "tauri android" > /dev/null 2>&1; then
    echo "  • Killing Tauri Android processes..."
    pkill -f "tauri android"
    echo "    ✓ Tauri Android processes killed"
else
    echo "    ✓ No Tauri Android processes running"
fi

echo ""
echo "✅ All dev servers stopped"
echo ""
echo "You can now run:"
echo "  source setup-android-env.sh && npm run tauri:android:dev"




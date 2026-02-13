#!/bin/bash
set -e

# Kill existing emulators if any
lsof -ti:9099 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true
lsof -ti:9199 | xargs kill -9 2>/dev/null || true

echo "Starting Firebase Emulators (Auth, Firestore, Functions, Storage)..."
firebase emulators:start --only functions,firestore,auth,storage --project daylog-16724 > emulator.log 2>&1 &
PID=$!
echo "Emulators started with PID $PID. Logs are in emulator.log"

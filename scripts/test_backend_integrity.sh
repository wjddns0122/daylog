#!/bin/bash
set -e

echo "Starting Firebase Emulators in background..."
firebase emulators:start --only functions,firestore,auth --project daylog-16724 > emulator.log 2>&1 &
PID=$!

echo "Waiting for emulators..."
sleep 20

if kill -0 $PID 2>/dev/null; then
  echo "✅ Emulators started successfully."
  
  echo "Stopping emulators..."
  kill $PID
  exit 0
else
  echo "❌ Emulators failed to start."
  cat emulator.log
  exit 1
fi

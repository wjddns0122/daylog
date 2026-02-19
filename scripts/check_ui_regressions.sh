#!/bin/bash

set -euo pipefail

echo "Checking UI regression sentinels..."

errors=0

if grep -q "onPressed: () {}" lib/features/calendar/presentation/screens/calendar_screen.dart; then
  echo "[FAIL] Empty calendar app bar handlers detected"
  errors=$((errors + 1))
fi

if grep -q "showDummyNotice('Terms')\|showDummyNotice('Privacy')\|showDummyNotice('Change Password')" lib/features/settings/presentation/screens/settings_screen.dart; then
  echo "[FAIL] Settings placeholder action found"
  errors=$((errors + 1))
fi

if grep -q "sendReleaseNotificationPlaceholder" functions/src/index.ts; then
  echo "[FAIL] Notification placeholder function still present"
  errors=$((errors + 1))
fi

if grep -q "useMockData = true" lib/features/notification/data/repositories/notification_repository_impl.dart; then
  echo "[FAIL] Notifications default to mock mode"
  errors=$((errors + 1))
fi

if [ "$errors" -gt 0 ]; then
  echo "Regression check failed with $errors issue(s)."
  exit 1
fi

echo "Regression check passed."

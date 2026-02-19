#!/bin/bash
# Seed test users into Firebase Emulator (Auth + Firestore)

PROJECT="daylog-16724"
AUTH_URL="http://localhost:9099/identitytoolkit.googleapis.com/v1"
FIRESTORE_URL="http://localhost:8080/v1/projects/$PROJECT/databases/(default)/documents"

create_user() {
  local EMAIL=$1
  local PASSWORD=$2
  local DISPLAY_NAME=$3
  local NICKNAME=$4

  echo "--- Creating: $NICKNAME ($EMAIL) ---"

  # 1. Create user in Auth (signUp)
  RESP=$(curl -s -X POST "$AUTH_URL/accounts:signUp?key=fake-api-key" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"displayName\":\"$DISPLAY_NAME\",\"returnSecureToken\":true}")

  TOKEN=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('idToken',''))" 2>/dev/null)
  USER_ID=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('localId',''))" 2>/dev/null)

  if [ -z "$USER_ID" ] || [ -z "$TOKEN" ] || [ "$USER_ID" == "None" ]; then
    # Maybe user already exists, try to sign in
    RESP=$(curl -s -X POST "$AUTH_URL/accounts:signInWithPassword?key=fake-api-key" \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"returnSecureToken\":true}")
    TOKEN=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('idToken',''))" 2>/dev/null)
    USER_ID=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('localId',''))" 2>/dev/null)
  fi

  if [ -z "$USER_ID" ] || [ -z "$TOKEN" ] || [ "$USER_ID" == "None" ]; then
    echo "  FAILED to create or sign in: $RESP"
    return 1
  fi

  echo "  UID: $USER_ID"

  NICKNAME_LOWER=$(echo "$NICKNAME" | tr '[:upper:]' '[:lower:]')
  DISPLAY_LOWER=$(echo "$DISPLAY_NAME" | tr '[:upper:]' '[:lower:]')

  # 2. Create Firestore user doc (authenticated as this user)
  RESULT=$(curl -s -X PATCH \
    "$FIRESTORE_URL/users/$USER_ID?updateMask.fieldPaths=uid&updateMask.fieldPaths=email&updateMask.fieldPaths=displayName&updateMask.fieldPaths=nickname&updateMask.fieldPaths=nicknameLower&updateMask.fieldPaths=displayNameLower&updateMask.fieldPaths=isVerified&updateMask.fieldPaths=followersCount&updateMask.fieldPaths=followingCount&updateMask.fieldPaths=loginMethod" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"fields\": {
        \"uid\": {\"stringValue\": \"$USER_ID\"},
        \"email\": {\"stringValue\": \"$EMAIL\"},
        \"displayName\": {\"stringValue\": \"$DISPLAY_NAME\"},
        \"nickname\": {\"stringValue\": \"$NICKNAME\"},
        \"nicknameLower\": {\"stringValue\": \"$NICKNAME_LOWER\"},
        \"displayNameLower\": {\"stringValue\": \"$DISPLAY_LOWER\"},
        \"isVerified\": {\"booleanValue\": false},
        \"followersCount\": {\"integerValue\": \"0\"},
        \"followingCount\": {\"integerValue\": \"0\"},
        \"loginMethod\": {\"stringValue\": \"email\"}
      }
    }")

  if echo "$RESULT" | grep -q "name"; then
    echo "  OK"
  else
    echo "  ERR: $RESULT"
  fi
}

create_user "minsu@test.com" "test1234" "김민수" "minsu_kim"
create_user "jiyoung@test.com" "test1234" "박지영" "jiyoung_park"
create_user "hyunwoo@test.com" "test1234" "이현우" "hyunwoo_lee"

echo ""
echo "=== Done! ==="
echo "Test accounts re-created:"
echo "  1. minsu@test.com / test1234"
echo "  2. jiyoung@test.com / test1234"
echo "  3. hyunwoo@test.com / test1234"

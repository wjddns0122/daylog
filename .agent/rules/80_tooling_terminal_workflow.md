---
trigger: always_on
---

---

description: "Terminal workflow guidance (Cursor context): safe dependency and setup steps"
globs: ["pubspec.yaml", "ios/**", "android/**", "**/*"]
alwaysApply: true

---

# Tooling & Native Setup

## Dependencies (typical)

- firebase_core, firebase_auth, cloud_firestore, firebase_storage
- google_sign_in
- kakao_flutter_sdk
- riverpod, hooks_riverpod
- freezed_annotation + build_runner
- json_serializable
- camera, image, image_cropper (if needed)
- share_plus, screenshot (share feature)
- lottie, shimmer, google_fonts (if used by Figma)

## Native placeholders required (do not invent real keys)

### iOS Info.plist placeholders

- Kakao: KAKAO_APP_KEY, LSApplicationQueriesSchemes (kakaokompassauth, kakaolink)
- Google: CFBundleURLTypes with Reverse Client ID
- Kakao scheme: kakao${KAKAO_APP_KEY}

### AndroidManifest placeholders

- Kakao: meta-data com.kakao.sdk.AppKey
- INTERNET permission
- Debug key hash generation note (commands/instructions only)

## Rule

Never hardcode secrets. Use:

- dart-define, env files, or platform config placeholders.

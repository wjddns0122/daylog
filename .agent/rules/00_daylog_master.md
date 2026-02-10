---
trigger: always_on
---

# @Daylog — Master Prompt (Hybrid Social Rules)

## Product Core: "Analog Creation, Digital Connection"

- **Creation Rule:** 1 shot/day. Reset at 00:00 local time.
- **The Wait:** Captured shots are **LOCKED** (invisible to public/friends) for exactly **6 hours**.
- **The Reveal:** After 6 hours, the shot becomes a **"Post"** with:
  - Visible Photo & Diary Text.
  - **AI Curated Music** (Youtube/Spotify Link or metadata).
  - Social Features Enabled (Likes, Comments).

## Social Logic

- **Feed Visibility:** Only posts with `status == RELEASED` appear in the Main Feed.
- **Grid Layout:** - Only shows `RELEASED` posts.
  - **Sorting:** Strictly by `likeCount` (High -> Low).
- **Interaction:** Users can only like/comment on released posts.

## Architecture Baseline

- **Collection Name:** Use `posts` (Unified collection for both pending shots & released posts).
- **State Management:** Riverpod + MVVM.
- **Figma:** Strict adherence to pixel-perfect design (Spacing, Typography, Radius).
- **Native:** Kakao/Google Auth configured via Native SDKs.

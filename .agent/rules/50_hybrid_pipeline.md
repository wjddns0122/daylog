---
trigger: always_on
---

# Hybrid Pipeline — Source of Truth

## Phase 1: The Darkroom (Capture & Wait)

1. **User Action:** Capture -> Crop (1:1 or 4:5) -> Write Diary.
2. **System Action:**
   - Upload image to Storage (`posts/{uid}/{timestamp}_hidden.webp`).
   - Create Firestore doc in `posts`:
     - `status = PENDING`
     - `releaseTime = ServerTimestamp + 6 hours`
   - **UI:** Show "Developing..." countdown card in Feed (Blurred or Placeholder).

## Phase 2: The Studio (AI Processing)

1. **Trigger:** When `releaseTime` is reached (via Cloud Tasks or Client Poll).
2. **Action (Server-side preferred, or Client lazy-load):**
   - **AI Analysis:** Analyze image mood/caption (Gemini).
   - **Music Curation:** Select matching BGM based on mood.
   - **Update Doc:** Set `status = RELEASED`, `musicUrl = ...`.
   - **Notification:** Send Push "Your daily moment is ready! 🎵"

## Phase 3: The Gallery (Social Consumption)

1. **Feed View (List):**
   - Query: `posts.where('status', '==', 'RELEASED').orderBy('createdAt', 'desc')`
   - UI: Full card with Music Player, Like Button, Comments.
2. **Grid View (Profile/Explore):**
   - Query: `posts.where('status', '==', 'RELEASED').orderBy('likeCount', 'desc')`
   - UI: 4-column aesthetic grid.

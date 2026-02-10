---
trigger: always_on
---

# Firebase Backbone Rules (Hybrid Schema)

## Collection: `posts` (Unified)

This collection handles the entire lifecycle from "Hidden Shot" to "Social Post".

### Fields

- `id` (PK): String (UUID or Auto-ID)
- `authorId`: String (Ref: users)
- `status`: String (Enum)
  - `PENDING`: Waiting for 6-hour timer (Hidden, Encrypted locally if possible).
  - `PROCESSING`: Time reached, AI is analyzing/curating music.
  - `RELEASED`: Visible to public (Social ready).
- `releaseTime`: Timestamp (Created + 6 hours)
- `imageUrl`: String (Hidden/Placeholder until status == RELEASED)
- `caption`: String
- `musicUrl`: String (AI Curated Music Link/Title)
- `likes`: Array<String> (List of User UIDs who liked)
- `likeCount`: Integer (Managed by Cloud Functions or Client logic for sorting)
- `commentCount`: Integer
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

## Collection: `users`

- `uid`, `email`, `nickname`, `photoUrl`, `createdAt`, `loginMethod`
- `followers`: Sub-collection or Counter
- `following`: Sub-collection or Counter

## Security Rules Principles

- **Read:**
  - If `status == RELEASED`: Public (or Friends only, depending on privacy setting).
  - If `status == PENDING`: Author ONLY.
- **Write:** - Author can create `PENDING` posts.
  - Author can update `caption` or delete post.
  - `likes`: Any auth user can add their UID (Atomic arrayUnion).

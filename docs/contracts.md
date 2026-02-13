# Operational Contract v2.3

## 1. Canonical Schema & Invariants

### 1.1 Collections
- **`posts`**: Main document store for shots.
- **`daily_locks`**: Deterministic locks for 1/day enforcement.
- **`idempotency_keys`**: Metadata for request deduplication (optional, or integrated).

### 1.2 `posts` Schema
| Field | Type | Owner | Mutable? | Description |
|-------|------|-------|----------|-------------|
| `authorId` | String | Server | NO | User UID. |
| `status` | String | Server | NO | `PENDING`, `PROCESSING`, `RELEASED`. |
| `releaseTime` | Timestamp | Server | NO | `createdAt + 6h`. |
| `createdAt` | Timestamp | Server | NO | Server timestamp. |
| `updatedAt` | Timestamp | Server | YES | Last update. |
| `dailyKey` | String | Server | NO | `uid_yyyyMMdd` (UTC). |
| `version` | Int | Server | YES | Monotonic increment. |
| `requestId` | String | Server | NO | Idempotency key. |
| `leaseOwner` | String | Server | YES | Worker ID claiming lease. |
| `leaseExpiresAt`| Timestamp | Server | YES | Lease TTL. |
| `processAttempts`| Int | Server | YES | Retry count. |
| `ai` | Map | Server | YES | Analysis result (mood, music, reasoning). |
| `aiError` | String | Server | YES | Error code if AI fails. |
| `caption` | String | Client | YES | User caption (Editable until PROCESSING). |
| `imageUrl` | String | Server | NO | Storage path. |

### 1.3 `daily_locks` Schema
- **ID**: `authorId_YYYYMMDD_UTC`
- **Fields**:
  - `createdAt`: Timestamp
  - `postId`: String (Reference to created post)

### 1.4 State Machine
| From | To | Actor | Condition |
|------|----|-------|-----------|
| `INIT` | `PENDING` | `createPostIntent` | Lock acquired. |
| `PENDING` | `PROCESSING` | `releaseWorker` | `now >= releaseTime`. |
| `PROCESSING` | `RELEASED` | `releaseWorker` | AI success or fallback. |
| `PROCESSING` | `PENDING` | `RepairWorker` | `now > leaseExpiresAt`. |

## 2. API Contract

### 2.1 `createPostIntent` (Callable)
- **Request**:
  ```json
  {
    "imagePath": "temp/uuid.jpg",
    "caption": "My day",
    "requestId": "uuid"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "postId": "uuid",
      "status": "PENDING",
      "releaseTime": "ISO8601"
    }
  }
  ```
- **Errors**:
  - `ALREADY_POSTED` (409): Lock exists.
  - `INVALID_ARGUMENT` (400): Bad input.

## 3. Migration & Compatibility

### 3.1 Legacy Mapping
| Legacy Field | Target Field | Logic |
|--------------|--------------|-------|
| `timestamp` | `createdAt` | `v2.createdAt ?? v1.timestamp`. |
| `userId` | `authorId` | `v2.authorId ?? v1.userId`. |
| (Missing) | `status` | `RELEASED`. |

### 3.2 Dual-Read Policy
- Clients MUST attempt to read v2 fields first.
- If `status` is undefined, client treats as `RELEASED`.

## 4. SLOs & Monitoring
- **Intent Success**: > 99.5%
- **Release Lag**: P95 < 2 min
- **Stuck States**: 0 docs in `PROCESSING` > 15m.

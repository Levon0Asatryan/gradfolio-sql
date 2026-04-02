# Table: `integrations`

## Purpose

Tracks LinkedIn and GitHub OAuth connections per user — connection status, OAuth tokens for API access, and sync timestamps. Each user can have at most one row per integration type (enforced by UNIQUE constraint). Supports LinkedIn & GitHub Integration (Feature 2) and Verification badges (Feature 5).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Frontend Type Mapping

- `Integration` interface in `src/data/integrations.mock.ts`
- `IntegrationId` type: `"linkedin" | "github"`
- `IntegrationStatus` type: `"connected" | "not_connected"`
- Rendered by `IntegrationsPage.tsx` and `IntegrationCard.tsx`

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Internal DB identifier. **Note**: The frontend uses `integration_type` as its `id` field (`Integration.id = "linkedin" \| "github"`). The API layer maps between them. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. CASCADE on delete. |
| `integration_type` | `ENUM(...)` | NO | — | Which external service. Values: `linkedin`, `github`. Combined with `user_id` in a UNIQUE constraint — one connection per type per user. Maps to `Integration.id` on the frontend. |
| `status` | `ENUM(...)` | NO | `'not_connected'` | Current connection state. Values: `connected` (OAuth completed, tokens stored), `not_connected` (not linked or disconnected). Maps to `Integration.status`. |
| `access_token` | `TEXT` | YES | `NULL` | OAuth access token for making API calls to GitHub/LinkedIn. `TEXT` because token lengths vary by provider (GitHub ~40 chars, LinkedIn can be longer). **Must be encrypted at the application layer** before storage — stored as ciphertext, decrypted when needed for API calls. `NULL` when not connected. |
| `refresh_token` | `TEXT` | YES | `NULL` | OAuth refresh token for obtaining new access tokens when they expire. LinkedIn uses refresh tokens; GitHub OAuth app tokens also support this. Same encryption requirement as `access_token`. |
| `token_expires_at` | `DATETIME` | YES | `NULL` | When the access token expires. Backend checks this before making API calls — if expired, uses `refresh_token` to get a new one. `NULL` means the token doesn't expire (some GitHub tokens). |
| `external_user_id` | `VARCHAR(255)` | YES | `NULL` | The user's identifier on the external platform (GitHub numeric user ID or LinkedIn member URN). Used to: (1) match imported data to avoid duplicates, (2) verify the linked account identity. |
| `last_synced_at` | `DATETIME` | YES | `NULL` | When data was last imported/synced from this integration. Shown on the integration card as "Last synced: X". `NULL` means never synced. Maps to `Integration.lastSyncedAt?`. |
| `created_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When this integration record was created. |
| `updated_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP ON UPDATE` | Last time this record was modified (e.g., token refresh, re-sync). |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `uq_integration_user_type` | UNIQUE | `user_id, integration_type` | One LinkedIn connection and one GitHub connection per user — no duplicates |

## Frontend ↔ DB field mapping note

The frontend `Integration` type has `name` and `description` fields (e.g., `name: "LinkedIn"`, `description: "Import your professional experience..."`). These are **not stored in the database** — they're hardcoded per integration type on the frontend because they never change. The `docUrl` field is also frontend-only.

## Example Data

```json
[
  {
    "id": "int_001",
    "user_id": "u_001",
    "integration_type": "github",
    "status": "connected",
    "access_token": "gho_encrypted_abc123...",
    "refresh_token": "ghr_encrypted_xyz789...",
    "token_expires_at": "2025-06-15 00:00:00",
    "external_user_id": "12345678",
    "last_synced_at": "2025-03-20 14:30:00",
    "created_at": "2025-01-15 09:00:00",
    "updated_at": "2025-03-20 14:30:00"
  },
  {
    "id": "int_002",
    "user_id": "u_001",
    "integration_type": "linkedin",
    "status": "not_connected",
    "access_token": null,
    "refresh_token": null,
    "token_expires_at": null,
    "external_user_id": null,
    "last_synced_at": null,
    "created_at": "2025-01-15 09:00:00",
    "updated_at": "2025-01-15 09:00:00"
  }
]
```

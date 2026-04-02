# Table: `notifications`

## Purpose

Stores user notifications — private alerts about events that require attention (team invitations, verification updates, contact requests). Unlike activities (public timeline), notifications are personal and have read/unread state. This is a **new table** — the spec requires notifications but no table existed previously. Supports Project Pages (Feature 4 — teammate tagging), Verification (Feature 5), and Additional Features (Feature 7 — notification system).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**
- **Polymorphic reference**: `reference_id` + `reference_type` point to the related entity (project, user, etc.) without a formal FK — this allows referencing any table without coupling.

## Frontend Type Mapping

- No frontend type exists yet — this table was added ahead of the frontend implementation. A `Notification` type will need to be created when the notification UI is built.

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. The recipient of the notification. CASCADE on delete — if the user is deleted, their notifications are removed. |
| `type` | `ENUM(...)` | NO | — | Notification category. Determines the icon, color, and behavior in the notification UI. Values: `team_invite` (someone added you to a project team), `team_accepted` (your teammate accepted the invitation), `team_rejected` (your teammate declined), `project_verified` (a project was verified by admin/endorsement), `comment` (someone commented on your project — future feature), `contact_request` (an employer wants to contact you), `general` (catch-all for other notifications). |
| `title` | `VARCHAR(500)` | NO | — | Short notification headline (e.g., "Team invitation", "Project verified"). Displayed as the primary text in the notification list. 500 chars allows descriptive titles. |
| `message` | `TEXT` | YES | `NULL` | Detailed notification body (e.g., "Gabe Nuels added you as UI/UX Designer on Smart Garden IoT System"). Optional — some notifications may only need a title. `TEXT` for flexibility. |
| `is_read` | `TINYINT(1)` | NO | `0` | Read state. `0` = unread (shows badge/highlight), `1` = read (dimmed). The most common query is "get unread notifications for user X" which is optimized by the composite index. |
| `reference_id` | `VARCHAR(36)` | YES | `NULL` | ID of the related entity (e.g., a `project_id` for team invites, a `user_id` for contact requests). This is a **polymorphic reference** — the actual table is determined by `reference_type`. Not a formal FK to avoid coupling to a single table. |
| `reference_type` | `VARCHAR(50)` | YES | `NULL` | Type of the referenced entity. Expected values: `project`, `user`, `certification`, etc. Used together with `reference_id` to construct the related entity lookup. 50 chars covers any table name. |
| `link` | `TEXT` | YES | `NULL` | Pre-computed URL path to navigate to when the notification is clicked (e.g., `/projects/proj_001`, `/profile/u_003`). Stored so the frontend doesn't need to compute URLs from reference types — just navigate to `link`. `TEXT` because URLs can be long. |
| `created_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When the notification was created. Used for sorting (newest first) and display ("2 hours ago"). |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_notifications_user` | B-tree | `user_id` | Fast lookup of all notifications for a user |
| `idx_notifications_user_unread` | B-tree (composite) | `user_id, is_read` | Optimizes the most common query: "get unread notifications for user X" (`WHERE user_id = ? AND is_read = 0`). The composite index lets MySQL satisfy this query using only the index without touching the table. Also used for unread count badge. |
| `idx_notifications_created` | B-tree | `created_at` | Sort by newest first, support pagination, and enable cleanup of old notifications. |

## Key Query Patterns

```sql
-- Get unread notification count for badge
SELECT COUNT(*) FROM notifications
WHERE user_id = ? AND is_read = 0;

-- Get recent notifications (paginated)
SELECT * FROM notifications
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- Mark notification as read
UPDATE notifications SET is_read = 1 WHERE id = ?;

-- Mark all as read
UPDATE notifications SET is_read = 1
WHERE user_id = ? AND is_read = 0;
```

## Example Data

```json
[
  {
    "id": "notif_001",
    "user_id": "u_003",
    "type": "team_invite",
    "title": "Team invitation",
    "message": "Gabe Nuels added you as UI/UX Designer on \"Smart Garden IoT System\"",
    "is_read": 0,
    "reference_id": "proj_001",
    "reference_type": "project",
    "link": "/projects/proj_001",
    "created_at": "2025-03-20 14:30:00"
  },
  {
    "id": "notif_002",
    "user_id": "u_001",
    "type": "team_accepted",
    "title": "Invitation accepted",
    "message": "Sona Petrosyan accepted your invitation to \"Smart Garden IoT System\"",
    "is_read": 1,
    "reference_id": "proj_001",
    "reference_type": "project",
    "link": "/projects/proj_001",
    "created_at": "2025-03-21 10:00:00"
  }
]
```

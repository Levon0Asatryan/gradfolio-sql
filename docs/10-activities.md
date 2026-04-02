# Table: `activities`

## Purpose

Stores activity feed events for each user — a timeline of actions like "Updated project Smart Garden", "Profile viewed by 5 people", "Added new skill React". Displayed on the dashboard activity feed. These are public timeline entries (unlike notifications which are private alerts). Supports the Dashboard (Feature 7).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Frontend Type Mapping

- `Activity` interface in `src/utils/types/dashboard.types.ts`
- Rendered by `ActivityFeed.tsx` (dashboard sidebar)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Maps to `Activity.id`. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. Whose activity feed this event belongs to. CASCADE on delete. |
| `type` | `ENUM(...)` | NO | — | Activity category. Values: `project` (project-related action), `profile` (profile-related action). Used to display different icons and colors in the activity feed. Maps to `Activity.type`. |
| `translation_key` | `VARCHAR(255)` | NO | — | i18n translation key for the activity message (e.g., `"projectUpdated"`, `"profileViewed"`, `"newSkill"`). The frontend looks this up in the translation dictionary to render the message in the user's language. `VARCHAR(255)` is plenty for dot-notation keys. Maps to `Activity.translationKey` (snake_case → camelCase transform in API). |
| `translation_params` | `JSON` | YES | `NULL` | Parameters to interpolate into the translated message (e.g., `{"projectName": "Smart Garden", "count": 3}`). The frontend's `interpolate()` function replaces `{projectName}` placeholders with these values. `JSON` because parameter shape varies by activity type. Maps to `Activity.translationParams?`. |
| `timestamp` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When the activity occurred. Used for sorting (newest first) and display ("2 hours ago"). Maps to `Activity.timestamp`. |
| `details` | `TEXT` | YES | `NULL` | Optional extra detail text. Not always used — serves as a catch-all for additional context. Maps to `Activity.details?`. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_activities_user` | B-tree | `user_id` | Fast lookup of all activities for a user's dashboard feed |
| `idx_activities_timestamp` | B-tree | `timestamp` | Sort by newest first, and support range queries ("activities in the last 30 days" for dashboard stats) |

## i18n Activity Keys

The translation dictionaries (`src/data/locales/en.ts`, `ru.ts`, `am.ts`) define these activity message templates:

| Key | English template |
| --- | --- |
| `projectUpdated` | "Updated project {projectName}" |
| `profileViewed` | "Profile viewed by {count} people" |
| `newConnection` | "New connection with {userName}" |
| `newFollower` | "New follower: {userName}" |
| `newSkill` | "Added new skill: {skillName}" |

## Example Data

```json
[
  {
    "id": "act_001",
    "user_id": "u_001",
    "type": "project",
    "translation_key": "projectUpdated",
    "translation_params": {"projectName": "Smart Garden IoT System"},
    "timestamp": "2025-03-20 14:30:00",
    "details": null
  },
  {
    "id": "act_002",
    "user_id": "u_001",
    "type": "profile",
    "translation_key": "profileViewed",
    "translation_params": {"count": 12},
    "timestamp": "2025-03-19 09:00:00",
    "details": null
  }
]
```

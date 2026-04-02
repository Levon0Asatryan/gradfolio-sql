# Table: `user_skills`

## Purpose

Stores individual skill tags for each user. Each row is one skill (e.g., "Python", "Machine Learning", "Project Management"). Skills are displayed as chips on the profile and are searchable across the platform. Supports the Portfolio Profile Page (Feature 3), Search & Discovery (Feature 6), and LinkedIn import (Feature 2).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Why a Separate Table (Not JSON)

Unlike `achievements` or `highlights` which are stored as JSON arrays, skills have their own table because:

1. **Search**: Skills need to be individually queryable — "find all users who have React" requires a WHERE clause on individual skill values. JSON arrays would require `JSON_CONTAINS()` which is slower and can't use indexes.
2. **Aggregation**: Tag clouds and trending skills require `GROUP BY skill_name` with `COUNT(*)` — trivial with a table, complex with JSON.
3. **Ordering**: Each skill can have its own `sort_order` for user-controlled display ordering.

## Frontend Type Mapping

- `ProfileData.skills: string[]` in `src/data/profile.mock.ts`
- Rendered by `SkillsChips.tsx` (read-only) and `EditableSkillsChips.tsx` (edit mode with add/delete)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Not mapped to frontend — the frontend works with skill names as strings, not objects with IDs. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. CASCADE on delete. |
| `skill_name` | `VARCHAR(255)` | NO | — | The skill tag text (e.g., "React", "Python", "Data Analysis"). 255 chars is more than enough for any skill name. Indexed for search queries. |
| `sort_order` | `INT` | NO | `0` | Display order on the profile. Skills appear in this order in the chips row. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_user_skills_user` | B-tree | `user_id` | Fast lookup of all skills for a user |
| `idx_user_skills_name` | B-tree | `skill_name` | Fast filtering by skill name across all users (search: "find users with Python"), tag cloud aggregation (`GROUP BY skill_name`) |

## Example Data

```json
[
  { "id": "sk_001", "user_id": "u_001", "skill_name": "TypeScript", "sort_order": 0 },
  { "id": "sk_002", "user_id": "u_001", "skill_name": "React", "sort_order": 1 },
  { "id": "sk_003", "user_id": "u_001", "skill_name": "Node.js", "sort_order": 2 },
  { "id": "sk_004", "user_id": "u_001", "skill_name": "Machine Learning", "sort_order": 3 }
]
```

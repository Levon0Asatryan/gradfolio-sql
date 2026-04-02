# Table: `project_team_members`

## Purpose

Tracks collaborators on a project. When a student adds teammates to their project, each teammate gets a row here. Teammates must accept the invitation before the project appears on their profile. This is a **new table** added to support the spec's team collaboration requirements. Supports Project Pages (Feature 4) and Verification (Feature 5 — mutual teammate confirmation as project verification).

## Relationships

- **Parent**: `projects` (via `project_id` FK, CASCADE delete)
- **Optional link**: `users` (via `user_id` FK, SET NULL on delete — nullable because teammates may not have accounts)

## Why This Table Exists

The spec heavily emphasizes team collaboration:
- "the original author can **add teammates** on the project page"
- "Once added and approved, the project will also appear on the teammate's profile"
- "once all teammates confirm their involvement, that mutual confirmation serves as verification"

The frontend already has `TeamMember` type and `TeamList` component displaying team members on every project.

## Frontend Type Mapping

- `TeamMember` interface in `src/data/project.mock.ts` and `src/data/profile.mock.ts`
- Rendered by `TeamList.tsx` (project detail page)
- Team avatars also shown on `ProjectsGrid.tsx` (profile project cards)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `CHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Inserts must omit this column — MySQL generates it automatically via DEFAULT (UUID()). CHAR(36) is fixed-length, more efficient than VARCHAR for always-36-char UUIDs. Maps to `TeamMember.id`. |
| `project_id` | `CHAR(36)` | NO | — | FK to `projects.id`. Which project this team member belongs to. CASCADE on delete — if the project is deleted, all team member records are removed. |
| `user_id` | `CHAR(36)` | YES | `NULL` | FK to `users.id`. Links to the teammate's account on the platform. **Nullable** because the spec allows listing teammates who don't have accounts ("provided those teammates also have accounts" is a preference, not a hard requirement). When NULL, the person is listed by name only with no clickable profile link. SET NULL on delete — if the linked user deletes their account, the team member record stays (preserving project history) but the link is broken. |
| `name` | `VARCHAR(255)` | NO | — | Display name of the team member. Required even when `user_id` is set, because: (1) external teammates have no user record to pull a name from, (2) serves as a cache so the project page doesn't need to JOIN `users` just for names. Maps to `TeamMember.name`. |
| `role` | `VARCHAR(255)` | YES | `NULL` | The teammate's role or contribution (e.g., "Lead Developer", "UI/UX Designer", "Research"). Optional — some projects may not define roles. Maps to `TeamMember.role?`. |
| `avatar_url` | `TEXT` | YES | `NULL` | URL to the teammate's avatar image. Can be copied from the user's `avatar_url` when linking, or set manually for external teammates. Maps to `TeamMember.avatarUrl?`. |
| `status` | `ENUM(...)` | NO | `'pending'` | Invitation workflow state. Values: `pending` (invited, awaiting confirmation), `accepted` (teammate confirmed involvement), `rejected` (teammate declined). Only `accepted` members should appear on the public project page. Spec: "once all teammates confirm, that mutual confirmation serves as verification." |
| `sort_order` | `INT` | NO | `0` | Display order in the team list. |
| `created_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When the teammate was added/invited. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_team_project` | B-tree | `project_id` | Fast lookup of all team members for a project |
| `idx_team_user` | B-tree | `user_id` | Fast lookup of all projects a user is a team member on — needed for "show project on teammate's profile" feature |
| `uq_team_project_user` | UNIQUE | `project_id, user_id` | Prevents adding the same user to the same project twice. Only applies when `user_id` is NOT NULL (MySQL UNIQUE allows multiple NULLs). |

## Key Query Patterns

```sql
-- Get team members for a project page (only accepted)
SELECT * FROM project_team_members
WHERE project_id = ? AND status = 'accepted'
ORDER BY sort_order;

-- Get all projects where user is a team member (for their profile)
SELECT p.* FROM projects p
JOIN project_team_members ptm ON ptm.project_id = p.id
WHERE ptm.user_id = ? AND ptm.status = 'accepted';

-- Get pending invitations for a user (notifications)
SELECT ptm.*, p.title AS project_title FROM project_team_members ptm
JOIN projects p ON p.id = ptm.project_id
WHERE ptm.user_id = ? AND ptm.status = 'pending';
```

## Example Data

```json
[
  {
    "id": "a7b9c1d3-6e8f-4a0b-c2d4-e5f6a7b8c9d0",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "user_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "name": "Gabe Nuels",
    "role": "Lead Developer",
    "avatar_url": "https://i.pravatar.cc/150?u=f47ac10b",
    "status": "accepted",
    "sort_order": 0,
    "created_at": "2024-02-10 09:00:00"
  },
  {
    "id": "a7b9c1d3-6e8f-4a0b-c2d4-e5f6a7b8c9d1",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "user_id": "9c8b7a6d-5e4f-4321-abcd-fedcba987654",
    "name": "Sona Petrosyan",
    "role": "UI/UX Designer",
    "avatar_url": "https://i.pravatar.cc/150?u=9c8b7a6d",
    "status": "accepted",
    "sort_order": 1,
    "created_at": "2024-02-12 10:00:00"
  },
  {
    "id": "a7b9c1d3-6e8f-4a0b-c2d4-e5f6a7b8c9d2",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "user_id": null,
    "name": "Armen Hakobyan",
    "role": "Hardware Engineer",
    "avatar_url": null,
    "status": "accepted",
    "sort_order": 2,
    "created_at": "2024-02-12 10:00:00"
  }
]
```

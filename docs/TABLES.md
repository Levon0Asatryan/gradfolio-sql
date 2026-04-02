# Gradfolio Database — Tables Overview

## All Tables (12)

| # | Table | Columns | Purpose |
| --- | --- | --- | --- |
| 1 | `users` | 18 | Core user accounts and profile data |
| 2 | `education` | 10 | Education history entries per user |
| 3 | `experience` | 10 | Work/internship experience entries per user |
| 4 | `certifications` | 7 | Professional certifications per user |
| 5 | `user_skills` | 4 | Skill tags per user |
| 6 | `projects` | 24 | Full project entries with metadata and repo info |
| 7 | `project_attachments` | 7 | Media attachments (images, videos, PDFs, links) per project |
| 8 | `project_team_members` | 9 | Team collaborators per project with invitation status |
| 9 | `integrations` | 10 | LinkedIn/GitHub OAuth connections per user |
| 10 | `activities` | 7 | Activity feed timeline events per user |
| 11 | `notifications` | 10 | User notifications (team invites, verifications, etc.) |

**Total: 12 tables, 116 columns**

---

## Relationships

```
users
│  id PK
│  auth0_id UNIQUE
│
├─── education              (user_id → users.id CASCADE)
├─── experience             (user_id → users.id CASCADE)
├─── certifications         (user_id → users.id CASCADE)
├─── user_skills            (user_id → users.id CASCADE)
├─── projects               (user_id → users.id CASCADE)
│       ├─── project_attachments    (project_id → projects.id CASCADE)
│       └─── project_team_members   (project_id → projects.id CASCADE,
│                                    user_id → users.id SET NULL)
├─── integrations           (user_id → users.id CASCADE)
│       UNIQUE (user_id, integration_type)
├─── activities             (user_id → users.id CASCADE)
└─── notifications          (user_id → users.id CASCADE)
```

All foreign keys use `ON DELETE CASCADE` except `project_team_members.user_id` which uses `ON DELETE SET NULL` — when a user deletes their account, their team member records remain on projects (name and role preserved) but the user link is broken.

---

## ENUM Types

| Table | Column | Values |
| --- | --- | --- |
| `projects` | `category` | `academic`, `personal`, `research`, `hackathon`, `course`, `other` |
| `projects` | `status` | `ongoing`, `completed`, `archived` |
| `project_attachments` | `type` | `image`, `video`, `pdf`, `link` |
| `project_team_members` | `status` | `pending`, `accepted`, `rejected` |
| `integrations` | `integration_type` | `linkedin`, `github` |
| `integrations` | `status` | `connected`, `not_connected` |
| `activities` | `type` | `project`, `profile` |
| `notifications` | `type` | `team_invite`, `team_accepted`, `team_rejected`, `project_verified`, `comment`, `contact_request`, `general` |

---

## JSON Columns

| Table | Column | Expected structure | Example |
| --- | --- | --- | --- |
| `education` | `highlights` | `string[]` | `["Dean's List 2023", "Thesis: AI in Healthcare"]` |
| `experience` | `achievements` | `string[]` | `["Increased page load speed by 20%", "Led team of 4"]` |
| `experience` | `skills` | `string[]` | `["React", "TypeScript", "Node.js"]` |
| `projects` | `tags` | `string[]` | `["web-app", "machine-learning", "capstone"]` |
| `projects` | `technologies` | `string[]` | `["Python", "TensorFlow", "Flask"]` |
| `projects` | `links` | `{label: string, url: string}[]` | `[{"label": "Paper", "url": "https://doi.org/..."}]` |
| `projects` | `files` | `{label: string, url: string}[]` | `[{"label": "Report.pdf", "url": "/uploads/..."}]` |
| `activities` | `translation_params` | `Record<string, string \| number>` | `{"projectName": "Smart Garden", "count": 3}` |

---

## Naming Conventions

- **Primary keys**: `id VARCHAR(36)` with `DEFAULT (UUID())` — MySQL 8.0+ native UUID generation
- **Foreign keys**: `{entity}_id` (e.g., `user_id`, `project_id`)
- **Column names**: `snake_case` (transformed to `camelCase` at the API layer)
- **Timestamps**: `DATETIME` with `DEFAULT CURRENT_TIMESTAMP` and optional `ON UPDATE CURRENT_TIMESTAMP`
- **Booleans**: `TINYINT(1)` with `0` = false, `1` = true
- **Ordering**: `sort_order INT DEFAULT 0` on all ordered child tables
- **Constraint names**: `fk_{table}_{referenced}` for FKs, `uq_{table}_{columns}` for UNIQUEs, `idx_{table}_{columns}` for indexes

---

## Frontend Type Mapping

| Table | TypeScript type(s) | Source file |
| --- | --- | --- |
| `users` | `ProfileData`, `DashboardHeaderUser` | `src/data/profile.mock.ts`, `src/components/dashboard/DashboardHeader.tsx` |
| `education` | `Education` | `src/data/profile.mock.ts` |
| `experience` | `Experience` | `src/data/profile.mock.ts` |
| `certifications` | `Certification` | `src/data/profile.mock.ts` |
| `user_skills` | `ProfileData.skills` (string array) | `src/data/profile.mock.ts` |
| `projects` | `ProjectDetailData`, `Project` (profile-level), `Project` (dashboard) | `src/data/project.mock.ts`, `src/data/profile.mock.ts`, `src/utils/types/dashboard.types.ts` |
| `project_attachments` | `ProjectAttachment` | `src/data/project.mock.ts` |
| `project_team_members` | `TeamMember` | `src/data/project.mock.ts`, `src/data/profile.mock.ts` |
| `integrations` | `Integration` | `src/data/integrations.mock.ts` |
| `activities` | `Activity` | `src/utils/types/dashboard.types.ts` |
| `notifications` | *(no frontend type yet — to be created)* | — |

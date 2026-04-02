# Table: `experience`

## Purpose

Stores work experience entries for each user — internships, part-time jobs, research assistantships, or any relevant professional experience. Users can have multiple entries. Supports the Portfolio Profile Page (Feature 3) and LinkedIn data import (Feature 2).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Frontend Type Mapping

- `Experience` interface in `src/data/profile.mock.ts`
- Rendered by `ExperienceList.tsx` (read-only) and `EditableExperienceList.tsx` (edit mode)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Maps to `Experience.id`. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. CASCADE on delete. |
| `title` | `VARCHAR(500)` | NO | — | Job title (e.g., "Software Engineering Intern", "Research Assistant"). Maps to `Experience.title`. |
| `organization` | `VARCHAR(500)` | NO | — | Company or institution name (e.g., "Google", "MIT AI Lab"). Maps to `Experience.organization`. |
| `start` | `VARCHAR(7)` | NO | — | Start date in ISO month format `YYYY-MM` (e.g., `"2023-06"`). `VARCHAR(7)` because this is a formatted string, not a full date — we only need year and month precision. Matches the frontend format exactly. Maps to `Experience.start`. |
| `end` | `VARCHAR(7)` | YES | `NULL` | End date in ISO month format. `NULL` means "Present" (currently working there). Same format rationale as `start`. Maps to `Experience.end?`. |
| `summary` | `TEXT` | NO | — | Description of duties, responsibilities, and achievements. `TEXT` because this can be several paragraphs. Maps to `Experience.summary`. |
| `achievements` | `JSON` | YES | `NULL` | Array of achievement bullet points (e.g., `["Increased page load speed by 20%", "Led team of 4 developers"]`). `JSON` because it's a variable-length list always read/written as a whole. Maps to `Experience.achievements?`. |
| `skills` | `JSON` | YES | `NULL` | Array of skill names used in this role (e.g., `["React", "TypeScript", "AWS"]`). `JSON` for same reason as achievements. Displayed as chips in the experience detail dialog. Maps to `Experience.skills?`. |
| `sort_order` | `INT` | NO | `0` | Display order on the profile. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_experience_user` | B-tree | `user_id` | Fast lookup of all experience entries for a user |

## Example Data

```json
{
  "id": "exp_001",
  "user_id": "u_001",
  "title": "Frontend Developer Intern",
  "organization": "ACME Corp",
  "start": "2023-06",
  "end": "2023-09",
  "summary": "Developed new features for the customer-facing dashboard using React and TypeScript. Improved page load performance by 20%.",
  "achievements": ["Built 3 new dashboard widgets", "Reduced bundle size by 15%", "Mentored 2 junior interns"],
  "skills": ["React", "TypeScript", "Webpack", "Jest"],
  "sort_order": 0
}
```

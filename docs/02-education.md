# Table: `education`

## Purpose

Stores education history entries for each user. Each row represents one degree or educational program (e.g., Bachelor's, Master's, high school). Users can have multiple education entries. Supports the Portfolio Profile Page (Feature 3) and LinkedIn data import (Feature 2).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Frontend Type Mapping

- `Education` interface in `src/data/profile.mock.ts`
- Rendered by `EducationList.tsx` (read-only) and `EditableEducationList.tsx` (edit mode)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Maps to `Education.id`. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. Which user this education entry belongs to. CASCADE on delete — if the user is deleted, all their education entries are removed. |
| `institution` | `VARCHAR(500)` | NO | — | Name of the school/university (e.g., "National Polytechnic University of Armenia"). 500 chars covers long institution names with departments. Maps to `Education.institution`. |
| `degree` | `VARCHAR(500)` | NO | — | Degree type (e.g., "Bachelor of Science", "Master of Engineering"). Maps to `Education.degree`. |
| `field` | `VARCHAR(500)` | NO | — | Field of study (e.g., "Computer Science", "Electrical Engineering"). Maps to `Education.field`. |
| `start_year` | `SMALLINT` | NO | — | Year the program started (e.g., `2020`). `SMALLINT` (2 bytes, range -32768 to 32767) is ideal for years — much more efficient than INT. Maps to `Education.startYear`. |
| `end_year` | `SMALLINT` | YES | `NULL` | Year the program ended or expected to end. `NULL` means currently enrolled. Maps to `Education.endYear?`. |
| `description` | `TEXT` | YES | `NULL` | Free-text description. Can include notable courses, GPA, thesis/capstone titles, honors. `TEXT` because length varies widely. Maps to `Education.description?`. |
| `highlights` | `JSON` | YES | `NULL` | Array of highlight strings (e.g., `["Dean's List 2023", "Summa Cum Laude"]`). `JSON` because it's a variable-length array that doesn't need individual querying — always read/written as a whole. Maps to `Education.highlights?`. |
| `sort_order` | `INT` | NO | `0` | Display order on the profile. Lower numbers appear first. Allows user to reorder education entries via drag-and-drop or manual ordering. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_education_user` | B-tree | `user_id` | Fast lookup of all education entries for a user (profile page query) |

## Example Data

```json
{
  "id": "ed_001",
  "user_id": "u_001",
  "institution": "National Polytechnic University of Armenia",
  "degree": "Bachelor of Science",
  "field": "Computer Science",
  "start_year": 2020,
  "end_year": 2024,
  "description": "Focused on software engineering and AI. Capstone: Student Portfolio Management System.",
  "highlights": ["Dean's List 2022", "Dean's List 2023", "GPA: 3.8/4.0"],
  "sort_order": 0
}
```

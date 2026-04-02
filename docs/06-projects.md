# Table: `projects`

## Purpose

Stores full project entries — the core content of the portfolio. Each project is a first-class entity with its own detail page, rich content, repo info, and metadata. This is the largest table in the schema because it embeds repo info and metadata fields directly (denormalized for simpler queries). Supports Project Pages (Feature 4), Search & Discovery (Feature 6), Dashboard (Feature 7), and GitHub import (Feature 2).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **Children**: `project_attachments` (media files), `project_team_members` (collaborators)

## Frontend Type Mapping

This table maps to **three** different TypeScript types depending on context:

| Type | File | Context | Fields used |
| --- | --- | --- | --- |
| `ProjectDetailData` | `src/data/project.mock.ts` | Full project detail page (`/projects/[id]`) | All fields |
| `Project` | `src/data/profile.mock.ts` | Profile page project cards | id, title→name, summary, category, tags, href, team (via JOIN) |
| `Project` | `src/utils/types/dashboard.types.ts` | Dashboard recent projects | id, title, summary→description, status, technologies, updated_at→lastUpdated |

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `CHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Inserts must omit this column — MySQL generates it automatically via DEFAULT (UUID()). CHAR(36) is fixed-length, more efficient than VARCHAR for always-36-char UUIDs. Used as route parameter in `/projects/{id}`. Maps to `ProjectDetailData.id`. |
| `user_id` | `CHAR(36)` | NO | — | FK to `users.id`. The project owner/creator. CASCADE on delete. |
| `title` | `VARCHAR(500)` | NO | — | Project name (e.g., "Smart Garden IoT System"). 500 chars covers descriptive titles. Maps to `ProjectDetailData.title` and profile `Project.name`. |
| `summary` | `TEXT` | YES | `NULL` | Short text summary of the project. Used on profile cards and search results. Maps to profile `Project.summary` and dashboard `Project.description`. NULL when not provided. |
| `ai_summary` | `TEXT` | YES | `NULL` | AI-generated 2-3 sentence highlight (e.g., "An IoT project using Arduino and Raspberry Pi to automate home garden irrigation..."). Currently a manual text field on the frontend. Will be auto-generated via AI API in the future. Maps to `ProjectDetailData.aiSummary`. |
| `hero_image_url` | `TEXT` | YES | `NULL` | URL of the main banner image for the project page. Displayed at the top of the project detail page in 16:9 aspect ratio. `TEXT` because image URLs can be long (especially from CDNs). Maps to `ProjectDetailData.heroImageUrl?`. |
| `description_html` | `LONGTEXT` | YES | `NULL` | Detailed project description as sanitized HTML. Can include headings, lists, links, formatted text. `LONGTEXT` (up to 4GB) because rich descriptions with embedded content can be large. The frontend sanitizes this before rendering (strips scripts, event handlers). Maps to `ProjectDetailData.descriptionHtml`. |
| `live_demo_url` | `TEXT` | YES | `NULL` | URL to the live deployed application (e.g., `https://my-app.vercel.app`). Shown as a button on the project header. Maps to `ProjectDetailData.liveDemoUrl?`. |
| `href` | `TEXT` | YES | `NULL` | General link for the project (used on profile cards when project is not on this platform). Maps to profile `Project.href?`. |
| `category` | `ENUM(...)` | NO | `'other'` | Project category. Values: `academic`, `personal`, `research`, `hackathon`, `course`, `other`. Used for filtering on the projects list page and search. The ENUM includes all values from both frontend types — profile-level uses a subset (`academic`, `personal`, `research`, `other`) while detail-level adds `course` and `hackathon`. Maps to `ProjectMetadata.category`. |
| `status` | `ENUM(...)` | NO | `'ongoing'` | Project status. Values: `ongoing`, `completed`, `archived`. Used on dashboard for status chips and filtering. Maps to dashboard `Project.status`. |
| `is_public` | `TINYINT(1)` | NO | `1` | Whether the project appears in search results and the public browse page. `1` = public (default), `0` = private (accessible only via direct link). Spec: "users can mark certain projects as private." |
| `tags` | `JSON` | YES | `NULL` | Array of general tags/labels (e.g., `["web-app", "capstone", "open-source"]`). Used on profile project cards. `JSON` because tags are always read/written as a whole list. Maps to profile `Project.tags`. |
| `technologies` | `JSON` | YES | `NULL` | Array of technology/framework names (e.g., `["React", "Node.js", "PostgreSQL"]`). Displayed as clickable chips on the project detail page — clicking navigates to search. `JSON` for same reason as tags. Maps to `ProjectDetailData.technologies`. |
| `links` | `JSON` | YES | `NULL` | Array of `{label, url}` objects for external links (e.g., publication DOI, YouTube demo). `JSON` because the structure is simple and count varies. Maps to `ProjectDetailData.links?`. |
| `files` | `JSON` | YES | `NULL` | Array of `{label, url}` objects for downloadable files (PDFs, slides). Same rationale as `links`. Maps to `ProjectDetailData.files?`. |
| `repo_url` | `TEXT` | YES | `NULL` | GitHub/GitLab repository URL. Displayed prominently on project header with a "GitHub Repo" button. Maps to `RepoInfo.url`. |
| `repo_latest_commit` | `DATE` | YES | `NULL` | Date of the most recent commit in the repo. Shown as metadata. Can be refreshed during GitHub sync. `DATE` is sufficient — commit time precision isn't needed for display. Maps to `RepoInfo.latestCommitDate?`. |
| `repo_readme_url` | `TEXT` | YES | `NULL` | URL to the repository's README file. Can be used to fetch and display README content. Maps to `RepoInfo.readmeUrl?`. |
| `meta_start_date` | `DATE` | YES | `NULL` | When the project was started. Displayed in the metadata sidebar card. `DATE` for day-level precision. Maps to `ProjectMetadata.startDate?`. |
| `meta_end_date` | `DATE` | YES | `NULL` | When the project was completed. `NULL` means ongoing. Maps to `ProjectMetadata.endDate?`. |
| `meta_course` | `VARCHAR(500)` | YES | `NULL` | Course name for academic projects (e.g., "CS 101 — Intro to AI"). Gives context that this was a class project. Maps to `ProjectMetadata.course?`. |
| `meta_professor` | `VARCHAR(500)` | YES | `NULL` | Professor/instructor name for academic projects. Maps to `ProjectMetadata.professor?`. |
| `created_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When the project was created on the platform. |
| `updated_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP ON UPDATE` | Last time the project was modified. Maps to dashboard `Project.lastUpdated`. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_projects_user` | B-tree | `user_id` | Fast lookup of all projects for a user (profile page, dashboard) |
| `idx_projects_category` | B-tree | `category` | Filter projects by category on the browse/search page |
| `idx_projects_status` | B-tree | `status` | Filter projects by status (dashboard shows ongoing vs completed) |
| `ft_projects_search` | FULLTEXT | `title, summary, ai_summary` | Natural language search across project content. Enables queries like "machine learning python" matching project titles and summaries. |

## Example Data

```json
{
  "id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
  "user_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "title": "Smart Garden IoT System",
  "summary": "An IoT system for automated home garden irrigation with real-time monitoring.",
  "ai_summary": "An Internet-of-Things project using Arduino and Raspberry Pi to automate home garden irrigation, featuring real-time soil monitoring and a mobile app dashboard.",
  "hero_image_url": "https://images.unsplash.com/photo-smart-garden",
  "description_html": "<h2>Problem</h2><p>Manual garden watering is inefficient...</p>",
  "live_demo_url": "https://smart-garden.vercel.app",
  "href": null,
  "category": "personal",
  "status": "completed",
  "is_public": 1,
  "tags": ["iot", "hardware", "mobile-app"],
  "technologies": ["Arduino", "Raspberry Pi", "React Native", "Firebase"],
  "links": [{"label": "Demo Video", "url": "https://youtube.com/watch?v=abc"}],
  "files": [{"label": "Project Report", "url": "/uploads/report.pdf"}],
  "repo_url": "https://github.com/gabenuels/smart-garden",
  "repo_latest_commit": "2024-11-15",
  "repo_readme_url": "https://github.com/gabenuels/smart-garden/blob/main/README.md",
  "meta_start_date": "2024-02-01",
  "meta_end_date": "2024-06-15",
  "meta_course": null,
  "meta_professor": null,
  "created_at": "2024-02-10 09:00:00",
  "updated_at": "2024-11-15 14:30:00"
}
```

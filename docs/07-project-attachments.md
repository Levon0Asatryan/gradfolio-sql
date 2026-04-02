# Table: `project_attachments`

## Purpose

Stores media attachments for projects — images, videos, PDFs, and external links. Each project can have multiple attachments displayed in an attachments gallery. This is a separate table (not JSON) because each attachment has multiple fields and needs its own sort order. Supports Project Pages (Feature 4).

## Relationships

- **Parent**: `projects` (via `project_id` FK, CASCADE delete — deleting a project removes all its attachments)
- **No children**

## Frontend Type Mapping

- `ProjectAttachment` interface in `src/data/project.mock.ts` and `src/data/profile.mock.ts` (identical definition in both)
- `ProjectAttachmentForm` in `src/components/project-new/types.ts` (form variant, same fields)
- Rendered by `AttachmentsGallery.tsx` (detail page) and `ProjectMediaUpload.tsx` (create/edit form)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Maps to `ProjectAttachment.id`. |
| `project_id` | `VARCHAR(36)` | NO | — | FK to `projects.id`. CASCADE on delete. |
| `type` | `ENUM(...)` | NO | — | Attachment type. Values: `image`, `video`, `pdf`, `link`. Determines how the frontend renders it: images get lightbox preview, videos get YouTube embed detection, PDFs get download link, links get external navigation. Maps to `ProjectAttachment.type`. |
| `url` | `TEXT` | NO | — | URL to the resource. Can be an uploaded file path (`/uploads/screenshot.png`), external URL (`https://youtube.com/watch?v=...`), or CDN link. `TEXT` because URLs vary in length. Maps to `ProjectAttachment.url`. |
| `title` | `VARCHAR(500)` | YES | `NULL` | Display title for the attachment (e.g., "App Screenshot", "Demo Video", "Final Report"). Shown as label in the gallery. Maps to `ProjectAttachment.title?`. |
| `thumbnail_url` | `TEXT` | YES | `NULL` | URL to a thumbnail image. For images, this may be a resized version; for videos, a preview frame. Falls back to `url` for images if not set. Maps to `ProjectAttachment.thumbnailUrl?`. |
| `sort_order` | `INT` | NO | `0` | Display order in the attachments gallery. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_project_attach_project` | B-tree | `project_id` | Fast lookup of all attachments for a project |

## Example Data

```json
[
  {
    "id": "att_001",
    "project_id": "proj_001",
    "type": "image",
    "url": "https://images.unsplash.com/photo-dashboard",
    "title": "Dashboard Screenshot",
    "thumbnail_url": null,
    "sort_order": 0
  },
  {
    "id": "att_002",
    "project_id": "proj_001",
    "type": "video",
    "url": "https://youtube.com/watch?v=demo123",
    "title": "Demo Walkthrough",
    "thumbnail_url": "https://img.youtube.com/vi/demo123/0.jpg",
    "sort_order": 1
  },
  {
    "id": "att_003",
    "project_id": "proj_001",
    "type": "pdf",
    "url": "/uploads/proj_001/final-report.pdf",
    "title": "Final Report",
    "thumbnail_url": null,
    "sort_order": 2
  }
]
```

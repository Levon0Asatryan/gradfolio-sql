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
| `id` | `CHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Inserts must omit this column — MySQL generates it automatically via DEFAULT (UUID()). CHAR(36) is fixed-length, more efficient than VARCHAR for always-36-char UUIDs. Maps to `ProjectAttachment.id`. |
| `project_id` | `CHAR(36)` | NO | — | FK to `projects.id`. CASCADE on delete. |
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
    "id": "f6a8b0c2-5d7e-4f9a-b1c3-d4e5f6a7b8c9",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "type": "image",
    "url": "https://images.unsplash.com/photo-dashboard",
    "title": "Dashboard Screenshot",
    "thumbnail_url": null,
    "sort_order": 0
  },
  {
    "id": "f6a8b0c2-5d7e-4f9a-b1c3-d4e5f6a7b8ca",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "type": "video",
    "url": "https://youtube.com/watch?v=demo123",
    "title": "Demo Walkthrough",
    "thumbnail_url": "https://img.youtube.com/vi/demo123/0.jpg",
    "sort_order": 1
  },
  {
    "id": "f6a8b0c2-5d7e-4f9a-b1c3-d4e5f6a7b8cb",
    "project_id": "a1b2c3d4-e5f6-4a7b-8c9d-ef0123456789",
    "type": "pdf",
    "url": "/uploads/a1b2c3d4/final-report.pdf",
    "title": "Final Report",
    "thumbnail_url": null,
    "sort_order": 2
  }
]
```

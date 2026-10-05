# Gradfolio SQL

MySQL 8.4 schema reference for the Gradfolio Student Portfolio Management System.

**The schema is owned by [gradfolio-api](https://github.com/Levon0Asatryan/gradfolio-api)'s
migrations** (`src/core/db/migrations`, decided in its `docs/m1-plan.md`, Q2).
`sql/schema.sql` here is frozen as their baseline (`0001_baseline`). Do not change the
schema in this repository: write a migration in gradfolio-api.

## Overview

- **Database**: MySQL 8.4 (production: Cloud SQL on Google Cloud; see gradfolio-api `docs/deploy.md`)
- **Tables**: 11 (at the baseline)
- **Schema file**: `sql/schema.sql`
- **Seed data**: `sql/seed.sql`
- **Local dev**: Docker Compose (`docker-compose.yml`) with MySQL + Adminer

## Schema

```
users                          Core user accounts and profile data (18 columns)
├── education                  Education history entries (10 columns)
├── experience                 Work/internship experience entries (10 columns)
├── certifications             Professional certifications (7 columns)
├── user_skills                Skill tags (4 columns)
├── projects                   Full project entries with metadata and repo info (25 columns)
│   ├── project_attachments    Media attachments: images, videos, PDFs, links (7 columns)
│   └── project_team_members   Team collaborators with invitation status (9 columns)
├── integrations               LinkedIn/GitHub OAuth connections (11 columns)
├── activities                 Activity feed timeline events (7 columns)
└── notifications              User notifications: team invites, verifications (10 columns)
```

## Key Conventions

- **Primary keys**: `CHAR(36) NOT NULL DEFAULT (UUID())`, but the application supplies every id: relying on the default leaves `LAST_INSERT_ID()` at 0
- **Foreign keys**: `CHAR(36)` matching parent PK type, named `{entity}_id`
- **Column names**: `snake_case` (transformed to `camelCase` at API layer)
- **Booleans**: `TINYINT(1)` — `0` = false, `1` = true
- **Ordering**: `sort_order INT DEFAULT 0` on ordered child tables
- **Cascades**: All FKs use `ON DELETE CASCADE` except `project_team_members.user_id` which uses `ON DELETE SET NULL`
- **TEXT columns cannot have DEFAULT values** (MySQL strict mode, also on Cloud SQL) — use `NULL` instead

## Frontend Type Mapping

| Table | TypeScript type | Source file |
| --- | --- | --- |
| `users` | `ProfileData`, `DashboardHeaderUser` | `src/data/profile.mock.ts` |
| `education` | `Education` | `src/data/profile.mock.ts` |
| `experience` | `Experience` | `src/data/profile.mock.ts` |
| `certifications` | `Certification` | `src/data/profile.mock.ts` |
| `user_skills` | `ProfileData.skills` | `src/data/profile.mock.ts` |
| `projects` | `ProjectDetailData`, `Project` | `src/data/project.mock.ts` |
| `project_attachments` | `ProjectAttachment` | `src/data/project.mock.ts` |
| `project_team_members` | `TeamMember` | `src/data/project.mock.ts` |
| `integrations` | `Integration` | `src/data/integrations.mock.ts` |
| `activities` | `Activity` | `src/utils/types/dashboard.types.ts` |
| `notifications` | *(to be created)* | — |

## Documentation

Detailed per-table docs in `docs/`:
- `docs/TABLES.md` — overview, relationships, ENUMs, JSON columns
- `docs/01-users.md` through `docs/11-notifications.md` — one file per table with column descriptions, types, rationale, indexes, example data

## Commands

```bash
# Browse the baseline schema with its sample data (schema + seed load on first boot)
docker compose up -d          # Start MySQL + Adminer
docker compose down           # Stop containers
docker compose down -v        # Stop and delete all data

# A real database (local or Cloud SQL) is created by gradfolio-api:
#   npm run migrate    (then npm run db:seed for demo data)
```

## Environment

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=gradfolio
MYSQL_USER=gradfolio
MYSQL_PASSWORD=gradfolio_pass
MYSQL_PORT=3306
ADMINER_PORT=8080
```

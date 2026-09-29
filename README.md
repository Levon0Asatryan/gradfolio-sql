# gradfolio-sql

Reference documentation for the Gradfolio database (MySQL 8.4): per-table docs, the
ERD, example queries and a browsable sample database.

> **The schema is owned by [gradfolio-api](https://github.com/Levon0Asatryan/gradfolio-api).**
> Its migrations in `src/core/db/migrations` are the source of truth, and
> `npm run migrate` there creates or upgrades a database (local or Aiven). The decision
> and its evidence are in gradfolio-api's `docs/m1-plan.md` (Q2).
>
> `sql/schema.sql` here is **frozen**: it is gradfolio-api's baseline migration
> (`0001_baseline`), proved identical by a test there. Later schema changes (CHECK
> constraints, tag tables, GitHub import columns) exist only as gradfolio-api
> migrations. Do not edit the schema here.

---

## Browse the baseline locally

Requires Docker.

```bash
cp .env.example .env        # edit credentials if needed
docker compose up -d        # MySQL + Adminer; loads schema.sql, then seed.sql, on first boot
docker compose ps           # gradfolio-mysql: healthy, gradfolio-adminer: running
```

| Container           | What it does                         | Default port |
|---------------------|--------------------------------------|--------------|
| `gradfolio-mysql`   | MySQL 8.4 with the baseline + seed   | `3306`       |
| `gradfolio-adminer` | Web UI to browse the database        | `8080`       |

Adminer: open `http://localhost:8080` and log in with `mysql` / `gradfolio` / `gradfolio_pass` / `gradfolio`.

Start again from scratch with `docker compose down -v && docker compose up -d`.

For development against the real, current schema, use gradfolio-api instead
(`docker compose up -d --build` there runs its migrations).

---

## SQL files

| File | Purpose |
|------|---------|
| `sql/schema.sql` | The baseline schema: 11 tables, indexes, constraints. Frozen. |
| `sql/seed.sql` | Sample data for browsing (3 users, 4 projects, teams, activities, notifications) |
| `sql/queries.sql` | **Illustrative only.** Examples of the queries the API needs, with their ownership and visibility rules. The API's real queries live in gradfolio-api. |
| `sql/drop.sql` | Drops every table |

### Seed data overview

- **3 users**: Levon (CS student, NPUA), Sona (UX/UI designer), Armen (Data Science, YSU)
- **3 education** entries, **3 experience** entries, **3 certifications**
- **13 skills** across all users
- **4 projects**: Gradfolio (capstone), Weather Dashboard, EduConnect, Wine Quality Predictor
- **5 attachments**, **3 team members** (incl. 1 external without an account)
- **3 integrations**, **5 activities**, **3 notifications**

The seed generates ids with `SET @user1 = UUID()` and passes them explicitly, the way
the application must. **A project's owner is never a team-member row**: the owner is
`projects.user_id`. Notification links are built from the real project ids.

---

## Schema overview (11 tables, at the baseline)

```
users                          Core user accounts and profile data (18 cols)
├── education                  Education history entries (10 cols)
├── experience                 Work/internship experience entries (10 cols)
├── certifications             Professional certifications (7 cols)
├── user_skills                Skill tags (4 cols)
├── projects                   Full project entries with metadata and repo info (25 cols)
│   ├── project_attachments    Media attachments: images, videos, PDFs, links (7 cols)
│   └── project_team_members   Team collaborators with invitation status (9 cols)
├── integrations               LinkedIn/GitHub OAuth connections (11 cols)
├── activities                 Activity feed timeline events (7 cols)
└── notifications              User notifications: team invites, verifications (10 cols)
```

## Relations

```
users
│  id PK (CHAR(36) UUID, supplied by the application)
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

All foreign keys use `ON DELETE CASCADE` — deleting a user removes all their data; deleting a project removes its attachments and team members.

Exception: `project_team_members.user_id` uses `ON DELETE SET NULL` — if a user deletes their account, their team member records stay on projects (name and role preserved) but the user link is broken.

## Key Conventions

- **Primary keys**: `CHAR(36) DEFAULT (UUID())`, but the application supplies every id: an INSERT that relies on the default leaves `LAST_INSERT_ID()` at 0, so the new id cannot be read back
- **Foreign keys**: `CHAR(36)` matching parent PK, named `{entity}_id`
- **Column names**: `snake_case` (transformed to `camelCase` at the API layer)
- **Booleans**: `TINYINT(1)` — `0` = false, `1` = true
- **TEXT columns**: use `NULL`, not `DEFAULT ''` (MySQL strict mode on Aiven disallows TEXT defaults)
- **Ordering**: `sort_order INT DEFAULT 0` on ordered child tables

## Table → TypeScript Type Mapping

| Table | TS type / interface |
|---|---|
| `users` | `ProfileData` + `ProfileData.socialLinks` + `DashboardHeaderUser` |
| `education` | `Education` (`highlights` → JSON) |
| `experience` | `Experience` (`achievements` + `skills` → JSON) |
| `certifications` | `Certification` |
| `user_skills` | `ProfileData.skills` |
| `projects` | `ProjectDetailData` + `Project` + `RepoInfo` + `ProjectMetadata` |
| `project_attachments` | `ProjectAttachment` |
| `project_team_members` | `TeamMember` |
| `integrations` | `Integration` |
| `activities` | `Activity` |
| `notifications` | *(frontend type to be created)* |

---

## Documentation

See `docs/` for detailed per-table documentation (every column: type, purpose, rationale, indexes, examples):

- [TABLES.md](docs/TABLES.md) — Overview, relationships, ENUMs, JSON columns, naming conventions
- [01-users.md](docs/01-users.md) — [02-education.md](docs/02-education.md) — [03-experience.md](docs/03-experience.md) — [04-certifications.md](docs/04-certifications.md)
- [05-user-skills.md](docs/05-user-skills.md) — [06-projects.md](docs/06-projects.md) — [07-project-attachments.md](docs/07-project-attachments.md) — [08-project-team-members.md](docs/08-project-team-members.md)
- [09-integrations.md](docs/09-integrations.md) — [10-activities.md](docs/10-activities.md) — [11-notifications.md](docs/11-notifications.md)

# gradfolio-sql

MySQL 8.4 database schema for the Gradfolio Student Portfolio System.

---

## Setup

### Option A: Aiven (Production — Free Tier)

The database is hosted on [Aiven](https://aiven.io/free-mysql-database) (free MySQL 8, 1 GB storage, no expiration).

1. Sign up at [aiven.io](https://aiven.io) (no credit card needed)
2. Create a MySQL service → copy connection details (host, port, user, password)
3. Connect via DataGrip, CLI, or any MySQL client (SSL required)
4. Run `sql/schema.sql` to create tables (remove the `CREATE DATABASE` and `USE` lines — Aiven provides `defaultdb`)
5. Run `sql/seed.sql` to populate test data

```bash
# CLI example
mysql -h <host> -P <port> -u avnadmin -p --ssl-mode=REQUIRED defaultdb < sql/schema.sql
mysql -h <host> -P <port> -u avnadmin -p --ssl-mode=REQUIRED defaultdb < sql/seed.sql
```

### Option B: Local Docker (Development)

Requires [Docker](https://www.docker.com/products/docker-desktop) and Docker Compose.

```bash
cd gradfolio-sql
cp .env.example .env        # edit credentials if needed
docker compose up -d        # starts MySQL + Adminer
```

| Container           | What it does                         | Default port |
|---------------------|--------------------------------------|--------------|
| `gradfolio-mysql`   | MySQL 8.4 database server            | `3306`       |
| `gradfolio-adminer` | Web UI to browse/manage the database | `8080`       |

On first boot, Docker runs `sql/schema.sql` automatically.

To load seed data:

```bash
docker exec -i gradfolio-mysql mysql -u gradfolio -pgradfolio_pass gradfolio < sql/seed.sql
```

Verify: `docker compose ps` — both containers should be `healthy` / `running`.

Adminer UI: open `http://localhost:8080` and log in with `mysql` / `gradfolio` / `gradfolio_pass` / `gradfolio`.

---

## Connecting from gradfolio (Next.js)

Add to `.env.local` in the `gradfolio` frontend project:

```env
# Local Docker
DATABASE_URL=mysql://gradfolio:gradfolio_pass@localhost:3306/gradfolio

# Aiven
DATABASE_URL=mysql://avnadmin:<password>@<host>:<port>/defaultdb?ssl={"rejectUnauthorized":true}
```

---

## SQL Files

| File | Purpose | When to run |
|------|---------|-------------|
| `sql/schema.sql` | Creates all 12 tables, indexes, and constraints | Once, on fresh database |
| `sql/seed.sql` | Inserts test data (3 users, 4 projects, teams, activities) | After schema, for development/demo |

### Seed data overview

- **3 users**: Levon (CS student, NPUA), Sona (UX/UI designer), Armen (Data Science, YSU)
- **3 education** entries, **3 experience** entries, **3 certifications**
- **13 skills** across all users
- **4 projects**: Gradfolio (capstone), Weather Dashboard, EduConnect, Wine Quality Predictor
- **5 attachments**, **5 team members** (incl. 1 external without account)
- **3 integrations**, **5 activities**, **3 notifications**

All IDs are auto-generated UUIDs via `@variable` chaining — seed uses `SET @user1 = UUID()` then references `@user1` in child tables.

---

## Schema Overview (12 tables)

```
users                          Core user accounts and profile data (18 cols)
├── education                  Education history entries (10 cols)
├── experience                 Work/internship experience entries (10 cols)
├── certifications             Professional certifications (7 cols)
├── user_skills                Skill tags (4 cols)
├── projects                   Full project entries with metadata and repo info (24 cols)
│   ├── project_attachments    Media attachments: images, videos, PDFs, links (7 cols)
│   └── project_team_members   Team collaborators with invitation status (9 cols)
├── integrations               LinkedIn/GitHub OAuth connections (10 cols)
├── activities                 Activity feed timeline events (7 cols)
└── notifications              User notifications: team invites, verifications (10 cols)
```

## Relations

```
users
│  id PK (CHAR(36), auto-generated UUID)
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

- **Primary keys**: `CHAR(36) DEFAULT (UUID())` — always auto-generated, never provided in INSERT
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

---

## Re-creating from scratch

### Aiven

Drop all tables in DataGrip (or delete and recreate the service), then re-run `schema.sql` + `seed.sql`.

### Docker

```bash
docker compose down -v    # stop containers and delete data volume
docker compose up -d      # fresh start — schema.sql runs automatically
# Then load seed:
docker exec -i gradfolio-mysql mysql -u gradfolio -pgradfolio_pass gradfolio < sql/seed.sql
```

---

## Teardown

```bash
docker compose down       # stop containers, keep data
docker compose down -v    # stop containers and delete all data
```

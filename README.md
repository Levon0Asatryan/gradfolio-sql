# gradfolio-sql

MySQL 8.4 database schema for the Gradfolio Student Portfolio System.

---

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop) and Docker Compose

---

## Setup

### 1. Clone / enter the directory

```bash
cd gradfolio-sql
```

### 2. Create your env file

```bash
cp .env.example .env
```

Open `.env` and change the credentials if needed:

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=gradfolio
MYSQL_USER=gradfolio
MYSQL_PASSWORD=gradfolio_pass
MYSQL_PORT=3306
ADMINER_PORT=8080
```

### 3. Start the server

```bash
docker compose up -d
```

This starts two containers:

| Container           | What it does                        | Default port |
|---------------------|-------------------------------------|--------------|
| `gradfolio-mysql`   | MySQL 8.4 database server           | `3306`       |
| `gradfolio-adminer` | Web UI to browse/manage the database| `8080`       |

On **first boot**, Docker automatically runs `sql/schema.sql` which creates the
`gradfolio` database and all tables.

### 4. Verify it's running

```bash
docker compose ps
```

You should see both containers with status `healthy` / `running`.

### 5. Open Adminer (optional)

Go to **http://localhost:8080** and log in:

| Field    | Value          |
|----------|----------------|
| System   | MySQL          |
| Server   | `mysql`        |
| Username | `gradfolio`    |
| Password | `gradfolio_pass` |
| Database | `gradfolio`    |

---

## Creating the database and tables manually

If you want to run the schema yourself instead of relying on auto-init:

```bash
# Open a shell inside the running MySQL container
docker exec -it gradfolio-mysql mysql -u gradfolio -pgradfolio_pass

# Then inside the MySQL shell:
source /docker-entrypoint-initdb.d/schema.sql
```

Or pipe it directly from your host machine:

```bash
docker exec -i gradfolio-mysql mysql -u gradfolio -pgradfolio_pass < sql/schema.sql
```

---

## Re-creating the schema from scratch

If you need to wipe everything and start over:

```bash
docker compose down -v          # stop containers and delete the data volume
docker compose up -d            # fresh start — schema.sql runs again automatically
```

---

## Connecting from gradfolio (Next.js)

Add to your `.env.local` in the `gradfolio` project:

```env
DATABASE_URL=mysql://gradfolio:gradfolio_pass@localhost:3306/gradfolio
```

---

## Schema overview (12 tables)

```
users                          Core user accounts and profile data
├── education                  Education history entries
├── experience                 Work/internship experience entries
├── certifications             Professional certifications
├── user_skills                Skill tags
├── projects                   Full project entries with metadata and repo info
│   ├── project_attachments    Media attachments (images, videos, PDFs, links)
│   └── project_team_members   Team collaborators with invitation status
├── integrations               LinkedIn/GitHub OAuth connections
├── activities                 Activity feed timeline events
└── notifications              User notifications (team invites, verifications)
```

## Relations

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

All foreign keys use `ON DELETE CASCADE` — deleting a user removes all their
data; deleting a project removes its attachments and team members.

Exception: `project_team_members.user_id` uses `ON DELETE SET NULL` — if a
user deletes their account, their team member records stay on projects (name
and role preserved) but the user link is broken.

### Table → TypeScript type mapping

| Table                  | TS type / interface                                              |
|------------------------|------------------------------------------------------------------|
| `users`                | `ProfileData` + `ProfileData.socialLinks` + `DashboardHeaderUser`|
| `education`            | `Education` (`highlights` → JSON column)                         |
| `experience`           | `Experience` (`achievements` + `skills` → JSON columns)          |
| `certifications`       | `Certification`                                                  |
| `user_skills`          | `ProfileData.skills`                                             |
| `projects`             | `ProjectDetailData` + `Project` + `RepoInfo` + `ProjectMetadata` |
| `project_attachments`  | `ProjectAttachment`                                              |
| `project_team_members` | `TeamMember`                                                     |
| `integrations`         | `Integration`                                                    |
| `activities`           | `Activity`                                                       |
| `notifications`        | *(frontend type to be created)*                                  |

---

## Documentation

See the `docs/` folder for detailed documentation of every table and column:

- [TABLES.md](docs/TABLES.md) — Overview of all tables, relationships, ENUMs, JSON columns, naming conventions
- [01-users.md](docs/01-users.md) — `users` table
- [02-education.md](docs/02-education.md) — `education` table
- [03-experience.md](docs/03-experience.md) — `experience` table
- [04-certifications.md](docs/04-certifications.md) — `certifications` table
- [05-user-skills.md](docs/05-user-skills.md) — `user_skills` table
- [06-projects.md](docs/06-projects.md) — `projects` table
- [07-project-attachments.md](docs/07-project-attachments.md) — `project_attachments` table
- [08-project-team-members.md](docs/08-project-team-members.md) — `project_team_members` table
- [09-integrations.md](docs/09-integrations.md) — `integrations` table
- [10-activities.md](docs/10-activities.md) — `activities` table
- [11-notifications.md](docs/11-notifications.md) — `notifications` table

---

## Teardown

```bash
docker compose down       # stop containers, keep data
docker compose down -v    # stop containers and delete all data
```

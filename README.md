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

## Relations

```
users
│  id PK
│  auth0_id UNIQUE
│
├─── education            (user_id → users.id)
├─── experience           (user_id → users.id)
├─── certifications       (user_id → users.id)
├─── user_skills          (user_id → users.id)
├─── projects             (user_id → users.id)
│       └─── project_attachments   (project_id → projects.id)
├─── integrations         (user_id → users.id)
│       UNIQUE (user_id, integration_type)
└─── activities           (user_id → users.id)
```

All foreign keys use `ON DELETE CASCADE` — deleting a user removes all their
data; deleting a project removes its attachments.

| Table                 | Column       | References    |
|-----------------------|--------------|---------------|
| `education`           | `user_id`    | `users.id`    |
| `experience`          | `user_id`    | `users.id`    |
| `certifications`      | `user_id`    | `users.id`    |
| `user_skills`         | `user_id`    | `users.id`    |
| `projects`            | `user_id`    | `users.id`    |
| `project_attachments` | `project_id` | `projects.id` |
| `integrations`        | `user_id`    | `users.id`    |
| `activities`          | `user_id`    | `users.id`    |

---

## Schema overview (10 tables)

```
users                       ProfileData  (github/linkedin columns inline)
├── education               Education    (highlights as JSON array)
├── experience              Experience   (achievements + skills as JSON arrays)
├── certifications          Certification
├── user_skills             ProfileData.skills
├── projects                ProjectDetailData + Project + RepoInfo + ProjectMetadata
│   └── project_attachments ProjectAttachment
├── integrations            Integration
└── activities              Activity
```

### Table → TypeScript type mapping

| Table                 | TS type / interface                                              |
|-----------------------|------------------------------------------------------------------|
| `users`               | `ProfileData` + `ProfileData.socialLinks`                        |
| `education`           | `Education` (`highlights` → JSON column)                         |
| `experience`          | `Experience` (`achievements` + `skills` → JSON columns)          |
| `certifications`      | `Certification`                                                  |
| `user_skills`         | `ProfileData.skills`                                             |
| `projects`            | `ProjectDetailData` + `Project` + `RepoInfo` + `ProjectMetadata` |
| `project_attachments` | `ProjectAttachment`                                              |
| `integrations`        | `Integration`                                                    |
| `activities`          | `Activity`                                                       |

---

## Teardown

```bash
docker compose down       # stop containers, keep data
docker compose down -v    # stop containers and delete all data
```

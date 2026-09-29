-- ============================================================
-- Gradfolio — Example Queries
--
-- ILLUSTRATIVE ONLY. Do not copy these into application code: the
-- API's real queries live in gradfolio-api, against the schema its
-- migrations own (which has moved on from this baseline).
--
-- What they do show are the rules every real query must keep:
--   * @viewer is the caller's users.id (NULL when logged out).
--   * Ownership: every write to a user-owned row is scoped to its owner
--     (user_id = @viewer, or through the owning project). 0 rows
--     changed means "not yours" and the API answers 404.
--   * Visibility: a private (is_public = 0) profile or project is
--     visible to its owner only; anyone else gets 404. (The tracker's
--     proposed Q3 rule; gradfolio-api M3 decides it.)
--   * Ids are supplied by the caller (@new_id): with DEFAULT (UUID()),
--     LAST_INSERT_ID() is 0 and the new id cannot be read back.
--   * Multi-statement writes run in one transaction.
-- ============================================================


-- ============================================================
-- 1. PROFILE — Get full user profile by ID
--    GET /api/users/:id
-- ============================================================

-- 1a. User base info. Never SELECT *: birthday, phone and auth0_id are
--     private, and tokens live elsewhere.
SELECT id, name, headline, location, verified, is_public, avatar_url, bio,
       github, linkedin, twitter, website, created_at
FROM users
WHERE id = @uid AND (is_public = 1 OR id = @viewer);

-- 1b. Education (ordered)
SELECT * FROM education WHERE user_id = @uid ORDER BY sort_order;

-- 1c. Experience (ordered)
SELECT * FROM experience WHERE user_id = @uid ORDER BY sort_order;

-- 1d. Certifications (ordered)
SELECT * FROM certifications WHERE user_id = @uid ORDER BY sort_order;

-- 1e. Skills (ordered)
SELECT skill_name FROM user_skills WHERE user_id = @uid ORDER BY sort_order;

-- 1f. User's own projects (summary for profile cards)
SELECT id, title, summary, category, status, tags, technologies, created_at
FROM projects
WHERE user_id = @uid AND (is_public = 1 OR user_id = @viewer)
ORDER BY created_at DESC;

-- 1g. Projects where user is a team member (appears on their profile too)
SELECT p.id, p.title, p.summary, p.category, p.tags, p.technologies, p.created_at
FROM projects p
JOIN project_team_members ptm ON ptm.project_id = p.id
WHERE ptm.user_id = @uid AND ptm.status = 'accepted' AND p.is_public = 1
ORDER BY p.created_at DESC;


-- ============================================================
-- 2. PROJECT DETAIL — Get full project by ID
--    GET /api/projects/:id
-- ============================================================

-- 2a. Project base info: visible to anyone if public, else to its owner only
SELECT * FROM projects
WHERE id = @pid AND (is_public = 1 OR user_id = @viewer);

-- 2b. Attachments (ordered), only through a project the viewer may see
SELECT a.*
FROM project_attachments a
JOIN projects p ON p.id = a.project_id
WHERE a.project_id = @pid AND (p.is_public = 1 OR p.user_id = @viewer)
ORDER BY a.sort_order;

-- 2c. Team members (only accepted, ordered), same visibility rule
SELECT m.id, m.user_id, m.name, m.role, m.avatar_url
FROM project_team_members m
JOIN projects p ON p.id = m.project_id
WHERE m.project_id = @pid AND m.status = 'accepted'
  AND (p.is_public = 1 OR p.user_id = @viewer)
ORDER BY m.sort_order;

-- 2d. Project owner info (for header)
SELECT u.id, u.name, u.headline, u.avatar_url
FROM users u
JOIN projects p ON p.user_id = u.id
WHERE p.id = @pid;


-- ============================================================
-- 3. DASHBOARD — Stats and recent activity
--    GET /api/dashboard
-- ============================================================

-- 3a. Total projects count
SELECT COUNT(*) AS total_projects FROM projects WHERE user_id = @viewer;

-- 3b. Recent projects (for dashboard cards)
SELECT id, title, summary, status, technologies, updated_at
FROM projects
WHERE user_id = @viewer
ORDER BY updated_at DESC
LIMIT 4;

-- 3c. Activity feed (recent 20)
SELECT * FROM activities
WHERE user_id = @viewer
ORDER BY timestamp DESC
LIMIT 20;

-- 3d. Recent activity count (last 30 days)
SELECT COUNT(*) AS recent_activities
FROM activities
WHERE user_id = @viewer AND timestamp > NOW() - INTERVAL 30 DAY;


-- ============================================================
-- 4. SEARCH — Find users and projects
--    GET /api/search?q=...
-- ============================================================

-- 4a. Search users by name/headline (fulltext)
SELECT id, name, headline, avatar_url, verified, location
FROM users
WHERE is_public = 1
  AND MATCH(name, headline) AGAINST(@query IN NATURAL LANGUAGE MODE)
LIMIT 20;

-- 4b. Search projects by title/summary (fulltext)
SELECT id, user_id, title, summary, ai_summary, category, technologies, hero_image_url, created_at
FROM projects
WHERE is_public = 1
  AND MATCH(title, summary, ai_summary) AGAINST(@query IN NATURAL LANGUAGE MODE)
LIMIT 20;

-- 4c. Search users by skill
SELECT DISTINCT u.id, u.name, u.headline, u.avatar_url, u.verified
FROM users u
JOIN user_skills us ON us.user_id = u.id
WHERE u.is_public = 1
  AND us.skill_name = @skill_name
LIMIT 20;

-- 4d. Search projects by technology tag.
--     Not JSON_CONTAINS: it compares exactly, so 'react' misses 'React'.
--     The JSON_TABLE column collates as utf8mb4_unicode_ci, so this matches
--     case-insensitively. Keep the comma-join form: on MySQL 8.4.11 the
--     correlated form (WHERE EXISTS (SELECT ... FROM JSON_TABLE(p.technologies
--     ...))) returns no rows. gradfolio-api keeps technologies in a table.
SELECT DISTINCT p.id, p.title, p.summary, p.technologies, p.category, p.hero_image_url
FROM projects p,
     JSON_TABLE(p.technologies, '$[*]' COLUMNS (tech VARCHAR(255) PATH '$')) AS jt
WHERE p.is_public = 1
  AND jt.tech = @tech
LIMIT 20;


-- ============================================================
-- 5. TAG CLOUD — Popular skills and technologies
--    GET /api/tags/skills
--    GET /api/tags/technologies
-- ============================================================

-- 5a. Top skills across all users
SELECT skill_name, COUNT(*) AS user_count
FROM user_skills
GROUP BY skill_name
ORDER BY user_count DESC
LIMIT 30;

-- 5b. Top technologies across all projects
-- (requires extracting from JSON — use a helper table or application-side aggregation)
-- Simplified: count projects mentioning a tech in their tags
SELECT jt.tag, COUNT(*) AS project_count
FROM projects,
     JSON_TABLE(technologies, '$[*]' COLUMNS (tag VARCHAR(255) PATH '$')) AS jt
WHERE is_public = 1
GROUP BY jt.tag
ORDER BY project_count DESC
LIMIT 30;


-- ============================================================
-- 6. INTEGRATIONS — Get user's integration status
--    GET /api/integrations
-- ============================================================

SELECT integration_type, status, last_synced_at
FROM integrations
WHERE user_id = @viewer;


-- ============================================================
-- 7. NOTIFICATIONS
--    GET /api/notifications
-- ============================================================

-- 7a. Unread count (for badge)
SELECT COUNT(*) AS unread_count
FROM notifications
WHERE user_id = @viewer AND is_read = 0;

-- 7b. Recent notifications (paginated)
SELECT * FROM notifications
WHERE user_id = @viewer
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- 7c. Mark one as read -- the caller's own notification only
--     (0 rows changed -> 404)
UPDATE notifications SET is_read = 1 WHERE id = @nid AND user_id = @viewer;

-- 7d. Mark all as read
UPDATE notifications SET is_read = 1
WHERE user_id = @viewer AND is_read = 0;


-- ============================================================
-- 8. TEAM MEMBERS — Invitation workflow
--    POST /api/projects/:id/team
--    PUT  /api/projects/:id/team/:memberId
-- ============================================================

-- 8a. Add teammate to project -- only the project's owner may
--     (0 rows inserted -> 404). The owner is never a member row. A teammate
--     who rejected is re-invited with an UPDATE: UNIQUE (project_id, user_id)
--     rejects a second INSERT.
INSERT INTO project_team_members (id, project_id, user_id, name, role, avatar_url, status)
SELECT @new_id, p.id, @teammate_uid, @name, @role, @avatar, 'pending'
FROM projects p
WHERE p.id = @pid AND p.user_id = @viewer AND @teammate_uid <> @viewer;

-- 8b. Accept invitation -- the invitee only, and only while pending
UPDATE project_team_members SET status = 'accepted'
WHERE id = @tm_id AND user_id = @viewer AND status = 'pending';

-- 8c. Reject invitation -- the invitee only, and only while pending
UPDATE project_team_members SET status = 'rejected'
WHERE id = @tm_id AND user_id = @viewer AND status = 'pending';

-- 8d. Get pending invitations for a user
SELECT ptm.*, p.title AS project_title, p.hero_image_url
FROM project_team_members ptm
JOIN projects p ON p.id = ptm.project_id
WHERE ptm.user_id = @viewer AND ptm.status = 'pending'
ORDER BY ptm.created_at DESC;


-- ============================================================
-- 9. BROWSE — User directory and project gallery
--    GET /api/users?page=1
--    GET /api/projects?page=1
-- ============================================================

-- 9a. Browse users (paginated, public only)
SELECT id, name, headline, avatar_url, verified, location
FROM users
WHERE is_public = 1
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- 9b. Browse projects (paginated, public only, with owner name)
SELECT p.id, p.title, p.summary, p.ai_summary, p.category, p.technologies,
       p.hero_image_url, p.created_at, u.name AS owner_name, u.avatar_url AS owner_avatar
FROM projects p
JOIN users u ON u.id = p.user_id
WHERE p.is_public = 1
ORDER BY p.created_at DESC
LIMIT 20 OFFSET 0;

-- 9c. Filter projects by category
SELECT id, title, summary, technologies, hero_image_url, created_at
FROM projects
WHERE is_public = 1 AND category = @category
ORDER BY created_at DESC
LIMIT 20;


-- ============================================================
-- 10. PROFILE EDIT — Update operations
--     PUT /api/users/me
--     PUT /api/users/me/education
--     PUT /api/users/me/skills
--     Here @uid is the caller (@viewer): every write is scoped to it.
-- ============================================================

-- 10a. Update user profile fields
UPDATE users
SET name = @name, headline = @headline, location = @location,
    bio = @bio, github = @github, linkedin = @linkedin,
    twitter = @twitter, website = @website, phone = @phone
WHERE id = @uid;

-- 10b. Add education entry
INSERT INTO education (id, user_id, institution, degree, field, start_year, end_year, description, highlights, sort_order)
VALUES (@new_id, @uid, @institution, @degree, @field, @start_year, @end_year, @desc, @highlights_json, @order);

-- 10c. Update education entry
UPDATE education
SET institution = @institution, degree = @degree, field = @field,
    start_year = @start_year, end_year = @end_year, description = @desc,
    highlights = @highlights_json, sort_order = @order
WHERE id = @eid AND user_id = @uid;

-- 10d. Delete education entry
DELETE FROM education WHERE id = @eid AND user_id = @uid;

-- 10e. Replace all skills: one transaction, or a failure between the DELETE
--      and the INSERTs leaves the user with no skills at all
START TRANSACTION;
DELETE FROM user_skills WHERE user_id = @uid;
-- Then insert each skill:
INSERT INTO user_skills (id, user_id, skill_name, sort_order)
VALUES (@new_id, @uid, @skill, @order);
COMMIT;

-- 10f. Create new project
INSERT INTO projects (id, user_id, title, summary, ai_summary, description_html, category, status,
                      technologies, tags, repo_url, live_demo_url, meta_start_date, meta_course, meta_professor)
VALUES (@new_id, @uid, @title, @summary, @ai_summary, @desc_html, @category, 'ongoing',
        @technologies_json, @tags_json, @repo_url, @demo_url, @start_date, @course, @professor);

-- 10g. Delete project (cascades to attachments and team members)
DELETE FROM projects WHERE id = @pid AND user_id = @uid;

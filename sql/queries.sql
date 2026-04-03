-- ============================================================
-- Gradfolio — Example Queries
-- Common queries the backend API will need.
-- Each query is labeled with the API endpoint it supports.
-- ============================================================


-- ============================================================
-- 1. PROFILE — Get full user profile by ID
--    GET /api/users/:id
-- ============================================================

-- 1a. User base info
SELECT * FROM users WHERE id = @uid;

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
WHERE user_id = @uid AND is_public = 1
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

-- 2a. Project base info
SELECT * FROM projects WHERE id = @pid;

-- 2b. Attachments (ordered)
SELECT * FROM project_attachments WHERE project_id = @pid ORDER BY sort_order;

-- 2c. Team members (only accepted, ordered)
SELECT id, user_id, name, role, avatar_url
FROM project_team_members
WHERE project_id = @pid AND status = 'accepted'
ORDER BY sort_order;

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
SELECT COUNT(*) AS total_projects FROM projects WHERE user_id = @uid;

-- 3b. Recent projects (for dashboard cards)
SELECT id, title, summary, status, technologies, updated_at
FROM projects
WHERE user_id = @uid
ORDER BY updated_at DESC
LIMIT 4;

-- 3c. Activity feed (recent 20)
SELECT * FROM activities
WHERE user_id = @uid
ORDER BY timestamp DESC
LIMIT 20;

-- 3d. Recent activity count (last 30 days)
SELECT COUNT(*) AS recent_activities
FROM activities
WHERE user_id = @uid AND timestamp > NOW() - INTERVAL 30 DAY;


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

-- 4d. Search projects by technology tag (JSON contains)
SELECT id, title, summary, technologies, category, hero_image_url
FROM projects
WHERE is_public = 1
  AND JSON_CONTAINS(technologies, CONCAT('"', @tech, '"'))
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
WHERE user_id = @uid;


-- ============================================================
-- 7. NOTIFICATIONS
--    GET /api/notifications
-- ============================================================

-- 7a. Unread count (for badge)
SELECT COUNT(*) AS unread_count
FROM notifications
WHERE user_id = @uid AND is_read = 0;

-- 7b. Recent notifications (paginated)
SELECT * FROM notifications
WHERE user_id = @uid
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- 7c. Mark one as read
UPDATE notifications SET is_read = 1 WHERE id = @nid;

-- 7d. Mark all as read
UPDATE notifications SET is_read = 1
WHERE user_id = @uid AND is_read = 0;


-- ============================================================
-- 8. TEAM MEMBERS — Invitation workflow
--    POST /api/projects/:id/team
--    PUT  /api/projects/:id/team/:memberId
-- ============================================================

-- 8a. Add teammate to project
INSERT INTO project_team_members (project_id, user_id, name, role, avatar_url, status)
VALUES (@pid, @teammate_uid, @name, @role, @avatar, 'pending');

-- 8b. Accept invitation
UPDATE project_team_members SET status = 'accepted'
WHERE id = @tm_id AND user_id = @uid;

-- 8c. Reject invitation
UPDATE project_team_members SET status = 'rejected'
WHERE id = @tm_id AND user_id = @uid;

-- 8d. Get pending invitations for a user
SELECT ptm.*, p.title AS project_title, p.hero_image_url
FROM project_team_members ptm
JOIN projects p ON p.id = ptm.project_id
WHERE ptm.user_id = @uid AND ptm.status = 'pending'
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
-- ============================================================

-- 10a. Update user profile fields
UPDATE users
SET name = @name, headline = @headline, location = @location,
    bio = @bio, github = @github, linkedin = @linkedin,
    twitter = @twitter, website = @website, phone = @phone
WHERE id = @uid;

-- 10b. Add education entry
INSERT INTO education (user_id, institution, degree, field, start_year, end_year, description, highlights, sort_order)
VALUES (@uid, @institution, @degree, @field, @start_year, @end_year, @desc, @highlights_json, @order);

-- 10c. Update education entry
UPDATE education
SET institution = @institution, degree = @degree, field = @field,
    start_year = @start_year, end_year = @end_year, description = @desc,
    highlights = @highlights_json, sort_order = @order
WHERE id = @eid AND user_id = @uid;

-- 10d. Delete education entry
DELETE FROM education WHERE id = @eid AND user_id = @uid;

-- 10e. Replace all skills (delete + re-insert)
DELETE FROM user_skills WHERE user_id = @uid;
-- Then insert each skill:
INSERT INTO user_skills (user_id, skill_name, sort_order)
VALUES (@uid, @skill, @order);

-- 10f. Create new project
INSERT INTO projects (user_id, title, summary, ai_summary, description_html, category, status,
                      technologies, tags, repo_url, live_demo_url, meta_start_date, meta_course, meta_professor)
VALUES (@uid, @title, @summary, @ai_summary, @desc_html, @category, 'ongoing',
        @technologies_json, @tags_json, @repo_url, @demo_url, @start_date, @course, @professor);

-- 10g. Delete project (cascades to attachments and team members)
DELETE FROM projects WHERE id = @pid AND user_id = @uid;

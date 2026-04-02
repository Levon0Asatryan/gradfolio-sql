-- ============================================================
-- Gradfolio Seed Data
-- Run after schema.sql to populate test data
--
-- Uses @variables to store auto-generated UUIDs so child
-- tables can reference parent rows via foreign keys.
-- ============================================================

-- ============================================================
-- USERS
-- ============================================================

SET @user1 = UUID();
SET @user2 = UUID();
SET @user3 = UUID();

INSERT INTO users (id, auth0_id, name, headline, location, verified, is_public, email, avatar_url, bio, github, linkedin, twitter, website, phone, birthday) VALUES
(@user1, 'google-oauth2|117364529384756', 'Levon Petrosyan', 'Computer Science Student at NPUA — Full-Stack Developer', 'Yerevan, Armenia', 1, 1, 'levon.petrosyan@example.com', 'https://i.pravatar.cc/150?u=levon', 'Passionate about web development, AI, and building tools that help students succeed.', 'https://github.com/levonp', 'https://linkedin.com/in/levonp', NULL, 'https://levonp.dev', '+374 99 123456', '2002-03-15'),
(@user2, 'github|9876543', 'Sona Hakobyan', 'UX/UI Designer & Frontend Developer', 'Yerevan, Armenia', 1, 1, 'sona.hakobyan@example.com', 'https://i.pravatar.cc/150?u=sona', 'Design-focused developer who loves creating intuitive user experiences.', 'https://github.com/sonahak', 'https://linkedin.com/in/sonahak', 'https://twitter.com/sonahak', NULL, NULL, '2001-08-22'),
(@user3, 'auth0|abc123def456', 'Armen Grigoryan', 'Data Science Student at YSU', 'Gyumri, Armenia', 0, 1, 'armen.g@example.com', 'https://i.pravatar.cc/150?u=armen', 'Exploring machine learning and data visualization.', 'https://github.com/armeng', NULL, NULL, NULL, NULL, '2003-01-10');

-- ============================================================
-- EDUCATION
-- ============================================================

INSERT INTO education (user_id, institution, degree, field, start_year, end_year, description, highlights, sort_order) VALUES
(@user1, 'National Polytechnic University of Armenia', 'Bachelor of Science', 'Computer Science', 2020, 2024, 'Focused on software engineering, web technologies, and artificial intelligence.', '["Dean''s List 2022", "Dean''s List 2023", "Capstone: Student Portfolio Management System"]', 0),
(@user2, 'National Polytechnic University of Armenia', 'Bachelor of Science', 'Information Technology', 2020, 2024, 'Specialized in human-computer interaction and frontend development.', '["Best UI/UX Project Award 2023"]', 0),
(@user3, 'Yerevan State University', 'Bachelor of Science', 'Data Science', 2021, NULL, 'Currently studying statistics, machine learning, and data engineering.', NULL, 0);

-- ============================================================
-- EXPERIENCE
-- ============================================================

INSERT INTO experience (user_id, title, organization, start, `end`, summary, achievements, skills, sort_order) VALUES
(@user1, 'Frontend Developer Intern', 'SoftConstruct', '2023-06', '2023-09', 'Developed new features for the customer-facing dashboard. Collaborated with the design team on UI improvements.', '["Built 3 new dashboard components", "Reduced page load time by 18%", "Participated in code reviews"]', '["React", "TypeScript", "MUI", "Git"]', 0),
(@user1, 'Freelance Web Developer', 'Self-Employed', '2023-10', NULL, 'Building websites and web applications for small businesses in Armenia.', '["Delivered 5 client projects", "Set up CI/CD pipelines"]', '["Next.js", "Node.js", "PostgreSQL"]', 1),
(@user2, 'UI/UX Design Intern', 'PicsArt', '2023-07', '2023-12', 'Designed mobile app features and conducted user research sessions.', '["Redesigned onboarding flow — improved completion by 25%", "Created design system components"]', '["Figma", "Adobe XD", "User Research"]', 0);

-- ============================================================
-- CERTIFICATIONS
-- ============================================================

INSERT INTO certifications (user_id, name, issuer, date, credential_url, sort_order) VALUES
(@user1, 'Meta Front-End Developer', 'Coursera / Meta', '2023-05', 'https://coursera.org/verify/cert_abc123', 0),
(@user1, 'AWS Cloud Practitioner', 'Amazon Web Services', '2024-01', 'https://www.credly.com/badges/abc123', 1),
(@user2, 'Google UX Design Certificate', 'Coursera / Google', '2023-08', 'https://coursera.org/verify/cert_xyz789', 0);

-- ============================================================
-- USER SKILLS
-- ============================================================

INSERT INTO user_skills (user_id, skill_name, sort_order) VALUES
(@user1, 'TypeScript', 0),
(@user1, 'React', 1),
(@user1, 'Next.js', 2),
(@user1, 'Node.js', 3),
(@user1, 'MySQL', 4),
(@user1, 'Docker', 5),
(@user2, 'Figma', 0),
(@user2, 'React', 1),
(@user2, 'CSS', 2),
(@user2, 'User Research', 3),
(@user3, 'Python', 0),
(@user3, 'TensorFlow', 1),
(@user3, 'SQL', 2);

-- ============================================================
-- PROJECTS
-- ============================================================

SET @proj1 = UUID();
SET @proj2 = UUID();
SET @proj3 = UUID();
SET @proj4 = UUID();

INSERT INTO projects (id, user_id, title, summary, ai_summary, hero_image_url, description_html, live_demo_url, href, category, status, is_public, tags, technologies, links, files, repo_url, repo_latest_commit, repo_readme_url, meta_start_date, meta_end_date, meta_course, meta_professor) VALUES
(@proj1, @user1, 'Gradfolio — Student Portfolio System', 'A platform for students to showcase academic projects, skills, and achievements professionally.', 'A full-stack Student Portfolio Management System that bridges academic coursework and industry recruitment, combining LinkedIn''s career timeline with GitHub''s project-centric evidence.', 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97', '<h2>Overview</h2><p>Gradfolio enables students to create rich portfolios with verified credentials, project evidence, and professional presentation.</p><h2>Features</h2><ul><li>Multi-section profile (education, experience, projects, skills)</li><li>GitHub/LinkedIn integration for data import</li><li>AI-generated project summaries</li><li>Search and discovery across portfolios</li></ul>', 'https://gradfolio.vercel.app', NULL, 'course', 'ongoing', 1, '["portfolio", "capstone", "full-stack"]', '["Next.js", "TypeScript", "MUI", "MySQL", "Auth0"]', '[{"label": "Figma Mockups", "url": "https://figma.com/file/gradfolio"}]', '[{"label": "Specification", "url": "/uploads/spec.pdf"}]', 'https://github.com/levonp/gradfolio', '2026-04-01', 'https://github.com/levonp/gradfolio/blob/main/README.md', '2025-09-01', NULL, 'Software Engineering', 'Prof. Harutyunyan'),

(@proj2, @user1, 'Weather Dashboard', 'A real-time weather dashboard with city search and 5-day forecasts.', 'A responsive weather application built with React that displays current conditions and extended forecasts using the OpenWeatherMap API.', 'https://images.unsplash.com/photo-1504608524841-42fe6f032b4b', '<h2>About</h2><p>A clean weather dashboard that lets users search any city and see current weather plus a 5-day forecast with charts.</p>', 'https://weather-dash.vercel.app', NULL, 'personal', 'completed', 1, '["weather", "api", "charts"]', '["React", "Chart.js", "OpenWeatherMap API", "CSS Modules"]', NULL, NULL, 'https://github.com/levonp/weather-dash', '2024-08-20', NULL, '2024-07-01', '2024-08-20', NULL, NULL),

(@proj3, @user2, 'EduConnect Mobile App', 'A mobile app connecting tutors with students for peer-to-peer learning.', 'A React Native mobile application designed to match students with peer tutors based on subject expertise, availability, and learning style preferences.', 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f', '<h2>Problem</h2><p>Students struggle to find qualified peer tutors. Existing platforms are expensive or university-specific.</p><h2>Solution</h2><p>EduConnect uses a matching algorithm to pair students with tutors, featuring in-app messaging and session scheduling.</p>', NULL, NULL, 'academic', 'completed', 1, '["mobile", "education", "matching"]', '["React Native", "Firebase", "Figma"]', NULL, NULL, 'https://github.com/sonahak/educonnect', '2024-05-15', NULL, '2024-01-15', '2024-05-30', 'Mobile App Development', 'Prof. Sargsyan'),

(@proj4, @user3, 'Armenian Wine Quality Predictor', 'ML model predicting wine quality from chemical properties of Armenian wines.', 'A machine learning project analyzing chemical composition data from Armenian wineries to predict wine quality scores using ensemble methods.', 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb', '<h2>Dataset</h2><p>Collected 1,200 samples from 5 Armenian wineries with 11 chemical features.</p><h2>Results</h2><p>Random Forest achieved 89% accuracy. Feature importance analysis revealed alcohol content and volatile acidity as top predictors.</p>', NULL, NULL, 'research', 'completed', 1, '["machine-learning", "wine", "data-science"]', '["Python", "scikit-learn", "Pandas", "Matplotlib"]', '[{"label": "Research Paper", "url": "https://arxiv.org/abs/example"}]', '[{"label": "Dataset", "url": "/uploads/wine_data.csv"}]', 'https://github.com/armeng/wine-predictor', '2024-12-01', NULL, '2024-09-01', '2024-12-15', 'Machine Learning', 'Prof. Davtyan');

-- ============================================================
-- PROJECT ATTACHMENTS
-- ============================================================

INSERT INTO project_attachments (project_id, type, url, title, thumbnail_url, sort_order) VALUES
(@proj1, 'image', 'https://images.unsplash.com/photo-1460925895917-afdab827c52f', 'Dashboard View', NULL, 0),
(@proj1, 'image', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d', 'Profile Page', NULL, 1),
(@proj1, 'video', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Demo Walkthrough', 'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg', 2),
(@proj3, 'image', 'https://images.unsplash.com/photo-1551650975-87deedd944c3', 'App Screens', NULL, 0),
(@proj4, 'pdf', 'https://example.com/uploads/wine_analysis.pdf', 'Full Analysis Report', NULL, 0);

-- ============================================================
-- PROJECT TEAM MEMBERS
-- ============================================================

INSERT INTO project_team_members (project_id, user_id, name, role, avatar_url, status, sort_order) VALUES
(@proj1, @user1, 'Levon Petrosyan', 'Lead Developer', 'https://i.pravatar.cc/150?u=levon', 'accepted', 0),
(@proj1, @user2, 'Sona Hakobyan', 'UI/UX Designer', 'https://i.pravatar.cc/150?u=sona', 'accepted', 1),
(@proj3, @user2, 'Sona Hakobyan', 'Lead Developer & Designer', 'https://i.pravatar.cc/150?u=sona', 'accepted', 0),
(@proj3, @user1, 'Levon Petrosyan', 'Backend Developer', 'https://i.pravatar.cc/150?u=levon', 'accepted', 1),
(@proj3, NULL, 'Aram Manukyan', 'QA Tester', NULL, 'accepted', 2);

-- ============================================================
-- INTEGRATIONS
-- ============================================================

INSERT INTO integrations (user_id, integration_type, status, last_synced_at) VALUES
(@user1, 'github', 'connected', '2026-03-20 14:30:00'),
(@user1, 'linkedin', 'not_connected', NULL),
(@user2, 'github', 'connected', '2026-03-18 10:00:00');

-- ============================================================
-- ACTIVITIES
-- ============================================================

INSERT INTO activities (user_id, type, translation_key, translation_params, timestamp, details) VALUES
(@user1, 'project', 'projectUpdated', '{"projectName": "Gradfolio"}', '2026-04-01 14:30:00', NULL),
(@user1, 'profile', 'newSkill', '{"skillName": "Docker"}', '2026-03-28 09:00:00', NULL),
(@user1, 'project', 'projectUpdated', '{"projectName": "Weather Dashboard"}', '2026-03-25 16:00:00', NULL),
(@user2, 'project', 'projectUpdated', '{"projectName": "EduConnect Mobile App"}', '2026-03-30 11:00:00', NULL),
(@user3, 'profile', 'newSkill', '{"skillName": "TensorFlow"}', '2026-03-22 08:00:00', NULL);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

INSERT INTO notifications (user_id, type, title, message, is_read, reference_id, reference_type, link) VALUES
(@user2, 'team_invite', 'Team invitation', 'Levon Petrosyan added you as UI/UX Designer on "Gradfolio"', 1, @proj1, 'project', '/projects/proj_001'),
(@user1, 'team_accepted', 'Invitation accepted', 'Sona Hakobyan accepted your invitation to "Gradfolio"', 1, @proj1, 'project', '/projects/proj_001'),
(@user1, 'team_invite', 'Team invitation', 'Sona Hakobyan added you as Backend Developer on "EduConnect Mobile App"', 0, @proj3, 'project', '/projects/proj_003');

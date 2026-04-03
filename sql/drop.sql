-- ============================================================
-- Gradfolio — Drop All Tables
-- Drops in reverse FK order to avoid constraint violations.
-- Run this to reset the database without deleting the Docker volume.
-- ============================================================

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS integrations;
DROP TABLE IF EXISTS project_team_members;
DROP TABLE IF EXISTS project_attachments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS user_skills;
DROP TABLE IF EXISTS certifications;
DROP TABLE IF EXISTS experience;
DROP TABLE IF EXISTS education;
DROP TABLE IF EXISTS users;

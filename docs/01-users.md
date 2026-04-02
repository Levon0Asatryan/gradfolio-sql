# Table: `users`

## Purpose

Stores core user accounts and profile data. Every registered user has exactly one row. This is the central table — all other tables reference it via `user_id` foreign keys. Supports the User Registration (Feature 1) and Portfolio Profile Page (Feature 3) features.

## Relationships

- **Parent of**: `education`, `experience`, `certifications`, `user_skills`, `projects`, `integrations`, `activities`, `notifications`
- **Referenced by**: `project_team_members.user_id` (nullable — team members may link to a user account)

## Frontend Type Mapping

- **Primary**: `ProfileData` in `src/data/profile.mock.ts`
- **Secondary**: `DashboardHeaderUser` in `src/components/dashboard/DashboardHeader.tsx` (subset: name, title/headline, bio, avatarUrl)
- **Onboarding form**: `ProfileForm` in `src/utils/constants/constants.ts` (subset: fullName, email, birthday, githubUrl, linkedinUrl, phone, website)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID v4. Used as the route parameter in `/profile/{id}` and as the foreign key target for all child tables. `VARCHAR(36)` because MySQL UUID() returns a 36-character hyphenated string (e.g., `550e8400-e29b-41d4-a716-446655440000`). |
| `auth0_id` | `VARCHAR(255)` | NO | — | The unique user identifier from Auth0 (e.g., `auth0\|abc123` or `google-oauth2\|12345`). Used to match Auth0 session to our user record on login. `VARCHAR(255)` because Auth0 IDs vary in length by provider but are always under 255 chars. Has a UNIQUE constraint — one Auth0 identity per user. |
| `name` | `VARCHAR(255)` | NO | — | User's full display name (e.g., "Levon Petrosyan"). Shown on profile header, search results, dashboard. Pre-filled from OAuth provider during registration. Maps to `ProfileData.name`. |
| `headline` | `VARCHAR(500)` | NO | `''` | Professional headline (e.g., "Computer Science Undergraduate at NPUA — Aspiring Data Scientist"). Shown below name on profile. 500 chars allows a descriptive one-liner. Defaults to empty string so it's never NULL. Maps to `ProfileData.headline`. |
| `location` | `VARCHAR(255)` | YES | `NULL` | Geographic location (e.g., "Yerevan, Armenia"). Optional — not all users want to share location. Displayed on profile header. Maps to `ProfileData.location`. |
| `verified` | `TINYINT(1)` | NO | `0` | Whether the profile has been verified (email confirmed + linked accounts + verified education/certs). `0` = not verified, `1` = verified. Used to show verification badge on profile. Maps to `ProfileData.verified`. |
| `is_public` | `TINYINT(1)` | NO | `1` | Whether the profile appears in search results and the user directory. `1` = public (default — spec says profiles are public by default since the aim is showcasing), `0` = private (only accessible via direct link). Used by search/explore API to filter results. |
| `email` | `VARCHAR(255)` | YES | `NULL` | Contact email address. May differ from the Auth0 login email. Shown on profile for contact purposes. Nullable because user may choose not to display it. Has a non-unique index for lookup. Maps to `ProfileData.email`. |
| `avatar_url` | `TEXT` | NO | `''` | URL to the user's profile photo. Can be an external URL (from OAuth provider) or an uploaded file URL. `TEXT` because URLs can be arbitrarily long. Defaults to empty string — frontend shows a fallback avatar. Maps to `ProfileData.avatarUrl`. |
| `bio` | `TEXT` | YES | `NULL` | Short biographical text. Spec says "optional short bio" at registration. Displayed on dashboard header. `TEXT` because there's no meaningful length constraint — users write a sentence or a paragraph. Maps to `DashboardHeaderUser.bio`. |
| `github` | `VARCHAR(500)` | YES | `NULL` | GitHub profile URL (e.g., `https://github.com/username`). Collected during onboarding or from OAuth. Displayed as social link on profile. 500 chars covers any URL. Maps to `ProfileData.socialLinks.github`. |
| `linkedin` | `VARCHAR(500)` | YES | `NULL` | LinkedIn profile URL. Same rationale as `github`. Maps to `ProfileData.socialLinks.linkedin`. |
| `twitter` | `VARCHAR(500)` | YES | `NULL` | Twitter/X profile URL. Frontend `ProfileData.socialLinks` has a `twitter` field. Same type as other social link columns. |
| `website` | `VARCHAR(500)` | YES | `NULL` | Personal website URL. Collected in onboarding stepper `StepBasicInfo`. Maps to `ProfileForm.website`. Same type as social links. |
| `phone` | `VARCHAR(50)` | YES | `NULL` | Phone number. Collected in onboarding. Spec mentions phone verification (OTP). `VARCHAR(50)` covers international formats with country code, spaces, dashes (max ~20 chars in practice, 50 gives headroom). |
| `birthday` | `DATE` | YES | `NULL` | Date of birth. Collected in onboarding stepper. `DATE` stores year-month-day which is all we need. Not displayed publicly — used for account purposes only. |
| `created_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP` | When the user account was created. Auto-set by MySQL. Used for sorting, analytics. |
| `updated_at` | `DATETIME` | NO | `CURRENT_TIMESTAMP ON UPDATE` | Last time any column in this row was modified. Auto-updated by MySQL. Used for cache invalidation, "last active" indicators. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `uq_users_auth0` | UNIQUE | `auth0_id` | One Auth0 identity per user. Prevents duplicate accounts from the same OAuth login. |
| `idx_users_email` | B-tree | `email` | Fast lookup by email (login flows, contact search) |
| `ft_users_search` | FULLTEXT | `name, headline` | Natural language search on the explore/search page. Enables queries like "machine learning engineer" matching against headline text. |

## Example Data

```json
{
  "id": "u_001",
  "auth0_id": "google-oauth2|117364529384756",
  "name": "Gabe Nuels",
  "headline": "Full-Stack Developer & CS Student at NPUA",
  "location": "Yerevan, Armenia",
  "verified": 1,
  "is_public": 1,
  "email": "gabe.nuels@example.com",
  "avatar_url": "https://i.pravatar.cc/150?u=u_001",
  "bio": "Passionate about building web applications and exploring AI.",
  "github": "https://github.com/gabenuels",
  "linkedin": "https://linkedin.com/in/gabenuels",
  "twitter": null,
  "website": "https://gabenuels.dev",
  "phone": "+374 99 123456",
  "birthday": "2001-05-15",
  "created_at": "2025-01-10 09:00:00",
  "updated_at": "2025-03-20 14:30:00"
}
```

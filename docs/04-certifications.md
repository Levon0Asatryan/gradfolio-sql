# Table: `certifications`

## Purpose

Stores professional certifications and awards for each user (e.g., AWS Certified Cloud Practitioner, Coursera certificates, language proficiency exams). Supports the Portfolio Profile Page (Feature 3), LinkedIn import (Feature 2), and Verification (Feature 5).

## Relationships

- **Parent**: `users` (via `user_id` FK, CASCADE delete)
- **No children**

## Frontend Type Mapping

- `Certification` interface in `src/data/profile.mock.ts`
- Rendered by `CertificationsList.tsx` (read-only) and `EditableCertificationsList.tsx` (edit mode)

## Columns

| Column | Type | Nullable | Default | Description |
| --- | --- | --- | --- | --- |
| `id` | `VARCHAR(36)` | NO | `UUID()` | Primary key. Auto-generated UUID. Maps to `Certification.id`. |
| `user_id` | `VARCHAR(36)` | NO | — | FK to `users.id`. CASCADE on delete. |
| `name` | `VARCHAR(500)` | NO | — | Certificate name (e.g., "AWS Certified Cloud Practitioner", "CCNA"). Maps to `Certification.name`. |
| `issuer` | `VARCHAR(500)` | NO | — | Issuing organization (e.g., "Amazon Web Services", "Cisco", "Coursera"). Maps to `Certification.issuer`. |
| `date` | `VARCHAR(7)` | NO | — | Date obtained in `YYYY-MM` format (e.g., `"2024-03"`). `VARCHAR(7)` to match the frontend format — certifications typically only need month precision. Maps to `Certification.date`. |
| `credential_url` | `TEXT` | YES | `NULL` | URL to verify the credential on the issuer's site (e.g., Coursera certificate link, Credly badge URL). `TEXT` because verification URLs can be long. Used for verification feature — recruiters can click to confirm. Maps to `Certification.credentialUrl?`. |
| `sort_order` | `INT` | NO | `0` | Display order on the profile. |

## Indexes

| Index | Type | Columns | Why |
| --- | --- | --- | --- |
| `PRIMARY` | Primary Key | `id` | Row identity |
| `idx_certifications_user` | B-tree | `user_id` | Fast lookup of all certifications for a user |

## Example Data

```json
{
  "id": "cert_001",
  "user_id": "u_001",
  "name": "AWS Certified Cloud Practitioner",
  "issuer": "Amazon Web Services",
  "date": "2024-03",
  "credential_url": "https://www.credly.com/badges/abc123",
  "sort_order": 0
}
```

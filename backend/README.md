# Achieva Mock Backend

Mock API server for the Achieva mobile examination platform.

## Quick Start

```bash
npm install
node server.js
```

Server starts on **http://localhost:3000**.

## Test Credentials

| Field    | Value              |
|----------|--------------------|
| Email    | test@achieva.ng    |
| Password | test1234           |

Any email with password `test1234` will succeed.

## Endpoints

### Authentication
- **POST /api/auth/login** — `{ email, password }` → JWT token

### Identity Verification
- **POST /api/nin/verify** — `{ nin, dob }` (Bearer token required)
  - Any valid 11-digit NIN succeeds
  - NIN `00000000000` returns error for testing
- **POST /api/face/verify** — `{ image_base64, nin }` (Bearer token required)
  - Always returns match: true

### Exam
- **GET /api/exam/info** — Returns exam title, duration, question count
- **GET /api/exam/questions** — Returns 40 questions (no answers)
- **POST /api/exam/submit** — `{ answers, duration_taken_seconds }`

### Proctoring
- **POST /api/proctor/snapshot** — `{ image_base64, event_type }`
- **POST /api/proctor/event** — `{ type, timestamp }`

### Health
- **GET /health** — `{ status: "ok" }`

## Mock Data

- `data/mock_candidates.json` — Test user accounts
- `data/mock_questions.json` — 40 questions across 4 subjects

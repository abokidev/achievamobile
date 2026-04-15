# Achieva Mobile

**Your Excellence, Verified.**

Achieva is a secure mobile examination platform built with Flutter, featuring identity verification (NIN + facial recognition), proctored exam delivery, and a companion mock backend.

## Features

- Secure login with JWT authentication
- NIN (National Identity Number) verification
- Facial verification with liveness detection (blink detection)
- Timed exam delivery with 40 multiple-choice questions
- Real-time proctoring (periodic snapshots, app lifecycle monitoring)
- Screenshot prevention (FLAG_SECURE)
- Copy/paste disabled during exams
- Question flagging and navigation grid

## Project Structure

```
achievamobile/
├── lib/                          # Flutter application
│   ├── main.dart                 # App entry point
│   ├── core/                     # Theme, constants, services
│   ├── features/                 # Auth, onboarding, exam screens
│   └── shared/                   # Reusable widgets
├── backend/                      # Node.js mock backend
│   ├── server.js                 # Express server
│   ├── routes/                   # API route handlers
│   ├── middleware/                # JWT auth middleware
│   └── data/                     # Mock candidates & questions
└── .github/workflows/            # CI/CD pipelines
```

## Getting Started

### Prerequisites

- Flutter SDK 3.22.0+
- Node.js 18+
- Android Studio / Android SDK

### Run the Backend

```bash
cd backend
npm install
node server.js
```

The server starts on `http://localhost:3000`.

### Run the Flutter App

```bash
flutter pub get
flutter run
```

The app is configured to connect to `http://10.0.2.2:3000` (Android emulator localhost). To change this, edit `lib/core/constants/strings.dart`.

### Test Credentials

| Field    | Value              |
|----------|--------------------|
| Email    | test@achieva.ng    |
| Password | test1234           |

### NIN Verification (Mock)

- Any 11-digit NIN works (e.g., `12345678901`)
- Any date of birth works
- NIN `00000000000` returns an error (for testing)

## Build APK

```bash
flutter build apk --release --no-tree-shake-icons
```

The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

## APK Download

Release APKs are automatically built and attached to [GitHub Releases](../../releases) via CI/CD on every push to `main`.

## Tech Stack

### Mobile (Flutter)
- Provider for state management
- HTTP for API calls
- Flutter Secure Storage for token storage
- Camera + Google ML Kit for face detection
- Google Fonts (Cinzel + DM Sans)

### Backend (Node.js)
- Express
- JWT authentication
- CORS enabled
- Mock data for all endpoints

## Color System

| Token          | Hex       |
|----------------|-----------|
| Primary        | `#002060` |
| Primary Light  | `#003087` |
| Accent         | `#F7941D` |
| Background     | `#001240` |
| Surface        | `#0A2A6E` |
| Text Primary   | `#FFFFFF` |
| Text Secondary | `#B0C4E8` |

## API Endpoints

| Method | Endpoint              | Description              |
|--------|-----------------------|--------------------------|
| POST   | /api/auth/login       | Authenticate user        |
| POST   | /api/nin/verify       | Verify NIN identity      |
| POST   | /api/face/verify      | Verify face match        |
| GET    | /api/exam/info        | Get exam metadata        |
| GET    | /api/exam/questions   | Get exam questions       |
| POST   | /api/exam/submit      | Submit exam answers      |
| POST   | /api/proctor/snapshot | Upload proctor snapshot  |
| POST   | /api/proctor/event    | Log proctoring event     |
| GET    | /health               | Health check             |

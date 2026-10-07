# Sustainn — Farm Management & Advisory Platform

Sustainn is a farm management and advisory platform for smallholder farmers. This
repository is a monorepo containing the three pieces of the system:

| Component | Path | Stack | Purpose |
|---|---|---|---|
| **Farmer App** | [`/`](.) | Flutter (Android, iOS, Web, Desktop) | Farmer-facing app for field/crop/activity tracking |
| **Backend API** | [`sustainn_backend/`](sustainn_backend) | Node.js, Express, MongoDB (Mongoose) | REST API + database for the farmer app and admin dashboard |
| **Admin Dashboard** | [`sustainn_admin_dashboard/`](sustainn_admin_dashboard) | Next.js, TypeScript, Tailwind CSS | Internal dashboard to view farmers, fields, crops, and stats |

---

## Architecture

```
┌─────────────────────┐        ┌──────────────────────┐
│   Farmer App         │        │  Admin Dashboard      │
│   (Flutter)          │        │  (Next.js, Vercel)    │
│   Android / Web       │        │  Login-protected       │
└──────────┬────────────┘        └──────────┬────────────┘
           │ REST (JSON)                     │ REST (x-admin-key)
           └────────────────┬────────────────┘
                             ▼
                  ┌───────────────────────┐
                  │   Backend API          │
                  │   (Express, Render)    │
                  └──────────┬──────────────┘
                             ▼
                  ┌───────────────────────┐
                  │   MongoDB Atlas        │
                  └───────────────────────┘
```

- The **Farmer App** and **Admin Dashboard** are independent clients of the same **Backend API**.
- The Backend API is the single source of truth for all data (users, fields, crops, activities, financials, action points) and is backed by MongoDB Atlas.
- Admin-only routes (`/api/admin/*`) are protected by a static API key (`ADMIN_API_KEY`); farmer-facing routes use a simple token issued at login.

---

## Live Deployments

| Component | URL |
|---|---|
| Backend API | `https://sustainn-v1-1.onrender.com` |
| Admin Dashboard | Deployed on Vercel (ask a maintainer for the link) |
| Farmer App (Web) | `https://razer255.github.io/sustainn_v1.1/` |
| Farmer App (Android) | Built automatically via GitHub Actions — see [Releases](../../releases) |

---

## Repository Structure

```
.
├── lib/                        # Flutter app source
│   ├── models/                 # Data models (User, Field, Crop, Activity, ...)
│   ├── screens/                # UI screens (auth, dashboard, crop, field, ...)
│   ├── services/                # API client, auth, mock data, weather
│   ├── routes/                 # App navigation/router
│   ├── theme/                   # Colors, typography
│   └── utils/                   # Geo utilities, helpers
├── android/ ios/ web/ ...      # Flutter platform targets
├── assets/translations/        # i18n strings (en, hi)
│
├── sustainn_backend/            # Express REST API
│   ├── server.js                # All models, routes, and the DB seeder
│   └── data/                    # Bundled static datasets (e.g. states/districts)
│
├── sustainn_admin_dashboard/    # Next.js admin dashboard
│   └── src/
│       ├── app/                 # Routes: /login, /, /users, /fields, /crops
│       ├── components/           # Shared UI (Sidebar, etc.)
│       └── lib/                  # Session/auth and backend API client
│
└── .github/workflows/build.yml  # CI: builds Android APK + deploys Web to GitHub Pages
```

---

## Prerequisites

| Tool | Used for | Version |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Farmer App | Stable channel, 3.44+ |
| [Node.js](https://nodejs.org/) | Backend + Admin Dashboard | 18+ |
| [MongoDB Atlas](https://www.mongodb.com/atlas) account | Backend database | — |
| Android SDK (via Android Studio) | Building the Android APK locally | — *(not required — CI builds it for you)* |

---

## Getting Started

### 1. Backend API (`sustainn_backend/`)

```bash
cd sustainn_backend
npm install
cp .env.example .env   # fill in the values below
npm run dev             # nodemon, auto-restarts on change
```

**Environment variables** (`sustainn_backend/.env`):

| Variable | Description |
|---|---|
| `PORT` | Port to listen on (default `3000`) |
| `MONGO_URI` | MongoDB Atlas connection string |
| `LGD_API_KEY` | *(legacy, no longer required)* — States/Districts are now served from a bundled static dataset instead of the data.gov.in LGD API |
| `ADMIN_API_KEY` | Shared secret the Admin Dashboard sends as `x-admin-key` to access `/api/admin/*` routes |

On first run against an empty database, the server automatically seeds baseline mock data (one farmer, three fields, four crops, sample activities, action points, and financials).

### 2. Admin Dashboard (`sustainn_admin_dashboard/`)

```bash
cd sustainn_admin_dashboard
npm install
cp .env.example .env.local   # fill in the values below
npm run dev                   # http://localhost:3001 (or next available port)
```

**Environment variables** (`sustainn_admin_dashboard/.env.local`):

| Variable | Description |
|---|---|
| `ADMIN_PASSWORD` | Password required to log into the dashboard |
| `SESSION_SECRET` | Random string used to sign the login session cookie |
| `BACKEND_URL` | URL of the running Backend API (e.g. `http://localhost:3000` locally, or the Render URL in production) |
| `ADMIN_API_KEY` | Must match the Backend's `ADMIN_API_KEY` exactly |

### 3. Farmer App (Flutter)

```bash
flutter pub get
flutter run                    # run on a connected device/emulator
flutter run -d chrome          # run in the browser
```

The app's backend URL is set in [`lib/services/api_service.dart`](lib/services/api_service.dart) (`_baseUrl`). Point it at your local backend (`http://localhost:3000/api`) for local development, or leave it pointed at the deployed backend to work against live data.

---

## Building for Release

### Android APK / Flutter Web (via CI — recommended)

Pushing to `main` automatically triggers [`.github/workflows/build.yml`](.github/workflows/build.yml), which:

1. Builds a release **APK** and attaches it to a new **GitHub Release**.
2. Builds the **Flutter Web** app and deploys it to **GitHub Pages**.

This avoids needing a local Android SDK install. Find builds under the [Actions](../../actions) and [Releases](../../releases) tabs.

### Building locally

```bash
flutter build apk --release     # requires Android SDK
flutter build web --release
```

---

## Deployment

| Component | Platform | Notes |
|---|---|---|
| Backend API | [Render](https://render.com) | Web Service, root directory `sustainn_backend`, build `npm install`, start `npm start`. Auto-deploys on push to `main`. Free tier sleeps after inactivity — first request after idle may take 30–50s. |
| Admin Dashboard | [Vercel](https://vercel.com) | Root directory `sustainn_admin_dashboard`. Auto-deploys on push to `main`. |
| Farmer App (Web) | GitHub Pages | Deployed by CI on every push to `main`. |
| Farmer App (Android) | GitHub Releases | Built by CI on every push to `main`; download the APK and install directly (enable "install from unknown sources"). |

---

## API Overview

Full route definitions live in [`sustainn_backend/server.js`](sustainn_backend/server.js).

| Area | Routes |
|---|---|
| Auth | `POST /api/auth/login` |
| Users | `POST /api/users`, `GET /api/users/:userId` |
| Fields | `GET/POST /api/fields` |
| Crops | `GET/POST /api/crops` |
| Activities | `GET/POST /api/activities` |
| Financials | `GET/PUT /api/financials/:cropId` |
| Action Points | `GET /api/action-points`, `PUT /api/action-points/:apId/resolve` |
| Location | `GET /api/location/states`, `GET /api/location/districts?stateCode=` |
| Admin *(requires `x-admin-key`)* | `GET /api/admin/stats`, `/api/admin/users`, `/api/admin/fields`, `/api/admin/crops` |

---

## Notes & Known Limitations

- **Location data**: State and District selection is served from a bundled static dataset (`sustainn_backend/data/states-districts.json`) rather than a live government API, since the previous data source (data.gov.in's LGD API) proved unreliable. Tehsil and Village are free-text fields on signup, since no comparably reliable open dataset exists at that granularity.
- **Auth**: The current login flow uses a simple token issued by the backend, suitable for the current stage of the project. Hardening this (real JWTs, password hashing, per-resource authorization) is a recommended next step before wider rollout.

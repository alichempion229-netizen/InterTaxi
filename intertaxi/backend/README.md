# Backend Earnings Setup

## Firebase Authentication

The Flutter app keeps its registration flow and creates a persistent anonymous
Firebase Auth session. Enable the **Anonymous** sign-in provider for Firebase
project `intertaxi-5b711`.

Configure the Flask service with:

- `FIREBASE_PROJECT_ID=intertaxi-5b711`
- `FIREBASE_SERVICE_ACCOUNT_JSON` containing the Firebase Admin service-account
  JSON, or use the platform's Application Default Credentials.

Store the service-account value as a backend secret. Never add it to Flutter,
the repository, or `google-services.json`. Without Admin credentials, protected
endpoints reject requests.

## Earnings Flow

- `POST /api/trips` records `owner_uid` from a verified bearer token when one is
  provided.
- `POST /api/trips/<trip_id>/start` records the authenticated start time.
- `POST /api/trips/<trip_id>/complete` and the authenticated Socket.IO
  completion event save the earning atomically and idempotently.
- `GET /api/earnings?period=day|week|month|year|all` returns the authenticated
  user's total and completed-trip history. The legacy
  `/api/drivers/<driver_id>/earnings` URL remains as an alias; its path ID does
  not determine access.
- Booking decisions require the same authenticated trip owner, because only
  approved seats contribute to the fare.

The saved amount is the existing per-seat trip price multiplied by the number
of approved seats at completion. A trip with no approved seats records a zero
amount, not generated income. Earnings are immutable completion snapshots and
are unique by `trip_id`.

On startup, SQLAlchemy creates the `earnings` table and adds `owner_uid` and
`started_at` to `trips` when they are missing. Existing trips have no verified
owner association; republish open trips after upgrading before starting them.
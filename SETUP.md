# FleetOS — Complete Setup Guide

## 🚀 Quick Start (5 minutes)

### 1. Enable Firebase Authentication

**This is the ONLY step needed to make login/signup work:**

1. Open: **https://console.firebase.google.com/project/hackindia-2dd25/authentication/providers**
2. Click **"Email/Password"**
3. Toggle **Enable** → Click **Save**

That's it. The Flutter app will now work.

---

### 2. Run the Flutter App

```bash
cd fleet_manager
flutter run -d chrome
```

**Test it:**
- Click "Get Started" → "Create Account"
- Fill in name, email, password → Click "Create Account"
- You'll be logged in and see the dashboard

---

### 3. (Optional) Connect the Backend

The backend needs a **service account private key** (different from the client keys).

**Get it:**
1. Go to: **https://console.firebase.google.com/project/hackindia-2dd25/settings/serviceaccounts/adminsdk**
2. Click **"Generate new private key"** → Download JSON
3. Save as: `fleet-backend/serviceAccountKey.json`
4. Start backend:
   ```bash
   cd fleet-backend
   npm run dev
   ```

The backend auto-detects `serviceAccountKey.json` — no `.env` changes needed.

---

## 🔍 Troubleshooting

### "Infinite loading on login/signup"

**Cause:** Email/Password provider not enabled in Firebase Console.

**Fix:** Follow step 1 above.

---

### "operation-not-allowed" error

Same as above — enable Email/Password in Authentication → Sign-in method.

---

### Backend: "Invalid PEM formatted message"

**Cause:** `.env` has placeholder credentials.

**Fix:** Either:
- Drop `serviceAccountKey.json` in `fleet-backend/` (auto-detected)
- OR paste real values into `.env` from the downloaded JSON:
  ```
  FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@hackindia-2dd25.iam.gserviceaccount.com
  FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQ...\n-----END PRIVATE KEY-----\n"
  ```

---

## 📦 What's Already Done

### Flutter App
- ✅ Firebase initialized with your project keys
- ✅ Auth service wired (sign-in, sign-up, password reset)
- ✅ Error handling with friendly messages
- ✅ Profile saved to Firestore `users/` collection
- ✅ Light/dark theme toggle everywhere
- ✅ Add/edit trucks and drivers
- ✅ Profile screen with logout

### Backend
- ✅ Express + Firebase Admin SDK
- ✅ JWT auth middleware
- ✅ IoT data ingestion endpoint
- ✅ WebSocket for real-time updates
- ✅ MQTT support (optional)
- ✅ Graceful startup even without credentials

---

## 🎯 Current State

**Flutter app:** Fully functional — just needs Email/Password enabled in Firebase Console (step 1).

**Backend:** Starts fine without credentials (serves 503 for DB routes). Add `serviceAccountKey.json` to connect.

---

## 📝 API Endpoints (Backend)

Once backend is connected:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check + Firebase status |
| `/api/auth/register` | POST | Create account |
| `/api/auth/login` | POST | Login (returns JWT) |
| `/api/trucks` | GET/POST | List/add trucks |
| `/api/drivers` | GET/POST | List/add drivers |
| `/api/iot/data` | POST | Ingest sensor data (device auth) |
| `/api/fleet/summary` | GET | Dashboard stats |
| `/api/fleet/earnings` | GET | Earnings analytics |

WebSocket: `ws://localhost:3000/ws` for real-time sensor updates.

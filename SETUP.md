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
- ✅ ML recommendations screen

### Backend
- ✅ Express + Firebase Admin SDK
- ✅ JWT auth middleware
- ✅ IoT data ingestion endpoint
- ✅ WebSocket for real-time updates
- ✅ MQTT support (optional)
- ✅ Graceful startup even without credentials
- ✅ ML integration endpoints
- ✅ Driver/truck metrics tracking

### ML Models
- ✅ Driver performance prediction
- ✅ Truck performance prediction
- ✅ Recommendation system
- ✅ Model retraining endpoints
- ✅ REST API for predictions

---

## 🤖 ML Integration (Optional)

The system includes machine learning models for driver and truck performance prediction.

### Quick Start

```bash
cd fleet-backend/ml
./setup_ml.sh
```

This will:
1. Create Python virtual environment
2. Install ML dependencies
3. Optionally train initial models

### Start ML API

```bash
cd fleet-backend/ml
source venv/bin/activate
python3 api.py
```

The ML API runs on `http://localhost:5001`

### What ML Does

- **Driver Scoring**: Predicts performance based on safety, fuel efficiency, on-time delivery, alerts, experience, trips
- **Truck Scoring**: Predicts performance based on maintenance, fuel efficiency, breakdowns, age, trips, capacity
- **Recommendations**: Ranks top drivers and trucks for optimal assignment

### Update Metrics

Metrics are automatically initialized with defaults when creating drivers/trucks. Update via API:

```bash
# Update driver metrics
PATCH /api/drivers/:driverId/metrics
{
  "safety_score": 95,
  "fuel_efficiency": 6.5,
  "trips_completed": 200
}

# Update truck metrics
PATCH /api/trucks/:truckId/metrics
{
  "maintenance_score": 98,
  "total_trips": 300
}
```

See `fleet-backend/ml/README.md` for detailed ML documentation.

---

## 🎯 Current State

**Flutter app:** Fully functional — just needs Email/Password enabled in Firebase Console (step 1).

**Backend:** Starts fine without credentials (serves 503 for DB routes). Add `serviceAccountKey.json` to connect.

**ML Integration:** Optional but recommended. Provides driver/truck performance predictions and recommendations.

---

## 🚀 Quick Start Guide

### 1. Enable Firebase Authentication (Required)
- Open: https://console.firebase.google.com/project/hackindia-2dd25/authentication/providers
- Enable "Email/Password" provider
- Save

### 2. Start Flutter App
```bash
cd fleet_manager
flutter run -d chrome
```

### 3. Start Backend (Optional but recommended)
```bash
# Option A: Quick start (auto-installs dependencies)
./start_backend.sh

# Option B: Manual start
cd fleet-backend
npm install
npm run dev
```

### 4. Setup ML (Optional)
```bash
cd fleet-backend/ml
./setup_ml.sh
```

This will:
- Create Python virtual environment
- Install ML dependencies (scikit-learn, pandas, flask, etc.)
- Optionally train initial models

To start ML API separately:
```bash
cd fleet-backend/ml
source venv/bin/activate
python3 api.py
```

---

## 📝 API Endpoints (Backend)

Once backend is connected:

### Authentication
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check + Firebase status |
| `/api/auth/register` | POST | Create account |
| `/api/auth/login` | POST | Login (returns JWT) |

### Trucks
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/trucks` | GET/POST | List/add trucks |
| `/api/trucks/:id` | GET | Get truck details |
| `/api/trucks/:id/status` | PATCH | Update truck status |
| `/api/trucks/:id/metrics` | PATCH | Update ML metrics |
| `/api/trucks/:id` | DELETE | Delete truck |

### Drivers
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/drivers` | GET/POST | List/add drivers |
| `/api/drivers/:id` | GET | Get driver details |
| `/api/drivers/:id/metrics` | PATCH | Update ML metrics |
| `/api/drivers/:id/assign` | POST | Assign to truck |
| `/api/drivers/:id/unassign` | POST | Unassign from truck |
| `/api/drivers/:id` | DELETE | Delete driver |
| `/api/drivers/me` | GET | Driver's own profile |

### IoT & Sensors
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/iot/data` | POST | Ingest sensor data (device auth) |
| `/api/iot/trucks/:id/latest` | GET | Latest sensor reading |
| `/api/iot/trucks/:id/history` | GET | Sensor history |

### Fleet Management
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/fleet/summary` | GET | Dashboard stats |
| `/api/fleet/active-trucks` | GET | Active trucks with sensors |
| `/api/fleet/earnings` | GET | Earnings analytics |

### ML Predictions (requires ML API running)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/ml/predict/driver` | POST | Predict driver score |
| `/api/ml/predict/truck` | POST | Predict truck score |
| `/api/ml/recommendations/drivers` | GET | Top recommended drivers |
| `/api/ml/recommendations/trucks` | GET | Top recommended trucks |
| `/api/ml/train/driver` | POST | Retrain driver model |
| `/api/ml/train/truck` | POST | Retrain truck model |

WebSocket: `ws://localhost:3000/ws` for real-time sensor updates.

---

## 🤖 ML Features

### Driver Metrics
- `safety_score` (0-100): Safety rating
- `fuel_efficiency` (km/l): Fuel consumption
- `on_time_delivery_rate` (0-100): On-time percentage
- `alert_count`: Number of alerts
- `experience_years`: Years of experience
- `trips_completed`: Total trips

### Truck Metrics
- `maintenance_score` (0-100): Maintenance quality
- `fuel_efficiency` (km/l): Fuel consumption
- `breakdown_count`: Number of breakdowns
- `age_years`: Vehicle age
- `total_trips`: Total trips
- `avg_load_capacity_used` (0-100): Capacity utilization

### Update Metrics Example
```bash
# Update driver metrics
curl -X PATCH http://localhost:3000/api/drivers/:driverId/metrics \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "safety_score": 95,
    "fuel_efficiency": 6.5,
    "trips_completed": 200
  }'

# Update truck metrics
curl -X PATCH http://localhost:3000/api/trucks/:truckId/metrics \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "maintenance_score": 98,
    "total_trips": 300
  }'
```

---
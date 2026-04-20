# FleetOS Backend API

IoT-based Truck Fleet Management — Node.js + Firebase Firestore

## Architecture

```
IoT Devices → MQTT / HTTP → Node.js Server → Firestore → Flutter App
                                    ↓
                              WebSocket (live updates)
```

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Copy env and fill in your Firebase service account credentials
cp .env.example .env

# 3. Add your Firebase service account private key to .env

# 4. Start dev server
npm run dev
```

## Firebase Setup

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key" → download JSON
3. Copy `client_email` and `private_key` into `.env`

## API Reference

### Auth
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | — | Register new owner |
| POST | `/api/auth/login` | — | Login, returns JWT |
| GET | `/api/auth/profile` | JWT | Get own profile |

### Trucks
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/trucks` | JWT | Add truck |
| GET | `/api/trucks` | JWT | List all trucks |
| GET | `/api/trucks/:id` | JWT | Get single truck |
| PATCH | `/api/trucks/:id/status` | JWT | Update status |
| DELETE | `/api/trucks/:id` | JWT | Delete truck |

### Drivers
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/drivers` | JWT | Add driver |
| GET | `/api/drivers` | JWT | List drivers |
| GET | `/api/drivers/:id` | JWT | Get driver |
| POST | `/api/drivers/:id/assign` | JWT | Assign to truck |
| POST | `/api/drivers/:id/unassign` | JWT | Unassign |

### IoT Data
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/iot/data` | Device Secret | Ingest sensor data |
| GET | `/api/iot/trucks/:id/latest` | JWT | Latest reading |
| GET | `/api/iot/trucks/:id/history` | JWT | Sensor history |

### Fleet Aggregation
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/fleet/summary` | JWT | Dashboard summary |
| GET | `/api/fleet/active-trucks` | JWT | Active trucks + sensor |
| GET | `/api/fleet/earnings?period=monthly` | JWT | Earnings analytics |
| POST | `/api/fleet/earnings` | JWT | Record earning |

## IoT Device Integration

Devices send data via HTTP POST to `/api/iot/data` with header:
```
X-Device-Secret: <IOT_DEVICE_SECRET from .env>
```

Payload:
```json
{
  "truckId": "MH12AB1234",
  "location": { "lat": 19.076, "lng": 72.877 },
  "temperature": 28.5,
  "fuelLevel": 72.3,
  "loadStatus": "loaded",
  "doorStatus": "closed",
  "speed": 65.2,
  "engineOn": true,
  "timestamp": "2026-04-20T10:30:00Z"
}
```

## MQTT (Optional)

Set `MQTT_BROKER_URL` in `.env`. Devices publish to:
```
fleet/trucks/<truckId>/data
```

## WebSocket

Connect to `ws://localhost:3000/ws` for real-time sensor updates:
```json
{ "event": "sensor_update", "truckId": "...", "plate": "MH12AB1234", "data": { ... } }
```

## Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | Fleet owners |
| `trucks` | Truck registry |
| `drivers` | Driver profiles |
| `sensorData` | IoT readings (time-series) |
| `earnings` | Revenue records |

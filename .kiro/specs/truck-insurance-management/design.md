# Design Document — Truck Insurance Management

## Overview

This feature adds a fully integrated insurance management system to the Fleet Management app. The current insurance screen displays hardcoded data with no backend persistence. This design replaces that with a real data flow backed by Firestore, introduces a real-time notification system for expiring and missing insurance, and enhances the driver and truck creation forms with optional at-creation assignment.

The implementation spans two layers:

- **Backend (Node.js/Express + Firestore):** New `insuranceService`, `insuranceController`, `notificationService`, `notificationController`, and their routes. Enhancements to `truckService` and `driverService` for cascade-delete, idle/available filtering, and atomic assignment.
- **Frontend (Flutter):** Full rewrite of `InsuranceScreen`, new `NotificationsScreen`, enhancements to `DriversScreen` and `TrucksScreen` form sheets, new API methods in `ApiService`, new models in `models.dart`, and a notification badge on `DashboardScreen`.

### Key Design Decisions

1. **Status is always server-computed.** The backend derives `status` and `daysUntilExpiry` from the server clock on every create/update. The frontend never performs date arithmetic.
2. **Notifications are never persisted.** `GET /api/notifications` computes results in real-time from live Truck and Insurance records on every request. This avoids a separate notification collection and stale-data problems.
3. **Atomic assignment via Firestore batch writes.** Driver–truck pairing at creation time uses a single batch write with a pre-commit freshness check to guard against race conditions.
4. **Pending entries are a frontend diff.** The Insurance Screen fetches both trucks and insurance records, then computes the "Pending" set client-side as the difference. This avoids a dedicated backend endpoint for pending status.
5. **Cascade delete is handled in `truckService`.** When a truck is deleted, the service queries and deletes any associated insurance record in the same operation, keeping the insurance collection consistent.

---

## Architecture

```mermaid
graph TD
    subgraph Flutter App
        DS[DashboardScreen]
        IS[InsuranceScreen]
        NS[NotificationsScreen]
        DRS[DriversScreen]
        TS[TrucksScreen]
        API[ApiService]
    end

    subgraph Express Backend
        IR[/api/insurance]
        NR[/api/notifications]
        TR[/api/trucks]
        DR[/api/drivers]
        IC[InsuranceController]
        NC[NotificationController]
        TC[TruckController]
        DC[DriverController]
        IS_SVC[InsuranceService]
        NS_SVC[NotificationService]
        TS_SVC[TruckService]
        DS_SVC[DriverService]
    end

    subgraph Firestore
        TRUCKS[(trucks)]
        DRIVERS[(drivers)]
        INSURANCE[(insurance)]
    end

    DS --> API
    IS --> API
    NS --> API
    DRS --> API
    TS --> API

    API --> IR
    API --> NR
    API --> TR
    API --> DR

    IR --> IC --> IS_SVC
    NR --> NC --> NS_SVC
    TR --> TC --> TS_SVC
    DR --> DC --> DS_SVC

    IS_SVC --> INSURANCE
    IS_SVC --> TRUCKS
    NS_SVC --> TRUCKS
    NS_SVC --> INSURANCE
    TS_SVC --> TRUCKS
    TS_SVC --> DRIVERS
    TS_SVC --> INSURANCE
    DS_SVC --> DRIVERS
    DS_SVC --> TRUCKS
```

All routes are protected by the existing `authenticate` middleware. The `ownerId` is always derived from `req.user.uid` — never from the request body.

---

## Components and Interfaces

### Backend Components

#### `insuranceService.js`

```
createInsurance({ ownerId, truckId, policyNumber, provider, startDate, expiryDate })
  → InsuranceRecord

getInsuranceRecords(ownerId)
  → InsuranceRecord[]

getInsuranceById(insuranceId, ownerId)
  → InsuranceRecord

updateInsurance(insuranceId, ownerId, { policyNumber, provider, startDate, expiryDate })
  → InsuranceRecord

deleteInsurance(insuranceId, ownerId)
  → void

computeStatus(startDate, expiryDate, serverDate)
  → { status: 'Valid' | 'Expiring Soon' | 'Expired', daysUntilExpiry: number }
```

`computeStatus` is a pure function exported separately to facilitate unit testing.

#### `insuranceController.js`

Thin controller delegating to `insuranceService`. Handles HTTP request/response mapping using the existing `success`, `created`, `notFound`, `forbidden`, `badRequest` helpers from `utils/response.js`.

#### `routes/insurance.js`

```
POST   /api/insurance
GET    /api/insurance
GET    /api/insurance/:insuranceId
PATCH  /api/insurance/:insuranceId
DELETE /api/insurance/:insuranceId
```

All routes use `authenticate` middleware. Validation uses `express-validator` following the same pattern as `routes/trucks.js`.

#### `notificationService.js`

```
getNotifications(ownerId)
  → { notifications: NotificationRecord[], count: number }

buildExpiringNotification(insurance, serverDate)
  → NotificationRecord | null

buildExpiredNotification(insurance, serverDate)
  → NotificationRecord | null

buildPendingNotification(truck)
  → NotificationRecord
```

`getNotifications` fetches all trucks and insurance records for the owner in parallel, then computes the notification list in memory. No Firestore writes occur.

#### `notificationController.js`

Single handler for `GET /api/notifications`.

#### `routes/notifications.js`

```
GET /api/notifications
```

Protected by `authenticate`.

#### `truckService.js` — Enhancements

- `getTrucks(ownerId, filters)` — accepts optional `{ status: 'idle' }` filter. When `status=idle`, returns only trucks where `status === 'idle'` AND `assignedDriverId === null`. Filtering is done in-memory after the Firestore query (avoids composite index requirement).
- `deleteTruck(truckId, ownerId)` — after deleting the truck document, queries the `insurance` collection for a record with `truckId` matching and deletes it if found.
- `addTruck({ ownerId, plate, model, type, year, driverId? })` — if `driverId` is provided, performs a Firestore batch write: creates the truck doc, updates the driver's `assignedTruckId` and `status`, and updates the truck's `assignedDriverId`. Verifies driver is still available before committing (returns 409 if not).

#### `driverService.js` — Enhancements

- `getDrivers(ownerId, filters)` — accepts optional `{ status: 'available' }` filter. When `status=available`, returns only drivers where `status === 'available'` AND `assignedTruckId === null`. Filtering is done in-memory.
- `addDriver({ ..., truckId? })` — if `truckId` is provided, performs a Firestore batch write: creates the driver doc, creates the users doc, updates the truck's `assignedDriverId`, and updates the driver's `assignedTruckId`. Verifies truck is still idle before committing (returns 409 if not).

#### `app.js` — Route Registration

```js
const insuranceRoutes    = require('./routes/insurance');
const notificationRoutes = require('./routes/notifications');

app.use('/api/insurance',     insuranceRoutes);
app.use('/api/notifications', notificationRoutes);
```

### Frontend Components

#### `models/models.dart` — New Models

```dart
class InsuranceModel {
  final String insuranceId;
  final String truckId;
  final String truckPlate;   // joined from truck record
  final String policyNumber;
  final String provider;
  final String startDate;
  final String expiryDate;
  final String status;       // 'Valid' | 'Expiring Soon' | 'Expired' | 'Pending'
  final int daysUntilExpiry;
  // factory InsuranceModel.fromJson(Map<String, dynamic> j)
}

class NotificationModel {
  final String type;          // 'expiring_soon' | 'expired' | 'pending_insurance'
  final String truckId;
  final String truckPlate;
  final int? daysUntilExpiry; // null for pending_insurance
  final String message;
  // factory NotificationModel.fromJson(Map<String, dynamic> j)
}
```

The existing `InsuranceModel` is replaced with the richer version above. The `AppStore` gains a `notifications` list and `notificationCount` integer.

#### `services/api_service.dart` — New Methods

```dart
static Future<List<Map<String, dynamic>>> getInsuranceRecords()
static Future<Map<String, dynamic>> addInsuranceRecord(Map<String, dynamic> body)
static Future<Map<String, dynamic>> updateInsuranceRecord(String insuranceId, Map<String, dynamic> body)
static Future<void> deleteInsuranceRecord(String insuranceId)
static Future<Map<String, dynamic>> getNotifications()
static Future<List<Map<String, dynamic>>> getIdleTrucks()      // GET /api/trucks?status=idle
static Future<List<Map<String, dynamic>>> getAvailableDrivers() // GET /api/drivers?status=available
```

`getTrucks()` and `getDrivers()` are updated to accept an optional `status` query parameter.

#### `screens/insurance_screen.dart` — Full Rewrite

- On load: calls `ApiService.getInsuranceRecords()` and `ApiService.getTrucks()` in parallel. Computes pending entries as trucks with no matching `truckId` in the insurance list.
- Insurance form: date pickers for start/expiry dates, text fields for policy number and provider. Validates all required fields and start < expiry before submitting.
- Delete: confirmation dialog → `ApiService.deleteInsuranceRecord(id)` → refresh list.
- No `DemoData` fallback. On error: shows error message + retry button.
- Status colours: green=Valid, amber=Expiring Soon, red=Expired, blue=Pending.

#### `screens/notifications_screen.dart` — New File

- On load: calls `ApiService.getNotifications()`.
- Renders three card types: amber for `expiring_soon`, red for `expired`, blue for `pending_insurance`.
- Pull-to-refresh, empty state ("No active alerts"), error + retry.

#### `screens/drivers_screen.dart` — `_DriverFormSheet` Enhancement

- In add mode: on `initState`, calls `ApiService.getIdleTrucks()`. Stores result in local state. Shows "Assign Truck (optional)" dropdown populated with idle trucks.
- If fetch fails: dropdown is disabled with label "Could not load trucks".
- On submit: includes `truckId` in body if a truck is selected.
- In edit mode: no dropdown rendered.

#### `screens/trucks_screen.dart` — `_TruckFormSheet` Enhancement

- In add mode: on `initState`, calls `ApiService.getAvailableDrivers()`. Shows "Assign Driver (optional)" dropdown.
- If fetch fails: dropdown is disabled with label "Could not load drivers".
- On submit: includes `driverId` in body if a driver is selected.
- In edit mode: no dropdown rendered.

#### `screens/dashboard_screen.dart` — Notification Badge

- `_loadSummary()` also calls `ApiService.getNotifications()` and stores the count.
- `_NotificationBell` widget updated: shows a red badge with the numeric count when count > 0; no badge when count is 0.
- On return from `NotificationsScreen`, `_loadSummary()` is called again to refresh the badge.
- Tapping the bell navigates to `NotificationsScreen`.

---

## Data Models

### Firestore: `insurance` Collection

```
insurance/{insuranceId}
  insuranceId:   string   (UUID v4)
  truckId:       string   (ref to trucks/{truckId})
  ownerId:       string   (Firebase Auth UID)
  policyNumber:  string
  provider:      string
  startDate:     string   (ISO 8601 date, e.g. "2025-01-15")
  expiryDate:    string   (ISO 8601 date, e.g. "2026-01-15")
  status:        string   ('Valid' | 'Expiring Soon' | 'Expired')
  createdAt:     Timestamp
  updatedAt:     Timestamp
```

Dates are stored as ISO 8601 strings (not Firestore Timestamps) to simplify arithmetic and serialization. The `status` field is always server-computed and stored; it is never derived from client input.

### API Response: Insurance Record

```json
{
  "insuranceId": "uuid",
  "truckId": "uuid",
  "ownerId": "uid",
  "policyNumber": "POL-12345",
  "provider": "HDFC Ergo",
  "startDate": "2025-01-15",
  "expiryDate": "2026-01-15",
  "status": "Valid",
  "daysUntilExpiry": 180,
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

`daysUntilExpiry` is computed on every read/write and included in the response but not stored in Firestore (it is always derived from `expiryDate` and the server date at request time).

### API Response: Notification Record

```json
{
  "type": "expiring_soon",
  "truckId": "uuid",
  "truckPlate": "MH12 AB 1234",
  "daysUntilExpiry": 3,
  "message": "Insurance for MH12 AB 1234 expires in 3 days"
}
```

For `pending_insurance`, `daysUntilExpiry` is omitted.

### Status Computation Rules

```
serverDate = current UTC date (date only, no time component)
daysUntilExpiry = floor((expiryDate - serverDate) / 86400000)

if daysUntilExpiry < 0:
    status = 'Expired'
elif daysUntilExpiry <= 30:
    status = 'Expiring Soon'
else:
    status = 'Valid'
```

### Notification Window Rules

```
expiring_soon: 1 <= daysUntilExpiry <= 5
expired:       daysUntilExpiry < 0  (i.e. expiryDate < serverDate)
pending:       truck has no insurance record in the insurance collection
```

### COLLECTIONS Constant Update

The `COLLECTIONS` object in `firebase.js` gains:

```js
INSURANCE: 'insurance',
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Status computation is deterministic and exhaustive

*For any* `startDate`, `expiryDate`, and `serverDate`, the `computeStatus` function SHALL return exactly one of `'Expired'`, `'Expiring Soon'`, or `'Valid'`, and the returned status SHALL match the rule: `'Expired'` if `daysUntilExpiry < 0`, `'Expiring Soon'` if `0 <= daysUntilExpiry <= 30`, `'Valid'` if `daysUntilExpiry > 30`.

**Validates: Requirements 3.1, 3.6**

---

### Property 2: daysUntilExpiry is the correct integer day difference

*For any* `expiryDate` and `serverDate`, the `daysUntilExpiry` value returned by the API SHALL equal `Math.floor((expiryDate - serverDate) / 86400000)`, and SHALL be negative when `expiryDate` is before `serverDate`.

**Validates: Requirements 3.6**

---

### Property 3: Insurance record round-trip preserves all fields

*For any* valid insurance creation body `{ truckId, policyNumber, provider, startDate, expiryDate }`, after `POST /api/insurance`, a subsequent `GET /api/insurance/:insuranceId` SHALL return a record containing all submitted fields unchanged, plus a server-computed `status` and `daysUntilExpiry`.

**Validates: Requirements 4.3 (uniqueness), 4.7 (field storage), 2.3 (persistence)**

---

### Property 4: Owner isolation — GET returns only own records

*For any* two distinct owners A and B, each with one or more insurance records, `GET /api/insurance` authenticated as owner A SHALL never include any record whose `ownerId` equals owner B's UID.

**Validates: Requirements 4.4**

---

### Property 5: Pending set is the complement of insured trucks

*For any* list of trucks `T` and list of insurance records `I` (both belonging to the same owner), the set of trucks displayed as "Pending" in the Insurance Screen SHALL equal exactly `{ t ∈ T | ∄ i ∈ I such that i.truckId == t.truckId }`.

**Validates: Requirements 1.1, 1.2**

---

### Property 6: Status summary counts are consistent

*For any* list of insurance records and pending trucks, the sum of `(valid + expiringSoon + expired + pending)` counts displayed in the summary chips SHALL equal the total number of items in the combined list.

**Validates: Requirements 1.4**

---

### Property 7: Cascade delete removes associated insurance record

*For any* truck that has an associated insurance record, after `DELETE /api/trucks/:truckId`, a subsequent `GET /api/insurance` SHALL contain no record with `truckId` equal to the deleted truck's ID.

**Validates: Requirements 1.3**

---

### Property 8: Delete round-trip removes record from GET response

*For any* existing insurance record, after `DELETE /api/insurance/:insuranceId`, a subsequent `GET /api/insurance` SHALL not include a record with that `insuranceId`.

**Validates: Requirements 6.2, 6.4**

---

### Property 9: Idle truck filter returns only truly idle trucks

*For any* list of trucks belonging to an owner, `GET /api/trucks?status=idle` SHALL return exactly those trucks where `status === 'idle'` AND `assignedDriverId === null`, and SHALL exclude all others.

**Validates: Requirements 4.8, 11.2**

---

### Property 10: Available driver filter returns only truly available drivers

*For any* list of drivers belonging to an owner, `GET /api/drivers?status=available` SHALL return exactly those drivers where `status === 'available'` AND `assignedTruckId === null`, and SHALL exclude all others.

**Validates: Requirements 12.2**

---

### Property 11: Atomic driver–truck assignment is bidirectional

*For any* valid driver creation body that includes a `truckId`, after a successful `POST /api/drivers`, both the created driver's `assignedTruckId` SHALL equal the specified `truckId` AND the truck document's `assignedDriverId` SHALL equal the new driver's `driverId`.

**Validates: Requirements 11.3**

---

### Property 12: Atomic truck–driver assignment is bidirectional

*For any* valid truck creation body that includes a `driverId`, after a successful `POST /api/trucks`, both the created truck's `assignedDriverId` SHALL equal the specified `driverId` AND the driver document's `assignedTruckId` SHALL equal the new truck's `truckId`.

**Validates: Requirements 12.3**

---

### Property 13: Race condition guard — stale truck rejected with 409

*For any* truck that was idle when the Driver Form was opened but becomes non-idle before the form is submitted, `POST /api/drivers` with that `truckId` SHALL return HTTP 409 and SHALL NOT create the driver record.

**Validates: Requirements 11.5**

---

### Property 14: Race condition guard — stale driver rejected with 409

*For any* driver that was available when the Truck Form was opened but becomes unavailable before the form is submitted, `POST /api/trucks` with that `driverId` SHALL return HTTP 409 and SHALL NOT create the truck record.

**Validates: Requirements 12.5**

---

### Property 15: Notification count equals notifications array length

*For any* `GET /api/notifications` response, the `count` field SHALL equal `notifications.length`.

**Validates: Requirements 9.3**

---

### Property 16: expiring_soon notifications match the 1–5 day window

*For any* set of insurance records, the `expiring_soon` notifications returned by `GET /api/notifications` SHALL include exactly those records where `1 <= daysUntilExpiry <= 5` (using the server date), and SHALL exclude all others.

**Validates: Requirements 7.1**

---

### Property 17: expired notifications match past-expiry records

*For any* set of insurance records, the `expired` notifications returned by `GET /api/notifications` SHALL include exactly those records where `daysUntilExpiry < 0` (using the server date), and SHALL exclude all others.

**Validates: Requirements 7.2**

---

### Property 18: pending_insurance notifications match trucks with no insurance

*For any* set of trucks and insurance records, the `pending_insurance` notifications returned by `GET /api/notifications` SHALL include exactly those trucks that have no associated insurance record, and SHALL exclude trucks that do have one.

**Validates: Requirements 8.1, 8.4**

---

### Property 19: Notification records contain all required fields

*For any* notification record of type `expiring_soon` or `expired`, the record SHALL contain non-null values for `type`, `truckId`, `truckPlate`, `daysUntilExpiry`, and `message`. For type `pending_insurance`, the record SHALL contain non-null values for `type`, `truckId`, `truckPlate`, and `message`.

**Validates: Requirements 7.3, 8.2**

---

### Property 20: Date validation rejects start-after-expiry

*For any* insurance creation or update body where `startDate > expiryDate`, the backend SHALL return HTTP 400 and SHALL NOT persist any record.

**Validates: Requirements 2.6**

---

### Property 21: Missing required fields are rejected

*For any* insurance creation body missing at least one of `{ truckId, policyNumber, provider, startDate, expiryDate }`, the backend SHALL return HTTP 400 and SHALL NOT persist any record.

**Validates: Requirements 2.4**

---

## Error Handling

### Backend

| Scenario | HTTP Status | Message |
|---|---|---|
| Missing required field | 400 | Field-level validation message |
| `startDate` after `expiryDate` | 400 | "Start date must be before expiry date" |
| Truck not owned by requester | 403 | "Forbidden" |
| Insurance record not found | 404 | "Insurance record not found" |
| Truck already has insurance | 409 | "An insurance record already exists for this truck" |
| Truck no longer idle (race) | 409 | "Selected truck is no longer available" |
| Driver no longer available (race) | 409 | "Selected driver is no longer available" |
| Firebase unavailable | 503 | "Firebase unavailable — …" |

All errors flow through the existing `errorHandler` middleware in `middleware/errorHandler.js`. Service functions attach a `statusCode` property to thrown errors, which the error handler uses to set the HTTP status.

### Frontend

- **Insurance Screen:** On load failure, shows `_ErrorState` widget with the error message and a "Retry" button. No `DemoData` fallback.
- **Notifications Screen:** Same `_ErrorState` pattern.
- **Driver Form — idle truck fetch failure:** Dropdown is rendered in a disabled state with label "Could not load trucks". The form remains submittable without a truck selection.
- **Truck Form — available driver fetch failure:** Same pattern with "Could not load drivers".
- **409 on form submit:** The form sheet displays an `_ErrorBanner` with the server's message (e.g., "Selected truck is no longer available"). The sheet stays open so the user can retry or change their selection.
- **Delete failure:** `ScaffoldMessenger` snackbar with the error message. The item remains in the list.

---

## Testing Strategy

### Unit Tests (Backend)

Focus on pure functions and service logic with mocked Firestore:

- `computeStatus` — test all three branches with boundary dates (exactly 0 days, exactly 30 days, 31 days, negative days).
- `daysUntilExpiry` calculation — test positive, zero, and negative values.
- `getNotifications` — mock truck and insurance collections, verify correct notification types are generated.
- Date validation (`startDate > expiryDate`) — test boundary and invalid cases.
- Idle truck filter — mock truck list, verify filter logic.
- Available driver filter — mock driver list, verify filter logic.

### Property-Based Tests (Backend)

Use **fast-check** (JavaScript PBT library). Each property test runs a minimum of **100 iterations**.

Property tests are tagged with:
`// Feature: truck-insurance-management, Property N: <property_text>`

- **Property 1** — Generate random `(startDate, expiryDate, serverDate)` triples. Verify `computeStatus` returns the correct status for each combination.
- **Property 2** — Generate random `(expiryDate, serverDate)` pairs. Verify `daysUntilExpiry` equals the correct integer difference.
- **Property 5** — Generate random truck lists and insurance record lists. Verify the pending set equals the set-difference.
- **Property 6** — Generate random insurance + pending lists. Verify counts sum to total.
- **Property 9** — Generate random truck lists with mixed statuses and `assignedDriverId` values. Verify the idle filter returns exactly the correct subset.
- **Property 10** — Generate random driver lists. Verify the available filter returns exactly the correct subset.
- **Property 15** — Generate random notification scenarios. Verify `count === notifications.length`.
- **Property 16** — Generate random insurance records with varying expiry dates. Verify `expiring_soon` set matches the 1–5 day window.
- **Property 17** — Generate random insurance records. Verify `expired` set matches past-expiry records.
- **Property 18** — Generate random truck and insurance lists. Verify `pending_insurance` set equals the set-difference.
- **Property 19** — Generate random notification records. Verify all required fields are present and non-null.
- **Property 20** — Generate random `(startDate, expiryDate)` pairs where `startDate > expiryDate`. Verify backend returns 400.
- **Property 21** — Generate random bodies with one or more required fields missing. Verify backend returns 400.

### Integration Tests (Backend)

Use a Firestore emulator or mocked admin SDK:

- Full CRUD lifecycle for insurance records (create → read → update → delete).
- Owner isolation: two owners, verify GET returns only own records.
- Cascade delete: create truck + insurance, delete truck, verify insurance is gone.
- Atomic assignment: create driver with truckId, verify both documents updated.
- Race condition: mark truck as non-idle between validation and commit, verify 409.
- `GET /api/notifications` with a mix of expiring, expired, and pending trucks.

### Unit Tests (Flutter)

- `InsuranceModel.fromJson` — verify all fields map correctly from API response.
- `NotificationModel.fromJson` — verify all fields map correctly.
- Pending set computation — given trucks and insurance lists, verify correct pending entries.
- Status colour mapping — verify each status string maps to the correct `Color`.
- `ApiService` methods — mock `http.Client`, verify correct URLs and request bodies.

### Widget Tests (Flutter)

- `InsuranceScreen` loading state, error state, and populated list.
- `NotificationsScreen` empty state, error state, and populated list.
- `_DriverFormSheet` in add mode: idle truck dropdown present; in edit mode: no dropdown.
- `_TruckFormSheet` in add mode: available driver dropdown present; in edit mode: no dropdown.
- Dashboard notification badge: count > 0 shows red badge; count = 0 shows no badge.

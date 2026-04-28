# Implementation Plan: Truck Insurance Management

## Overview

Implement end-to-end insurance management for the Fleet app. The backend (Node.js/Express + Firestore) gains a full insurance CRUD API, a real-time notifications endpoint, and enhancements to the truck and driver services. The Flutter frontend replaces the hardcoded insurance screen with live API data, adds a notifications screen, enhances the driver and truck creation forms with optional at-creation assignment, and shows a notification badge on the dashboard.

All backend code follows the existing patterns in `truckController.js`, `truckService.js`, and `routes/trucks.js`. All frontend code follows the existing patterns in `ApiService` and the existing screen files.

---

## Tasks

- [x] 1. Register the INSURANCE collection constant
  - In `src/config/firebase.js`, add `INSURANCE: 'insurance'` to the `COLLECTIONS` object
  - This makes the collection name available to all services via `COLLECTIONS.INSURANCE`
  - _Requirements: 4.7_

- [x] 2. Implement `insuranceService.js`
  - [x] 2.1 Create `src/services/insuranceService.js` with `computeStatus` pure function
    - Export `computeStatus(startDate, expiryDate, serverDate)` as a named export
    - Compute `daysUntilExpiry = Math.floor((new Date(expiryDate) - serverDate) / 86400000)`
    - Return `{ status: 'Expired' | 'Expiring Soon' | 'Valid', daysUntilExpiry }` following the rules: `< 0` → Expired, `0–30` → Expiring Soon, `> 30` → Valid
    - _Requirements: 3.1, 3.6_

  - [ ]* 2.2 Write property test for `computeStatus` — Property 1
    - **Property 1: Status computation is deterministic and exhaustive**
    - Use `fast-check` to generate random `(startDate, expiryDate, serverDate)` triples
    - Assert the returned status is exactly one of the three values and matches the boundary rules
    - **Validates: Requirements 3.1, 3.6**

  - [ ]* 2.3 Write property test for `daysUntilExpiry` — Property 2
    - **Property 2: daysUntilExpiry is the correct integer day difference**
    - Generate random `(expiryDate, serverDate)` pairs; assert result equals `Math.floor((expiryDate - serverDate) / 86400000)` and is negative when expiry is before server date
    - **Validates: Requirements 3.6**

  - [x] 2.4 Implement `createInsurance`, `getInsuranceRecords`, `getInsuranceById`, `updateInsurance`, `deleteInsurance` in `insuranceService.js`
    - `createInsurance`: generate UUID v4 for `insuranceId`, verify `truckId` belongs to `ownerId` (403 if not), check no existing record for that `truckId` (409 if duplicate), call `computeStatus` with server date, persist all fields listed in the data model, return the full record with `daysUntilExpiry`
    - `getInsuranceRecords`: query `COLLECTIONS.INSURANCE` where `ownerId ==` caller's uid, sort in-memory by `createdAt` descending, compute `daysUntilExpiry` on each record before returning
    - `getInsuranceById`: fetch by `insuranceId`, throw 404 if missing, 403 if wrong owner
    - `updateInsurance`: fetch record, verify ownership, recompute status with server date, update `policyNumber`, `provider`, `startDate`, `expiryDate`, `status`, `updatedAt`
    - `deleteInsurance`: fetch record, verify ownership, delete document
    - Attach `statusCode` to all thrown errors following the existing pattern in `truckService.js`
    - _Requirements: 2.3, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 6.4_

  - [ ]* 2.5 Write property test for insurance record round-trip — Property 3
    - **Property 3: Insurance record round-trip preserves all fields**
    - Generate valid creation bodies; after create, verify GET returns all submitted fields unchanged plus server-computed `status` and `daysUntilExpiry`
    - **Validates: Requirements 4.3, 4.7, 2.3**

  - [ ]* 2.6 Write property test for owner isolation — Property 4
    - **Property 4: Owner isolation — GET returns only own records**
    - Generate two distinct owner UIDs each with records; assert GET for owner A never includes owner B's records
    - **Validates: Requirements 4.4**

  - [ ]* 2.7 Write property test for delete round-trip — Property 8
    - **Property 8: Delete round-trip removes record from GET response**
    - After DELETE, assert subsequent GET does not include that `insuranceId`
    - **Validates: Requirements 6.2, 6.4**

  - [ ]* 2.8 Write property test for date validation — Property 20
    - **Property 20: Date validation rejects start-after-expiry**
    - Generate `(startDate, expiryDate)` pairs where `startDate > expiryDate`; assert service throws a 400 error and does not persist
    - **Validates: Requirements 2.6**

  - [ ]* 2.9 Write property test for missing required fields — Property 21
    - **Property 21: Missing required fields are rejected**
    - Generate bodies with one or more of `{ truckId, policyNumber, provider, startDate, expiryDate }` missing; assert service/route returns 400
    - **Validates: Requirements 2.4**

- [x] 3. Implement `insuranceController.js`
  - Create `src/controllers/insuranceController.js` with handlers: `addInsurance`, `getInsurances`, `getInsurance`, `updateInsurance`, `deleteInsurance`
  - Each handler delegates to the corresponding `insuranceService` function and uses `created`, `success`, `notFound`, `forbidden`, `badRequest` from `utils/response.js`
  - Pass `req.user.uid` as `ownerId`; never read `ownerId` from `req.body`
  - All handlers follow the `try/catch → next(err)` pattern from `truckController.js`
  - _Requirements: 4.1, 4.6_

- [x] 4. Create `routes/insurance.js` with all 5 endpoints and validation
  - Create `src/routes/insurance.js`
  - Apply `router.use(authenticate)` at the top
  - `POST /`: validate `truckId` (notEmpty), `policyNumber` (notEmpty), `provider` (notEmpty), `startDate` (isISO8601), `expiryDate` (isISO8601); add a custom validator that rejects `startDate >= expiryDate` with message "Start date must be before expiry date"
  - `GET /`: no body validation
  - `GET /:insuranceId`: validate `param('insuranceId').notEmpty()`
  - `PATCH /:insuranceId`: validate `param('insuranceId').notEmpty()`; optional field validators for `policyNumber`, `provider`, `startDate`, `expiryDate`; same cross-field date check when both dates are present
  - `DELETE /:insuranceId`: validate `param('insuranceId').notEmpty()`
  - All routes use the `validate` middleware from `middleware/validate.js`
  - _Requirements: 2.4, 2.6, 4.1_

- [x] 5. Enhance `truckService.js`
  - [x] 5.1 Add idle filter to `getTrucks`
    - Update `getTrucks(ownerId, filters = {})` signature
    - When `filters.status === 'idle'`, filter the in-memory result to only trucks where `status === 'idle'` AND `assignedDriverId === null`
    - Existing callers that pass no `filters` argument are unaffected
    - _Requirements: 4.8, 11.2_

  - [ ]* 5.2 Write property test for idle truck filter — Property 9
    - **Property 9: Idle truck filter returns only truly idle trucks**
    - Generate random truck lists with mixed statuses and `assignedDriverId` values; assert the filtered result equals exactly the subset where both conditions hold
    - **Validates: Requirements 4.8, 11.2**

  - [x] 5.3 Add cascade delete of insurance record in `deleteTruck`
    - After deleting the truck document, query `COLLECTIONS.INSURANCE` where `truckId ==` the deleted truck's ID and `ownerId ==` the owner's UID; if a document is found, delete it
    - _Requirements: 1.3_

  - [ ]* 5.4 Write property test for cascade delete — Property 7
    - **Property 7: Cascade delete removes associated insurance record**
    - After `deleteTruck`, assert `GET /api/insurance` contains no record with that `truckId`
    - **Validates: Requirements 1.3**

  - [x] 5.5 Add atomic driver assignment to `addTruck`
    - Update `addTruck` to accept optional `driverId` in the input object
    - When `driverId` is provided: fetch the driver document inside a transaction/batch; verify `status === 'available'` AND `assignedTruckId === null` — if not, throw a 409 error with message "Selected driver is no longer available" and do NOT create the truck
    - Use a Firestore batch write to atomically: create the truck doc, update the driver's `assignedTruckId` to the new `truckId` and `status` to `'on_trip'`, and set the truck's `assignedDriverId` to `driverId`
    - When `driverId` is not provided, behaviour is unchanged
    - _Requirements: 12.3, 12.4, 12.5_

  - [ ]* 5.6 Write property test for atomic truck–driver assignment — Property 12
    - **Property 12: Atomic truck–driver assignment is bidirectional**
    - After successful `POST /api/trucks` with a `driverId`, assert the truck's `assignedDriverId` equals the driver's ID AND the driver's `assignedTruckId` equals the new truck's ID
    - **Validates: Requirements 12.3**

  - [ ]* 5.7 Write property test for race condition guard on truck creation — Property 14
    - **Property 14: Race condition guard — stale driver rejected with 409**
    - Mark a driver as unavailable between validation and commit; assert `POST /api/trucks` returns 409 and no truck document is created
    - **Validates: Requirements 12.5**

- [x] 6. Enhance `driverService.js`
  - [x] 6.1 Add available filter to `getDrivers`
    - Update `getDrivers(ownerId, filters = {})` signature
    - When `filters.status === 'available'`, filter the in-memory result to only drivers where `status === 'available'` AND `assignedTruckId === null`
    - Existing callers that pass no `filters` argument are unaffected
    - _Requirements: 12.2_

  - [ ]* 6.2 Write property test for available driver filter — Property 10
    - **Property 10: Available driver filter returns only truly available drivers**
    - Generate random driver lists with mixed statuses and `assignedTruckId` values; assert the filtered result equals exactly the subset where both conditions hold
    - **Validates: Requirements 12.2**

  - [x] 6.3 Add atomic truck assignment to `addDriver`
    - Update `addDriver` to accept optional `truckId` in the input object
    - When `truckId` is provided: fetch the truck document; verify `status === 'idle'` AND `assignedDriverId === null` — if not, throw a 409 error with message "Selected truck is no longer available" and do NOT create the driver
    - Use a Firestore batch write to atomically: create the users doc, create the driver doc, update the truck's `assignedDriverId` to the new driver's uid, and update the driver's `assignedTruckId` to `truckId`
    - When `truckId` is not provided, behaviour is unchanged (existing sequential writes are fine)
    - _Requirements: 11.3, 11.4, 11.5_

  - [ ]* 6.4 Write property test for atomic driver–truck assignment — Property 11
    - **Property 11: Atomic driver–truck assignment is bidirectional**
    - After successful `POST /api/drivers` with a `truckId`, assert the driver's `assignedTruckId` equals the truck's ID AND the truck's `assignedDriverId` equals the new driver's ID
    - **Validates: Requirements 11.3**

  - [ ]* 6.5 Write property test for race condition guard on driver creation — Property 13
    - **Property 13: Race condition guard — stale truck rejected with 409**
    - Mark a truck as non-idle between validation and commit; assert `POST /api/drivers` returns 409 and no driver document is created
    - **Validates: Requirements 11.5**

- [ ] 7. Checkpoint — Ensure all backend service tests pass
  - Run the test suite; confirm `computeStatus`, idle filter, available filter, cascade delete, and atomic assignment tests all pass
  - Ask the user if any questions arise before proceeding to notification services

- [x] 8. Implement `notificationService.js`
  - [x] 8.1 Create `src/services/notificationService.js` with `getNotifications`, `buildExpiringNotification`, `buildExpiredNotification`, `buildPendingNotification`
    - `buildExpiringNotification(insurance, serverDate)`: returns a `NotificationRecord` if `1 <= daysUntilExpiry <= 5`, otherwise `null`
    - `buildExpiredNotification(insurance, serverDate)`: returns a `NotificationRecord` if `daysUntilExpiry < 0`, otherwise `null`
    - `buildPendingNotification(truck)`: always returns a `NotificationRecord` of type `pending_insurance`
    - `getNotifications(ownerId)`: fetch all trucks and insurance records for the owner in parallel using `Promise.all`; build the notification list in memory; return `{ notifications, count: notifications.length }`; no Firestore writes
    - Message format: "Insurance for {plate} expires in {n} days" / "Insurance for {plate} expired {n} days ago" / "No insurance record found for truck {plate}"
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.4, 9.2, 9.4, 9.5, 9.6_

  - [ ]* 8.2 Write property test for notification count consistency — Property 15
    - **Property 15: Notification count equals notifications array length**
    - Generate random notification scenarios; assert `count === notifications.length` always
    - **Validates: Requirements 9.3**

  - [ ]* 8.3 Write property test for expiring_soon window — Property 16
    - **Property 16: expiring_soon notifications match the 1–5 day window**
    - Generate insurance records with varying expiry dates; assert `expiring_soon` set matches exactly those with `1 <= daysUntilExpiry <= 5`
    - **Validates: Requirements 7.1**

  - [ ]* 8.4 Write property test for expired notifications — Property 17
    - **Property 17: expired notifications match past-expiry records**
    - Generate insurance records; assert `expired` set matches exactly those with `daysUntilExpiry < 0`
    - **Validates: Requirements 7.2**

  - [ ]* 8.5 Write property test for pending_insurance notifications — Property 18
    - **Property 18: pending_insurance notifications match trucks with no insurance**
    - Generate truck and insurance lists; assert `pending_insurance` set equals the set-difference (trucks with no matching insurance record)
    - **Validates: Requirements 8.1, 8.4**

  - [ ]* 8.6 Write property test for notification required fields — Property 19
    - **Property 19: Notification records contain all required fields**
    - Generate notification records of all three types; assert required fields are present and non-null per type
    - **Validates: Requirements 7.3, 8.2**

- [x] 9. Implement `notificationController.js`
  - Create `src/controllers/notificationController.js` with a single `getNotifications` handler
  - Delegate to `notificationService.getNotifications(req.user.uid)`
  - Return result using `success(res, { notifications, count })`
  - Follow the `try/catch → next(err)` pattern
  - _Requirements: 9.1, 9.3_

- [x] 10. Create `routes/notifications.js`
  - Create `src/routes/notifications.js`
  - Apply `router.use(authenticate)`
  - `GET /`: no validation needed, delegate to `notificationController.getNotifications`
  - _Requirements: 9.1_

- [x] 11. Register insurance and notification routes in `app.js` and update truck/driver routes for status filter
  - In `src/app.js`: require `./routes/insurance` and `./routes/notifications`; register `app.use('/api/insurance', insuranceRoutes)` and `app.use('/api/notifications', notificationRoutes)` after the existing route registrations
  - In `src/routes/trucks.js`: update the `GET /` handler to read `req.query.status` and pass `{ status: req.query.status }` as the `filters` argument to `truckService.getTrucks`
  - In `src/routes/drivers.js`: update the `GET /` handler to read `req.query.status` and pass `{ status: req.query.status }` as the `filters` argument to `driverService.getDrivers`
  - In `src/controllers/truckController.js`: update `getTrucks` to forward `req.query` filters to the service
  - In `src/controllers/driverController.js`: update `getDrivers` to forward `req.query` filters to the service
  - _Requirements: 4.1, 4.8, 9.1, 11.1, 12.1_

- [ ] 12. Checkpoint — Verify all backend routes are reachable
  - Confirm `POST /api/insurance`, `GET /api/insurance`, `GET /api/notifications`, `GET /api/trucks?status=idle`, and `GET /api/drivers?status=available` all return expected responses (use a REST client or integration test)
  - Ensure all tests pass; ask the user if questions arise before proceeding to frontend

- [x] 13. Add `InsuranceModel` and `NotificationModel` to `models/models.dart`
  - Add `InsuranceModel` class with fields: `insuranceId`, `truckId`, `truckPlate`, `policyNumber`, `provider`, `startDate`, `expiryDate`, `status`, `daysUntilExpiry`; implement `factory InsuranceModel.fromJson(Map<String, dynamic> j)`
  - Add `NotificationModel` class with fields: `type`, `truckId`, `truckPlate`, `daysUntilExpiry` (nullable int), `message`; implement `factory NotificationModel.fromJson(Map<String, dynamic> j)`
  - Replace any existing stub `InsuranceModel` with the richer version
  - Add `notifications` list and `notificationCount` integer to `AppStore` (or equivalent state class) if it exists in `models.dart`
  - _Requirements: 5.5, 10.4_

- [x] 14. Add new API methods to `ApiService`
  - In `lib/services/api_service.dart`, add the following static methods following the existing pattern:
    - `getInsuranceRecords()` → `GET /api/insurance`, returns `List<Map<String, dynamic>>`
    - `addInsuranceRecord(Map<String, dynamic> body)` → `POST /api/insurance`
    - `updateInsuranceRecord(String insuranceId, Map<String, dynamic> body)` → `PATCH /api/insurance/:insuranceId`
    - `deleteInsuranceRecord(String insuranceId)` → `DELETE /api/insurance/:insuranceId`
    - `getNotifications()` → `GET /api/notifications`, returns `Map<String, dynamic>` with `notifications` and `count`
    - `getIdleTrucks()` → `GET /api/trucks?status=idle`, returns `List<Map<String, dynamic>>`
    - `getAvailableDrivers()` → `GET /api/drivers?status=available`, returns `List<Map<String, dynamic>>`
  - _Requirements: 5.5, 10.4, 11.1, 12.1_

- [x] 15. Full rewrite of `insurance_screen.dart`
  - [x] 15.1 Replace hardcoded data loading with real API calls
    - On `initState` / `_loadData()`: call `ApiService.getInsuranceRecords()` and `ApiService.getTrucks()` in parallel using `Future.wait`
    - Compute pending entries in-memory as trucks with no matching `truckId` in the insurance list (Property 5)
    - Show `CircularProgressIndicator` while loading; show `_ErrorState` widget (error message + Retry button) on failure — no `DemoData` fallback
    - Implement pull-to-refresh with `RefreshIndicator`
    - _Requirements: 1.1, 1.2, 5.1, 5.2, 5.3, 5.4_

  - [ ]* 15.2 Write unit test for pending set computation — Property 5
    - **Property 5: Pending set is the complement of insured trucks**
    - Given truck and insurance lists, assert pending entries equal exactly the set-difference
    - **Validates: Requirements 1.1, 1.2**

  - [x] 15.3 Implement summary chips and status colour mapping
    - Display four summary chips at the top: Valid (green), Expiring Soon (amber), Expired (red), Pending (blue)
    - Counts are derived from the combined insurance + pending list
    - Status colour helper: `'Valid'` → green, `'Expiring Soon'` → amber, `'Expired'` → red, `'Pending'` → blue
    - _Requirements: 1.4, 3.4, 3.5_

  - [ ]* 15.4 Write unit test for status summary count consistency — Property 6
    - **Property 6: Status summary counts are consistent**
    - Given a combined list, assert `valid + expiringSoon + expired + pending == total`
    - **Validates: Requirements 1.4**

  - [x] 15.5 Implement insurance form with date pickers and validation
    - `_InsuranceFormSheet` (modal bottom sheet): text fields for `policyNumber` and `provider`; date pickers (via `showDatePicker`) for `startDate` and `expiryDate`
    - In add mode: `truckId` is pre-set from the selected pending entry
    - In edit mode: pre-populate all fields from the existing `InsuranceModel`
    - Client-side validation: all fields required (show field-level error on empty); `startDate` must be before `expiryDate` (show "Start date must be before expiry date")
    - On submit: call `ApiService.addInsuranceRecord` or `ApiService.updateInsuranceRecord`; on success close sheet and call `_loadData()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 5.6_

  - [x] 15.6 Implement delete with confirmation dialog
    - Long-press or delete icon triggers a confirmation `AlertDialog`
    - On confirm: call `ApiService.deleteInsuranceRecord(id)`; on success remove entry from list
    - On failure: show `ScaffoldMessenger` snackbar with error message; retain entry in list
    - _Requirements: 6.1, 6.2, 6.3_

- [x] 16. Create `notifications_screen.dart`
  - Create `lib/screens/notifications_screen.dart`
  - On `initState`: call `ApiService.getNotifications()`; store `List<NotificationModel>` in local state
  - Render three card types: amber card for `expiring_soon`, red card for `expired`, blue card for `pending_insurance`
  - Each card shows truck plate, days remaining/overdue (for expiry types), and the message string
  - Implement `RefreshIndicator` for pull-to-refresh
  - Show empty state widget ("No active alerts") when list is empty
  - Show `_ErrorState` (error message + Retry button) on load failure
  - _Requirements: 7.5, 8.3, 9.1_

- [x] 17. Enhance `drivers_screen.dart` — `_DriverFormSheet` with idle truck dropdown
  - In `_DriverFormSheet`, add a `List<Map<String, dynamic>> _idleTrucks` and `bool _trucksLoadFailed` to local state
  - In `initState` (add mode only): call `ApiService.getIdleTrucks()`; populate `_idleTrucks`; on failure set `_trucksLoadFailed = true`
  - Render an "Assign Truck (optional)" `DropdownButtonFormField` populated from `_idleTrucks`; disabled with label "Could not load trucks" when `_trucksLoadFailed` is true
  - In edit mode: do not render the dropdown
  - On submit: include `truckId` in the request body if a truck is selected
  - On 409 response: display an `_ErrorBanner` inside the sheet with the server's message; keep the sheet open
  - _Requirements: 11.1, 11.2, 11.4, 11.5, 11.6, 11.7_

- [x] 18. Enhance `trucks_screen.dart` — `_TruckFormSheet` with available driver dropdown
  - In `_TruckFormSheet`, add a `List<Map<String, dynamic>> _availableDrivers` and `bool _driversLoadFailed` to local state
  - In `initState` (add mode only): call `ApiService.getAvailableDrivers()`; populate `_availableDrivers`; on failure set `_driversLoadFailed = true`
  - Render an "Assign Driver (optional)" `DropdownButtonFormField` populated from `_availableDrivers`; disabled with label "Could not load drivers" when `_driversLoadFailed` is true
  - In edit mode: do not render the dropdown
  - On submit: include `driverId` in the request body if a driver is selected
  - On 409 response: display an `_ErrorBanner` inside the sheet with the server's message; keep the sheet open
  - _Requirements: 12.1, 12.2, 12.4, 12.5, 12.6, 12.7_

- [x] 19. Update `dashboard_screen.dart` with notification badge
  - In `_loadSummary()` (or equivalent dashboard data-loading method): also call `ApiService.getNotifications()` and store the returned `count` in state
  - Update the `_NotificationBell` widget (or equivalent): when `count > 0`, overlay a red `Badge` widget showing the numeric count; when `count == 0`, render the bell icon without a badge
  - Wire the bell's `onTap` to navigate to `NotificationsScreen`; on return (after `await Navigator.push`), call `_loadSummary()` again to refresh the badge count
  - _Requirements: 10.1, 10.2, 10.3, 10.5_

- [x] 20. Final checkpoint — Ensure all tests pass and feature is wired end-to-end
  - Run the full backend test suite; confirm all property tests and unit tests pass
  - Verify the Flutter app compiles without errors (`flutter analyze`)
  - Confirm the complete flow: add truck → appears as Pending in Insurance Screen → add insurance → status computed by backend → notification badge updates on dashboard → notifications screen shows correct alerts
  - Ask the user if any questions arise

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Property tests use `fast-check` (already available in the Node.js ecosystem); run with `npm test`
- Each property test is tagged with `// Feature: truck-insurance-management, Property N: <text>` for traceability
- All backend error handling flows through the existing `errorHandler` middleware in `middleware/errorHandler.js`
- The `ownerId` is always derived from `req.user.uid` — never from the request body
- Dates are stored as ISO 8601 strings in Firestore; `daysUntilExpiry` is computed on every read and included in the response but not stored
- Notifications are never persisted to Firestore; they are computed in real-time on every `GET /api/notifications` request

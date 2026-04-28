# Requirements Document

## Introduction

This feature adds a fully integrated truck insurance management system to the Fleet Management app. Currently the insurance section displays hardcoded data and has no backend persistence. The goal is to replace that with a real data flow: when a truck is added to the system it automatically appears in the insurance section with a "Pending" status, fleet owners can then enter full insurance details (policy number, provider, start date, expiry date) via a form, the system automatically computes a status indicator (Valid, Expiring Soon, Expired) from the dates, and all data is stored in and fetched from the Firestore backend. Full CRUD operations are supported and the UI refreshes on load and on demand.

The feature also introduces an in-app notification system that alerts the Fleet_Owner about insurance policies expiring within 5 days, already-expired policies, and trucks with no insurance record. Additionally, the driver and truck creation forms are enhanced to allow optional truck–driver pairing at creation time, reducing the need for a separate assignment step.

## Glossary

- **Insurance_Service**: The Node.js/Express backend service responsible for creating, reading, updating, and deleting insurance records in Firestore.
- **Insurance_Controller**: The Express controller that handles HTTP requests for insurance endpoints and delegates to the Insurance_Service.
- **Insurance_Record**: A Firestore document in the `insurance` collection that stores all insurance details for a single truck.
- **Insurance_Screen**: The Flutter screen that displays the list of insurance records and provides the form for adding or editing insurance details.
- **Insurance_Form**: The modal bottom sheet in the Flutter app where a user enters or edits insurance details for a truck.
- **Status_Calculator**: The backend logic that derives an insurance status from the policy start date and expiry date using the server's current date.
- **Fleet_Owner**: An authenticated user with the fleet owner role who manages trucks and their insurance.
- **Truck_Record**: An existing Firestore document in the `trucks` collection representing a registered truck.
- **API_Service**: The existing Flutter HTTP client (`api_service.dart`) used to communicate with the backend.
- **Notification_Record**: A transient object computed in real-time by the backend representing a single alert for the Fleet_Owner (expiring insurance, expired insurance, or pending insurance).
- **Notification_Controller**: The Express controller that handles `GET /api/notifications` and delegates computation to the Notification_Service.
- **Notification_Service**: The backend service that queries Firestore for trucks and insurance records belonging to the Fleet_Owner and computes the list of Notification_Records using the server's current date.
- **Notification_Screen**: The Flutter screen (or section) that displays the list of active Notification_Records for the Fleet_Owner.
- **Idle_Truck**: A Truck_Record whose `status` field equals `"idle"` and whose `assignedDriverId` field is `null`, meaning it is not currently assigned to any driver.
- **Available_Driver**: A driver record whose `status` field equals `"available"` and whose `assignedTruckId` field is `null`, meaning the driver is not currently assigned to any truck.
- **Driver_Form**: The modal bottom sheet (`_DriverFormSheet`) in the Flutter app where a Fleet_Owner enters details for a new driver.
- **Truck_Form**: The modal bottom sheet (`_TruckFormSheet`) in the Flutter app where a Fleet_Owner enters details for a new truck.
- **Server_Date**: The current UTC date as determined by the Node.js backend at the time of request processing, used for all date-based calculations to prevent client clock manipulation.

---

## Requirements

### Requirement 1: Automatic Truck Appearance in Insurance Section

**User Story:** As a Fleet Owner, I want every truck I add to the system to automatically appear in the insurance section, so that I never miss insuring a newly registered truck.

#### Acceptance Criteria

1. WHEN a Truck_Record is created via the truck management flow, THE Insurance_Screen SHALL display that truck as an insurance entry with status "Pending" on the next load or refresh.
2. WHEN the Insurance_Screen loads, THE Insurance_Screen SHALL fetch the list of all trucks belonging to the Fleet_Owner from the backend and display any truck that has no associated Insurance_Record as a "Pending" entry.
3. WHEN a truck is deleted from the system, THE Insurance_Service SHALL delete the associated Insurance_Record for that truck if one exists, and THE Notification_Service SHALL exclude that truck from all future Notification_Record computations.
4. THE Insurance_Screen SHALL display a summary count of trucks in each status category (Valid, Expiring Soon, Expired, Pending) at the top of the screen.

---

### Requirement 2: Insurance Details Form

**User Story:** As a Fleet Owner, I want to enter full insurance details for each truck through a form, so that all policy information is captured and stored accurately.

#### Acceptance Criteria

1. WHEN a Fleet_Owner taps the "Add" action on a Pending insurance entry, THE Insurance_Form SHALL open and present input fields for: policy number, insurance provider name, policy start date, and policy expiry date.
2. WHEN a Fleet_Owner taps the "Edit" action on an existing insurance entry, THE Insurance_Form SHALL open pre-populated with the current Insurance_Record values.
3. WHEN the Fleet_Owner submits the Insurance_Form with all required fields filled, THE Insurance_Service SHALL persist the Insurance_Record to Firestore and THE Insurance_Screen SHALL reflect the updated data without requiring a full app restart.
4. IF the Fleet_Owner submits the Insurance_Form with any required field empty, THEN THE Insurance_Form SHALL display a field-level validation message identifying the missing field and SHALL NOT submit the record to the backend.
5. WHEN a date field is activated in the Insurance_Form, THE Insurance_Form SHALL present a date picker so that the Fleet_Owner selects a structured date rather than typing free text.
6. IF the policy start date entered is after the policy expiry date, THEN THE Insurance_Form SHALL display a validation error stating "Start date must be before expiry date" and SHALL NOT submit the record.

---

### Requirement 3: Automatic Status Calculation

**User Story:** As a Fleet Owner, I want the system to automatically calculate and display the insurance status based on the policy dates, so that I can immediately see which trucks need attention without manual tracking.

#### Acceptance Criteria

1. WHEN an Insurance_Record is created or updated, THE Insurance_Service SHALL compute the insurance status using the Server_Date and the following rules:
   - IF the Server_Date is after the policy expiry date, THEN the status SHALL be "Expired".
   - IF the Server_Date is within 30 days before the policy expiry date, THEN the status SHALL be "Expiring Soon".
   - IF the Server_Date is on or after the policy start date and more than 30 days before the policy expiry date, THEN the status SHALL be "Valid".
2. THE Insurance_Service SHALL use the Server_Date exclusively for all status and days-remaining calculations; client-supplied dates SHALL NOT be used for status derivation.
3. THE Insurance_Service SHALL store the computed status value in the Insurance_Record in Firestore alongside the raw date fields.
4. WHEN the Insurance_Screen loads insurance data from the backend, THE Insurance_Screen SHALL display the status value returned by the backend without recomputing it on the client.
5. THE Insurance_Screen SHALL render each status with a distinct colour indicator: green for "Valid", amber for "Expiring Soon", red for "Expired", and blue for "Pending".
6. WHEN the backend returns an Insurance_Record, THE Insurance_Service SHALL include a computed `daysUntilExpiry` integer field in the API response, calculated as the number of whole days from the Server_Date to the policy expiry date (negative if already expired), so that the frontend does not perform date arithmetic.

---

### Requirement 4: Backend CRUD API for Insurance Records

**User Story:** As a Fleet Owner, I want all insurance data to be stored in and retrieved from the backend, so that the data persists across sessions and devices.

#### Acceptance Criteria

1. THE Insurance_Controller SHALL expose the following HTTP endpoints, all protected by the existing `authenticate` middleware:
   - `POST /api/insurance` — create a new Insurance_Record
   - `GET /api/insurance` — retrieve all Insurance_Records for the authenticated Fleet_Owner
   - `GET /api/insurance/:insuranceId` — retrieve a single Insurance_Record by ID
   - `PATCH /api/insurance/:insuranceId` — update an existing Insurance_Record
   - `DELETE /api/insurance/:insuranceId` — delete an Insurance_Record
2. WHEN a `POST /api/insurance` request is received with a `truckId` that does not belong to the authenticated Fleet_Owner, THEN THE Insurance_Controller SHALL return HTTP 403.
3. WHEN a `POST /api/insurance` request is received with a `truckId` that already has an Insurance_Record, THEN THE Insurance_Controller SHALL return HTTP 409 with a message indicating a record already exists for that truck.
4. WHEN a `GET /api/insurance` request is received, THE Insurance_Service SHALL return only Insurance_Records whose `ownerId` matches the authenticated Fleet_Owner's UID.
5. WHEN a `PATCH /api/insurance/:insuranceId` request is received, THE Insurance_Service SHALL recompute the insurance status using the Server_Date based on the updated dates and persist the new status value.
6. IF a request targets an Insurance_Record that does not exist, THEN THE Insurance_Controller SHALL return HTTP 404.
7. THE Insurance_Service SHALL store each Insurance_Record in Firestore with the fields: `insuranceId`, `truckId`, `ownerId`, `policyNumber`, `provider`, `startDate`, `expiryDate`, `status`, `createdAt`, `updatedAt`.
8. WHEN the `GET /api/trucks` endpoint is called, THE Insurance_Service SHALL support a `?status=idle` query parameter that filters the returned trucks to only those with `status == "idle"` and `assignedDriverId == null`, so that the frontend can populate Idle_Truck dropdowns without client-side filtering.

---

### Requirement 5: Frontend Integration and Data Refresh

**User Story:** As a Fleet Owner, I want the insurance screen to always show live data from the backend, so that I am never looking at stale or hardcoded information.

#### Acceptance Criteria

1. WHEN the Insurance_Screen is navigated to, THE Insurance_Screen SHALL fetch insurance data from `GET /api/insurance` via the API_Service and replace any previously displayed data with the response.
2. WHEN the Fleet_Owner performs a pull-to-refresh gesture on the Insurance_Screen, THE Insurance_Screen SHALL re-fetch insurance data from the backend and update the displayed list.
3. WHEN the Insurance_Screen is loading data, THE Insurance_Screen SHALL display a loading indicator and SHALL NOT display stale data from a previous load.
4. IF the backend request fails, THEN THE Insurance_Screen SHALL display an error message and a retry button, and SHALL NOT display hardcoded fallback data.
5. THE API_Service SHALL expose the following methods to the Insurance_Screen: `getInsuranceRecords()`, `addInsuranceRecord(body)`, `updateInsuranceRecord(insuranceId, body)`, and `deleteInsuranceRecord(insuranceId)`.
6. WHEN an Insurance_Record is successfully created or updated via the Insurance_Form, THE Insurance_Screen SHALL refresh its list by re-fetching from the backend.

---

### Requirement 6: Insurance Record Deletion

**User Story:** As a Fleet Owner, I want to delete an insurance record for a truck, so that I can remove outdated or incorrect entries.

#### Acceptance Criteria

1. WHEN a Fleet_Owner long-presses or activates a delete action on an insurance entry in the Insurance_Screen, THE Insurance_Screen SHALL display a confirmation dialog before proceeding.
2. WHEN the Fleet_Owner confirms deletion, THE API_Service SHALL call `DELETE /api/insurance/:insuranceId` and THE Insurance_Screen SHALL remove the entry from the displayed list upon a successful response.
3. IF the delete request fails, THEN THE Insurance_Screen SHALL display an error message and SHALL retain the entry in the displayed list.
4. WHEN an Insurance_Record is deleted, THE Insurance_Service SHALL remove the document from the Firestore `insurance` collection.

---

### Requirement 7: Insurance Expiry Notifications (5-Day Warning)

**User Story:** As a Fleet Owner, I want to receive an in-app notification when a truck's insurance is about to expire within 5 days, so that I can renew the policy before it lapses.

#### Acceptance Criteria

1. WHEN the Notification_Service computes Notification_Records for a Fleet_Owner, THE Notification_Service SHALL include a Notification_Record of type `"expiring_soon"` for every Insurance_Record whose `expiryDate` is between 1 and 5 days from the Server_Date (inclusive).
2. WHEN the Notification_Service computes Notification_Records for a Fleet_Owner, THE Notification_Service SHALL include a Notification_Record of type `"expired"` for every Insurance_Record whose `expiryDate` is before the Server_Date.
3. THE Notification_Record for an expiring or expired insurance SHALL include the fields: `type`, `truckId`, `truckPlate`, `daysUntilExpiry` (negative if already expired), and `message` (a human-readable string such as "Insurance for MH12 AB 1234 expires in 3 days" or "Insurance for MH12 AB 1234 expired 2 days ago").
4. THE Notification_Service SHALL use the Server_Date exclusively for all expiry calculations; client-supplied dates SHALL NOT influence notification generation.
5. WHEN the Notification_Screen is loaded, THE Notification_Screen SHALL display each expiry Notification_Record with the truck plate, the days remaining or overdue, and a colour-coded indicator (amber for expiring soon, red for expired).

---

### Requirement 8: Pending Insurance Notifications

**User Story:** As a Fleet Owner, I want to see alerts for trucks that have no insurance record at all, so that I am reminded to add insurance for every truck in my fleet.

#### Acceptance Criteria

1. WHEN the Notification_Service computes Notification_Records for a Fleet_Owner, THE Notification_Service SHALL include a Notification_Record of type `"pending_insurance"` for every Truck_Record belonging to the Fleet_Owner that has no associated Insurance_Record in Firestore.
2. THE Notification_Record for a pending insurance truck SHALL include the fields: `type`, `truckId`, `truckPlate`, and `message` (a human-readable string such as "No insurance record found for truck MH12 AB 1234").
3. WHEN the Notification_Screen is loaded, THE Notification_Screen SHALL display each pending Notification_Record with the truck plate and a blue colour-coded indicator consistent with the "Pending" status colour used in the Insurance_Screen.
4. WHEN a Fleet_Owner adds an Insurance_Record for a truck, THE Notification_Service SHALL no longer include a `"pending_insurance"` Notification_Record for that truck in subsequent responses.

---

### Requirement 9: Backend Notifications Endpoint

**User Story:** As a Fleet Owner, I want a single API endpoint that returns all my active insurance alerts, so that the app can display a consolidated notification list without the frontend performing any date calculations.

#### Acceptance Criteria

1. THE Notification_Controller SHALL expose a `GET /api/notifications` endpoint protected by the existing `authenticate` middleware.
2. WHEN `GET /api/notifications` is called, THE Notification_Service SHALL query Firestore for all Truck_Records and Insurance_Records belonging to the authenticated Fleet_Owner and compute the full list of Notification_Records in real-time using the Server_Date.
3. THE `GET /api/notifications` response SHALL return a JSON object with the fields: `notifications` (array of Notification_Record objects) and `count` (total number of Notification_Records).
4. THE Notification_Service SHALL include all three notification types in a single response: `"expiring_soon"`, `"expired"`, and `"pending_insurance"`.
5. WHEN the Fleet_Owner has no active alerts, THE Notification_Service SHALL return an empty `notifications` array and `count` of 0.
6. THE Notification_Service SHALL NOT persist Notification_Records to Firestore; all notification data SHALL be computed on each request from the live Truck_Records and Insurance_Records.

---

### Requirement 10: Notification Badge on Dashboard

**User Story:** As a Fleet Owner, I want to see a notification badge count on the home/dashboard screen, so that I can immediately know how many active insurance alerts require my attention without navigating to the notification section.

#### Acceptance Criteria

1. WHEN the dashboard screen loads or refreshes, THE dashboard screen SHALL call `GET /api/notifications` via the API_Service and display the returned `count` as a badge on the notification icon or section.
2. WHEN the `count` is zero, THE dashboard screen SHALL NOT display a badge (or SHALL display the icon without a numeric overlay).
3. WHEN the `count` is greater than zero, THE dashboard screen SHALL display the numeric count in a red badge overlaid on the notification icon.
4. THE API_Service SHALL expose a `getNotifications()` method that calls `GET /api/notifications` and returns the notifications array and count.
5. WHEN the Fleet_Owner navigates from the dashboard to the Notification_Screen and then returns to the dashboard, THE dashboard screen SHALL refresh the badge count by re-fetching from the backend.

---

### Requirement 11: Driver Assignment via Idle Truck Dropdown in Driver Form

**User Story:** As a Fleet Owner, I want to optionally assign an idle truck to a new driver directly from the Add Driver form, so that I can set up a driver–truck pair in a single step without navigating to a separate assignment screen.

#### Acceptance Criteria

1. WHEN the Driver_Form is opened in "add" mode, THE Driver_Form SHALL fetch the list of Idle_Trucks from `GET /api/trucks?status=idle` and display an optional dropdown labelled "Assign Truck (optional)".
2. THE dropdown in the Driver_Form SHALL list only Idle_Trucks; trucks with status `"active"`, `"on_trip"`, or `"maintenance"` SHALL NOT appear in the list.
3. WHEN the Fleet_Owner selects an Idle_Truck from the dropdown and submits the Driver_Form, THE Insurance_Service SHALL atomically create the driver record and assign the selected truck to the driver in a single Firestore batch write, updating both the driver's `assignedTruckId` and the truck's `assignedDriverId`.
4. WHEN the Fleet_Owner leaves the truck dropdown unselected and submits the Driver_Form, THE Insurance_Service SHALL create the driver record with `assignedTruckId: null` and SHALL NOT modify any truck record.
5. WHEN the Driver_Form is submitted with a truck selected, THE backend SHALL verify at submission time that the selected truck still has `status == "idle"` and `assignedDriverId == null`; IF the truck is no longer idle, THEN THE backend SHALL return HTTP 409 with the message "Selected truck is no longer available" and SHALL NOT create the driver record.
6. IF the `GET /api/trucks?status=idle` request fails, THEN THE Driver_Form SHALL display the truck dropdown in a disabled state with a label "Could not load trucks" and SHALL still allow the Fleet_Owner to submit the form without a truck assignment.
7. WHEN the Driver_Form is opened in "edit" mode, THE Driver_Form SHALL NOT display the idle truck dropdown, as truck assignment changes for existing drivers are handled through the existing assign/unassign flow.

---

### Requirement 12: Driver Assignment via Available Driver Dropdown in Truck Form

**User Story:** As a Fleet Owner, I want to optionally assign an available driver to a new truck directly from the Add Truck form, so that I can set up a truck–driver pair in a single step without navigating to a separate assignment screen.

#### Acceptance Criteria

1. WHEN the Truck_Form is opened in "add" mode, THE Truck_Form SHALL fetch the list of Available_Drivers from `GET /api/drivers?status=available` and display an optional dropdown labelled "Assign Driver (optional)".
2. THE dropdown in the Truck_Form SHALL list only Available_Drivers; drivers with status `"on_trip"` or any non-null `assignedTruckId` SHALL NOT appear in the list.
3. WHEN the Fleet_Owner selects an Available_Driver from the dropdown and submits the Truck_Form, THE backend SHALL atomically create the truck record and assign the selected driver to the truck in a single Firestore batch write, updating both the truck's `assignedDriverId` and the driver's `assignedTruckId`.
4. WHEN the Fleet_Owner leaves the driver dropdown unselected and submits the Truck_Form, THE backend SHALL create the truck record with `assignedDriverId: null` and SHALL NOT modify any driver record.
5. WHEN the Truck_Form is submitted with a driver selected, THE backend SHALL verify at submission time that the selected driver still has `status == "available"` and `assignedTruckId == null`; IF the driver is no longer available, THEN THE backend SHALL return HTTP 409 with the message "Selected driver is no longer available" and SHALL NOT create the truck record.
6. IF the `GET /api/drivers?status=available` request fails, THEN THE Truck_Form SHALL display the driver dropdown in a disabled state with a label "Could not load drivers" and SHALL still allow the Fleet_Owner to submit the form without a driver assignment.
7. WHEN the Truck_Form is opened in "edit" mode, THE Truck_Form SHALL NOT display the available driver dropdown, as driver assignment changes for existing trucks are handled through the existing assign/unassign flow.

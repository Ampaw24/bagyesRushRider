# BagyesRUSH Rider App — Feature Documentation

**Version:** 1.0.0
**Platform:** Flutter (iOS & Android)
**Architecture:** Clean Architecture · Riverpod · GoRouter
**Base API:** `http://35.178.123.67:8071/api/v1`

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Feature Status Matrix](#3-feature-status-matrix)
4. [Feature Specifications](#4-feature-specifications)
   - [4.1 Authentication](#41-authentication)
   - [4.2 Dashboard & Navigation](#42-dashboard--navigation)
   - [4.3 Order Management](#43-order-management)
   - [4.4 Real-Time Location Tracking](#44-real-time-location-tracking)
   - [4.5 Wallet & Earnings](#45-wallet--earnings)
   - [4.6 Rider Profile Management](#46-rider-profile-management)
   - [4.7 Notifications](#47-notifications)
   - [4.8 Online / Offline Toggle](#48-online--offline-toggle)
5. [Required Features — Not Yet Implemented](#5-required-features--not-yet-implemented)
6. [API Endpoints Reference](#6-api-endpoints-reference)
7. [State Management](#7-state-management)
8. [Routing Map](#8-routing-map)
9. [Third-Party Dependencies](#9-third-party-dependencies)
10. [Known Issues & Technical Debt](#10-known-issues--technical-debt)

---

## 1. Project Overview

BagyesRUSH Rider is the delivery-courier companion app for the BagyesRUSH platform. It enables registered riders to:

- Receive, accept, and fulfil delivery orders in real time
- Track their GPS location and share it with the platform during active trips
- Manage their account, documents, and earnings
- Toggle their availability (online/offline queue)

**Package ID:** `com.example.delivery_boy`
**Flutter SDK:** 3.38.6 · **Dart:** 3.10.7

---

## 2. Architecture Overview

```
lib/
├── main.dart                    # Entry point — ProviderScope + GoRouter
├── core/
│   ├── di/                      # GetIt service locator
│   ├── router/                  # GoRouter config + route constants
│   ├── services/                # UserSessionManager (SharedPreferences)
│   ├── network/                 # API endpoint constants + Dio client
│   ├── errors/                  # Failure class hierarchy
│   └── utils/                   # Auth interceptor
└── features/rider/
    ├── auth/                    # Login · Signup · OTP
    ├── dashboard/               # Shell tab navigator
    ├── orders/                  # New · Active · History
    ├── tracking/                # Maps · GPS · Polyline
    ├── wallet/                  # Earnings
    └── profile/                 # Profile view/edit + doc upload
```

Each feature follows the layered pattern:

```
feature/
├── models/          # Dart data classes (fromJson / toJson)
├── services/        # Raw Dio API calls
├── repositories/    # Interface + Impl (wraps services, returns Either<Failure, T>)
├── providers/       # Riverpod Notifier + immutable State class
└── views/
    ├── screens/     # Full-page widgets
    └── widgets/     # Reusable sub-widgets
```

---

## 3. Feature Status Matrix

| # | Feature | Status | Priority |
|---|---------|--------|----------|
| 1 | Phone + Password Login | Implemented | — |
| 2 | Phone + OTP Signup | Implemented | — |
| 3 | Session Persistence (JWT) | Implemented | — |
| 4 | Dashboard Tab Navigation | Implemented | — |
| 5 | New Order List & Accept/Reject | Implemented | — |
| 6 | Active Orders & Status Updates | Implemented | — |
| 7 | Order History | Implemented | — |
| 8 | Real-Time GPS Tracking | Implemented (partial) | — |
| 9 | Google Maps + Polyline Routing | Implemented (partial) | — |
| 10 | Online / Offline Queue Toggle | Implemented | — |
| 11 | Wallet / Earnings View | Implemented (partial) | — |
| 12 | Profile View | Implemented (partial) | — |
| 13 | Profile Edit Screen | **Not Implemented** | High |
| 14 | Document Upload UI | **Not Implemented** | High |
| 15 | Push Notifications | **Not Implemented** | High |
| 16 | In-App Notifications Screen | **Not Implemented** | Medium |
| 17 | Order Detail Sheet (full) | **Not Implemented** | High |
| 18 | Chat / Contact Customer | **Not Implemented** | Medium |
| 19 | Trip Start / Finish Flow | **Not Implemented** | High |
| 20 | Earnings Filter & Withdrawal | **Not Implemented** | Medium |
| 21 | Password Reset / Change | **Not Implemented** | Medium |
| 22 | Rate / Review Order | **Not Implemented** | Low |
| 23 | SOS / Emergency Button | **Not Implemented** | Low |
| 24 | App Settings Screen | **Not Implemented** | Low |

---

## 4. Feature Specifications

### 4.1 Authentication

**Status:** Implemented

#### 4.1.1 Login
- Screen: `RiderLoginScreen`
- Input: Phone number (with country-code picker) + Password
- API: `POST /couriers/login`
- On success: JWT token and user object saved to `SharedPreferences` via `UserSessionManager`; GoRouter redirects to `/dashboard`
- On failure: Error message shown via `fluttertoast`

#### 4.1.2 Signup + OTP Verification
- Screen 1: `RiderSignupScreen` — collect phone + password → `POST /otp/send`
- Screen 2: `RiderOtpScreen` — enter OTP → `POST /couriers/signup`
- On success: Session saved; navigate to dashboard

#### 4.1.3 Session Management
- Token stored under key `auth_token` in SharedPreferences
- User JSON stored under key `user_data`
- Dio interceptor attaches `Authorization: Bearer <token>` to every request
- HTTP 401 response triggers session clear + redirect to `/login`
- `UserSessionManager.isLoggedIn` drives GoRouter redirect guard

#### 4.1.4 Logout
- Called via `RiderProfileProvider.logout()`
- Clears SharedPreferences session, GoRouter redirects to `/login`

---

### 4.2 Dashboard & Navigation

**Status:** Implemented

- Shell route at `/dashboard` — `RiderDashboardScreen`
- Three bottom-navigation tabs:
  1. **Orders** — sub-pages: New Orders, Active Orders, Order History (TabBar within tab)
  2. **Wallet** — Earnings overview
  3. **Profile** — Rider profile & settings
- Nested route `/dashboard/map` for the map/tracking screen

---

### 4.3 Order Management

**Status:** Implemented (full detail sheet integration partial)

#### 4.3.1 New Orders
- Screen: `RiderNewOrdersScreen`
- Fetches available orders via `GET /orders/requested/:riderId`
- Each card shows: order ID, pickup & delivery address, payment mode, earnings
- Actions: **Accept** (`POST /orders/accept`) | **Reject** (`POST /orders/reject`)
- State provider: `riderNewOrdersProvider`

#### 4.3.2 Active Orders
- Screen: `RiderActiveOrdersScreen`
- Fetches in-progress orders via `GET /orders/active/:riderId`
- Actions per order:
  - **Update Status** (`PUT /orders/update`) — step through delivery statuses
  - **Set Trip** (`POST /orders/trip/set`) — mark trip as started
  - **Finish Trip** (`POST /orders/trip/finish`) — mark delivery complete
  - **Update Location** (`PUT /orders/location/update`) — push GPS coords for this order
- State provider: `riderActiveOrdersProvider`

#### 4.3.3 Order History
- Screen: `RiderOrderHistoryScreen`
- Fetches completed orders via `GET /orders/history/:riderId`
- Read-only list; shows final amounts, timestamps, addresses
- State provider: `riderOrderHistoryProvider`

#### 4.3.4 Order Detail Bottom Sheet
- Widget: `RiderOrderDetailSheet`
- Shows full order breakdown: customer info, coords, amounts, charges
- **Requires completion:** full button actions for trip flow (see §5)

---

### 4.4 Real-Time Location Tracking

**Status:** Partially Implemented

- Screen: `RiderMapScreen` at `/dashboard/map`
- Uses `google_maps_flutter` for map rendering
- Uses `location` package to stream device GPS
- Polyline routing via `flutter_polyline_points`
- Location update sent to backend via `PUT /orders/location/update` on each position change
- `RiderTrackingProvider` manages `LatLng position` + `bool isTracking`

**Required completion:**
- Background location tracking (continues when app is minimised)
- ETA calculation and display to rider
- Directions text overlay (turn-by-turn)

---

### 4.5 Wallet & Earnings

**Status:** Partially Implemented

- Screen: `RiderWalletScreen`
- Fetches earnings via `GET /earnings/user/:riderId`
- Displays total earnings + itemised earning list (`RiderEarningItem`)

**Required completion:**
- Earnings filter by date range / period
- Breakdown per order (linked to order detail)
- Withdrawal request flow (if platform supports it)
- Transaction history with pagination

---

### 4.6 Rider Profile Management

**Status:** Partially Implemented

- Screen: `RiderProfileScreen`
- Fetches profile via `GET /couriers/details/:id`
- Shows: name, phone, email, number plate, document status

**Required completion (see §5):**
- Edit profile screen (`/dashboard/profile/edit`) — currently a placeholder
- Document upload UI for: selfie, licences, insurance, roadworthy cert
- Profile completeness indicator / onboarding checklist
- Password change flow

---

### 4.7 Notifications

**Status:** Not Implemented

- Route `/dashboard/notifications` is a placeholder screen
- API endpoint defined: `GET /notifications/user/:id`

**Required (see §5):** Full notification screen + push notification integration

---

### 4.8 Online / Offline Toggle

**Status:** Implemented

- Toggle button on Dashboard header
- Uses `StateProvider<bool>` (`riderQueueProvider`) to track online state
- When online: rider appears in the dispatch queue and receives new orders
- When offline: rider is hidden from dispatch; no new orders assigned

---

## 5. Required Features — Not Yet Implemented

These features must be built before the app is production-ready.

### 5.1 Edit Profile Screen (HIGH)

**Route:** `/dashboard/profile/edit`
**Description:** Allow the rider to update their personal information.

Fields to support:
- Full name
- Email address
- Vehicle / number plate
- Profile photo (selfie) — image picker + `POST /couriers/upload/doc`
- Password change

Implementation notes:
- Pre-populate from `RiderUserModel` loaded by `RiderProfileProvider`
- On save: call `PUT /couriers/update`
- Show progress indicator during upload; show success/error toast

---

### 5.2 Document Upload UI (HIGH)

**Description:** Guided screen for uploading required compliance documents.

Documents required:
- Rider selfie / photo ID
- Driver's licence
- Motor insurance certificate
- Roadworthy / vehicle inspection cert

Implementation notes:
- Use `image_picker` (already a dependency) for camera or gallery
- Upload each doc individually via `POST /couriers/upload/doc`
- Show per-document status: Uploaded / Pending / Rejected
- Block order acceptance until all docs are approved (profile completeness check already in `RiderUserModel.isProfileComplete`)

---

### 5.3 Complete Trip Flow in Order Detail (HIGH)

**Description:** The order detail sheet must wire up the full lifecycle buttons.

Required states and transitions:
```
Accepted → Heading to Pickup → Arrived at Pickup → Picked Up → En Route → Delivered
```

Each transition:
- Calls `PUT /orders/update` with the new status
- May trigger `POST /orders/trip/set` or `POST /orders/trip/finish`
- Updates active order card UI immediately (optimistic update or re-fetch)

---

### 5.4 Push Notifications (HIGH)

**Description:** Riders must receive push alerts for new orders, cancellations, and messages.

Recommended implementation:
- Integrate **Firebase Cloud Messaging (FCM)** (`firebase_messaging` package)
- Register FCM device token on login; send to backend
- Handle foreground and background notification payloads
- Foreground: show in-app banner or `fluttertoast`
- Background/terminated: standard OS notification; tap navigates to relevant screen

Notification types to handle:
| Event | Action on tap |
|-------|--------------|
| New order available | Open New Orders tab |
| Order accepted confirmation | Open Active Orders tab |
| Order cancelled by customer | Show cancellation dialog |
| Payment received | Open Wallet screen |
| Document approved / rejected | Open Profile screen |
| General message | Open Notifications screen |

---

### 5.5 In-App Notifications Screen (MEDIUM)

**Route:** `/dashboard/notifications`
**Description:** Scrollable list of all past notifications for the rider.

- Fetch from `GET /notifications/user/:id`
- Mark as read on open / individual tap
- Empty state illustration when no notifications

---

### 5.6 Chat / Contact Customer (MEDIUM)

**Description:** Allow rider and customer to communicate during an active delivery.

Options (choose one based on backend capability):
- **In-app chat:** WebSocket or polling-based message thread per order
- **Phone call launcher:** `url_launcher` to dial customer number (`tel:` URI) — simplest approach, already dependency available

Recommended MVP: tap-to-call button on active order card / detail sheet using customer phone from `RiderCustomer.phone`.

---

### 5.7 Earnings Filter & Period View (MEDIUM)

**Description:** Allow rider to filter earnings by day / week / month / custom range.

- Date range picker (use `intl` for formatting, already a dependency)
- Summary stats per period: total trips, total earned, average per trip
- Paginated list of earning items

---

### 5.8 Password Reset Flow (MEDIUM)

**Description:** Allow rider to reset a forgotten password before login.

Suggested flow:
1. "Forgot password?" link on Login screen
2. Enter registered phone number
3. Receive OTP (reuse `POST /otp/send`)
4. Enter OTP + new password
5. `PUT /couriers/update` (or a dedicated reset endpoint)

---

### 5.9 Background Location Tracking (HIGH — required for tracking)

**Description:** The current GPS implementation stops when the app goes to background.

- Use `flutter_background_service` or `workmanager` package
- Continue streaming location to `PUT /orders/location/update` while active trip is ongoing
- Stop service when trip is finished or rider goes offline
- Handle Android foreground service permissions & iOS Background Modes

---

### 5.10 Onboarding / Profile Completeness Flow (MEDIUM)

**Description:** First-time login should guide the rider through completing their profile before they can accept orders.

- After signup, check `RiderUserModel.isProfileComplete`
- If incomplete, show a checklist/stepper screen
- Each step maps to a document upload or profile field
- Only show queue toggle and order tabs once profile is complete

---

### 5.11 App Settings Screen (LOW)

**Route:** `/dashboard/settings`
**Description:** Basic settings accessible from the Profile tab.

Settings to include:
- Language / locale selection
- Notification preferences (sound, vibration)
- App version info
- Privacy Policy / Terms of Service links
- Logout button (move from profile screen)

---

### 5.12 Order Rating / Review (LOW)

**Description:** After a trip is finished, prompt the rider to rate the experience.

- Simple 1–5 star rating dialog after `POST /orders/trip/finish` resolves successfully
- Optional text comment
- Submit to a ratings endpoint (requires new API endpoint if not present)

---

### 5.13 SOS / Emergency Button (LOW)

**Description:** Single tap to alert dispatch or call emergency services.

- Persistent floating button during active delivery
- Tap: confirm dialog → send SOS event to backend and/or dial emergency number

---

## 6. API Endpoints Reference

| Method | Endpoint | Feature | Status |
|--------|----------|---------|--------|
| POST | `/couriers/login` | Login | Integrated |
| POST | `/couriers/signup` | Signup | Integrated |
| POST | `/otp/send` | OTP | Integrated |
| GET | `/couriers/details/:id` | Profile | Integrated |
| PUT | `/couriers/update` | Edit Profile | **Required** |
| POST | `/couriers/upload/doc` | Doc Upload | **Required** |
| GET | `/orders/get` | Orders | Integrated |
| GET | `/orders/requested/:id` | New Orders | Integrated |
| GET | `/orders/active/:id` | Active Orders | Integrated |
| GET | `/orders/history/:id` | History | Integrated |
| POST | `/orders/accept` | Accept Order | Integrated |
| POST | `/orders/reject` | Reject Order | Integrated |
| PUT | `/orders/update` | Update Status | Partial |
| POST | `/orders/trip/set` | Start Trip | **Required** |
| POST | `/orders/trip/finish` | Finish Trip | **Required** |
| PUT | `/orders/location/update` | Location Update | Integrated |
| GET | `/earnings/user/:id` | Wallet | Integrated |
| GET | `/notifications/user/:id` | Notifications | **Required** |

---

## 7. State Management

All new features use **Riverpod** (`flutter_riverpod: ^2.6.1`).

**Pattern per feature:**
```dart
// 1. Immutable state
class FeatureState extends Equatable {
  final FeatureStatus status;
  final SomeModel? data;
  final String? errorMessage;
}

// 2. Notifier
class FeatureNotifier extends AsyncNotifier<FeatureState> {
  Future<void> load() async { ... }
}

// 3. Provider
final featureProvider = AsyncNotifierProvider<FeatureNotifier, FeatureState>(
  FeatureNotifier.new,
);
```

**Existing providers:**
| Provider | Location |
|----------|----------|
| `riderAuthProvider` | `features/rider/auth/viewmodels/` |
| `riderNewOrdersProvider` | `features/rider/orders/providers/` |
| `riderActiveOrdersProvider` | `features/rider/orders/providers/` |
| `riderOrderHistoryProvider` | `features/rider/orders/providers/` |
| `riderWalletProvider` | `features/rider/wallet/providers/` |
| `riderProfileProvider` | `features/rider/profile/providers/` |
| `riderTrackingProvider` | `features/rider/tracking/providers/` |
| `riderQueueProvider` | `features/rider/dashboard/` (StateProvider\<bool\>) |

---

## 8. Routing Map

```
/                            → Splash (auto-redirect)
/login                       → RiderLoginScreen
/signup                      → RiderSignupScreen
/otp                         → RiderOtpScreen
/dashboard                   → RiderDashboardScreen (shell)
  /dashboard/map             → RiderMapScreen
  /dashboard/profile/edit    → ProfileEditScreen          [REQUIRED]
  /dashboard/notifications   → NotificationsScreen        [REQUIRED]
  /dashboard/settings        → AppSettingsScreen          [OPTIONAL]
```

Guard: GoRouter redirect reads `UserSessionManager.isLoggedIn`:
- `false` → force `/login`
- `true` + at `/login` → force `/dashboard`

---

## 9. Third-Party Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^14.6.2 | Declarative routing |
| `dio` | ^5.7.0 | HTTP client |
| `get_it` | ^8.0.2 | Dependency injection |
| `equatable` | ^2.0.5 | Value equality for state |
| `dartz` | ^0.10.1 | Functional error handling |
| `shared_preferences` | ^2.3.3 | Local session storage |
| `google_maps_flutter` | ^2.9.0 | Map rendering |
| `flutter_polyline_points` | ^2.1.0 | Route drawing |
| `location` | ^7.0.0 | GPS access |
| `geocoding` | ^3.0.0 | Address ↔ coordinates |
| `url_launcher` | ^6.3.1 | Phone / external links |
| `image_picker` | ^1.1.2 | Camera / gallery |
| `intl` | ^0.19.0 | Date formatting |
| `fluttertoast` | ^8.2.8 | Toast messages |
| `font_awesome_flutter` | ^10.7.0 | Icons |
| `flutter_slidable` | ^3.1.1 | Swipeable list items |
| `flutter_spinkit` | ^5.2.1 | Loading indicators |
| `provider` | ^6.1.2 | Legacy (being removed) |

**To add for required features:**
| Package | Purpose |
|---------|---------|
| `firebase_messaging` | Push notifications (FCM) |
| `firebase_core` | Firebase initialisation |
| `flutter_background_service` | Background location tracking |
| `flutter_local_notifications` | Foreground notification banners |

---

## 10. Known Issues & Technical Debt

| # | Issue | Priority | Action |
|---|-------|----------|--------|
| 1 | Google Maps API key hardcoded in `rider_map_screen.dart` | High | Move to `AndroidManifest.xml` / `AppDelegate.swift` via environment config before production |
| 2 | API field typo: `motorIssurance` (should be `motorInsurance`) | Medium | Preserved for backend compatibility; fix when backend is corrected |
| 3 | Legacy `/pages/` directory still in codebase | Low | Delete after confirming no legacy route references remain |
| 4 | Both `http` and `dio` packages present | Low | Standardise on `dio`; remove `http` and `http_interceptor` |
| 5 | `provider` package retained alongside Riverpod | Low | Remove once `AppState` ChangeNotifier migration is complete |
| 6 | No unit or widget test coverage | High | Add tests for repositories, providers, and critical screens |
| 7 | No error boundary / global error handler | Medium | Add `FlutterError.onError` + `PlatformDispatcher.instance.onError` handlers |
| 8 | Background location stops when app minimised | High | Implement background service (see §5.9) |
| 9 | No loading/empty states on some screens | Medium | Add shimmer skeletons and empty-state illustrations for all list screens |
| 10 | API base URL is HTTP (not HTTPS) | High | Switch to HTTPS in production; update `baseurl.dart` and server config |

---

*Document generated: 2026-03-25 — BagyesRUSH Rider v1.0.0*

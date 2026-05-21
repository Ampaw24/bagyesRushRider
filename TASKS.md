# BagyesRUSH Rider — Development Task List

> Generated from code analysis against Budget Proposal (25 March 2026)  
> Last updated: 20 May 2026  
> Total: 17 tasks | Completed: 0 / 17

---

## PHASE 1 — Critical Fixes
> These MUST be done before any QA or testing session.

---

### TASK-01 — Activate Firebase Initialization
- **Status:** `[ ] Pending`
- **Feature:** #10 Push Notifications
- **File:** `lib/main.dart` (lines 25–27)
- **What to do:**
  - Uncomment the two lines inside `main()`:
    ```dart
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    ```
  - Add `google-services.json` to `android/app/`
  - Add `GoogleService-Info.plist` to `ios/Runner/`
- **Why:** Firebase is completely inactive. Push notifications, FCM token registration, and background message handling are all non-functional until this is done.

---

### TASK-02 — Re-enable Authentication Route Guard
- **Status:** `[ ] Pending`
- **Feature:** #01 Authentication System
- **File:** `lib/core/router/app_router.dart` (lines 44–52)
- **What to do:**
  - Uncomment the `isPublicRoute` block and the redirect guard inside the `redirect()` callback:
    ```dart
    final isPublicRoute = location == AppRoutes.splash ||
        location == AppRoutes.intro ||
        location == AppRoutes.login ||
        location == AppRoutes.signup ||
        location == AppRoutes.otp ||
        location == AppRoutes.vehicleInfo ||
        location == AppRoutes.vehicleDetails ||
        location == AppRoutes.forgotPassword;
    if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;
    ```
- **Why:** Currently any user can navigate directly to `/dashboard` without being logged in. The app is completely unprotected.

---

### TASK-03 — Secure the Google Maps API Key
- **Status:** `[ ] Pending`
- **Feature:** #06 Google Maps Navigation
- **File:** `lib/features/rider/tracking/views/screens/rider_map_screen.dart` (line 16)
- **What to do:**
  - Remove the hardcoded key:
    ```dart
    // REMOVE THIS:
    const _kGoogleMapsApiKey = 'AIzaSyA6QwaWqE4gtpQq4tTXGVIxLmeEeVKhYUc';
    ```
  - Replace with:
    ```dart
    const _kGoogleMapsApiKey = String.fromEnvironment('MAPS_API_KEY');
    ```
  - Run the app with:
    ```bash
    flutter run --dart-define=MAPS_API_KEY=<your-actual-key>
    ```
  - Add `MAPS_API_KEY` to your CI/CD secrets and build scripts
- **Why:** A hardcoded key is exposed in the APK binary and any git history. It can be extracted and abused for quota theft.

---

### TASK-04 — Call FcmService.initialize() at App Startup
- **Status:** `[ ] Pending`
- **Feature:** #10 Push Notifications
- **File:** `lib/main.dart`
- **What to do:**
  - After `Firebase.initializeApp()` inside `main()`, add:
    ```dart
    await FcmService.initialize(
      onNotificationTap: (route) {
        // Navigate using a global navigator key or store the route
        // and redirect once the router is ready
      },
    );
    ```
- **Why:** `FcmService` in `lib/core/services/fcm_service.dart` is a complete implementation but is never called anywhere — no foreground or background messages will ever be received.

---

### TASK-05 — Register FCM Token After Login and Signup
- **Status:** `[ ] Pending`
- **Feature:** #10 Push Notifications
- **File:** `lib/features/rider/auth/viewmodels/rider_auth_viewmodel.dart`
- **What to do:**
  - Inside the `login()` method, after a successful response, add:
    ```dart
    await FcmService.registerToken(dio, userId);
    ```
  - Do the same inside `signup()` after the user is created
- **Why:** The backend needs the FCM device token to send push notifications to this specific rider. Without this step, the server has no way to target the device.

---

### TASK-06 — Remove Legacy MultiProvider Wrapper
- **Status:** `[ ] Pending`
- **Files:**
  - `lib/main.dart`
  - `lib/states/app.state.dart`
- **What to do:**
  - In `main.dart`, remove the `legacy.MultiProvider` wrapper so only `ProviderScope` remains:
    ```dart
    // REMOVE:
    child: legacy.MultiProvider(
      providers: [legacy.ChangeNotifierProvider(create: (_) => AppState())],
      child: const BagyesRushApp(),
    ),
    // KEEP:
    child: const BagyesRushApp(),
    ```
  - Delete `lib/states/app.state.dart`
  - Remove the `provider` import from `main.dart` if no longer used
- **Why:** Two competing state management systems (Riverpod + old Provider) in the widget tree is confusing and adds unnecessary overhead. All new features use Riverpod only.

---

## PHASE 2 — Missing Features
> Functionality specified in the budget proposal that has not been built yet.

---

### TASK-07 — Wallet: Fund Withdrawal Flow
- **Status:** `[ ] Pending`
- **Feature:** #08 Wallet & Earnings Dashboard (`GHS 350`)
- **Files to create/edit:**
  - `lib/features/rider/wallet/views/screens/rider_withdrawal_screen.dart` ← **NEW**
  - `lib/features/rider/wallet/services/rider_wallet_api_service.dart` ← add `withdraw()` method
  - `lib/features/rider/wallet/repositories/rider_wallet_repository.dart` ← add `withdraw()` method
  - `lib/features/rider/wallet/views/screens/rider_wallet_screen.dart` ← add Withdraw button
- **What to do:**
  - Build a `RiderWithdrawalScreen` with:
    - Amount input field (GHS)
    - Mobile money number field
    - Network/provider selector (MTN, Vodafone, AirtelTigo)
    - Submit button that calls the withdrawal API
  - Add a `Withdraw` button to the wallet gradient header
  - Route: add `withdrawal` route under `/dashboard` in `app_router.dart`
- **Why:** The proposal explicitly includes "enable fund withdrawal functionality" — this entire flow is missing from the codebase.

---

### TASK-08 — Order History: Date Range Filter
- **Status:** `[ ] Pending`
- **Feature:** #05 Order History (`GHS 250`)
- **File:** `lib/features/rider/orders/views/screens/rider_order_history_screen.dart`
- **What to do:**
  - Add filter chips above the list (same pattern as wallet screen):
    ```dart
    // Chips: All | Today | This Week | This Month
    ```
  - Filter `state.orders` client-side by comparing `order.createdAt` to the selected period
  - Add a `HistoryPeriod` enum to the orders provider similar to `EarningsPeriod`
- **Why:** The proposal specifies "filtering options" for completed deliveries. Currently the history shows all orders with no way to narrow by date.

---

### TASK-09 — SOS Button: Admin API Notification
- **Status:** `[ ] Pending`
- **Feature:** #17 SOS Emergency Button (`GHS 150`)
- **File:** `lib/core/widgets/sos_floating_button.dart`
- **What to do:**
  - After the user confirms the SOS dialog, send an API alert before/alongside the phone call:
    ```dart
    await dio.post('/sos-alert', data: {
      'riderId': userId,
      'latitude': currentLat,
      'longitude': currentLng,
      'timestamp': DateTime.now().toIso8601String(),
    });
    ```
  - Replace hardcoded `tel:911` with a configurable dispatch/emergency number from remote config or constants
  - Add an SOS API service method + repository method
- **Why:** The proposal states the button should "notify an administrator." Currently it only opens a phone dialer with no server record created and no admin alert sent.

---

### TASK-10 — New Orders: Auto-Refresh
- **Status:** `[ ] Pending`
- **Feature:** #03 New Order Management (`GHS 300`)
- **File:** `lib/features/rider/orders/views/screens/rider_new_orders_screen.dart`
- **What to do:**
  - Add a `Timer` in `initState` that fires every 15 seconds while the screen is active:
    ```dart
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.read(newOrdersProvider.notifier).load();
    });
    ```
  - Cancel the timer in `dispose()`:
    ```dart
    _timer?.cancel();
    ```
  - Only poll when the rider is online (`ref.read(riderQueueProvider)`)
- **Why:** Riders currently must manually pull-to-refresh to see incoming orders. New orders should appear automatically in near-real-time without any action from the rider.

---

### TASK-11 — Earnings: Charts / Visualisation
- **Status:** `[ ] Pending`
- **Feature:** #13 Earnings Filter & Analytics (`GHS 300`)
- **File:** `lib/features/rider/wallet/views/screens/rider_wallet_screen.dart`
- **What to do:**
  - Add `fl_chart` to `pubspec.yaml`:
    ```yaml
    fl_chart: ^0.69.0
    ```
  - Below the stat cards, add a `BarChart` or `LineChart` showing daily earnings for the selected period
  - Map `state.filteredEarnings` into `BarChartGroupData` using the earning date as the X-axis
- **Why:** The proposal specifies "visualise earnings by day, week, or month." Currently only a text list is shown — no graphical chart exists.

---

### TASK-12 — Customer Contact: In-App Chat / WhatsApp
- **Status:** `[ ] Pending`
- **Feature:** #12 Customer Contact Feature (`GHS 300`)
- **Files:**
  - `lib/features/rider/tracking/views/screens/rider_map_screen.dart`
  - `lib/features/rider/orders/views/widgets/rider_order_detail_sheet.dart`
- **What to do:**
  - Add a WhatsApp deep-link button alongside the existing call button:
    ```dart
    await launchUrl(Uri.parse(
      'https://wa.me/$phoneNumber?text=Hi, I am your BagyesRUSH rider'));
    ```
  - Also add the call + chat buttons to `RiderOrderDetailSheet` so they are accessible without going to the map screen
- **Why:** The proposal includes "initiate in-app chat with customers." Currently only a `tel:` phone call is wired, and only from the map screen.

---

## PHASE 3 — Improvements & Enhancements
> Polish, reliability, and cleanup tasks.

---

### TASK-13 — GPS: Background Location Tracking
- **Status:** `[ ] Pending`
- **Feature:** #07 Real-Time GPS Tracking (`GHS 600`)
- **Files:**
  - `lib/features/rider/tracking/providers/rider_tracking_providers.dart`
  - `lib/features/rider/tracking/services/rider_tracking_api_service.dart`
- **What to do:**
  - Add `workmanager` or `flutter_background_service` to `pubspec.yaml`
  - Configure a background task that continues the GPS stream when the app is minimized
  - Register the background task when `startTracking()` is called
  - Cancel it in `stopTracking()`
  - Request `ACCESS_BACKGROUND_LOCATION` permission on Android
- **Why:** Location tracking currently stops the moment the rider minimizes the app. The backend loses the rider's live position mid-delivery, breaking the customer tracking experience.

---

### TASK-14 — Trip Rating: Submit to API
- **Status:** `[ ] Pending`
- **Feature:** #11 Trip Lifecycle Flow (`GHS 500`)
- **File:** `lib/features/rider/orders/views/screens/rider_active_orders_screen.dart`
- **What to do:**
  - In `_RatingSheetState`, on "Submit Rating" tap, POST to the backend:
    ```dart
    await dio.post('/order/rate', data: {
      'orderId': widget.orderId,
      'rating': _rating,
      'comment': _commentCtrl.text.trim(),
    });
    ```
  - Add a `rateOrder()` method to the orders repository and API service
  - Show a success toast after submission
- **Why:** The star rating UI is built and visible after every delivery, but the submit button only closes the sheet. No rating data is ever sent to the server.

---

### TASK-15 — Delete Legacy Pages Directory
- **Status:** `[ ] Pending`
- **Files to delete:**
  - `lib/pages/` (entire directory)
  - `lib/states/app.state.dart`
  - `lib/services/app.services.dart`
  - `lib/components/` (entire directory)
- **What to do:**
  - Grep for any remaining imports of these files in `lib/`:
    ```bash
    grep -r "lib/pages\|app.state\|app.services\|lib/components" lib/
    ```
  - Remove any remaining references
  - Delete the directories
- **Why:** All old screens in `lib/pages/` have been replaced by the clean-architecture screens in `lib/features/`. Dead code inflates the bundle, causes confusion, and makes the codebase harder to navigate.

---

### TASK-16 — App Version: Use Build-Time Constant
- **Status:** `[ ] Pending`
- **File:** `lib/features/rider/settings/views/screens/rider_settings_screen.dart` (~line 82)
- **What to do:**
  - Add `package_info_plus` to `pubspec.yaml`:
    ```yaml
    package_info_plus: ^8.0.0
    ```
  - Replace the hardcoded `'1.0.0'` string:
    ```dart
    // Replace:
    trailing: Text('1.0.0', ...)
    // With:
    FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snap) => Text(snap.data?.version ?? '—', ...),
    )
    ```
- **Why:** The version string must match `pubspec.yaml` automatically. A hardcoded value will fall out of sync with every release and require a manual code change.

---

### TASK-17 — Environment Configuration (Dev / Staging / Prod)
- **Status:** `[ ] Pending`
- **Files:**
  - `lib/constant/baseurl.dart`
  - `android/app/` — add `google-services.json` per flavor
  - `ios/Runner/` — add `GoogleService-Info.plist` per flavor
- **What to do:**
  - Define base URLs per environment using `--dart-define`:
    ```dart
    const baseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://api.bagyesrush.com',
    );
    ```
  - Set up Flutter flavors (or separate build scripts) for `dev`, `staging`, `prod`
  - Use a separate Firebase project per environment with its own `google-services.json`
  - Document the build commands in `README.md`
- **Why:** A single hardcoded base URL means dev builds hit production data. This is a data integrity and security risk during active development and testing.

---

## Progress Tracker

| Task | Description | Phase | Status |
|------|-------------|-------|--------|
| TASK-01 | Activate Firebase initialization | 1 — Critical | `[ ] Pending` |
| TASK-02 | Re-enable authentication route guard | 1 — Critical | `[ ] Pending` |
| TASK-03 | Secure the Google Maps API key | 1 — Critical | `[ ] Pending` |
| TASK-04 | Call FcmService.initialize() at startup | 1 — Critical | `[ ] Pending` |
| TASK-05 | Register FCM token after login/signup | 1 — Critical | `[ ] Pending` |
| TASK-06 | Remove legacy MultiProvider wrapper | 1 — Critical | `[ ] Pending` |
| TASK-07 | Wallet — Fund Withdrawal Flow | 2 — Features | `[ ] Pending` |
| TASK-08 | Order History — Date Range Filter | 2 — Features | `[ ] Pending` |
| TASK-09 | SOS Button — Admin API Notification | 2 — Features | `[ ] Pending` |
| TASK-10 | New Orders — Auto-Refresh | 2 — Features | `[ ] Pending` |
| TASK-11 | Earnings — Charts / Visualisation | 2 — Features | `[ ] Pending` |
| TASK-12 | Customer Contact — WhatsApp / Chat | 2 — Features | `[ ] Pending` |
| TASK-13 | GPS — Background Location Tracking | 3 — Polish | `[ ] Pending` |
| TASK-14 | Trip Rating — Submit to API | 3 — Polish | `[ ] Pending` |
| TASK-15 | Delete legacy pages directory | 3 — Polish | `[ ] Pending` |
| TASK-16 | App Version — Build-time constant | 3 — Polish | `[ ] Pending` |
| TASK-17 | Environment configuration | 3 — Polish | `[ ] Pending` |

**Completed: 0 / 17**

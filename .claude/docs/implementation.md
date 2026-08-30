# BagyesRUSH — Rider App Implementation Guide

> Mirror the patterns from the vendor/consumer side exactly. This document is the reference for building the **rider (courier)** side of the app.

---

## Table of Contents

1. [Folder Structure](#1-folder-structure)
2. [Architecture Overview](#2-architecture-overview)
3. [Theming & Colors](#3-theming--colors)
4. [Dependency Injection (GetIt)](#4-dependency-injection-getit)
5. [Network Layer (Dio)](#5-network-layer-dio)
6. [API Endpoints](#6-api-endpoints)
7. [Error Handling Pattern](#7-error-handling-pattern)
8. [MVVM — State Management Patterns](#8-mvvm--state-management-patterns)
9. [Complete Feature Template (All Layers)](#9-complete-feature-template-all-layers)
10. [Widget Design Patterns](#10-widget-design-patterns)
11. [Navigation (GoRouter)](#11-navigation-gorouter)
12. [Session Management](#12-session-management)
13. [Known Inconsistencies — Do Not Replicate](#13-known-inconsistencies--do-not-replicate)
14. [Checklist: Adding a New Rider Feature](#14-checklist-adding-a-new-rider-feature)

---

## 1. Folder Structure

Create the rider app feature modules following this layout (mirrors `lib/features/vendor_wallet/` and `lib/src/vendor/`):

```
lib/
├── features/
│   └── rider/                          ← NEW: all rider feature modules live here
│       ├── auth/
│       │   ├── models/
│       │   │   └── rider_user_model.dart
│       │   ├── repositories/
│       │   │   ├── rider_auth_repository.dart        ← abstract contract
│       │   │   └── rider_auth_repository_impl.dart   ← Dio implementation
│       │   ├── viewmodels/
│       │   │   └── rider_auth_viewmodel.dart
│       │   └── views/
│       │       ├── rider_login_view.dart
│       │       └── rider_signup_view.dart
│       │
│       ├── dashboard/
│       │   ├── models/
│       │   │   └── rider_stats_model.dart
│       │   ├── repositories/
│       │   │   ├── rider_dashboard_repository.dart
│       │   │   └── rider_dashboard_repository_impl.dart
│       │   ├── providers/
│       │   │   └── rider_dashboard_providers.dart    ← Riverpod
│       │   └── views/
│       │       ├── screens/
│       │       │   └── rider_dashboard_screen.dart
│       │       └── widgets/
│       │
│       ├── orders/
│       │   ├── models/
│       │   │   └── rider_order_model.dart
│       │   ├── repositories/
│       │   │   ├── rider_orders_repository.dart
│       │   │   └── rider_orders_repository_impl.dart
│       │   ├── providers/
│       │   │   └── rider_orders_providers.dart
│       │   └── views/
│       │       ├── screens/
│       │       │   ├── rider_active_orders_screen.dart
│       │       │   └── rider_order_detail_screen.dart
│       │       └── widgets/
│       │           └── rider_order_card.dart
│       │
│       ├── wallet/
│       │   ├── models/
│       │   │   ├── rider_wallet_model.dart
│       │   │   └── rider_transaction_model.dart
│       │   ├── repositories/
│       │   │   ├── rider_wallet_repository.dart
│       │   │   └── rider_wallet_repository_impl.dart
│       │   ├── providers/
│       │   │   └── rider_wallet_providers.dart
│       │   └── views/
│       │       ├── screens/
│       │       │   ├── rider_wallet_screen.dart
│       │       │   └── rider_transaction_history_screen.dart
│       │       └── widgets/
│       │           ├── rider_balance_card.dart
│       │           └── rider_transaction_tile.dart
│       │
│       ├── profile/
│       │   ├── models/
│       │   ├── repositories/
│       │   ├── providers/
│       │   └── views/
│       │
│       └── tracking/
│           ├── models/
│           ├── repositories/
│           ├── providers/
│           └── views/
│
├── constant/                           ← Already exists — reuse everything here
│   ├── app_theme.dart                  ← AppColors, AppTheme
│   ├── constant.dart                   ← Text styles, spacing
│   ├── baseurl.dart                    ← BASEURL getter
│   └── typedef.dart                    ← ResultFuture, DataMap, etc.
│
├── core/                               ← Already exists — reuse everything here
│   ├── di/service_locator.dart         ← Register rider services here
│   ├── network/api_endpoints.dart      ← Add rider endpoints here
│   ├── errors/failures.dart            ← Already has all Failure classes
│   ├── utils/network_utility.dart      ← Shared Dio instance
│   ├── viewmodel/viewmodel.dart        ← Base ViewModel<T> if using Provider
│   └── widgets/custom_dialogs.dart     ← Reuse these dialogs
```

---

## 2. Architecture Overview

The app uses **Clean Architecture** with a **hybrid state management** approach:

```
View  ←→  StateNotifier/ViewModel  ←→  Repository (abstract)
                                            ↓
                                   RepositoryImpl → ApiService
                                            ↓
                                      Dio (sl<Dio>(), see §5)
                                            ↓
                                         REST API
```

### Two Patterns — Know When to Use Each

| Situation | Use |
|-----------|-----|
| New rider feature | **Riverpod** (`NotifierProvider` / `StateNotifierProvider`) |
| Adapting an existing Provider-based screen | **Provider** (`ViewModel<T>` + `ChangeNotifier`) |
| Simple read-only data | **Riverpod** `FutureProvider` |
| Complex multi-step flow (e.g. order acceptance) | **Riverpod** `StateNotifierProvider.autoDispose` |

For all new rider features, **use Riverpod**. It is the modern pattern in this codebase.

---

## 3. Theming & Colors

**Never hardcode colors.** Always use `AppColors` from `lib/constant/app_theme.dart`.

### Color Reference

```dart
// Import
import 'package:bagyesrushappusernew/constant/app_theme.dart';

// Backgrounds
AppColors.scaffold          // Dark background (used as Scaffold bg)
AppColors.surface           // Warm cream — card areas
AppColors.surfaceVariant    // Light gray — input fill
AppColors.card              // Pure white

// Brand
AppColors.primary           // Red #D32F2F — buttons, active state, CTA
AppColors.primaryLight      // #EF5350
AppColors.primaryDark       // #B71C1C
AppColors.accent            // Amber #F59E0B — earnings, highlights
AppColors.secondary         // Charcoal #2D3748 — secondary actions

// Text
AppColors.textPrimary       // #1A202C — headings, body
AppColors.textSecondary     // #718096 — subtitles, metadata
AppColors.textHint          // #A0AEC0 — placeholders, hints

// Borders
AppColors.border            // #E2E8F0 — card borders
AppColors.divider           // #EDF2F7 — list dividers

// Feedback
AppColors.success           // #38A169 — completed, online
AppColors.error             // #E53E3E — failed, offline
AppColors.warning           // #DD6B20 — pending
AppColors.info              // #3182CE — informational
```

### Text Styles

```dart
// Import
import 'package:bagyesrushappusernew/constant/constant.dart';

splashBigTextStyle      // 40px Pacifico, primary color — splash only
blackHeadingTextStyle   // 17px Mukta w500 — section headings
blackSmallTextStyle     // 15px Mukta — body text
appBarTextStyle         // 18px Mukta w500, primary color — AppBar title

// Inline custom styles — follow this pattern:
const TextStyle(
  fontFamily: 'Mukta',         // Always use Mukta for body
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
)
```

### Spacing Constants

```dart
const double fixPadding = 10.0;            // base unit
const double buttonHeight = 70;
const SizedBox heightSpace = SizedBox(height: 10.0);
const SizedBox widthSpace = SizedBox(width: 10.0);

// Common multiples
EdgeInsets.all(fixPadding * 2)             // 20px all sides
EdgeInsets.symmetric(horizontal: 20, vertical: 16)
```

### Applying the Theme

```dart
// In MaterialApp — already done in main.dart
MaterialApp.router(
  theme: AppTheme.light,   // from lib/constant/app_theme.dart
  ...
)
```

---

## 4. Dependency Injection (GetIt)

File: `lib/core/di/service_locator.dart`

Add rider registrations to the existing `init()` function. Follow the established ordering: **services → repositories → viewmodels/notifiers**.

```dart
// Inside the existing init() function in service_locator.dart

// ── Rider API Services ──
sl.registerLazySingleton(() => RiderAuthApiService(sl()));     // sl() = Dio (shared singleton, see §5)
sl.registerLazySingleton(() => RiderOrdersApiService(sl()));
sl.registerLazySingleton(() => RiderWalletApiService(sl()));
sl.registerLazySingleton(() => RiderDashboardApiService(sl()));

// ── Rider Repositories ──
sl.registerLazySingleton<RiderAuthRepository>(
  () => RiderAuthRepositoryImpl(sl()),
);
sl.registerLazySingleton<RiderOrdersRepository>(
  () => RiderOrdersRepositoryImpl(sl()),
);
sl.registerLazySingleton<RiderWalletRepository>(
  () => RiderWalletRepositoryImpl(sl()),
);

// ── Rider ViewModels (Provider pattern — new instance each time) ──
sl.registerFactory(() => RiderAuthViewModel(sl(), sl()));

// Riverpod Notifiers access sl() directly in their build() method.
// No registration needed for Riverpod notifiers.
```

### Registration Rules

| What | Registration |
|------|-------------|
| Services (Dio wrappers, storage) | `registerLazySingleton` |
| Repositories | `registerLazySingleton` |
| ViewModels (Provider / ChangeNotifier), per-screen | `registerFactory` |
| ViewModel that must be shared app-wide (e.g. an in-progress-delivery ViewModel read from multiple screens) | `registerLazySingleton` |
| Riverpod Notifiers | Not registered — use `sl<Repo>()` inside `build()` |

### Two Registration Sites — Which One to Extend

Registration is split across **two files** in this codebase; for ordinary rider features, always extend the first one:

| File | When it runs | What goes here |
|---|---|---|
| `lib/core/di/service_locator.dart` (`sl.init()`) | Once, at app boot, right after `dotenv`/Firebase init | **Default for all new rider services/repositories/viewmodels.** Plain `registerLazySingleton`/`registerFactory` calls, no guards needed. |
| `lib/core/services/app_initializer.dart` (`AppInitializer.initialize()`) | Also at boot, immediately after `sl.init()`, and awaited before `runApp` | Reserved for the small chain that must exist and be restored **before the first frame renders** (secure storage → `CacheHelper` → `Dio` → `CurrentUserProvider` → `AuthRepository` → `AuthViewmodel.restoreSession()`). Uses eager `registerSingleton` guarded by `if (!_sl.isRegistered<T>())` so it's safe to call more than once. Do not add ordinary rider features here — only touch this file if a rider service genuinely needs to be ready synchronously before the splash screen resolves. |

### Accessing the Container

```dart
import 'package:bagyesrushappusernew/core/di/service_locator.dart';

// Inside a Riverpod Notifier build():
final _repo = sl<RiderOrdersRepository>();

// In a widget (Provider pattern):
final vm = sl<RiderAuthViewModel>();
```

---

## 5. Network Layer (Dio)

**Two `Dio` clients coexist in this codebase — use the right one.**

| Client | Where it's built | Who uses it | Status |
|---|---|---|---|
| `sl<Dio>()` | `AppInitializer._configureDio()` in `lib/core/services/app_initializer.dart`, registered eagerly as a GetIt singleton | `AuthRepository`, `CartRepository`, `OrdersRepository`, `ParcelRepository`, `PaymentRepository` — the newest, most consistent repositories | **Use this for all new rider repositories.** |
| `NetworkUtility().dio` (`lib/core/utils/network_utility.dart`) | Builds its own separate `Dio` instance internally | `HomeRepository`, `NotificationRepository`, vendor/onboarding repositories | Legacy — do not extend, kept only for existing vendor/onboarding code. |

Both attach an auth-header interceptor reading `Cache.instance.sessionToken` and handle 401s by clearing the session and redirecting to login, so behavior is equivalent — but **new rider API services must inject `Dio` directly via `sl<Dio>()`**, matching the pattern used by `auth`/`cart`/`orders`. Do not instantiate a new `Dio()` and do not route through `NetworkUtility`.

### Creating an API Service (constructor-injected `Dio`)

Keep the API-service layer from §1's folder structure (it stays useful as the one place that knows raw endpoint shapes), but source its `Dio` from `sl<Dio>()`, not `NetworkUtility`:

```dart
// lib/features/rider/orders/services/rider_orders_api_service.dart

import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import '../models/rider_order_model.dart';

class RiderOrdersApiService {
  RiderOrdersApiService(Dio client) : _dio = client;
  final Dio _dio;

  Future<List<RiderOrderModel>> fetchActiveOrders() async {
    final response = await _dio.get(ApiEndpoints.riderActiveOrders);
    final List data = response.data['data'] as List;
    return data.map((e) => RiderOrderModel.fromJson(e)).toList();
  }

  Future<RiderOrderModel> acceptOrder(String orderId) async {
    final response = await _dio.patch(
      ApiEndpoints.riderAcceptOrder(orderId),
      data: {'status': 'accepted'},
    );
    return RiderOrderModel.fromJson(response.data['data']);
  }
}
```

Register it with `sl.registerLazySingleton(() => RiderOrdersApiService(sl()))` — GetIt resolves the `Dio` parameter from the already-registered `sl<Dio>()` singleton automatically (see §4's updated registration example and §9 for how the repository/repository-impl layers wrap this service).

### Dio Configuration (already set up — reference only)

- **Base URL:** reads `BASEURL` from `.env` → `Config.devBaseUrl` (debug) / `Config.baseUrl` (release)
- **Timeouts:** 30s connect, 30s receive
- **Auth header:** injected automatically via interceptor if session token exists (`Cache.instance.sessionToken`)
- **401 handling:** auto-clears session + redirect to login via `appRouter.go(AppRoutes.login)`
- **Logging:** `LogInterceptor` in debug builds only

---

## 6. API Endpoints

File: `lib/core/network/api_endpoints.dart`

Add rider endpoints to the existing `abstract final class ApiEndpoints`:

```dart
abstract final class ApiEndpoints {
  // ...existing vendor/customer endpoints...

  // ── Rider Auth ──────────────────────────────────────────────────
  static const String riderSignup    = '/riders/signup';
  static const String riderLogin     = '/riders/login';
  static const String riderProfile   = '/riders/profile';

  // ── Rider Orders ─────────────────────────────────────────────────
  static const String riderActiveOrders  = '/riders/orders/active';
  static const String riderOrderHistory  = '/riders/orders/history';

  static String riderOrderDetail(String id)  => '/riders/orders/$id';
  static String riderAcceptOrder(String id)  => '/riders/orders/$id/accept';
  static String riderOrderStatus(String id)  => '/riders/orders/$id/status';
  static String riderDeclineOrder(String id) => '/riders/orders/$id/decline';

  // ── Rider Wallet ─────────────────────────────────────────────────
  static const String riderWallet              = '/riders/wallet';
  static const String riderWalletTransactions  = '/riders/wallet/transactions';
  static const String riderWalletWithdraw      = '/riders/wallet/withdraw';

  // ── Rider Location ───────────────────────────────────────────────
  static const String riderLocationUpdate = '/riders/location';
  static const String riderAvailability   = '/riders/availability';
}
```

---

## 7. Error Handling Pattern

File: `lib/core/errors/failures.dart` — already contains all needed classes.

### Always Return `Either<Failure, T>`

Use the `ResultFuture<T>` typedef from `lib/constant/typedef.dart`:

```dart
// typedef.dart already defines:
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef DataMap = Map<String, dynamic>;
```

### Standard Repository Error Wrapper

Copy this `_run` helper into every `RepositoryImpl`:

```dart
Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } on DioException catch (e) {
    final message = e.response?.data?['message'] as String?
        ?? e.message
        ?? 'Request failed';
    return Left(ServerFailure(message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### Consuming Errors in the Notifier

```dart
final result = await _repo.fetchActiveOrders();
result.fold(
  (failure) => state = state.copyWith(
    status: RiderOrdersStatus.error,
    errorMessage: failure.message,
  ),
  (orders) => state = state.copyWith(
    status: RiderOrdersStatus.loaded,
    orders: orders,
  ),
);
```

### Showing Errors in the View

```dart
// In ConsumerStatefulWidget build():
ref.listen<RiderOrdersState>(riderOrdersProvider, (_, next) {
  if (next.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.errorMessage!)),
    );
  }
});
```

---

## 8. MVVM — State Management Patterns

### Pattern A: Riverpod Notifier (use for all new features)

#### Step 1 — State Class

```dart
// lib/features/rider/orders/providers/rider_orders_providers.dart

import 'package:equatable/equatable.dart';
import '../models/rider_order_model.dart';

enum RiderOrdersStatus { initial, loading, loaded, error }

class RiderOrdersState extends Equatable {
  final RiderOrdersStatus status;
  final List<RiderOrderModel> orders;
  final String? errorMessage;

  const RiderOrdersState({
    this.status = RiderOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  RiderOrdersState copyWith({
    RiderOrdersStatus? status,
    List<RiderOrderModel>? orders,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, errorMessage];
}
```

#### Step 2 — Notifier

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import '../../repositories/rider_orders_repository.dart';
import 'rider_orders_state.dart';  // or inline above

class RiderOrdersNotifier extends Notifier<RiderOrdersState> {
  late final RiderOrdersRepository _repo;

  @override
  RiderOrdersState build() {
    _repo = sl<RiderOrdersRepository>();     // ← GetIt access
    return const RiderOrdersState();
  }

  Future<void> load() async {
    state = state.copyWith(status: RiderOrdersStatus.loading, clearError: true);

    final result = await _repo.fetchActiveOrders();
    result.fold(
      (failure) => state = state.copyWith(
        status: RiderOrdersStatus.error,
        errorMessage: failure.message,
      ),
      (orders) => state = state.copyWith(
        status: RiderOrdersStatus.loaded,
        orders: orders,
      ),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    final result = await _repo.acceptOrder(orderId);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (updated) {
        final newList = state.orders
            .map((o) => o.id == orderId ? updated : o)
            .toList();
        state = state.copyWith(orders: newList);
      },
    );
  }

  void refresh() => load();
}

// Provider — at file bottom
final riderOrdersProvider =
    NotifierProvider<RiderOrdersNotifier, RiderOrdersState>(
  RiderOrdersNotifier.new,
);

// Derived providers
final activeOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(riderOrdersProvider).orders.length;
});
```

#### Step 3 — View

```dart
// lib/features/rider/orders/views/screens/rider_active_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../providers/rider_orders_providers.dart';
import '../widgets/rider_order_card.dart';

class RiderActiveOrdersScreen extends ConsumerStatefulWidget {
  const RiderActiveOrdersScreen({super.key});

  @override
  ConsumerState<RiderActiveOrdersScreen> createState() =>
      _RiderActiveOrdersScreenState();
}

class _RiderActiveOrdersScreenState
    extends ConsumerState<RiderActiveOrdersScreen> {

  @override
  void initState() {
    super.initState();
    // Trigger data load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderOrdersProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderOrdersProvider);

    // Side-effect listener — show snackbar on error
    ref.listen<RiderOrdersState>(riderOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Active Orders')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RiderOrdersState state) {
    // Loading
    if (state.status == RiderOrdersStatus.initial ||
        state.status == RiderOrdersStatus.loading) {
      return const _OrdersSkeleton();
    }

    // Error
    if (state.status == RiderOrdersStatus.error) {
      return _ErrorView(
        message: state.errorMessage ?? 'Failed to load orders',
        onRetry: () => ref.read(riderOrdersProvider.notifier).load(),
      );
    }

    // Empty
    if (state.orders.isEmpty) {
      return const _EmptyOrdersView();
    }

    // Success
    return RefreshIndicator(
      onRefresh: () => ref.read(riderOrdersProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => RiderOrderCard(order: state.orders[i]),
      ),
    );
  }
}
```

---

### Pattern B: Provider ViewModel (use when adapting older screens)

This mirrors `lib/src/auth` exactly — a **sealed-class state hierarchy**, not a mutable state object with `copyWith`. This is the preferred shape for anything on the Provider/`ViewModel<T>` path (the plain-`copyWith` mutable-state style still found in a couple of legacy screens, e.g. `lib/src/onboarding`, is older and should not be copied for new rider code).

```dart
// lib/features/rider/auth/viewmodels/rider_auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';

sealed class RiderAuthState extends Equatable {
  const RiderAuthState();
  @override
  List<Object> get props => [];
}

final class RiderAuthInitial extends RiderAuthState {
  const RiderAuthInitial();
}

final class RiderAuthLoading extends RiderAuthState {
  const RiderAuthLoading();
}

final class RiderLoggedIn extends RiderAuthState {
  const RiderLoggedIn();
}

final class RiderAuthError extends RiderAuthState {
  const RiderAuthError({required this.message, required this.title});
  RiderAuthError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object> get props => [message, title];
}
```

```dart
// lib/features/rider/auth/viewmodels/rider_auth_viewmodel.dart

import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../repositories/rider_auth_repository.dart';
import 'rider_auth_state.dart';

class RiderAuthViewModel extends ViewModel<RiderAuthState> {
  RiderAuthViewModel({required RiderAuthRepository repository})
      : _repository = repository,
        super(const RiderAuthInitial());

  final RiderAuthRepository _repository;

  Future<void> login({required String phone, required String password}) async {
    emit(const RiderAuthLoading());
    final result = await _repository.login(phone: phone, password: password);
    result.fold(
      (failure) => emit(RiderAuthError.fromFailure(failure)),
      (_) => emit(const RiderLoggedIn()),
    );
  }
}
```

`ViewModel<T>` (`lib/core/viewmodel/viewmodel.dart`) is the shared base — it holds `state`/`emit()` and wraps `notifyListeners()` in a frame-safe post-frame callback; do not extend `ChangeNotifier` directly for new rider ViewModels.

**Consuming in a View** — register the ViewModel in `service_locator.dart` (`registerFactory` for per-screen, `registerLazySingleton` if shared app-wide) and either add it to the root `MultiProvider` list in `lib/scw_provider.dart` (for app-wide ViewModels) or wrap it locally per-screen:

```dart
class RiderLoginView extends StatefulWidget { ... }

class _RiderLoginViewState extends State<RiderLoginView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<RiderAuthViewModel>(),
      child: Consumer<RiderAuthViewModel>(
        builder: (context, vm, _) {
          if (vm.state is RiderAuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ...; // your form
        },
      ),
    );
  }
}
```

For an app-wide ViewModel already registered in `scw_provider.dart`, skip the local `ChangeNotifierProvider` and just use `context.read<T>()` (actions) / `context.watch<T>()` or `context.select<T, R>()` (render) directly — do not also wrap it in a screen-local provider, which would create a second, shadowing instance (an inconsistency already present in a couple of vendor screens — avoid replicating it).

---

## 9. Complete Feature Template (All Layers)

Use this as a copy-paste starting point for any new rider feature.

### Layer 1: Model

```dart
// lib/features/rider/<feature>/models/rider_<feature>_model.dart

import 'package:equatable/equatable.dart';

class RiderOrderModel extends Equatable {
  final String id;
  final String customerName;
  final String pickupAddress;
  final String deliveryAddress;
  final double fare;
  final String status;
  final DateTime createdAt;

  const RiderOrderModel({
    required this.id,
    required this.customerName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.fare,
    required this.status,
    required this.createdAt,
  });

  // Convenience formatters
  String get fareFormatted => 'GH₵ ${fare.toStringAsFixed(2)}';
  bool get isActive => status == 'active' || status == 'picked_up';

  RiderOrderModel copyWith({ /* all fields */ }) => RiderOrderModel(/* ... */);

  factory RiderOrderModel.fromJson(Map<String, dynamic> json) => RiderOrderModel(
    id:              json['id'] as String,
    customerName:    json['customer_name'] as String,
    pickupAddress:   json['pickup_address'] as String,
    deliveryAddress: json['delivery_address'] as String,
    fare:            (json['fare'] as num).toDouble(),
    status:          json['status'] as String,
    createdAt:       DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':               id,
    'customer_name':    customerName,
    'pickup_address':   pickupAddress,
    'delivery_address': deliveryAddress,
    'fare':             fare,
    'status':           status,
    'created_at':       createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, status, fare];
}
```

### Layer 2: Repository Contract

```dart
// lib/features/rider/<feature>/repositories/rider_orders_repository.dart

import 'package:dartz/dartz.dart';
import 'package:bagyesrushappusernew/core/errors/failures.dart';
import '../models/rider_order_model.dart';

abstract class RiderOrdersRepository {
  Future<Either<Failure, List<RiderOrderModel>>> fetchActiveOrders();
  Future<Either<Failure, RiderOrderModel>> fetchOrderDetail(String orderId);
  Future<Either<Failure, RiderOrderModel>> acceptOrder(String orderId);
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status);
}
```

### Layer 3: Repository Implementation

```dart
// lib/features/rider/<feature>/repositories/rider_orders_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/errors/failures.dart';
import '../services/rider_orders_api_service.dart';
import 'rider_orders_repository.dart';
import '../models/rider_order_model.dart';

class RiderOrdersRepositoryImpl implements RiderOrdersRepository {
  final RiderOrdersApiService _api;

  RiderOrdersRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderOrderModel>>> fetchActiveOrders() =>
      _run(() => _api.fetchActiveOrders());

  @override
  Future<Either<Failure, RiderOrderModel>> fetchOrderDetail(String orderId) =>
      _run(() => _api.fetchOrderDetail(orderId));

  @override
  Future<Either<Failure, RiderOrderModel>> acceptOrder(String orderId) =>
      _run(() => _api.acceptOrder(orderId));

  @override
  Future<Either<Failure, void>> updateOrderStatus(
      String orderId, String status) =>
      _run(() => _api.updateOrderStatus(orderId, status));

  // ── Generic error wrapper ──────────────────────────────────────────
  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Request failed';
      return Left(ServerFailure(message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

### Layer 4: Riverpod Provider

```dart
// lib/features/rider/<feature>/providers/rider_orders_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import '../repositories/rider_orders_repository.dart';
import '../models/rider_order_model.dart';

// ── State ──────────────────────────────────────────────────────────────
enum RiderOrdersStatus { initial, loading, loaded, error }

class RiderOrdersState extends Equatable {
  final RiderOrdersStatus status;
  final List<RiderOrderModel> orders;
  final String? errorMessage;

  const RiderOrdersState({
    this.status = RiderOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  RiderOrdersState copyWith({
    RiderOrdersStatus? status,
    List<RiderOrderModel>? orders,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, errorMessage];
}

// ── Notifier ───────────────────────────────────────────────────────────
class RiderOrdersNotifier extends Notifier<RiderOrdersState> {
  late final RiderOrdersRepository _repo;

  @override
  RiderOrdersState build() {
    _repo = sl<RiderOrdersRepository>();
    return const RiderOrdersState();
  }

  Future<void> load() async {
    state = state.copyWith(status: RiderOrdersStatus.loading, clearError: true);
    final result = await _repo.fetchActiveOrders();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderOrdersStatus.error, errorMessage: f.message),
      (orders) => state = state.copyWith(
          status: RiderOrdersStatus.loaded, orders: orders),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    final result = await _repo.acceptOrder(orderId);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      (updated) => state = state.copyWith(
        orders: state.orders.map((o) => o.id == orderId ? updated : o).toList(),
      ),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────
final riderOrdersProvider =
    NotifierProvider<RiderOrdersNotifier, RiderOrdersState>(
  RiderOrdersNotifier.new,
);
```

### Layer 5: View

```dart
// lib/features/rider/<feature>/views/screens/rider_active_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../providers/rider_orders_providers.dart';
import '../widgets/rider_order_card.dart';

class RiderActiveOrdersScreen extends ConsumerStatefulWidget {
  const RiderActiveOrdersScreen({super.key});

  @override
  ConsumerState<RiderActiveOrdersScreen> createState() =>
      _RiderActiveOrdersScreenState();
}

class _RiderActiveOrdersScreenState
    extends ConsumerState<RiderActiveOrdersScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderOrdersProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderOrdersProvider);

    ref.listen<RiderOrdersState>(riderOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Active Orders')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RiderOrdersState state) {
    switch (state.status) {
      case RiderOrdersStatus.initial:
      case RiderOrdersStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case RiderOrdersStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Something went wrong'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(riderOrdersProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case RiderOrdersStatus.loaded:
        if (state.orders.isEmpty) {
          return const Center(child: Text('No active orders'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(riderOrdersProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => RiderOrderCard(order: state.orders[i]),
          ),
        );
    }
  }
}
```

---

## 10. Widget Design Patterns

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Screen / page | `<Name>Screen` or `<Name>View` | `RiderWalletScreen` |
| Reusable component | `<Name>` (PascalCase) | `RiderBalanceCard` |
| Private sub-widget | `_<Name>` | `_WithdrawButton`, `_StatTile` |
| Step in a flow | `<Name>Step` | `PickupLocationStep` |

### Card with Border (standard)

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 0.5),
  ),
  child: ...,
)
```

### Icon Pill (status indicator)

```dart
Container(
  width: 36,
  height: 36,
  decoration: BoxDecoration(
    color: AppColors.success.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(10),
  ),
  child: const Icon(Icons.check, color: AppColors.success, size: 18),
)
```

### Glassmorphic Hero Card (match vendor wallet style)

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 20),
  height: MediaQuery.sizeOf(context).width * 0.55,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ...,   // card content
      ),
    ),
  ),
)
```

### Slide-up Page Transition

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, anim, __) => const RiderWithdrawScreen(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 380),
  ),
);
```

### Slide-right Page Transition

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, anim, __) => const RiderOrderDetailScreen(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: anim, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 320),
  ),
);
```

### Animated Load-in (fade + slide)

```dart
class _RiderBalanceCardState extends State<RiderBalanceCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: _cardContent()),
    );
  }
}
```

### Custom Dialog (reuse existing)

```dart
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';

// Success
await CustomDialog.showSuccess(
  context: context,
  title: 'Order Accepted!',
  subtitle: 'Head to the pickup point',
  iconPath: Assets.successLottie,
  onConfirm: () => Navigator.pop(context),
);

// Error
await CustomDialog.showError(
  context: context,
  title: 'Failed',
  subtitle: 'Could not accept order. Try again.',
  iconPath: Assets.errorLottie,
);
```

### Responsive Sizing

```dart
// Always use MediaQuery.sizeOf — NOT MediaQuery.of(context).size
final w = MediaQuery.sizeOf(context).width;
final h = MediaQuery.sizeOf(context).height;

// Example responsive padding
EdgeInsets.all(w * 0.06)
```

---

## 11. Navigation (GoRouter)

File: `lib/core/router/app_routes.dart` — add rider route constants here.

```dart
abstract final class AppRoutes {
  // ...existing routes...

  // Rider routes
  static const String riderHome         = '/rider';
  static const String riderLogin        = '/rider/login';
  static const String riderSignup       = '/rider/signup';
  static const String riderDashboard    = '/rider/dashboard';
  static const String riderOrders       = '/rider/orders';
  static const String riderOrderDetail  = '/rider/orders/:id';
  static const String riderWallet       = '/rider/wallet';
  static const String riderProfile      = '/rider/profile';
}
```

File: `lib/core/router/app_router.dart` — add rider GoRoute entries.

```dart
GoRoute(
  path: AppRoutes.riderDashboard,
  builder: (_, __) => const RiderDashboardScreen(),
  routes: [
    GoRoute(
      path: 'orders',
      builder: (_, __) => const RiderActiveOrdersScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => RiderOrderDetailScreen(
            orderId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: 'wallet',
      builder: (_, __) => const RiderWalletScreen(),
    ),
  ],
),
```

---

## 12. Session Management

**Do not use `UserSessionManager`** (`lib/core/services/user_session_manager.dart`) — it exists in the codebase but is dead code: it is never registered in GetIt and never instantiated anywhere. Using `sl<UserSessionManager>()` will throw at runtime ("type not registered").

The real session chain, wired up eagerly in `AppInitializer.initialize()` before `runApp`:

```
FlutterSecureStorage → CacheHelper → Cache.instance (in-memory) → CurrentUserProvider → AuthRepository / AuthViewmodel.restoreSession()
```

- `CacheHelper` (`lib/core/helpers/cache_helper.dart`) persists the session token/user id to secure storage and warms `Cache.instance` on boot.
- `Cache.instance` (`lib/core/singletons/cache.dart`) is a plain in-memory singleton read **synchronously** wherever a token is needed without awaiting storage (Dio interceptors, `GoRouter`'s redirect guard).
- `CurrentUserProvider` (`lib/core/common/app/current_user_provider.dart`) is a `ChangeNotifier` holding the logged-in `User` — the single source of truth for "who is logged in," and it also serves as `GoRouter`'s `refreshListenable` so route guards re-evaluate on login/logout.

```dart
// Reading the current session (already injected into Dio by the interceptor)
final token = Cache.instance.sessionToken;
final user = sl<CurrentUserProvider>().user;      // or context.watch<CurrentUserProvider>().user in a widget

// Checking auth state
if (Cache.instance.sessionToken == null) {
  appRouter.go(AppRoutes.riderLogin);
}

// Logging out — follow AuthViewmodel's logout() method for the exact sequence
// (clears CacheHelper, resets CurrentUserProvider, then navigates)
await sl<AuthViewmodel>().logout();
appRouter.go(AppRoutes.riderLogin);
```

For rider-specific session fields beyond what `CurrentUserProvider`/`User` already covers (e.g. `isOnline`/availability), extend the existing `User` model and `CurrentUserProvider` rather than introducing a parallel session object — there is already exactly one source of truth for the logged-in user and it should stay that way.

---

## 13. Known Inconsistencies — Do Not Replicate

A few things already living in this codebase are legacy leftovers or latent bugs, not patterns to follow. Flagged here so a rider feature doesn't copy them:

- **Double `AuthViewmodel` registration.** `service_locator.dart` registers `AuthViewmodel` with `registerFactory`, and `app_initializer.dart` separately registers it with `registerSingleton` (guarded by `isRegistered`). The singleton wins because `AppInitializer.initialize()` runs second, but the factory line is dead and confusing. When registering a rider ViewModel, register it in **exactly one place** — `service_locator.dart` for anything not on the pre-first-frame critical path (see §4).
- **Singular/plural folder duplication in `lib/src/payment/`.** Both `model/`/`repository/`/`viewmodel/` (singular) and `models/`/`repositories/`/`viewmodels/` (plural) exist side by side with overlapping files. Use **plural** folder names only, consistently, for every rider feature.
- **Duplicate model definitions in `lib/src/auth/models/`.** `user.dart` (hand-written `Equatable`, used everywhere) coexists with an unused `user_model.dart` (`json_serializable`-generated, dead code). Define **one** model class per entity, hand-written with manual `fromJson`/`toJson`/`copyWith` extending `Equatable` — do not add a second codegen-based model "in case it's needed later."
- **Screen-local `ChangeNotifierProvider` shadowing a globally-registered instance.** A couple of vendor screens wrap an already-globally-provided ViewModel in a second, screen-local `ChangeNotifierProvider(create: (_) => sl<X>())`, creating two live instances of what's meant to be shared state. Pick one lifetime per ViewModel (see the note at the end of §8 Pattern B) and stick to it.

---

## 14. Checklist: Adding a New Rider Feature

Copy this checklist for every new feature:

```
[ ] 1. Create folder: lib/features/rider/<feature>/
[ ] 2. Add model(s) in models/ — extend Equatable, add fromJson/toJson
[ ] 3. Add abstract repository in repositories/<feature>_repository.dart
[ ] 4. Add API service in services/<feature>_api_service.dart
        — inject Dio via sl<Dio>() directly, call it directly (see §5 — do not use NetworkUtility)
[ ] 5. Add repository impl in repositories/<feature>_repository_impl.dart
        — implements abstract repo, calls API service
        — includes _run() error wrapper
[ ] 6. Add state class + Notifier + Providers in providers/<feature>_providers.dart
        — state: Equatable, copyWith, clearError flag
        — notifier: build() fetches repo from sl<>(), load() follows fold() pattern
[ ] 7. Register in service_locator.dart
        — API service: registerLazySingleton
        — Repository impl: registerLazySingleton<AbstractRepo>(() => ConcreteImpl(sl()))
[ ] 8. Add API endpoints to lib/core/network/api_endpoints.dart
[ ] 9. Create screen(s) in views/screens/ — ConsumerStatefulWidget
        — initState loads via addPostFrameCallback
        — ref.listen for error snackbar
        — _buildBody switches on status
[ ] 10. Create widgets in views/widgets/ — dumb/stateless where possible
[ ] 11. Add route constants to AppRoutes
[ ] 12. Add GoRoute entry to app_router.dart
```

---

## Key Imports Reference

```dart
// Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';

// GetIt DI
import 'package:bagyesrushappusernew/core/di/service_locator.dart';

// Error types
import 'package:bagyesrushappusernew/core/errors/failures.dart';

// Typedefs (ResultFuture, DataMap)
import 'package:bagyesrushappusernew/constant/typedef.dart';

// Colors + Theme
import 'package:bagyesrushappusernew/constant/app_theme.dart';

// Text styles + spacing
import 'package:bagyesrushappusernew/constant/constant.dart';

// API endpoints
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';

// Either
import 'package:dartz/dartz.dart';

// Equatable
import 'package:equatable/equatable.dart';
```
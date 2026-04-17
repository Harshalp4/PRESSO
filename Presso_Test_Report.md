# Presso Platform — Code Audit & Test Report

**Date:** April 5, 2026
**Scope:** Full codebase review of Presso.API, presso_app (Customer), presso_operations (Ops)

---

## 1. Bug Fixed This Session: Order 400 "Service Not Found"

**Root Cause:** The Flutter app persists selected services to SharedPreferences (for draft order recovery). When the database services change (e.g., after running a seed migration), the cached service IDs become stale. The app sends old IDs that no longer exist in the DB, resulting in `"Service {id} not found"`.

**Fixes Applied:**
- Added `validateCachedServices()` method in `CreateOrderFlowNotifier` — compares cached selections against fresh API data and removes stale entries
- Wired validation into `_servicesProvider` in `service_selection_screen.dart` — runs automatically when services are fetched from API
- Added stale-data error recovery in `order_summary_screen.dart` — if API returns "not found", resets the draft and sends user back to service selection with a clear message
- Debug logging added for stale cache detection

**Action Required:** After running the DB migration, clear the Flutter app data once (Settings → Apps → Presso → Clear Data) OR simply re-select services from the service selection screen (the new validation will auto-clear stale selections).

---

## 2. Previously Fixed Issues (This Session)

| Issue | Fix | File(s) |
|-------|-----|---------|
| Hardcoded coin conversion (`coins ~/ 10`) | Uses `config.coinValueRupees` from DB | profile_screen.dart, home_provider.dart |
| Hardcoded "₹30 off" referral text | Computed from `bonusCoins * coinRate` | refer_screen.dart |
| Hardcoded "20% off" student discount | Uses `config.studentDiscountPercent` | offers_strip.dart, student_verify_screen.dart |
| Hardcoded service areas list | Uses `config.serviceAreas` with fallback | home_screen.dart |
| Hardcoded express charge in order | Uses `config.expressCharge` | order_summary_screen.dart |
| Order summary coin discount | Uses `coinDiscountFor(coinValueRupees:)` | order_summary_screen.dart |
| Stats "Saved" in referral screen | Uses `coinRate` from config | refer_screen.dart |

---

## 3. Feature Inventory & Test Checklist

### 3.1 Customer App (presso_app) — 32 Screens

#### Authentication Flow
| # | Feature | Screen | Status | Notes |
|---|---------|--------|--------|-------|
| 1 | Splash / auto-login | splash_screen.dart | Code complete | Checks JWT token in SharedPreferences |
| 2 | Onboarding carousel | onboarding_screen.dart | Code complete | 3-page intro slider |
| 3 | Phone number entry | phone_auth_screen.dart | Code complete | +91 prefix, 10-digit validation |
| 4 | OTP verification | otp_screen.dart | Code complete | 6-digit OTP, Firebase Auth |
| 5 | Profile setup | profile_setup_screen.dart | Code complete | Name, email, optional |

#### Home & Navigation
| # | Feature | Screen | Status | Notes |
|---|---------|--------|--------|-------|
| 6 | Home dashboard | home_screen.dart | Code complete | AI greeting, live order card, services grid, offers |
| 7 | AI greeting card | ai_greeting_card.dart | Code complete | Time-based tips from API/fallback |
| 8 | Service area picker | home_screen.dart (bottom sheet) | **Now DB-driven** | Was hardcoded, now uses `config.serviceAreas` |
| 9 | Offers strip | offers_strip.dart | **Now DB-driven** | Flash deal + student discount from config |
| 10 | Suvichar (daily message) | home_provider.dart | Code complete | Hindi/English motivational quotes |
| 11 | Live order tracking card | live_order_card.dart | Code complete | Shows active order status |

#### Order Flow (Critical Path)
| # | Feature | Screen | Status | Notes |
|---|---------|--------|--------|-------|
| 12 | Service selection | service_selection_screen.dart | **Fixed** | Now validates cached services against API |
| 13 | Garment count | garment_count_screen.dart | Code complete | Per-garment quantity selector |
| 14 | Treatment selection | (within garment screen) | Code complete | For Bags+Leather, Shoe Cleaning |
| 15 | Pickup slot selection | slot_selection_screen.dart | Code complete | Date + time slot picker |
| 16 | Address selection | address_selection_screen.dart | Code complete | Saved addresses list |
| 17 | Order summary | order_summary_screen.dart | **Fixed** | Config-driven pricing, stale-data recovery |
| 18 | Payment (Razorpay) | order_summary_screen.dart | **Needs config** | Test key placeholder in code |
| 19 | Payment (COD) | order_summary_screen.dart | Code complete | Direct order placement |
| 20 | Order confirmation | order_confirmed_screen.dart | Code complete | Success animation + order ID |
| 21 | Order tracking | order_tracking_screen.dart | Code complete | Real-time status via SignalR |
| 22 | Order detail | order_detail_screen.dart | Code complete | Full breakdown view |
| 23 | Order history | orders_screen.dart | Code complete | Paginated list with filters |

#### Profile & Settings
| # | Feature | Screen | Status | Notes |
|---|---------|--------|--------|-------|
| 24 | Profile view/edit | profile_screen.dart | **Fixed** | Coin value now from config |
| 25 | Saved addresses | addresses_screen.dart | Code complete | CRUD for addresses |
| 26 | Add/edit address | add_address_screen.dart | Code complete | Google Maps integration |
| 27 | Student verification | student_verify_screen.dart | **Fixed** | Discount % from config |
| 28 | Notifications settings | notifications_screen.dart | Code complete | Toggle preferences |

#### Loyalty & Referrals
| # | Feature | Screen | Status | Notes |
|---|---------|--------|--------|-------|
| 29 | Savings dashboard | savings_screen.dart | Code complete | Total savings, order count |
| 30 | Loyalty tiers | loyalty_card.dart | Code complete | Silver/Gold/Platinum/Diamond |
| 31 | Refer & earn | refer_screen.dart | **Fixed** | All text now config-driven |
| 32 | Referral history | refer_screen.dart | Code complete | List of referred users |

### 3.2 Operations App (presso_operations) — 20 Screens

#### Rider Features
| # | Feature | Status |
|---|---------|--------|
| 1 | Rider dashboard (pending jobs) | Code complete |
| 2 | Job detail view | Code complete |
| 3 | Photo capture (pickup) | Code complete |
| 4 | Shoe photo capture | Code complete |
| 5 | Garment confirmation | Code complete |
| 6 | OTP verification (pickup) | Code complete |
| 7 | Pickup completion | Code complete |
| 8 | Delivery flow | Code complete |
| 9 | Delivery OTP verification | Code complete |
| 10 | Earnings dashboard | Code complete |

#### Facility Features
| # | Feature | Status |
|---|---------|--------|
| 11 | Facility dashboard | Code complete |
| 12 | Scan/receive orders | Code complete |
| 13 | Order detail (processing) | Code complete |
| 14 | Status update | Code complete |

#### Admin Features
| # | Feature | Status |
|---|---------|--------|
| 15 | Service zones management | Code complete |
| 16 | Create zone | Code complete |
| 17 | Edit zone | Code complete |

### 3.3 API Endpoints (Presso.API) — 19 Endpoint Groups

| Group | Key Routes | Status |
|-------|-----------|--------|
| Auth | POST /login, /refresh-token | Code complete |
| Users | GET/PUT /me, GET /savings | Code complete |
| Addresses | CRUD /addresses | Code complete |
| Services | GET /services (with garments & treatments) | Code complete |
| Orders | POST /create, GET list/detail, PUT cancel | **Fixed error handling** |
| Pickup Slots | GET available, POST create | Code complete |
| Coins | GET balance/ledger | Code complete |
| Referrals | GET code/stats/history, POST apply | Code complete |
| Riders | GET /dashboard, PUT /accept, /pickup, /deliver | Code complete |
| Facility | GET /dashboard, PUT /receive, /process, /ready | Code complete |
| Admin | GET /stats, PUT /config, CRUD /zones | Code complete |
| Payments | POST /webhook (Razorpay) | Code complete |
| Config | GET /config (AppConfig key-values) | Code complete |
| Notifications | GET list, PUT read/settings | Code complete |
| Photos | POST upload, GET download | Code complete |
| Daily Message | GET /suvichar | Code complete |
| SignalR Hub | /hubs/orders (real-time) | Code complete |

---

## 4. Database Status

**Tables:** 20 total (Users, Orders, OrderItems, Addresses, Services, GarmentTypes, ServiceTreatments, PickupSlots, CoinsLedger, Referrals, Notifications, Riders, AppConfig, ServiceZones, StudentVerifications, OrderPhotos, PaymentTransactions, OrderStatusHistory, AdminUsers, DailyMessages)

**Seed Data:** 11 services, 46 garment types, 6 treatments, 16 AppConfig keys

**Migrations:** 6 completed; user MUST run new seed migration:
```bash
cd Presso.API
dotnet ef migrations add SeedAllServicesAndTreatments
dotnet ef database update
```

---

## 5. Critical Configuration Checklist

| Item | File | Current State | Action |
|------|------|---------------|--------|
| JWT Secret | appsettings.json | Placeholder | MUST change before production |
| Firebase credentials | appsettings.json | Not configured | Configure for auth to work |
| Razorpay key | order_summary_screen.dart | `rzp_test_YOUR_KEY_HERE` | Replace with real key |
| Database password | appsettings.json | Default | Change for production |
| CORS origins | Program.cs | localhost:3000 | Add production domain |
| Poppins fonts | Both apps assets/fonts/ | Placeholder .ttf files | Download from Google Fonts |
| Azure Blob Storage | appsettings.json | Not configured | Configure for photo uploads |

---

## 6. Known Limitations / Not Yet Implemented

| Feature | Location | Status |
|---------|----------|--------|
| PaymentService (Razorpay server-side) | API | Stub only |
| StudentVerificationService | API | Stub only |
| FirestoreService (real-time sync) | API | Stub only |
| AzureBlobService (photo storage) | API | Stub only |
| DailyMessageService (AI messages) | API | Stub only |
| Push notifications (FCM) | API + Apps | Configured but untested |
| Google Maps integration | presso_app | API key needed |

---

## 7. Immediate Next Steps

1. **Run DB migration** to seed all 11 services, 46 garment types, 6 treatments
2. **Clear Flutter app data** (one time) to flush stale cached service IDs
3. **Download Poppins fonts** → replace placeholder .ttf files in both apps
4. **Configure Firebase** for phone auth to work
5. **Test order flow end-to-end**: Select services → Add garments → Pick slot → Select address → Review summary → Place order (COD)
6. **Configure Razorpay** test key for online payment testing

---

## 8. Summary of All Code Changes (This Session)

### Files Modified: 14

| File | Change |
|------|--------|
| `create_order_provider.dart` | Added `validateCachedServices()`, coin/express config params |
| `service_selection_screen.dart` | Wired cache validation on service load |
| `order_summary_screen.dart` | Config-driven pricing, stale-data error recovery |
| `profile_screen.dart` | Coin value from config |
| `home_provider.dart` | `rupeesEquivalentFor()` with configurable rate |
| `home_screen.dart` | Service areas from config, added import |
| `refer_screen.dart` | All text computed from config, StatsRow → ConsumerWidget |
| `offers_strip.dart` | Student discount % from config, added Riverpod |
| `student_verify_screen.dart` | Discount % from config (3 occurrences) |
| `OrderService.cs` | Improved error messages (previous session) |
| `ServiceConfiguration.cs` | 11 services with deterministic GUIDs (previous session) |
| `GarmentTypeConfiguration.cs` | 46 garment types (previous session) |
| `ServiceTreatmentConfiguration.cs` | 6 treatments (previous session) |
| `fallback_services.dart` | GUIDs synced with DB seeds (previous session) |

# Presso - Complete Database & App Update Guide

> Generated: April 2026 | PostgreSQL on localhost:5432 | Database: `presso`

---

## 1. Complete Database Schema (20 Tables)

### 1.1 Users & Auth

**Users**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| FirebaseUid | varchar | Unique, from Firebase Auth |
| Phone | varchar(15) | Required |
| Name | varchar(100) | Nullable |
| Email | varchar(256) | Nullable |
| IsActive | bool | Default true |
| IsStudentVerified | bool | Default false |
| ReferralCode | varchar(20) | Unique, auto-generated |
| Role | enum(Customer,Rider,Admin) | Default Customer |
| CoinBalance | int | Default 0 |
| FcmToken | varchar(512) | For push notifications |
| FcmTokenUpdatedAt | timestamp | |
| ProfilePhotoUrl | varchar(512) | Azure Blob URL |
| CreatedAt / UpdatedAt | timestamp | |

**RefreshTokens**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| Token | varchar | |
| TokenHash | varchar | Indexed |
| ExpiresAt | timestamp | |
| IsRevoked | bool | |
| CreatedAt | timestamp | |

**Addresses**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| Label | varchar(50) | Home, Work, etc. |
| AddressLine1 | varchar(200) | Required |
| AddressLine2 | varchar(200) | |
| City | varchar(100) | |
| Pincode | varchar(6) | Checked against ServiceZones |
| Lat / Lng | double | For maps |
| IsDefault | bool | |
| IsDeleted | bool | Soft delete |
| CreatedAt / UpdatedAt | timestamp | |

### 1.2 Service Catalog

**Services** (11 services seeded)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Name | varchar(100) | e.g. "Wash + Iron" |
| Description | varchar(500) | |
| Category | varchar(50) | clothes, home_linen, specialty |
| PricePerPiece | decimal(10,2) | Base price |
| IconUrl | varchar(512) | |
| IsActive | bool | |
| SortOrder | int | Display order |
| CreatedAt / UpdatedAt | timestamp | |

**GarmentTypes** (46 garment types seeded)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| ServiceId | uuid FK→Services | CASCADE delete |
| Name | varchar(100) | e.g. "Shirt", "Sneakers" |
| PriceOverride | decimal(10,2)? | If null, use Service.PricePerPiece |
| SortOrder | int | |
| CreatedAt / UpdatedAt | timestamp | |

**ServiceTreatments** (6 treatments seeded)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| ServiceId | uuid FK→Services | CASCADE delete |
| Name | varchar(100) | e.g. "Deep Clean" |
| Description | varchar(500) | |
| PriceMultiplier | decimal(5,2) | 1.0x, 1.5x, 2.0x |
| SortOrder | int | |
| IsActive | bool | |
| CreatedAt / UpdatedAt | timestamp | |

### 1.3 Orders & Payments

**Orders**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| OrderNumber | varchar | Auto-generated sequence |
| UserId | uuid FK→Users | |
| AddressId | uuid FK→Addresses | |
| PickupSlotId | uuid? FK→PickupSlots | Nullable |
| Status | enum | Pending→Confirmed→RiderAssigned→PickupInProgress→PickedUp→InProcess→ReadyForDelivery→OutForDelivery→Delivered / Cancelled |
| SubTotal | decimal | Sum of items |
| CoinDiscount | decimal | Coins redeemed value |
| StudentDiscount | decimal | If student verified |
| ExpressCharge | decimal | If express delivery |
| AdminDiscount | decimal | Custom discount |
| TotalAmount | decimal | Final amount |
| PickupOtpHash | varchar? | SHA256 of 4-digit OTP |
| DeliveryOtpHash | varchar? | SHA256 of 4-digit OTP |
| PaymentStatus | enum | Pending/Authorized/Captured/Failed/Refunded |
| RazorpayOrderId | varchar? | |
| RazorpayPaymentId | varchar? | |
| IsExpressDelivery | bool | |
| SpecialInstructions | varchar? | |
| FacilityNotes | varchar? | Staff notes |
| CoinsEarned | int | Calculated post-payment |
| CoinsRedeemed | int | |
| UserDiscountId | uuid? FK→UserDiscounts | |
| AssignedStoreId | uuid? FK→StoreLocations | |
| PickupPhotoUrls | text[] | Array of URLs |
| PickupPhotosBlobFolder | varchar? | Azure Blob path |
| PhotosUploadedAt | timestamp? | |
| PickupPhotoCount | int | |
| Timestamps | various | PickedUpAt, FacilityReceivedAt, ProcessingStartedAt, ReadyAt, OutForDeliveryAt, DeliveredAt, CreatedAt, UpdatedAt |

**OrderItems**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| OrderId | uuid FK→Orders | CASCADE |
| ServiceId | uuid FK→Services | |
| GarmentTypeId | uuid? FK→GarmentTypes | |
| ServiceName | varchar | Denormalized |
| GarmentTypeName | varchar? | Denormalized |
| ServiceTreatmentId | uuid? FK→ServiceTreatments | |
| TreatmentName | varchar? | Denormalized |
| TreatmentMultiplier | decimal | Default 1.0 |
| Quantity | int | |
| PricePerPiece | decimal | Snapshot at order time |
| Subtotal | decimal | Price × Qty × Multiplier |
| CreatedAt | timestamp | |

**PickupSlots** (28 seeded — 7 days × 4 slots)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Date | date | |
| StartTime | time | |
| EndTime | time | |
| MaxOrders | int | Default 10 |
| CurrentOrders | int | Incremented on order |
| IsActive | bool | |
| StoreLocationId | uuid? FK→StoreLocations | |
| CreatedAt / UpdatedAt | timestamp | |

### 1.4 Operations & Fulfillment

**OrderAssignments**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| OrderId | uuid FK→Orders | |
| RiderId | uuid FK→Riders | |
| Type | enum(Pickup, Delivery) | |
| Status | enum(Assigned,Accepted,InProgress,Completed,Cancelled) | |
| AssignedAt | timestamp | |
| AcceptedAt / CompletedAt | timestamp? | |
| CreatedAt / UpdatedAt | timestamp | |

**Riders**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | 1:1 |
| VehicleNumber | varchar? | |
| IsActive / IsAvailable | bool | |
| CurrentLat / CurrentLng | double? | Live location |
| TodayEarnings | decimal | |
| LastLocationUpdate | timestamp? | |
| CreatedAt / UpdatedAt | timestamp | |

**StoreLocations** (1 seeded — Mahape HQ)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Name | varchar(100) | |
| AddressLine1/2 | varchar(200) | |
| City / State / Pincode | varchar | |
| Latitude / Longitude | double | |
| Phone | varchar(15) | |
| Email | varchar(256)? | |
| GoogleMapsUrl | varchar(512)? | |
| OpenTime / CloseTime | time | |
| IsOpenSunday | bool | |
| ServiceRadiusKm | double | |
| IsActive / IsHeadquarters | bool | |
| CreatedAt | timestamp | |

**ServiceZones** (managed via Admin panel)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Name | varchar(100) | e.g. "Vashi" |
| Pincode | varchar(6) | Checked during order |
| City | varchar(100) | |
| Area | varchar(100)? | |
| Description | varchar(500)? | |
| IsActive | bool | |
| SortOrder | int | |
| AssignedStoreId | uuid? FK→StoreLocations | |
| CreatedAt / UpdatedAt | timestamp | |

### 1.5 Rewards & Discounts

**CoinsLedger**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| OrderId | uuid? FK→Orders | |
| Amount | int | +ve earned, -ve redeemed |
| Type | enum(Earned,Redeemed,Referral,Bonus) | |
| Description | varchar(500) | |
| CreatedAt | timestamp | |

**Referrals**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| ReferrerUserId | uuid FK→Users | |
| ReferredUserId | uuid FK→Users | |
| ReferralCode | varchar(20) | |
| Status | enum(Pending,Completed,Expired) | |
| CoinsEarned | int | |
| CreatedAt / UpdatedAt | timestamp | |

**UserDiscounts** (admin-created per-user)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| Type | enum(Percentage, FlatAmount) | |
| Value | decimal | e.g. 10 (= 10% or ₹10) |
| Reason | varchar | |
| IsActive | bool | |
| ExpiresAt | timestamp? | |
| UsageLimit | int? | Null = unlimited |
| UsageCount | int | |
| CreatedByAdminId | uuid | |
| CreatedAt / UpdatedAt | timestamp | |

### 1.6 Notifications & Content

**Notifications**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| OrderId | uuid? | |
| Title / Body | varchar | |
| Type | enum(OrderUpdate,Promotion,Referral,Coins,General) | |
| IsRead | bool | |
| CreatedAt | timestamp | |

**DailyMessages** (Suvichar)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Date | date | Unique per day |
| HindiText / EnglishText | varchar | |
| Category | varchar? | |
| CreatedAt | timestamp | |

**StudentVerifications**
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| UserId | uuid FK→Users | |
| IdPhotoUrl | varchar | Azure Blob |
| Status | enum(Pending,Approved,Rejected) | |
| ReviewNote | varchar? | Admin note |
| CreatedAt / UpdatedAt | timestamp | |

### 1.7 App Configuration

**AppConfigs** (16 keys seeded)
| Column | Type | Notes |
|--------|------|-------|
| Id | uuid PK | |
| Key | varchar(100) | Unique index |
| Value | varchar(4000) | |
| Description | varchar(500)? | |
| ValueType | varchar(20) | string, int, decimal, json |
| UpdatedAt | timestamp | |

---

## 2. Seed Data — All 11 Services

### Services

| ID (last 4) | Name | Category | Base Price | Garments | Treatments |
|---|---|---|---|---|---|
| ...0001 | Wash + Iron | clothes | ₹29/pc | 5 | — |
| ...0002 | Wash + Fold | clothes | ₹19/pc | 4 | — |
| ...0003 | Dry Clean | clothes | ₹149/pc | 5 | — |
| ...0004 | Iron Only | clothes | ₹12/pc | 4 | — |
| ...0005 | Premium Hand Wash | clothes | ₹99/pc | 3 | — |
| ...0006 | Bedsheet + Pillow Covers | home_linen | ₹79/set | 4 | — |
| ...0007 | Curtains + Drapes | home_linen | ₹149/pc | 3 | — |
| ...0008 | Saree + Ethnic Wear | specialty | ₹99/pc | 4 | — |
| ...0009 | Woolen + Winter Wear | specialty | ₹149/pc | 3 | — |
| ...000a | Bags + Leather Goods | specialty | ₹299/pc | 3 | 3 (1.0x/1.5x/2.0x) |
| ...000b | Shoe Cleaning | specialty | ₹199/pr | 6 | 3 (1.0x/1.5x/2.0x) |

### Garment Types (46 total)

**Wash + Iron:** Shirt ₹29, T-Shirt ₹29, Pant/Jeans ₹29, Kurta ₹29, Saree ₹49

**Wash + Fold:** Shirt ₹19, T-Shirt ₹19, Pant/Jeans ₹19, Towel ₹19

**Dry Clean:** Suit 2pc ₹349, Blazer ₹249, Jacket ₹299, Saree Silk ₹199, Lehenga ₹499

**Iron Only:** Shirt ₹12, Pant/Jeans ₹12, Kurta ₹12, Saree ₹20

**Premium Hand Wash:** Silk ₹99, Woolen ₹129, Delicate ₹99

**Bedsheet + Pillows:** Single ₹79, Double ₹99, King ₹119, Pillow pair ₹39

**Curtains:** Small <5ft ₹149, Medium 5-7ft ₹179, Large >7ft ₹229

**Saree + Ethnic:** Cotton ₹99, Silk ₹199, Lehenga/Sherwani ₹349, Ethnic Kurta Set ₹149

**Woolen + Winter:** Sweater ₹149, Jacket/Coat ₹249, Blanket ₹299

**Bags + Leather:** Handbag ₹299, Backpack ₹249, Wallet/Belt ₹149

**Shoe Cleaning:** Sneakers ₹199, Leather ₹249, Sandals ₹149, Heels ₹199, Boots ₹299, Ethnic/Kolhapuri ₹179

### Treatment Tiers

| Service | Basic (1.0x) | Deep (1.5x) | Premium/Restore (2.0x) |
|---------|---|---|---|
| Bags + Leather | Clean Only | Deep Clean + color restore | Full Restore + waterproofing |
| Shoe Cleaning | Basic Clean + deodorize | Deep Clean + stain removal | Premium Restore + protection |

### AppConfig Keys (16 seeded)

| Key | Value | Type | Purpose |
|-----|-------|------|---------|
| coin_value_rupees | 0.1 | decimal | ₹ per coin (10 coins = ₹1) |
| student_discount_percent | 20 | int | Student discount % |
| express_charge | 30 | decimal | Express delivery flat fee ₹ |
| delivery_hours_standard | 48 | int | Standard delivery hours |
| delivery_hours_specialty | 72 | int | Specialty delivery hours |
| delivery_hours_express | 24 | int | Express delivery hours |
| referral_bonus_coins | 50 | int | Coins per referral (both sides) |
| coins_earned_percent | 5 | int | % of order earned as coins |
| min_order_items | 3 | int | Min garments per order |
| loyalty_gold_threshold | 500 | int | Coins for Gold tier |
| loyalty_platinum_threshold | 1500 | int | Coins for Platinum tier |
| service_areas | ["Mahape","Vashi",...] | json | Active areas |
| ai_tip_morning | ... | string | Morning tip text |
| ai_tip_afternoon | ... | string | Afternoon tip text |
| ai_tip_evening | ... | string | Evening tip text |
| ai_tip_night | ... | string | Night tip text |

---

## 3. Migration Steps

Run these commands in the `Presso.API/` directory:

```bash
# Step 1: Create migration for new seed data
dotnet ef migrations add SeedAllServicesAndTreatments

# Step 2: Apply to database
dotnet ef database update

# Step 3: Verify data
psql -h localhost -U harshal -d presso -c "SELECT name, category, price_per_piece FROM services ORDER BY sort_order;"
psql -h localhost -U harshal -d presso -c "SELECT COUNT(*) FROM garment_types;"
psql -h localhost -U harshal -d presso -c "SELECT COUNT(*) FROM service_treatments;"
```

**Expected counts after migration:**
- Services: 11
- GarmentTypes: 46
- ServiceTreatments: 6
- AppConfigs: 16
- StoreLocations: 1
- PickupSlots: 28

**If you have old services from the admin panel**, they will still exist alongside the new seed data. To clean up, either delete them via admin or run:
```sql
-- OPTIONAL: Remove old seed data (the 3 original services)
DELETE FROM garment_types WHERE service_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');
DELETE FROM services WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- OPTIONAL: Remove admin-created services (if any exist with different IDs)
-- Check first: SELECT id, name FROM services WHERE id NOT LIKE '10000000%';
```

---

## 4. Flutter App — Hardcoded Values to Fix

These values are hardcoded in the app but SHOULD come from the `AppConfig` table via the API. The app already has `AppConfigProvider` with getters for all these, but some screens bypass it.

### 4.1 Express Delivery Charge (CRITICAL)

**File:** `presso_app/lib/features/orders/presentation/providers/create_order_provider.dart`
**Line ~105:**
```dart
// CURRENT (hardcoded):
double get expressDeliveryCharge => isExpressDelivery ? 30.0 : 0.0;

// FIX: Use config provider
double get expressDeliveryCharge => isExpressDelivery ? _config.expressCharge : 0.0;
```

### 4.2 Coin-to-Rupee Conversion (CRITICAL)

**File:** `presso_app/lib/features/orders/presentation/providers/create_order_provider.dart`
**Lines ~100-102:**
```dart
// CURRENT (hardcoded):
double get coinDiscountAmount {
  return coinsToRedeem / 10.0;  // hardcoded 10 coins = ₹1
}

// FIX:
double get coinDiscountAmount {
  return coinsToRedeem * _config.coinValueRupees;  // uses DB config
}
```

**File:** `presso_app/lib/features/profile/presentation/screens/profile_screen.dart`
**Line ~23:**
```dart
// CURRENT: coinsValue = coins ~/ 10
// FIX: coinsValue = (coins * config.coinValueRupees).floor()
```

**File:** `presso_app/lib/features/home/presentation/providers/home_provider.dart`
**Line ~215:**
```dart
// CURRENT: '₹${(balance / 10)...}'
// FIX: '₹${(balance * config.coinValueRupees)...}'
```

### 4.3 Service Areas List (MEDIUM)

**File:** `presso_app/lib/features/home/presentation/screens/home_screen.dart`
**Lines ~395-402:**
```dart
// CURRENT: Hardcoded list ['Mahape', 'Vashi', 'Nerul', ...]
// FIX: Use config.serviceAreas or fetch from ServiceZones API
```

### 4.4 Referral Discount Text (LOW)

**File:** `presso_app/lib/features/referral/presentation/screens/refer_screen.dart`
**Lines ~43, 49, 196:**
```dart
// CURRENT: "₹30 off your first order" (hardcoded)
// FIX: Use referral_first_order_discount AppConfig key
```

### 4.5 Student Discount % in UI text (LOW)

**Files:** `offers_strip.dart`, `student_verify_screen.dart`
```dart
// CURRENT: "20% off every order" (hardcoded string)
// FIX: "${config.studentDiscountPercent}% off every order"
```

---

## 5. API Endpoints Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /api/services | All active services with garment types & treatments |
| GET | /api/services/{id} | Single service detail |
| POST | /api/orders | Create order |
| GET | /api/orders | User's orders (paginated) |
| GET | /api/orders/{id} | Order detail |
| GET | /api/config | All AppConfig key-value pairs |
| GET | /api/slots?date=YYYY-MM-DD | Available pickup slots |
| GET | /api/addresses | User's addresses |
| POST | /api/addresses | Add address |
| GET | /api/notifications | User's notifications |
| GET | /api/savings | User's savings summary |
| GET | /api/coins/balance | Coin balance |
| POST | /api/referrals | Apply referral code |
| GET | /api/zones | Service zones (admin) |
| POST | /api/zones | Create zone (admin) |
| PUT | /api/zones/{id} | Update zone (admin) |

---

## 6. Enums Reference

```
UserRole:        Customer(0), Rider(1), Admin(2)
OrderStatus:     Pending(0), Confirmed(1), RiderAssigned(2), PickupInProgress(3),
                 PickedUp(4), InProcess(5), ReadyForDelivery(6), OutForDelivery(7),
                 Delivered(8), Cancelled(9)
PaymentStatus:   Pending(0), Authorized(1), Captured(2), Failed(3), Refunded(4)
AssignmentType:  Pickup(0), Delivery(1)
AssignmentStatus: Assigned(0), Accepted(1), InProgress(2), Completed(3), Cancelled(4)
CoinsType:       Earned(0), Redeemed(1), Referral(2), Bonus(3)
NotificationType: OrderUpdate(0), Promotion(1), Referral(2), Coins(3), General(4)
ReferralStatus:  Pending(0), Completed(1), Expired(2)
VerificationStatus: Pending(0), Approved(1), Rejected(2)
DiscountType:    Percentage(0), FlatAmount(1)
```

---

## 7. Order Pricing Formula

```
subtotal = SUM(garment_price × treatment_multiplier × quantity) for each item

garment_price = GarmentType.PriceOverride ?? Service.PricePerPiece
treatment_multiplier = ServiceTreatment.PriceMultiplier (default 1.0)

coin_discount = min(coins_to_redeem, user.coin_balance, subtotal × 20% × 10) / 10
student_discount = subtotal × 10% (if student verified) [API uses OrderSettings]
admin_discount = UserDiscount applied if active and not expired
express_charge = subtotal × 25% (if express) [API uses OrderSettings]

total = subtotal - coin_discount - student_discount - admin_discount + express_charge
total = max(total, 0)

coins_earned = floor(total × coins_earned_percent / 100)
```

> Note: The API uses `OrderSettings` from appsettings.json for discount calculations (server-side), while the app uses `AppConfig` table values for display. Keep both in sync.

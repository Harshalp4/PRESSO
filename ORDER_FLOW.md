# Presso — Order Lifecycle & App Responsibilities

A single reference for how an order travels through the system, which app touches it at each step, and what status/assignment changes happen.

---

## 1. Status Enum (backend)

`Presso.API/Domain/Enums/OrderStatus.cs`

| Value | Name              | Meaning                                          |
|-------|-------------------|--------------------------------------------------|
| 0     | Pending           | Customer placed order, not yet confirmed         |
| 1     | Confirmed         | Order accepted by system                         |
| 2     | RiderAssigned     | A pickup rider has been dispatched               |
| 3     | PickupInProgress  | Rider marked "arrived" at customer               |
| 4     | PickedUp          | Rider completed pickup (OTP verified)            |
| 5     | InProcess         | At facility — being washed/ironed                |
| 6     | ReadyForDelivery  | Processing complete, waiting for delivery rider  |
| 7     | OutForDelivery    | Delivery rider arrived at customer               |
| 8     | Delivered         | OTP verified, order closed                       |
| 9     | Cancelled         | Any stage — terminal                             |

---

## 2. End-to-End Flow

```
 CUSTOMER APP                 OPERATIONS APP (Rider)         OPERATIONS APP (Facility)
 ────────────                 ──────────────────────         ─────────────────────────

 Place order        ─────►    [0] Pending
                                │
                                │ auto-dispatch (dev) /
                                │ admin assign (prod)
                                ▼
                              [2] RiderAssigned
                                │
                              Rider taps "Accept"
                                │
                                ▼
                              [2] Accepted (assignment)
                                │
                              Rider taps "I've Arrived"
                                │
                                ▼
                              [3] PickupInProgress
                                │
                              Capture photos
                                │
                              Enter OTP (customer shows)
                                │
                                ▼
                              [4] PickedUp ─────────────►   Appears in "At Facility"
                              (assignment = Completed)        (needs facility endpoints)
                                                                 │
                                                                 │ Facility taps
                                                                 │ "Start Washing"
                                                                 ▼
                                                              [5] InProcess (Washing)
                                                                 │
                                                                 │ "Move to Ironing"
                                                                 ▼
                                                              [5] InProcess (Ironing)
                                                                 │
                                                                 │ "Mark Ready"
                                                                 ▼
                                                              [6] ReadyForDelivery
                                                                 │
                                                                 │ auto-dispatch /
                                                                 │ admin assign
                                                                 ▼
                              [6] ReadyForDelivery (delivery)
                              assignment created
                                │
                              Rider accepts + arrives
                                │
                                ▼
                              [7] OutForDelivery
                                │
                              Enter OTP (customer shows)
                                │
                                ▼
 Order Delivered   ◄──────    [8] Delivered
                              (assignment = Completed)
```

---

## 3. Who Sees What (by status)

| Status              | Customer App | Rider App                | Facility App          |
|---------------------|:------------:|:------------------------:|:---------------------:|
| Pending / Confirmed | ✅ tracking   | ✅ pickup queue           | —                     |
| RiderAssigned       | ✅ tracking   | ✅ active pickup job      | —                     |
| PickupInProgress    | ✅ tracking   | ✅ active pickup job      | —                     |
| **PickedUp**        | ✅ tracking   | ✅ "Completed Today" list | ✅ "At Facility"       |
| InProcess           | ✅ tracking   | —                        | ✅ Washing / Ironing   |
| ReadyForDelivery    | ✅ tracking   | ✅ delivery queue         | ✅ Ready               |
| OutForDelivery      | ✅ tracking   | ✅ active delivery job    | —                     |
| Delivered           | ✅ history    | ✅ earnings / history     | ✅ history             |
| Cancelled           | ✅ history    | —                        | —                     |

> ⚠️ Bold = where things currently break. Today: after `PickedUp` the order vanishes from the rider app and the facility app has no backend at all.

---

## 4. Assignment vs Order

Two tables, two lifecycles, always kept in sync on the same action.

| Action                              | Order.Status       | Assignment.Status | Assignment.Type |
|-------------------------------------|--------------------|-------------------|-----------------|
| Order created                       | Pending            | —                 | —               |
| Auto-dispatch / admin assign pickup | RiderAssigned      | Assigned          | Pickup          |
| Rider accepts                       | RiderAssigned      | Accepted          | Pickup          |
| Rider arrives                       | PickupInProgress   | InProgress        | Pickup          |
| Rider confirms pickup (OTP)         | **PickedUp**       | **Completed**     | Pickup          |
| Facility starts processing          | InProcess          | —                 | —               |
| Facility marks ready                | ReadyForDelivery   | —                 | —               |
| Delivery assigned                   | ReadyForDelivery   | Assigned          | Delivery        |
| Rider arrives at customer           | OutForDelivery     | InProgress        | Delivery        |
| Rider confirms delivery (OTP)       | **Delivered**      | **Completed**     | Delivery        |

---

## 5. Current Gaps (as of 2026-04-07)

1. **`FacilityEndpoints` do not exist** in the API. The ops app calls `GET /api/facility/orders`, `/stats`, `/scan`, `PATCH /status` — all 404. Needs to be built.
2. **`PickedUp` orders disappear** from the rider's jobs list — they are not in the pickup or delivery filter. Need a "Completed Today" section on the rider dashboard fed by `completedToday` (already in the response DTO, currently hardcoded to 0).
3. **No explicit drop-off step.** Right now `PickedUp` is assumed to mean "at facility". If we want a rider-to-facility handoff scan, we need a new `AtFacility` sub-state or a facility "receive" action.
4. **Washing / Ironing are not first-class statuses.** The ops UI shows them as sub-states of `InProcess`. Either add new enum values (`Washing = 51`, `Ironing = 52`) or store a `ProcessingStage` string on `Order`.
5. **Delivery auto-dispatch** does not exist yet. Right now only pickups are auto-assigned to the logged-in rider.

---

## 6. DB Snapshot (2026-04-07)

```
 OrderNumber      | Status | Assignment
------------------|--------|-------------
 PRE-20260405-0002 | 4      | Completed  ← picked up, stuck (no facility flow)
 PRE-20260405-0005 | 4      | Completed  ← picked up, stuck
 PRE-20260405-0003 | 0      | Assigned
 PRE-20260405-0004 | 0      | Assigned
 PRE-20260405-0012 | 0      | Assigned
```

5 orders total. 2 picked up (stuck at step 4 because there's nothing to progress them). 3 still pending pickup.

---

## 7. Planned Fix Order

1. Build `FacilityEndpoints.cs` (list / detail / stats / status / scan).
2. Populate `completedToday` + add a "Completed Today" list on the rider dashboard.
3. Decide: add Washing/Ironing enum values, or use `ProcessingStage` string.
4. Optional: rider "drop-off at facility" action + facility "receive" scan.
5. Delivery auto-dispatch for `ReadyForDelivery` orders.

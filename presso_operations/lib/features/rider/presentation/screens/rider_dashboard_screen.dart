// Rider dashboard — redesigned to match Presso_Mobile_Wireframes.html
// (Screens 1, 2: Online toggle + Jobs list with stats + tabs).
//
// All data flow (riderProvider, SignalR, auto-refresh, acceptJob) is
// preserved from the previous implementation; only the visual layer has
// been rebuilt on top of the shared Presso UI kit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presso_operations/core/constants/api_constants.dart';
import 'package:presso_operations/core/services/signalr_service.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/auth/presentation/providers/auth_provider.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/rider_provider.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  // 0 = All, 1 = Pickup, 2 = To Drop, 3 = At Facility, 4 = Delivery
  int _tabIndex = 0;
  Timer? _refreshTimer;
  SignalRService? _signalRService;

  // Debounced search — user types, we wait 350ms, then hit the API. Keeps
  // filtering server-side per user direction ("everything should happen on
  // api end") while avoiding a request on every keystroke.
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    _connectSignalR();
    Future.microtask(() async {
      await ref.read(riderProvider.notifier).loadJobs();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.read(riderProvider.notifier).loadJobs();
    });
  }

  Future<void> _connectSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.jwtTokenKey);
    if (token == null || !mounted) return;

    final signalR = ref.read(signalRServiceProvider);
    _signalRService = signalR;
    await signalR.connect(token);
    if (!mounted) return;
    signalR.onNotification(_onSignalRNotification);
  }

  void _onSignalRNotification(Map<String, dynamic> notification) {
    if (!mounted) return;
    ref.read(riderProvider.notifier).loadJobs();
    final title = notification['title'] as String? ??
        notification['Title'] as String? ??
        'New notification';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        backgroundColor: PressoTokens.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _signalRService?.removeListener(_onSignalRNotification);
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(riderProvider.notifier).setSearchQuery(value);
    });
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'R';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderProvider);
    final jobs = state.jobs;
    // All three lists are pre-partitioned by the server (see
    // RiderService.GetRiderJobsAsync). The client does no status filtering —
    // tabs are a direct render of the API response so totals always match.
    final pickupJobs = jobs?.pickupJobs ?? const <AssignmentModel>[];
    final toDropRaw = jobs?.toDropJobs ?? const <AssignmentModel>[];
    final atFacilityRaw = jobs?.atFacilityJobs ?? const <AssignmentModel>[];
    final deliveryJobs = jobs?.deliveryJobs ?? const <AssignmentModel>[];

    final pickupTagged =
        pickupJobs.map((j) => _TaggedJob(j, 'pickup')).toList();
    final toDropTagged =
        toDropRaw.map((j) => _TaggedJob(j, 'pickup')).toList();
    final atFacilityTagged =
        atFacilityRaw.map((j) => _TaggedJob(j, 'atFacility')).toList();
    final deliveryTagged =
        deliveryJobs.map((j) => _TaggedJob(j, 'delivery')).toList();

    // "All" tab shows every active/in-flight assignment across all buckets.
    final all = <_TaggedJob>[
      ...pickupTagged,
      ...toDropTagged,
      ...atFacilityTagged,
      ...deliveryTagged,
    ];

    late final List<_TaggedJob> activeList;
    switch (_tabIndex) {
      case 1:
        activeList = pickupTagged;
        break;
      case 2:
        activeList = toDropTagged;
        break;
      case 3:
        activeList = atFacilityTagged;
        break;
      case 4:
        activeList = deliveryTagged;
        break;
      default:
        activeList = all;
    }

    final cols = PressoBreakpoints.cardColumns(context);

    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: _appBar(state),
      body: PhoneColumn(
        child: RefreshIndicator(
          color: PressoTokens.primary,
          onRefresh: () => ref.read(riderProvider.notifier).loadJobs(),
          child: ListView(
            padding: const EdgeInsets.only(top: 14, bottom: 80),
            children: [
              _searchBar(),
              PressoTabRow(
                labels: [
                  'All · ${all.length}',
                  'Pickup${pickupTagged.isEmpty ? '' : ' · ${pickupTagged.length}'}',
                  'To Drop${toDropTagged.isEmpty ? '' : ' · ${toDropTagged.length}'}',
                  'Facility${atFacilityTagged.isEmpty ? '' : ' · ${atFacilityTagged.length}'}',
                  'Delivery${deliveryTagged.isEmpty ? '' : ' · ${deliveryTagged.length}'}',
                ],
                activeIndex: _tabIndex,
                onTap: (i) => setState(() => _tabIndex = i),
              ),
              if (state.isLoading && state.jobs == null)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: PressoTokens.primary),
                  ),
                )
              else if (state.error != null && state.jobs == null)
                _error(state.error!)
              else if (activeList.isEmpty)
                _empty(_emptyKind(_tabIndex, state.searchQuery))
              else
                _jobList(activeList, cols),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the job cards either as a vertical list (phone, 1 col) or a
  /// responsive grid (tablet, 2-3 cols).
  Widget _jobList(List<_TaggedJob> list, int cols) {
    if (cols == 1) {
      return Column(children: list.map((t) => _jobCard(t.job, t.type)).toList());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 12.0;
          final cardWidth = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final t in list)
                SizedBox(
                  width: cardWidth,
                  child: _jobCard(t.job, t.type, grid: true),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── App bar (wireframe Screen 2) ──────────────────────────────────────────
  // Avatar + Name + "Available" dot + Switch + Bell. Wrapped in PhoneColumn
  // so it aligns with the body on tablets.
  PreferredSizeWidget _appBar(RiderState state) {
    final name = ref.watch(authProvider).userName ?? 'Rider';
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: PhoneColumn(
            background: Colors.white,
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Avatar with initials
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PressoTokens.primary.withValues(alpha: .12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: PressoTokens.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: PressoTokens.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state.isOnline
                                      ? PressoTokens.green
                                      : PressoTokens.textHint,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                state.isOnline ? 'Available' : 'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: state.isOnline
                                      ? PressoTokens.green
                                      : PressoTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Availability switch
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: state.isOnline,
                        onChanged: (_) => ref
                            .read(riderProvider.notifier)
                            .toggleAvailability(),
                        activeColor: Colors.white,
                        activeTrackColor: PressoTokens.green,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                      ),
                    ),
                    // Bell (notifications placeholder — long press to logout)
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: PressoTokens.amber, size: 24),
                      tooltip: 'Notifications',
                      onPressed: () {},
                      onLongPress: null,
                    ),
                    // Logout (kept accessible as a small trailing icon)
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: PressoTokens.textHint, size: 18),
                      tooltip: 'Log out',
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Job card (wireframe Screen 2) ─────────────────────────────────────────
  // Layout:
  //   Row1: "PR-xxxx · Pickup"        NEW / READY / SCHEDULED chip
  //   Row2: "Customer · City"
  //   Row3: "Slot HH:MM – HH:MM"  (or "Express · by HH:MM")
  //   Row4: "📦 N garments · X.X km"                 ₹amount
  Widget _jobCard(AssignmentModel job, String type, {bool grid = false}) {
    // Server sends 'Offered' for new offers. Keep 'Available' as a legacy
    // alias so older payloads still light up the NEW chip.
    final isAvailable = job.status == 'Offered' || job.status == 'Available';
    final isAtFacility = type == 'atFacility';
    final isPickup = type == 'pickup' || isAtFacility;
    final isInTransit = job.status == 'InTransitToFacility';

    final orderNumber = job.order?.orderNumber ?? '--';
    final typeLabel = isAtFacility
        ? 'At Facility'
        : (isPickup ? 'Pickup' : 'Delivery');
    final customer = job.customer?.name ?? 'Customer';
    final city = job.address?.city ?? job.address?.addressLine1 ?? '';
    final subtitle =
        city.isEmpty ? customer : '$customer · $city';

    String slotLine;
    if (isAtFacility) {
      slotLine = 'Processing at facility';
    } else if (job.order?.isExpressDelivery == true) {
      slotLine = 'Express · priority';
    } else if (job.order?.pickupSlotDisplay != null &&
        job.order!.pickupSlotDisplay!.isNotEmpty) {
      slotLine = 'Slot ${job.order!.pickupSlotDisplay}';
    } else if (isPickup) {
      slotLine = 'Pickup scheduled';
    } else {
      // Delivery: distinguish a fresh offer from an in-flight run. Showing
      // "Out for delivery" on an Offered card made it look like the job had
      // already started when the rider hadn't even accepted it.
      slotLine = isAvailable
          ? 'New delivery · tap to accept'
          : 'Out for delivery';
    }

    final count = job.order?.garmentCount ?? 0;
    final payout = isAtFacility ? null : job.payoutAmount;

    // "Scheduled" pickups are the rider's primary work — they've already
    // accepted the offer and need to physically go and collect. Treat that
    // state as the headline action: bigger primary chip + accent border on
    // the card so it pops out of the list at a glance.
    final isReady = job.order?.status == 'ReadyForDelivery';
    final isScheduled = isPickup
        && !isAvailable
        && !isInTransit
        && !isAtFacility;

    final statusChipLabel = isAtFacility
        ? 'IN PROCESS'
        : isAvailable
            ? 'NEW'
            : isInTransit
                ? 'TO DROP'
                : isScheduled
                    ? 'SCHEDULED'
                    : (isReady ? 'READY' : 'OUT FOR DELIVERY');
    // Color code (top-to-bottom = lifecycle):
    //   NEW         amber  – needs immediate decision
    //   SCHEDULED   teal   – primary, the rider's next pickup
    //   TO DROP     blue   – in transit back to facility
    //   IN PROCESS  grey   – passive, waiting on facility
    //   READY       green  – delivery is ready to go out
    //   OUT         purple – delivery in flight
    final statusChipColor = isAtFacility
        ? PressoChipColor.grey
        : isAvailable
            ? PressoChipColor.amber
            : isInTransit
                ? PressoChipColor.blue
                : isScheduled
                    ? PressoChipColor.teal
                    : (isReady ? PressoChipColor.green : PressoChipColor.purple);

    final cardBorder = isScheduled
        ? const BorderSide(color: PressoTokens.primary, width: 2)
        : null;

    return PressoCard(
      margin: grid
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(16),
      border: cardBorder,
      onTap: () {
        // At Facility cards are read-only — there's nothing for the rider to
        // act on until a delivery assignment comes in. Tapping is a no-op.
        if (isAtFacility) return;
        if (isAvailable) {
          // Offered assignment: take the rider into the full-screen Job
          // Offer takeover (with countdown + accept/decline). The offer
          // screen is no longer auto-pushed from the dashboard — we only
          // show the timer when the rider explicitly taps a scheduled
          // offer, so unaccepted jobs sit quietly in the list instead of
          // hijacking the UI.
          context.push('/rider/offer', extra: job);
        } else if (isInTransit) {
          context.push('/rider/job/${job.id}/drop');
        } else if (isPickup) {
          context.push('/rider/job/${job.id}');
        } else {
          context.push('/rider/delivery/${job.id}');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: order number · type + status chip
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '#$orderNumber',
                        style: const TextStyle(
                          color: PressoTokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  $typeLabel',
                        style: const TextStyle(
                          color: PressoTokens.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PressoChip(label: statusChipLabel, color: statusChipColor),
              if (job.order?.isExpressDelivery == true) ...[
                const SizedBox(width: 6),
                const PressoChip(
                  label: 'EXPRESS',
                  color: PressoChipColor.red,
                  icon: Icons.bolt,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: subtitle — customer · city
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: PressoTokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Row 3: slot line
          Text(
            slotLine,
            style: const TextStyle(
              fontSize: 12,
              color: PressoTokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Row 4: garments · distance           ₹amount
          Row(
            children: [
              const Text('📦 ', style: TextStyle(fontSize: 13)),
              Text(
                '$count garments',
                style: const TextStyle(
                  fontSize: 12,
                  color: PressoTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (payout != null)
                Text(
                  '₹${payout.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PressoTokens.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty / error states ──────────────────────────────────────────────────
  // Maps the current tab + active search into a key used by `_empty`.
  // Search overrides tab-specific messaging so the rider understands an empty
  // list is because of their query, not because there's no work.
  String _emptyKind(int tabIndex, String? search) {
    if (search != null && search.isNotEmpty) return 'search';
    switch (tabIndex) {
      case 1:
        return 'pickup';
      case 2:
        return 'drop';
      case 3:
        return 'facility';
      case 4:
        return 'delivery';
      default:
        return 'pickup';
    }
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PressoTokens.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search by order number',
            hintStyle: const TextStyle(
                fontSize: 13, color: PressoTokens.textHint),
            prefixIcon: const Icon(Icons.search,
                size: 20, color: PressoTokens.textSecondary),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: PressoTokens.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _searchDebounce?.cancel();
                      ref
                          .read(riderProvider.notifier)
                          .setSearchQuery(null);
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _empty(String type) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _emptyIcon(type),
                size: 60,
                color: PressoTokens.textHint.withValues(alpha: .6),
              ),
              const SizedBox(height: 14),
              Text(
                _emptyMessage(type),
                style: const TextStyle(
                  fontSize: 13,
                  color: PressoTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 11,
                  color: PressoTokens.textHint,
                ),
              ),
            ],
          ),
        ),
      );

  IconData _emptyIcon(String type) {
    switch (type) {
      case 'pickup':
        return Icons.upload_file_outlined;
      case 'drop':
        return Icons.inventory_2_outlined;
      case 'facility':
        return Icons.store_mall_directory_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'search':
        return Icons.search_off;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _emptyMessage(String type) {
    switch (type) {
      case 'pickup':
        return 'No pickup jobs right now';
      case 'drop':
        return 'Nothing to drop at the facility';
      case 'facility':
        return 'No orders in process at the facility';
      case 'delivery':
        return 'No delivery jobs right now';
      case 'search':
        return 'No orders match your search';
      default:
        return 'Nothing here yet';
    }
  }

  Widget _error(String message) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: PressoTokens.red, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: PressoTokens.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              BtnPrimary(
                label: 'Retry',
                onPressed: () =>
                    ref.read(riderProvider.notifier).loadJobs(),
              ),
            ],
          ),
        ),
      );

}

/// Internal helper: pairs an assignment with its resolved type so the "All"
/// tab can mix pickups and deliveries while each card still knows where to
/// navigate on tap.
class _TaggedJob {
  final AssignmentModel job;
  final String type; // 'pickup' | 'delivery'
  const _TaggedJob(this.job, this.type);
}

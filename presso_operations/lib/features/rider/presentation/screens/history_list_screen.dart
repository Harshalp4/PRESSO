// Rider History list — Screen 9 from Presso_Mobile_Wireframes.html.
//
// Shows the rider's completed pickups + deliveries with an inline mini-
// timeline per card so they can glance at the downstream status of each
// past order. Backed by GET /api/riders/me/jobs/history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/rider_provider.dart';

class HistoryListScreen extends ConsumerStatefulWidget {
  const HistoryListScreen({super.key});

  @override
  ConsumerState<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends ConsumerState<HistoryListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderHistoryProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderHistoryProvider);
    // Merge pickup + delivery history, then collapse to one row per order.
    // A rider who both picks up and later delivers the same order otherwise
    // sees the order twice in History. Prefer the delivery assignment when
    // present (it carries the latest status) so the card reflects the most
    // recent leg; fall back to the pickup otherwise.
    final merged = <AssignmentModel>[
      ...(state.jobs?.pickupJobs ?? const <AssignmentModel>[]),
      ...(state.jobs?.deliveryJobs ?? const <AssignmentModel>[]),
    ];
    final byOrderId = <String, AssignmentModel>{};
    for (final job in merged) {
      final key = job.order?.id ?? job.id;
      final existing = byOrderId[key];
      if (existing == null || job.type == 'Delivery') {
        byOrderId[key] = job;
      }
    }
    final completed = byOrderId.values.toList()
      ..sort((a, b) {
        final at = a.completedAt ?? a.assignedAt;
        final bt = b.completedAt ?? b.assignedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: pressoAppBar(title: 'History'),
      body: PhoneColumn(
        child: RefreshIndicator(
          color: PressoTokens.primary,
          onRefresh: () => ref.read(riderHistoryProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            children: [
              if (state.isLoading && state.jobs == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: PressoTokens.primary),
                  ),
                )
              else if (state.error != null && state.jobs == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Center(
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                        color: PressoTokens.textSecondary,
                      ),
                    ),
                  ),
                )
              else if (completed.isEmpty)
                _empty()
              else
                ...completed.map(_historyCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 60,
                color: PressoTokens.textHint.withValues(alpha: .6),
              ),
              const SizedBox(height: 14),
              const Text(
                'No completed pickups yet',
                style: TextStyle(
                  fontSize: 13,
                  color: PressoTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your completed jobs will show here',
                style: TextStyle(
                  fontSize: 11,
                  color: PressoTokens.textHint,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Card with inline mini-timeline ────────────────────────────────────────
  Widget _historyCard(AssignmentModel job) {
    // Map effective order status → step index 0..4
    // 0=Picked, 1=Facility, 2=Wash, 3=OFD, 4=Done.
    //
    // effectiveStatus already flattens OrderStatus.InProcess into the live
    // FacilityStage (AtFacility / Washing / Ironing / Ready) returned by
    // the API, so we see the same progression the facility app does instead
    // of parking every in-flight order at idx=1.
    final orderStatus = job.order?.effectiveStatus ?? '';
    int idx;
    switch (orderStatus) {
      case 'PickedUp':
        idx = 0;
        break;
      case 'AtFacility':
      case 'InProcess':
        idx = 1;
        break;
      case 'Washing':
      case 'Ironing':
        idx = 2;
        break;
      case 'Ready':
      case 'ReadyForDelivery':
        idx = 3;
        break;
      case 'OutForDelivery':
        idx = 3;
        break;
      case 'Delivered':
        idx = 4;
        break;
      default:
        idx = 0;
    }

    return PressoCard(
      onTap: () => context.push(
        '/rider/history/${job.id}',
        extra: job,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${job.order?.orderNumber ?? ''}',
                  style: const TextStyle(
                    color: PressoTokens.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PressoChip(
                label: idx == 4 ? 'DELIVERED' : 'IN TRANSIT',
                color: idx == 4
                    ? PressoChipColor.green
                    : PressoChipColor.teal,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job.customer?.name ?? 'Customer',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PressoTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${job.order?.garmentCount ?? 0} items',
            style: const TextStyle(
              fontSize: 11,
              color: PressoTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          MiniTimeline(
            currentIndex: idx,
            totalSteps: 5,
            labels: const ['Picked', 'Facility', 'Wash', 'OFD', 'Done'],
          ),
        ],
      ),
    );
  }
}

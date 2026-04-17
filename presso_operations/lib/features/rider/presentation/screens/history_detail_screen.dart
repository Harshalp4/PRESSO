// Rider History detail — Screen 10 from Presso_Mobile_Wireframes.html.
//
// Customer-style live tracker for a past pickup, so the rider can see
// exactly where the order is in the facility pipeline and confirm their
// pickup proof photos were saved.

import 'package:flutter/material.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';

class HistoryDetailScreen extends StatelessWidget {
  final AssignmentModel job;
  const HistoryDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    // effectiveStatus collapses the InProcess bucket into its live facility
    // sub-stage (Washing/Ironing/Ready) so the rider sees the real customer
    // view instead of everything pinned at "Dropped at facility".
    final orderStatus = job.order?.effectiveStatus ?? '';
    final idx = _statusIndex(orderStatus);

    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: pressoAppBar(
        title: '#${job.order?.orderNumber ?? ''}',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: PhoneColumn(
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 40),
          children: [
          // Customer header card
          PressoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          PressoTokens.primary.withValues(alpha: .15),
                      child: Text(
                        _initials(job.customer?.name),
                        style: const TextStyle(
                          color: PressoTokens.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.customer?.name ?? 'Customer',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: PressoTokens.textPrimary,
                            ),
                          ),
                          Text(
                            '${job.order?.garmentCount ?? 0} items • '
                            '${job.order?.serviceSummary ?? 'Laundry'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: PressoTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SectionTitle('Live status'),
          PressoCard(
            child: Tracker(
              steps: [
                _step('Picked up', 'From customer', idx, 0),
                _step('Dropped at facility', 'Scanned in', idx, 1),
                _step('Washing / Ironing', 'In processing', idx, 2),
                _step('Out for delivery', 'Rider assigned', idx, 3),
                _step('Delivered', 'Handed to customer', idx, 4),
              ],
            ),
          ),

          const SectionTitle('Pickup proof'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _buildPhotoGrid(job.order?.pickupPhotoUrls ?? const []),
          ),
        ],
        ),
      ),
    );
  }

  int _statusIndex(String s) {
    switch (s) {
      case 'PickedUp':
        return 0;
      case 'AtFacility':
      case 'InProcess':
        return 1;
      case 'Washing':
      case 'Ironing':
        return 2;
      case 'Ready':
      case 'ReadyForDelivery':
      case 'OutForDelivery':
        return 3;
      case 'Delivered':
        return 4;
      default:
        return 0;
    }
  }

  OrderStepItem _step(String title, String sub, int currentIdx, int i) {
    final PressoStepState st;
    if (i < currentIdx) {
      st = PressoStepState.done;
    } else if (i == currentIdx) {
      st = PressoStepState.active;
    } else {
      st = PressoStepState.pending;
    }
    return OrderStepItem(title: title, subtitle: sub, state: st);
  }

  Widget _buildPhotoGrid(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PressoTokens.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 28, color: PressoTokens.textHint),
            SizedBox(height: 6),
            Text(
              'No pickup photos uploaded',
              style: TextStyle(
                fontSize: 11,
                color: PressoTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          urls[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white,
            child: const Icon(Icons.broken_image_outlined,
                color: PressoTokens.textHint),
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

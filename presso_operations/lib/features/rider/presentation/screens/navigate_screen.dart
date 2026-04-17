// Navigate screen — wireframe screen 4. Shown after the rider taps
// "Accept Pickup" on JobDetailScreen. Larger map, teal gradient ETA card,
// compact customer card, and a green "I've Arrived" button that calls
// markArrived and advances to the photo capture screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/jobs_provider.dart';

class NavigateScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const NavigateScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends ConsumerState<NavigateScreen> {
  bool _isMarkingArrived = false;

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Navigate to pickup',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: jobAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load job',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (job) => _buildContent(job),
      ),
    );
  }

  Widget _buildContent(AssignmentModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMap(job),
          const SizedBox(height: 14),
          _buildEtaCard(),
          const SizedBox(height: 14),
          _buildCompactCustomerCard(job),
          const SizedBox(height: 24),
          _buildArrivedButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMap(AssignmentModel job) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation,
                    color: AppColors.primary, size: 48),
                const SizedBox(height: 8),
                Text(
                  job.address?.fullAddress ?? 'Location',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: ElevatedButton.icon(
              onPressed: () {
                final lat = job.address?.latitude;
                final lng = job.address?.longitude;
                if (lat != null && lng != null) {
                  final uri = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Teal gradient ETA card — distance/ETA on the left, turn-by-turn hint on
  // the right. Static for now; will wire to a real routing provider later.
  Widget _buildEtaCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '450 m',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ETA 3 min',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Turn right at Baner Road',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCustomerCard(AssignmentModel job) {
    final name = job.customer?.name ?? 'Customer';
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
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
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  job.address?.fullAddress ?? '',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              final phone = job.customer?.maskedPhone;
              if (phone != null && phone.isNotEmpty) {
                launchUrl(Uri.parse('tel:$phone'));
              }
            },
            icon: const Icon(Icons.phone, color: AppColors.green, size: 22),
            tooltip: 'Call',
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isMarkingArrived
            ? null
            : () async {
                setState(() => _isMarkingArrived = true);
                try {
                  await ref
                      .read(riderRepositoryProvider)
                      .markArrived(widget.assignmentId);
                  if (mounted) {
                    context.pushReplacement(
                        '/rider/job/${widget.assignmentId}/photos');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark arrived: $e'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isMarkingArrived = false);
                }
              },
        icon: _isMarkingArrived
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.location_on, size: 22),
        label: Text(
          _isMarkingArrived ? 'Marking...' : "I've Arrived",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.green.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

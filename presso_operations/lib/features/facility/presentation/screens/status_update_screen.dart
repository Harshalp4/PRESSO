import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/facility/data/facility_repository.dart';
import 'package:presso_operations/features/facility/presentation/providers/facility_provider.dart';

class StatusUpdateScreen extends ConsumerStatefulWidget {
  final String orderId;

  const StatusUpdateScreen({super.key, required this.orderId});

  @override
  ConsumerState<StatusUpdateScreen> createState() =>
      _StatusUpdateScreenState();
}

class _StatusUpdateScreenState extends ConsumerState<StatusUpdateScreen> {
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AtFacility':
        return AppColors.primary;
      case 'Washing':
        return const Color(0xFF00E5FF);
      case 'Ironing':
        return AppColors.amber;
      case 'Ready':
        return AppColors.green;
      case 'PickedUp':
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'AtFacility':
        return 'At Facility';
      case 'Washing':
        return 'Washing';
      case 'Ironing':
        return 'Ironing';
      case 'Ready':
        return 'Ready';
      case 'PickedUp':
        return 'Picked Up';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'AtFacility':
        return Icons.warehouse_outlined;
      case 'Washing':
        return Icons.local_laundry_service;
      case 'Ironing':
        return Icons.iron;
      case 'Ready':
        return Icons.check_circle_outline;
      case 'PickedUp':
        return Icons.delivery_dining;
      default:
        return Icons.circle_outlined;
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'AtFacility':
        return 'Washing';
      case 'Washing':
        return 'Ironing';
      case 'Ironing':
        return 'Ready';
      default:
        return null;
    }
  }

  String _instructionText(String current) {
    switch (current) {
      case 'AtFacility':
        return 'Start the washing machine';
      case 'Washing':
        return 'Transfer to ironing station';
      case 'Ironing':
        return 'Pack and label the order';
      default:
        return '';
    }
  }

  IconData _instructionIcon(String current) {
    switch (current) {
      case 'AtFacility':
        return Icons.local_laundry_service;
      case 'Washing':
        return Icons.iron;
      case 'Ironing':
        return Icons.inventory_2_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _confirmUpdate(String currentStatus, String nextStatus) async {
    setState(() => _isUpdating = true);

    try {
      final repository = ref.read(facilityRepositoryProvider);
      final notes = _notesController.text.trim();
      await repository.updateStatus(
        widget.orderId,
        nextStatus,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (!mounted) return;

      // Refresh data
      ref.read(facilityOrdersProvider.notifier).loadOrders();
      ref.invalidate(facilityOrderDetailProvider(widget.orderId));
      ref.invalidate(facilityStatsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as ${_statusLabel(nextStatus)}'),
          backgroundColor: _statusColor(nextStatus),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      setState(() => _isUpdating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(facilityOrderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Update Status',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load order details',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(
                    facilityOrderDetailProvider(widget.orderId)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (detail) {
          final next = _nextStatus(detail.status);
          if (next == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 64, color: AppColors.green),
                  const SizedBox(height: 16),
                  Text(
                    'No further status updates available',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current status: ${_statusLabel(detail.status)}',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return _buildUpdateContent(detail.status, next, detail.orderNumber);
        },
      ),
    );
  }

  Widget _buildUpdateContent(
      String currentStatus, String nextStatus, String orderNumber) {
    final currentColor = _statusColor(currentStatus);
    final nextColor = _statusColor(nextStatus);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Order number
              Center(
                child: Text(
                  orderNumber,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current → Next status cards
              Row(
                children: [
                  // Current status card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: currentColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(_statusIcon(currentStatus),
                              size: 32, color: currentColor),
                          const SizedBox(height: 8),
                          Text(
                            _statusLabel(currentStatus),
                            style: TextStyle(
                              color: currentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current',
                            style: TextStyle(
                              color: currentColor.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),

                  // Next status card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nextColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: nextColor.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Icon(_statusIcon(nextStatus),
                              size: 32, color: nextColor),
                          const SizedBox(height: 8),
                          Text(
                            _statusLabel(nextStatus),
                            style: TextStyle(
                              color: nextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Next',
                            style: TextStyle(
                              color: nextColor.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Instruction card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: nextColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _instructionIcon(currentStatus),
                        color: nextColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _instructionText(currentStatus),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes field
              Text(
                'Any notes for this update? (optional)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),

        // Confirm button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUpdating
                    ? null
                    : () => _confirmUpdate(currentStatus, nextStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: nextColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirm: Mark as ${_statusLabel(nextStatus)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

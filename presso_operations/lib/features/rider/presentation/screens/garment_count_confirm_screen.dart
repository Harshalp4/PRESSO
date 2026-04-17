import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/jobs_provider.dart';

class GarmentCountConfirmScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final int photosTaken;

  const GarmentCountConfirmScreen({
    super.key,
    required this.assignmentId,
    this.photosTaken = 0,
  });

  @override
  ConsumerState<GarmentCountConfirmScreen> createState() =>
      _GarmentCountConfirmScreenState();
}

class _GarmentCountConfirmScreenState
    extends ConsumerState<GarmentCountConfirmScreen> {
  final Map<String, int> _counts = {};
  final TextEditingController _notesController = TextEditingController();
  bool _initialized = false;
  int _expectedTotal = 0;

  void _initCounts(AssignmentModel job) {
    if (_initialized) return;
    _initialized = true;

    final garmentCount = job.order?.garmentCount ?? 0;
    _expectedTotal = garmentCount;

    final serviceSummary = job.order?.serviceSummary ?? 'Garments';
    _counts[serviceSummary] = garmentCount;
  }

  int get _actualTotal => _counts.values.fold(0, (sum, v) => sum + v);
  bool get _hasMismatch => _actualTotal != _expectedTotal;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
          'Confirm Count',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load job',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (job) {
          _initCounts(job);
          return _buildContent(job);
        },
      ),
    );
  }

  Widget _buildContent(AssignmentModel job) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionCard(),
                const SizedBox(height: 20),
                ..._counts.entries.map((entry) => _buildCounterRow(entry.key)),
                const SizedBox(height: 16),
                _buildTotalRow(),
                if (_hasMismatch) ...[
                  const SizedBox(height: 16),
                  _buildMismatchWarning(),
                  const SizedBox(height: 16),
                  _buildNotesField(),
                ],
              ],
            ),
          ),
        ),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Count all items with the customer present',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Verify each garment count before confirming.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String serviceType) {
    final count = _counts[serviceType] ?? 0;
    final isMatch = count == _expectedTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasMismatch
              ? AppColors.amber.withOpacity(0.4)
              : AppColors.green.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected: $_expectedTotal',
                  style: TextStyle(
                    color: isMatch ? AppColors.green : AppColors.amber,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: count > 0
                      ? () => setState(() => _counts[serviceType] = count - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: AppColors.primary,
                  disabledColor: AppColors.textSecondary.withOpacity(0.3),
                  iconSize: 22,
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: _hasMismatch ? AppColors.amber : AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _counts[serviceType] = count + 1),
                  icon: const Icon(Icons.add),
                  color: AppColors.primary,
                  iconSize: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _hasMismatch
            ? AppColors.amber.withOpacity(0.1)
            : AppColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasMismatch
              ? AppColors.amber.withOpacity(0.4)
              : AppColors.green.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Count',
            style: TextStyle(
              color: _hasMismatch ? AppColors.amber : AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              if (_hasMismatch) ...[
                Text(
                  '$_expectedTotal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward,
                    color: AppColors.amber, size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                '$_actualTotal',
                style: TextStyle(
                  color: _hasMismatch ? AppColors.amber : AppColors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMismatchWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Count Mismatch',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Actual count ($_actualTotal) differs from expected ($_expectedTotal). Please add a note explaining the difference.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Explain why the count is different...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              context.push(
                '/rider/job/${widget.assignmentId}/otp',
                extra: {
                  'count': _actualTotal,
                  'notes': _hasMismatch ? _notesController.text : null,
                  'photosTaken': widget.photosTaken,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Confirm & Get OTP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

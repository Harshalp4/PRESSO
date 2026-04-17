import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';

import 'package:presso_app/features/orders/domain/models/slot_model.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';

class PickupSlotScreen extends ConsumerStatefulWidget {
  const PickupSlotScreen({super.key});

  @override
  ConsumerState<PickupSlotScreen> createState() => _PickupSlotScreenState();
}

class _PickupSlotScreenState extends ConsumerState<PickupSlotScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  bool _hasAutoAdvanced = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate next 7 days
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    // If it's past the last pickup slot window (8 PM), skip today entirely
    // — just like DMart / Zepto / BigBasket do.
    if (now.hour >= 20) {
      _selectedDate = _dates.length > 1 ? _dates[1] : today;
      _hasAutoAdvanced = true;
    } else {
      _selectedDate = today;
    }
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// When slots load and every one is expired/full, auto-advance to the
  /// next date that might have availability (runs only once).
  void _autoAdvanceIfAllExpired(List<SlotModel> slots) {
    if (_hasAutoAdvanced) return;
    final allUnavailable = slots.isNotEmpty &&
        slots.every((s) => !s.isSelectable);
    if (!allUnavailable) return;

    // Find the next date in the list after _selectedDate
    final idx = _dates.indexOf(_selectedDate);
    if (idx >= 0 && idx < _dates.length - 1) {
      _hasAutoAdvanced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = _dates[idx + 1]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(_selectedDate);
    final slotsAsync = ref.watch(slotsProvider(dateStr));
    final flowState = ref.watch(createOrderFlowProvider);
    final notifier = ref.read(createOrderFlowProvider.notifier);
    final selectedSlot = flowState.selectedSlot;
    final selectedAddress = flowState.selectedAddress;
    final isExpress = flowState.isExpressDelivery;

    final now = DateTime.now();

    // Auto-advance past today if all slots are gone
    slotsAsync.whenData(_autoAdvanceIfAllExpired);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pickup Slot', style: AppTextStyles.heading3),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SELECT DATE (matching mockup sec-title) ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text(
                      'SELECT DATE',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  // Date selector (horizontal scroll matching mockup)
                  SizedBox(
                    height: 68,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _dates.length,
                      itemBuilder: (context, i) {
                        final date = _dates[i];
                        final isSelected = date == _selectedDate;
                        final isToday =
                            date == DateTime(now.year, now.month, now.day);
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = date;
                            // User made a manual choice — don't override it
                            _hasAutoAdvanced = true;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: const BoxConstraints(minWidth: 62),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.05)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isToday
                                      ? 'TODAY'
                                      : DateFormat('EEE')
                                          .format(date)
                                          .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── SELECT TIME (matching mockup sec-title) ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'SELECT TIME',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  // Time slots — 2-column grid (matching mockup)
                  slotsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Failed to load slots',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    data: (slots) {
                      if (slots.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.event_busy_rounded,
                                    color: AppColors.textSecondary, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'No slots available',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: slots.map((slot) {
                            final isSelected = selectedSlot?.id == slot.id;
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width -
                                      14 * 2 -
                                      8) /
                                  2,
                              child: _SlotCard(
                                slot: slot,
                                isSelected: isSelected,
                                onTap: slot.isSelectable
                                    ? () => notifier.setSlot(slot)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── DELIVERY ADDRESS (matching mockup) ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'DELIVERY ADDRESS',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () => context.push('/order/address'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 0.5),
                      ),
                      child: selectedAddress != null
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAddress.type == 'work'
                                      ? '\u{1F3E2}'
                                      : '\u{1F3E0}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedAddress.label.isNotEmpty
                                            ? selectedAddress.label
                                            : selectedAddress.type == 'work'
                                                ? 'Work'
                                                : 'Home',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedAddress.fullAddress,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    '\u{2713} Serviceable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Text('\u{1F4CD}',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Select delivery address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.primary, size: 22),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── EXPRESS DELIVERY (matching mockup) ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'EXPRESS DELIVERY',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () => notifier.setExpressDelivery(!isExpress),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isExpress
                            ? AppColors.amber.withOpacity(0.05)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isExpress
                              ? AppColors.amber
                              : AppColors.cardBorder,
                          width: isExpress ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('\u{26A1}',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '24-hr Express',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Get clothes back in 24 hours',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+\u{20B9}30',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isExpress
                                  ? AppColors.amber
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Bottom button (matching mockup: "Review Order →") ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: selectedSlot != null
                    ? () => context.push('/order/address')
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: selectedSlot != null
                        ? const LinearGradient(
                            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                          )
                        : null,
                    color: selectedSlot == null ? AppColors.textHint : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selectedSlot != null
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Review Order \u{2192}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selectedSlot != null
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slot card (matching mockup 2-column grid style) ─────────────────────────

class _SlotCard extends StatelessWidget {
  final SlotModel slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SlotCard({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = slot.isExpired || slot.isFull;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.background
              : isSelected
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDisabled
                    ? AppColors.border.withOpacity(0.4)
                    : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.displayTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isDisabled
                    ? AppColors.textHint
                    : isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                decoration: slot.isExpired ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            _AvailabilityBadge(slot: slot),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final SlotModel slot;
  const _AvailabilityBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    // Expired takes highest priority
    if (slot.isExpired) {
      return _badge('Expired', AppColors.textHint, AppColors.textHint.withOpacity(0.12));
    }
    if (slot.isFull) {
      return _badge('Full', AppColors.red, AppColors.red.withOpacity(0.15));
    }
    final remaining = slot.remainingCount;
    if (remaining == null) {
      return _badge('Available', AppColors.green, AppColors.green.withOpacity(0.12));
    }
    if (slot.isLow) {
      return _badge('$remaining slot${remaining == 1 ? '' : 's'} left',
          AppColors.amber, AppColors.amber.withOpacity(0.12));
    }
    return _badge('Available', AppColors.green, AppColors.green.withOpacity(0.12));
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(savingsProvider.notifier).loadAll();
      ref.read(savingsProvider.notifier).loadCoinHistory(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final config = ref.watch(appConfigProvider);
    final coinRate = config.coinValueRupees;
    final user = ref.watch(authProvider).user;
    final balance = state.coinBalance?.balance ?? user?.coinBalance ?? 0;
    final valueInRupees = (balance * coinRate).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar: My Coins ──
            // No leading back arrow: this screen lives inside the bottom-tab
            // shell, so a back affordance here is dead UI.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'My Coins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          ref.read(savingsProvider.notifier).refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Coin hero (centered) ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 28, horizontal: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text('\u{1FA99}',
                                        style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$balance',
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'coins available (\u20B9$valueInRupees value)',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '1 coin = \u20B9${coinRate.toStringAsFixed(2)} \u2022 Earn 5% on every order',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── RECENT ACTIVITY section title ──
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'RECENT ACTIVITY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Activity card ──
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border, width: 0.8),
                              ),
                              child: state.history.isEmpty
                                  ? _EmptyActivity()
                                  : Column(
                                      children: [
                                        for (int i = 0;
                                            i < state.history.length;
                                            i++) ...[
                                          _ActivityRow(
                                              entry: state.history[i]),
                                          if (i <
                                              state.history.length - 1)
                                            const Divider(
                                              height: 1,
                                              thickness: 0.5,
                                              color: AppColors.divider,
                                              indent: 14,
                                              endIndent: 14,
                                            ),
                                        ],
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 32),

                            // ── Refer & Earn link ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: GestureDetector(
                                onTap: () => context.push('/referral'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text('\u{1F381}',
                                          style:
                                              TextStyle(fontSize: 22)),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Refer friends & earn coins',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons
                                            .arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty activity placeholder ──────────────────────────────────────────────

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          children: const [
            Text('\u{1FA99}', style: TextStyle(fontSize: 28)),
            SizedBox(height: 8),
            Text(
              'No activity yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Place your first order to start earning coins',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity row matching mockup ────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final dynamic entry;

  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final String description;
    final String dateStr;
    final int amount;
    final bool isCredit;

    // entry is LedgerEntry from savings_model.dart
    if (entry is Map) {
      description = entry['description'] ?? '';
      amount = entry['amount'] ?? 0;
      dateStr = '';
      isCredit = amount > 0;
    } else {
      description = entry.description ?? '';
      amount = entry.amount ?? 0;
      dateStr = _formatDate(entry.createdAt);
      isCredit = entry.isCredit;
    }

    // Build label from description or orderNumber
    String label = description;
    if (entry.orderNumber != null && entry.orderNumber!.isNotEmpty) {
      label = 'Order #${entry.orderNumber}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}$amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCredit
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    try {
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/domain/models/earnings_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/jobs_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsProvider(_selectedPeriod));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Earnings',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () =>
                ref.invalidate(earningsProvider(_selectedPeriod)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsProvider(_selectedPeriod));
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              earningsAsync.when(
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to load earnings',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .invalidate(earningsProvider(_selectedPeriod)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (earnings) => _buildEarningsContent(earnings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': 'Week'},
      {'key': 'month', 'label': 'Month'},
    ];

    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(period['label']!),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPeriod = period['key']!);
              }
            },
            selectedColor: AppColors.primary.withOpacity(0.2),
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarningsContent(EarningsResponse earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(earnings),
        const SizedBox(height: 16),
        _buildStatsRow(earnings),
        if (earnings.dailyBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBarChart(earnings.dailyBreakdown),
        ],
        if (earnings.recentJobs.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecentJobsList(earnings.recentJobs),
        ],
      ],
    );
  }

  Widget _buildHeroCard(EarningsResponse earnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green.withOpacity(0.2),
            AppColors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u20b9${earnings.totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${earnings.jobCount} jobs completed',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(EarningsResponse earnings) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pickups',
            '${earnings.pickupCount}',
            AppColors.primary,
            Icons.upload_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Deliveries',
            '${earnings.deliveryCount}',
            AppColors.green,
            Icons.download_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Jobs',
            '${earnings.jobCount}',
            AppColors.amber,
            Icons.work_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<DailyEarning> dailyBreakdown) {
    final maxEarning = dailyBreakdown
        .map((e) => e.earnings)
        .reduce((a, b) => a > b ? a : b);
    final chartMax = maxEarning > 0 ? maxEarning : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Breakdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyBreakdown.map((day) {
                final barHeight = (day.earnings / chartMax) * 120;
                final dayLabel = _formatDayLabel(day.date);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\u20b9${day.earnings.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: max(barHeight, 4),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabel,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } catch (_) {
      return dateStr.length > 3 ? dateStr.substring(0, 3) : dateStr;
    }
  }

  Widget _buildRecentJobsList(List<RecentJob> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Jobs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...jobs.map((job) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: job.type.toLowerCase() == 'pickup'
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      job.type.toLowerCase() == 'pickup'
                          ? Icons.upload_outlined
                          : Icons.download_outlined,
                      color: job.type.toLowerCase() == 'pickup'
                          ? AppColors.primary
                          : AppColors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${job.orderNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              job.type.toUpperCase(),
                              style: TextStyle(
                                color: job.type.toLowerCase() == 'pickup'
                                    ? AppColors.primary
                                    : AppColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (job.customerName != null) ...[
                              Text(' \u2022 ',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              Expanded(
                                child: Text(
                                  job.customerName!,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\u20b9${job.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (job.completedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(job.completedAt!),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

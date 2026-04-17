// Dispatch screen — wireframe screen 14.
//
// Facility staff hits this screen when they mark a Ready order out for
// delivery. The backend's /suggested-rider endpoint returns the closest
// online rider; staff confirms and we POST /dispatch which creates a 60-s
// Offered assignment for the rider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/facility/data/facility_repository.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;

  const DispatchScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  SuggestedRiderModel? _rider;
  bool _loading = true;
  bool _dispatching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(facilityRepositoryProvider)
          .getSuggestedRider(widget.orderId);
      if (!mounted) return;
      setState(() {
        _rider = r;
        _loading = false;
        if (r == null) _error = 'No riders are online right now.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load suggested rider';
      });
    }
  }

  Future<void> _dispatch() async {
    if (_rider == null || _dispatching) return;
    setState(() => _dispatching = true);
    try {
      await ref
          .read(facilityRepositoryProvider)
          .dispatchOrder(widget.orderId, _rider!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offered to ${_rider!.name}'),
          backgroundColor: PressoTokens.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dispatching = false;
        _error = 'Dispatch failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PressoTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Dispatch #${widget.orderNumber}',
          style: const TextStyle(
            color: PressoTokens.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: PhoneColumn(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: PressoTokens.primary),
                )
              : _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_rider == null) {
      return Column(
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: PressoTokens.amber.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_outlined,
                color: PressoTokens.amber, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            _error ?? 'No riders available',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: PressoTokens.textSecondary,
            ),
          ),
          const Spacer(),
          BtnOutline(
            label: 'Refresh',
            icon: Icons.refresh,
            onPressed: _load,
          ),
        ],
      );
    }

    final r = _rider!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Suggested rider'),
        PressoCard(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        PressoTokens.primary.withValues(alpha: .15),
                    child: Text(
                      _initials(r.name),
                      style: const TextStyle(
                        color: PressoTokens.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PressoTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 13, color: PressoTokens.amber),
                            const SizedBox(width: 4),
                            Text(
                              r.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: PressoTokens.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: PressoTokens.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: PressoTokens.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      Icons.straighten,
                      r.distanceKm != null
                          ? '${r.distanceKm!.toStringAsFixed(1)} km'
                          : '—',
                      'distance',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      Icons.schedule,
                      r.distanceKm != null
                          ? '${(r.distanceKm! / 0.4).ceil()} min'
                          : '—',
                      'ETA',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(Icons.timer_outlined, '60s', 'window'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!,
                style: const TextStyle(color: PressoTokens.red, fontSize: 12)),
          ),
        const Spacer(),
        BtnPrimary(
          label: _dispatching
              ? 'Sending offer...'
              : 'Send Offer to ${r.name.split(' ').first}',
          icon: Icons.send,
          onPressed: _dispatching ? null : _dispatch,
        ),
        const SizedBox(height: 8),
        const Text(
          'The rider has 60 seconds to accept. If they don\'t, you can re-dispatch.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: PressoTokens.textHint),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: PressoTokens.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PressoTokens.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: PressoTokens.primary, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PressoTokens.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: PressoTokens.textSecondary,
              ),
            ),
          ],
        ),
      );

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

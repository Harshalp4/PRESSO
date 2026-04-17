import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/loading_overlay.dart';
import 'package:presso_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';
import 'package:presso_app/core/providers/app_config_provider.dart';

class OrderSummaryScreen extends ConsumerStatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  String _paymentMethod = 'online';
  Razorpay? _razorpay;
  bool _isPaymentProcessing = false;

  static const String _razorpayKey = 'rzp_test_YOUR_KEY_HERE';

  static bool get _isRazorpaySupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (_isRazorpaySupported) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ─── Razorpay callbacks ────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isPaymentProcessing = false);
    _placeOrderAfterPayment(
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPaymentProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment failed. Please try again.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPaymentProcessing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRazorpay(double amount) async {
    if (!_isRazorpaySupported || _razorpay == null) {
      if (mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Online Payment', style: AppTextStyles.heading3),
            content: Text(
              'Online payment is available on mobile devices only.\n\nPlace order as Cash on Delivery for now?',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Place as COD', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        );
        if (proceed == true) await _placeOrderAfterPayment();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'Presso Laundry',
      'description': 'Laundry order payment',
      'prefill': {'contact': phone, 'email': email.isNotEmpty ? email : 'customer@presso.in'},
      'theme': {'color': '#00BCD4'},
      'retry': {'enabled': true, 'max_count': 2},
    };
    setState(() => _isPaymentProcessing = true);
    try {
      _razorpay!.open(options);
    } catch (e) {
      setState(() => _isPaymentProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment gateway: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _placeOrderAfterPayment({String? paymentId, String? orderId, String? signature}) async {
    final flowState = ref.read(createOrderFlowProvider);
    if (!flowState.isReadyToOrder) return;
    final createNotifier = ref.read(createOrderProvider.notifier);
    final flowNotifier = ref.read(createOrderFlowProvider.notifier);
    final config = ref.read(appConfigProvider);
    final request = flowNotifier.buildRequest();
    final order = await createNotifier.createOrder(
      request,
      paymentMethod: _paymentMethod,
      totalAmount: flowState.totalFor(coinValueRupees: config.coinValueRupees, expressCharge: config.expressCharge),
      subtotal: flowState.subtotal,
      expressCharge: flowState.expressChargeFor(expressCharge: config.expressCharge),
      coinsRedeemed: flowState.coinsToRedeem,
      selectedServices: flowState.selectedServices,
    );
    if (!mounted) return;
    if (order != null) {
      flowNotifier.reset();
      context.push('/order/confirmed', extra: order.id);
    } else {
      final error = ref.read(createOrderProvider).error;
      if (error != null) {
        if (error.contains('not found')) {
          flowNotifier.reset();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Services were updated. Please re-select your items.'), backgroundColor: AppColors.amber, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 4)),
            );
            context.go('/order/services');
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  Future<void> _placeOrder(double total) async {
    if (_paymentMethod == 'online') {
      _openRazorpay(total);
    } else {
      await _placeOrderAfterPayment();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(createOrderFlowProvider);
    final createState = ref.watch(createOrderProvider);
    final authState = ref.watch(authProvider);
    final isStudentVerified = authState.user?.isStudentVerified ?? false;

    final config = ref.watch(appConfigProvider);
    final studentDiscountPct = config.studentDiscountPercent / 100.0;
    final expressChargeAmount = config.expressCharge;
    final coinsEarnedPct = config.coinsEarnedPercent;

    final subtotal = flowState.subtotal;
    final studentDiscount = isStudentVerified ? subtotal * studentDiscountPct : 0.0;
    final coinDiscount = flowState.coinDiscountFor(coinValueRupees: config.coinValueRupees);
    final expressCharge = flowState.isExpressDelivery ? expressChargeAmount : 0.0;
    final total = (subtotal - studentDiscount - coinDiscount + expressCharge).clamp(0.0, double.infinity);

    final slot = flowState.selectedSlot;
    final address = flowState.selectedAddress;
    final isReady = flowState.isReadyToOrder;
    final isBusy = createState.isLoading || _isPaymentProcessing;

    // Coins earned (mockup: 5% of total)
    final coinsEarned = (total * coinsEarnedPct / 100).round();
    final coinsValue = coinsEarned * config.coinValueRupees;

    // What's missing?
    final missingSlot = slot == null;
    final missingAddress = address == null;

    return LoadingOverlay(
      isLoading: createState.isLoading,
      message: 'Placing your order...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Order Summary', style: AppTextStyles.heading3),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // ── MISSING ITEMS BANNER ──
                    if (missingSlot || missingAddress)
                      _MissingItemsBanner(
                        missingSlot: missingSlot,
                        missingAddress: missingAddress,
                        onSelectSlot: () => context.push('/order/slots'),
                        onSelectAddress: () => context.push('/order/address'),
                      ),

                    // ── ORDER ITEMS (grouped by service) ──
                    const _SectionTitle(title: 'ORDER ITEMS'),

                    ...flowState.selectedServices.where((service) {
                      return service.garmentTypes.any((g) {
                        final key = '${service.id}_${g.id}';
                        return (flowState.garmentCounts[key] ?? 0) > 0;
                      });
                    }).map((service) {
                      final items = service.garmentTypes.where((g) {
                        final key = '${service.id}_${g.id}';
                        return (flowState.garmentCounts[key] ?? 0) > 0;
                      }).toList();

                      double serviceTotal = 0;
                      for (final g in items) {
                        final key = '${service.id}_${g.id}';
                        final qty = flowState.garmentCounts[key] ?? 0;
                        final basePrice = g.priceOverride ?? service.pricePerPiece;
                        final treatmentId = flowState.treatmentSelections[key];
                        final treatment = treatmentId != null
                            ? service.treatments.cast<dynamic>().firstWhere((t) => t.id == treatmentId, orElse: () => null)
                            : null;
                        final multiplier = treatment?.priceMultiplier ?? 1.0;
                        serviceTotal += basePrice * multiplier * qty;
                      }

                      return Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      service.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                  Text(
                                    '\u{20B9}${serviceTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            // Garment rows
                            ...items.map((g) {
                              final key = '${service.id}_${g.id}';
                              final qty = flowState.garmentCounts[key] ?? 0;
                              final basePrice = g.priceOverride ?? service.pricePerPiece;
                              final treatmentId = flowState.treatmentSelections[key];
                              final treatment = treatmentId != null
                                  ? service.treatments.cast<dynamic>().firstWhere((t) => t.id == treatmentId, orElse: () => null)
                                  : null;
                              final multiplier = treatment?.priceMultiplier ?? 1.0;
                              final itemTotal = basePrice * multiplier * qty;
                              final label = treatment != null ? '${g.name} (${treatment.name})' : g.name;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  children: [
                                    Text('${qty}x ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                    Text('\u{20B9}${itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 4),
                          ],
                        ),
                      );
                    }),

                    // ── PRICE BREAKDOWN ──
                    const _SectionTitle(title: 'PRICE BREAKDOWN'),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Column(
                        children: [
                          _PriceRow(label: 'Subtotal (${flowState.totalItemCount} items)', value: '\u{20B9}${subtotal.toStringAsFixed(0)}'),
                          const SizedBox(height: 6),
                          _PriceRow(label: 'Delivery', value: 'FREE', valueColor: AppColors.green),
                          if (isStudentVerified) ...[
                            const SizedBox(height: 6),
                            _PriceRow(label: 'Student discount (${config.studentDiscountPercent}%)', value: '-\u{20B9}${studentDiscount.toStringAsFixed(0)}', valueColor: AppColors.green),
                          ],
                          if (flowState.coinsToRedeem > 0) ...[
                            const SizedBox(height: 6),
                            _PriceRow(label: 'Coins redeemed (${flowState.coinsToRedeem})', value: '-\u{20B9}${coinDiscount.toStringAsFixed(0)}', valueColor: AppColors.green),
                          ],
                          if (flowState.isExpressDelivery) ...[
                            const SizedBox(height: 6),
                            _PriceRow(label: 'Express delivery (\u{26A1})', value: '+\u{20B9}${expressCharge.toStringAsFixed(0)}', valueColor: AppColors.amber),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.only(top: 8),
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text('\u{20B9}${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── PICKUP DETAILS (tappable to edit) ──
                    const _SectionTitle(title: 'PICKUP DETAILS'),

                    GestureDetector(
                      onTap: () => context.push('/order/slots'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: missingSlot ? AppColors.amber : AppColors.cardBorder,
                            width: missingSlot ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Slot
                                  Row(
                                    children: [
                                      const Text('\u{1F4C5} ', style: TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          slot != null ? '${slot.date} \u{00B7} ${slot.displayTime}' : 'Select a pickup slot',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: slot != null ? AppColors.textSecondary : AppColors.amber,
                                            fontWeight: slot != null ? FontWeight.w400 : FontWeight.w600,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Address
                                  Row(
                                    children: [
                                      Text(address != null ? (address.type == 'work' ? '\u{1F3E2} ' : '\u{1F3E0} ') : '\u{1F4CD} ', style: const TextStyle(fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          address != null ? address.fullAddress : 'Select a delivery address',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: address != null ? AppColors.textSecondary : AppColors.amber,
                                            fontWeight: address != null ? FontWeight.w400 : FontWeight.w600,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Delivery type
                                  Row(
                                    children: [
                                      const Text('\u{1F69A} ', style: TextStyle(fontSize: 14)),
                                      Text(
                                        flowState.isExpressDelivery
                                            ? 'Express Delivery (${config.deliveryHoursExpress} hrs)'
                                            : 'Standard Delivery (${config.deliveryHoursStandard} hrs)',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── COINS EARNED ──
                    if (coinsEarned > 0) ...[
                      const _SectionTitle(title: 'COINS EARNED'),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.amber.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Text('\u{1FA99}', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('+$coinsEarned coins earned!', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$coinsEarnedPct% of \u{20B9}${total.toStringAsFixed(0)} = $coinsEarned coins (\u{20B9}${coinsValue.toStringAsFixed(2)} value)',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

            // ── BOTTOM PAYMENT BAR ──
            _PaymentBar(
              total: total,
              isReady: isReady,
              isBusy: isBusy,
              missingSlot: missingSlot,
              missingAddress: missingAddress,
              onPayOnline: () {
                setState(() => _paymentMethod = 'online');
                _placeOrder(total);
              },
              onPayCash: () {
                setState(() => _paymentMethod = 'cash');
                _placeOrder(total);
              },
              onSelectSlot: () => context.push('/order/slots'),
              onSelectAddress: () => context.push('/order/address'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Missing items banner ────────────────────────────────────────────────────

class _MissingItemsBanner extends StatelessWidget {
  final bool missingSlot;
  final bool missingAddress;
  final VoidCallback onSelectSlot;
  final VoidCallback onSelectAddress;

  const _MissingItemsBanner({
    required this.missingSlot,
    required this.missingAddress,
    required this.onSelectSlot,
    required this.onSelectAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('\u{26A0}\u{FE0F}', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text('Complete before placing order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          if (missingSlot)
            GestureDetector(
              onTap: onSelectSlot,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Center(child: Text('\u{1F4C5}', style: TextStyle(fontSize: 11))),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Select a pickup slot', style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600))),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.amber),
                  ],
                ),
              ),
            ),
          if (missingAddress)
            GestureDetector(
              onTap: onSelectAddress,
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Center(child: Text('\u{1F4CD}', style: TextStyle(fontSize: 11))),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Select a delivery address', style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600))),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.amber),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      ),
    );
  }
}

// ─── Price row ───────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

// ─── Payment bar ─────────────────────────────────────────────────────────────

class _PaymentBar extends StatelessWidget {
  final double total;
  final bool isReady;
  final bool isBusy;
  final bool missingSlot;
  final bool missingAddress;
  final VoidCallback onPayOnline;
  final VoidCallback onPayCash;
  final VoidCallback onSelectSlot;
  final VoidCallback onSelectAddress;

  const _PaymentBar({
    required this.total,
    required this.isReady,
    required this.isBusy,
    required this.missingSlot,
    required this.missingAddress,
    required this.onPayOnline,
    required this.onPayCash,
    required this.onSelectSlot,
    required this.onSelectAddress,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = isReady && !isBusy;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // If not ready, show what's missing as a tappable hint
            if (!isReady && !isBusy) ...[
              GestureDetector(
                onTap: missingSlot ? onSelectSlot : (missingAddress ? onSelectAddress : null),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('\u{26A0}\u{FE0F} ', style: TextStyle(fontSize: 12)),
                      Flexible(
                        child: Text(
                          missingSlot && missingAddress
                              ? 'Select pickup slot & address to continue'
                              : missingSlot
                                  ? 'Select a pickup slot to continue'
                                  : 'Select a delivery address to continue',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Pay Online — Razorpay button (always full width)
            GestureDetector(
              onTap: canPay ? onPayOnline : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: canPay
                      ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)])
                      : null,
                  color: !canPay ? AppColors.textHint.withOpacity(0.4) : null,
                  boxShadow: canPay
                      ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  children: [
                    Text('Pay securely with', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(canPay ? 0.7 : 0.4))),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Razorpay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(canPay ? 1 : 0.5), letterSpacing: 0.5)),
                        Text('  \u{00B7}  \u{20B9}${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(canPay ? 1 : 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Cash on Delivery — visible secondary button
            GestureDetector(
              onTap: canPay ? onPayCash : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: canPay ? AppColors.surface : AppColors.background,
                  border: Border.all(color: canPay ? AppColors.primary : AppColors.border, width: canPay ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_rounded, size: 16, color: canPay ? AppColors.primary : AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      'Cash on Pickup \u{00B7} \u{20B9}${total.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: canPay ? AppColors.primary : AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

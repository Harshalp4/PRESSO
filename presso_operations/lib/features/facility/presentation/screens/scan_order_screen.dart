import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/facility/data/facility_repository.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_detail_model.dart';
import 'package:presso_operations/features/facility/presentation/providers/facility_provider.dart';

class ScanOrderScreen extends ConsumerStatefulWidget {
  const ScanOrderScreen({super.key});

  @override
  ConsumerState<ScanOrderScreen> createState() => _ScanOrderScreenState();
}

class _ScanOrderScreenState extends ConsumerState<ScanOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderNumberController = TextEditingController();
  bool _isSearching = false;
  bool _isConfirming = false;
  FacilityOrderDetailModel? _scannedOrder;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _searchOrder() async {
    final orderNumber = _orderNumberController.text.trim();
    if (orderNumber.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _scannedOrder = null;
    });

    try {
      final repository = ref.read(facilityRepositoryProvider);
      final order = await repository.scanOrder(orderNumber);
      setState(() {
        _scannedOrder = order;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Order not found. Please check the order number and try again.';
        _isSearching = false;
      });
    }
  }

  Future<void> _confirmReceipt() async {
    if (_scannedOrder == null) return;

    setState(() => _isConfirming = true);

    try {
      final repository = ref.read(facilityRepositoryProvider);
      await repository.updateStatus(_scannedOrder!.id, 'AtFacility');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Order ${_scannedOrder!.orderNumber} received at facility'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh orders list
      ref.read(facilityOrdersProvider.notifier).loadOrders();
      ref.invalidate(facilityStatsProvider);

      setState(() {
        _scannedOrder = null;
        _orderNumberController.clear();
        _isConfirming = false;
      });
    } catch (e) {
      setState(() => _isConfirming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm receipt. Please try again.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Receive Order',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Manual Entry'),
            Tab(text: 'QR Scan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualEntryTab(),
          _buildQRScanTab(),
        ],
      ),
    );
  }

  Widget _buildManualEntryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Text(
          'Enter Order Number',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: PRE-YYYYMMDD-XXXX',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _orderNumberController,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'PRE-20260317-0001',
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _searchOrder(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Search',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style:
                        const TextStyle(color: AppColors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Scanned order card
        if (_scannedOrder != null) ...[
          const SizedBox(height: 20),
          _buildScannedOrderCard(_scannedOrder!),
        ],
      ],
    );
  }

  Widget _buildScannedOrderCard(FacilityOrderDetailModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.green, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Order Found',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow('Order', order.orderNumber),
          _detailRow('Customer', order.customerName),
          _detailRow('Garments', '${order.garmentCount} items'),
          _detailRow('Status', _statusLabel(order.status)),
          if (order.hasShoeItems)
            _detailRow('Shoes', '${order.shoeItems.length} shoe item(s)'),
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.specialInstructions!,
                      style: const TextStyle(
                          color: AppColors.amber, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirmReceipt,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(
                _isConfirming ? 'Confirming...' : 'Confirm Receipt',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Scanner',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use the Manual Entry tab to search for orders by their order number.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

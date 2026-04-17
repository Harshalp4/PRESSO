import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/admin/domain/models/service_zone_model.dart';
import 'package:presso_operations/features/admin/presentation/providers/admin_provider.dart';

class CreateZoneScreen extends ConsumerStatefulWidget {
  final String? zoneId; // null = create, non-null = edit

  const CreateZoneScreen({super.key, this.zoneId});

  @override
  ConsumerState<CreateZoneScreen> createState() => _CreateZoneScreenState();
}

class _CreateZoneScreenState extends ConsumerState<CreateZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _isActive = true;
  ServiceZoneModel? _existingZone;

  bool get _isEditing => widget.zoneId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingZone();
    } else {
      // Default city for new zones in Navi Mumbai
      _cityController.text = 'Navi Mumbai';
    }
  }

  void _loadExistingZone() {
    final zones = ref.read(serviceZonesProvider).zones;
    final zone = zones.where((z) => z.id == widget.zoneId).firstOrNull;
    if (zone != null) {
      _existingZone = zone;
      _nameController.text = zone.name;
      _pincodeController.text = zone.pincode;
      _cityController.text = zone.city;
      _areaController.text = zone.area ?? '';
      _descriptionController.text = zone.description ?? '';
      _isActive = zone.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'city': _cityController.text.trim(),
    };

    if (_areaController.text.trim().isNotEmpty) {
      data['area'] = _areaController.text.trim();
    }
    if (_descriptionController.text.trim().isNotEmpty) {
      data['description'] = _descriptionController.text.trim();
    }

    if (_isEditing) {
      data['isActive'] = _isActive;
    }

    String? error;
    if (_isEditing) {
      error = await ref
          .read(serviceZonesProvider.notifier)
          .updateZone(widget.zoneId!, data);
    } else {
      error = await ref
          .read(serviceZonesProvider.notifier)
          .createZone(data);
    }

    setState(() => _isSubmitting = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.red,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Zone updated' : 'Zone created'),
          backgroundColor: AppColors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Zone' : 'Add Service Zone',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Zone name
            _buildLabel('Zone Name *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Nerul, Vashi, Belapur',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Zone name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Pincode
            _buildLabel('Pincode *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _pincodeController,
              hint: 'e.g. 400706',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Pincode is required';
                }
                if (v.trim().length != 6) {
                  return 'Pincode must be exactly 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // City
            _buildLabel('City *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _cityController,
              hint: 'e.g. Navi Mumbai',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'City is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Area (optional)
            _buildLabel('Area'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _areaController,
              hint: 'e.g. Sector 19, Palm Beach Road',
            ),
            const SizedBox(height: 20),

            // Description (optional)
            _buildLabel('Description'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Optional notes about this zone',
              maxLines: 3,
            ),

            // Active toggle (edit mode only)
            if (_isEditing) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zone Active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isActive
                              ? 'Accepting orders from this zone'
                              : 'Orders blocked from this zone',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.green,
                      inactiveThumbColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Zone' : 'Create Zone',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Quick-add hint for create mode
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Navi Mumbai Pincodes',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nerul: 400706\n'
                      'Vashi: 400703\n'
                      'Belapur: 400614\n'
                      'Kharghar: 410210\n'
                      'Panvel: 410206',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        errorStyle: const TextStyle(color: AppColors.red),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/presso_button.dart';
import '../../../../core/widgets/presso_text_field.dart';
import '../../data/profile_repository.dart';
import '../providers/profile_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;
  bool _isFetchingLocation = false;
  bool _isFetchingPincode = false;

  // Service zone check
  bool? _isServiceable; // null = not checked, true/false = result
  String? _serviceabilityMessage;

  // GPS data
  double? _latitude;
  double? _longitude;
  String? _locationPreview; // short text shown in the map area

  final List<String> _labels = ['Home', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_onPincodeChanged);
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pin = _pincodeController.text.trim();
    if (pin.length == 6) {
      _lookupPincode(pin);
    } else {
      // Reset serviceability when pincode changes
      if (_isServiceable != null) {
        setState(() {
          _isServiceable = null;
          _serviceabilityMessage = null;
        });
      }
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isFetchingPincode = true);
    bool filled = false;
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio
          .get('https://api.postalpincode.in/pincode/$pincode');
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        final result = data[0] as Map<String, dynamic>;
        if (result['Status'] == 'Success') {
          final postOffices =
              result['PostOffice'] as List<dynamic>? ?? [];
          if (postOffices.isNotEmpty) {
            final po = postOffices[0] as Map<String, dynamic>;
            final district = po['District'] as String? ?? '';
            final stateName = po['State'] as String? ?? '';
            final area = po['Name'] as String? ?? '';
            if (mounted) {
              setState(() {
                if (district.isNotEmpty) _cityController.text = district;
                if (stateName.isNotEmpty) _stateController.text = stateName;
                if (_line2Controller.text.trim().isEmpty &&
                    area.isNotEmpty) {
                  _line2Controller.text = area;
                }
              });
              filled = true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Pincode lookup failed: $e');
    }

    // Fallback: try reverse geocoding from pincode using geocoding package
    if (!filled && mounted) {
      try {
        final locations = await locationFromAddress('$pincode, India');
        if (locations.isNotEmpty) {
          final placemarks = await placemarkFromCoordinates(
            locations.first.latitude,
            locations.first.longitude,
          );
          if (placemarks.isNotEmpty && mounted) {
            final p = placemarks.first;
            setState(() {
              if (p.subAdministrativeArea != null &&
                  p.subAdministrativeArea!.isNotEmpty) {
                _cityController.text = p.subAdministrativeArea!;
              } else if (p.locality != null && p.locality!.isNotEmpty) {
                _cityController.text = p.locality!;
              }
              if (p.administrativeArea != null &&
                  p.administrativeArea!.isNotEmpty) {
                _stateController.text = p.administrativeArea!;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Geocoding pincode fallback failed: $e');
      }
    }
    // Check if this pincode is in our service area
    if (mounted) {
      try {
        final result = await ref
            .read(profileRepositoryProvider)
            .checkPincodeServiceability(pincode);
        if (mounted) {
          setState(() {
            _isServiceable = result.isServiceable;
            _serviceabilityMessage = result.message;
          });
        }
      } catch (_) {
        // Don't block on serviceability check failure
      }
    }

    if (mounted) setState(() => _isFetchingPincode = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Block if pincode is not serviceable
    if (_isServiceable == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _serviceabilityMessage ??
                'We don\'t currently serve this pincode. Please use a Navi Mumbai pincode.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Block if serviceability hasn't been checked yet
    if (_isServiceable == null && _pincodeController.text.trim().length == 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we verify your pincode.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final body = {
      'label': _selectedLabel,
      'addressLine1': _line1Controller.text.trim(),
      'addressLine2': _line2Controller.text.trim().isEmpty
          ? null
          : _line2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'isDefault': _isDefault,
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
    };

    final success = await ref.read(profileProvider.notifier).addAddress(body);
    setState(() => _isSaving = false);

    if (success && mounted) {
      context.pop(true); // return true so caller knows address was added
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save address. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnack('Location services are disabled. Please enable GPS.');
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnack('Location permission denied.');
          setState(() => _isFetchingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnack(
              'Location permission permanently denied. Enable in Settings.');
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode to get address
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;

          // Build address line 1
          final parts = <String>[];
          if (place.subThoroughfare != null &&
              place.subThoroughfare!.isNotEmpty) {
            parts.add(place.subThoroughfare!);
          }
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            parts.add(place.thoroughfare!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            parts.add(place.subLocality!);
          }
          final line1 = parts.isNotEmpty ? parts.join(', ') : '';

          // Build address line 2
          final line2Parts = <String>[];
          if (place.locality != null &&
              place.locality!.isNotEmpty &&
              place.locality != place.subLocality) {
            // skip if same as subLocality
          }
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            line2Parts.add(place.subAdministrativeArea!);
          }
          final line2 = line2Parts.join(', ');

          setState(() {
            if (line1.isNotEmpty) _line1Controller.text = line1;
            if (line2.isNotEmpty) _line2Controller.text = line2;
            if (place.locality != null && place.locality!.isNotEmpty) {
              _cityController.text = place.locality!;
            } else if (place.subAdministrativeArea != null) {
              _cityController.text = place.subAdministrativeArea!;
            }
            if (place.postalCode != null && place.postalCode!.isNotEmpty) {
              _pincodeController.text = place.postalCode!;
            }
            _locationPreview =
                '${place.subLocality ?? ''}, ${place.locality ?? ''}'
                    .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          });
        }
      } catch (geocodeError) {
        // Geocoding failed but we still have coordinates
        if (mounted) {
          setState(() {
            _locationPreview =
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
          _showSnack(
              'Got your location but could not determine address. Please fill manually.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not get location. Please try again.');
      }
    }

    if (mounted) setState(() => _isFetchingLocation = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Address', style: AppTextStyles.heading2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Map / Location Area ──
              GestureDetector(
                onTap: _isFetchingLocation ? null : _useMyLocation,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Center content — either location info or placeholder
                      if (_isFetchingLocation)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Fetching your location...',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      else if (_locationPreview != null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _locationPreview!,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_latitude != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: AppColors.textHint,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to detect your location',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                      // "Use my location" button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _isFetchingLocation ? null : _useMyLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isFetchingLocation
                                      ? Icons.hourglass_top_rounded
                                      : Icons.my_location_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isFetchingLocation
                                      ? 'Locating...'
                                      : _locationPreview != null
                                          ? 'Refresh'
                                          : 'Use my location',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Label Pills ──
              Text(
                'LABEL',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _labels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLabel = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.body.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Address Line 1 ──
              PressoTextField(
                label: 'Address Line 1',
                hint: 'House/flat number, street name',
                controller: _line1Controller,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ── Address Line 2 ──
              PressoTextField(
                label: 'Address Line 2 (optional)',
                hint: 'Landmark, area',
                controller: _line2Controller,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              // ── Pincode (first — auto-fills city & state) ──
              PressoTextField(
                label: 'Pincode',
                hint: '6-digit pincode',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                suffixWidget: _isFetchingPincode
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      )
                    : (_cityController.text.isNotEmpty &&
                            _pincodeController.text.length == 6)
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.green, size: 18)
                        : null,
                validator: (v) {
                  if (v == null || v.trim().length != 6) {
                    return 'Enter a valid 6-digit pincode';
                  }
                  return null;
                },
              ),

              // ── Serviceability banner ──
              if (_isServiceable != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isServiceable!
                        ? AppColors.green.withOpacity(0.1)
                        : AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isServiceable!
                          ? AppColors.green.withOpacity(0.3)
                          : AppColors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isServiceable!
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 18,
                        color: _isServiceable!
                            ? AppColors.green
                            : AppColors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serviceabilityMessage ??
                              (_isServiceable!
                                  ? 'This area is serviceable!'
                                  : 'We don\'t serve this area yet.'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isServiceable!
                                ? AppColors.green
                                : AppColors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── City & State (auto-filled from pincode) ──
              Row(
                children: [
                  Expanded(
                    child: PressoTextField(
                      label: 'City',
                      hint: 'Auto-filled',
                      controller: _cityController,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PressoTextField(
                      label: 'State',
                      hint: 'Auto-filled',
                      controller: _stateController,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Set as Default Toggle ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set as default address',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Save Button ──
              PressoButton(
                label: 'Save Address',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

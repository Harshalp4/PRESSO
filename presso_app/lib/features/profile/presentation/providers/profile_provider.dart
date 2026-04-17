import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/profile_repository.dart';

// ── Profile State ──────────────────────────────────────────────────────────────

class ProfileState {
  final bool isLoading;
  final String? error;
  final List<AddressModel> addresses;
  final bool addressLoading;
  final List<NotificationModel> notifications;
  final bool notificationLoading;
  final bool studentVerifyLoading;
  final bool studentVerifySubmitted;
  final String? studentVerifyError;
  final String? studentVerifySuccess;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.addresses = const [],
    this.addressLoading = false,
    this.notifications = const [],
    this.notificationLoading = false,
    this.studentVerifyLoading = false,
    this.studentVerifySubmitted = false,
    this.studentVerifyError,
    this.studentVerifySuccess,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    List<AddressModel>? addresses,
    bool? addressLoading,
    List<NotificationModel>? notifications,
    bool? notificationLoading,
    bool? studentVerifyLoading,
    bool? studentVerifySubmitted,
    String? studentVerifyError,
    String? studentVerifySuccess,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      addresses: addresses ?? this.addresses,
      addressLoading: addressLoading ?? this.addressLoading,
      notifications: notifications ?? this.notifications,
      notificationLoading: notificationLoading ?? this.notificationLoading,
      studentVerifyLoading: studentVerifyLoading ?? this.studentVerifyLoading,
      studentVerifySubmitted:
          studentVerifySubmitted ?? this.studentVerifySubmitted,
      studentVerifyError: studentVerifyError,
      studentVerifySuccess: studentVerifySuccess,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super(const ProfileState());

  // ── Addresses ──

  Future<void> loadAddresses() async {
    state = state.copyWith(addressLoading: true, error: null);

    // Try API first
    final res = await _repo.getAddresses();
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      state = state.copyWith(addressLoading: false, addresses: res.data!);
      await _saveAddressesToDisk(res.data!);
      return;
    }

    // API failed — load from local storage
    final local = await _loadAddressesFromDisk();
    state = state.copyWith(addressLoading: false, addresses: local);
  }

  Future<bool> addAddress(Map<String, dynamic> body) async {
    state = state.copyWith(addressLoading: true);

    // Try API first
    final res = await _repo.createAddress(body);
    AddressModel newAddress;
    if (res.success && res.data != null) {
      newAddress = res.data!;
    } else {
      // API failed — create local address
      newAddress = AddressModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        label: body['label'] as String? ?? 'Home',
        addressLine1: body['addressLine1'] as String? ?? '',
        addressLine2: body['addressLine2'] as String?,
        city: body['city'] as String? ?? '',
        pincode: body['pincode'] as String? ?? '',
        isDefault: body['isDefault'] as bool? ?? false,
        latitude: body['latitude'] as double?,
        longitude: body['longitude'] as double?,
      );
    }

    // Read existing addresses from local storage, then append
    final existing = await _loadAddressesFromDisk();
    final merged = [...existing, newAddress];

    state = state.copyWith(addressLoading: false, addresses: merged);
    await _saveAddressesToDisk(merged);
    return true;
  }

  Future<List<AddressModel>> _loadAddressesFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('saved_addresses');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(AddressModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAddressesToDisk(List<AddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = addresses.map((a) => a.toJson()).toList();
    await prefs.setString('saved_addresses', jsonEncode(jsonList));
  }

  Future<bool> updateAddress(String id, Map<String, dynamic> body) async {
    state = state.copyWith(addressLoading: true);
    final res = await _repo.updateAddress(id, body);
    if (res.success && res.data != null) {
      final updated = state.addresses
          .map((a) => a.id == id ? res.data! : a)
          .toList();
      state = state.copyWith(addressLoading: false, addresses: updated);
      return true;
    }
    state = state.copyWith(addressLoading: false);
    return false;
  }

  Future<bool> deleteAddress(String id) async {
    state = state.copyWith(addressLoading: true);
    await _repo.deleteAddress(id); // try API, ignore result
    final updated = state.addresses.where((a) => a.id != id).toList();
    state = state.copyWith(addressLoading: false, addresses: updated);
    await _saveAddressesToDisk(updated);
    return true;
  }

  Future<bool> setDefaultAddress(String id) async {
    final res = await _repo.setDefaultAddress(id);
    if (res.success) {
      final updated = state.addresses
          .map((a) => a.copyWith(isDefault: a.id == id))
          .toList();
      state = state.copyWith(addresses: updated);
      return true;
    }
    return false;
  }

  // ── Notifications ──

  Future<void> loadNotifications() async {
    state = state.copyWith(notificationLoading: true, error: null);
    final res = await _repo.getNotifications();
    state = state.copyWith(
      notificationLoading: false,
      notifications: res.data ?? [],
      error: res.success ? null : res.message,
    );
  }

  Future<void> markAsRead(String id) async {
    final res = await _repo.markAsRead(id);
    if (res.success) {
      final updated = state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      state = state.copyWith(notifications: updated);
    }
  }

  Future<void> markAllRead() async {
    final res = await _repo.markAllRead();
    if (res.success) {
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updated);
    }
  }

  // ── Student Verification ──

  Future<void> submitStudentVerification(File imageFile) async {
    state = state.copyWith(
      studentVerifyLoading: true,
      studentVerifyError: null,
      studentVerifySuccess: null,
    );

    final res = await _repo.submitStudentVerification(imageFile);

    state = state.copyWith(
      studentVerifyLoading: false,
      studentVerifySubmitted: res.success,
      studentVerifySuccess:
          res.success ? (res.data ?? 'Submitted for review') : null,
      studentVerifyError: res.success ? null : res.message,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo);
});

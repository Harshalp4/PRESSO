import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/referral_repository.dart';
import '../../domain/models/referral_model.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class ReferralState {
  final bool isLoading;
  final String? error;
  final ReferralStats? stats;
  final List<ReferralHistory> history;
  final bool applyLoading;
  final String? applyError;
  final String? applySuccess;

  const ReferralState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.history = const [],
    this.applyLoading = false,
    this.applyError,
    this.applySuccess,
  });

  ReferralState copyWith({
    bool? isLoading,
    String? error,
    ReferralStats? stats,
    List<ReferralHistory>? history,
    bool? applyLoading,
    String? applyError,
    String? applySuccess,
  }) {
    return ReferralState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      applyLoading: applyLoading ?? this.applyLoading,
      applyError: applyError,
      applySuccess: applySuccess,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class ReferralNotifier extends StateNotifier<ReferralState> {
  final ReferralRepository _repo;

  ReferralNotifier(this._repo) : super(const ReferralState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final statsRes = await _repo.getMyCode();
    final historyRes = await _repo.getHistory();

    state = state.copyWith(
      isLoading: false,
      stats: statsRes.data,
      history: historyRes.data ?? [],
      error: statsRes.success ? null : statsRes.message,
    );
  }

  Future<bool> applyCode(String code) async {
    state = state.copyWith(
      applyLoading: true,
      applyError: null,
      applySuccess: null,
    );

    final res = await _repo.applyCode(code);

    state = state.copyWith(
      applyLoading: false,
      applyError: res.success ? null : res.message,
      applySuccess: res.success ? (res.data ?? 'Applied!') : null,
    );

    return res.success;
  }

  Future<void> refresh() => load();
}

// ── Provider ───────────────────────────────────────────────────────────────────

final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final repo = ref.watch(referralRepositoryProvider);
  return ReferralNotifier(repo);
});

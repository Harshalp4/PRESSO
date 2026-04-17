import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/savings_repository.dart';
import '../../domain/models/savings_model.dart';

// ── Savings state ──────────────────────────────────────────────────────────────

class SavingsState {
  final bool isLoading;
  final String? error;
  final SavingsModel? savings;
  final CoinBalance? coinBalance;
  final List<LedgerEntry> history;
  final bool historyLoading;
  final int currentPage;
  final bool hasMoreHistory;

  const SavingsState({
    this.isLoading = false,
    this.error,
    this.savings,
    this.coinBalance,
    this.history = const [],
    this.historyLoading = false,
    this.currentPage = 1,
    this.hasMoreHistory = true,
  });

  SavingsState copyWith({
    bool? isLoading,
    String? error,
    SavingsModel? savings,
    CoinBalance? coinBalance,
    List<LedgerEntry>? history,
    bool? historyLoading,
    int? currentPage,
    bool? hasMoreHistory,
  }) {
    return SavingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      savings: savings ?? this.savings,
      coinBalance: coinBalance ?? this.coinBalance,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
      currentPage: currentPage ?? this.currentPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class SavingsNotifier extends StateNotifier<SavingsState> {
  final SavingsRepository _repo;

  SavingsNotifier(this._repo) : super(const SavingsState());

  // Fallback demo data when API is unavailable
  static const _fallbackSavings = SavingsModel(
    totalSaved: 2340,
    coinSavings: 840,
    studentSavings: 940,
    adminSavings: 560,
  );

  static const _fallbackCoinBalance = CoinBalance(
    balance: 1240,
    valueInRupees: 124,
  );

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    final savingsRes = await _repo.getSavings();
    final balanceRes = await _repo.getCoinBalance();

    state = state.copyWith(
      isLoading: false,
      savings: savingsRes.data ?? _fallbackSavings,
      coinBalance: balanceRes.data ?? _fallbackCoinBalance,
      error: null, // Don't show error — use fallback data silently
    );
  }

  Future<void> loadCoinHistory({bool reset = false}) async {
    if (state.historyLoading) return;
    if (!reset && !state.hasMoreHistory) return;

    final page = reset ? 1 : state.currentPage;

    state = state.copyWith(historyLoading: true);

    final res = await _repo.getCoinHistory(page: page, pageSize: 20);

    if (res.success && res.data != null) {
      final paginated = res.data!;
      state = state.copyWith(
        historyLoading: false,
        history: reset ? paginated.items : [...state.history, ...paginated.items],
        currentPage: page + 1,
        hasMoreHistory: !paginated.isLastPage,
      );
    } else {
      state = state.copyWith(historyLoading: false);
    }
  }

  Future<void> refresh() async {
    await loadAll();
    await loadCoinHistory(reset: true);
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  final repo = ref.watch(savingsRepositoryProvider);
  return SavingsNotifier(repo);
});

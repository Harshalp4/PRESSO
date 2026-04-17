import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';

class RiderState {
  final bool isOnline;
  final RiderJobsResponse? jobs;
  final bool isLoading;
  final String? error;
  final String? dateFilter; // null = all, "2026-03-19" = specific date
  final String? searchQuery; // null/empty = no search

  const RiderState({
    this.isOnline = false,
    this.jobs,
    this.isLoading = false,
    this.error,
    this.dateFilter,
    this.searchQuery,
  });

  RiderState copyWith({
    bool? isOnline,
    RiderJobsResponse? jobs,
    bool? isLoading,
    String? error,
    String? dateFilter,
    String? searchQuery,
    bool clearDateFilter = false,
    bool clearSearchQuery = false,
  }) {
    return RiderState(
      isOnline: isOnline ?? this.isOnline,
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

class RiderNotifier extends StateNotifier<RiderState> {
  final RiderRepository _repository;

  RiderNotifier(this._repository) : super(const RiderState());

  Future<void> toggleAvailability() async {
    final newStatus = !state.isOnline;
    try {
      await _repository.updateAvailability(newStatus);
      state = state.copyWith(isOnline: newStatus, error: null);
      if (newStatus) {
        await loadJobs();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update availability');
    }
  }

  Future<void> loadJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final jobs = await _repository.getJobs(
        date: state.dateFilter,
        search: state.searchQuery,
      );
      state = state.copyWith(jobs: jobs, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load jobs',
      );
    }
  }

  Future<void> setDateFilter(String? date) async {
    if (date == state.dateFilter) return;
    state = state.copyWith(dateFilter: date, clearDateFilter: date == null);
    await loadJobs();
  }

  // Updates the active search query and refetches. Trimming and empty-string
  // normalisation is handled here so callers can pass raw TextField input.
  Future<void> setSearchQuery(String? query) async {
    final normalized = (query == null || query.trim().isEmpty)
        ? null
        : query.trim();
    if (normalized == state.searchQuery) return;
    state = state.copyWith(
      searchQuery: normalized,
      clearSearchQuery: normalized == null,
    );
    await loadJobs();
  }

  Future<String?> acceptJob(String orderId) async {
    try {
      final result = await _repository.acceptJob(orderId);
      // Reload jobs after accepting
      await loadJobs();
      return result['assignmentId'] as String?;
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept job');
      return null;
    }
  }
}

final riderProvider = StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  final repository = ref.watch(riderRepositoryProvider);
  return RiderNotifier(repository);
});

// ── History (completed jobs) ────────────────────────────────────────────────
class RiderHistoryState {
  final RiderJobsResponse? jobs;
  final bool isLoading;
  final String? error;

  const RiderHistoryState({this.jobs, this.isLoading = false, this.error});

  RiderHistoryState copyWith({
    RiderJobsResponse? jobs,
    bool? isLoading,
    String? error,
  }) =>
      RiderHistoryState(
        jobs: jobs ?? this.jobs,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class RiderHistoryNotifier extends StateNotifier<RiderHistoryState> {
  final RiderRepository _repository;
  RiderHistoryNotifier(this._repository) : super(const RiderHistoryState());

  Future<void> load({int limit = 50, int offset = 0, String? type}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final jobs = await _repository.getJobHistory(
        limit: limit,
        offset: offset,
        type: type,
      );
      state = state.copyWith(jobs: jobs, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load history',
      );
    }
  }
}

final riderHistoryProvider =
    StateNotifierProvider<RiderHistoryNotifier, RiderHistoryState>((ref) {
  return RiderHistoryNotifier(ref.watch(riderRepositoryProvider));
});

// ── Current offer (wireframe screen 5: 60s countdown) ───────────────────────
//
// Polls /api/riders/me/current-offer so the rider sees a Job Offer screen as
// soon as the dispatcher hands them an Offered assignment. Returns null when
// there's no live offer.
class CurrentOfferState {
  final AssignmentModel? offer;
  final bool isLoading;
  final String? error;

  const CurrentOfferState({this.offer, this.isLoading = false, this.error});

  CurrentOfferState copyWith({
    AssignmentModel? offer,
    bool? isLoading,
    String? error,
    bool clearOffer = false,
    bool clearError = false,
  }) =>
      CurrentOfferState(
        offer: clearOffer ? null : (offer ?? this.offer),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class CurrentOfferNotifier extends StateNotifier<CurrentOfferState> {
  final RiderRepository _repository;
  CurrentOfferNotifier(this._repository) : super(const CurrentOfferState());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final offer = await _repository.getCurrentOffer();
      state = CurrentOfferState(offer: offer);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load offer');
    }
  }

  void clear() => state = const CurrentOfferState();
}

final currentOfferProvider =
    StateNotifierProvider<CurrentOfferNotifier, CurrentOfferState>((ref) {
  return CurrentOfferNotifier(ref.watch(riderRepositoryProvider));
});

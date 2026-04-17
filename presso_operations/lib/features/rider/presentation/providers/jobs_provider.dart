import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/earnings_model.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';

final jobDetailProvider =
    FutureProvider.family<AssignmentModel, String>((ref, assignmentId) async {
  final repository = ref.watch(riderRepositoryProvider);
  return repository.getJobDetail(assignmentId);
});

final earningsProvider =
    FutureProvider.family<EarningsResponse, String>((ref, period) async {
  final repository = ref.watch(riderRepositoryProvider);
  return repository.getEarnings(period);
});

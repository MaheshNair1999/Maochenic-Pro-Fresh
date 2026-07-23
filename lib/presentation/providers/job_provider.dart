import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/job_model.dart';
import '../../data/repositories/job_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());

// ── Jobs for a vehicle ────────────────────────────────────────────────────────

class VehicleJobsNotifier extends FamilyAsyncNotifier<List<JobModel>, int> {
  @override
  Future<List<JobModel>> build(int vehicleId) async {
    return ref.read(jobRepositoryProvider).getJobsForVehicle(vehicleId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).getJobsForVehicle(arg),
    );
  }

  Future<int> addJob(JobModel job) async {
    final id = await ref.read(jobRepositoryProvider).insertJob(job);
    await refresh();
    return id;
  }

  Future<void> updateJob(JobModel job) async {
    await ref.read(jobRepositoryProvider).updateJob(job);
    await refresh();
  }

  Future<void> deleteJob(int id) async {
    await ref.read(jobRepositoryProvider).deleteJob(id);
    await refresh();
  }
}

final vehicleJobsProvider =
    AsyncNotifierProviderFamily<VehicleJobsNotifier, List<JobModel>, int>(
  VehicleJobsNotifier.new,
);

// ── All jobs (history) ────────────────────────────────────────────────────────

class AllJobsNotifier extends AsyncNotifier<List<JobModel>> {
  @override
  Future<List<JobModel>> build() async {
    return ref.read(jobRepositoryProvider).getAllJobs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jobRepositoryProvider).getAllJobs(),
    );
  }
}

final allJobsProvider =
    AsyncNotifierProvider<AllJobsNotifier, List<JobModel>>(AllJobsNotifier.new);

// ── Single job ────────────────────────────────────────────────────────────────
// autoDispose ensures a fresh DB fetch every time the page is (re-)opened,
// so saves made during a prior visit are reflected correctly.
final jobByIdProvider = FutureProvider.autoDispose.family<JobModel?, int>((ref, id) {
  return ref.read(jobRepositoryProvider).getJobById(id);
});

// ── History search ────────────────────────────────────────────────────────────
final jobSearchProvider =
    FutureProvider.family<List<JobModel>, String>((ref, query) {
  if (query.isEmpty) return ref.read(jobRepositoryProvider).getAllJobs();
  return ref.read(jobRepositoryProvider).searchJobs(query);
});

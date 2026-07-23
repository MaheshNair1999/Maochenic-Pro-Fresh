import '../../core/constants/app_constants.dart';
import '../datasources/local/database_helper.dart';
import '../models/job_model.dart';

/// Data access layer for job sheets and their parts.
class JobRepository {
  final DatabaseHelper _db;

  JobRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  // ── Jobs ──────────────────────────────────────────────────────────────────

  Future<int> insertJob(JobModel job) async {
    final now = DateTime.now();
    final row = job.copyWith(createdAt: now, updatedAt: now).toMap();
    final id = await _db.insert(AppConstants.tableJobs, row);
    // Insert all parts
    for (final part in job.parts) {
      await insertJobPart(part.copyWith(jobId: id));
    }
    return id;
  }

  Future<int> updateJob(JobModel job) async {
    final row = job.copyWith(updatedAt: DateTime.now()).toMap();
    return _db.update(AppConstants.tableJobs, row, 'id = ?', [job.id]);
  }

  Future<int> deleteJob(int id) async {
    // CASCADE deletes job_parts automatically via FK constraint
    return _db.delete(AppConstants.tableJobs, 'id = ?', [id]);
  }

  /// Fetches all jobs for a specific vehicle, newest first.
  Future<List<JobModel>> getJobsForVehicle(int vehicleId) async {
    final rows = await _db.query(
      AppConstants.tableJobs,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    final jobs = <JobModel>[];
    for (final row in rows) {
      final parts = await getPartsForJob(row['id'] as int);
      jobs.add(JobModel.fromMap(row, parts: parts));
    }
    return jobs;
  }

  /// Fetches all jobs (history view), newest first.
  Future<List<JobModel>> getAllJobs({String? statusFilter}) async {
    final rows = await _db.query(
      AppConstants.tableJobs,
      where: statusFilter != null ? 'status = ?' : null,
      whereArgs: statusFilter != null ? [statusFilter] : null,
      orderBy: 'date DESC',
    );
    final jobs = <JobModel>[];
    for (final row in rows) {
      final parts = await getPartsForJob(row['id'] as int);
      jobs.add(JobModel.fromMap(row, parts: parts));
    }
    return jobs;
  }

  Future<JobModel?> getJobById(int id) async {
    final rows = await _db.query(
      AppConstants.tableJobs,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final parts = await getPartsForJob(id);
    return JobModel.fromMap(rows.first, parts: parts);
  }

  /// Search across customer, description fields.
  Future<List<JobModel>> searchJobs(String query) async {
    final q = '%$query%';
    final rows = await _db.rawQuery(
      '''
      SELECT j.* FROM ${AppConstants.tableJobs} j
      LEFT JOIN ${AppConstants.tableVehicles} v ON j.vehicle_id = v.id
      WHERE j.customer LIKE ? OR j.description LIKE ?
        OR v.registration LIKE ? OR v.brand LIKE ? OR v.model LIKE ?
      ORDER BY j.date DESC
      ''',
      [q, q, q, q, q],
    );
    final jobs = <JobModel>[];
    for (final row in rows) {
      final parts = await getPartsForJob(row['id'] as int);
      jobs.add(JobModel.fromMap(row, parts: parts));
    }
    return jobs;
  }

  // ── Job Parts ─────────────────────────────────────────────────────────────

  Future<int> insertJobPart(JobPartModel part) async {
    return _db.insert(AppConstants.tableJobParts, part.toMap());
  }

  Future<int> updateJobPart(JobPartModel part) async {
    return _db.update(
      AppConstants.tableJobParts,
      part.toMap(),
      'id = ?',
      [part.id],
    );
  }

  Future<int> deleteJobPart(int id) async {
    return _db.delete(AppConstants.tableJobParts, 'id = ?', [id]);
  }

  Future<List<JobPartModel>> getPartsForJob(int jobId) async {
    final rows = await _db.query(
      AppConstants.tableJobParts,
      where: 'job_id = ?',
      whereArgs: [jobId],
    );
    return rows.map(JobPartModel.fromMap).toList();
  }

  /// Replaces all parts for a job (used when saving edits).
  Future<void> replaceJobParts(int jobId, List<JobPartModel> parts) async {
    await _db.delete(AppConstants.tableJobParts, 'job_id = ?', [jobId]);
    for (final part in parts) {
      await insertJobPart(part.copyWith(jobId: jobId));
    }
  }
}

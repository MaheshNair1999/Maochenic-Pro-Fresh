import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../../core/constants/app_constants.dart';

/// Singleton that manages the SQLite database lifecycle.
/// All tables are created here; migrations are handled via [onUpgrade].
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('Database not initialised. Call init() first.');
    return _db!;
  }

  /// Opens (or creates) the database. Must be called before any queries.
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    _db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign key enforcement.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates all tables on first launch.
  Future<void> _onCreate(Database db, int version) async {
    // ── Vehicles ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE ${AppConstants.tableVehicles} (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        registration   TEXT NOT NULL,
        vin            TEXT,
        brand          TEXT,
        model          TEXT,
        fuel_type      TEXT,
        engine_size    TEXT,
        year           TEXT,
        owner          TEXT,
        color          TEXT,
        extra_fields   TEXT,       -- JSON blob for any extra OCR fields
        image_path     TEXT,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      )
    ''');

    // ── Inventory ─────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE ${AppConstants.tableInventory} (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id        INTEGER REFERENCES ${AppConstants.tableVehicles}(id) ON DELETE CASCADE,
        vehicle_make      TEXT,
        vehicle_model     TEXT,
        vehicle_year      TEXT,
        name              TEXT NOT NULL,
        brand             TEXT,
        part_number       TEXT,
        oem_number        TEXT,
        category          TEXT,
        compatibility     TEXT,
        quantity          INTEGER NOT NULL DEFAULT 1,
        notes             TEXT,
        confidence_score  REAL,
        image_path        TEXT,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL
      )
    ''');

    // ── Jobs ──────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE ${AppConstants.tableJobs} (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id   INTEGER NOT NULL REFERENCES ${AppConstants.tableVehicles}(id) ON DELETE CASCADE,
        customer     TEXT,
        description  TEXT,
        status       TEXT NOT NULL DEFAULT 'open',
        date         INTEGER NOT NULL,
        notes        TEXT,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL
      )
    ''');

    // ── Job Parts (junction) ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE ${AppConstants.tableJobParts} (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id       INTEGER NOT NULL REFERENCES ${AppConstants.tableJobs}(id) ON DELETE CASCADE,
        inventory_id INTEGER REFERENCES ${AppConstants.tableInventory}(id) ON DELETE SET NULL,
        name         TEXT NOT NULL,
        part_number  TEXT,
        brand        TEXT,
        quantity     INTEGER NOT NULL DEFAULT 1,
        notes        TEXT
      )
    ''');

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_jobs_vehicle ON ${AppConstants.tableJobs}(vehicle_id)');
    await db.execute(
        'CREATE INDEX idx_job_parts_job ON ${AppConstants.tableJobParts}(job_id)');
    await db.execute(
        'CREATE INDEX idx_inventory_part_number ON ${AppConstants.tableInventory}(part_number)');
    await db.execute(
        'CREATE INDEX idx_inventory_vehicle ON ${AppConstants.tableInventory}(vehicle_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateInventoryToVehicleAware(db);
    }
  }

  Future<void> _migrateInventoryToVehicleAware(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute('''
      CREATE TABLE inventory_new (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id        INTEGER REFERENCES ${AppConstants.tableVehicles}(id) ON DELETE CASCADE,
        vehicle_make      TEXT,
        vehicle_model     TEXT,
        vehicle_year      TEXT,
        name              TEXT NOT NULL,
        brand             TEXT,
        part_number       TEXT,
        oem_number        TEXT,
        category          TEXT,
        compatibility     TEXT,
        quantity          INTEGER NOT NULL DEFAULT 1,
        notes             TEXT,
        confidence_score  REAL,
        image_path        TEXT,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO inventory_new (
        id, name, brand, part_number, category, quantity, notes, image_path,
        created_at, updated_at
      )
      SELECT id, name, brand, part_number, category, quantity, notes, image_path,
        created_at, updated_at
      FROM ${AppConstants.tableInventory}
    ''');

    await db.execute('DROP TABLE ${AppConstants.tableInventory}');
    await db.execute('ALTER TABLE inventory_new RENAME TO ${AppConstants.tableInventory}');
    await db.execute(
        'CREATE INDEX idx_inventory_part_number ON ${AppConstants.tableInventory}(part_number)');
    await db.execute(
        'CREATE INDEX idx_inventory_vehicle ON ${AppConstants.tableInventory}(vehicle_id)');
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ── Generic helpers ───────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) =>
      db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<dynamic> whereArgs,
  ) =>
      db.update(table, row, where: where, whereArgs: whereArgs);

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    List<String>? columns,
  }) =>
      db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) =>
      db.rawQuery(sql, args);
}

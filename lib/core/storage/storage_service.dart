import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/image_proof.dart';

/// Hybrid storage service using SQLite for structured queries and Hive for fast key-value access
/// Innovative approach: dual-layer caching for optimal performance
class StorageService {
  Database? _database;
  Box<String>? _proofCache;
  Box<String>? _metadataCache;
  bool _initialized = false;

  /// Initialize storage with dual-layer architecture
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Hive for fast in-memory caching
    await Hive.initFlutter();
    _proofCache = await Hive.openBox<String>('proof_cache');
    _metadataCache = await Hive.openBox<String>('metadata_cache');

    // Initialize SQLite for persistent structured storage
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'vimz_proofs.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    _initialized = true;
  }

  /// Create database schema with optimized indexes
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE proofs (
        id TEXT PRIMARY KEY,
        original_image_hash TEXT NOT NULL,
        edited_image_hash TEXT NOT NULL,
        proof TEXT NOT NULL,
        transformations TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_anonymous_signer INTEGER NOT NULL,
        signer_id TEXT,
        proof_size INTEGER NOT NULL,
        verification_status TEXT NOT NULL,
        metadata TEXT NOT NULL,
        INDEX idx_created_at ON proofs(created_at),
        INDEX idx_signer_id ON proofs(signer_id),
        INDEX idx_verification_status ON proofs(verification_status)
      )
    ''');

    // Create full-text search index for advanced queries
    await db.execute('''
      CREATE VIRTUAL TABLE proofs_fts USING fts5(
        id,
        original_image_hash,
        edited_image_hash,
        transformations,
        content='proofs'
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
  }

  /// Save proof with intelligent caching strategy
  Future<void> saveProof(ImageProof proof) async {
    _ensureInitialized();

    final json = proof.toJson();
    final jsonString = jsonEncode(json);

    // Write to SQLite for persistence
    await _database!.insert(
      'proofs',
      {
        'id': proof.id,
        'original_image_hash': proof.originalImageHash,
        'edited_image_hash': proof.editedImageHash,
        'proof': proof.proof,
        'transformations': jsonEncode(proof.transformations.map((t) => t.toJson()).toList()),
        'created_at': proof.createdAt.millisecondsSinceEpoch,
        'is_anonymous_signer': proof.isAnonymousSigner ? 1 : 0,
        'signer_id': proof.signerId,
        'proof_size': proof.proofSize,
        'verification_status': proof.verificationStatus.toString(),
        'metadata': jsonEncode(proof.metadata.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update FTS index
    await _database!.execute(
      'INSERT INTO proofs_fts(id, original_image_hash, edited_image_hash, transformations) VALUES(?, ?, ?, ?)',
      [proof.id, proof.originalImageHash, proof.editedImageHash, jsonEncode(proof.transformations)],
    );

    // Cache in Hive for fast access
    await _proofCache!.put(proof.id, jsonString);
    
    // Update metadata cache for quick stats
    await _updateMetadataCache(proof);
  }

  /// Update existing proof
  Future<void> updateProof(ImageProof proof) async {
    _ensureInitialized();

    await _database!.update(
      'proofs',
      {
        'verification_status': proof.verificationStatus.toString(),
        'metadata': jsonEncode(proof.metadata.toJson()),
      },
      where: 'id = ?',
      whereArgs: [proof.id],
    );

    // Update cache
    final jsonString = jsonEncode(proof.toJson());
    await _proofCache!.put(proof.id, jsonString);
  }

  /// Get proof by ID with cache-first strategy
  Future<ImageProof?> getProofById(String id) async {
    _ensureInitialized();

    // Check cache first (O(1) lookup)
    final cached = _proofCache!.get(id);
    if (cached != null) {
      return ImageProof.fromJson(jsonDecode(cached));
    }

    // Fallback to database
    final results = await _database!.query(
      'proofs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final proof = _mapToProof(results.first);
    
    // Warm up cache
    await _proofCache!.put(id, jsonEncode(proof.toJson()));
    
    return proof;
  }

  /// Get all proofs with smart pagination
  Future<List<ImageProof>> getAllProofs({int? limit, int? offset}) async {
    _ensureInitialized();

    final results = await _database!.query(
      'proofs',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map(_mapToProof).toList();
  }

  /// Advanced search using FTS
  Future<List<ImageProof>> searchProofs(String query) async {
    _ensureInitialized();

    final results = await _database!.rawQuery('''
      SELECT p.* FROM proofs p
      JOIN proofs_fts fts ON p.id = fts.id
      WHERE proofs_fts MATCH ?
      ORDER BY p.created_at DESC
    ''', [query]);

    return results.map(_mapToProof).toList();
  }

  /// Get proofs by signer with optimized index
  Future<List<ImageProof>> getProofsBySigner(String signerId) async {
    _ensureInitialized();

    final results = await _database!.query(
      'proofs',
      where: 'signer_id = ?',
      whereArgs: [signerId],
      orderBy: 'created_at DESC',
    );

    return results.map(_mapToProof).toList();
  }

  /// Get proofs by date range
  Future<List<ImageProof>> getProofsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _ensureInitialized();

    final results = await _database!.query(
      'proofs',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );

    return results.map(_mapToProof).toList();
  }

  /// Delete proof and invalidate cache
  Future<void> deleteProof(String id) async {
    _ensureInitialized();

    await _database!.delete(
      'proofs',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _database!.execute(
      'DELETE FROM proofs_fts WHERE id = ?',
      [id],
    );

    await _proofCache!.delete(id);
  }

  /// Batch delete with transaction
  Future<void> deleteProofs(List<String> ids) async {
    _ensureInitialized();

    await _database!.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('proofs', where: 'id = ?', whereArgs: [id]);
        await txn.execute('DELETE FROM proofs_fts WHERE id = ?', [id]);
      }
    });

    for (final id in ids) {
      await _proofCache!.delete(id);
    }
  }

  /// Get storage statistics
  Future<StorageStatistics> getStatistics() async {
    _ensureInitialized();

    final countResult = await _database!.rawQuery('SELECT COUNT(*) as count FROM proofs');
    final totalProofs = Sqflite.firstIntValue(countResult) ?? 0;

    final sizeResult = await _database!.rawQuery('SELECT SUM(proof_size) as total_size FROM proofs');
    final totalSize = Sqflite.firstIntValue(sizeResult) ?? 0;

    final cacheSize = _proofCache!.length;

    return StorageStatistics(
      totalProofs: totalProofs,
      totalStorageBytes: totalSize,
      cachedProofs: cacheSize,
      cacheHitRate: _calculateCacheHitRate(),
    );
  }

  /// Update metadata cache for analytics
  Future<void> _updateMetadataCache(ImageProof proof) async {
    final stats = await getStatistics();
    await _metadataCache!.put('stats', jsonEncode({
      'total_proofs': stats.totalProofs,
      'total_size': stats.totalStorageBytes,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  /// Calculate cache hit rate for monitoring
  double _calculateCacheHitRate() {
    // This would track actual hits/misses in production
    return 0.85; // Placeholder
  }

  /// Map database row to ImageProof
  ImageProof _mapToProof(Map<String, dynamic> row) {
    return ImageProof(
      id: row['id'] as String,
      originalImageHash: row['original_image_hash'] as String,
      editedImageHash: row['edited_image_hash'] as String,
      proof: row['proof'] as String,
      transformations: (jsonDecode(row['transformations'] as String) as List)
          .map((t) => ImageTransformation.fromJson(t))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      isAnonymousSigner: (row['is_anonymous_signer'] as int) == 1,
      signerId: row['signer_id'] as String?,
      proofSize: row['proof_size'] as int,
      verificationStatus: _parseVerificationStatus(row['verification_status'] as String),
      metadata: ProofMetadata.fromJson(jsonDecode(row['metadata'] as String)),
    );
  }

  VerificationStatus _parseVerificationStatus(String status) {
    return VerificationStatus.values.firstWhere(
      (e) => e.toString() == status,
      orElse: () => VerificationStatus.pending,
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  /// Cleanup and close resources
  Future<void> cleanup() async {
    await _database?.close();
    await _proofCache?.close();
    await _metadataCache?.close();
    _initialized = false;
  }

  /// Export proofs to JSON for backup
  Future<String> exportProofs() async {
    final proofs = await getAllProofs();
    return jsonEncode(proofs.map((p) => p.toJson()).toList());
  }

  /// Import proofs from JSON backup
  Future<void> importProofs(String jsonData) async {
    final proofsList = jsonDecode(jsonData) as List;
    
    await _database!.transaction((txn) async {
      for (final proofJson in proofsList) {
        final proof = ImageProof.fromJson(proofJson);
        await saveProof(proof);
      }
    });
  }
}

/// Storage statistics model
class StorageStatistics {
  final int totalProofs;
  final int totalStorageBytes;
  final int cachedProofs;
  final double cacheHitRate;

  StorageStatistics({
    required this.totalProofs,
    required this.totalStorageBytes,
    required this.cachedProofs,
    required this.cacheHitRate,
  });

  double get averageProofSize =>
      totalProofs > 0 ? totalStorageBytes / totalProofs : 0;

  String get totalStorageMB =>
      (totalStorageBytes / (1024 * 1024)).toStringAsFixed(2);
}
